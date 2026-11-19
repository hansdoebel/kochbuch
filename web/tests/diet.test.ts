import { test, expect, beforeAll, afterAll } from 'bun:test';
import {
  defaultDietPreferences,
  dietPreferencesSchema,
  mealTargets,
  dayProfile,
  migrateLegacyGoals,
  targetPenalty,
} from '../src/lib/diet';
import { adaptRecipe } from '../src/server/adaptation';
import { suggestPlan } from '../src/server/planner';
import { Catalog } from '../src/server/catalog';
import { createApp } from '../src/server/app';
import { shoppingList } from '../src/server/shopping';
import type { Recipe } from '../src/lib/types';
let catalog: Catalog;
beforeAll(() => (catalog = new Catalog(undefined, false)));
afterAll(() => catalog.close());
function fixture(): Recipe {
  const r = structuredClone(catalog.get('ready:quinoa-bowl-mit-tofu-in-sesamkruste-und-brokkoli')!);
  r.id = 'ready:test';
  r.servings = 4;
  r.tags = ['Hauptgericht', 'Vegan'];
  r.minutes = 20;
  r.nutrition = {
    recipeId: r.id,
    basis: 'per_serving',
    quality: 'estimated',
    sourceUrl: 'https://example.org/nutrition',
    reviewedAt: '2026-11-19',
    nutrients: { energy_kcal: 500, protein_g: 30, carbs_g: 40, fiber_g: 10, fat_g: 20, iron_mg: 2 },
  };
  r.structuredIngredients = [
    {
      ...r.structuredIngredients.find((i) => i.name === 'Tofu natur')!,
      quantity: 400,
      text: '400 g Tofu',
    },
    { ...r.structuredIngredients.at(-1)!, quantity: null, text: 'Pfeffer nach Geschmack' },
  ];
  return r;
}
test('goal migration uses minimums and creates no invented targets', () => {
  expect(defaultDietPreferences().profiles.rest).toEqual({});
  const p = migrateLegacyGoals({
    energy_kcal: 2000,
    protein_g: 120,
    fiber_g: 30,
    carbs_g: -1,
    fat_g: 'bad',
  });
  expect(p.profiles.rest).toEqual({
    energy_kcal: { min: 2000, max: 2000 },
    protein_g: { min: 120 },
    fiber_g: { min: 30 },
  });
  expect(p.mealShare).toBeUndefined();
  expect(targetPenalty(160, { min: 120 })).toBe(0);
});
test('calendar profiles, exceptions and personal meal allocation', () => {
  const p = defaultDietPreferences();
  p.trainingWeekdays = [1];
  p.profiles.training = { energy_kcal: { min: 2400, max: 2600 }, protein_g: { min: 150 } };
  p.profiles.rest = { energy_kcal: { min: 2000, max: 2200 } };
  expect(dayProfile(p, '2026-11-23')).toBe('training');
  expect(() => mealTargets(p, '2026-11-23')).toThrow();
  p.mealShare = 0.25;
  expect(mealTargets(p, '2026-11-23')).toEqual({
    energy_kcal: { min: 600, max: 650 },
    protein_g: { min: 37.5 },
  });
  p.overrides['2026-11-23'] = 'rest';
  expect(mealTargets(p, '2026-11-23').energy_kcal).toEqual({ min: 500, max: 550 });
});
test('rejects inverted ranges, invalid dates, duplicate weekdays and bad portions', () => {
  const p = defaultDietPreferences();
  for (const v of [
    { ...p, profiles: { ...p.profiles, rest: { protein_g: { min: 100, max: 50 } } } },
    { ...p, trainingWeekdays: [1, 1] },
    { ...p, overrides: { '2026-02-30': 'rest' } },
    { ...p, minPortions: 3, maxPortions: 1 },
    { ...p, mealShare: 0 },
    { ...p, profiles: { ...p.profiles, rest: { protein_g: { min: Infinity } } } },
  ])
    expect(dietPreferencesSchema.safeParse(v).success).toBe(false);
});
test('simultaneous bounds scale personal ingredients without rewriting the recipe', () => {
  const r = fixture();
  const a = adaptRecipe(
    {
      id: r.id,
      targets: {
        energy_kcal: { min: 700, max: 800 },
        protein_g: { min: 42 },
        fiber_g: { min: 12 },
      },
    },
    r
  );
  expect(a.status).toBe('fits');
  expect(a.servings).toBeCloseTo(1.5);
  expect(a.nutrients.protein_g).toBeCloseTo(45);
  expect(a.ingredients[0].quantity).toBeCloseTo(150);
  expect(a.ingredients[1].quantity).toBeNull();
  expect(a.ingredients[1].text).toBe('Pfeffer nach Geschmack');
  expect(r.structuredIngredients[0].quantity).toBe(400);
  expect(r.servings).toBe(4);
});
test('incompatible ratios return the exact closest proportional approximation', () => {
  const r = fixture();
  r.nutrition!.nutrients = { energy_kcal: 100, protein_g: 10 };
  const a = adaptRecipe(
    { id: r.id, targets: { energy_kcal: { max: 100 }, protein_g: { min: 20 } } },
    r
  );
  expect(a.status).toBe('closest');
  expect(a.servings).toBeCloseTo(1.2);
  expect(a.violations).toHaveLength(2);
  expect(a.nutrients.protein_g).toBeCloseTo(12);
});
test('zero is known, missing is not zero, and portion limits constrain the result', () => {
  const r = fixture();
  r.nutrition!.nutrients.fiber_g = 0;
  expect(adaptRecipe({ id: r.id, targets: { fiber_g: { max: 0 } } }, r).status).toBe('fits');
  expect(adaptRecipe({ id: r.id, targets: { fiber_g: { min: 10 } } }, r).status).toBe('closest');
  delete r.nutrition!.nutrients.fiber_g;
  expect(adaptRecipe({ id: r.id, targets: { fiber_g: { min: 10 } } }, r).status).toBe(
    'unavailable'
  );
  expect(
    adaptRecipe({ id: r.id, targets: { energy_kcal: { min: 2000 } }, maxPortions: 2 }, r).servings
  ).toBe(2);
});
test('partial BLS blocks adjustment; publisher estimates require explicit choice and stay separate', () => {
  const r = fixture();
  r.nutrition!.calculation = {
    totalLines: 2,
    knownLines: 1,
    coverage: { energy_kcal: { known: 1, total: 2 } },
    missing: [],
    sources: [],
    warnings: [],
  };
  expect(
    adaptRecipe({ id: r.id, targets: { energy_kcal: { min: 990, max: 990 } } }, r).status
  ).toBe('unavailable');
  const a = adaptRecipe(
    {
      id: r.id,
      source: 'publisher_estimate',
      targets: { energy_kcal: { min: 990, max: 990 }, carbs_g: { min: 86 } },
    },
    r
  );
  expect(a.status).toBe('fits');
  expect(a.servings).toBe(1);
  expect(a.nutrients.carbs_g).toBe(86);
  expect(a.nutrients.iron_mg).toBeUndefined();
  expect(a.sourceUrl).toBe(r.publisherNutrition!.sourceUrl);
  expect(a.warnings.join(' ')).toContain('Kohlenhydratdefinition');
});
test('stale recipe selections cannot bypass ingredient exclusions or vegan filters', () => {
  const r = fixture();
  expect(
    adaptRecipe(
      {
        id: r.id,
        targets: { protein_g: { min: 20 } },
        excludedIngredientIds: [r.structuredIngredients[0].ingredientId!],
      },
      r
    ).status
  ).toBe('unavailable');
  r.tags = ['Hauptgericht', 'Vegetarisch'];
  expect(
    adaptRecipe({ id: r.id, targets: { protein_g: { min: 20 } }, eatingStyle: 'vegan' }, r).status
  ).toBe('unavailable');
});
test('household size changes shopping amounts but not the personal nutrient goal', () => {
  const r = fixture(),
    p = defaultDietPreferences();
  p.mealShare = 0.25;
  p.profiles.rest = { energy_kcal: { min: 3000, max: 3000 }, protein_g: { min: 160 } };
  const plan = suggestPlan({ startDate: '2026-11-19', days: 1, servings: 3, diet: p }, [r]);
  expect(plan.entries[0].adaptation!.servings).toBeCloseTo(1.5);
  expect(plan.entries[0].servings).toBeCloseTo(4.5);
  expect(plan.entries[0].adaptation!.nutrients.protein_g).toBeCloseTo(45);
  const list = shoppingList(plan.selections, (id) => (id === r.id ? r : null));
  expect(
    list.groups.flatMap((g) => g.items).find((i) => i.text.includes('Tofu'))!.quantity
  ).toBeCloseTo(450);
  expect(() => suggestPlan({ startDate: '2026-11-19', servings: 1.5, diet: p }, [r])).toThrow();
});
test('missing profile on one day does not prevent planning later days', () => {
  const r = fixture(),
    p = defaultDietPreferences();
  p.mealShare = 0.25;
  p.trainingWeekdays = [4];
  p.profiles.training = { carbs_g: { min: 30 } };
  p.profiles.rest = { protein_g: { min: 80 } };
  delete r.nutrition!.nutrients.carbs_g;
  const plan = suggestPlan({ startDate: '2026-11-19', days: 2, diet: p }, [r]);
  expect(plan.unplannedDates).toEqual(['2026-11-19']);
  expect(plan.entries.map((e) => e.date)).toEqual(['2026-11-20']);
});
test('advance preparation is opt-in, and aggregate portions remain exportable', () => {
  const r = fixture();
  r.tags.push('Vorbereitung am Vortag');
  expect(suggestPlan({ startDate: '2026-11-19', days: 1 }, [r]).entries).toHaveLength(0);
  expect(
    suggestPlan({ startDate: '2026-11-19', days: 1, allowAdvancePrep: true }, [r]).warnings.join(
      ' '
    )
  ).toContain('Marinierzeit');
  const second = { ...fixture(), id: 'ready:second' };
  const p = defaultDietPreferences();
  p.mealShare = 1;
  p.maxPortions = 10;
  p.profiles.rest = { energy_kcal: { min: 5000, max: 5000 } };
  const plan = suggestPlan(
    { startDate: '2026-11-19', days: 7, servings: 10, diet: p, allowAdvancePrep: true },
    [r, second]
  );
  expect(plan.selections.every((s) => s.servings <= 100)).toBe(true);
});
test('real Asian tofu imports and adaptation API enforce provenance and validation', async () => {
  const handle = createApp(catalog);
  const options = await (await handle(new Request('http://local/api/diet/options'))).json();
  expect(options.recipes.filter((r: Recipe) => r.tags.includes('Asiatisch'))).toHaveLength(3);
  const id = 'ready:quinoa-bowl-mit-tofu-in-sesamkruste-und-brokkoli',
    r = catalog.get(id)!;
  expect(r.tags).not.toContain('Vegan');
  expect(r.publisherNutrition!.nutrients.protein_g).toBe(51);
  const post = (body: unknown, origin = 'http://local') =>
    handle(
      new Request('http://local/api/diet/adapt', {
        method: 'POST',
        headers: { Origin: origin },
        body: JSON.stringify(body),
      })
    );
  const body = { id, targets: { energy_kcal: { min: 495, max: 495 }, protein_g: { min: 25 } } };
  expect((await (await post(body)).json()).status).toBe('unavailable');
  const a = await (await post({ ...body, source: 'publisher_estimate' })).json();
  expect(a.status).toBe('fits');
  expect(a.servings).toBeCloseTo(0.5);
  expect(a.nutrients.protein_g).toBeCloseTo(25.5);
  expect(a.ingredients.find((i: { name: string }) => i.name === 'Tofu natur').quantity).toBeCloseTo(
    50
  );
  expect((await post(body, 'https://other.example')).status).toBe(403);
  expect((await post({ ...body, minPortions: 3, maxPortions: 1 })).status).toBe(400);
  expect((await post({ ...body, id: 'missing' })).status).toBe(404);
});

