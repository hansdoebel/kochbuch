<script lang="ts">
  import {
    Flame,
    Leaf,
    Wheat,
    Activity,
    Plus,
    Trash2,
    ChartNoAxesCombined,
    Info,
  } from '@lucide/svelte';
  import { Card } from '$lib/components/ui/card';
  import { Button } from '$lib/components/ui/button';
  import { Input } from '$lib/components/ui/input';
  import { Progress } from '$lib/components/ui/progress';
  import { Badge } from '$lib/components/ui/badge';
  import NutritionDatabase from './NutritionDatabase.svelte';
  import WeeklyPlanner from './WeeklyPlanner.svelte';
  import DietPlan from './DietPlan.svelte';
  import {
    dietTargetsSchema,
    dietPreferencesSchema,
    migrateLegacyGoals,
    targetsForDate,
    goalLabel,
    type DietTargets,
  } from '$lib/diet';
  import { api, readLocal, writeLocal, localDate } from '$lib/client';
  import type { Analysis, BasketItem, CatalogMeta } from '$lib/types';
  let {
    basket,
    meta,
    onUsePlan,
  }: { basket: BasketItem[]; meta: CatalogMeta | null; onUsePlan: (items: BasketItem[]) => void } =
    $props();
  type Meal = { entryId: string; id: string; title: string; servings: number; date: string };
  const stored = readLocal<Meal[]>('meals:v1', []);
  let meals = $state<Meal[]>(
    Array.isArray(stored)
      ? stored.filter(
          (m) =>
            m &&
            typeof m.id === 'string' &&
            typeof m.entryId === 'string' &&
            typeof m.title === 'string' &&
            /^\d{4}-\d{2}-\d{2}$/.test(m.date) &&
            Number.isFinite(m.servings) &&
            m.servings > 0
        )
      : []
  );
  const storedPrefs = dietPreferencesSchema.safeParse(readLocal('diet-preferences:v1', null));
  let preferences = $state(
    storedPrefs.success ? storedPrefs.data : migrateLegacyGoals(readLocal('goals:v1', {}))
  );
  const storedHistory = readLocal<Record<string, unknown>>('daily-goals:v1', {});
  let goalHistory = $state<Record<string, DietTargets>>(
    Object.fromEntries(
      Object.entries(
        storedHistory && typeof storedHistory === 'object' ? storedHistory : {}
      ).filter(
        ([date, targets]) =>
          /^\d{4}-\d{2}-\d{2}$/.test(date) && dietTargetsSchema.safeParse(targets).success
      )
    ) as Record<string, DietTargets>
  );
  let scope = $state<'selection' | 'eaten'>('selection'),
    day = $state(localDate()),
    logRecipe = $state(''),
    logServings = $state(1);
  const goals = $derived(
    scope === 'eaten' && goalHistory[day] ? goalHistory[day] : targetsForDate(preferences, day)
  );
  let analysis = $state<Analysis | null>(null),
    error = $state(''),
    busy = $state(false);
  const todayMeals = $derived(meals.filter((m) => m.date === day));
  const selections = $derived.by(() => {
    if (scope === 'selection') return basket.map(({ id, servings }) => ({ id, servings }));
    const sums = new Map<string, number>();
    for (const meal of todayMeals) sums.set(meal.id, (sums.get(meal.id) ?? 0) + meal.servings);
    return [...sums].map(([id, servings]) => ({ id, servings }));
  });
  const macros = [
    { key: 'energy_kcal', name: 'Energie', unit: 'kcal', icon: Flame },
    { key: 'protein_g', name: 'Protein', unit: 'g', icon: Activity },
    { key: 'fiber_g', name: 'Ballaststoffe', unit: 'g', icon: Leaf },
    { key: 'carbs_g', name: 'Kohlenhydrate', unit: 'g', icon: Wheat },
  ] as const;
  const micros = [
    ['fat_g', 'Fett', 'g'],
    ['sugar_g', 'Zucker', 'g'],
    ['saturated_fat_g', 'Gesättigte Fettsäuren', 'g'],
    ['sodium_mg', 'Natrium', 'mg'],
    ['calcium_mg', 'Calcium', 'mg'],
    ['iron_mg', 'Eisen', 'mg'],
    ['magnesium_mg', 'Magnesium', 'mg'],
    ['potassium_mg', 'Kalium', 'mg'],
    ['zinc_mg', 'Zink', 'mg'],
    ['vitamin_b12_ug', 'Vitamin B12', 'µg'],
    ['vitamin_d_ug', 'Vitamin D', 'µg'],
    ['folate_ug', 'Folat', 'µg'],
    ['iodine_ug', 'Jod', 'µg'],
    ['selenium_ug', 'Selen', 'µg'],
  ] as const;
  const fmt = (n: number) => new Intl.NumberFormat('de-DE', { maximumFractionDigits: 1 }).format(n);
  $effect(() => {
    writeLocal('meals:v1', meals);
  });
  $effect(() => {
    writeLocal('diet-preferences:v1', preferences);
    writeLocal('daily-goals:v1', goalHistory);
  });
  $effect(() => {
    if (!basket.some((r) => r.id === logRecipe)) logRecipe = basket[0]?.id ?? '';
  });
  $effect(() => {
    const body = { selections };
    const controller = new AbortController();
    busy = true;
    error = '';
    api<Analysis>('/api/analysis', body, controller.signal)
      .then((data) => (analysis = data))
      .catch((e) => {
        if (e.name !== 'AbortError') error = e.message;
      })
      .finally(() => {
        if (!controller.signal.aborted) busy = false;
      });
    return () => controller.abort();
  });
  function logMeal() {
    const recipe = basket.find((r) => r.id === logRecipe);
    if (!recipe || !Number.isFinite(logServings) || logServings <= 0 || logServings > 100) return;
    if (!goalHistory[day])
      goalHistory = {
        ...goalHistory,
        [day]: structuredClone($state.snapshot(targetsForDate(preferences, day))),
      };
    meals = [
      ...meals,
      {
        entryId:
          globalThis.crypto?.randomUUID?.() ??
          `local-${Date.now()}-${Math.random().toString(36).slice(2)}`,
        id: recipe.id,
        title: recipe.title,
        servings: logServings,
        date: day,
      },
    ];
    scope = 'eaten';
  }
