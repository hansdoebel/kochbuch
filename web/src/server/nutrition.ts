import type { Database } from 'bun:sqlite';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { z } from 'zod';
import type { NutritionProfile, Nutrients } from '../lib/types';

const https = z.url().refine((value) => value.startsWith('https://'));
const factSchema = z.tuple([
  z.number().finite().nonnegative().nullable(),
  z.number().int().nonnegative().nullable(),
  z.number().int().nonnegative().nullable(),
  z.string().nullable(),
]);
export const snapshotSchema = z
  .object({
    version: z.literal(1),
    dataset: z.object({
      id: z.string().min(1),
      publisher: z.string().min(1),
      version: z.string().min(1),
      source_url: https,
      license: z.string().min(1),
      citation: z.string().min(1),
      retrieved_on: z.iso.date(),
      sha256: z.string().regex(/^[a-f0-9]{64}$/),
      expected_food_count: z.number().int().positive(),
    }),
    nutrients: z.array(
      z.object({
        code: z.string().min(1),
        name: z.string().min(1),
        unit: z.enum(['kcal', 'g', 'mg', 'ug']),
        source_code: z.string().min(1),
      })
    ),
    origins: z.array(z.string()),
    references: z.array(z.string()),
    foods: z.array(
      z.object({
        code: z.string().min(1),
        name: z.string().min(1),
        name_en: z.string().nullable(),
        facts: z.array(factSchema),
      })
    ),
  })
  .superRefine((d, ctx) => {
    const fail = (message: string) => ctx.addIssue({ code: 'custom', message });
    if (d.nutrients.some((n) => n.unit !== n.code.split('_').at(-1)))
      fail('Nutrient code/unit differs');
    if (new Set(d.nutrients.map((n) => n.code)).size !== d.nutrients.length)
      fail('Duplicate nutrient');
    if (
      new Set(d.foods.map((f) => f.code)).size !== d.foods.length ||
      d.foods.length !== d.dataset.expected_food_count
    )
      fail('Invalid food count or duplicate code');
    for (const food of d.foods) {
      if (food.facts.length !== d.nutrients.length) fail('Nutrient columns differ');
      for (const [value, origin, ref, qualifier] of food.facts) {
        if (
          (origin !== null && origin >= d.origins.length) ||
          (ref !== null && ref >= d.references.length)
        )
          fail('Invalid provenance reference');
        if (qualifier && value !== null) fail('Qualified unknown cannot be a number');
      }
    }
  });
