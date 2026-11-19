<script lang="ts">
  import { Card } from '$lib/components/ui/card';
  import { Button } from '$lib/components/ui/button';
  import { Input } from '$lib/components/ui/input';
  import { api, localDate, readLocal, writeLocal } from '$lib/client';
  import type { BasketItem } from '$lib/types';
  import type { DietPreferences } from '$lib/diet';
  import type { WeeklyPlan } from './server/planner';
  let {
    onUsePlan,
    preferences,
  }: { preferences: DietPreferences; onUsePlan: (items: BasketItem[]) => void } = $props();
  let start = $state(localDate()),
    maxMinutes = $state(90),
    servings = $state(1),
    vegan = $state(true),
    energy = $state<number | undefined>(undefined),
    protein = $state<number | undefined>(undefined),
    fiber = $state<number | undefined>(undefined),
    busy = $state(false),
    error = $state('');
  let useDiet = $state(false),
    allowAdvancePrep = $state(false);
  let mainOnly = $state(true);
  let maxRepeats = $state(3);
  let plan = $state<WeeklyPlan | null>(null);
  const saved = readLocal<WeeklyPlan | null>('weekly-plan:v1', null);
  if (
    saved &&
    Array.isArray(saved.entries) &&
    Array.isArray(saved.selections) &&
    Array.isArray(saved.warnings) &&
    saved.entries.length <= 7
  )
    plan = saved;
  async function generate() {
    busy = true;
    error = '';
    try {
      plan = await api<WeeklyPlan>('/api/plan/suggest', {
        startDate: start,
        days: 7,
        servings,
        maxMinutes,
        vegan: useDiet ? false : vegan,
        allowAdvancePrep,
        diet: useDiet ? preferences : undefined,
        mainOnly,
        maxRepeats,
        targetsPerMeal: { energy_kcal: energy, protein_g: protein, fiber_g: fiber },
      });
      writeLocal('weekly-plan:v1', plan);
    } catch (e) {
      error = e instanceof Error ? e.message : 'Planung fehlgeschlagen';
    } finally {
      busy = false;
    }
  }
  function usePlan() {
    if (!plan) return;
    const items: BasketItem[] = plan.selections.map((s) => {
      const e = plan!.entries.find((e) => e.id === s.id)!;
      return { ...s, title: e.title, source: e.source, ready: e.ready };
    });
    onUsePlan(items);
  }
</script>

