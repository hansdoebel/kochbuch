import { createHash } from 'node:crypto';
import { z } from 'zod';
import type {
  Recipe,
  Selection,
  ShoppingList,
  ShoppingItem,
  Analysis,
  Nutrients,
} from '../lib/types';
export const selectionSchema = z
  .array(z.object({ id: z.string().max(100), servings: z.number().finite().positive().max(100) }))
  .max(24)
  .refine((items) => new Set(items.map((i) => i.id)).size === items.length, 'Duplicate recipes');
const number = (n: number) =>
  new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 }).format(n);
const safeId = (key: string) => createHash('sha256').update(key).digest('hex').slice(0, 16);
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
export function shoppingList(
  selections: Selection[],
  get: (id: string) => Recipe | null,
  options: { hidePantry?: boolean; includeOptional?: boolean } = {}
): ShoppingList {
  const selected = selectedRecipes(selections, get);
  const groups = new Map<string, Map<string, ShoppingItem>>();
  const originals: string[] = [];
  const add = (group: string, key: string, item: ShoppingItem) => {
    if (!groups.has(group)) groups.set(group, new Map());
    const old = groups.get(group)!.get(key);
    if (old && old.quantity !== null && item.quantity !== null) {
      old.quantity += item.quantity;
      old.recipes = [...new Set([...old.recipes, ...item.recipes])];
    } else if (!old) groups.get(group)!.set(key, item);
  };
  for (const { recipe, servings } of selected) {
    if (!recipe.ready) {
      originals.push(recipe.title);
      recipe.ingredients.forEach((text, i) =>
        add('Originalmengen · ' + recipe.title, recipe.id + ':' + i, {
          id: safeId(recipe.id + ':' + i),
          text,
          quantity: null,
          unit: null,
          optional: false,
          recipes: [recipe.title],
        })
      );
      continue;
    }
    for (const ingredient of recipe.structuredIngredients) {
      if (options.hidePantry && ingredient.pantry) continue;
      if (options.includeOptional === false && ingredient.optional) continue;
      const scale = servings / recipe.servings!;
      const key = JSON.stringify([
        ingredient.ingredientId,
        ingredient.unit,
        ingredient.variant,
        ingredient.optional,
        ingredient.quantity === null ? recipe.id : null,
      ]);
      const name = ingredient.name + (ingredient.variant ? ' (' + ingredient.variant + ')' : '');
      add(ingredient.category, key, {
        id: safeId(key),
        text:
          ingredient.quantity === null
            ? ingredient.text + ' · Originalmenge, nicht skaliert'
            : name,
        quantity: ingredient.quantity === null ? null : ingredient.quantity * scale,
        unit: ingredient.unit,
        optional: ingredient.optional,
        recipes: [recipe.title],
      });
    }
  }
  const categoryOrder = [
    'Obst & Gemüse',
    'Milchprodukte & Eier',
    'Fleisch & Wurst',
    'Fisch',
    'Grundnahrungsmittel',
    'Gewürze & Backzutaten',
    'Konserven & Gläser',
    'Tiefkühl',
    'Getränke',
    'Sonstiges',
  ];
  const result = [...groups]
    .sort(
      ([a], [b]) =>
        (categoryOrder.indexOf(a) < 0 ? 99 : categoryOrder.indexOf(a)) -
        (categoryOrder.indexOf(b) < 0 ? 99 : categoryOrder.indexOf(b))
    )
    .map(([name, items]) => ({
      name,
      items: [...items.values()].map((i) => ({
        ...i,
        text:
          (i.quantity === null ? '' : number(i.quantity) + ' ' + (i.unit ?? '') + ' ') +
          i.text +
          (i.optional && !/optional/i.test(i.text) ? ' · optional' : ''),
      })),
    }));
  return {
    version: 1,
    createdAt: new Date().toISOString(),
    recipes: selected.map(({ recipe, servings }) => ({
      title: recipe.title,
      portions: recipe.ready ? number(servings) + ' Portionen' : 'Original: ' + recipe.servingsText,
      sourceUrl: recipe.sourceUrl,
    })),
    groups: result,
    unscaledRecipes: originals,
    itemCount: result.reduce((n, g) => n + g.items.length, 0),
  };
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
