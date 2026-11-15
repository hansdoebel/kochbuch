# Leitfaden für Rezepte

Diese Regeln gelten für Menschen und Agenten, die ein Rezept ergänzen. Ziel: jede Datei lässt sich unverändert nach Anytype und Notion importieren, und die Einkaufsliste bleibt mit den Markdown-Dateien deckungsgleich.

## Sprache und Namen

Rezepte sind auf Deutsch. Österreichische und deutsche Bezeichnungen bleiben so, wie sie in der Quelle stehen. Nicht stillschweigend umbenennen: Staubzucker bleibt Staubzucker (nicht Puderzucker), Mehl glatt bleibt Mehl glatt, Zwetschkenröster bleibt Zwetschkenröster, Feinkristallzucker bleibt Feinkristallzucker, Germ bleibt Germ, Topfen bleibt Topfen, Paradeiser bleibt Paradeiser. Eine kurze Glosse darf in `## Tipps` stehen.

Mengen, die die Quelle in Gramm angibt, bleiben in Gramm, auch bei Milch oder Rum.

## Einheiten

Metrisch. In Markdown die übliche Schreibweise mit Punkt, wo sie gebräuchlich ist:

| Schreibung | Bedeutung | In `units.code` | Umrechnung |
| --- | --- | --- | --- |
| g | Gramm | `g` | Basis Masse |
| kg | Kilogramm | `kg` | 1000 g |
| ml | Milliliter | `ml` | Basis Volumen |
| l | Liter | `l` | 1000 ml |
| EL | Esslöffel | `EL` | 15 ml, nur wenn die Quelle EL sagt |
| TL | Teelöffel | `TL` | 5 ml, nur wenn die Quelle TL sagt |
| Msp. | Messerspitze | `Msp` | keine feste Umrechnung |
| Prise | Prise | `Prise` | keine Grammzahl erfinden |
| Stk. / Stück | Stück | `Stk` | zählbar |
| Pkt. | Packung | `Pkt` | kein allgemeiner Faktor; Inhalt nur eintragen, wenn er bekannt und als Umrechnung gekennzeichnet ist |
| Bund | Bund | `Bund` | keine feste Umrechnung |
| Glas | Glas | `Glas` | Füllmenge hängt vom Produkt ab |

Eine neue Einheit zuerst in `db/seed.sql` in `units` anlegen, danach verwenden. Masse und Volumen nicht über eine angenommene Dichte ineinander rechnen (200 g Milch und 200 ml Milch bleiben zwei verschiedene Zeilen).

Nicht numerische Angaben:

- `1 Prise Salz` wird zu Menge `1`, Einheit `Prise`. Keine Gramm-Schätzung.
- Eine Wendung wie `geriebene Schale von einer halben Zitrone` bleibt im Markdown wörtlich. In der Datenbank zusätzlich eine kaufbare Menge setzen (`0.5` Stk. Zitrone), die Wendung nach `amount_text`, die Verarbeitung nach `preparation` (`geriebene Schale`). So kann die Einkaufsliste skalieren: zweimal eine halbe Zitrone ergibt 1 Stk.

## Dateinamen

Eine Datei pro Rezept unter `rezepte/`. Der Name ist der Slug plus `.md`:

- Kleinbuchstaben, Ziffern, Bindestriche
- Umlaute und ß auflösen: ä→ae, ö→oe, ü→ue, ß→ss
- Akzente abwerfen: é→e
- keine Leerzeichen, keine Umlaute im Dateinamen

Beispiele: `kaiserschmarrn.md`, `kaesespaetzle.md`, `marillenknodel.md`. `recipes.slug` ist derselbe Name ohne `.md`.

## Markdown-Aufbau

YAML-Frontmatter mit genau diesen flachen Schlüsseln, danach CommonMark. Tags als Kommastring, keine YAML-Liste, keine verschachtelten Objekte, keine mehrzeiligen `|`-Blöcke:

```yaml
---
title: Kaiserschmarrn
slug: kaiserschmarrn
servings: 2
servings_label: Personen
prep_minutes: 20
cook_minutes: 15
source: Demel via Kurier TV
tags: Mehlspeise, Süßspeise, Österreichisch, Demel
---
```

Danach diese Abschnitte, in dieser Reihenfolge:

1. `#` mit dem Titel, ein kurzer Satz zur Quelle
2. `## Zutaten` mit `###`-Gruppen (`Teig`, `Zum Backen`, `Zum Karamellisieren`, …). Jede Zutat eine Aufzählung `- `.
3. `## Zubereitung` als nummerierte Liste
4. `## Tipps` als Aufzählung

Die Gruppennamen im Markdown und in `recipe_ingredients.ingredient_group` sind dieselben. Zeiten, die nicht in der Quelle stehen, im Text als geschätzt kennzeichnen. Eine Rekonstruktion der Schritte klar als solche benennen.

## Import nach Anytype und Notion

- Gewöhnliches CommonMark
- keine HTML-Tags, auch kein `<br>` und kein `<img>`
- keine Markdown-Bilder und keine verlinkten Bilddateien
- keine Fußnoten, keine Aufgabenlisten, keine Wiki-Links (`[[…]]`)
- Frontmatter nur mit den Schlüsseln oben; Werte sind einfache Zeichenketten oder Zahlen

Die Quelle als Text ins Feld `source`. Ein Link auf eine Bilddatei gehört nicht ins Rezept.

## Keine Bilder, kein Binärformat

Niemals Bilder oder andere Binärdateien committen. Das Repo bleibt klein und textbasiert. `.gitignore` blockt die üblichen Endungen und die gebaute SQLite-Datei. Eine Endung, die dort fehlt, ist kein Freibrief: die Datei trotzdem nicht aufnehmen.

## Datenbank mitziehen

Jedes neue Rezept kommt im selben Commit nach `db/seed.sql`. Die Markdown-Datei allein lässt die Einkaufsliste unverändert.

1. Zutat wiederverwenden, wenn `ingredients.name` schon existiert. Neue Zutat mit Abteilung aus `shopping_categories`, Standard-Einheit und `pantry_staple` (1 für Salz, Mehl, Zucker, Staubzucker und Vergleichbares, das die Liste ausblenden können soll).
2. `recipes` mit dem Slug der Datei, Portionen und Zeiten.
3. Eine Zeile in `recipe_ingredients` pro Zutat, `sort_order` in der Reihenfolge des Markdowns (10, 20, 30, …). `optional` ist 1 nur, wenn die Quelle die Zutat als wahlfrei bezeichnet.
4. Tags anlegen oder wiederverwenden und in `recipe_tags` verknüpfen. Tag-Namen exakt so schreiben wie vorhanden.
5. Feste `id`-Werte verwenden (`SELECT MAX(id) + 1` der jeweiligen Tabelle). Dieselben Inserts laufen damit später in Postgres.
6. `python3 db/build_db.py --check` ausführen. `db/kochbuch.sqlite` nicht committen.

Ein Wochenplan-Eintrag ist nur nötig, wenn das Rezept in einem konkreten Plan liegen soll. Die Tabelle dafür ist `meal_plan_entries` (Datum, Mahlzeit, Rezept, Portionen). Übliche Mahlzeiten: Frühstück, Mittagessen, Abendessen, Jause, Nachspeise.
