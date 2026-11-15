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
