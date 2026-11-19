# Nährwertprofile

`recipe-profiles.json` enthält bewusst noch keine Profile. Die Quellarchive haben keine Nährwertdaten zurückbehalten. Das Dashboard zeigt unbekannte Werte als nicht analysiert und zählt sie nicht als Nullwerte. Die tatsächliche Zutatenanalyse ist der nächste Arbeitsschritt (PER-256).

Ein Profil benötigt `recipeId`, `basis: "per_serving"`, `quality: "estimated"` oder `"verified"`, eine HTTPS-Quelle in `sourceUrl`, ein gültiges Prüfdatum `reviewedAt` und `nutrients`. Mindestens ein numerischer Nährwert ist erforderlich. Negative, nicht endliche und unbekannte Nährstofffelder sind ungültig. Doppelte oder unbekannte Rezept-IDs verhindern den Indexaufbau. Fehlende Werte werden ausgelassen oder ausdrücklich `null` gesetzt; eine echte Null darf als Zahl `0` stehen.

Die stabilen Rezept-IDs sind über `/api/recipes?q=…` abrufbar: kuratierte Rezepte heißen zum Beispiel `ready:rotes-linsen-curry`; Archiv-IDs werden aus kanonischer URL und Karten-ID beziehungsweise Titel gebildet. Es werden keine Dateisystempfade als Rezept-IDs verwendet.

| Feld | Einheit pro Portion |
| --- | --- |
| `energy_kcal` | kcal |
| `protein_g`, `carbs_g`, `fiber_g`, `fat_g` | g |
| `sugar_g`, `saturated_fat_g` | g |
| `sodium_mg`, `calcium_mg`, `iron_mg`, `magnesium_mg`, `potassium_mg`, `zinc_mg` | mg |
| `vitamin_b12_ug`, `vitamin_d_ug`, `folate_ug`, `iodine_ug`, `selenium_ug` | µg |

Ein vorhandenes Profil bedeutet nicht automatisch vollständige Makro-/Mikronährwerte. Die API liefert deshalb für jeden Nährstoff eine eigene Abdeckung. Geschätzte und verifizierte Profile bleiben unterscheidbar. Tagesziele stammen ausschließlich aus den persönlichen Eingaben; es werden keine Ernährungsziele anhand angenommener Körperdaten gesetzt.

Vor dem nächsten Analyseschritt werden Referenzlebensmittel samt Datenbank-ID und Version, essbare Mengen, Garzustand, Ausbeute und Unsicherheiten benötigt. ml, EL, Stück oder ein Ingwerstück werden nicht stillschweigend in Gramm umgerechnet. Verzehreinträge und Ziele bleiben im lokalen Browser-Speicher; die Bun-API berechnet aus Rezept-IDs und Portionen nur die angeforderte Auswertung.
