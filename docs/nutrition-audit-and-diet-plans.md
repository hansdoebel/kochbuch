# Nährwertprüfung und persönliche Ernährungspläne

Stand: 19. November 2026. Implementierung: `web/src/server/nutrition.ts`, `adaptation.ts`, `planner.ts` und `web/src/lib/diet.ts`.

## Ergebnis der erneuten Prüfung

Die BLS-Berechnung bleibt eine nachvollziehbare Zutatenbilanz mit Lücken, keine Analyse des fertigen Essens. Die Grundrechnung stimmt: Referenzwert pro 100 g × essbare Gramm / 100 / Originalportionen. Einkauf und Analyse skalieren anschließend mit den gewünschten Originalportionen. 200 g einer Zutat mit 10 g Protein pro 100 g ergeben für zwei Portionen jeweils 10 g Protein, für drei gegessene Portionen 30 g.

| Prüfung | Verhalten |
| --- | --- |
| Energie / Makros | kcal bzw. g; BLS-Quellcodes bleiben gespeichert. Energie wird nicht aus gerundeten Makros neu konstruiert. |
| Mikronährstoffe | mg und µg getrennt; kein Faktor-1000-Verlust. Natrium ist kein Salz. |
| Kohlenhydrate | BLS verfügbare Kohlenhydrate. Herausgeberangaben behalten ihre eigene, nicht unabhängig geprüfte Definition. Keine stille Subtraktion von Ballaststoffen. |
| Fehlend / Null | Nicht analysiert, Spuren und Nachweisgrenzen bleiben unbekannt. Echte Null bleibt numerische Null. Selen fehlt im Snapshot und wird nicht erfunden. |
| Gewichte | Nur g/kg und explizit dokumentierte Umrechnungen. Keine pauschale Dichte für ml/EL/TL, keine erfundenen Stück- oder Handvollgewichte. |
| Lebensmittelzustand | Roh-, TK-, Konserven- und gegarte Bezugsbasis beachten; Abtropfgewicht und Bohnenwasser nicht gleichsetzen. Quinoa mit trockenem Zutatengewicht bilanzieren. |
| Abdeckung | Pro Nährstoff, nicht nur pro gematchter Zutat. Ein bekanntes Lebensmittel kann einzelne unbekannte Nährwerte haben. |
| Zutatenwahl | Optionale Zutaten außerhalb der Basisbilanz; Alternativen nicht doppelt zählen. Tatsächliche Änderungen müssen gesondert erfasst werden. |
| Herkunft | Version, Lizenz, Quellcode, Ableitung, Qualifier, Lebensmittelzuordnung und Prüfnotiz bleiben erhalten. |

Korrigiert wurden drei konkrete Probleme: Der Wochenplan bestrafte zuvor Protein und Ballaststoffe oberhalb eines Ziels. Beide werden jetzt als Mindestziele behandelt. Persönliche Zielportionen und Haushaltsmenge sind getrennt. Außerdem stammt das Datumsfeld einer berechneten Bilanz jetzt ausschließlich aus tatsächlich verwendeten Datensätzen; ein neuer, unbeteiligter Datensatz verjüngt keinen alten Herkunftsnachweis.

Generische Lebensmittel sind keine exakten Produktetiketten. Gar-/Retentionsverluste, entfernte Bestandteile und tatsächlich aufgenommenes Bratöl bleiben Unsicherheiten. Vier neu geprüfte Zuordnungen ergänzen Shiitake, Brokkoli, Mandeln und TK-Brechbohnen. Frische Sojabohnen mit unklarem Schoten-/Kerngewicht, Räuchertofu, Soja Cuisine und unbestimmte Würzsaucen erhalten keine erdachten Werte.

## Persönliche Ziele und automatische Anpassung

