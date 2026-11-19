# Recherche zur Kochbuch-Oberfläche

Stand: 19. November 2026. Im Repository existierten zuvor weder Web-UI noch Typst-Vorlage. Die zusätzlichen Quellarchive aus PR #3 sind unabhängig von der Oberfläche; der Index verwendet automatisch die auf dem jeweiligen Branch verfügbaren Archive.

| Projekt | Relevante Eigenschaften | Entscheidung für Kochbuch |
| --- | --- | --- |
| [Mealie](https://github.com/mealie-recipes/mealie), [Dokumentation](https://mealie.io/documentation/getting-started/features/) | Rezeptverwaltung, Portionsskalierung, Essensplanung und Einkaufslisten; Vue-Oberfläche mit eigener API. | Der kurze Weg vom Rezept zur Einkaufsliste ist ein gutes Vorbild. Kein Import des vollständigen Servers oder seines Datenmodells. |
| [Tandoor Recipes](https://github.com/TandoorRecipes/recipes), [Website](https://tandoor.dev/) | Umfangreiche Rezeptverwaltung, Zutaten, Mahlzeiten und Einkaufslisten. | Mengen und Zutaten müssen strukturiert bleiben. Für den gewünschten reinen Browser ist die vollständige Anwendung zu umfangreich. |
| [Chowdown](https://github.com/clarklab/chowdown) | Einfache, in Markdown gespeicherte Rezepte. | Dateibasierte Daten als Quelle beibehalten; keine Migration in ein proprietäres Format. |
| [Cooklang / CookCLI](https://github.com/cooklang/cookcli) | Rezeptdateien, CLI und eingebetteter Webserver. | Eine schlanke lokale Anwendung und nachvollziehbare Mengen sind passend. Die vorhandenen Markdown- und SQL-Dateien bleiben jedoch das maßgebliche Format. |

Die Projekte wurden als Funktions- und Architekturvergleich verwendet. Es wurde kein Anwendungscode daraus übernommen. Die UI-Komponenten stammen aus dem offiziellen [shadcn-svelte-Registry](https://www.shadcn-svelte.com/docs/installation/vite); Hinweise zur Lizenz stehen in `web/THIRD_PARTY_NOTICES.md`.

## Gewählte Umsetzung

- Svelte 5 mit Vite und shadcn-svelte; Bun als Runtime, Paketmanager und Test-Runner. Keine separate Node-/Python-API für die Weboberfläche.
- Bun-SQLite-FTS5 sucht serverseitig nach Titel, Zutaten und Quelle. Der Browser erhält höchstens 30 Zusammenfassungen pro Seite; vollständige Rezepte werden erst beim Öffnen geladen. Ein anhand der Quelldateien invalidierter lokaler Index verhindert wiederholtes Parsen aller Archive.
- Kein Bilddownload, keine externen Fonts und keine Analyse-/Tracking-Dienste. Komprimierte statische Assets, persistente Auswahl und verzögerte Abfragen mit Abbruch veralteter Requests. Die Ernährungsansicht wird separat geladen.
- Kuratierte SQL-Zutaten werden nach Portionen skaliert und nur bei gleicher Zutat, Einheit, Variante und Optionalität addiert. Masse und Volumen bleiben getrennt. Archivtexte werden nicht automatisch interpretiert oder skaliert, sondern mit Originalmengen pro Rezept exportiert.
- Die mobile Einkaufsliste wird aus einer versionierten [Typst-Vorlage](https://typst.app/docs/reference/data-loading/json/) erzeugt. JSON wird als Daten geladen und niemals als Typst-Code ausgewertet. PDF, eigenständiger Typst-Quelltext und JSON sind exportierbar.

## Nährwerte als nächste Ebene

Die bisherigen Scraper haben keine Nährwerttabellen zurückbehalten. Leere Werte dürfen nicht als null Gramm oder als erfülltes/unerfülltes Tagesziel erscheinen. Die Oberfläche zeigt deshalb bekannte Teilsummen und ihre Abdeckung pro Nährstoff; Auswahl und tatsächlich protokollierter Verzehr sind getrennte Daten.

Für die Zutatenanalyse ist [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/) ein möglicher Referenzdienst. Die API erfordert einen Schlüssel; ein Schlüssel ist kein Bestandteil dieser Umsetzung. Alternativ kommen geeignete europäische Lebensmitteldaten in Betracht. Vor dem Berechnen müssen konkrete Lebensmittel, essbare Gramm, Einheiten, Roh-/Gargewicht und Ausbeute zugeordnet werden. Eine automatische Zuordnung nur anhand eines ähnlichen Namens wäre keine verifizierte Nährwertanalyse. Diese Arbeit wird in PER-256 weitergeführt.
