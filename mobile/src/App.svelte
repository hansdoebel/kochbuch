<script lang="ts">
  import { onMount } from "svelte";
  import { App as NativeApp } from "@capacitor/app";
  import { Share } from "@capacitor/share";
  import { current, sync, read, save } from "./store";
  import { analyse } from "../../web/src/lib/analysis";
  import { suggestPlan } from "../../web/src/server/planner";
  import type { Recipe } from "../../web/src/lib/types";
  import {
    defaultDietPreferences,
    dietKeys,
    goalLabel,
    type DietKey,
    type DietPreferences,
  } from "../../web/src/lib/diet";
  type Entry = { date: string; id: string; servings: number };
  const today = () => new Date().toLocaleDateString("sv-SE");
  const plus = (date: string, n: number) => {
    const d = new Date(date + "T12:00:00Z");
    d.setUTCDate(d.getUTCDate() + n);
    return d.toISOString().slice(0, 10);
  };
  const fmt = (x: number) =>
    x.toLocaleString("de-DE", { maximumFractionDigits: 1 });
  const names: Record<DietKey, string> = {
    energy_kcal: "Energie (kcal)",
    protein_g: "Protein (g)",
    fiber_g: "Ballaststoffe (g)",
    carbs_g: "Kohlenhydrate (g)",
    fat_g: "Fett (g)",
  };
  let snapshot = $state.raw<Awaited<ReturnType<typeof current>> | null>(null),
    tab = $state("Rezepte"),
    query = $state(""),
    limit = $state(30),
    detail = $state<Recipe | null>(null),
    favoritesOnly = $state(false);
  let favorites = $state(read<string[]>("favorites", [])),
    plan = $state(read<Entry[]>("plan", [])),
    log = $state(read<Entry[]>("log", []));
  let prefs = $state<DietPreferences>(read("prefs", defaultDietPreferences())),
    profile = $state(read("profile", { name: "", height: "", weight: "" })),
    edit = $state<"training" | "rest">("rest");
  let origin = $state(read("origin", "")),
    busy = $state(false),
    message = $state(""),
    start = $state(today()),
    day = $state(today()),
    portions = $state(1);
  const recipes = $derived(snapshot?.recipes ?? []),
    byId = $derived(new Map(recipes.map((r) => [r.id, r])));
  const matches = $derived(
    recipes.filter(
      (r) =>
        (!favoritesOnly || favorites.includes(r.id)) &&
        (!query ||
          [r.title, r.source, ...r.ingredients]
            .join(" ")
            .toLocaleLowerCase()
            .includes(query.trim().toLocaleLowerCase())),
    ),
  );
  const week = $derived(
    Array.from({ length: 7 }, (_, i) => plus(start || today(), i)),
  );
  const eaten = $derived(log.filter((e) => e.date === day));
  const nutrition = $derived(
    eaten.flatMap((entry) => {
      const recipe = byId.get(entry.id);
      return recipe
        ? [
            {
              entry,
              analysis: analyse(
                [{ id: entry.id, servings: entry.servings }],
                () => recipe,
              ),
            },
          ]
        : [];
    }),
  );
  $effect(() => {
    save("favorites", favorites);
    save("plan", plan);
    save("log", log);
    save("prefs", prefs);
    save("profile", profile);
    save("origin", origin);
  });
  onMount(() => {
    current()
      .then((s) => (snapshot = s))
      .catch((e) => (message = e.message));
    const back = NativeApp.addListener("backButton", () => {
      if (detail) detail = null;
      else if (tab !== "Rezepte") navigate("Rezepte");
      else NativeApp.minimizeApp();
    });
    return () => {
      void back.then((listener) => listener.remove());
    };
  });
  function navigate(t: string) {
    tab = t;
    detail = null;
    message = "";
    window.scrollTo(0, 0);
  }
  function open(r: Recipe) {
    detail = r;
    portions = 1;
    message = "";
    window.scrollTo(0, 0);
  }
  async function refresh() {
    busy = true;
    message = "";
    try {
      const old = snapshot ?? (await current());
      snapshot = await sync(origin, old);
      message = snapshot === old ? "Bereits aktuell." : "Rezepte aktualisiert.";
    } catch (e) {
      message =
        e instanceof Error ? e.message : "Synchronisieren fehlgeschlagen.";
    } finally {
      busy = false;
    }
  }
  function append(target: "plan" | "log") {
    if (!detail || !day || !(portions > 0 && portions <= 100)) return;
    const entry = { id: detail.id, date: day, servings: portions };
    if (target === "plan") plan = [...plan, entry];
    else log = [...log, entry];
    message =
      target === "plan" ? "Im Wochenplan gespeichert." : "Verzehr gespeichert.";
  }
  function generate() {
    try {
      const hasTargets =
        Object.keys(prefs.profiles.rest).length ||
        Object.keys(prefs.profiles.training).length;
      const candidates = recipes.filter(
        (r) =>
          r.ready &&
          (prefs.eatingStyle === "any" ||
            r.tags.includes("Vegan") ||
            (prefs.eatingStyle === "vegetarian" &&
              r.tags.includes("Vegetarisch"))),
      );
      const result = suggestPlan(
        {
          startDate: start,
          days: 7,
          ...(hasTargets ? { diet: $state.snapshot(prefs) } : {}),
        },
        candidates,
      );
      const free = result.entries.filter(
        (e) => !plan.some((p) => p.date === e.date),
      );
      plan = [
        ...plan,
        ...free.map(({ id, date, servings }) => ({ id, date, servings })),
      ];
      message = free.length + " Tage ergänzt. " + result.warnings.join(" ");
    } catch (e) {
      message = e instanceof Error ? e.message : "Planung fehlgeschlagen.";
    }
  }
  function setGoal(key: DietKey, value: string) {
    if (value === "") delete prefs.profiles[edit][key];
    else {
      const n = Number(value);
      if (Number.isFinite(n) && n > 0)
        prefs.profiles[edit][key] =
          key === "protein_g" || key === "fiber_g"
            ? { min: n }
            : { min: n, max: n };
    }
  }