const matchSchema = z.object({
  version: z.literal(1),
  matches: z.array(
    z.object({
      ingredient_id: z.number().int().positive(),
      ingredient_name: z.string().min(1),
      food_id: z.string().min(1),
      method: z.enum(['reviewed', 'exact']),
      reviewed_on: z.iso.date(),
      note: z.string().trim().min(1),
    })
  ),
  weights: z.array(
    z.object({
      recipe_ingredient_id: z.number().int().positive(),
      edible_grams: z.number().finite().nonnegative(),
      source_url: https,
      reviewed_on: z.iso.date(),
      note: z.string().trim().min(1),
    })
  ),
});
export function nutritionFiles(root: string) {
  return [
    'nutrition/load-matches.sql',
    'nutrition/matches.json',
    'nutrition/aliases.json',
    ...readdirSync(join(root, 'nutrition/data'))
      .filter((f) => f.endsWith('.json'))
      .map((f) => 'nutrition/data/' + f),
  ].map((f) => join(root, f));
}
export function loadNutrition(db: Database, root: string) {
  const execute = (file: string, document: unknown) => {
    const raw = JSON.stringify(document);
    for (const statement of readFileSync(join(root, file), 'utf8').split(';'))
      if (statement.trim()) db.query(statement).run({ $document: raw });
  };
  db.transaction(() => {
    for (const path of nutritionFiles(root).filter((f) => f.includes('/data/'))) {
      const raw = JSON.parse(readFileSync(path, 'utf8'));
      const doc = snapshotSchema.parse(raw);
      const d = doc.dataset;
      db.query('INSERT INTO nutrition_datasets VALUES (?,?,?,?,?,?,?,?)').run(
        d.id,
        d.publisher,
        d.version,
        d.source_url,
        d.license,
        d.citation,
        d.retrieved_on,
        d.sha256
      );
      const nutrient = db.query('INSERT OR IGNORE INTO nutrition_nutrients VALUES (?,?,?,?)');
      for (const n of doc.nutrients) nutrient.run(n.code, n.name, n.unit, n.source_code);
      const food = db.query('INSERT INTO nutrition_foods VALUES (?,?,?,?,?,?)');
      const fact = db.query('INSERT INTO nutrition_facts VALUES (?,?,?,?,?,?,?)');
      for (const f of doc.foods) {
        const id = d.id + ':' + f.code;
        food.run(id, d.id, f.code, f.name, f.name_en, d.source_url);
        f.facts.forEach(([value, origin, ref, qualifier], i) =>
          fact.run(
            id,
            doc.nutrients[i].code,
            value,
            origin === null ? null : doc.origins[origin],
            ref === null ? null : doc.references[ref],
            qualifier,
            doc.nutrients[i].source_code
          )
        );
      }
    }
    const matches = matchSchema.parse(
      JSON.parse(readFileSync(join(root, 'nutrition/matches.json'), 'utf8'))
    );
    for (const m of matches.matches) {
      const ingredient = db
        .query('SELECT name FROM ingredients WHERE id=?')
        .get(m.ingredient_id) as { name: string } | null;
      if (ingredient?.name !== m.ingredient_name)
        throw new Error('Nutrition mapping ingredient ID/name differs: ' + m.ingredient_name);
    }
    execute('nutrition/load-matches.sql', matches);
  })();
}
export function calculatedProfile(db: Database, id: number, slug: string): NutritionProfile | null {
  const rows = db.query('SELECT * FROM v_recipe_nutrition WHERE recipe_id=?').all(id) as {
    nutrient_code: keyof Nutrients;
    amount_per_serving: number | null;
    total_lines: number;
    known_lines: number;
  }[];
  if (!rows.some((r) => r.known_lines > 0)) return null;
  const lines = db
    .query('SELECT * FROM v_recipe_nutrition_lines WHERE recipe_id=? AND optional=0')
    .all(id) as {
    food_id: string | null;
    edible_grams: number | null;
    ingredient_name: string;
    weight_note: string | null;
  }[];
  const sources = db
    .query(
      `SELECT DISTINCT f.id AS foodId,f.name,d.citation AS dataset,f.source_url AS sourceUrl,m.note FROM v_recipe_nutrition_lines l JOIN ingredient_nutrition_matches m ON m.ingredient_id=l.ingredient_id JOIN nutrition_foods f ON f.id=m.food_id JOIN nutrition_datasets d ON d.id=f.dataset_id WHERE l.recipe_id=? AND l.optional=0 AND l.edible_grams IS NOT NULL ORDER BY f.id`
    )
    .all(id) as NonNullable<NutritionProfile['calculation']>['sources'];
  const date = db
    .query(
      `SELECT MAX(d.retrieved_on) AS day FROM nutrition_datasets d JOIN nutrition_foods f ON f.dataset_id=d.id WHERE f.id IN (SELECT value FROM json_each(?))`
    )
    .get(JSON.stringify(sources.map((s) => s.foodId))) as { day: string };
  return {
    recipeId: 'ready:' + slug,
    basis: 'per_serving',
    quality: 'estimated',
    sourceUrl: sources[0]?.sourceUrl ?? 'https://blsdb.de/download',
    reviewedAt: date.day,
    nutrients: Object.fromEntries(rows.map((r) => [r.nutrient_code, r.amount_per_serving])),
    calculation: {
      totalLines: lines.length,
      knownLines: lines.filter((l) => l.food_id && l.edible_grams !== null).length,
      coverage: Object.fromEntries(
        rows.map((r) => [r.nutrient_code, { known: r.known_lines, total: r.total_lines }])
      ),
      missing: lines
        .filter((l) => !l.food_id || l.edible_grams === null)
        .map((l) => ({
          ingredient: l.ingredient_name,
          reason: [
            !l.food_id ? 'Keine bestätigte Lebensmittelzuordnung' : '',
            l.edible_grams === null ? 'Essbares Gewicht fehlt' : '',
          ]
            .filter(Boolean)
            .join('; '),
        })),
      sources,
      warnings: [
        'Geschätzte Zutatenbilanz pro Portion; optionale Zutaten ausgeschlossen.',
        'Keine Korrektur für Garverluste, Vitaminabbau, abgetropfte Mengen oder Alkoholabgabe. Keine vollständige Verzehrmessung.',
        ...new Set(lines.map((l) => l.weight_note).filter((s): s is string => !!s)),
      ],
    },
  };
}
export function nutritionFoods(db: Database, q = '', offset = 0) {
  const escaped = q.replace(/[\\%_]/g, '\\$&');
  const pattern = '%' + escaped + '%';
  const where = `WHERE (f.name LIKE ? ESCAPE '\\' OR f.name_en LIKE ? ESCAPE '\\' OR f.source_food_code LIKE ? ESCAPE '\\')`;
  const total = (
    db
      .query(`SELECT COUNT(*) n FROM nutrition_foods f ${where}`)
      .get(pattern, pattern, pattern) as { n: number }
  ).n;
  const foods = db
    .query(
      `SELECT f.*,d.license,d.citation,d.version FROM nutrition_foods f JOIN nutrition_datasets d ON d.id=f.dataset_id ${where} ORDER BY f.name COLLATE NOCASE,f.id LIMIT 25 OFFSET ?`
    )
    .all(pattern, pattern, pattern, offset) as {
    id: string;
    name: string;
    source_food_code: string;
    dataset_id: string;
    name_en: string | null;
    source_url: string;
    license: string;
    citation: string;
    version: string;
  }[];
  return {
    total,
    items: foods.map((f) => ({
      ...f,
      nutrients: db
        .query(
          `SELECT n.code,n.name,n.unit,f.source_nutrient_code AS source_code,f.amount_per_100g,f.derivation,f.reference,f.qualifier FROM nutrition_facts f JOIN nutrition_nutrients n ON n.code=f.nutrient_code WHERE f.food_id=? ORDER BY n.code`
        )
        .all(String(f.id)),
    })),
  };
}
export function nutritionStatus(db: Database) {
  const scalar = (query: string) => (db.query(query).get() as { n: number }).n;
  return {
    foodCount: scalar('SELECT COUNT(*) n FROM nutrition_foods'),
    factCount: scalar('SELECT COUNT(*) n FROM nutrition_facts'),
    matchedIngredients: scalar('SELECT COUNT(*) n FROM ingredient_nutrition_matches'),
    ingredientCount: scalar('SELECT COUNT(*) n FROM ingredients'),
    datasets: db.query('SELECT * FROM nutrition_datasets ORDER BY id').all(),
    unresolved: db
      .query(
        `SELECT i.id,i.name,COUNT(DISTINCT ri.recipe_id) AS recipeCount FROM ingredients i JOIN recipe_ingredients ri ON ri.ingredient_id=i.id LEFT JOIN ingredient_nutrition_matches m ON m.ingredient_id=i.id WHERE m.food_id IS NULL GROUP BY i.id,i.name ORDER BY recipeCount DESC,i.name`
      )
      .all(),
  };
}