<Card class="analytics-card weekly-planner">
  <h2>Deine Woche vorschlagen</h2>
  <p class="muted-copy">
    Eine Mahlzeit pro Tag. Gemeinsame Zutaten, Abwechslung und Kochzeit helfen beim Planen. Der
    Vorschlag bleibt getrennt von deinem Verzehr.
  </p>
  <form
    class="meal-form"
    onsubmit={(e) => {
      e.preventDefault();
      generate();
    }}
  >
    <div class="goal-fields">
      <label>Ab Datum<Input type="date" bind:value={start} required /></label><label>
        {useDiet ? 'Personen mit demselben Tagesziel' : 'Portionen je Mahlzeit'}<Input
          type="number"
          min={useDiet ? 1 : 0.1}
          max="10"
          step={useDiet ? 1 : 0.1}
          bind:value={servings}
          required
        />
      </label><label>
        Max. Kochzeit (Min.)<Input
          type="number"
          min="1"
          max="360"
          bind:value={maxMinutes}
          required
        />
      </label>
    </div>
    <label>
      Max. Wiederholungen je Rezept<Input
        type="number"
        min="1"
        max="3"
        bind:value={maxRepeats}
        required
      />
    </label>
    <label class="planner-check">
      <input type="checkbox" bind:checked={mainOnly} /> Nur Hauptgerichte
    </label>
    <label class="planner-check">
      <input type="checkbox" bind:checked={useDiet} /> Tagesprofile verwenden und persönliche Portionen
      anpassen
    </label>
    {#if useDiet}<p class="notice">
        Verwendet Training/Ruhetag, Ernährungsweise und ausgeschlossene Zutaten aus deinen
        Einstellungen. {preferences.source === 'publisher_estimate'
          ? 'Herausgeber-Schätzungen ausdrücklich gewählt.'
          : 'Nur vollständige Zutatenwerte für alle Ziele.'} Anteil der Mahlzeit am Tagesziel vorher festlegen.
        Die Personenanzahl vergrößert nur die Kochmenge.
      </p>{/if}
    <label class="planner-check">
      <input type="checkbox" bind:checked={allowAdvancePrep} /> Rezepte mit Vorbereitung am Vortag erlauben
    </label>
    <label class="planner-check">
      <input type="checkbox" disabled={useDiet} bind:checked={vegan} /> Nur als vegan markierte Rezepte
    </label>
    {#if !useDiet}<details class="micros">
        <summary>Optionale Nährwertziele je geplanter Mahlzeit</summary>
        <p class="muted-copy">
          Für die gesamte geplante Portionenmenge. Nur vollständige Werte werden für den
          Zielvergleich genutzt.
        </p>
        <div class="goal-fields">
          <label>
            Energie (kcal)<Input type="number" min="1" max="5000" bind:value={energy} />
          </label><label>
            Protein mindestens (g)<Input type="number" min="1" max="300" bind:value={protein} />
          </label><label>
            Ballaststoffe mindestens (g)<Input type="number" min="1" max="150" bind:value={fiber} />
          </label>
        </div>
      </details>{/if}
    <Button type="submit" disabled={busy}>{busy ? 'Wird geplant …' : '7 Tage vorschlagen'}</Button>
  </form>
  {#if error}<p role="alert" class="error">{error}</p>{/if}
  {#if plan}<div class="nutrition-table-scroll">
      <table class="nutrition-table">
        <thead>
          <tr><th>Datum</th><th>Mahlzeit</th><th>Portionen</th><th>Datenlage</th></tr>
        </thead><tbody>
          {#each plan.entries as entry}<tr>
              <td>{entry.date}</td><td>{entry.title}<small>{entry.minutes} Min.</small></td><td>
                {new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 }).format(
                  entry.servings
                )}
                {#if entry.adaptation?.servings}<small>
                    {entry.adaptation.servings.toFixed(2)} pro Person · {entry.profile ===
                    'training'
                      ? 'Training'
                      : 'Ruhetag'}
                  </small>{/if}
              </td><td>
                {#if entry.adaptation}<span>
                    {entry.adaptation.status === 'fits'
                      ? 'Zielbereiche erreicht'
                      : 'Näherung, Ziele nicht alle erfüllt'} · {entry.adaptation.source ===
                    'publisher_estimate'
                      ? 'Herausgeber-Schätzung'
                      : 'Zutatenbilanz'}
                  </span>{:else}{entry.nutritionUsed
                    ? 'Nährwertziele berücksichtigt'
                    : entry.analysis.profiledCount
                      ? 'Geschätzte Teilwerte'
                      : 'Nicht analysiert'}{/if}
                {#each entry.adaptation?.violations ?? [] as v}<small>
                    {v.key}: {v.value.toFixed(1)} · Ziel {v.min ?? 'offen'}–{v.max ?? 'offen'}
                  </small>{/each}
              </td>
            </tr>{/each}
        </tbody>
      </table>
    </div>
    {#if plan.unplannedDates?.length}<p class="notice">
        Ohne Vorschlag: {plan.unplannedDates.join(', ')}
      </p>{/if}
    {#each plan.warnings as warning}<p class="notice">{warning}</p>{/each}<Button
      disabled={!plan.entries.length}
      onclick={usePlan}
    >
      Plan als Auswahl übernehmen &amp; Einkaufsliste öffnen
    </Button>
    <p class="muted-copy">
      Ersetzt die aktuelle Rezeptauswahl. Mehrfach geplante Rezepte werden zusammengezählt.
    </p>{/if}
</Card>