</script>

<header><strong>Kochbuch</strong><span>{profile.name}</span></header>
<main>
  {#if message}<p role="status" class="notice">{message}</p>{/if}
  {#if detail}
    <button onclick={() => (detail = null)}>← Zurück</button>
    <p class="source">{detail.source}</p>
    <h1>{detail.title}</h1>
    <p>
      {detail.servingsText} · {detail.minutes
        ? detail.minutes + " Min."
        : "Zeit offen"}
    </p>
    <button
      onclick={() => {
        const id = detail!.id;
        favorites = favorites.includes(id)
          ? favorites.filter((f) => f !== id)
          : [...favorites, id];
      }}
    >
      {favorites.includes(detail.id) ? "★ Gespeichert" : "☆ Merken"}
    </button>
    <h2>Zutaten</h2>
    <ul>
      {#each detail.ingredients as i}<li>{i}</li>{/each}
    </ul>
    <h2>Zubereitung</h2>
    <ol>
      {#each detail.instructions as step}<li>{step}</li>{/each}
    </ol>
    {#if detail.publisherNutrition}<h2>Herausgeber-Schätzung je Portion</h2>
      <p>
        {detail.publisherNutrition.nutrients.energy_kcal} kcal · {detail
          .publisherNutrition.nutrients.protein_g} g Protein · {detail
          .publisherNutrition.nutrients.fiber_g} g Ballaststoffe · {detail
          .publisherNutrition.nutrients.publisher_carbohydrates_g} g Kohlenhydrate
        · {detail.publisherNutrition.nutrients.fat_g} g Fett
      </p>{/if}
    <h2>Zutatenbilanz je Portion</h2>
    {#if detail.nutrition}<p>
        Bekannte Werte. Lücken in der Zutatenabdeckung ergeben Teilsummen.
      </p>
      {#each Object.entries(detail.nutrition.nutrients) as [k, v]}{#if typeof v === "number"}<div
            class="row"
          >
            <span>{names[k as DietKey] ?? k}</span><b>{fmt(v)}</b>
          </div>{/if}{/each}{:else}<p>Keine Zutatenbilanz verfügbar.</p>{/if}
    {#if detail.sourceUrl?.startsWith("https://")}<p>
        <a href={detail.sourceUrl} target="_blank" rel="noreferrer">
          Originalrezept öffnen
        </a>
      </p>{/if}
    <label>Datum<input type="date" bind:value={day} /></label><label>
      Originalportionen<input
        type="number"
        min=".1"
        max="100"
        step=".1"
        bind:value={portions}
      />
    </label>
    <div class="actions">
      <button onclick={() => append("plan")}>Einplanen</button><button
        onclick={() => append("log")}
      >
        Als gegessen erfassen
      </button>
    </div>
  {:else if tab === "Rezepte"}
    <h1>Was kochen wir?</h1>
    <input
      aria-label="Rezepte durchsuchen"
      placeholder="Rezept oder Zutat suchen"
      bind:value={query}
      oninput={() => (limit = 30)}
    /><button
      aria-pressed={favoritesOnly}
      onclick={() => (favoritesOnly = !favoritesOnly)}
    >
      ★ Gemerkte Rezepte
    </button>
    <p>{snapshot ? matches.length + " Rezepte" : "Sammlung wird geladen …"}</p>
    {#each matches.slice(0, limit) as r (r.id)}<button
        class="recipe"
        onclick={() => open(r)}
      >
        <small>{r.source}</small><strong>{r.title}</strong><span>
          {r.minutes ? r.minutes + " Min. · " : ""}{r.servingsText}
        </span>
      </button>{/each}{#if matches.length > limit}<button
        onclick={() => (limit += 30)}
      >
        Mehr anzeigen
      </button>{/if}
  {:else if tab === "Woche"}
    <h1>Deine Woche</h1>
    <label>Woche ab<input type="date" bind:value={start} /></label><button
      disabled={!start || !snapshot}
      onclick={generate}
    >
      Freie Tage mit Vorschlägen füllen
    </button>
    {#each week as d}<section>
        <h2>
          {new Date(d + "T12:00:00").toLocaleDateString("de-DE", {
            weekday: "long",
            day: "numeric",
            month: "short",
          })}
        </h2>
        {#each plan.filter((e) => e.date === d) as e}<div class="row">
            <button
              class="link"
              onclick={() => {
                const r = byId.get(e.id);
                if (r) open(r);
              }}
            >
              {byId.get(e.id)?.title ?? e.id} · {fmt(e.servings)} Port.
            </button><button
              aria-label="Eintrag entfernen"
              onclick={() => (plan = plan.filter((p) => p !== e))}
            >
              ×
            </button>
          </div>{/each}<button
          onclick={() => {
            day = d;
            navigate("Rezepte");
          }}
        >
          Rezept hinzufügen
        </button>
      </section>{/each}
    <button
      onclick={async () => {
        try {
          await Share.share({
            title: "Wochenplan",
            text: plan
              .filter((e) => week.includes(e.date))
              .map(
                (e) =>
                  e.date +
                  " · " +
                  (byId.get(e.id)?.title ?? e.id) +
                  " · " +
                  fmt(e.servings) +
                  " Port.",
              )
              .join("\n"),
          });
        } catch {
          message = "Teilen beendet.";
        }
      }}
    >
      Wochenplan teilen
    </button>
  {:else if tab === "Analyse"}
    <h1>Dein Verzehr</h1>
    <label>Tag<input type="date" bind:value={day} /></label>
    <p>{eaten.length} erfasste Mahlzeiten</p>
    {#each dietKeys as key}
      {@const known = nutrition.filter(
        (n) => typeof n.analysis.totals[key] === "number",
      )}
      {@const goal =
        prefs.profiles[
          prefs.trainingWeekdays.includes(new Date(day + "T12:00:00").getDay())
            ? "training"
            : "rest"
        ][key]}
      <section>
        <small>{names[key]}</small>
        <h2>
          {known.length
            ? fmt(known.reduce((s, n) => s + n.analysis.totals[key]!, 0))
            : "—"}
        </h2>
        <p>
          Ziel {goalLabel(goal)} · {known.filter(
            (n) => n.analysis.completeCoverage[key] === 1,
          ).length}/{eaten.length} vollständig
        </p>
      </section>{/each}
    {#each eaten as e}<div class="row">
        <span>
          {byId.get(e.id)?.title ?? e.id} · {fmt(e.servings)} Port.
        </span><button
          aria-label="Verzehr entfernen"
          onclick={() => (log = log.filter((p) => p !== e))}
        >
          ×
        </button>
      </div>{/each}<button onclick={() => navigate("Rezepte")}>
      Verzehr über Rezept erfassen
    </button>
  {:else}
    <h1>Einstellungen</h1>
    <h2>Persönliches Profil</h2>
    <label>Name<input bind:value={profile.name} /></label><label>
      Größe (cm)<input
        type="text"
        inputmode="decimal"
        bind:value={profile.height}
      />
    </label><label>
      Gewicht (kg)<input
        type="text"
        inputmode="decimal"
        bind:value={profile.weight}
      />
    </label>
    <p>Profil, Wochenplan und Verzehr bleiben auf diesem Gerät.</p>
    <label>
      Ernährungsweise<select bind:value={prefs.eatingStyle}>
        <option value="any">Alle</option><option value="vegetarian">
          Vegetarisch
        </option><option value="vegan">Vegan</option>
      </select>
    </label>
    <h2>Tagesziele</h2>
    <label>
      Profil<select bind:value={edit}>
        <option value="rest">Ruhetag</option><option value="training">
          Trainingstag
        </option>
      </select>
    </label>{#each dietKeys as k}<label>
        {names[k]}
        {k === "protein_g" || k === "fiber_g" ? "mindestens" : ""}<input
          type="number"
          min="0"
          value={prefs.profiles[edit][k]?.min ?? ""}
          onchange={(e) => setGoal(k, e.currentTarget.value)}
        />
      </label>{/each}
    <fieldset>
      <legend>
        Trainingstage
      </legend>{#each ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"] as name, i}<label
          class="check"
        >
          <input
            type="checkbox"
            checked={prefs.trainingWeekdays.includes(i)}
            onchange={(e) =>
              (prefs.trainingWeekdays = e.currentTarget.checked
                ? [...prefs.trainingWeekdays, i]
                : prefs.trainingWeekdays.filter((n) => n !== i))}
          />{name}
        </label>{/each}
    </fieldset>
    <label>
      Mahlzeitenanteil am Tagesziel (%)<input
        type="number"
        min="1"
        max="100"
        value={prefs.mealShare ? prefs.mealShare * 100 : ""}
        onchange={(e) => {
          const v = Number(e.currentTarget.value);
          prefs.mealShare = v > 0 && v <= 100 ? v / 100 : undefined;
        }}
      />
    </label><label>
      Nährwertbasis für Vorschläge<select bind:value={prefs.source}>
        <option value="bls_complete">Vollständige Zutatenbilanz</option><option
          value="publisher_estimate"
        >
          Herausgeber-Schätzung
        </option>
      </select>
    </label>
    <h2>Rezepte synchronisieren</h2>
    <label>
      Kochbuch-Server (HTTPS)<input
        type="url"
        placeholder="https://kochbuch.example.org"
        bind:value={origin}
      />
    </label>
    <p>
      {snapshot?.updated
        ? "Zuletzt aktualisiert " +
          new Date(snapshot.updated).toLocaleString("de-DE")
        : "Mitgelieferte Rezeptsammlung"}
    </p>
    <button disabled={busy || !origin} onclick={refresh}>
      {busy ? "Wird geladen …" : "Jetzt synchronisieren"}
    </button>
  {/if}
</main>
<nav aria-label="Navigation">
  {#each ["Rezepte", "Woche", "Analyse", "Profil"] as name}<button
      class:active={name === tab}
      onclick={() => navigate(name)}
    >
      {name}
    </button>{/each}
</nav>
