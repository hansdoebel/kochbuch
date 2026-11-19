# Nährwertdaten

Primärquelle ist **Max Rubner-Institut (2025): Bundeslebensmittelschlüssel (BLS), Version 4.0 — Deutsche Nährstoffdatenbank. Karlsruhe. DOI: [10.25826/Data20251217-134202-0](https://doi.org/10.25826/Data20251217-134202-0)**, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Der Snapshot ist eine reduzierte, strukturierte Übernahme von 17 Komponenten aller 7.140 Lebensmittel; Originalwerte, Herkunft und Literaturverweise bleiben erhalten. Keine Original-Exceldatei oder Binärdatenbank im Git. Entscheidung und Alternativen: [Recherche](../docs/nutrition-research.md).

## Tabellen und Datenfluss

`db/schema.sql` definiert `nutrition_datasets`, `nutrition_nutrients`, `nutrition_foods`, **`nutrition_facts`**, `ingredient_nutrition_matches` und `recipe_nutrition_weights`. `nutrition_facts` enthält eine Zeile pro Lebensmittel und Nährstoff mit Menge je 100 g, ursprünglichem Nährstoffcode, Herkunft, Literaturreferenz und eventuellem Marker. Die Datenbank lässt sich aus den Textdateien vollständig reproduzieren:

```bash
python3 db/build_db.py --check
npm run lint:nutrition
npm run nutrition:report
```

Der letzte Befehl schreibt `.cache/nutrition/review.json`: fehlende Zuordnungen nach Rezeptwiederverwendung, Vorschläge zur Prüfung und Rezeptzeilen ohne essbares Gewicht. Textähnlichkeit ist nur eine Prüfhilfe, keine automatische Freigabe. Der Webserver lädt dieselben Snapshots und berechnet daraus die Profile beim Indexaufbau. Quellen-/Mengenänderungen invalidieren den Index automatisch. Die UI lädt nie den ganzen Referenzdatensatz: `/api/nutrition/foods` liefert 25 Treffer je Seite, `/api/nutrition/status` Bestand und Lücken.

`v_recipe_nutrition_lines` bestimmt Gramm nur aus Masseinheiten, vorhandenen expliziten Produktumrechnungen oder belegten Zeilengewichten. `v_recipe_nutrition` liefert je Rezept und Nährstoff eine bekannte Teilsumme pro Portion sowie `known_lines` und `total_lines`. Nur gleiche Werte bedeuten vollständige Zutatenabdeckung. NULL bleibt unbekannt; echte Null bleibt 0. Optionale Zutaten sind im kuratierten Basisrezept ausgeschlossen. Keine pauschalen Gar-/Retentionsfaktoren.

## Regelmäßig erweitern

1. In der Lebensmittel-Tabelle der Ernährungsansicht nach Name, englischem Namen oder BLS-Code suchen; Lebensmittelzustand und Fettgehalt prüfen. „Linse rot reif“ ist trocken, „gekocht“ ein anderer Datensatz.
2. Eine Zuordnung in `matches.json` ergänzen: `ingredient_id`, exakt vorhandener `ingredient_name`, versionierte `food_id` wie `bls-4.0:H730000`, `method: "reviewed"`, `reviewed_on` und eine ehrliche `note`. IDs und Namen werden gegengeprüft. Keine Alternativen oder Markenprodukte einem vermeintlich passenden Lebensmittel zuordnen.
3. Fehlende essbare Mengen in `weights` ergänzen, ausschließlich mit `recipe_ingredient_id`, gewogenen/belegten `edible_grams`, HTTPS-`source_url`, `reviewed_on` und `note`. Beispiel: tatsächlich verwendete Zitronenschale wiegen; die kaufbare Menge in der Einkaufsliste bleibt unverändert. Leere `weights` sind gültig.
4. Für Archive kann `aliases.json` geprüfte exakte Namen auf eine versionierte `food_id` abbilden. Nur eindeutige führende g/kg-Mengen werden automatisch berechnet. Mehrdeutige Zeilen bleiben offen; vorhandene Portionen müssen eindeutig numerisch sein.
5. `npm run lint:nutrition`, Rezeptprüfungen und `cd web && bun test` ausführen; neue Zuordnungen wirken sofort in allen betroffenen Rezepten beim nächsten Serverstart.

Es gibt bewusst keine externen Anfragen während der Rezeptsuche oder automatische Freigabe unsicherer Zuordnungen.

## Referenzdaten aktualisieren

```bash
# Offiziellen fixierten Download prüfen und Snapshot bytegenau reproduzieren:
python3 nutrition/import_bls.py --download --check
# Offline aus einer vorhandenen offiziellen ZIP-Datei:
python3 nutrition/import_bls.py --archive /pfad/BLS_4_0_2025_DE.zip --check
```

`bls-source.json` fixiert Version, Quell-URL, ZIP-Größe, SHA-256, Abrufdatum und erwartete Lebensmittelzahl. `snapshot-lock.json` schützt den erzeugten Text gegen versehentliche Änderungen. Ohne `--check` schreibt der Importer Snapshot und Lock atomar je Datei neu. Die ZIP bleibt unter `.cache/`. Netzwerkfehler, andere Prüfsummen, Einheiten oder Lebensmittelzahlen überschreiben den Snapshot nicht.

Ein monatlicher GitHub-Action-Lauf prüft die aktuelle Download-Liste auf eine neue Version, reproduziert die fixierte offizielle Version und prüft die Zuordnungen. Die Erstaktivierung des Zeitplans erfolgt nach Merge in den Default-Branch. Er lädt keine unbekannte neue Version stillschweigend. Bei einer neuen BLS-Version: offiziellen Download prüfen, den Importadapter/Manifest explizit aktualisieren, einen neuen versionierten Snapshot ergänzen, Zuordnungen auf geänderte Lebensmittelcodes prüfen und als normalen PR validieren. USDA/Ciqual können weitere Snapshots mit eigenem Dataset-/Lizenznachweis liefern; Einheiten und Nährstoffdefinitionen müssen vorher abgeglichen werden.

## Manuelle Rezeptprofile

`recipe-profiles.json` bleibt als explizite Ausnahme erhalten. Ein manuelles Profil hat Vorrang vor der Zutatenberechnung und braucht `recipeId`, `basis: "per_serving"`, `quality: "estimated"` oder `"verified"`, HTTPS-`sourceUrl`, gültiges `reviewedAt` und `nutrients`. Mindestens ein nicht negativer numerischer Wert ist erforderlich. Fehlende Felder werden ausgelassen oder auf `null` gesetzt. „verified“ nur für tatsächlich belegte Werte verwenden. Derzeit sind keine manuellen Profile nötig.

| Felder | Einheit |
| --- | --- |
| `energy_kcal` | kcal |
| `protein_g`, `carbs_g`, `fiber_g`, `fat_g`, `sugar_g`, `saturated_fat_g` | g |
| `sodium_mg`, `calcium_mg`, `iron_mg`, `magnesium_mg`, `potassium_mg`, `zinc_mg` | mg |
| `vitamin_b12_ug`, `vitamin_d_ug`, `folate_ug`, `iodine_ug`, `selenium_ug` | µg |

BLS CHO sind verfügbare Kohlenhydrate, FOLFD ist Folat, ID ist Iodid. Selen wird von diesem Import nicht bereitgestellt. Bei Datenlücken zeigt das Dashboard Teilsummen und Abdeckung je Nährstoff. Ziele setzt der Nutzer; Vorschläge werden niemals automatisch als gegessen protokolliert.


Persönliche Trainings-/Ruhetagsziele, Portionenanpassung und die erneute Prüfung sind in [nutrition-audit-and-diet-plans.md](../docs/nutrition-audit-and-diet-plans.md) dokumentiert. Herausgeber-Schätzwerte können ausdrücklich als separate Makrobasis gewählt werden; fehlende BLS-Werte werden damit nicht aufgefüllt.