</script>

<div class="page-heading">
  <div>
    <span class="eyebrow">ESSEN BESSER VERSTEHEN</span>
    <h1>Deine Ernährung im Blick.</h1>
    <p>Was ist geplant, was hast du gegessen – und was wissen wir darüber?</p>
  </div>
  <Badge variant="secondary"><ChartNoAxesCombined size={14} />Analyse</Badge>
</div>
<div class="analytics-controls">
  <div class="filter-pair">
    <button class:chosen={scope === 'selection'} onclick={() => (scope = 'selection')}>
      Rezeptauswahl
    </button><button class:chosen={scope === 'eaten'} onclick={() => (scope = 'eaten')}>
      Tatsächlich gegessen
    </button>
  </div>
  {#if scope === 'eaten'}<label class="date-label">
      Tag<Input
        type="date"
        value={day}
        oninput={(e) => {
          if (/^\d{4}-\d{2}-\d{2}$/.test(e.currentTarget.value)) day = e.currentTarget.value;
        }}
        aria-label="Tag des Verzehrs"
      />
    </label>{/if}
</div>
<div class="analytics-note">
  <Info size={19} />
  <div>
    <strong>
      {meta?.nutritionCount ?? 0} von {meta?.count ?? '…'} Rezepten mit Nährwertprofil
    </strong>
    <p>
      Die Zutatenbilanz nutzt BLS-Referenzdaten. Unvollständige Analysen bleiben als Teilsummen
      erkennbar. Persönliche Ziele legst du selbst fest.
    </p>
  </div>
</div>
{#if error}<p class="error" role="alert">{error}</p>{/if}
<div class="macro-grid" aria-busy={busy}>
  {#each macros as metric}
    {@const value = analysis?.totals[metric.key]}
    {@const known = analysis?.coverage[metric.key] ?? 0}
    {@const range = goals[metric.key]}
    {@const goal = range?.min || range?.max}
    <Card class="metric-card">
      <div class="metric-top"><span>{metric.name}</span><metric.icon size={19} /></div>
      <div class="metric-value">
        {known && value !== null && value !== undefined ? fmt(value) : '—'}<span>
          {metric.unit}
        </span>
      </div>
      <p class="metric-caption">
        {known
          ? `${analysis?.completeCoverage[metric.key] ?? 0}/${analysis?.selectedCount ?? 0} Rezepte vollständig · ${known} mit Teilwerten`
          : 'Noch keine Nährwerte erfasst'}
      </p>
      {#if known && goal && value !== null && value !== undefined}<Progress
          value={Math.min(100, (value / goal) * 100)}
          aria-label={metric.name + ' im Verhältnis zu deinem Ziel'}
        />
        <p class="goal-caption">
          Bekannte Teilsumme · Ziel {goalLabel(range)}
          {metric.unit}
        </p>{:else}<div class="unknown-progress" aria-hidden="true"></div>
        <p class="goal-caption">
          {goal ? 'Ziel ' + goalLabel(range) + ' ' + metric.unit : 'Noch kein persönliches Ziel'}
        </p>{/if}
    </Card>
  {/each}
</div>
<div class="analytics-columns">
  <Card class="analytics-card">
    <div class="section-title">
      <h2>
        {scope === 'selection'
          ? 'Analyse der Auswahl'
          : 'Verzehr am ' + new Date(day + 'T12:00:00').toLocaleDateString('de-DE')}
      </h2>
      <Badge variant="secondary">
        {analysis?.profiledCount ?? 0}/{analysis?.selectedCount ?? 0} analysiert
      </Badge>
    </div>
    {#if !selections.length}<div class="analytics-empty">
        <Leaf size={31} />
        <h3>
          {scope === 'selection'
            ? 'Dein nächstes Essen beginnt in der Sammlung.'
            : 'Für diesen Tag ist noch kein Verzehr gespeichert.'}
        </h3>
        <p>
          {scope === 'selection'
            ? 'Wähle Rezepte aus, um ihre verfügbaren Nährwerte gemeinsam zu betrachten.'
            : 'Erfasse bewusst die Portionen, die du wirklich gegessen hast.'}
        </p>
      </div>
    {:else if !analysis?.profiledCount}<div class="analytics-empty">
        <ChartNoAxesCombined size={31} />
        <h3>Bereit für die Nährwertanalyse.</h3>
        <p>
          {analysis?.selectedCount ?? selections.length} Rezepte sind erfasst. Sobald geprüfte oder gekennzeichnete
          geschätzte Nährwertprofile vorliegen, erscheinen hier die Mengen.
        </p>
      </div>
    {:else}<p class="notice">
        {analysis.profiledCount} Rezepte mit Profil, davon {analysis.verifiedCount} verifiziert. Unbekannte
        Nährwerte fehlen in der Summe; Teilsummen sind keine vollständige Tagesbilanz.
      </p>{/if}
    {#if analysis?.partialRecipes.length}<p class="notice">
        Teilweise erfasste Zutaten: {analysis.partialRecipes.join(', ')}. Die angezeigten Mengen
        sind bekannte Teilsummen.
      </p>{/if}
    <details class="micros" open={!!analysis?.profiledCount}>
      <summary>Weitere Makro- und Mikronährstoffe</summary>
      <table>
        <thead><tr><th>Nährstoff</th><th>Bekannte Menge</th><th>Vollständig</th></tr></thead><tbody>
          {#each micros as [key, label, unit]}<tr>
              <td>{label}</td><td>
                {analysis?.coverage[key]
                  ? fmt(analysis.totals[key]!) + ' ' + unit
                  : 'Nicht analysiert'}
              </td><td>{analysis?.completeCoverage[key] ?? 0}/{analysis?.selectedCount ?? 0}</td>
            </tr>{/each}
        </tbody>
      </table>
    </details>
  </Card>
  <Card class="analytics-card">
    <h2>Verzehr festhalten</h2>
    <p class="muted-copy">
      Eine Rezeptauswahl ist noch kein Verzehr. Erfasse deine tatsächlich gegessenen Portionen
      separat.
    </p>
    <form
      class="meal-form"
      onsubmit={(e) => {
        e.preventDefault();
        logMeal();
      }}
    >
      <label>
        Rezept aus deiner Auswahl<select bind:value={logRecipe} disabled={!basket.length} required>
          <option value="" disabled>Rezept auswählen</option>{#each basket as recipe}<option
              value={recipe.id}
            >
              {recipe.title}
            </option>{/each}
        </select>
      </label>
      <div class="meal-fields">
        <label>
          Gegessene Portionen<Input
            type="number"
            min="0.1"
            max="100"
            step="0.1"
            bind:value={logServings}
            required
          />
        </label><label>
          Datum<Input
            type="date"
            value={day}
            oninput={(e) => {
              if (/^\d{4}-\d{2}-\d{2}$/.test(e.currentTarget.value)) day = e.currentTarget.value;
            }}
            required
          />
        </label>
      </div>
      <Button type="submit" disabled={!logRecipe || !logServings || logServings <= 0}>
        <Plus size={16} />Verzehr speichern
      </Button>
    </form>
    {#if todayMeals.length}<div class="meal-log">
        {#each todayMeals as meal}<div>
            <span>
              <strong>{meal.title}</strong><small>{fmt(meal.servings)} Portionen</small>
            </span><Button
              variant="ghost"
              size="icon"
              aria-label={'Verzehr von ' + meal.title + ' entfernen'}
              onclick={() => (meals = meals.filter((m) => m.entryId !== meal.entryId))}
            >
              <Trash2 size={15} />
            </Button>
          </div>{/each}
      </div>{/if}
  </Card>
</div>
<p class="muted-copy">
  Tagesziele für {day}. Beim ersten Verzehr wird der damalige Zielstand für diesen Tag gespeichert;
  spätere Änderungen gelten für neue Tage. Alte Einträge ohne Zielstand verwenden das aktuelle
  Profil.
</p>
<DietPlan {preferences} onChange={(p) => (preferences = p)} {onUsePlan} />
<WeeklyPlanner {preferences} {onUsePlan} />
<NutritionDatabase />
