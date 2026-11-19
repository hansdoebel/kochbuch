# NDR: kuratierte Fitness-Auswahl

Elf ausdrücklich ausgewählte öffentliche NDR-Rezeptkarten, geprüft am 19. November 2026. **Kein Crawl des gesamten NDR-Archivs.** Die Auswahl steht in `selection.json`, mit konkreter URL, Begründung, Prüfdatum und Fingerabdruck des geprüften Karteninhalts.

| Rezept | Urheber laut Karte | Portionen | Gesamtzeit | NDR-Schätzung pro Portion |
| --- | --- | ---: | ---: | --- |
| [Protein-Bowl mit Linsen und Kichererbsen](https://www.ndr.de/ratgeber/kochen/rezepte/gesunde-protein-bowl-mit-linsen-und-kichererbsen,proteinbowl-102.html) | Team Ernährungs-Docs | 2 | 30 Min. | 590 kcal · 28 g Protein · 18 g Ballaststoffe |
| [Chili sin Carne mit Sojageschnetzeltem](https://www.ndr.de/ratgeber/kochen/rezepte/Chili-sin-Carne-mit-Sojageschnetzeltem,chilisincarne112.html) | ndr.de (Organisation; keine persönliche Byline) | 4 | 40 Min. | 484 kcal · 46 g Protein · 23 g Ballaststoffe |
| [Bunte Quinoa-Pfanne mit Hähnchen](https://www.ndr.de/ratgeber/kochen/rezepte/bunte-quinoa-pfanne-mit-haehnchen-gemuese,quinoapfanne-100.html) | Team Ernährungs-Docs | 2 | 40 Min. | 582 kcal · 42 g Protein · 11 g Ballaststoffe |
| [Blumenkohl-Curry mit Tofu](https://www.ndr.de/ratgeber/kochen/rezepte/Blumenkohl-Curry-mit-Tofu,rezept5548.html) | ndr.de | 4 | 30 Min. | 360 kcal · 26 g Protein · 12 g Ballaststoffe |
| [Gemüsepfanne mit Tofu](https://www.ndr.de/ratgeber/kochen/rezepte/Gemuesepfanne-mit-Tofu,rezept3014.html) | ndr.de | 1 | 15 Min. | 296 kcal · 26 g Protein · 7 g Ballaststoffe |
| [Lachs-Päckchen mit Gemüse und Feta](https://www.ndr.de/ratgeber/kochen/rezepte/Lachs-Paeckchen-mit-Gemuese-und-Feta,rezept2548.html) | ndr.de | 2 | 30 Min. | 473 kcal · 42 g Protein · 6 g Ballaststoffe |
| [Strammer Max vegetarisch](https://www.ndr.de/ratgeber/kochen/rezepte/Strammer-Max-vegetarisch,strammermax132.html) | ndr.de | 1 | 15 Min. | 410 kcal · 32 g Protein · 6 g Ballaststoffe; ohne Salat |
| [Quarkfrühstück mit Gemüse und Obst („Doc-Klasen-Spezial“)](https://www.ndr.de/ratgeber/kochen/rezepte/Quarkfruehstueck-mit-Gemuese-und-Obst-Doc-Klasen-Fruehstueck,fruehstueck2230.html) | Jörn Klasen | 1 | 10 Min. | 653 kcal · 33 g Protein · 17 g Ballaststoffe |
| [Gebratener Tofu mit Pfannengemüse und Pilzen](https://www.ndr.de/ratgeber/kochen/rezepte/Tofu-mit-Pfannengemuese-und-Pilzen,tofupfanne114.html) | Tarik Rose | 4 | 30 Min. + Marinieren | 385 kcal · 28 g Protein · 10 g Ballaststoffe |
| [Bohnenpfanne mit Tofu](https://www.ndr.de/ratgeber/kochen/rezepte/bohnenpfanne-mit-tofu,bohnenpfanne-100.html) | Uwe Behrends | 2 | 30 Min. | 482 kcal · 28 g Protein · 8 g Ballaststoffe |
| [Quinoa-Bowl mit Tofu in Sesamkruste und Brokkoli](https://www.ndr.de/ratgeber/kochen/rezepte/Quinoa-Bowl-mit-Tofu-in-Sesamkruste-und-Brokkoli,rezept2868.html) | ndr.de | 2 | 40 Min. | 990 kcal · 51 g Protein · 21 g Ballaststoffe |

Alle elf stehen auch als gekürzte, neu formulierte Kochbuchfassungen unter `rezepte/` und in `db/seed.sql`. Damit funktionieren Suche, skalierbare Einkaufsliste und Wochenplan unmittelbar. Ein Original wird nicht doppelt als Archivkarte angezeigt.

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
- Die UI zeigt NDR-Schätzwerte mit Quelle getrennt von der BLS-Zutatenbilanz. Es werden weder fehlende Mikronährwerte mit Null aufgefüllt noch NDR-Makros mit BLS-Teilsummen vermischt. Die Kohlenhydratdefinition ist als Herausgeberangabe gekennzeichnet. Diese Schätzwerte vervollständigen keine BLS-Profile. Für die Portionsanpassung können sie ausdrücklich als getrennte Schätzbasis gewählt werden; eine automatische Umschaltung gibt es nicht.

Andere recherchierte Websites bleiben in [der Forschungsdatei](../../docs/fitness-recipes-and-preferences.md) und [der Metadaten-Shortlist](../../docs/fitness-recipe-shortlist.json) vorgemerkt; sie werden nicht importiert.

## Zweite Auswahlcharge

Fünf weitere Karten wurden einzeln geprüft, statt eine Sitemap zu übernehmen: zwei pflanzliche Gemüsegerichte, ein Fischgericht, eine vegetarische Ei-/Tofu-Mahlzeit und ein Frühstück. Alle erreichen laut Herausgeber mindestens 26 g Protein und 6 g Ballaststoffe pro Portion. Diese Quellenwerte bleiben Schätzungen, keine unabhängige Nährwertprüfung.

- Das Eiweißbrot kann laut Quelle durch Vollkornbrot ersetzt werden; dies verändert die Nährwerte. Die zusätzliche Salatbeilage bleibt ausdrücklich außerhalb der veröffentlichten Portion.
- Basilikum-Tofu, Räuchertofu, Krabben und die unbestimmte Nussmischung erhalten keine erfundene Produktzuordnung. Bei der Gemüsepfanne sind Hülsenfrüchte ein Ersatz, keine zusätzliche Zutat.
- Scheibe, Schuss und Spritzer sind qualitative Einheiten ohne Grammdichte. Optionale Sojasoße wird nicht automatisch als bekannte Masse berechnet.
- Der Parser erkennt zusätzlich ältere NDR-Überschriften und bewahrt Zusätze wie „ohne Salat“. Die bisherigen drei Quell-Fingerabdrücke bleiben unverändert.

## Asiatisch beeinflusste Tofu-Auswahl

Drei weitere Karten einzeln geprüft: Sesam-/Quinoa-Bowl, Bohnenpfanne und marinierter Tofu mit Gemüse und Pilzen. Mengen und Schritte bleiben nachvollziehbar; die volle Seite bleibt außerhalb des Repositories. Der Parser unterstützt Rezepturheber als JSON-LD-Liste.

- Honig macht Stir-fry und Bowl vegetarisch statt vegan. Bei der Bohnenpfanne sind Curry-/Teriyaki-Produkte unbestimmt; keine pauschale Vegan-Markierung.
- Der marinierte Tofu braucht mehrere Stunden oder eine Nacht zusätzlich zu 30 Minuten. Der Wochenplan verlangt dafür eine ausdrückliche Freigabe von Vorabend-Vorbereitung.
- Die 990-kcal-Bowl kann per Portion skaliert werden; „Fitness“ bedeutet kein automatisch energiearmes Essen.
- „scharzer Sesam“ wird mit Hinweis berichtigt. Die unklare Quellalternative „Tamani“ ersetzt keine eigenständige geprüfte Zutat. Frische Sojabohnen mit unklarer Schotenbasis und unbestimmte Pilze werden nicht zwangsgematcht.
