-- Einkaufsliste für einen Zeitraum.
-- Skalierung (Portionen) passiert in v_meal_plan_lines.
-- Hier werden Mengen derselben Zutat, Variante und Einheit summiert
-- und nach Supermarkt-Abteilung sortiert.
--
-- Daten an den Plan anpassen. Vorrat (Salz, Mehl, Zucker, Staubzucker)
-- ausblenden: die pantry_staple-Zeile einkommentieren.
-- Optionale Zutaten ausblenden: AND optional = 0 ergänzen.
--
-- Erwartet für den Seed (Kaiserschmarrn, 2 Portionen, 16. Nov 2026):
--   Zitrone                 0,5 Stk
--   Butter                  60 g
--   Eier (Gr. M)            4 Stk
--   Milch                   200 g
--   Feinkristallzucker      80 g      (30 g Teig + 50 g Karamell)
--   Mehl glatt              120 g
--   Staubzucker             10 g
--   Rosinen                 30 g
--   Salz                    1 Prise
--   Vanillezucker           1 Pkt     (Basis 8 g, übliches Packerl, nicht von Demel)
--   Demel's Zwetschkenröster 1 Glas
--   Rum                     10 g

SELECT
  category_sort,
  category_name AS kategorie,
  ingredient_name AS zutat,
  variant AS variante,
  ROUND(SUM(scaled_quantity), 2) AS menge,
  unit_code AS einheit,
  ROUND(SUM(scaled_base_quantity), 2) AS basis_menge,
  base_unit_code AS basis_einheit,
  pantry_staple AS vorrat,
  MIN(amount_text) AS mengentext
FROM v_meal_plan_lines
WHERE plan_date BETWEEN '2026-11-16' AND '2026-11-22'
  -- AND pantry_staple = 0
GROUP BY
  category_sort,
  category_name,
  ingredient_name,
  variant,
  unit_code,
  base_unit_code,
  pantry_staple
ORDER BY
  category_sort,
  ingredient_name,
  unit_code;
