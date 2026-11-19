# Fitness-Rezepte und persönliche Einstellungen

Recherche und Codeprüfung vom 19. November 2026. Ergebnis: gezielte Rezeptauswahl und persönliche Trainings-/Ruhetagsprofile sind sinnvoll. Diese Änderung dokumentiert die Auswahl und das Umsetzungskonzept; sie importiert keine Rezepttexte und implementiert noch keine persönlichen Einstellungen.

## Quellen nach konkreten Rezepten bewerten

Die folgenden Original-Rezeptseiten wurden geöffnet und ihre Zutaten, Portionsbasis, veröffentlichte Nährwerte und praktische Eignung geprüft. Dies ist eine Recherche, kein eigener Kochtest und keine unabhängige Nährwertverifikation. Alle Zahlen sind **Schätzwerte des jeweiligen Herausgebers pro veröffentlichter Portion**, keine BLS-Berechnung. Fehlende Werte bleiben unbekannt. Seitenzahlen, Sterne und Marketing-Tags ersetzen die Prüfung nicht.

| Quelle und Priorität | Warum prüfen? | Einschränkung |
| --- | --- | --- |
| **NDR / Ernährungs-Docs – hoch** | Deutschsprachige Gerichte mit metrischen Mengen und häufig Protein-/Ballaststoffangaben. Die geprüfte Bowl hat Hülsenfrüchte und Gemüse. | Gesundheits-/Krankheits-Tags der Redaktion nicht als persönliche Eignung übernehmen. Essbare Stückgewichte und Portionenzahl vor Import abgleichen. |
| **Fit Men Cook – hoch, selektiv** | Explizite Meal-Prep-Ausrichtung, Portionen und Makros; geprüfte Bohnensuppe liefert sowohl Protein als auch Ballaststoffe. | Kevin Curry ist der Rezepturheber, nicht die wissenschaftliche Quelle für persönliche Bedarfswerte. Die geprüfte Suppe ist als Low Carb/Keto getaggt, veröffentlicht aber 39 g Kohlenhydrate pro Portion: Tags nicht blind übernehmen. |
| **The Real Food Dietitians – hoch, selektiv** | [Team mit registrierten Dietitians](https://therealfooddietitians.com/), Meal-Prep-Auswahl und transparente Portionsbasis. | Nicht jede Rezeptautorin ist selbst Dietitian. Die geprüfte Teriyaki-Karte stammt von Ana Ankeny und schließt Reis aus den Nährwerten aus. Gericht und Beilage getrennt rechnen. |
| **Skinnytaste – mittel bis hoch** | Nützliche Protein-/Ballaststofffilter, klarer Urheber und Portionsangaben. | Weight-Watchers-Punkte und Low-Calorie-Marketing sind kein Auswahlziel. Die geprüfte Pfanne hat gutes Protein, aber viel Natrium; für die tägliche Kombination betrachten. |
| **Good Food / BBC-Good-Food-Domain – mittel, selektiv** | Metrische Rezeptkarten, Nährwerte mit Ballaststoffen und Salz; geeignet für Gemüse-/Hülsenfruchtgerichte. | Die geprüfte Mahlzeit setzt bereits gegartes Huhn voraus. Ihre 35 Minuten enthalten dessen ursprüngliche Garzeit nicht. Salz nicht als Natrium importieren. |
| **Pick Up Limes – hoch für pflanzliche Auswahl, bereits vorhanden** | Geprüfte Pasta kombiniert Tofu, Sojamilch und Bohnen, mit detaillierten Nährwerten und Grammangaben. | Quelle ist bereits im offenen Archiv-PR #3 enthalten: nicht erneut scrapen. Konkrete Karten auswählen. Fortifizierte Produkte, optionale Toppings und Kohlenhydratdefinitionen prüfen. |
| **Eating Bird Food – Ergänzungsquelle** | Transparente Rezeptkarten und Gemüse-/Vollkornbeilagen. | Die geprüfte Quinoa-Beilage hat nur 8 g Protein pro Portion. Deshalb keine eigenständige proteinreiche Hauptmahlzeit; nicht wegen „Quinoa“ hochstufen. |

### Konkrete Shortlist

| Original-Rezept und Urheber | kcal | Protein | Ballaststoffe | Urteil für diese Erweiterung |
| --- | ---: | ---: | ---: | --- |
| [Protein-Bowl mit Linsen und Kichererbsen](https://www.ndr.de/ratgeber/kochen/rezepte/gesunde-protein-bowl-mit-linsen-und-kichererbsen,proteinbowl-102.html), Team Ernährungs-Docs | ca. 590 | 28 g | 18 g | Gute erste vegetarische Kandidatin; 30 Minuten. Mengenbasis der Portionssteuerung vor Normalisierung bestätigen. |
| [Green Chile Chicken Soup with White Beans](https://fitmencook.com/recipes/green-chile-chicken-soup/), Kevin Curry | 340 | 35 g | 8 g | Bedingt vormerken: sechs Portionen à 411 g, 30 Minuten mit bereits gegartem Rotisserie-Huhn. 39 g Kohlenhydrate, 780 mg Natrium; Keto-Tag und lange Lagerempfehlung nicht übernehmen. |
| [Creamy Alfredo-Style High Protein Pasta](https://www.pickuplimes.com/recipe/creamy-alfredo-style-high-protein-pasta-2417), Pick Up Limes | 725 | 35,3 g | 11,7 g | Gute pflanzliche Kandidatin mit mehr Energie/Kohlenhydraten; vier Portionen, 35 Minuten. Bereits archivierte URL wiederverwenden; Zutaten-/Toppingbasis prüfen. |
| [Ground Turkey Taco Skillet](https://www.skinnytaste.com/turkey-taco-skillet/), Gina Homolka | 503 | 37 g | 5,5 g | Bedingt vormerken: 30 Minuten, Portion 1½ Cups. Natrium 1.081 mg; Gemüse-/Beilagenkombination und genaue essbare Portionsmasse prüfen. |
| [Sheet Pan Teriyaki Chicken](https://therealfooddietitians.com/sheet-pan-teriyaki-chicken/), Ana Ankeny | 255 | 29 g | 3 g | Mahlzeitenbaustein, kein vollständiger Trainingstagsplan. Nährwerte gelten für ¼ des Rezepts **ohne Reis**; 40 Minuten. Beilage separat erfassen. |
| [Lemony chicken lentils](https://www.bbcgoodfood.com/recipes/lemony-chicken-lentils), Ailsa Burt | 507 | 35 g | 9 g | Bedingt vormerken: Resteverwertung, vier Portionen. Gegartes Huhn vorausgesetzt; 10 g gesättigte Fettsäuren und 2,2 g Salz pro Portion mitbetrachten. |
| [Easy Quinoa Salad](https://www.eatingbirdfood.com/easy-quinoa-salad/), Brittany Mullins | 316 | 8 g | 7 g | Nur Beilage. Die Herausgeberin kennzeichnet die Werte als automatisch berechnete Näherung; keine Hauptmahlzeit allein aufgrund der Zutatenbezeichnung. |

Maschinenlesbare Metadaten ohne Zutaten-/Anleitungstexte: [fitness-recipe-shortlist.json](fitness-recipe-shortlist.json). „Kandidat“ bedeutet keine Importfreigabe. Eine Website insgesamt wird nicht als gesund oder trainingsgeeignet freigegeben.

## Auswahlregeln für weitere Recherche und Importe

1. **Einzelne URL statt komplettes Archiv.** Neue Recherche ausschließlich zu ausgewählten alltagstauglichen Fitness-Mahlzeiten. Vorhandene Archive durchsuchen und kanonische URLs abgleichen, bevor weitere Daten angelegt werden. Die frühere Anweisung zum vollständigen Archivieren ist für diese Erweiterung durch die gezielte Auswahl ersetzt.
2. **Nachvollziehbare Mahlzeit.** Urheber, Zutaten, Zubereitung, Portionen und eine brauchbare Mengenbasis müssen vorliegen. Nährwerte müssen erkennen lassen, ob Beilagen, Öl, Dressing und Toppings enthalten sind. Roh-/gekocht- und Abtropfgewichte auseinanderhalten.
3. **Protein und Lebensmittelqualität zusammen betrachten.** Hülsenfrüchte, Tofu, Eier, Fisch oder andere geeignete Proteinquellen mit Gemüse und passenden Sättigungsbeilagen bevorzugen. Proteinpulver ist kein Qualitätsnachweis. Zusätzliche Kohlenhydrate können für Training sinnvoll sein; wenig Energie ist kein pauschaler Vorteil.
4. **Praktische Suchheuristik für Hauptmahlzeiten:** zunächst ungefähr mindestens 25 g Protein und 6 g Ballaststoffe pro Portion suchen. Das ist eine interne Suchpräferenz, keine gesetzliche Nährwertauslobung oder allgemeine Bedarfsgrenze. Gute Komponenten unterhalb dieser Werte dürfen als Komponenten vorgemerkt werden; Änderungen erst nach Berechnung bewerten. Nicht alle Mahlzeiten müssen dieselben Werte erreichen.
5. **Auswahl begründen.** Zeit, Kosten soweit belegbar, Wiederaufwärmen, Aufbewahrung laut Quelle, Geschmackskonzept, Gemüseanteil, Salz und gesättigte Fette mitbewerten. Ein Sterneschnitt ist kein eigener Kochtest. Keine Haltbarkeit aus dem Begriff „Meal Prep“ ableiten.
6. **Quellenwerte separat behalten.** Publisher-Nährwerte als `publisher_estimate` mit Datum und Portionsbasis dokumentieren. Sie sind Vergleichsdaten, kein Ersatz für `nutrition_facts`. Total Carbohydrate aus US-Quellen nicht als BLS CHO/verfügbare Kohlenhydrate ausgeben; Salz und Natrium unterscheiden.
7. **Vor tatsächlicher Übernahme:** Originalkarte nochmals prüfen; relevante Zugangs-/Nutzungsbedingungen beachten; keine Premiuminhalte, Fotos oder vollständigen Seiten übernehmen. Deutsche Übertragung mit eindeutiger Quelle, Mengenentscheidungen und Datenbankeinträgen gemäß bestehendem Rezeptformat. Neue Quellen bleiben ohne freigegebene konkrete URLs außerhalb automatischer Importe.

## Persönliche Einstellungen: klare Empfehlung

**Ja, ein kleines Einstellungsmodell ist sinnvoll.** Zuerst Essenspräferenzen und manuell bestätigte Trainings-/Ruhetagsziele anbieten. Wissenschaftliche Orientierungsbereiche optional erklären; kein universelles Fitness-Preset stillschweigend aktivieren.

### Was die Evidenz für die Einstellungen bedeutet

- **Protein:** Das [DGE-Positionspapier](https://www.dge.de/presse/meldungen/2020/positionspapier-zur-proteinzufuhr-im-sport/) unterscheidet Freizeitaktivität und höhere Trainingsumfänge; für mehr als fünf Stunden Training pro Woche nennt es abhängig von Belastung und Ziel 1,2–2,0 g/kg/Tag. Die [ISSN-Position](https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/) nennt 1,4–2,0 g/kg/Tag für die meisten trainierenden gesunden Personen und beschreibt die anhaltende Reaktion nach Krafttraining. Produktfolgerung: gleiches Proteinminimum auf Trainings- und Erholungstagen vorschlagen; manuelle Anpassung erlauben. Ein Ruhetag nach hartem Training ist kein Grund, Protein automatisch abzusenken. Diese Bereiche sind keine individuell festgelegten Ziele.
- **Kohlenhydrate:** Das [DGE-Positionspapier](https://www.dge.de/fileadmin/dok/gesunde-ernaehrung/gezielte-ernaehrung/sportler-innen/EU11_2019_M660_M667.pdf) orientiert sich an der Belastung: etwa 3–5 g/kg/Tag bei niedriger Intensität und 5–7 g/kg/Tag bei ungefähr einer Stunde moderater Belastung täglich; höhere Ausdauerumfänge sind eigene Kategorien. Produktfolgerung: Kohlenhydrate können je Tagesbelastung variieren. „Training“ als Boolean reicht für automatische Empfehlungen nicht aus; Dauer, Intensität und Sportart zählen. Kein automatisches Low-Carb-Ruhetagsprofil.
- **Ballaststoffe:** Die [DGE](https://www.dge.de/wissenschaft/referenzwerte/ballaststoffe/) nennt mindestens 30 g/Tag als Richtwert für Erwachsene. Als ausdrücklich übernehmbarer Richtwert mit Quelle anzeigen; kein niedrigeres Ruhetagsziel ableiten. Große ballaststoffreiche Mahlzeiten unmittelbar vor einer belastenden Einheit nur nach persönlicher Verträglichkeit bevorzugen.
- **Energie:** Die [DGE-Übersicht zur Sporternährung](https://www.dge.de/gesunde-ernaehrung/gezielte-ernaehrung/ernaehrung-und-sport/) betont individuelle Unterschiede. Training und Alltag beeinflussen den Bedarf; kein pauschales „Training +500 kcal“ oder „Rest −500 kcal“. Kalorien zunächst manuell als Zielbereich oder mit erklärter, bestätigter Schätzmethode eingeben. Aus „Fitness“ kein Abnehmziel ableiten.
- **Mikronährstoffe:** Referenzen hängen teilweise von Alter und Lebensphase ab; nicht pauschal an Trainingstagen erhöhen. Optional später zum [DGE/ÖGE-Referenzwerte-Tool](https://www.dge.de/wissenschaft/referenzwerte-tool/) anbinden. Fehlende Aufnahme ist bei unvollständiger Rezeptanalyse keine nachgewiesene Unterversorgung.

### Meal Prep braucht eine eigene Lagerprüfung

Die geprüfte Fit-Men-Cook-Suppe nennt eine Kühlschranklagerung von fünf bis sieben Tagen. Das übernehmen wir nicht: [USDA FSIS](https://ask.fsis.usda.gov/article/How-do-I-handle-leftovers-safely) empfiehlt gekühlte Reste innerhalb von drei bis vier Tagen zu verwenden oder für längere Lagerung einzufrieren. Ein siebentägiger Plan darf deshalb nicht automatisch eine Woche Kühlschranklagerung bedeuten. Vorhandenes gegartes Huhn ist zudem kein frisch gekochter Rohstoff mit automatisch neu beginnender Lagerfrist. In einer späteren Meal-Prep-Funktion Kochdatum, Gefrieranteil und erneuten Kochtermin getrennt vom Rezept und mit eigener Quellenprüfung behandeln.

### Kleines erstes Einstellungsmodell

| Bereich | Felder | Wirkung |
| --- | --- | --- |
| Essen | vegan / vegetarisch / gemischt; bestätigte Ausschlüsse; ungeliebte Zutaten; bevorzugte Küchen | Harte Ausschlüsse vor der Rangfolge, Vorlieben als weiche Gewichtung. Unbekannte Allergenlage nicht als „frei von“ ausgeben. |
| Alltag | verfügbare Kochzeit, Wunschportionen, Meal-Prep-Vorliebe, Wiederholungslimit | Planner-Vorgaben persistent machen; keine unbestätigten Lagerzeiten ableiten. |
| Training | Kraft / Ausdauer / gemischt; regelmäßige Wochentage; optional Dauer/Intensität; datumsbezogener Override | Zwei selbst konfigurierbare Zielprofile „Training“ und „Erholung“. Einzelfall schlägt Wochenmuster. |
| Ziele je Person und Tag | Energie als Bereich, Protein und Ballaststoffe als Minimum, Kohlenhydrate als Bereich oder manuelles Ziel; Fett optional | Minimum nicht als exaktes Optimum behandeln. Beide Profile editierbar; Kopieren statt doppelt eingeben. |
| Optionale Referenzhilfe | Gewicht in kg nur für g/kg-Hilfe; Quelle, Zielgruppe, Versions-/Abrufdatum | Erst Bereich erklären, dann vom Nutzer übernehmen lassen. Keine Körperdaten als Pflicht für reine manuelle Ziele. |
| Datenschutz und Verlauf | lokal speichern, exportieren/löschen, gültig-ab-Datum oder Ziel-Snapshot pro Tag | Bestehende lokal gespeicherte Ziele migrieren; historische Vergleiche nicht rückwirkend durch neue Ziele verändern. |

### Abgleich mit der existierenden Implementierung

Geprüfte Basis: PR #5 / Commit `7394fd367d614fb6202c6bd7d996911b062cc170`.

- `NutritionPanel.svelte` speichert ein globales `goals:v1`-Objekt für Energie, Protein, Ballaststoffe und Kohlenhydrate. Es gibt noch keine Tagesprofile, Trainingszuordnung oder Quellinformation für Ziele.
- `WeeklyPlanner.svelte` hat flüchtige Filter, ein persistiertes Planergebnis und separate Mahlzeitenziele. Kohlenhydrate sind bislang kein Planner-Zielfeld. Diese UI-Vorgaben mit den persönlichen Präferenzen verbinden.
- `server/planner.ts` bewertet Abstand zum Ziel symmetrisch. Das passt nicht zu Protein-/Ballaststoff-Minima: Ein vollständiger Wert über dem Minimum darf nicht allein wegen des Überschusses schlechter abschneiden. Energie-/Kohlenhydratbereiche innerhalb der Grenzen gleich behandeln.
- Der aktuelle Vorschlag plant **eine Mahlzeit pro Tag**. Tagesziele niemals automatisch als Ziel dieser einen Mahlzeit verwenden oder ungefragt durch drei teilen. Gewünschten Mahlzeitenanteil bzw. ein eigenständiges Mahlzeitenbudget ausdrücklich festlegen; andernfalls bei der bisherigen Rezept-/Einkaufsplanung bleiben.
- Personenziele und Kochmengen auseinanderhalten. Mehr Portionen für mehrere Personen vervielfachen die Einkaufsliste, nicht das persönliche Tagesziel. Das vorhandene `targetsPerMeal` gilt für die gesamte geplante Portionenmenge; ein neues Profil benötigt eine explizite Umrechnung.
- `nutrition_facts` bleibt die Tabelle für Lebensmittelwerte. Persönliche Zielwerte und wissenschaftliche Referenzbereiche gehören in getrennte Modelle. BLS-Werte weder durch persönliche Ziele noch durch Publisher-Schätzungen überschreiben.
- Die vorhandene Vollständigkeitsprüfung erhalten: Unvollständige Teilsummen dürfen keine Zielerfüllung oder Kalorienobergrenze bestätigen. Empfehlungen können auf vollständigen vorhandenen Mahlzeiten beruhen; bei Lücken nur bekannte Beiträge und offene Daten nennen.

### Umsetzung in dieser Reihenfolge

1. Einstellungen für Vorlieben, Ausschlüsse und persistente Planner-Vorgaben; bestehende Ziele ohne Verlust übernehmen.
2. Zwei manuelle Tagesprofile, Wochenmuster und Datums-Override; Richtwerte als optionale, zitierte Übernahmehilfe. Protein-/Ballaststoff-Minima und Energie-/Kohlenhydratbereiche korrekt vergleichen.
3. Erst mit ausreichend vollständig normalisierten Mahlzeiten Tagesbudgets und Restbedarf einbinden. Unvollständige Archivrezepte nicht durch Marketing-Tags in die Ernährungsoptimierung hochstufen.
4. Kleine kuratierte Rezeptchargen mit dokumentierter Einzelentscheidung übernehmen und neue BLS-Zuordnungen wiederverwenden. Ergebnisse beim Kochen bewerten; keine neue Vollarchiv-Sammlung.

### Abnahmekriterien für eine spätere Implementierung

- Trainingstag, Ruhetag und Datums-Override wählen nachvollziehbar das richtige bestätigte Profil.
- Profilwechsel verändert weder gespeicherten Verzehr noch historische Ziel-Snapshots.
- Protein/Faser oberhalb eines Minimums werden nicht als Zielverletzung gewertet; fehlende Angaben bleiben unbekannt.
- Haushaltsportionen ändern keine personenbezogenen Ziele; Tagesziele sind keine heimlichen Abendessensbudgets.
- Ausschlüsse wirken vor dem Ranking; bei fehlenden geeigneten Kandidaten werden Lücken gemeldet, keine Regeln stillschweigend gelockert.
- Jede optionale Referenzhilfe nennt Quelle, Population, Einheit und Stand. Manuelle Werte bleiben möglich.
