import { z } from 'zod';
import type { Recipe, Selection, Nutrients } from '../lib/types';
import { analyse } from '../lib/analysis';
import { adaptRecipe, type Adaptation } from './adaptation';
import {
  dietPreferencesSchema,
  mealTargets,
  dayProfile,
  targetPenalty,
  type DietTargets,
} from '../lib/diet';

export const planSchema = z.object({
  startDate: z.iso.date(),
  days: z.number().int().min(1).max(7).default(7),
  servings: z.number().positive().max(10).default(1),
  maxMinutes: z.number().int().positive().max(360).default(90),
  vegan: z.boolean().default(false),
  allowAdvancePrep: z.boolean().default(false),
  diet: dietPreferencesSchema.optional(),
  mainOnly: z.boolean().default(true),
  maxRepeats: z.number().int().min(1).max(3).default(3),
  targetsPerMeal: z
    .object({
      energy_kcal: z.number().positive().max(5000).optional(),
      protein_g: z.number().positive().max(300).optional(),
      fiber_g: z.number().positive().max(150).optional(),
      carbs_g: z.number().positive().max(1000).optional(),
    })
    .default({}),
});
export type PlanInput = z.input<typeof planSchema>;
export function suggestPlan(input: PlanInput, recipes: Recipe[]) {
  const options = planSchema.parse(input);
  if (options.diet && (!Number.isInteger(options.servings) || options.diet.mealShare === undefined))
    throw new Error('Für Tagesprofile ganze Personenzahl und Mahlzeitenanteil festlegen.');
  const candidates = recipes
    .filter(
      (r) =>
        r.ready &&
        r.servings &&
        r.minutes !== null &&
        r.minutes <= options.maxMinutes &&
        (!options.vegan || r.tags.includes('Vegan')) &&
        (!options.mainOnly || r.tags.includes('Hauptgericht')) &&
        (options.allowAdvancePrep || !r.tags.includes('Vorbereitung am Vortag')) &&
        (!options.diet ||
          ((options.diet.eatingStyle !== 'vegan' || r.tags.includes('Vegan')) &&
            (options.diet.eatingStyle !== 'vegetarian' ||
              r.tags.includes('Vegetarisch') ||
              r.tags.includes('Vegan')) &&
            !r.structuredIngredients.some(
              (i) =>
                i.ingredientId !== null &&
                options.diet!.excludedIngredientIds.includes(i.ingredientId)
            )))
    )
    .sort((a, b) => a.id.localeCompare(b.id));
  const entries: {
    date: string;
    recipe: Recipe;
    servings: number;
    nutritionUsed: boolean;
    adaptation?: Adaptation;
    profile?: string;
  }[] = [];
  const counts = new Map<string, number>();
  const plannedServings = new Map<string, number>();
  const usedIngredients = new Set<number>();
  const targets = Object.entries(options.targetsPerMeal) as [keyof Nutrients, number][];
  const unplannedDates: string[] = [];
  for (let day = 0; day < options.days; day++) {
    const date = new Date(options.startDate + 'T12:00:00Z');
    date.setUTCDate(date.getUTCDate() + day);
    const dateString = date.toISOString().slice(0, 10);
    let bestAdaptation: Adaptation | undefined;
    let best: Recipe | null = null,
      bestScore = -Infinity,
      nutritionUsed = false;
    for (const r of candidates) {
      const adaptation = options.diet
        ? adaptRecipe(
            {
              id: r.id,
              targets: mealTargets(options.diet, dateString),
              source: options.diet.source,
              minPortions: options.diet.minPortions,
              maxPortions: options.diet.maxPortions,
            },
            r
          )
        : undefined;
      if (adaptation?.status === 'unavailable') continue;
      const batch = (adaptation?.servings ?? 1) * options.servings;
      if ((plannedServings.get(r.id) ?? 0) + batch > 100) continue;
      const count = counts.get(r.id) ?? 0;
      if (count >= options.maxRepeats || entries.at(-1)?.recipe.id === r.id) continue;
      const c = r.nutrition?.calculation;
      const completeness =
        c && c.totalLines > 0 ? c.knownLines / c.totalLines : r.nutrition ? 1 : 0;
      const nutritionEligible =
        !!targets.length &&
        targets.every(([key]) => {
          const coverage = c?.coverage[key];
          return (
            typeof r.nutrition?.nutrients[key] === 'number' &&
            (!c || (coverage && coverage.total > 0 && coverage.known === coverage.total))
          );
        });
      // Incomplete lower bounds must never be rewarded as meeting a target.
      let score = 3 * completeness - 4 * count;
      const ids = [
        ...new Set(
          r.structuredIngredients
            .map((i) => i.ingredientId)
            .filter((id): id is number => id !== null)
        ),
      ];
      score += ids.length ? ids.filter((id) => usedIngredients.has(id)).length / ids.length : 0;
      if (adaptation) {
        const t = mealTargets(options.diet!, dateString);
        const deviation = Object.entries(t).reduce(
          (sum, [key, range]) =>
            sum + targetPenalty(adaptation.nutrients[key as keyof Nutrients]!, range!) ** 2,
          0
        );
        // Satisfying the requested bounds takes priority over ingredient reuse or variety scores.
        score += adaptation.status === 'fits' ? 100 : 10 - 20 * Math.min(deviation, 10);
      }
      if (!adaptation && nutritionEligible)
        score +=
          5 -
          targets.reduce(
            (sum, [key, target]) =>
              sum +
              Math.min(
                3,
                targetPenalty(
                  r.nutrition!.nutrients[key]! * options.servings,
                  key === 'protein_g' || key === 'fiber_g'
                    ? { min: target }
                    : { min: target, max: target }
                )
              ),
            0
          ) /
            targets.length;
      if (score > bestScore) {
        best = r;
        bestScore = score;
        nutritionUsed = !!adaptation || nutritionEligible;
        bestAdaptation = adaptation;
      }
    }
    if (!best) {
      unplannedDates.push(dateString);
      continue;
    }
    entries.push({
      date: date.toISOString().slice(0, 10),
      recipe: best,
      servings:
        bestAdaptation?.servings !== null && bestAdaptation?.servings !== undefined
          ? bestAdaptation.servings * options.servings
          : options.servings,
      nutritionUsed,
      adaptation: bestAdaptation,
      profile: options.diet ? dayProfile(options.diet, dateString) : undefined,
    });
    plannedServings.set(best.id, (plannedServings.get(best.id) ?? 0) + entries.at(-1)!.servings);
    counts.set(best.id, (counts.get(best.id) ?? 0) + 1);
    best.structuredIngredients.forEach((i) => {
      if (i.ingredientId !== null) usedIngredients.add(i.ingredientId);
    });
  }
  const sums = new Map<string, number>();
  entries.forEach((e) => sums.set(e.recipe.id, (sums.get(e.recipe.id) ?? 0) + e.servings));
  const selections: Selection[] = [...sums].map(([id, servings]) => ({ id, servings }));
  const get = (id: string) => candidates.find((r) => r.id === id) ?? null;
  return {
    entries: entries.map((e) => ({
      date: e.date,
      id: e.recipe.id,
      title: e.recipe.title,
      servings: e.servings,
      source: e.recipe.source,
      ready: e.recipe.ready,
      minutes: e.recipe.minutes,
      nutritionUsed: e.nutritionUsed,
      adaptation: e.adaptation,
      profile: e.profile,
      analysis: analyse([{ id: e.recipe.id, servings: e.servings }], get),
    })),
    selections,
    unplannedDates,
    analysis: analyse(selections, get),
    warnings: [
      'Vorschlag für eine Mahlzeit pro Tag, keine vollständige Tagesernährung. Auswahl vor dem Einkauf prüfen.',
      ...(entries.some((e) => e.recipe.tags.includes('Vorbereitung am Vortag'))
        ? [
            'Vorbereitung am Vortag erforderlich; die angegebene Kochzeit enthält keine Marinierzeit.',
          ]
        : []),
      'Abwechslung, Zeitlimit, Datenabdeckung und gemeinsame Zutaten berücksichtigt; keine Aussage über Haltbarkeit oder Allergene.',
      ...(entries.some((e) => e.adaptation?.status === 'closest')
        ? ['Einige Mahlzeiten sind nur Näherungen; nicht alle Ziele gleichzeitig erfüllbar.']
        : []),
      ...(options.diet?.source === 'publisher_estimate'
        ? [
            'Portionen verwenden ausdrücklich gewählte Herausgeber-Schätzungen. Keine BLS-Makros oder Mikronährwerte zugemischt.',
          ]
        : []),
      ...(entries.some((e) => !e.nutritionUsed) && targets.length
        ? ['Unvollständige Nährwerte werden nicht zur Zieloptimierung verwendet.']
        : []),
      ...(entries.length < options.days
        ? ['Nicht genug passende Rezepte für alle Tage unter diesen Filtern.']
        : []),
    ],
  };
}
export type WeeklyPlan = ReturnType<typeof suggestPlan>;
