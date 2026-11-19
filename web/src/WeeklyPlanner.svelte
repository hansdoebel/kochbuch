<script lang="ts">
  import { Card } from '$lib/components/ui/card';
  import { Button } from '$lib/components/ui/button';
  import { Input } from '$lib/components/ui/input';
  import { api, localDate, readLocal, writeLocal } from '$lib/client';
  import type { BasketItem } from '$lib/types';
  import type { WeeklyPlan } from './server/planner';
  let { onUsePlan }: { onUsePlan: (items: BasketItem[]) => void } = $props();
  let start = $state(localDate()),
    maxMinutes = $state(90),
    servings = $state(1),
    vegan = $state(true),
    energy = $state<number | undefined>(undefined),
    protein = $state<number | undefined>(undefined),
    fiber = $state<number | undefined>(undefined),
    busy = $state(false),
    error = $state('');
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
        vegan,
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
        Portionen je Mahlzeit<Input
          type="number"
          min="0.1"
          max="10"
          step="0.1"
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
      <input type="checkbox" bind:checked={vegan} /> Nur als vegan markierte Rezepte
    </label>
    <details class="micros">
      <summary>Optionale Nährwertziele je geplanter Mahlzeit</summary>
      <p class="muted-copy">
        Für die gesamte geplante Portionenmenge. Nur vollständige Werte werden für den Zielvergleich
        genutzt.
      </p>
      <div class="goal-fields">
        <label>
          Energie (kcal)<Input type="number" min="1" max="5000" bind:value={energy} />
        </label><label>
          Protein (g)<Input type="number" min="1" max="300" bind:value={protein} />
        </label><label>
          Ballaststoffe (g)<Input type="number" min="1" max="150" bind:value={fiber} />
        </label>
      </div>
    </details>
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
                {entry.servings}
              </td><td>
                {entry.nutritionUsed
                  ? 'Nährwertziele berücksichtigt'
                  : entry.analysis.profiledCount
                    ? 'Geschätzte Teilwerte'
                    : 'Nicht analysiert'}
              </td>
            </tr>{/each}
        </tbody>
      </table>
    </div>
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
