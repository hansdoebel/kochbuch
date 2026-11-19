import { z } from 'zod';
import type { Recipe, Selection, Analysis, Nutrients } from './types';
export const selectionSchema = z
  .array(z.object({ id: z.string().max(100), servings: z.number().finite().positive().max(100) }))
  .max(24)
  .refine((items) => new Set(items.map((i) => i.id)).size === items.length, 'Duplicate recipes');
export function selectedRecipes(selections: Selection[], get: (id: string) => Recipe | null) {
  selectionSchema.parse(selections);
  return selections.map((item) => {
    const recipe = get(item.id);
    if (!recipe)
      throw new Error(
        'Ein ausgewähltes Rezept ist nicht mehr verfügbar. Bitte entferne es aus der Auswahl.'
      );
    return { recipe, servings: item.servings };
  });
}
export function analyse(selections: Selection[], get: (id: string) => Recipe | null): Analysis {
  const selected = selectedRecipes(selections, get);
  const totals: Nutrients = {};
  const coverage: Record<string, number> = {};
  const missingRecipes: string[] = [];
  const partialRecipes: string[] = [];
  const completeCoverage: Record<string, number> = {};
  let profiledCount = 0,
    verifiedCount = 0;
  for (const { recipe, servings } of selected) {
    if (!recipe.nutrition) {
      missingRecipes.push(recipe.title);
      continue;
    }
    profiledCount++;
    if (recipe.nutrition.quality === 'verified') verifiedCount++;
    if (
      recipe.nutrition.calculation &&
      Object.values(recipe.nutrition.calculation.coverage).some((c) => c && c.known < c.total)
    )
      partialRecipes.push(recipe.title);
    for (const [key, value] of Object.entries(recipe.nutrition.nutrients))
      if (value !== null && value !== undefined) {
        totals[key as keyof Nutrients] = (totals[key as keyof Nutrients] ?? 0) + value * servings;
        coverage[key] = (coverage[key] ?? 0) + 1;
        const c = recipe.nutrition.calculation?.coverage[key as keyof Nutrients];
        if (!recipe.nutrition.calculation || (c && c.total > 0 && c.known === c.total))
          completeCoverage[key] = (completeCoverage[key] ?? 0) + 1;
      }
  }
  return {
    selectedCount: selected.length,
    profiledCount,
    verifiedCount,
    totals,
    coverage,
    missingRecipes,
    partialRecipes,
    completeCoverage,
  };
}
