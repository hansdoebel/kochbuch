import { Database } from 'bun:sqlite';
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, mkdirSync, statSync } from 'node:fs';
import { resolve, join, sep } from 'node:path';
import { z } from 'zod';
import {
  nutritionFiles,
  loadNutrition,
  calculatedProfile,
  readFoodAliases,
  archiveProfile,
} from './nutrition';
import type { Recipe, RecipeSummary, Ingredient, NutritionProfile } from '../lib/types';

export const REPO_ROOT = resolve(import.meta.dir, '../../..');
const nutrientKeys = [
  'energy_kcal',
  'protein_g',
  'carbs_g',
  'fiber_g',
  'fat_g',
  'sugar_g',
  'saturated_fat_g',
  'sodium_mg',
  'calcium_mg',
  'iron_mg',
  'magnesium_mg',
  'potassium_mg',
  'zinc_mg',
  'vitamin_b12_ug',
  'vitamin_d_ug',
  'folate_ug',
  'iodine_ug',
  'selenium_ug',
] as const;
const nutritionSchema = z.object({
  version: z.literal(1),
  profiles: z.array(
    z.object({
      recipeId: z.string().min(1),
      basis: z.literal('per_serving'),
      quality: z.enum(['estimated', 'verified']),
      sourceUrl: z.url().refine((v) => v.startsWith('https://')),
      reviewedAt: z.iso.date(),
      nutrients: z
        .object(
          Object.fromEntries(
            nutrientKeys.map((k) => [k, z.number().finite().nonnegative().nullable().optional()])
          )
        )
        .strict()
        .refine(
          (n) => Object.values(n).some((v) => typeof v === 'number'),
          'At least one known nutrient is required'
        ),
    })
  ),
});
export function readProfiles(root = REPO_ROOT): Map<string, NutritionProfile> {
  const parsed = nutritionSchema.parse(
    JSON.parse(readFileSync(join(root, 'nutrition/recipe-profiles.json'), 'utf8'))
  );
  const result = new Map<string, NutritionProfile>();
  for (const profile of parsed.profiles) {
    if (result.has(profile.recipeId))
      throw new Error(`Duplicate nutrition profile: ${profile.recipeId}`);
    result.set(profile.recipeId, profile as NutritionProfile);
  }
  return result;
}
const urlIn = (text: string) => text.match(/https?:\/\/[^\s]+/)?.[0] ?? null;
const minuteCount = (value: unknown): number | null => {
  const m = String(value ?? '').match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  return m ? Number(m[1] ?? 0) * 60 + Number(m[2] ?? 0) + Number(m[3] ?? 0) / 60 : null;
};
export function servingCount(value: unknown): number | null {
  if (Array.isArray(value)) return servingCount(value[0]);
  const m = String(value ?? '')
    .trim()
    .match(/^(\d+)(?:\s+(?:servings?|people|portions?|personen|portionen))?$/i);
  return m && Number(m[1]) > 0 ? Number(m[1]) : null;
}
function collectFiles(root: string): string[] {
  const files = ['db/schema.sql', 'db/seed.sql', 'nutrition/recipe-profiles.json'].map((f) =>
    join(root, f)
  );
  files.push(...nutritionFiles(root));
  files.push(
    ...readdirSync(join(root, 'rezepte'))
      .filter((f) => f.endsWith('.md'))
      .map((f) => join(root, 'rezepte', f))
  );
  for (const dir of readdirSync(join(root, 'quellen'), { withFileTypes: true }))
    if (dir.isDirectory()) {
      const manifest = join(root, 'quellen', dir.name, 'manifest.json');
      files.push(manifest);
      const data = JSON.parse(readFileSync(manifest, 'utf8'));
      if (data.completed === false) throw new Error(`Archive is still being scraped: ${dir.name}`);
      for (const page of data.pages)
        if (page.file) {
          if (page.file !== page.file.split(/[\\/]/).pop())
            throw new Error('Invalid archive filename');
          files.push(join(root, 'quellen', dir.name, page.file));
        }
    }
  return files.sort();
}
export class Catalog {
  db: Database;
  nutritionDB: Database;
  constructor(
    public root = REPO_ROOT,
    cache = true
  ) {
    const seed = new Database(':memory:');
    seed.exec('PRAGMA foreign_keys=ON');
    seed.exec(readFileSync(join(root, 'db/schema.sql'), 'utf8'));
    seed.exec(readFileSync(join(root, 'db/seed.sql'), 'utf8'));
    loadNutrition(seed, root);
    this.nutritionDB = seed;
    const files = collectFiles(root);
    const fingerprint = createHash('sha256')
      .update('web-catalog-v4-nutrition')
      .update(
        files
          .map((f) => {
            const s = statSync(f);
            return `${f}:${s.size}:${s.mtimeMs}`;
          })
          .join('|')
      )
      .digest('hex');
    if (cache) mkdirSync(join(root, '.cache'), { recursive: true });
    this.db = new Database(cache ? join(root, '.cache/web.sqlite') : ':memory:');
    this.db.run('PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;');
    this.db.run('CREATE TABLE IF NOT EXISTS cache_meta (key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    if (
      this.db.query('SELECT value FROM cache_meta WHERE key = ?').get('fingerprint') &&
      (
        this.db.query('SELECT value FROM cache_meta WHERE key = ?').get('fingerprint') as {
          value: string;
        }
      ).value === fingerprint
    )
      return;
    const profiles = readProfiles(root);
    const aliases = readFoodAliases(seed, root);

    this.db.transaction(() => {
      this.db.run('DROP TABLE IF EXISTS search; DROP TABLE IF EXISTS cards;');
      this.db.run(
        'CREATE TABLE cards (id TEXT PRIMARY KEY,title TEXT NOT NULL,source TEXT NOT NULL,ready INTEGER NOT NULL,minutes REAL,summary TEXT NOT NULL,detail TEXT NOT NULL); CREATE INDEX cards_source ON cards(source,ready,title); CREATE VIRTUAL TABLE search USING fts5(id UNINDEXED,title,ingredients,source,tokenize="unicode61 remove_diacritics 2",prefix="2 3 4");'
      );
      const insert = this.db.query('INSERT INTO cards VALUES (?,?,?,?,?,?,?)');
      const fts = this.db.query('INSERT INTO search VALUES (?,?,?,?)');
      const add = (r: Recipe) => {
        const {
          authors,
          ingredients,
          structuredIngredients,
          instructions,
          notes,
          nutrition,
          ...summary
        } = r;
        insert.run(
          r.id,
          r.title,
          r.source,
          Number(r.ready),
          r.minutes,
          JSON.stringify(summary),
          JSON.stringify(r)
        );
        fts.run(r.id, r.title, r.ingredients.join(' '), r.source);
      };
      const curatedUrls = new Set<string>();
      const curated = seed.query('SELECT * FROM recipes ORDER BY id').all() as any[];
      for (const row of curated) {
        const md = readFileSync(join(root, 'rezepte', row.slug + '.md'), 'utf8');
        const body = md.split('---').slice(2).join('---');
        const instructions = [
          ...body
            .split('## Zubereitung')[1]
            .split('## Tipps')[0]
            .matchAll(/^\d+\. (.+)$/gm),
        ].map((m) => m[1]);
        const notes = [...body.split('## Tipps')[1].matchAll(/^- (.+)$/gm)].map((m) => m[1]);
        const rows = seed
          .query(
            'SELECT ri.*,i.name,i.pantry_staple,u.code,c.name AS category FROM recipe_ingredients ri JOIN ingredients i ON i.id=ri.ingredient_id LEFT JOIN units u ON u.id=ri.unit_id JOIN shopping_categories c ON c.id=i.category_id WHERE recipe_id=? ORDER BY ri.sort_order'
          )
          .all(row.id) as any[];
        const structured: Ingredient[] = rows.map((i) => ({
          name: i.name,
          text:
            i.amount_text ??
            `${i.quantity ?? ''} ${i.code ?? ''} ${i.name}${i.variant ? ' (' + i.variant + ')' : ''}`.trim(),
          quantity: i.quantity,
          unit: i.code,
          group: i.ingredient_group,
          category: i.category,
          pantry: !!i.pantry_staple,
          optional: !!i.optional,
          variant: i.variant,
          ingredientId: i.ingredient_id,
        }));
        const sourceUrl = urlIn(row.source ?? '');
        if (sourceUrl) curatedUrls.add(sourceUrl);
        const id = 'ready:' + row.slug;
        const nutrition = profiles.get(id) ?? calculatedProfile(seed, row.id, row.slug);
        const host = sourceUrl ? new URL(sourceUrl).hostname.replace(/^www\./, '') : null;
        const publisher =
          host === 'rainbowplantlife.com' ? 'Rainbow Plant Life' : (host ?? row.source);
        add({
          authors: [
            String(row.source)
              .split('http')[0]
              .replace(/[ –-]+$/, ''),
          ],
          id,
          title: row.title,
          source: publisher,
          sourceUrl,
          ready: true,
          servings: row.servings,
          servingsText: `${row.servings} ${row.servings_label}`,
          minutes: row.prep_minutes + row.cook_minutes,
          ingredientCount: rows.length,
          language: 'de',
          hasNutrition: !!nutrition,
          missingFields: [],
          tags: (
            seed
              .query(
                'SELECT t.name FROM tags t JOIN recipe_tags rt ON rt.tag_id=t.id WHERE rt.recipe_id=?'
              )
              .all(row.id) as { name: string }[]
          ).map((t) => t.name),
          ingredients: structured.map((i) => i.text),
          structuredIngredients: structured,
          instructions,
          notes,
          nutrition,
        });
      }
      for (const file of files.filter(
        (f) =>
          f.endsWith('.json') &&
          !f.endsWith('manifest.json') &&
          f.startsWith(join(root, 'quellen') + sep)
      )) {
        const data = JSON.parse(readFileSync(file, 'utf8'));
        if (curatedUrls.has(data.source_url)) continue;
        for (const card of data.recipes) {
          const id =
            'archive:' +
            createHash('sha256')
              .update(data.source_url + '#' + (card.recipe_id || card.name))
              .digest('hex')
              .slice(0, 24);
          if (this.db.query('SELECT id FROM cards WHERE id=?').get(id)) continue;
          const nutrition =
            profiles.get(id) ??
            archiveProfile(seed, id, card.ingredients, servingCount(card.yield), aliases);
          add({
            authors: card.authors ?? [],
            id,
            title: card.name || 'Ohne Titel',
            source: card.publisher,
            sourceUrl: data.source_url,
            ready: false,
            servings: servingCount(card.yield),
            servingsText: Array.isArray(card.yield)
              ? card.yield.join(' · ')
              : String(card.yield ?? 'Portionen nicht angegeben'),
            minutes: minuteCount(card.total_time),
            ingredientCount: card.ingredients.length,
            language: card.language ?? 'en',
            hasNutrition: !!nutrition,
            missingFields: card.missing_fields ?? [],
            tags: [],
            ingredients: card.ingredients,
            structuredIngredients: [],
            instructions: card.instructions,
            notes: [...(data.page_recipe_notes ?? []), ...(data.extraction_warnings ?? [])],
            nutrition,
          });
        }
      }
      for (const id of profiles.keys())
        if (!this.db.query('SELECT id FROM cards WHERE id=?').get(id))
          throw new Error(`Nutrition profile refers to unknown recipe: ${id}`);
      this.db
        .query('INSERT OR REPLACE INTO cache_meta VALUES (?,?)')
        .run('fingerprint', fingerprint);
    })();
  }
  readyRecipes(): Recipe[] {
    return (
      this.db.query('SELECT detail FROM cards WHERE ready=1 ORDER BY id').all() as {
        detail: string;
      }[]
    ).map((r) => JSON.parse(r.detail));
  }
  get(id: string): Recipe | null {
    const row = this.db.query('SELECT detail FROM cards WHERE id=?').get(id) as {
      detail: string;
    } | null;
    return row ? JSON.parse(row.detail) : null;
  }
  search(
    options: { q?: string; source?: string; ready?: boolean; offset?: number; limit?: number } = {}
  ) {
    const tokens =
      (options.q ?? '')
        .normalize('NFKC')
        .match(/[\p{L}\p{N}]+/gu)
        ?.slice(0, 12) ?? [];
    const clauses: string[] = [];
    const args: (string | number)[] = [];
    if (tokens.length) {
      clauses.push('search MATCH ?');
      args.push(tokens.map((t) => '"' + t + '"*').join(' AND '));
    }
    if (options.source) {
      clauses.push('c.source=?');
      args.push(options.source);
    }
    if (options.ready) {
      clauses.push('c.ready=1');
    }
    const from = tokens.length ? 'cards c JOIN search ON c.id=search.id' : 'cards c';
    const where = clauses.length ? ' WHERE ' + clauses.join(' AND ') : '';
    const count = (
      this.db.query(`SELECT count(*) AS n FROM ${from}${where}`).get(...args) as { n: number }
    ).n;
    const order = tokens.length
      ? 'c.ready DESC,bm25(search,0,10,3,1),c.title'
      : 'c.ready DESC,c.title COLLATE NOCASE';
    const items = (
      this.db
        .query(`SELECT c.summary FROM ${from}${where} ORDER BY ${order} LIMIT ? OFFSET ?`)
        .all(
          ...args,
          Math.min(60, Math.max(1, options.limit ?? 30)),
          Math.max(0, options.offset ?? 0)
        ) as { summary: string }[]
    ).map((r) => JSON.parse(r.summary) as RecipeSummary);
    return { items, total: count };
  }
  meta() {
    const count = (this.db.query('SELECT count(*) n FROM cards').get() as { n: number }).n;
    const readyCount = (
      this.db.query('SELECT count(*) n FROM cards WHERE ready=1').get() as { n: number }
    ).n;
    const nutritionCount = (
      this.db
        .query("SELECT count(*) n FROM cards WHERE json_extract(summary,'$.hasNutrition')=1")
        .get() as { n: number }
    ).n;
    const sources = this.db
      .query(
        'SELECT source AS name,count(*) AS count FROM cards GROUP BY source ORDER BY count DESC'
      )
      .all() as { name: string; count: number }[];
    return { count, readyCount, nutritionCount, sources };
  }
  close() {
    this.db.close();
    this.nutritionDB.close();
  }
}
