import { beforeAll, afterAll, describe, test, expect } from 'bun:test';
import { Catalog } from '../src/server/catalog';
import {
  snapshotSchema,
  nutritionFoods,
  nutritionStatus,
  parseMetricIngredient,
  archiveProfile,
  calculatedProfile,
} from '../src/server/nutrition';
import { createApp } from '../src/server/app';
import { suggestPlan } from '../src/server/planner';
import { analyse, shoppingList } from '../src/server/shopping';
import type { Recipe } from '../src/lib/types';
import { Database } from 'bun:sqlite';
import { readFileSync } from 'node:fs';
let catalog: Catalog;
beforeAll(() => (catalog = new Catalog(undefined, false)));
afterAll(() => catalog.close());
describe('BLS reference database', () => {
  test('imports all foods and preserves units, provenance, true zeros and detection limits', () => {
    const db = catalog.nutritionDB,
      status = nutritionStatus(db);
    expect(status.foodCount).toBe(7140);
    expect(status.factCount).toBe(7140 * 17);
    expect(status.matchedIngredients).toBeGreaterThan(30);
    const oats = nutritionFoods(db, 'C133000').items[0];
    expect(oats.name).toBe('Hafer Flocken');
    const fact = db
      .query('SELECT * FROM nutrition_facts WHERE food_id=? AND nutrient_code=?')
      .get('bls-4.0:C133000', 'protein_g') as any;
    expect(fact.amount_per_100g).toBe(13.22);
    expect(fact.derivation).toBe('Analyse');
    expect(fact.source_nutrient_code).toBe('PROT625');
    expect(
      (
        db
          .query(
            'SELECT COUNT(*) n FROM nutrition_facts WHERE qualifier IS NOT NULL AND amount_per_100g IS NOT NULL'
          )
          .get() as any
      ).n
    ).toBe(0);
    expect(
      (
        db
          .query(
            'SELECT COUNT(*) n FROM nutrition_facts WHERE qualifier=? AND amount_per_100g IS NULL'
          )
          .get('TR') as any
      ).n
    ).toBeGreaterThan(0);
    expect(
      (db.query('SELECT COUNT(*) n FROM nutrition_facts WHERE amount_per_100g=0').get() as any).n
    ).toBeGreaterThan(0);
    expect(nutritionFoods(db, '%%%%').total).toBe(0); // LIKE wildcards are literal
    expect(nutritionFoods(db, '').items.length).toBe(25);
  });
  test('rejects duplicate foods, corrupt provenance and qualified numeric values', () => {
    const valid = {
      version: 1,
      dataset: {
        id: 'test',
        publisher: 'test',
        version: '1',
        source_url: 'https://example.org',
        license: 'CC0',
        citation: 'test',
        retrieved_on: '2026-11-19',
        sha256: 'a'.repeat(64),
        expected_food_count: 1,
      },
      nutrients: [{ code: 'protein_g', name: 'Protein', unit: 'g', source_code: 'P' }],
      origins: ['Analysed'],
      references: [],
      foods: [{ code: 'A', name: 'Food', name_en: null, facts: [[0, 0, null, null]] }],
    };
    expect(snapshotSchema.safeParse(valid).success).toBe(true);
    for (const facts of [[[0, 4, null, null]], [[0, 0, null, 'TR']], [[-1, 0, null, null]]])
      expect(
        snapshotSchema.safeParse({ ...valid, foods: [{ ...valid.foods[0], facts }] }).success
      ).toBe(false);
    expect(
      snapshotSchema.safeParse({ ...valid, foods: [valid.foods[0], valid.foods[0]] }).success
    ).toBe(false);
  });
  test('per-serving arithmetic preserves uncovered weights and nutrient coverage', () => {
    const db = new Database(':memory:');
    db.exec('PRAGMA foreign_keys=ON');
    db.exec(readFileSync('../db/schema.sql', 'utf8'));
    db.exec(
      `INSERT INTO shopping_categories VALUES (1,'Food',1);INSERT INTO units VALUES (1,'g','g','mass','g',1);INSERT INTO ingredients VALUES (1,'A',1,1,0),(2,'B',1,1,0);INSERT INTO recipes VALUES (1,'test','Test',2,'Portionen',1,1,NULL,NULL);INSERT INTO recipe_ingredients VALUES (1,1,1,200,1,NULL,NULL,'Food',NULL,0,1),(2,1,2,NULL,NULL,'Unbekannt',NULL,'Food',NULL,0,2);INSERT INTO nutrition_datasets VALUES ('test','test','1','https://example.org','CC0','test','2026-11-19','${'a'.repeat(64)}');INSERT INTO nutrition_nutrients VALUES ('protein_g','Protein','g','P');INSERT INTO nutrition_foods VALUES ('test:A','test','A','A',NULL,'https://example.org');INSERT INTO nutrition_facts VALUES ('test:A','protein_g',10,'Analyse',NULL,NULL,'P');INSERT INTO ingredient_nutrition_matches VALUES (1,'test:A','reviewed','2026-11-19','Reviewed');`
    );
    const p = calculatedProfile(db, 1, 'test')!;
    expect(p.nutrients.protein_g).toBe(10);
    expect(p.calculation?.coverage.protein_g).toEqual({ known: 1, total: 2 });
    expect(p.calculation?.missing[0].ingredient).toBe('B');
    const r = { ...catalog.get('ready:kaiserschmarrn')!, id: 'ready:test', nutrition: p };
    const result = analyse([{ id: r.id, servings: 3 }], () => r);
    expect(result.totals.protein_g).toBe(30);
    expect(result.completeCoverage.protein_g ?? 0).toBe(0);
    expect(result.partialRecipes).toEqual([r.title]);
    db.close();
  });
});
describe('conservative automatic archive analysis', () => {
  const aliases = new Map([['rolled oats', 'bls-4.0:C133000']]);
  test('only explicit metric masses and exact approved aliases are used', () => {
    expect(parseMetricIngredient('200 g rolled oats, finely ground', aliases)?.grams).toBe(200);
    expect(parseMetricIngredient('0.2 kg rolled oats', aliases)?.grams).toBe(200);
    for (const line of [
      '1 cup rolled oats',
      '100–200 g rolled oats',
      '100-200 g rolled oats',
      '~200 g rolled oats',
      '1,000 g rolled oats',
      '200 g cooked oats',
      '200 g rolled oats, cooked',
      '200 g rolled oats or flour',
      '200 g rolled oats (optional)',
    ])
      expect(parseMetricIngredient(line, aliases)).toBeNull();
    const profile = archiveProfile(
      catalog.nutritionDB,
      'test',
      ['200 g rolled oats', '1 cup milk'],
      2,
      aliases
    )!;
    expect(profile.nutrients.protein_g).toBeCloseTo(13.22);
    expect(profile.calculation?.coverage.protein_g).toEqual({ known: 1, total: 2 });
    expect(profile.calculation?.missing.length).toBe(1);
    expect(
      archiveProfile(catalog.nutritionDB, 'test', ['200 g rolled oats'], null, aliases)
    ).toBeNull();
  });
});
describe('weekly planning', () => {
  test('respects filters, repeat limits, dates and combines the shopping selection', () => {
    const plan = suggestPlan(
      { startDate: '2026-12-29', days: 7, servings: 2, vegan: true, maxMinutes: 120 },
      catalog.readyRecipes()
    );
    expect(plan.entries.length).toBe(7);
    expect(plan.entries.at(-1)?.date).toBe('2027-01-04');
    for (const entry of plan.entries) {
      expect(catalog.get(entry.id)!.tags).toContain('Vegan');
      expect(plan.entries.filter((e) => e.id === entry.id).length).toBeLessThanOrEqual(3);
    }
    expect(plan.selections.reduce((n, s) => n + s.servings, 0)).toBe(14);
    expect(shoppingList(plan.selections, (id) => catalog.get(id)).itemCount).toBeGreaterThan(0);
    expect(
      suggestPlan({ startDate: '2026-11-19', maxMinutes: 1 }, catalog.readyRecipes()).entries
    ).toHaveLength(0);
    expect(() => suggestPlan({ startDate: '2026-99-99' }, [])).toThrow();
  });
  test('does not optimise goals against incomplete lower bounds', () => {
    const base = catalog.get('ready:kaiserschmarrn')!;
    const make = (id: string, energy: number, known: number): Recipe => ({
      ...base,
      tags: ['Hauptgericht'],
      id,
      nutrition: {
        recipeId: id,
        basis: 'per_serving',
        quality: 'estimated',
        sourceUrl: 'https://example.org',
        reviewedAt: '2026-11-19',
        nutrients: { energy_kcal: energy },
        calculation: {
          totalLines: 2,
          knownLines: known,
          coverage: { energy_kcal: { known, total: 2 } },
          missing: [],
          sources: [],
          warnings: [],
        },
      },
    });
    const plan = suggestPlan(
      { startDate: '2026-11-19', days: 1, servings: 2, targetsPerMeal: { energy_kcal: 1000 } },
      [make('incomplete', 500, 1), make('complete', 500, 2)]
    );
    expect(plan.entries[0].id).toBe('complete');
    expect(plan.entries[0].nutritionUsed).toBe(true);
    const incomplete = suggestPlan(
      { startDate: '2026-11-19', days: 1, targetsPerMeal: { energy_kcal: 500 } },
      [make('incomplete', 500, 1)]
    );
    expect(incomplete.entries[0].nutritionUsed).toBe(false);
    expect(incomplete.warnings.join(' ')).toContain('Unvollständige');
  });
  test('food API and planner validate inputs and origins', async () => {
    const app = createApp(catalog);
    const response = await app(new Request('http://localhost/api/nutrition/foods?q=C133000'));
    expect((await response.json()).total).toBe(1);
    expect((await app(new Request('http://localhost/api/nutrition/foods?offset=-1'))).status).toBe(
      400
    );
    const request = (body: unknown, origin?: string) =>
      new Request('http://localhost/api/plan/suggest', {
        method: 'POST',
        body: JSON.stringify(body),
        headers: origin ? { origin } : undefined,
      });
    expect((await app(request({ startDate: '2026-11-19', days: 8 }))).status).toBe(400);
    expect((await app(request({ startDate: '2026-11-19' }, 'https://evil.example'))).status).toBe(
      403
    );
    const plan = await (await app(request({ startDate: '2026-11-19' }))).json();
    expect(plan.entries.length).toBeGreaterThan(0);
  });
});
