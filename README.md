# Kochbuch

Privates Rezeptarchiv von Hans Döbel, auf Deutsch. Jedes Rezept ist eine Markdown-Datei. Eine SQLite-Datenbank baut daraus Wochenplan und Einkaufsliste.

## Ordner

```text
rezepte/                 eine Datei pro Rezept
db/schema.sql            Tabellen, Einheiten, View für die Einkaufsliste
db/seed.sql              Daten, im Gleichschritt mit den Markdown-Dateien
db/shopping_list.sql     Beispielabfrage für den hinterlegten Wochenplan
db/build_db.py           erzeugt db/kochbuch.sqlite und druckt die Liste
db/README.md             Schema und der Weg nach Postgres/Neon
AGENTS.md                Regeln für neue Rezepte
```

`db/kochbuch.sqlite` wird nicht eingecheckt. Sie lässt sich jederzeit aus den SQL-Dateien neu bauen, und eine Binärdatei würde das Repo aufblähen und sich schlecht zusammenführen lassen. Bilder und andere Binärdateien sind über `.gitignore` ausgeschlossen.

## Rezept hinzufügen

1. `rezepte/<slug>.md` nach `AGENTS.md` anlegen.
   Die Original-Rezeptseite prüfen; Urheber, Website und direkte URL identisch in `source` und `recipes.source` erfassen. Unter dem Titel einen sichtbaren Quellenlink setzen. Bei nicht öffentlichen Quellen die tatsächliche Herkunft nennen, keine URL erfinden.
2. Dieselben Angaben in `db/seed.sql` ergänzen: Rezept, Zutatenzeilen, Tags. Vorhandene Zutaten wiederverwenden.
3. Datenbank neu bauen und die Einkaufsliste prüfen:

```bash
python3 db/build_db.py --check
```

Ohne `--check` druckt das Skript die Liste für den Beispielzeitraum (16.–22. November 2026). Ein anderer Zeitraum:

```bash
python3 db/build_db.py 2026-11-16 2026-11-22
python3 db/build_db.py 2026-11-16 2026-11-22 --ohne-vorrat
```

`--ohne-vorrat` lässt Zutaten weg, die im Haushalt meist schon da sind (Salz, Mehl, Zucker, Staubzucker).

Dieselbe Abfrage direkt in SQLite, nachdem die Datei erzeugt wurde:

```bash
sqlite3 -header -column db/kochbuch.sqlite < db/shopping_list.sql
```

## Einkaufsliste

Ein Eintrag im Wochenplan nennt Datum, Mahlzeit, Rezept und die gewünschten Portionen. Die View `v_meal_plan_lines` rechnet die Mengen mit `gewünschte Portionen / Rezeptportionen` um. Die Beispielabfrage summiert danach pro Zutat, Variante und Einheit und gruppiert nach Supermarkt-Abteilung.

Der hinterlegte Plan enthält Kaiserschmarrn für 2 Personen am 16. November 2026. Feinkristallzucker steht zweimal im Rezept (30 g im Teig, 50 g zum Karamellisieren) und erscheint auf der Liste als 80 g.

Schema, Einheiten, nicht numerische Angaben und der Umzug auf Postgres (zum Beispiel Neon) stehen in `db/README.md`.

## Öffentliche Rezeptarchive

Die Original-Rezeptdaten von Rainbow Plant Life, Babish und Joshua Weissman stehen unter `quellen/`. Abdeckung, Unterschiede zu den deutschen Kochbuch-Rezepten und die Wiederholung des Abrufs sind in [quellen/README.md](quellen/README.md) dokumentiert. Die ersten fünf Rainbow-Plant-Life-Rezepte sind außerdem auf Deutsch in `rezepte/` und in der Zutaten-Datenbank erfasst.

Offline prüfen:

```bash
python3 scripts/check_sources.py
python3 -m unittest discover -s scripts -v
python3 db/build_db.py --check
```

## Automatische Rezeptprüfung

GitHub Actions führt bei jedem Pull Request und bei Änderungen auf `main` vier unabhängige Prüfungen parallel aus: Markdown-Formatierung mit `markdownlint-cli2`, Rezeptformat samt Quellen und Datenbankabgleich, Integrität des Quellenarchivs und Regressionstests. Fehler in einem Job brechen die anderen nicht ab. Diese Regeln werden vom Code durchgesetzt und benötigen keine Agenten- oder Skill-Anweisungen. Husky-Hooks sind nicht nötig.

Node.js 24 und Python 3.10+ genügen für dieselben Prüfungen lokal:

```bash
npm ci --ignore-scripts
npm run lint
npm test
```

`npm run lint` führt die drei Linter parallel aus und meldet einen Fehler, sobald mindestens eine Prüfung fehlschlägt. Einzeln laufen sie über `npm run lint:markdown`, `npm run lint:recipes` und `npm run lint:sources`. Die Markdown-Regeln stehen in `.markdownlint-cli2.jsonc`; das Rezeptformat wird in `scripts/lint_recipes.py` geprüft. Online-Rezepte brauchen eine direkte HTTPS-Quelle und denselben sichtbaren Link. Eigene Rezepte, Fotos und Familienrezepte müssen ihre nicht öffentliche Herkunft ausdrücklich nennen. Die vorhandene Kaiserschmarrn-Transkription hat eine eng begrenzte Ausnahme für ihre belegte Quelle ohne nachweisbare URL.

## Weboberfläche

Unter [`web/`](web/README.md) liegt eine Svelte-5-/shadcn-svelte-Oberfläche mit Bun-API. Sie durchsucht die vorhandenen Rezeptarchive und kuratierten Rezepte, speichert eine Rezeptauswahl lokal und exportiert Einkaufslisten über eine mobile Typst-Vorlage als PDF, eigenständige `.typ`-Datei oder JSON. Light/Dark Mode und eine Ernährungsansicht mit persönlichen Zielen und getrenntem Verzehrprotokoll sind enthalten.

```bash
cd web
bun install --frozen-lockfile
bun run setup:typst
bun run build
bun run start
```

Danach `http://127.0.0.1:3000` öffnen. Für Details, Entwicklung und Prüfungen siehe [web/README.md](web/README.md). Kuratierte Zutaten sind skalierbar; Archivrezepte behalten ihre Originalmengen. Nährwertprofile sind noch nicht analysiert und werden nicht als Nullwerte ausgegeben. Der nächste Schritt zur Zutatenanalyse ist in [nutrition/README.md](nutrition/README.md) beschrieben. Die [Open-Source-Recherche](docs/webui-research.md) dokumentiert die Auswahl der Architektur.

## Nährwerte und Wochenplanung

Die Ernährungsansicht verwendet versionierte Referenzdaten des Max Rubner-Instituts: BLS 4.0 (CC BY 4.0), 7.140 Lebensmittel und 17 Nährstoffe pro 100 g. Freigegebene Zutatenzuordnungen erzeugen automatisch geschätzte Rezeptprofile; fehlende Mengen bleiben als Teilsummen erkennbar. Die Lebensmittel-Tabelle zeigt Herkunft und Lizenz. Ein Wochenvorschlag berücksichtigt Zeit, Abwechslung und gemeinsame Zutaten und lässt sich als Einkaufsliste exportieren. Erweiterung und regelmäßige Prüfung: [nutrition/README.md](nutrition/README.md).
