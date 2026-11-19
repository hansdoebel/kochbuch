# NDR: kuratierte Fitness-Auswahl

Drei ausdrücklich ausgewählte öffentliche NDR-Rezeptkarten, geprüft am 19. November 2026. **Kein Crawl des gesamten NDR-Archivs.** Die Auswahl steht in `selection.json`, mit konkreter URL, Begründung, Prüfdatum und Fingerabdruck des geprüften Karteninhalts.

| Rezept | Urheber laut Karte | Portionen | Gesamtzeit | NDR-Schätzung pro Portion |
| --- | --- | ---: | ---: | --- |
| [Protein-Bowl mit Linsen und Kichererbsen](https://www.ndr.de/ratgeber/kochen/rezepte/gesunde-protein-bowl-mit-linsen-und-kichererbsen,proteinbowl-102.html) | Team Ernährungs-Docs | 2 | 30 Min. | 590 kcal · 28 g Protein · 18 g Ballaststoffe |
| [Chili sin Carne mit Sojageschnetzeltem](https://www.ndr.de/ratgeber/kochen/rezepte/Chili-sin-Carne-mit-Sojageschnetzeltem,chilisincarne112.html) | ndr.de (Organisation; keine persönliche Byline) | 4 | 40 Min. | 484 kcal · 46 g Protein · 23 g Ballaststoffe |
| [Bunte Quinoa-Pfanne mit Hähnchen](https://www.ndr.de/ratgeber/kochen/rezepte/bunte-quinoa-pfanne-mit-haehnchen-gemuese,quinoapfanne-100.html) | Team Ernährungs-Docs | 2 | 40 Min. | 582 kcal · 42 g Protein · 11 g Ballaststoffe |

Alle drei stehen auch als gekürzte, neu formulierte Kochbuchfassungen unter `rezepte/` und in `db/seed.sql`. Damit funktionieren Suche, skalierbare Einkaufsliste und Wochenplan unmittelbar. Ein Original wird nicht doppelt als Archivkarte angezeigt.

## Erfassung und Wiederholung

```bash
python3 scripts/scrape_recipes.py --source ndr
python3 scripts/scrape_recipes.py --source ndr --refresh
python3 scripts/check_sources.py
```

Der Import liest ausschließlich die geprüften URLs aus `selection.json`, keine Sitemaps und keine weiterführenden Links. Maximal 20 einzeln begründete Einträge sind erlaubt. `robots.txt` wird geprüft; der Client nennt sich `KochbuchRecipeArchiver/1.0`. Geänderte Rezeptinhalte werden vor dem Ersetzen anhand des geprüften Fingerabdrucks erkannt und müssen erneut geprüft werden. Fotos, vollständige Artikel, Video-Metadaten und Krankheits-Eignungstags werden nicht gespeichert. Die Rechte verbleiben beim NDR und den genannten Urhebern.

Die Quell-JSON-LD-Daten verlieren Zutatenmerkmale. Deshalb liest der Parser die sichtbaren Zutaten: Abtropfgewicht, nicht abgetropfte Kidneybohnen, Farben, optionale Zutaten und Alternativen bleiben erhalten. Portionen müssen zwischen JSON-LD und sichtbarer Portionssteuerung übereinstimmen. Urheber stammen ausschließlich aus der Rezeptkarte, niemals aus Bild- oder Video-Credits. Die Zubereitung im gespeicherten Datensatz ist als `editorial_summary` gekennzeichnet und stammt aus der geprüften Kurzfassung in der Auswahl.

Für neue Einträge: Originalseite öffnen, die vollständige Karte prüfen, Auswahlgrund und kurze eigene Anleitung festhalten; mit `extract_ndr` und `source_digest` den geprüften Inhalt fixieren. Danach erst die URL zur Auswahl ergänzen und die normalisierte Fassung samt Mengenentscheidungen in Markdown und SQL anlegen. `--refresh` gibt eine inhaltlich geänderte Karte nicht automatisch frei.

## Mengen, Zeit und Nährwerte

- Die Bowl benutzt Rucola; Spinat ist eine Alternative. Feta bedeutet: **vegetarisch, nicht vegan**, auch wenn NDR beide Tags anzeigt.
- Kichererbsen: 150 g Abtropfgewicht. Kidneybohnen im Chili: 400 g einschließlich Bohnenwasser. Nicht dieselbe Gramm-Basis für Nährwerte verwenden.
- Handvoll, Stück und Volumen erhalten keine erfundenen essbaren Grammgewichte. Geprüfte BLS-Zuordnungen ergänzen die Zutatenbilanz, aber verbleibende Gewichte bleiben offen.
- Die Quelle nennt nur Gesamtzeiten. `total_minutes` speichert diese unverändert; getrennte Vorbereitungs-/Garzeiten bleiben NULL beziehungsweise `unbekannt` im Markdown.
- Die UI zeigt NDR-Schätzwerte mit Quelle getrennt von der BLS-Zutatenbilanz. Es werden weder fehlende Mikronährwerte mit Null aufgefüllt noch NDR-Makros mit BLS-Teilsummen vermischt. Die Kohlenhydratdefinition ist als Herausgeberangabe gekennzeichnet. Diese Schätzwerte schalten keine Ernährungs-Zieloptimierung für unvollständige Zutatenprofile frei.

Andere recherchierte Websites bleiben in [der Forschungsdatei](../../docs/fitness-recipes-and-preferences.md) und [der Metadaten-Shortlist](../../docs/fitness-recipe-shortlist.json) vorgemerkt; sie werden nicht importiert.
