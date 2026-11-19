<script lang="ts">
  import { onMount } from 'svelte';
  import { Card } from '$lib/components/ui/card';
  import { Button } from '$lib/components/ui/button';
  import { Input } from '$lib/components/ui/input';
  import { api, localDate } from '$lib/client';
  import {
    dietKeys,
    dietPreferencesSchema,
    dayProfile,
    mealTargets,
    goalLabel,
    type DietPreferences,
    type DietKey,
  } from '$lib/diet';
  import { dietStrategies, strategyReviewedOn } from '$lib/diet-strategies';
  import type { BasketItem, RecipeSummary } from '$lib/types';
  import type { Adaptation } from './server/adaptation';
  let {
    preferences,
    onChange,
    onUsePlan,
  }: {
    preferences: DietPreferences;
    onChange: (p: DietPreferences) => void;
    onUsePlan: (items: BasketItem[]) => void;
  } = $props();
  let draft = $state('');
  $effect(() => {
    draft = JSON.stringify(preferences);
  });
  let editProfile = $state<'training' | 'rest'>('rest');
  let options = $state<{ recipes: RecipeSummary[]; ingredients: { id: number; name: string }[] }>({
    recipes: [],
    ingredients: [],
  });
  let recipeId = $state(''),
    date = $state(localDate()),
    people = $state(1),
    result = $state<Adaptation | null>(null),
    error = $state(''),
    busy = $state(false),
    exclusion = $state('');
  const labels: Record<DietKey, string> = {
    energy_kcal: 'Energie (kcal)',
    protein_g: 'Protein (g)',
    carbs_g: 'Kohlenhydrate (g)',
    fiber_g: 'Ballaststoffe (g)',
    fat_g: 'Fett (g)',
  };
  const weekdays = ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];
  const fmt = (n: number) => new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 }).format(n);
  onMount(() => {
    const controller = new AbortController();
    api<typeof options>('/api/diet/options', undefined, controller.signal)
      .then((data) => {
        options = data;
        recipeId =
          data.recipes.find((r) => r.tags.includes('Tofu'))?.id ?? data.recipes[0]?.id ?? '';
      })
      .catch((e) => {
        if (e.name !== 'AbortError') error = e.message;
      });
    return () => controller.abort();
  });
  // Results are invalidated whenever any input changes; a stale proposal cannot be applied.
  $effect(() => {
    JSON.stringify(preferences);
    recipeId;
    date;
    people;
    result = null;
  });
  function change(next: unknown) {
    const parsed = dietPreferencesSchema.safeParse(next);
    if (parsed.success) {
      onChange(parsed.data);
      error = '';
      draft = JSON.stringify(parsed.data);
    } else error = parsed.error.issues.map((i) => i.message).join(' · ');
  }
  function bound(key: DietKey, side: 'min' | 'max', raw: string) {
    const next = structuredClone($state.snapshot(preferences));
    const r = { ...next.profiles[editProfile][key] };
    if (raw === '') delete r[side];
    else r[side] = Number(raw);
    if (r.min === undefined && r.max === undefined) delete next.profiles[editProfile][key];
    else next.profiles[editProfile][key] = r;
    change(next);
  }
  async function adapt() {
    busy = true;
    error = '';
    result = null;
    try {
      if (!Number.isInteger(people) || people < 1 || people > 10)
        throw new Error('Ganze Personenzahl zwischen 1 und 10 wählen.');
      const stamp = JSON.stringify([preferences, recipeId, date, people]);
      const proposal = await api<Adaptation>('/api/diet/adapt', {
        id: recipeId,
        targets: mealTargets(preferences, date),
        source: preferences.source,
        eatingStyle: preferences.eatingStyle,
        excludedIngredientIds: preferences.excludedIngredientIds,
        minPortions: preferences.minPortions,
        maxPortions: preferences.maxPortions,
      });
      if (stamp === JSON.stringify([preferences, recipeId, date, people])) result = proposal;
    } catch (e) {
      error = e instanceof Error ? e.message : 'Anpassung fehlgeschlagen';
    } finally {
      busy = false;
    }
  }
  function apply() {
    const r = options.recipes.find((r) => r.id === recipeId);
    if (!r || !result?.servings) return;
    onUsePlan([
      {
        id: r.id,
        title: r.title,
        source: r.source,
        ready: true,
        servings: result.servings * people,
      },
    ]);
  }