export function readFoodAliases(db: Database, root: string) {
  const doc = z
    .object({
      version: z.literal(1),
      aliases: z.array(
        z.object({ food_id: z.string().min(1), names: z.array(z.string().trim().min(1)).min(1) })
      ),
    })
    .parse(JSON.parse(readFileSync(join(root, 'nutrition/aliases.json'), 'utf8')));
  const aliases = new Map<string, string>();
  const add = (name: string, id: string) => {
    const key = normalizeFoodName(name);
    if (aliases.has(key) && aliases.get(key) !== id)
      throw new Error('Ambiguous food alias: ' + name);
    aliases.set(key, id);
  };
  for (const row of doc.aliases) {
    if (!db.query('SELECT id FROM nutrition_foods WHERE id=?').get(row.food_id))
      throw new Error('Alias refers to unknown food: ' + row.food_id);
    row.names.forEach((name) => add(name, row.food_id));
  }
  return aliases;
}
export const normalizeFoodName = (name: string) =>
  name.normalize('NFKC').toLocaleLowerCase('de-DE').replace(/\s+/g, ' ').trim();
export function parseMetricIngredient(text: string, aliases: Map<string, string>) {
  // Deliberately accept exact leading metric mass only. Never choose an
  // alternative, parse a range, infer a cup density or a cooked/raw state.
  if (
    /\b(or|oder|optional|cooked|boiled|baked|fried|roasted|drained|canned|toasted|sprouted|soaked|rehydrated|unshelled)\b|\b(?:in|with) (?:the )?shells?\b|[~≈]/i.test(
      text
    )
  )
    return null;
  const match = text
    .trim()
    .match(/^(\d+(?:\.\d+)?)\s*(kg|g|grams?|kilograms?)\s+([^,()]+)(?:[,()].*)?$/i);
  if (!match) return null;
  const foodId = aliases.get(normalizeFoodName(match[3]));
  if (!foodId) return null;
  const grams = Number(match[1].replace(',', '.')) * (/^(kg|kilogram)/i.test(match[2]) ? 1000 : 1);
  if (!Number.isFinite(grams) || grams < 0 || grams > 1_000_000) return null;
  return { foodId, grams };
}
export function archiveProfile(
  db: Database,
  recipeId: string,
  ingredients: string[],
  servings: number | null,
  aliases: Map<string, string>
): NutritionProfile | null {
  if (!servings || !ingredients.length) return null;
  const totals: Nutrients = {},
    coverage: NonNullable<NutritionProfile['calculation']>['coverage'] = {};
  const missing: { ingredient: string; reason: string }[] = [];
  const sources: NonNullable<NutritionProfile['calculation']>['sources'] = [];
  let knownLines = 0;
  for (const ingredient of ingredients) {
    const parsed = parseMetricIngredient(ingredient, aliases);
    if (!parsed) {
      missing.push({
        ingredient,
        reason: 'Keine eindeutige freigegebene Zuordnung mit metrischem Gewicht',
      });
      continue;
    }
    knownLines++;
    const rows = db
      .query('SELECT nutrient_code,amount_per_100g FROM nutrition_facts WHERE food_id=?')
      .all(parsed.foodId) as { nutrient_code: keyof Nutrients; amount_per_100g: number | null }[];
    for (const row of rows) {
      const c = coverage[row.nutrient_code] ?? { known: 0, total: ingredients.length };
      if (row.amount_per_100g !== null) {
        totals[row.nutrient_code] =
          (totals[row.nutrient_code] ?? 0) + (row.amount_per_100g * parsed.grams) / 100 / servings;
        c.known++;
      }
      coverage[row.nutrient_code] = c;
    }
    const source = db
      .query(
        'SELECT f.id AS foodId,f.name,d.citation AS dataset,f.source_url AS sourceUrl FROM nutrition_foods f JOIN nutrition_datasets d ON d.id=f.dataset_id WHERE f.id=?'
      )
      .get(parsed.foodId) as Omit<(typeof sources)[number], 'note'>;
    if (!sources.some((s) => s.foodId === source.foodId))
      sources.push({
        ...source,
        note: 'Automatische exakte Alias-Zuordnung, explizite metrische Masse; generischer Referenzwert.',
      });
  }
  if (!Object.keys(totals).length) return null;
  const date = db
    .query(
      `SELECT MAX(d.retrieved_on) AS day FROM nutrition_datasets d JOIN nutrition_foods f ON f.dataset_id=d.id WHERE f.id IN (SELECT value FROM json_each(?))`
    )
    .get(JSON.stringify(sources.map((s) => s.foodId))) as { day: string };
  return {
    recipeId,
    basis: 'per_serving',
    quality: 'estimated',
    sourceUrl: sources[0]?.sourceUrl ?? 'https://blsdb.de/download',
    reviewedAt: date.day,
    nutrients: totals,
    calculation: {
      totalLines: ingredients.length,
      knownLines,
      coverage,
      missing,
      sources,
      warnings: [
        'Automatische Archiv-Teilanalyse: nur explizite g/kg und freigegebene exakte Lebensmittel-Aliasse.',
        'Keine Gar-/Retentionskorrektur; unerkannte Mengen und Zutaten fehlen in der Summe.',
      ],
    },
  };
}