In der Ernährungsansicht können Training und Ruhetag getrennte Energie-, Protein-, Kohlenhydrat-, Ballaststoff- und Fettbereiche erhalten. Jede Grenze ist optional. Für Protein und Ballaststoffe reicht typischerweise ein selbst gewähltes Minimum. Wochentage und einzelne Datumsausnahmen bestimmen das Profil. Der angegebene Zweck (Aufbau, Abnahme, Erhaltung) setzt keine persönlichen Zahlen automatisch.

Gültige alte `goals:v1`-Zahlen werden in beide Tagesprofile übernommen; Protein/Faser als Minimum, Energie/Kohlenhydrate als exakter Bereich. Beim ersten neuen Verzehreintrag eines Tages wird der Zielstand gespeichert. Spätere Einstellungsänderungen ändern diesen historischen Zielstand nicht. Historische Einträge ohne gespeicherte Ziele verwenden weiterhin das aktuelle Profil. Ziele, Mahlzeiten und Einstellungen liegen lokal im Browser; JSON-Kopieren/Einfügen erlaubt eine manuelle Sicherung der Einstellungen.

Für die Anpassung muss der Anteil **einer Mahlzeit** am persönlichen Tagesziel ausdrücklich gesetzt werden. 25 % eines Tagesziels von 2.400 kcal sind 600 kcal pro Person für diese Mahlzeit. Es wird nicht angenommen, dass alle drei Mahlzeiten gleich groß sind. Drei Personen vergrößern die Zutatenliste um Faktor drei, nicht das persönliche Ziel.

Der Algorithmus sucht innerhalb der gewählten Portionsgrenzen eine gemeinsame Skalierung aller Zutaten. Er bildet die Schnittmenge der erfüllbaren Bereiche. Bei mehreren Lösungen bevorzugt er die Mitte des Energiebereichs, sonst eine möglichst normale Originalportion. Gibt es keine gemeinsame Lösung, minimiert er die Summe quadrierter relativer Grenzverletzungen stückweise exakt. Ergebnis: passend, ausdrücklich nur Näherung, oder mangels Daten nicht anpassbar. Jede nicht erfüllte Grenze bleibt sichtbar. Keine Zutatenersetzung, keine Umgestaltung des Makroverhältnisses und keine Garantie einer vollständigen Tagesversorgung.

Die normale Datenbasis verlangt vollständige Abdeckung für **jeden gewählten** Zielnährstoff. Fehlende Werte aktivieren keinen automatischen Fallback. Optional kann ausdrücklich die vollständige Herausgeber-Makroschätzung der Rezeptkarte verwendet werden. Dann stammen alle fünf Makrowerte aus derselben Schätzung, inklusive Kohlenhydratdefinition und Quellenlink; BLS-Mikrowerte werden nicht ergänzt. Die normale Analyse bleibt eine separate BLS-Bilanz. Unbekannte Zutatenmengen bleiben im Originaltext.

Ernährungsweise und ausgeschlossene zugeordnete Zutaten filtern Vorschläge. Das prüft keine Produktspuren oder ungenannten Alternativen. Eine veraltete Einzelrezept-Auswahl darf die Filter auch im API-Endpunkt nicht umgehen. Originalrezepte bleiben unverändert. Übernommene Mengen gehen in die bestehende Einkaufsliste und den mobilen Typst-/PDF-Export.

Der Wochenplan plant weiterhin **eine Mahlzeit pro Tag**, keinen vollständigen Tag. Tagesprofile bestimmen persönliche Portionen, die Personenanzahl die Kochmenge. Passende Vorschläge haben Vorrang vor bloßer Zutatenwiederverwendung. Nicht planbare Tage werden einzeln gemeldet; sie verhindern spätere Tage nicht. Vorabend-Vorbereitung ist ein eigener Filter, und aggregierte Portionen bleiben innerhalb der Exportgrenzen.

## Verbreitete Ernährungsstrategien

Die UI bietet acht kurze, quellenverlinkte Erläuterungen. Keine gemessene Beliebtheitsrangliste: Essensmuster, Energieziele und Timing sind verschiedene Dimensionen und kombinierbar.

