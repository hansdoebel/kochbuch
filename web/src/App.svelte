<script lang="ts">
  import { onMount } from 'svelte';
  import {
    BookOpen,
    Search,
    Sun,
    Moon,
    Plus,
    Check,
    Clock,
    ShoppingBag,
    SlidersHorizontal,
    Leaf,
    ChartNoAxesCombined,
    Download,
    Trash2,
    Minus,
    ExternalLink,
    LoaderCircle,
    ChevronLeft,
    ChevronRight,
    Menu,
    X,
    Utensils,
  } from '@lucide/svelte';
  import { Button } from '$lib/components/ui/button';
  import { Card } from '$lib/components/ui/card';
  import { Badge } from '$lib/components/ui/badge';
  import { Input } from '$lib/components/ui/input';
  import { Checkbox } from '$lib/components/ui/checkbox';
  import * as Dialog from '$lib/components/ui/dialog';
  import { api, readLocal, writeLocal } from '$lib/client';
  import type { BasketItem, Recipe, RecipeSummary, CatalogMeta, ShoppingList } from '$lib/types';
  let view = $state<'recipes' | 'shopping' | 'nutrition'>('recipes');
  let meta = $state<CatalogMeta | null>(null),
    items = $state<RecipeSummary[]>([]),
    total = $state(0),
    loading = $state(true),
    error = $state('');
  let q = $state(''),
    source = $state(''),
    ready = $state(false),
    offset = $state(0),
    mobileFilters = $state(false);
  let dark = $state(document.documentElement.classList.contains('dark'));
  const stored = readLocal<BasketItem[]>('basket:v1', []);
  let basket = $state<BasketItem[]>(
    Array.isArray(stored)
      ? stored
          .filter(
            (i) =>
              i &&
              typeof i.id === 'string' &&
              typeof i.title === 'string' &&
              Number.isFinite(i.servings) &&
              i.servings > 0
          )
          .slice(0, 24)
      : []
  );
  let detail = $state<Recipe | null>(null),
    detailOpen = $state(false),
    detailLoading = $state(false),
    detailError = $state('');
  let list = $state<ShoppingList | null>(null),
    listLoading = $state(false),
    hidePantry = $state(false),
    includeOptional = $state(true),
    exporting = $state(false),
    exportError = $state('');
  let checked = $state<Set<string>>(new Set());
  const selected = $derived(new Set(basket.map((r) => r.id)));
  const selections = $derived(basket.map(({ id, servings }) => ({ id, servings })));
  const fmt = (n: number) => new Intl.NumberFormat('de-DE').format(n);
  onMount(() => {
    api<CatalogMeta>('/api/meta')
      .then((m) => (meta = m))
      .catch((e) => (error = e.message));
  });
  $effect(() => {
    writeLocal('basket:v1', basket);
  });
  $effect(() => {
    const params = new URLSearchParams({ q, source, ready: String(ready), offset: String(offset) });
    const controller = new AbortController();
    loading = true;
    error = '';
    const timer = setTimeout(
      () =>
        api<{ items: RecipeSummary[]; total: number }>(
          '/api/recipes?' + params,
          undefined,
          controller.signal
        )
          .then((data) => {
            items = data.items;
            total = data.total;
          })
          .catch((e) => {
            if (e.name !== 'AbortError') error = e.message;
          })
          .finally(() => {
            if (!controller.signal.aborted) loading = false;
          }),
      140
    );
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  });
  $effect(() => {
    const body = { selections, hidePantry, includeOptional };
    const controller = new AbortController();
    checked = new Set();
    if (!body.selections.length) {
      list = null;
      listLoading = false;
      return;
    }
    listLoading = true;
    api<ShoppingList>('/api/shopping', body, controller.signal)
      .then((data) => {
        list = data;
        exportError = '';
      })
      .catch((e) => {
        if (e.name !== 'AbortError') exportError = e.message;
      })
      .finally(() => {
        if (!controller.signal.aborted) listLoading = false;
      });
    return () => controller.abort();
  });
  function toggleTheme() {
    dark = !dark;
    document.documentElement.classList.toggle('dark', dark);
    try {
      localStorage.setItem('kochbuch:theme', dark ? 'dark' : 'light');
    } catch {}
  }
  function toggleRecipe(recipe: RecipeSummary) {
    if (selected.has(recipe.id)) {
      basket = basket.filter((r) => r.id !== recipe.id);
      return;
    }
    if (basket.length >= 24) {
      error = 'Du kannst bis zu 24 Rezepte gleichzeitig auswählen.';
      return;
    }
    basket = [
      ...basket,
      {
        id: recipe.id,
        title: recipe.title,
        source: recipe.source,
        ready: recipe.ready,
        servings: recipe.servings ?? 1,
      },
    ];
  }
  function portions(id: string, value: number) {
    if (Number.isFinite(value) && value > 0 && value <= 100)
      basket = basket.map((r) => (r.id === id ? { ...r, servings: value } : r));
  }
  let detailController: AbortController | null = null;
  async function openRecipe(id: string) {
    detailController?.abort();
    detailController = new AbortController();
    const controller = detailController;
    detailOpen = true;
    detail = null;
    detailLoading = true;
    detailError = '';
    try {
      detail = await api<Recipe>(
        '/api/recipes/' + encodeURIComponent(id),
        undefined,
        controller.signal
      );
    } catch (e) {
      if (!controller.signal.aborted)
        detailError = e instanceof Error ? e.message : 'Rezept nicht verfügbar.';
    } finally {
      if (!controller.signal.aborted) detailLoading = false;
    }
  }
  function chooseSource(name: string) {
    source = name;
    offset = 0;
    mobileFilters = false;
  }
  async function download(format: 'pdf' | 'typ' | 'json') {
    exporting = true;
    exportError = '';
    try {
      const response = await fetch('/api/export?format=' + format, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ selections, hidePantry, includeOptional }),
      });
      if (!response.ok) throw new Error((await response.json()).error ?? 'Export fehlgeschlagen.');
      const url = URL.createObjectURL(await response.blob());
      const a = document.createElement('a');
      a.href = url;
      a.download = 'einkaufsliste.' + format;
      a.click();
      setTimeout(() => URL.revokeObjectURL(url), 2000);
    } catch (e) {
      exportError = e instanceof Error ? e.message : 'Export fehlgeschlagen.';
    } finally {
      exporting = false;
    }
  }
