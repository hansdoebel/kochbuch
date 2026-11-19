import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { Catalog, servingCount, readProfiles } from '../src/server/catalog';
import { shoppingList, analyse } from '../src/server/shopping';
import { createApp } from '../src/server/app';
import { typstSource, pdfExport, typstBinary } from '../src/server/export';
import type { Recipe } from '../src/lib/types';
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { mkdir } from 'node:fs/promises';
import { gzipSync, gunzipSync } from 'node:zlib';

let catalog: Catalog;
beforeAll(() => {
  catalog = new Catalog(undefined, false);
});
afterAll(() => catalog.close());
describe('catalog and indexed search', () => {
  test('reads curated recipes and available archives without duplicate canonical sources', () => {
    const meta = catalog.meta();
    expect(meta.count).toBeGreaterThan(1700);
    expect(meta.readyCount).toBeGreaterThanOrEqual(6);
    expect(meta.nutritionCount).toBe(readProfiles().size);
    expect(catalog.search({ q: 'linsen', ready: true }).items.map((r) => r.id)).toContain(
      'ready:rotes-linsen-curry'
    );
    expect(
      catalog
        .search({ source: 'Rainbow Plant Life', q: 'curry' })
        .items.every((r) => r.source === 'Rainbow Plant Life')
    ).toBe(true);
  });
  test('search handles quotes, punctuation and literal operators safely', () => {
    expect(() => catalog.search({ q: '" OR * - NOT \' ; DROP TABLE cards; --' })).not.toThrow();
    expect(catalog.search({ q: 'olivenol', ready: true }).total).toBeGreaterThan(0);
    expect(catalog.search({ limit: 10000 }).items.length).toBe(60);
  });
  test('does not pretend ranges or unknown yield text are exact servings', () => {
    expect(servingCount('3 to 4')).toBeNull();
    expect(servingCount('4 servings')).toBe(4);
    expect(servingCount('1-2 servings worth')).toBeNull();
  });
});
describe('shopping arithmetic', () => {
  test('scales exact amounts, sums repeated ingredients, preserves g vs ml', () => {
    const list = shoppingList([{ id: 'ready:kaiserschmarrn', servings: 4 }], (id) =>
      catalog.get(id)
    );
    const items = list.groups.flatMap((g) => g.items);
    expect(items.find((i) => i.text.includes('Feinkristallzucker'))?.quantity).toBe(160);
    expect(items.find((i) => i.text.endsWith('Milch'))?.unit).toBe('g');
    expect(items.find((i) => i.text.includes('Zitrone'))?.quantity).toBe(1);
  });
  test('pantry and optional filters are explicit', () => {
    const list = shoppingList(
      [{ id: 'ready:rotes-linsen-curry', servings: 4 }],
      (id) => catalog.get(id),
      { hidePantry: true, includeOptional: false }
    );
    const text = list.groups
      .flatMap((g) => g.items)
      .map((i) => i.text)
      .join(' ');
    expect(text).not.toContain('Serrano');
    expect(text).not.toContain('Kreuzkümmel');
    expect(text).toContain('Linsen');
    const ginger = list.groups.flatMap((g) => g.items).find((i) => i.text.includes('Ingwer'))!;
    expect(ginger.text).toContain('Originalmenge, nicht skaliert');
    expect(ginger.text).not.toContain('nach Bedarf');
  });
  test('archive ingredients stay unchanged rather than receiving invented scaling', () => {
    const archived = catalog.search({ q: 'lentil' }).items.find((r) => !r.ready)!;
    const recipe = catalog.get(archived.id)!;
    const list = shoppingList([{ id: archived.id, servings: 99 }], (id) => catalog.get(id));
    expect(list.unscaledRecipes).toEqual([recipe.title]);
    expect(list.groups.flatMap((g) => g.items).map((i) => i.text)).toEqual(recipe.ingredients);
  });
  test('rejects duplicate, invalid and unknown selections', () => {
    expect(() =>
      shoppingList([{ id: 'ready:kaiserschmarrn', servings: 0 }], (id) => catalog.get(id))
    ).toThrow();
    expect(() => shoppingList([{ id: 'none', servings: 1 }], (id) => catalog.get(id))).toThrow();
    expect(() =>
      shoppingList(
        [
          { id: 'ready:kaiserschmarrn', servings: 1 },
          { id: 'ready:kaiserschmarrn', servings: 2 },
        ],
        (id) => catalog.get(id)
      )
    ).toThrow();
  });
});
describe('nutrition honesty', () => {
  test('profiles require units, citations, dates and real known values', async () => {
    const folder = await mkdtemp(join(tmpdir(), 'kochbuch-nutrition-test-'));
    try {
      await mkdir(join(folder, 'nutrition'));
      const profile = {
        recipeId: 'test',
        basis: 'per_serving',
        quality: 'verified',
        sourceUrl: 'https://example.org/food/1',
        reviewedAt: '2026-11-19',
        nutrients: { protein_g: 0 },
      };
      const write = async (p: unknown) =>
        writeFile(
          join(folder, 'nutrition/recipe-profiles.json'),
          JSON.stringify({ version: 1, profiles: [p] })
        );
      await write(profile);
      expect(readProfiles(folder).get('test')?.nutrients.protein_g).toBe(0);
      for (const invalid of [
        { ...profile, sourceUrl: 'javascript:evil' },
        { ...profile, reviewedAt: '2026-99-99' },
        { ...profile, nutrients: { protein_g: -1 } },
        { ...profile, nutrients: { protein_mg: 10 } },
        { ...profile, nutrients: { protein_g: null } },
      ]) {
        await write(invalid);
        expect(() => readProfiles(folder)).toThrow();
      }
    } finally {
      await rm(folder, { recursive: true, force: true });
    }
  });
  test('missing values remain unknown, while genuine zero remains zero', () => {
    const recipe: Recipe = { ...catalog.get('ready:rotes-linsen-curry')!, nutrition: null };
    expect(
      analyse([{ id: recipe.id, servings: 2 }], () => recipe).totals.protein_g
    ).toBeUndefined();
    const profiled: Recipe = {
      ...recipe,
      nutrition: {
        recipeId: recipe.id,
        basis: 'per_serving',
        quality: 'estimated',
        sourceUrl: 'https://example.org/food/123',
        reviewedAt: '2026-11-19',
        nutrients: { protein_g: 10, fiber_g: 0, vitamin_b12_ug: null },
      },
    };
    const result = analyse([{ id: recipe.id, servings: 2 }], () => profiled);
    expect(result.totals.protein_g).toBe(20);
    expect(result.totals.fiber_g).toBe(0);
    expect(result.totals.vitamin_b12_ug).toBeUndefined();
    expect(result.verifiedCount).toBe(0);
  });
  test('partial analysis reports coverage per nutrient', () => {
    const r: Recipe = { ...catalog.get('ready:kaiserschmarrn')!, nutrition: null };
    const profiled: Recipe = {
      ...r,
      id: 'profiled',
      nutrition: {
        recipeId: 'profiled',
        basis: 'per_serving',
        quality: 'verified',
        sourceUrl: 'https://example.org/food/123',
        reviewedAt: '2026-11-19',
        nutrients: { energy_kcal: 120 },
      },
    };
    const result = analyse(
      [
        { id: r.id, servings: 1 },
        { id: 'profiled', servings: 2 },
      ],
      (id) => (id === 'profiled' ? profiled : r)
    );
    expect(result.totals.energy_kcal).toBe(240);
    expect(result.coverage.energy_kcal).toBe(1);
    expect(result.selectedCount).toBe(2);
    expect(result.missingRecipes).toEqual([r.title]);
  });
});
describe('HTTP routes', () => {
  test('serves precompressed assets with correct content type and cache headers', async () => {
    const folder = await mkdtemp(join(tmpdir(), 'kochbuch-assets-test-'));
    try {
      await mkdir(join(folder, 'assets'));
      await writeFile(join(folder, 'assets/test.js'), 'console.log("ok")');
      await writeFile(join(folder, 'assets/test.js.gz'), gzipSync('console.log("ok")'));
      const response = await createApp(
        catalog,
        folder
      )(new Request('http://localhost/assets/test.js', { headers: { 'accept-encoding': 'gzip' } }));
      expect(response.headers.get('content-encoding')).toBe('gzip');
      expect(response.headers.get('content-type')).toContain('javascript');
      expect(response.headers.get('cache-control')).toContain('immutable');
      expect(gunzipSync(await response.arrayBuffer()).toString()).toBe('console.log("ok")');
    } finally {
      await rm(folder, { recursive: true, force: true });
    }
  });
  test('serves bounded summaries, details and list JSON', async () => {
    const app = createApp(catalog);
    const meta = await app(new Request('http://localhost/api/meta'));
    expect(meta.status).toBe(200);
    const result = await (await app(new Request('http://localhost/api/recipes?q=curry'))).json();
    expect(result.items.length).toBeLessThanOrEqual(30);
    expect(result.items[0]).not.toHaveProperty('instructions');
    const detail = await app(
      new Request('http://localhost/api/recipes/' + encodeURIComponent('ready:kaiserschmarrn'))
    );
    expect((await detail.json()).authors.length).toBeGreaterThan(0);
    const response = await app(
      new Request('http://localhost/api/shopping', {
        method: 'POST',
        body: JSON.stringify({ selections: [{ id: 'ready:kaiserschmarrn', servings: 2 }] }),
      })
    );
    expect((await response.json()).itemCount).toBeGreaterThan(0);
  });
  test('rejects cross-origin exports, malformed bodies and invalid pagination', async () => {
    const app = createApp(catalog);
    expect(
      (
        await app(
          new Request('http://localhost/api/export', {
            method: 'POST',
            headers: { origin: 'https://evil.example' },
            body: '{}',
          })
        )
      ).status
    ).toBe(403);
    expect(
      (await app(new Request('http://localhost/api/shopping', { method: 'POST', body: 'wrong' })))
        .status
    ).toBe(400);
    expect((await app(new Request('http://localhost/api/recipes?offset=NaN'))).status).toBe(400);
  });
});
describe('Typst export', () => {
  test('source embeds JSON as bytes so recipe text cannot become Typst code', () => {
    const list = shoppingList([{ id: 'ready:kaiserschmarrn', servings: 2 }], (id) =>
      catalog.get(id)
    );
    list.groups[0].items[0].text = '#read("/etc/passwd") [injection]';
    const source = typstSource(list);
    expect(source).not.toContain('#read');
    expect(source).toStartWith('#let data = json(bytes((');
  });
  test.skipIf(!typstBinary())(
    'compiles mobile PDF and downloadable standalone template',
    async () => {
      const list = shoppingList([{ id: 'ready:kaiserschmarrn', servings: 2 }], (id) =>
        catalog.get(id)
      );
      const pdf = await pdfExport(list);
      expect(new TextDecoder().decode(pdf.slice(0, 5))).toBe('%PDF-');
      const folder = await mkdtemp(join(tmpdir(), 'kochbuch-typst-test-'));
      try {
        await writeFile(join(folder, 'list.typ'), typstSource(list));
        const child = Bun.spawn(
          [
            typstBinary()!,
            'compile',
            '--root',
            folder,
            join(folder, 'list.typ'),
            join(folder, 'list.pdf'),
          ],
          { stderr: 'pipe' }
        );
        const stderr = await new Response(child.stderr).text();
        expect(await child.exited, stderr).toBe(0);
        expect((await readFile(join(folder, 'list.pdf'))).byteLength).toBeGreaterThan(1000);
      } finally {
        await rm(folder, { recursive: true, force: true });
      }
    }
  );
});
