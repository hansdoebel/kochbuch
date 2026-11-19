import { z } from 'zod';
import type { Recipe, Nutrients } from '../lib/types';
import {
  dietTargetsSchema,
  nutritionBasisSchema,
  dietKeys,
  targetPenalty,
  type DietTargets,
  type DietKey,
} from '../lib/diet';
export const adaptSchema = z
  .object({
    id: z.string().min(1).max(100),
    targets: dietTargetsSchema,
    source: nutritionBasisSchema.default('bls_complete'),
    eatingStyle: z.enum(['any', 'vegetarian', 'vegan']).default('any'),
    excludedIngredientIds: z.array(z.number().int().positive()).max(100).default([]),
    minPortions: z.number().finite().min(0.1).max(10).default(0.5),
    maxPortions: z.number().finite().positive().max(10).default(2),
  })
  .strict()
  .refine((i) => i.minPortions <= i.maxPortions, 'Ungültige Portionsgrenzen');
export type AdaptInput = z.input<typeof adaptSchema>;
export function recipeValues(
  recipe: Recipe,
  source: 'bls_complete' | 'publisher_estimate',
  targets: DietTargets
) {
  const keys = dietKeys.filter((k) => targets[k]);
  const values: Nutrients = {};
  const missing: string[] = [];
  if (source === 'publisher_estimate') {
    const p = recipe.publisherNutrition?.nutrients;
    if (p)
      Object.assign(values, {
        energy_kcal: p.energy_kcal,
        protein_g: p.protein_g,
        carbs_g: p.publisher_carbohydrates_g,
        fiber_g: p.fiber_g,
        fat_g: p.fat_g,
      });
    for (const k of keys) if (typeof values[k] !== 'number') missing.push(k);
  } else {
    for (const k of keys) {
      const value = recipe.nutrition?.nutrients[k];
      const c = recipe.nutrition?.calculation;
      const coverage = c?.coverage[k];
      if (
        typeof value !== 'number' ||
        (c && (!coverage || coverage.total <= 0 || coverage.known !== coverage.total))
      )
        missing.push(k);
      else values[k] = value;
    }
  }
  return { values, missing };
}
export function adaptRecipe(input: AdaptInput, recipe: Recipe) {
  const options = adaptSchema.parse(input);
  if (options.id !== recipe.id) throw new Error('Rezept-ID stimmt nicht überein.');
  const keys = dietKeys.filter((k) => options.targets[k]);
  const { values, missing } = recipeValues(recipe, options.source, options.targets);
  const excluded = recipe.structuredIngredients.some(
    (i) => i.ingredientId !== null && options.excludedIngredientIds.includes(i.ingredientId)
  );
  const styleFits =
    options.eatingStyle === 'any' ||
    recipe.tags.includes(options.eatingStyle === 'vegan' ? 'Vegan' : 'Vegetarisch') ||
    (options.eatingStyle === 'vegetarian' && recipe.tags.includes('Vegan'));
  const unavailable =
    excluded || !styleFits || !recipe.ready || !recipe.servings || !keys.length || !!missing.length;
  const warnings: string[] = [];
  if (options.source === 'publisher_estimate')
    warnings.push(
      'Anpassung auf Basis einer Herausgeber-Schätzung; keine BLS-Berechnung. Kohlenhydratdefinition der Quelle bleibt maßgeblich.'
    );
  else
    warnings.push(
      missing.length
        ? 'Die Zutatenbilanz ist für gewählte Ziele unvollständig.'
        : 'Vollständige bekannte Zutatenwerte für die gewählten Ziele; generische Referenzwerte und Garverluste bleiben Schätzunsicherheiten.'
    );
  if (recipe.structuredIngredients.some((i) => i.quantity === null))
    warnings.push(
      'Zutaten ohne Mengenangabe behalten ihren Originaltext; keine Menge wird erfunden.'
    );
  if (unavailable)
    return {
      status: 'unavailable' as const,
      id: recipe.id,
      servings: null,
      nutrients: {} as Nutrients,
      source: options.source,
      sourceUrl:
        options.source === 'publisher_estimate'
          ? recipe.publisherNutrition?.sourceUrl
          : recipe.nutrition?.sourceUrl,
      missing,
      violations: [] as { key: DietKey; value: number; min?: number; max?: number }[],
      warnings: [
        ...warnings,
        excluded || !styleFits
          ? 'Rezept entspricht nicht deinen Zutatenfiltern oder der Ernährungsweise.'
          : !keys.length
            ? 'Bitte mindestens ein Ziel festlegen.'
            : !recipe.ready
              ? 'Nur normalisierte Rezepte sind anpassbar.'
              : 'Nährwerte fehlen oder sind für die gewählten Ziele unvollständig.',
      ],
      ingredients: [] as {
        name: string;
        text: string;
        quantity: number | null;
        unit: string | null;
        optional: boolean;
      }[],
    };
  let low = options.minPortions,
    high = options.maxPortions;
  const candidates = [low, high, 1];
  for (const key of keys) {
    const v = values[key]!,
      r = options.targets[key]!;
    if (v === 0) {
      if ((r.min ?? 0) > 0) low = Infinity;
      continue;
    }
    if (r.min !== undefined) {
      low = Math.max(low, r.min / v);
      candidates.push(r.min / v);
    }
    if (r.max !== undefined) {
      high = Math.min(high, r.max / v);
      candidates.push(r.max / v);
    }
  }
  const energy = options.targets.energy_kcal;
  const desired =
    energy && values.energy_kcal! > 0
      ? ((energy.min ?? energy.max!) + (energy.max ?? energy.min!)) / 2 / values.energy_kcal!
      : 1;
  let servings: number;
  if (low <= high) {
    servings = Math.min(high, Math.max(low, desired));
  } else {
    candidates.push(desired);
    const score = (s: number) =>
      keys.reduce((n, k) => n + targetPenalty(values[k]! * s, options.targets[k]!) ** 2, 0);
    const breaks = [
      ...new Set(
        candidates
          .filter(Number.isFinite)
          .map((s) => Math.max(options.minPortions, Math.min(options.maxPortions, s)))
      ),
    ].sort((a, b) => a - b);
    for (let i = 1; i < breaks.length; i++) {
      const left = breaks[i - 1],
        right = breaks[i],
        mid = (left + right) / 2;
      let aa = 0,
        ab = 0;
      for (const k of keys) {
        const v = values[k]!,
          r = options.targets[k]!;
        let a = 0,
          b = 0;
        if (r.min !== undefined && v * mid < r.min) {
          a = -v / Math.max(r.min, 1);
          b = r.min / Math.max(r.min, 1);
        } else if (r.max !== undefined && v * mid > r.max) {
          a = v / Math.max(r.max, 1);
          b = -r.max / Math.max(r.max, 1);
        }
        aa += a * a;
        ab += a * b;
      }
      if (aa > 0) candidates.push(Math.max(left, Math.min(right, -ab / aa)));
    }
    servings = candidates
      .filter(Number.isFinite)
      .map((s) => Math.max(options.minPortions, Math.min(options.maxPortions, s)))
      .sort((a, b) => score(a) - score(b) || Math.abs(a - 1) - Math.abs(b - 1))[0];
  }
  const nutrients = Object.fromEntries(
    Object.entries(values).map(([k, v]) => [k, v! * servings])
  ) as Nutrients;
  const violations = keys
    .filter((k) => targetPenalty(nutrients[k]!, options.targets[k]!) > 1e-8)
    .map((key) => ({ key, value: nutrients[key]!, ...options.targets[key] }));
  if (violations.length)
    warnings.push(
      'Mit proportionalen Zutatenmengen sind nicht alle Ziele gleichzeitig erfüllbar. Dies ist eine Näherung, kein passender Gesamtplan.'
    );
  return {
    status: violations.length ? ('closest' as const) : ('fits' as const),
    id: recipe.id,
    servings,
    nutrients,
    source: options.source,
    sourceUrl:
      options.source === 'publisher_estimate'
        ? recipe.publisherNutrition!.sourceUrl
        : recipe.nutrition!.sourceUrl,
    missing,
    violations,
    warnings,
    ingredients: recipe.structuredIngredients.map((i) => ({
      name: i.name,
      text: i.text,
      quantity: i.quantity === null ? null : (i.quantity * servings) / recipe.servings!,
      unit: i.unit,
      optional: i.optional,
    })),
  };
}
export type Adaptation = ReturnType<typeof adaptRecipe>;
