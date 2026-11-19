export type Nutrients = Partial<
  Record<
    | 'energy_kcal'
    | 'protein_g'
    | 'carbs_g'
    | 'fiber_g'
    | 'fat_g'
    | 'sugar_g'
    | 'saturated_fat_g'
    | 'sodium_mg'
    | 'calcium_mg'
    | 'iron_mg'
    | 'magnesium_mg'
    | 'potassium_mg'
    | 'zinc_mg'
    | 'vitamin_b12_ug'
    | 'vitamin_d_ug'
    | 'folate_ug'
    | 'iodine_ug'
    | 'selenium_ug',
    number | null
  >
>;
export interface NutritionProfile {
  recipeId: string;
  basis: 'per_serving';
  quality: 'estimated' | 'verified';
  sourceUrl: string;
  reviewedAt: string;
  nutrients: Nutrients;
}
export interface RecipeSummary {
  id: string;
  title: string;
  source: string;
  sourceUrl: string | null;
  ready: boolean;
  servings: number | null;
  servingsText: string;
  minutes: number | null;
  ingredientCount: number;
  language: string;
  hasNutrition: boolean;
  missingFields: string[];
  tags: string[];
}
export interface Ingredient {
  name: string;
  text: string;
  quantity: number | null;
  unit: string | null;
  group: string;
  category: string;
  pantry: boolean;
  optional: boolean;
  variant: string | null;
  ingredientId: number | null;
}
export interface Recipe extends RecipeSummary {
  authors: string[];
  ingredients: string[];
  structuredIngredients: Ingredient[];
  instructions: string[];
  notes: string[];
  nutrition: NutritionProfile | null;
}
export interface BasketItem {
  id: string;
  servings: number;
  title: string;
  ready: boolean;
  source: string;
}
export interface Selection {
  id: string;
  servings: number;
}
export interface ShoppingItem {
  id: string;
  text: string;
  quantity: number | null;
  unit: string | null;
  optional: boolean;
  recipes: string[];
}
export interface ShoppingList {
  version: 1;
  createdAt: string;
  recipes: { title: string; portions: string; sourceUrl: string | null }[];
  groups: { name: string; items: ShoppingItem[] }[];
  unscaledRecipes: string[];
  itemCount: number;
}
export interface Analysis {
  selectedCount: number;
  profiledCount: number;
  verifiedCount: number;
  totals: Nutrients;
  coverage: Record<string, number>;
  missingRecipes: string[];
}
export interface CatalogMeta {
  count: number;
  readyCount: number;
  nutritionCount: number;
  sources: { name: string; count: number }[];
  pdfAvailable: boolean;
}