</script>

<Card class="analytics-card diet-settings">
  <h2>Dein Ernährungsplan</h2>
  <p class="muted-copy">
    Eigene Tagesziele statt pauschaler Vorgaben. Leer bedeutet kein Ziel. Mindestziele dürfen
    überschritten werden. Einstellungen bleiben in diesem Browser.
  </p>
  <div class="goal-fields">
    <label>
      Vorhaben<select
        value={preferences.purpose}
        onchange={(e) => change({ ...preferences, purpose: e.currentTarget.value })}
      >
        <option value="manual">Eigene Vorgaben</option><option value="maintain">
          Gewicht halten
        </option><option value="gain">Muskelaufbau</option><option value="lose">
          Gewicht reduzieren
        </option>
      </select>
    </label>
    <label>
      Ernährungsweise<select
        value={preferences.eatingStyle}
        onchange={(e) => change({ ...preferences, eatingStyle: e.currentTarget.value })}
      >
        <option value="any">Alle Rezepte</option><option value="vegetarian">
          Vegetarisch markiert
        </option><option value="vegan">Vegan markiert</option>
      </select>
    </label>
    <label>
      Tagesprofil bearbeiten<select bind:value={editProfile}>
        <option value="rest">Ruhetag</option><option value="training">Trainingstag</option>
      </select>
    </label>
  </div>
  <p class="muted-copy">
    Das Vorhaben setzt keine Zahlen automatisch. Lege deine abgestimmten Zielbereiche fest.
  </p>
  <div class="nutrition-table-scroll">
    <table class="nutrition-table">
      <thead><tr><th>Tagesziel</th><th>Minimum</th><th>Maximum</th></tr></thead><tbody>
        {#each dietKeys as key}<tr>
            <td>{labels[key]}</td><td>
              <Input
                type="number"
                min="0"
                step="any"
                aria-label={labels[key] + ' Minimum ' + editProfile}
                value={preferences.profiles[editProfile][key]?.min ?? ''}
                oninput={(e) => bound(key, 'min', e.currentTarget.value)}
              />
            </td><td>
              <Input
                type="number"
                min="0"
                step="any"
                aria-label={labels[key] + ' Maximum ' + editProfile}
                value={preferences.profiles[editProfile][key]?.max ?? ''}
                oninput={(e) => bound(key, 'max', e.currentTarget.value)}
              />
            </td>
          </tr>{/each}
      </tbody>
    </table>
  </div>
  <fieldset>
    <legend>Wiederkehrende Trainingstage</legend>
    <div class="diet-weekdays">
      {#each weekdays as label, index}<label>
          <input
            type="checkbox"
            checked={preferences.trainingWeekdays.includes(index)}
            onchange={(e) =>
              change({
                ...preferences,
                trainingWeekdays: e.currentTarget.checked
                  ? [...preferences.trainingWeekdays, index]
                  : preferences.trainingWeekdays.filter((d) => d !== index),
              })}
          />{label}
        </label>{/each}
    </div>
  </fieldset>
  <div class="goal-fields">
    <label>
      Datum<Input
        type="date"
        value={date}
        oninput={(e) => {
          if (/^\d{4}-\d{2}-\d{2}$/.test(e.currentTarget.value)) date = e.currentTarget.value;
        }}
      />
    </label><label>
      Profil für dieses Datum<select
        value={preferences.overrides[date] ?? 'auto'}
        onchange={(e) => {
          const overrides = { ...preferences.overrides };
          const v = e.currentTarget.value;
          if (v === 'auto') delete overrides[date];
          else overrides[date] = v as 'rest' | 'training';
          change({ ...preferences, overrides });
        }}
      >
        <option value="auto">Wochentag verwenden</option><option value="training">
          Trainingstag
        </option><option value="rest">Ruhetag</option>
      </select>
    </label>
  </div>
  <p>
    Am {date}: {dayProfile(preferences, date) === 'training' ? 'Trainingstag' : 'Ruhetag'}. Protein
    und Ballaststoffe können als reines Minimum geplant werden.
  </p>
  <details class="micros">
    <summary>Zutaten für die automatische Planung ausschließen</summary>
    <p class="muted-copy">
      Filtert die zugeordneten Zutaten. Alternativen, Spuren und Produktinhalte benötigen eine
      eigene Prüfung.
    </p>
    <label>
      Zutat<select bind:value={exclusion}>
        <option value="">
          Auswählen
        </option>{#each options.ingredients.filter((i) => !preferences.excludedIngredientIds.includes(i.id)) as i}<option
            value={i.id}
          >
            {i.name}
          </option>{/each}
      </select>
    </label><Button
      variant="outline"
      disabled={!exclusion}
      onclick={() => {
        change({
          ...preferences,
          excludedIngredientIds: [...preferences.excludedIngredientIds, Number(exclusion)],
        });
        exclusion = '';
      }}
    >
      Ausschließen
    </Button>{#each preferences.excludedIngredientIds as id}<p>
        {options.ingredients.find((i) => i.id === id)?.name ?? id}
        <Button
          variant="ghost"
          onclick={() =>
            change({
              ...preferences,
              excludedIngredientIds: preferences.excludedIngredientIds.filter((i) => i !== id),
            })}
        >
          Entfernen
        </Button>
      </p>{/each}
  </details>
  <h3>Portionen automatisch anpassen</h3>
  <p class="muted-copy">
    Skaliert alle Zutaten gemeinsam. Das Verhältnis von Protein, Fett und Kohlenhydraten bleibt
    gleich. Es werden keine Zutaten ersetzt. Erst deinen Anteil dieser Mahlzeit am Tagesziel
    festlegen; der Rest des Tages wird hier nicht geplant.
  </p>
  <div class="goal-fields">
    <label>
      Anteil am Tagesziel (%)<Input
        type="number"
        min="1"
        max="100"
        step="1"
        placeholder="Selbst festlegen"
        value={preferences.mealShare === undefined ? '' : preferences.mealShare * 100}
        oninput={(e) =>
          change({
            ...preferences,
            mealShare:
              e.currentTarget.value === '' ? undefined : Number(e.currentTarget.value) / 100,
          })}
      />
    </label>
    <label>
      Min. Originalportionen pro Person<Input
        type="number"
        min="0.1"
        max="10"
        step="0.1"
        value={preferences.minPortions}
        oninput={(e) => change({ ...preferences, minPortions: Number(e.currentTarget.value) })}
      />
    </label>
    <label>
      Max. Originalportionen pro Person<Input
        type="number"
        min="0.1"
        max="10"
        step="0.1"
        value={preferences.maxPortions}
        oninput={(e) => change({ ...preferences, maxPortions: Number(e.currentTarget.value) })}
      />
    </label>
  </div>
  <label>
    Nährwertbasis<select
      value={preferences.source}
      onchange={(e) => change({ ...preferences, source: e.currentTarget.value })}
    >
      <option value="bls_complete">
        Nur vollständige Zutatenbilanz für alle gewählten Ziele
      </option><option value="publisher_estimate">
        Herausgeber-Schätzung ausdrücklich verwenden
      </option>
    </select>
  </label>
  <p class="notice">
    Unvollständige BLS-Werte sperren die Anpassung. Herausgeber-Schätzungen werden nur auf Wunsch
    verwendet; sie bleiben getrennt von der BLS-Analyse und enthalten keine ergänzten
    Mikronährwerte.
  </p>
  <form
    class="meal-form"
    onsubmit={(e) => {
      e.preventDefault();
      adapt();
    }}
  >
    <label>
      Rezept<select bind:value={recipeId}>
        {#each options.recipes.filter((r) => preferences.eatingStyle === 'any' || r.tags.includes(preferences.eatingStyle === 'vegan' ? 'Vegan' : 'Vegetarisch') || (preferences.eatingStyle === 'vegetarian' && r.tags.includes('Vegan'))) as r}<option
            value={r.id}
          >
            {r.title}
          </option>{/each}
      </select>
    </label><label>
      Personen mit demselben Ziel<Input
        type="number"
        min="1"
        max="10"
        step="1"
        bind:value={people}
      />
    </label><Button type="submit" disabled={busy || !recipeId}>
      {busy ? 'Wird berechnet …' : 'Portionsvorschlag berechnen'}
    </Button>
  </form>
  {#if error}<p class="error" role="alert">{error}</p>{/if}
  {#if result}<div aria-live="polite">
      <h3>
        {result.status === 'fits'
          ? 'Zielbereiche erreichbar'
          : result.status === 'closest'
            ? 'Näherung – Ziele nicht alle erreichbar'
            : 'Keine belastbare Anpassung möglich'}
      </h3>
      {#if result.sourceUrl}<a href={result.sourceUrl} target="_blank" rel="noreferrer">
          {result.source === 'publisher_estimate'
            ? 'Quelle der Herausgeber-Schätzung'
            : 'Quelle der Zutatenbilanz'}
        </a>{/if}
      {#each result.warnings as warning}<p class="notice">{warning}</p>{/each}
      {#if result.missing.length}<p>
          Fehlend oder unvollständig: {result.missing
            .map((k) => labels[k as DietKey] ?? k)
            .join(', ')}
        </p>{/if}
      {#if result.servings !== null}<p>
          <strong>
            {fmt(result.servings)} Originalportionen pro Person · {fmt(result.servings * people)} zum
            Kochen
          </strong>
        </p>
        <ul>
          {#each dietKeys.filter((k) => result?.nutrients[k] !== undefined) as key}<li>
              {labels[key]}: {fmt(result.nutrients[key]!)} pro Person · Ziel {goalLabel(
                mealTargets(preferences, date)[key]
              )}{result.violations.some((v) => v.key === key) ? ' · nicht erfüllt' : ''}
            </li>{/each}
        </ul>
        <details class="micros">
          <summary>Zutaten für {people} Person(en)</summary>
          <ul>
            {#each result.ingredients as i}<li>
                {i.quantity === null
                  ? i.text
                  : fmt(i.quantity * people) + ' ' + (i.unit ?? '') + ' ' + i.name}{i.optional
                  ? ' (optional)'
                  : ''}
              </li>{/each}
          </ul>
        </details>
        <Button onclick={apply}>Vorschlag als Auswahl übernehmen &amp; Einkaufsliste öffnen</Button>
        <p class="muted-copy">
          Ersetzt die Auswahl. Die Originalrezepte bleiben erhalten. Unbekannte Mengen bleiben
          unskaliert.
        </p>{/if}
    </div>{/if}
  <details class="micros">
    <summary>Einstellungen sichern oder übertragen</summary>
    <p class="muted-copy">
      JSON enthält deine Ziele und Präferenzen. Einfügen und übernehmen, um sie auf diesem Gerät
      wiederherzustellen.
    </p>
    <label>Einstellungen als JSON<textarea rows="5" bind:value={draft}></textarea></label><Button
      variant="outline"
      onclick={() => {
        try {
          change(JSON.parse(draft));
        } catch {
          error = 'Ungültiges JSON';
        }
      }}
    >
      Einstellungen übernehmen
    </Button>
  </details>
</Card>
<Card class="analytics-card">
  <h2>Verbreitete Ernährungsstrategien</h2>
  <p class="muted-copy">
    Lebensmittelauswahl, Energieziele und Essenszeiten sind verschiedene Stellschrauben und können
    kombiniert werden. Keine Rangliste. Quellen geprüft: {strategyReviewedOn}.
  </p>
  {#each dietStrategies as strategy}<details class="micros">
      <summary>{strategy.name}</summary>
      <p>{strategy.summary}</p>
      <p>{strategy.training}</p>
      <p class="notice">{strategy.tradeoff}</p>
      <a href={strategy.url} target="_blank" rel="noreferrer">{strategy.source}</a>
    </details>{/each}
</Card>