| Strategie | Nutzen für die Planung | Grenzen / Quelle |
| --- | --- | --- |
| Mediterran / ausgewogene Mischkost | Gemüse, Vollkorn, Hülsenfrüchte, Nüsse und pflanzliche Öle als Grundlage | Eigene Energie-/Proteinziele nötig. [AHA](https://www.heart.org/en/healthy-living/healthy-eating/eat-smart/nutrition-basics/mediterranean-diet) |
| Proteinbetont / Makroplanung | Proteinquellen und Trainingsbedarf bewusst planen | Makros allein sichern keine Mikronährstoffe. DGE: bei mehr als fünf Sportstunden pro Woche je nach Ziel 1,2–2,0 g/kg/Tag; kein pauschales Ziel für alle. [DGE](https://www.dge.de/presse/meldungen/2020/positionspapier-zur-proteinzufuhr-im-sport/) |
| Energiedefizit | Langfristige Zufuhr unter Verbrauch für Gewichtsabnahme | Alltagstauglichkeit, Training und Erholung beachten; kein automatisch berechnetes Defizit. [NIDDK](https://www.niddk.nih.gov/health-information/weight-management/healthy-eating-physical-activity-for-life) |
| Erhaltung / Muskelaufbau | Energie, Protein und progressives Training zusammen betrachten | Mehr Energie bedeutet nicht automatisch mehr Muskelmasse. Erholung braucht auch am Ruhetag Nährstoffe. [DGE](https://www.dge.de/presse/meldungen/2020/positionspapier-zur-proteinzufuhr-im-sport/) |
| Vegetarisch / vegan | Tofu und Hülsenfrüchte als Proteinquellen | Honig ist nicht vegan. Vegane Ernährung braucht insbesondere zuverlässige B12-Supplementierung und Prüfung kritischer Nährstoffe. [DGE, Neubewertung 2024 / FAQ](https://www.dge.de/gesunde-ernaehrung/faq/faqs-vegane-ernaehrung/) |
| Low Carb / ketogen | Persönliche Kohlenhydratbereiche möglich | Uneinheitliche Definition; wenig Kohlenhydrate belegt keine Ketose. Kein automatisch geeigneter Keto-Plan. [S3-Leitlinie Adipositas 2024](https://register.awmf.org/assets/guidelines/050-001l_S3_Praevention-Therapie-Adipositas_2024-10.pdf) |
| Intervallfasten | Zeitfenster kann die Umsetzung erleichtern | Kein zuverlässiger Gewichtsverlust-Vorteil gegenüber üblicher Ernährungsberatung bei Erwachsenen mit Übergewicht/Adipositas. Keine Schlussfolgerung für Muskelaufbau. [Cochrane 2026](https://doi.org/10.1002/14651858.CD015610.pub2) |
| DASH | Ausgewogene Lebensmittelauswahl mit Fokus auf Natrium und gesättigte Fette | Die Portionsoptimierung hat keine Natriumziele; keine DASH-Konformitätsgarantie. [NHLBI](https://www.nhlbi.nih.gov/health/dash-eating-plan) |

Die Informationskarten setzen keine automatischen Vorgaben. Als weitere allgemeine Referenz nennt die [DGE für Erwachsene mindestens 30 g Ballaststoffe pro Tag](https://www.dge.de/wissenschaft/referenzwerte/ballaststoffe/). Die Eignung persönlicher Ziele hängt von Person, Belastung und Kontext ab.

## Verifikation

Regressionen prüfen handgerechnete Portionen, Null gegen unbekannt, Abdeckung je Nährstoff, Quellen-Datum, explizite Schätzwerte, unvereinbare Zielverhältnisse, Portionsgrenzen, Filter, Kalender-Ausnahmen, Haushaltsmengen und spätere planbare Tage. Rezeptlinter gleichen alle 17 Markdown-Rezepte mit SQL ab. Der bestehende PDF-Test kompiliert sowohl die mobile PDF als auch das eigenständige Typst-Template. Browser-Darstellung wurde mangels Browser-QA-Werkzeug nicht visuell geprüft.
