# Nährwertdaten: Recherche und Entscheidung

Geprüft am 19. November 2026. Primärdaten werden lokal versioniert; die Anwendung benötigt weder einen externen API-Schlüssel noch laufende Netzabfragen.

| Datenbank | Eignung und Wiederverwendung | Entscheidung |
| --- | --- | --- |
| [BLS 4.0, Max Rubner-Institut](https://blsdb.de/download) | Deutsche Referenzdaten, 7.140 Lebensmittel im Download, bis zu 138 Komponenten; Herkunft pro Wert. Seit Version 4.0 Open Data unter CC BY 4.0. [MRI-Beschreibung](https://www.mri.bund.de/de/institute/ernaehrungsverhalten/forschungsbereiche/bundeslebensmittelschluessel-bls/). | Primärquelle: passt zur deutschen Zutatenliste und hat konsistent definierte verfügbare Kohlenhydrate. |
| [USDA FoodData Central](https://fdc.nal.usda.gov/data-documentation/) | Foundation und SR Legacy für generische Lebensmittel; Branded für Produktetiketten. [CC0, API mit Schlüssel](https://fdc.nal.usda.gov/api-guide/); [Bulk-Downloads](https://fdc.nal.usda.gov/download-datasets/) ohne API. | Gute spätere Ergänzung für BLS-Lücken. Nicht stillschweigend US-Kohlenhydrate „by difference“ mit verfügbaren Kohlenhydraten gleichsetzen. |
| [ANSES Ciqual 2025](https://doi.org/10.57745/RDMHWY) | Europäische generische Lebensmittel, französische Bezeichnungen, offene Etalab-2.0-Lizenz mit Quellenangabe. | Geeignete zusätzliche Referenz; zunächst eine Primärquelle für konsistente Definitionen. |
| [UK CoFID 2021](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid) | Offizieller britischer Tabellen-Download; nützlich für britische Lebensmittel. | Zusätzlicher Adapter möglich; Definitions- und Zustandsabgleich nötig. |
| [Open Food Facts](https://world.openfoodfacts.org/data) | Produkt-/Barcode-Daten, ODbL, meist Etikettwerte. | Später für konkrete Produkte, separat mit Attribution und Lizenzpflichten. Kein Ersatz für durchgängige generische Mikronährwerte. |

## Umsetzung

Die offizielle BLS-ZIP-Datei ist mit SHA-256 fixiert. Der Standardbibliothek-Importer liest XLSX direkt, prüft Quellcodes und Einheiten und erzeugt einen kleinen Text-Snapshot statt eingecheckter Excel-/SQLite-Dateien. Enthalten sind alle 7.140 Lebensmittel und 17 für das Dashboard benötigte Nährstoffe, je 100 g essbarer Anteil. Die restlichen BLS-Komponenten werden nicht importiert. Selen ist in dieser Auswahl/Quelle nicht vorhanden und bleibt unbekannt. „Folat“ ist BLS FOLFD, nicht Folat-Äquivalent; „Kohlenhydrate“ ist BLS CHO, verfügbar.

Herkunftskategorien, Literaturverweise und Kennzeichnungen wie TR, <LOD und <LOQ bleiben erhalten. Eine ausdrücklich veröffentlichte Null bleibt Null; Spuren und Nachweisgrenzen werden mangels quantifizierter Menge nicht als Null ausgegeben. Nährwertprofile aus Rezept-Websites ersetzen diese Referenztabelle nicht.

Freigegebene Zutatenzuordnungen beziehen sich auf Datenbankversion und Lebensmittelcode. Die erste Fassung enthält 33 Zuordnungen. Mehrdeutige Alternativen wie „Tamari oder Sojasauce“, Produkt-Fettgehalte und essbare Gewichte bleiben offen. Gleichnamige Zutaten verwenden dieselbe Zuordnung in allen Rezepten. Exakte geprüfte englische Aliasse erlauben zusätzlich eine konservative Archiv-Analyse expliziter g/kg-Zeilen; Cups, Stück, Spannen und mehrdeutige Lebensmittel werden nicht interpretiert. Die Archivdateien selbst bleiben unverändert.

Berechnungen sind geschätzte Zutatenbilanzen pro Portion, keine Laboranalyse einer fertigen Mahlzeit. Nicht aufgenommene Zutaten und fehlende Mikronährwerte erscheinen in der Abdeckung und als Lücken. Optionale Zutaten fehlen im kuratierten Basisrezept. Garverluste, Vitaminretention und Alkoholverdampfung werden nicht pauschal angenommen. Gewichte können für einzelne Rezeptzeilen mit Quelle ergänzt werden; das verhindert, dass Zitronenschale als halbe ganze Frucht berechnet wird.

## Wochenplanung

Der deterministische Vorschlag wählt bis zu sieben einzelne Mahlzeiten aus kuratierten Rezepten. Hauptgerichte sind voreingestellt; Vegan-Filter, Zeitlimit, Portionszahl und Wiederholungslimit sind explizit. Gemeinsame Zutaten und Datenabdeckung helfen bei der Reihenfolge; gleiche Rezepte stehen nicht direkt hintereinander. Es gibt keine implizite Mindestproteinzufuhr oder persönliche Kalorienvorgabe.

Optionale Nährwertziele gelten für die gesamte geplante Portionenmenge einer Mahlzeit. Sie fließen nur bei vollständiger Zutatenabdeckung für alle Zielnährstoffe in die Rangfolge ein. Geschätzte Teilsummen werden niemals als passende Kalorienobergrenze gewertet. Bei den anfänglich unvollständigen Rezepten dient der Vorschlag daher vor allem Abwechslung, Zeit und Einkauf. Er ist kein medizinischer Ernährungsplan, keine vollständige Tagesbilanz und kein Haltbarkeits- oder Allergentest.

Der Vorschlag bleibt lokal gespeichert und getrennt vom Verzehrprotokoll. Übernahme ersetzt die Rezeptauswahl und öffnet die bestehende Einkaufsansicht mit PDF-/Typst-Export. Mehrfach geplante Rezepte werden für die Mengen zusammengezogen.
