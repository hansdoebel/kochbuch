import { z } from 'zod';
export const dietKeys = ['energy_kcal', 'protein_g', 'carbs_g', 'fiber_g', 'fat_g'] as const;
export type DietKey = (typeof dietKeys)[number];
const limits: Record<DietKey, number> = {
  energy_kcal: 10000,
  protein_g: 500,
  carbs_g: 1500,
  fiber_g: 200,
  fat_g: 500,
};
const range = (max: number) =>
  z
    .object({
      min: z.number().finite().nonnegative().max(max).optional(),
      max: z.number().finite().nonnegative().max(max).optional(),
    })
    .strict()
    .refine((r) => r.min !== undefined || r.max !== undefined, 'Mindestens eine Grenze angeben')
    .refine(
      (r) => r.min === undefined || r.max === undefined || r.min <= r.max,
      'Minimum darf Maximum nicht übersteigen'
    );
export const dietTargetsSchema = z
  .object({
    energy_kcal: range(limits.energy_kcal).optional(),
    protein_g: range(limits.protein_g).optional(),
    carbs_g: range(limits.carbs_g).optional(),
    fiber_g: range(limits.fiber_g).optional(),
    fat_g: range(limits.fat_g).optional(),
  })
  .strict();
export type DietTargets = z.infer<typeof dietTargetsSchema>;
export const nutritionBasisSchema = z.enum(['bls_complete', 'publisher_estimate']);
export const dietPreferencesSchema = z
  .object({
    version: z.literal(1),
    purpose: z.enum(['manual', 'maintain', 'gain', 'lose']).default('manual'),
    eatingStyle: z.enum(['any', 'vegetarian', 'vegan']).default('any'),
    excludedIngredientIds: z
      .array(z.number().int().positive())
      .max(100)
      .refine((a) => new Set(a).size === a.length)
      .default([]),
    profiles: z.object({ training: dietTargetsSchema, rest: dietTargetsSchema }),
    trainingWeekdays: z
      .array(z.number().int().min(0).max(6))
      .max(7)
      .refine((a) => new Set(a).size === a.length)
      .default([]),
    overrides: z
      .record(z.iso.date(), z.enum(['training', 'rest']))
      .refine((o) => Object.keys(o).length <= 366)
      .default({}),
    source: nutritionBasisSchema.default('bls_complete'),
    mealShare: z.number().finite().positive().max(1).optional(),
    minPortions: z.number().finite().positive().min(0.1).max(10).default(0.5),
    maxPortions: z.number().finite().positive().max(10).default(2),
  })
  .strict()
  .refine((p) => p.minPortions <= p.maxPortions, 'Portionsgrenzen prüfen');
export type DietPreferences = z.infer<typeof dietPreferencesSchema>;
export const defaultDietPreferences = (): DietPreferences =>
  dietPreferencesSchema.parse({ version: 1, profiles: { training: {}, rest: {} } });
export function migrateLegacyGoals(raw: unknown): DietPreferences {
  const prefs = defaultDietPreferences();
  if (!raw || typeof raw !== 'object') return prefs;
  const profile: DietTargets = {};
  for (const key of dietKeys) {
    const n = (raw as Record<string, unknown>)[key];
    if (typeof n === 'number' && Number.isFinite(n) && n > 0 && n <= limits[key])
      profile[key] = key === 'protein_g' || key === 'fiber_g' ? { min: n } : { min: n, max: n };
  }
  prefs.profiles.training = structuredClone(profile);
  prefs.profiles.rest = structuredClone(profile);
  return prefs;
}
export function dayProfile(prefs: DietPreferences, date: string): 'training' | 'rest' {
  z.iso.date().parse(date);
  return (
    prefs.overrides[date] ??
    (prefs.trainingWeekdays.includes(new Date(date + 'T12:00:00Z').getUTCDay())
      ? 'training'
      : 'rest')
  );
}
export function targetsForDate(prefs: DietPreferences, date: string): DietTargets {
  return prefs.profiles[dayProfile(prefs, date)];
}
export function mealTargets(prefs: DietPreferences, date: string): DietTargets {
  if (prefs.mealShare === undefined)
    throw new Error('Bitte den Anteil der Mahlzeit am Tagesziel festlegen.');
  const goals = targetsForDate(prefs, date);
  const result: DietTargets = {};
  for (const key of dietKeys) {
    const r = goals[key];
    if (r)
      result[key] = {
        ...(r.min === undefined ? {} : { min: r.min * prefs.mealShare }),
        ...(r.max === undefined ? {} : { max: r.max * prefs.mealShare }),
      };
  }
  return result;
}
export function targetPenalty(value: number, range: { min?: number; max?: number }) {
  if (range.min !== undefined && value < range.min)
    return (range.min - value) / Math.max(range.min, 1);
  if (range.max !== undefined && value > range.max)
    return (value - range.max) / Math.max(range.max, 1);
  return 0;
}
export const goalLabel = (r: { min?: number; max?: number } | undefined) =>
  !r
    ? 'Nicht festgelegt'
    : r.min !== undefined && r.max !== undefined
      ? `${r.min}–${r.max}`
      : r.min !== undefined
        ? `≥ ${r.min}`
        : `≤ ${r.max}`;