</script>

<svelte:window
  onkeydown={(e) => {
    if (
      e.key === '/' &&
      !(e.target instanceof HTMLInputElement) &&
      !(e.target instanceof HTMLTextAreaElement) &&
      !(e.target instanceof HTMLSelectElement)
    ) {
      e.preventDefault();
      view = 'recipes';
      document.getElementById('recipe-search')?.focus();
    }
  }}
/>
<a href="#main" class="skip-link">Zum Inhalt springen</a>
<header class="topbar">
  <a
    class="brand"
    href="/"
    onclick={(e) => {
      e.preventDefault();
      view = 'recipes';
    }}
  >
    <span class="brand-mark"><BookOpen size={21} /></span><span>
      Kochbuch<span class="brand-sub">Gutes Essen. Gut geplant.</span>
    </span>
  </a>
  <nav aria-label="Hauptnavigation">
    <button
      aria-label="Rezepte"
      class:nav-active={view === 'recipes'}
      onclick={() => (view = 'recipes')}
    >
      <BookOpen size={17} /><span>Rezepte</span>
    </button>
    <button
      aria-label="Einkaufsliste"
      class:nav-active={view === 'shopping'}
      onclick={() => (view = 'shopping')}
    >
      <ShoppingBag size={17} /><span>Einkaufsliste</span>{#if basket.length}<span class="nav-count">
          {basket.length}
        </span>{/if}
    </button>
    <button
      aria-label="Ernährung"
      class:nav-active={view === 'nutrition'}
      onclick={() => (view = 'nutrition')}
    >
      <ChartNoAxesCombined size={17} /><span>Ernährung</span>
    </button>
  </nav>
  <Button
    variant="ghost"
    size="icon-lg"
    class="theme-toggle"
    onclick={toggleTheme}
    aria-label={dark ? 'Helles Design aktivieren' : 'Dunkles Design aktivieren'}
  >
    {#if dark}<Sun size={19} />{:else}<Moon size={19} />{/if}
  </Button>
</header>
<div class="app-shell" class:wide={view !== 'recipes'}>
  {#if view === 'recipes'}
    <aside class="collection" class:mobile-open={mobileFilters} aria-label="Rezeptfilter">
      <div class="collection-heading">
        <span class="eyebrow">DEINE SAMMLUNG</span><Button
          class="mobile-close"
          variant="ghost"
          size="icon"
          onclick={() => (mobileFilters = false)}
          aria-label="Filter schließen"
        >
          <X size={18} />
        </Button>
      </div>
      <div class="collection-number">
        {meta ? fmt(meta.count) : '…'}<span>Rezepte zum Entdecken</span>
      </div>
      <div class="filter-pair">
        <button
          class:chosen={!ready}
          onclick={() => {
            ready = false;
            offset = 0;
          }}
        >
          Alle Rezepte
        </button><button
          class:chosen={ready}
          onclick={() => {
            ready = true;
            offset = 0;
          }}
        >
          Skalierbar <span>{meta?.readyCount ?? 6}</span>
        </button>
      </div>
      <div class="sidebar-label">
        <span class="eyebrow">QUELLEN</span>{#if source}<button
            onclick={() => chooseSource('')}
            class="reset-filter"
          >
            Zurücksetzen
          </button>{/if}
      </div>
      <button class="source-row" class:source-selected={!source} onclick={() => chooseSource('')}>
        <span>Alle Quellen</span><span>{meta ? fmt(meta.count) : '…'}</span>
      </button>
      {#each meta?.sources ?? [] as s}<button
          class="source-row"
          class:source-selected={source === s.name}
          onclick={() => chooseSource(s.name)}
        >
          <span>{s.name}</span><span>{fmt(s.count)}</span>
        </button>{/each}
      <div class="sidebar-note">
        <Leaf size={18} />
        <p>
          Deine Rezepte bleiben bei dir.<br />Auswahl und Verzehr werden lokal auf diesem Gerät
          gespeichert.
        </p>
      </div>
    </aside>
  {/if}
  <main id="main" class="main-content">
    {#if view === 'recipes'}
      <div class="page-heading">
        <div>
          <span class="eyebrow">ETWAS GUTES AUF DEN TISCH</span>
          <h1>Was möchtest du kochen?</h1>
          <p>Finde ein Rezept. Stell dein Menü zusammen. Nimm die Liste mit.</p>
        </div>
        <Button
          variant="outline"
          class="mobile-filter"
          onclick={() => (mobileFilters = !mobileFilters)}
        >
          <SlidersHorizontal size={16} />Filter
        </Button>
      </div>
      <div class="search-wrap">
        <Search size={21} /><Input
          id="recipe-search"
          bind:value={q}
          oninput={() => (offset = 0)}
          placeholder="Rezepte oder Zutaten suchen …"
          aria-label="Rezepte oder Zutaten suchen"
          class="search-input"
        />{#if loading}<LoaderCircle size={18} class="animate-spin" />{:else if q}<button
            aria-label="Suche löschen"
            onclick={() => {
              q = '';
              offset = 0;
            }}
          >
            <X size={18} />
          </button>{:else}<kbd>/</kbd>{/if}
      </div>
      <div class="results-heading">
        <p aria-live="polite">
          {fmt(total)}
          {q ? 'Treffer' : 'Rezepte'}{source ? ' · ' + source : ''}
        </p>
        <span>{ready ? 'Mengen geprüft & skalierbar' : 'Kuratierte Rezepte zuerst'}</span>
      </div>
      {#if error}<div class="error" role="alert">
          {error}<Button
            variant="outline"
            onclick={() => {
              q = '';
              source = '';
              ready = false;
              offset = 0;
            }}
          >
            Filter zurücksetzen
          </Button>
        </div>{/if}
      <section class="recipe-grid" aria-label="Rezepte" aria-busy={loading}>
        {#if loading && !items.length}{#each [1, 2, 3, 4, 5, 6] as n}<Card
              class="recipe-card skeleton"
              aria-hidden="true"
            >
              <div></div>
              <div></div>
              <div></div>
            </Card>{/each}{/if}
        {#each items as recipe (recipe.id)}
          <Card class={'recipe-card ' + (selected.has(recipe.id) ? 'is-selected' : '')}>
            <div class="card-top">
              <span class="recipe-source">{recipe.source}</span>{#if recipe.ready}<span
                  class="ready-icon"
                  title="Mengen geprüft und skalierbar"
                >
                  <Check size={14} />
                </span>{/if}
            </div>
            <button class="recipe-title" onclick={() => openRecipe(recipe.id)}>
              <h2>{recipe.title}</h2>
            </button>
            <div class="recipe-facts">
              <span>
                <Utensils size={14} />{recipe.ingredientCount} Zutaten
              </span>{#if recipe.minutes !== null}<span>
                  <Clock size={14} />{recipe.minutes} Min.
                </span>{/if}
            </div>
            <div class="card-bottom">
              <Badge variant="secondary">
                {recipe.missingFields.length
                  ? 'Unvollständig'
                  : recipe.ready
                    ? 'Skalierbar'
                    : recipe.language.startsWith('de')
                      ? 'Deutsch'
                      : 'Originalrezept'}
              </Badge><Button
                variant={selected.has(recipe.id) ? 'default' : 'outline'}
                size="icon-lg"
                onclick={() => toggleRecipe(recipe)}
                aria-label={selected.has(recipe.id)
                  ? recipe.title + ' aus Auswahl entfernen'
                  : recipe.title + ' auswählen'}
                aria-pressed={selected.has(recipe.id)}
              >
                {#if selected.has(recipe.id)}<Check size={18} />{:else}<Plus size={18} />{/if}
              </Button>
            </div>
          </Card>
        {/each}
      </section>
      {#if !loading && !items.length && !error}<div class="empty-state">
          <Search size={30} />
          <h2>Hier ist noch nichts dabei.</h2>
          <p>Versuche einen anderen Begriff oder wähle alle Quellen.</p>
          <Button
            variant="outline"
            onclick={() => {
              q = '';
              source = '';
              ready = false;
              offset = 0;
            }}
          >
            Alle Rezepte anzeigen
          </Button>
        </div>{/if}
      {#if total > 30}<div class="pagination">
          <Button
            variant="outline"
            disabled={offset === 0 || loading}
            onclick={() => (offset = Math.max(0, offset - 30))}
          >
            <ChevronLeft size={16} />Zurück
          </Button><span>{offset + 1}–{Math.min(offset + 30, total)} von {fmt(total)}</span><Button
            variant="outline"
            disabled={offset + 30 >= total || loading}
            onclick={() => {
              offset += 30;
              document.getElementById('main')?.scrollIntoView({ behavior: 'smooth' });
            }}
          >
            Weiter<ChevronRight size={16} />
          </Button>
        </div>{/if}
    {:else if view === 'shopping'}
      <div class="page-heading">
        <div>
          <span class="eyebrow">VOM MENÜ ZUM EINKAUF</span>
          <h1>Deine Einkaufsliste</h1>
          <p>
            {list
              ? `${basket.length} Rezepte · ${list.itemCount} Einträge · bereit zum Mitnehmen`
              : 'Wähle ein paar Rezepte für deinen nächsten Einkauf.'}
          </p>
        </div>
        <Button variant="outline" onclick={() => (view = 'recipes')}>
          <Plus size={16} />Rezepte ergänzen
        </Button>
      </div>
      {#if basket.length}
        <div class="shopping-toolbar">
          <label><Checkbox bind:checked={hidePantry} />Vorrat ausblenden</label><label>
            <Checkbox bind:checked={includeOptional} />Optionale Zutaten
          </label>
          <div class="export-actions">
            <Button
              disabled={exporting || listLoading || !meta?.pdfAvailable}
              onclick={() => download('pdf')}
            >
              {#if exporting}<LoaderCircle class="animate-spin" size={16} />{:else}<Download
                  size={16}
                />{/if}PDF fürs Handy
            </Button><Button
              variant="outline"
              disabled={exporting || listLoading}
              onclick={() => download('typ')}
            >
              Typst
            </Button><Button
              variant="ghost"
              disabled={exporting || listLoading}
              onclick={() => download('json')}
            >
              JSON
            </Button>
          </div>
        </div>
        {#if !meta?.pdfAvailable}<p class="notice">
            Für den direkten PDF-Export wird Typst benötigt. Die eigenständige Typst-Datei kannst du
            bereits herunterladen.
          </p>{/if}
        {#if list?.unscaledRecipes.length}<p class="notice">
            {list.unscaledRecipes.length} Archivrezepte behalten ihre Originalmengen und sind separat
            aufgeführt. Bei skalierbaren Rezepten werden gleiche Zutaten zusammengezählt.
          </p>{/if}
        {#if exportError}<p class="error" role="alert">{exportError}</p>{/if}
        <div class="shopping-groups" aria-busy={listLoading}>
          {#each list?.groups ?? [] as group}<Card class="shopping-group">
              <h2>{group.name}</h2>
              {#each group.items as item}<label
                  class="shopping-row"
                  class:completed={checked.has(item.id)}
                >
                  <Checkbox
                    checked={checked.has(item.id)}
                    onCheckedChange={(value) => {
                      const next = new Set(checked);
                      value ? next.add(item.id) : next.delete(item.id);
                      checked = next;
                    }}
                  /><span>{item.text}</span>
                </label>{/each}
            </Card>{/each}
        </div>
      {:else}<div class="empty-state">
          <ShoppingBag size={38} />
          <h2>Ein gutes Essen beginnt mit einer Idee.</h2>
          <p>Wähle Rezepte aus deiner Sammlung und wir stellen die Zutaten zusammen.</p>
          <Button onclick={() => (view = 'recipes')}>Rezepte entdecken</Button>
        </div>{/if}
    {:else}
      {#await import('./NutritionPanel.svelte')}<div class="empty-state">
          <LoaderCircle size={28} class="animate-spin" />Analyse wird geladen …
        </div>{:then module}<module.default {basket} {meta} />{:catch}<p role="alert" class="error">
          Die Ernährungsansicht konnte nicht geladen werden.
        </p>{/await}
    {/if}
  </main>
  {#if view !== 'nutrition'}
    <aside class="plan" aria-label="Deine Rezeptauswahl">
      <div class="plan-heading">
        <div>
          <span class="eyebrow">FÜR DEN NÄCHSTEN EINKAUF</span>
          <h2>Deine Auswahl <span>{basket.length}</span></h2>
        </div>
        {#if basket.length}<Button
            variant="ghost"
            size="icon"
            aria-label="Auswahl leeren"
            onclick={() => (basket = [])}
          >
            <Trash2 size={16} />
          </Button>{/if}
      </div>
      {#if !basket.length}<div class="plan-empty">
          <div><ShoppingBag size={27} /></div>
          <p>Hier kommt dein Menü hin.</p>
          <span>Mit dem Plus am Rezept hinzufügen.</span>
        </div>{/if}
      {#each basket as item (item.id)}<div class="plan-item">
          <div class="plan-item-heading">
            <button onclick={() => openRecipe(item.id)}>{item.title}</button><Button
              size="icon-sm"
              variant="ghost"
              aria-label={item.title + ' entfernen'}
              onclick={() => (basket = basket.filter((r) => r.id !== item.id))}
            >
              <X size={14} />
            </Button>
          </div>
          <div class="portion-row">
            {#if item.ready}<span>Portionen</span>
              <div class="portion-controls">
                <Button
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Portionen reduzieren"
                  disabled={item.servings <= 0.5}
                  onclick={() => portions(item.id, Math.max(0.5, item.servings - 1))}
                >
                  <Minus size={13} />
                </Button><input
                  type="number"
                  min="0.5"
                  max="100"
                  step="0.5"
                  aria-label={'Portionen für ' + item.title}
                  value={item.servings}
                  onchange={(e) => portions(item.id, Number(e.currentTarget.value))}
                /><Button
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Portionen erhöhen"
                  disabled={item.servings >= 100}
                  onclick={() => portions(item.id, item.servings + 1)}
                >
                  <Plus size={13} />
                </Button>
              </div>{:else}<span>Originalmengen</span><span class="original-label">
                Archiv
              </span>{/if}
          </div>
        </div>{/each}
      <div class="plan-footer">
        <div>
          <span>Zutaten auf der Liste</span><strong>
            {listLoading ? '…' : (list?.itemCount ?? 0)}
          </strong>
        </div>
        <Button class="plan-cta" disabled={!basket.length} onclick={() => (view = 'shopping')}>
          <ShoppingBag size={16} />Einkaufsliste ansehen
        </Button>
        <p>Deine Auswahl bleibt auf diesem Gerät gespeichert.</p>
      </div>
    </aside>
  {/if}
</div>
{#if basket.length && view === 'recipes'}<div class="mobile-basket">
    <span><strong>{basket.length}</strong> Rezepte ausgewählt</span><Button
      onclick={() => (view = 'shopping')}
    >
      Liste ansehen
    </Button>
  </div>{/if}
<Dialog.Root bind:open={detailOpen}>
  <Dialog.Content
    class="recipe-dialog sm:max-w-3xl w-[calc(100%-2rem)] max-h-[88dvh] overflow-y-auto p-7"
  >
    <Dialog.Title class="text-2xl font-semibold leading-tight pr-6">
      {detail?.title ?? 'Rezept'}
    </Dialog.Title><Dialog.Description class="text-muted-foreground">
      {detail
        ? (detail.authors.length ? detail.authors.join(', ') + ' · ' : '') + detail.source
        : 'Details werden geladen …'}
    </Dialog.Description>
    {#if detailLoading}<div class="empty-state">
        <LoaderCircle class="animate-spin" size={28} />
      </div>{:else if detailError}<p class="error" role="alert">{detailError}</p>{:else if detail}
      <div class="detail-tools">
        <Badge variant="secondary">{detail.servingsText}</Badge>{#if detail.minutes !== null}<Badge
            variant="secondary"
          >
            {detail.minutes} Min.
          </Badge>{/if}<Button
          onclick={() => toggleRecipe(detail!)}
          variant={selected.has(detail.id) ? 'outline' : 'default'}
        >
          {#if selected.has(detail.id)}<Check size={16} />Ausgewählt{:else}<Plus size={16} />Zur
            Auswahl{/if}
        </Button>
      </div>
      {#if detail.sourceUrl}<a
          class="source-link"
          href={detail.sourceUrl}
          target="_blank"
          rel="noopener noreferrer"
        >
          Originalrezept öffnen<ExternalLink size={14} />
        </a>{/if}
      {#if detail.nutrition}
        <div class="notice">
          <Badge variant="secondary">
            Nährwerte: {detail.nutrition.quality === 'verified' ? 'verifiziert' : 'geschätzt'}
          </Badge>
          <p class="mt-2">
            Angaben pro Portion · geprüft am {detail.nutrition.reviewedAt} ·
            <a
              class="source-link"
              href={detail.nutrition.sourceUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              Nährwertquelle
            </a>
          </p>
        </div>
      {/if}
      {#if detail.missingFields.length}<p class="notice">
          Die Originalkarte ist unvollständig: {detail.missingFields
            .map(
              (field) =>
                (
                  ({
                    authors: 'Urheberangabe',
                    ingredients: 'Zutaten',
                    instructions: 'Anleitung',
                    name: 'Titel',
                  }) as Record<string, string>
                )[field] ?? field
            )
            .join(', ')}. Vor dem Kochen mit der Quelle abgleichen.
        </p>{/if}
      <div class="recipe-detail-columns">
        <section>
          <h3>Zutaten</h3>
          <ul>
            {#each detail.ingredients as text}<li>{text}</li>{/each}
          </ul>
        </section>
        <section>
          <h3>Zubereitung</h3>
          <ol>
            {#each detail.instructions as text}<li>{text}</li>{/each}
          </ol>
        </section>
      </div>
      {#if detail.notes.length}<details class="recipe-notes">
          <summary>Hinweise zur Quelle</summary>{#each detail.notes as text}<p>{text}</p>{/each}
        </details>{/if}
    {/if}
  </Dialog.Content>
</Dialog.Root>
