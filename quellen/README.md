# Quellenarchiv

Die JSON-Dateien sichern die öffentlichen Rezeptkarten von [Rainbow Plant Life](https://rainbowplantlife.com/), [Babish](https://www.babi.sh/recipes) und [Joshua Weissman](https://www.joshuaweissman.com/recipes). Jede Karte nennt ihre konkrete Original-URL und die Urheberangabe aus der Quelle. Die Rechte verbleiben bei den jeweiligen Urhebern.

Das Archiv enthält Originaltexte auf Englisch, Originalmengen und Quellzeiten. Es ist die Grundlage für die weitere Übertragung ins Kochbuch. Die fünf bereits übersetzten Rainbow-Plant-Life-Rezepte und elf gezielt ausgewählte NDR-Rezepte stehen zusätzlich unter `rezepte/` und in `db/seed.sql`; die übrigen Archivkarten sind noch nicht in der Einkaufslisten-Datenbank. Keine automatischen Übersetzungen oder stillen Umrechnungen: vor der Übernahme die Regeln in `AGENTS.md` anwenden.

## Umfang

Abgerufen am 16. November 2026. Die konkreten Zahlen und jeder einzelne Seitenstatus stehen im jeweiligen `manifest.json`. Der Umfang ist das zu diesem Zeitpunkt öffentlich auffindbare Rezeptarchiv; Inhalte aus kostenpflichtigen Angeboten und Büchern werden nicht erschlossen.

| Quelle | Geprüfte Seiten | Vollständige Rezeptkarten | Unvollständige Quellkarten | Ohne Rezeptkarte | Abruffehler |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rainbow Plant Life | 403 | 329 | 0 | 74 | 0 |
| Babish | 632 | 628 | 4 | 0 | 0 |
| Joshua Weissman | 803 | 800 | 3 | 0 | 0 |
| Gesamt | 1838 | 1757 | 7 | 74 | 0 |

- Rainbow Plant Life: Beitrags- und Seitensitemaps aus `sitemap_index.xml`; mehrere Rezeptkarten auf einer Seite werden einzeln erfasst. Nicht-Rezeptseiten werden als `no_recipe` dokumentiert.
- Babish: alle `/recipes/`-Einträge aus `sitemap.xml`. Die Urheberangabe wird so übernommen, wie sie die Rezeptkarte nennt (zum Beispiel `bingingwithbabish`). Vier als Rezept ausgezeichnete Ratgeberseiten haben keine Zutaten oder keine Anleitung; sie bleiben ausdrücklich `incomplete`.
- Joshua Weissman: alle 90 Seiten des Rezeptindexes, bis keine nächste Seite mehr verlinkt ist. Zutaten und Anleitungen stehen teils erst nach JavaScript-Ausführung im JSON-LD; der Scraper liest dafür die öffentlich sichtbaren HTML-Rezeptlisten. Gruppen, zusätzliche Absätze und Hinweise bleiben in `ingredient_sections` und `instruction_sections` erhalten. Nicht standardisierte Zeitangaben wie „overnight“ bleiben unverändert.

Dateien enthalten keine Bilder, Videos, Werbung, Kommentare oder vollständigen Webseiten. Die Aufzählungen der Zutaten und Arbeitsschritte sind für das Archiv als Text normalisiert; HTML wird entfernt. Gruppeninformationen sind zusätzlich enthalten, soweit der jeweilige Parser sie liefert. Bei Rainbow Plant Life bleiben Fußnoten zur Rezeptkarte auf Seitenebene in `page_recipe_notes`; sie können sich auf mehrere Karten beziehen. US-Mengen werden im Quellenarchiv nicht umgerechnet.

## Status und Wiederholung

`recipe` bedeutet, dass Titel, Urheber, Zutaten und Anleitung erfasst wurden. `incomplete` bewahrt eine von der Website als Rezept markierte Karte mit fehlenden Quellfeldern; `missing_fields` benennt die Lücken. Das ist kein verifiziertes Kochbuch-Rezept. `no_recipe` bezeichnet Seiten ohne Rezeptkarte, `disallowed` einen Ausschluss durch robots.txt, `error` einen fehlgeschlagenen Abruf oder eine nicht lesbare Seite. Fehlende Angaben niemals erfinden. Das Manifest ist die maßgebliche Liste der erfassten Dateien.

Python 3.10+ und `curl` genügen; keine zusätzlichen Python-Pakete nötig. Zwei Arbeiter, jeweils mindestens eine Sekunde Pause zwischen Abrufen. robots.txt wird vor dem Abruf ausgewertet. Bei HTTP-Fehlern werden begrenzte Wiederholungen versucht; verbleibende Fehler stehen im Manifest und führen zu einem Fehlerstatus des Befehls.

```bash
python3 scripts/scrape_recipes.py --source rainbowplantlife
python3 scripts/scrape_recipes.py --source babish
python3 scripts/scrape_recipes.py --source joshuaweissman
```

Ohne `--refresh` werden die aktuellen Sitemap-/Index-URLs neu ermittelt, vorhandene erfolgreiche Einträge jedoch wiederverwendet. Mit `--refresh` werden alle Seiten neu geladen. Nur Fehler des letzten Manifests erneut versuchen, ohne den Index nochmals zu durchsuchen:

```bash
python3 scripts/scrape_recipes.py --source joshuaweissman --retry-errors
```

Offline die Vollständigkeit gegenüber dem Manifest und die Quellenzuordnung prüfen:

```bash
python3 scripts/check_sources.py
python3 -m unittest discover -s scripts -v
```

## Gezielte NDR-Erweiterung

Zusätzlich stehen elf einzeln geprüfte Fitness-Rezepte unter [`ndr/`](ndr/README.md). Diese Auswahl folgt ausschließlich der geprüften URL-Liste, keinem vollständigen Sitemap-Import. Alle elf sind auch nach `rezepte/` und `db/seed.sql` normalisiert. Details zu Quellenprüfung, Alternativen, Portionen und getrennten NDR-/BLS-Nährwerten stehen in der NDR-Dokumentation. Die Umfangstabelle oben beschreibt weiterhin den ursprünglichen Vollarchiv-Import vom 16. November.