test('planner treats protein and fiber as minimums, not exact maxima', () => {
  const above = fixture(),
    exact = fixture();
  above.id = 'ready:a';
  exact.id = 'ready:z';
  above.nutrition!.nutrients.protein_g = 80;
  above.nutrition!.nutrients.fiber_g = 25;
  exact.nutrition!.nutrients.protein_g = 30;
  exact.nutrition!.nutrients.fiber_g = 10;
  const plan = suggestPlan(
    { startDate: '2026-11-19', days: 1, targetsPerMeal: { protein_g: 30, fiber_g: 10 } },
    [exact, above]
  );
  expect(plan.entries[0].id).toBe(above.id);
});
test('a fitting recipe takes priority over a fresh recipe that misses targets', () => {
  const fit = fixture(),
    closest = fixture();
  fit.id = 'ready:fit';
  closest.id = 'ready:closest';
  closest.nutrition!.nutrients = { energy_kcal: 500, protein_g: 1 };
  const p = defaultDietPreferences();
  p.mealShare = 1;
  p.profiles.rest = { energy_kcal: { min: 500, max: 500 }, protein_g: { min: 30 } };
  const plan = suggestPlan({ startDate: '2026-11-19', days: 3, diet: p }, [fit, closest]);
  expect(plan.entries.map((e) => e.id)).toEqual([fit.id, closest.id, fit.id]);
  expect(plan.entries[2].adaptation?.status).toBe('fits');
});
