<script lang="ts">
  import { Card } from '$lib/components/ui/card';
  import { Input } from '$lib/components/ui/input';
  import { Button } from '$lib/components/ui/button';
  import { api } from '$lib/client';
  type Fact = {
    code: string;
    name: string;
    unit: string;
    amount_per_100g: number | null;
    derivation: string | null;
    reference: string | null;
    qualifier: string | null;
  };
  type Food = {
    id: string;
    source_food_code: string;
    name: string;
    name_en: string | null;
    source_url: string;
    citation: string;
    license: string;
    nutrients: Fact[];
  };
  type Status = {
    foodCount: number;
    factCount: number;
    matchedIngredients: number;
    ingredientCount: number;
    unresolved: { name: string; recipeCount: number }[];
    datasets: { citation: string; license: string; source_url: string }[];
  };
  let query = $state(''),
    offset = $state(0),
    result = $state<{ items: Food[]; total: number }>({ items: [], total: 0 }),
    status = $state<Status | null>(null),
    error = $state(''),
    busy = $state(false),
    selected = $state<Food | null>(null);
  const fmt = (n: number) => new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 }).format(n);
  const value = (food: Food, key: string) => {
    const f = food.nutrients.find((n) => n.code === key);
    return f?.amount_per_100g === null || f?.amount_per_100g === undefined
      ? '—'
      : fmt(f.amount_per_100g);
  };
  $effect(() => {
    const c = new AbortController();
    api<Status>('/api/nutrition/status', undefined, c.signal)
      .then((s) => (status = s))
      .catch((e) => {
        if (e.name !== 'AbortError') error = e.message;
      });
    return () => c.abort();
  });
  $effect(() => {
    const q = query,
      page = offset;
    const c = new AbortController();
    busy = true;
    error = '';
    const timer = setTimeout(
      () =>
        api<typeof result>(
          '/api/nutrition/foods?q=' + encodeURIComponent(q) + '&offset=' + page,
          undefined,
          c.signal
        )
          .then((r) => (result = r))
          .catch((e) => {
            if (e.name !== 'AbortError') error = e.message;
          })
          .finally(() => {
            if (!c.signal.aborted) busy = false;
          }),
      140
    );
    return () => {
      clearTimeout(timer);
      c.abort();
    };
  });
</script>

<Card class="analytics-card nutrition-database">
  <h2>Lebensmittel &amp; Nährwertdatenbank</h2>
  <p class="muted-copy">
    {status?.foodCount ?? '…'} Lebensmittel · {status?.factCount ?? '…'} Nährwertangaben · {status?.matchedIngredients ??
      0}/{status?.ingredientCount ?? 0} Kochbuch-Zutaten zugeordnet.
  </p>
  <p class="notice">
    Alle Werte je 100 g essbarer Anteil. BLS 4.0, Max Rubner-Institut, CC BY 4.0. Auf 17 Nährstoffe
    reduziert; Herkunftsmarker bleiben erhalten. „—“ bedeutet unbekannt.
  </p>
  <label>
    Lebensmittel suchen<Input
      type="search"
      placeholder="Hafer, lentil oder BLS-Code …"
      value={query}
      oninput={(e) => {
        query = e.currentTarget.value;
        offset = 0;
        selected = null;
      }}
    />
  </label>
  {#if error}<p role="alert" class="error">{error}</p>{/if}
  <div class="nutrition-table-scroll" aria-busy={busy}>
    <table class="nutrition-table">
      <caption>Referenzwerte pro 100 g · {result.total} Treffer</caption><thead>
        <tr>
          <th>Lebensmittel</th><th>kcal</th><th>Protein (g)</th><th>Kohlenhydrate (g)</th><th>
            Ballaststoffe (g)
          </th><th>Fett (g)</th>
        </tr>
      </thead><tbody>
        {#each result.items as food}<tr>
            <td>
              <button
                class="food-detail-link"
                onclick={() => (selected = selected?.id === food.id ? null : food)}
              >
                {food.name}
              </button><small>{food.source_food_code}</small>
            </td><td>{value(food, 'energy_kcal')}</td><td>{value(food, 'protein_g')}</td><td>
              {value(food, 'carbs_g')}
            </td><td>{value(food, 'fiber_g')}</td><td>{value(food, 'fat_g')}</td>
          </tr>{/each}
        {#if !result.items.length && !busy}<tr>
            <td colspan="6">Keine passenden Lebensmittel.</td>
          </tr>{/if}
      </tbody>
    </table>
  </div>
  <div class="nutrition-pagination">
    <Button
      variant="outline"
      disabled={offset === 0 || busy}
      onclick={() => (offset = Math.max(0, offset - 25))}
    >
      Zurück
    </Button><span>
      {result.total ? offset + 1 : 0}–{Math.min(offset + 25, result.total)} / {result.total}
    </span><Button
      variant="outline"
      disabled={offset + 25 >= result.total || busy}
      onclick={() => (offset += 25)}
    >
      Weiter
    </Button>
  </div>
  {#if selected}<div class="food-facts-detail">
      <h3>{selected.name}</h3>
      <p>{selected.name_en ?? ''} · {selected.source_food_code}</p>
      <p class="muted-copy">
        {selected.citation} · {selected.license} ·
        <a class="source-link" href={selected.source_url} target="_blank" rel="noreferrer">
          Originaldaten
        </a>
      </p>
      <div class="nutrition-table-scroll">
        <table class="nutrition-table">
          <thead><tr><th>Nährstoff</th><th>je 100 g</th><th>Herkunft</th></tr></thead><tbody>
            {#each selected.nutrients as fact}<tr>
                <td>{fact.name}</td><td>
                  {fact.amount_per_100g === null
                    ? (fact.qualifier ?? 'Unbekannt')
                    : fmt(fact.amount_per_100g) + ' ' + fact.unit.replace('ug', 'µg')}
                </td><td>
                  {fact.derivation ?? 'Nicht angegeben'}{#if fact.reference}<details>
                      <summary>Referenz</summary>{fact.reference}
                    </details>{/if}
                </td>
              </tr>{/each}
          </tbody>
        </table>
      </div>
    </div>{/if}
  {#if status?.unresolved.length}<details class="micros">
      <summary>Noch zuzuordnen: {status.unresolved.length} Zutaten</summary>
      <p class="muted-copy">
        Einmal zuordnen, in allen Rezepten wiederverwenden. Alternativen und konkrete Produkte
        brauchen eine eindeutige Auswahl.
      </p>
      <ul>
        {#each status.unresolved as row}<li>{row.name} · {row.recipeCount} Rezepte</li>{/each}
      </ul>
    </details>{/if}
  {#each status?.datasets ?? [] as dataset}<p class="muted-copy">
      {dataset.citation} ·
      <a class="source-link" href={dataset.source_url} target="_blank" rel="noreferrer">
        {dataset.license}
      </a>
    </p>{/each}
</Card>
