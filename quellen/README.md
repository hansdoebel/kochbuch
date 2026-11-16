# Quellenarchiv

Die JSON-Dateien sichern öffentliche Rezeptkarten von Rainbow Plant Life, Babish, Joshua Weissman, [Cook Well / Ethan Chlebowski](https://app.cookwell.com/recipes), [RecipeTin Eats](https://www.recipetineats.com/), [Zucker & Jagdwurst](https://www.zuckerjagdwurst.com/de), [Maangchi](https://www.maangchi.com/recipes) und [Pick Up Limes](https://www.pickuplimes.com/recipe/). Jede Karte nennt ihre konkrete Original-URL und die Urheberangabe aus der Quelle. Die Rechte verbleiben bei den jeweiligen Urhebern.

Das Archiv enthält Originaltexte auf Englisch beziehungsweise Deutsch, Originalmengen und Quellzeiten. Es ist die Grundlage für die weitere Übertragung ins Kochbuch. Nur die fünf bereits übersetzten Rainbow-Plant-Life-Rezepte stehen zusätzlich unter `rezepte/` und in `db/seed.sql`; die übrigen Archivkarten sind noch nicht in der Einkaufslisten-Datenbank. Keine automatischen Übersetzungen oder stillen Umrechnungen: vor der Übernahme die Regeln in `AGENTS.md` anwenden.

## Umfang

Abgerufen am 16. November 2026. Die konkreten Zahlen und jeder einzelne Seitenstatus stehen im jeweiligen `manifest.json`. Der Umfang ist das zu diesem Zeitpunkt öffentlich auffindbare Rezeptarchiv; Inhalte aus kostenpflichtigen Angeboten und Büchern werden nicht erschlossen.

| Quelle | Geprüfte Seiten | Vollständige Rezeptkarten | Unvollständige Quellkarten | Zugangsbeschränkt | Ohne Rezeptkarte | Abruffehler |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Rainbow Plant Life | 403 | 329 | 0 | 0 | 74 | 0 |
| Babish | 632 | 628 | 4 | 0 | 0 | 0 |
| Joshua Weissman | 803 | 800 | 3 | 0 | 0 | 0 |
| Cook Well | 626 | 307 | 1 | 318 | 0 | 0 |
| RecipeTin Eats | 1778 | 1542 | 0 | 0 | 236 | 0 |
| Zucker & Jagdwurst | 1046 | 1120 | 4 | 0 | 24 | 0 |
| Maangchi | 451 | 451 | 0 | 0 | 0 | 0 |
| Pick Up Limes | 490 | 489 | 0 | 0 | 1 | 0 |
| Gesamt | 6229 | 5666 | 12 | 318 | 335 | 0 |

- Rainbow Plant Life: Beitrags- und Seitensitemaps aus `sitemap_index.xml`; mehrere Rezeptkarten auf einer Seite werden einzeln erfasst. Nicht-Rezeptseiten werden als `no_recipe` dokumentiert.
- Babish: alle `/recipes/`-Einträge aus `sitemap.xml`. Die Urheberangabe wird so übernommen, wie sie die Rezeptkarte nennt (zum Beispiel `bingingwithbabish`). Vier als Rezept ausgezeichnete Ratgeberseiten haben keine Zutaten oder keine Anleitung; sie bleiben ausdrücklich `incomplete`.
- Joshua Weissman: alle 90 Seiten des Rezeptindexes, bis keine nächste Seite mehr verlinkt ist. Zutaten und Anleitungen stehen teils erst nach JavaScript-Ausführung im JSON-LD; der Scraper liest dafür die öffentlich sichtbaren HTML-Rezeptlisten. Gruppen, zusätzliche Absätze und Hinweise bleiben in `ingredient_sections` und `instruction_sections` erhalten. Nicht standardisierte Zeitangaben wie „overnight“ bleiben unverändert.
- Cook Well: alle `/recipe/`-URLs des öffentlichen App-Sitemaps. Karten mit `isAccessibleForFree: false` werden als `restricted` protokolliert; ihre Rezeptdaten werden nicht gespeichert. Als Urheber bleibt die tatsächliche Kartenangabe erhalten, etwa Ethan Chlebowski oder Cook Well Official. Diese Erweiterung wurde mit Cook Well begonnen.
- RecipeTin Eats: Beitrags- und Seitensitemaps; Blogbeiträge, Verzeichnisse, Sammlungen und Buchvorschauen ohne öffentliche Rezeptkarte bleiben `no_recipe`. Die Videos zu exklusiven Buchrezepten ersetzen keine öffentlich verfügbare Zutatenliste.
- Zucker & Jagdwurst: alle deutschen `/de/rezepte/`-Seiten des Sitemaps. Die englischen Parallelfassungen werden nicht doppelt erfasst. Eine Seite kann mehrere eigenständige Rezeptkarten enthalten. Fehlende persönliche Urheberangaben werden nicht durch Namen aus dem allgemeinen Website-Footer ersetzt, sondern als unvollständig markiert.
- Maangchi: alle `/recipe/`-URLs aus den jährlichen Beitrags-Sitemaps. Die sichtbaren Zutaten- und Anleitungslisten sind maßgeblich, da manche Quell-JSONs Zutaten auslassen oder leere Anleitungsschritte liefern. Ältere Artikel werden anhand ihrer Rezeptüberschriften erfasst; Seiten ohne Recipe-JSON-LD verwenden den sichtbaren Originaltitel und die Byline. Auch als Rezept ausgezeichnete Anleitungen zum Herstellen von Grundzutaten bleiben enthalten.
- Pick Up Limes: alle `/recipe/`-URLs im öffentlichen Sitemap. Verschachtelte Textlisten mit Arbeitsschritten sowie die Hinweise zu Rezept und Aufbewahrung werden erfasst. Keine Premium-Inhalte aus der App.

**Serious Eats ist ausgeschlossen.** Der Herausgeber untersagt automatisiertes Content-Archiving ohne vorherige schriftliche Erlaubnis in [robots.txt](https://www.seriouseats.com/robots.txt). `quellen/seriouseats/manifest.json` dokumentiert diesen Ausschluss mit null Rezeptabrufen; es werden keine Rezeptseiten gespeichert. Dies ist keine Aussage darüber, wie viele Rezepte die Website anbietet.

Dateien enthalten keine Bilder, Videos, Werbung, Kommentare oder vollständigen Webseiten. Die Aufzählungen der Zutaten und Arbeitsschritte sind für das Archiv als Text normalisiert; HTML wird entfernt. Gruppeninformationen sind zusätzlich enthalten, soweit der jeweilige Parser sie liefert. Bei Rainbow Plant Life bleiben Fußnoten zur Rezeptkarte auf Seitenebene in `page_recipe_notes`; sie können sich auf mehrere Karten beziehen. US-Mengen werden im Quellenarchiv nicht umgerechnet.

## Status und Wiederholung

`recipe` bedeutet, dass Titel, Urheber, Zutaten und Anleitung erfasst wurden. `incomplete` bewahrt eine von der Website als Rezept markierte Karte mit fehlenden Quellfeldern; `missing_fields` benennt die Lücken. Das ist kein verifiziertes Kochbuch-Rezept. `no_recipe` bezeichnet Seiten ohne Rezeptkarte, `disallowed` einen Ausschluss durch robots.txt und `restricted` eine nicht frei zugängliche Karte ohne gespeicherte Rezeptdaten. `error` bezeichnet einen fehlgeschlagenen Abruf oder eine nicht lesbare Seite. Ein vollständiger Quellenausschluss steht als `source_status: excluded` im Manifest. Fehlende Angaben niemals erfinden. Das Manifest ist die maßgebliche Liste der erfassten Dateien.

Python 3.10+ und `curl` genügen; keine zusätzlichen Python-Pakete nötig. Standardmäßig zwei Arbeiter, jeweils mindestens eine Sekunde Pause zwischen Abrufen. `--workers 1` bis `--workers 4` steuert die Parallelität. robots.txt wird vor dem Abruf ausgewertet; der Client nennt sich `KochbuchRecipeArchiver`. Bei HTTP-Fehlern werden begrenzte Wiederholungen versucht; verbleibende Fehler stehen im Manifest und führen zu einem Fehlerstatus des Befehls.

```bash
python3 scripts/scrape_recipes.py --source rainbowplantlife
python3 scripts/scrape_recipes.py --source babish
python3 scripts/scrape_recipes.py --source joshuaweissman
python3 scripts/scrape_recipes.py --source cookwell
python3 scripts/scrape_recipes.py --source recipetineats
python3 scripts/scrape_recipes.py --source zuckerjagdwurst
python3 scripts/scrape_recipes.py --source maangchi
python3 scripts/scrape_recipes.py --source pickuplimes
```

Ohne `--refresh` werden die aktuellen Sitemap-/Index-URLs neu ermittelt, vorhandene erfolgreiche Einträge jedoch wiederverwendet. Mit `--refresh` werden alle Seiten neu geladen. Nur Fehler des letzten Manifests erneut versuchen, ohne den Index nochmals zu durchsuchen:

```bash
python3 scripts/scrape_recipes.py --source joshuaweissman --retry-errors
```

Neue Läufe schreiben während der Verarbeitung atomare Checkpoints mit `completed: false` und `pending`-Seiten. `--retry-errors` setzt auch diese offenen Seiten fort. Die Quellenprüfung lässt einen unterbrochenen Lauf nicht als vollständig durchgehen. Nach Parseränderungen prüfen `--retry-incomplete` beziehungsweise `--retry-no-recipe` die betreffenden Einstufungen erneut; die Flags sind mit `--retry-errors` kombinierbar.

Offline die Vollständigkeit gegenüber dem Manifest und die Quellenzuordnung prüfen:

```bash
python3 scripts/check_sources.py
python3 -m unittest discover -s scripts -v
```
