import { z } from 'zod';
import type { Recipe, Selection, Nutrients } from '../lib/types';
import { analyse } from './shopping';

export const planSchema = z.object({
  startDate: z.iso.date(),
  days: z.number().int().min(1).max(7).default(7),
  servings: z.number().positive().max(10).default(1),
  maxMinutes: z.number().int().positive().max(360).default(90),
  vegan: z.boolean().default(false),
  mainOnly: z.boolean().default(true),
  maxRepeats: z.number().int().min(1).max(3).default(3),
  targetsPerMeal: z
    .object({
      energy_kcal: z.number().positive().max(5000).optional(),
      protein_g: z.number().positive().max(300).optional(),
      fiber_g: z.number().positive().max(150).optional(),
    })
    .default({}),
});
export type PlanInput = z.input<typeof planSchema>;
export function suggestPlan(input: PlanInput, recipes: Recipe[]) {
  const options = planSchema.parse(input);
  const candidates = recipes
    .filter(
      (r) =>
        r.ready &&
        r.servings &&
        r.minutes !== null &&
        r.minutes <= options.maxMinutes &&
        (!options.vegan || r.tags.includes('Vegan')) &&
        (!options.mainOnly || r.tags.includes('Hauptgericht'))
    )
    .sort((a, b) => a.id.localeCompare(b.id));
  const entries: { date: string; recipe: Recipe; servings: number; nutritionUsed: boolean }[] = [];
  const counts = new Map<string, number>();
  const usedIngredients = new Set<number>();
  const targets = Object.entries(options.targetsPerMeal) as [keyof Nutrients, number][];
  for (let day = 0; day < options.days; day++) {
    let best: Recipe | null = null,
      bestScore = -Infinity,
      nutritionUsed = false;
    for (const r of candidates) {
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
      if (nutritionEligible)
        score +=
          5 -
          targets.reduce(
            (sum, [key, target]) =>
              sum +
              Math.min(
                3,
                Math.abs(r.nutrition!.nutrients[key]! * options.servings - target) / target
              ),
            0
          ) /
            targets.length;
      if (score > bestScore) {
        best = r;
        bestScore = score;
        nutritionUsed = nutritionEligible;
      }
    }
    if (!best) break;
    const date = new Date(options.startDate + 'T12:00:00Z');
    date.setUTCDate(date.getUTCDate() + day);
    entries.push({
      date: date.toISOString().slice(0, 10),
      recipe: best,
      servings: options.servings,
      nutritionUsed,
    });
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
      analysis: analyse([{ id: e.recipe.id, servings: e.servings }], get),
    })),
    selections,
    analysis: analyse(selections, get),
    warnings: [
      'Vorschlag für eine Mahlzeit pro Tag, keine vollständige Tagesernährung. Auswahl vor dem Einkauf prüfen.',
      'Abwechslung, Zeitlimit, Datenabdeckung und gemeinsame Zutaten berücksichtigt; keine Aussage über Haltbarkeit oder Allergene.',
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
