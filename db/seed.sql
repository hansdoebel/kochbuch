-- Seed im Gleichschritt mit rezepte/*.md.
-- Neue Zeilen mit fester id (MAX(id)+1), damit dieselbe Datei in Postgres läuft.
-- Nächste freie ids nach diesem Seed:
--   shopping_categories 11, units 13, ingredients 13, recipes 2,
--   tags 5, recipe_ingredients 14, meal_plans 2, meal_plan_entries 2.

INSERT INTO shopping_categories (id, name, sort_order) VALUES
  (1, 'Obst & Gemüse', 10),
  (2, 'Milchprodukte & Eier', 20),
  (3, 'Fleisch & Wurst', 30),
  (4, 'Fisch', 40),
  (5, 'Grundnahrungsmittel', 50),
  (6, 'Gewürze & Backzutaten', 60),
  (7, 'Konserven & Gläser', 70),
  (8, 'Tiefkühl', 80),
  (9, 'Getränke', 90),
  (10, 'Sonstiges', 100);

INSERT INTO units (id, code, name, dimension, base_unit_code, factor_to_base) VALUES
  (1, 'g', 'Gramm', 'mass', 'g', 1),
  (2, 'kg', 'Kilogramm', 'mass', 'g', 1000),
  (3, 'ml', 'Milliliter', 'volume', 'ml', 1),
  (4, 'l', 'Liter', 'volume', 'ml', 1000),
  -- Küchenmaße, nur zum Zusammenziehen, wenn ein Rezept EL/TL sagt.
  (5, 'EL', 'Esslöffel', 'volume', 'ml', 15),
  (6, 'TL', 'Teelöffel', 'volume', 'ml', 5),
  (7, 'Msp', 'Messerspitze', 'qualitative', NULL, NULL),
  (8, 'Prise', 'Prise', 'qualitative', NULL, NULL),
  (9, 'Stk', 'Stück', 'count', 'Stk', 1),
  -- Pkt, Bund und Glas hängen am Produkt und haben keinen allgemeinen Faktor.
  (10, 'Pkt', 'Packung', 'qualitative', NULL, NULL),
  (11, 'Bund', 'Bund', 'qualitative', NULL, NULL),
  (12, 'Glas', 'Glas', 'qualitative', NULL, NULL);

INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES
  (1, 'Eier', 2, 9, 0),
  (2, 'Feinkristallzucker', 5, 1, 1),
  (3, 'Milch', 2, 1, 0),
  (4, 'Mehl glatt', 5, 1, 1),
  (5, 'Salz', 6, 8, 1),
  (6, 'Zitrone', 1, 9, 0),
  (7, 'Vanillezucker', 6, 10, 0),
  (8, 'Rosinen', 6, 1, 0),
  (9, 'Rum', 9, 1, 0),
  (10, 'Butter', 2, 1, 0),
  (11, 'Staubzucker', 5, 1, 1),
  (12, 'Demel''s Zwetschkenröster', 7, 12, 0);

-- Übliches 8-g-Packerl, keine Angabe von Demel. Die Einkaufsliste zeigt weiter Pkt.
INSERT INTO ingredient_unit_conversions (
  ingredient_id, unit_id, base_unit_code, factor_to_base, note
) VALUES (
  7, 10, 'g', 8,
  'Übliches österreichisches Vanillezucker-Packerl à 8 g. Nicht aus der Demel-Quelle.'
);

INSERT INTO recipes (
  id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes
) VALUES (
  1,
  'kaiserschmarrn',
  'Kaiserschmarrn',
  2,
  'Personen',
  20,
  15,
  'Demel via Kurier TV',
  'Zubereitung und Zeiten sind eine Rekonstruktion und mit dem Original abzugleichen. Zitronenschale als 0,5 Stk. Zitrone erfasst.'
);

INSERT INTO tags (id, name) VALUES
  (1, 'Mehlspeise'),
  (2, 'Süßspeise'),
  (3, 'Österreichisch'),
  (4, 'Demel');

INSERT INTO recipe_tags (recipe_id, tag_id) VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 4);

-- Reihenfolge wie in rezepte/kaiserschmarrn.md.
INSERT INTO recipe_ingredients (
  id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation,
  ingredient_group, variant, optional, sort_order
) VALUES
  (1, 1, 1, 4, 9, NULL, NULL, 'Teig', 'Gr. M', 0, 10),
  (2, 1, 2, 30, 1, NULL, NULL, 'Teig', NULL, 0, 20),
  (3, 1, 3, 200, 1, NULL, NULL, 'Teig', NULL, 0, 30),
  (4, 1, 4, 120, 1, NULL, NULL, 'Teig', NULL, 0, 40),
  (5, 1, 5, 1, 8, NULL, NULL, 'Teig', NULL, 0, 50),
  (
    6, 1, 6, 0.5, 9,
    'geriebene Schale von einer halben Zitrone',
    'geriebene Schale',
    'Teig', NULL, 0, 60
  ),
  (7, 1, 7, 1, 10, NULL, NULL, 'Teig', NULL, 0, 70),
  (8, 1, 8, 30, 1, NULL, NULL, 'Zum Einweichen', NULL, 0, 80),
  (9, 1, 9, 10, 1, NULL, NULL, 'Zum Einweichen', NULL, 0, 90),
  (10, 1, 10, 60, 1, NULL, NULL, 'Zum Backen', NULL, 0, 100),
  (11, 1, 2, 50, 1, NULL, NULL, 'Zum Karamellisieren', NULL, 0, 110),
  (12, 1, 11, 10, 1, NULL, NULL, 'Zum Bestreuen', NULL, 0, 120),
  (13, 1, 12, 1, 12, NULL, NULL, 'Zum Servieren', NULL, 0, 130);

INSERT INTO meal_plans (id, name, starts_on, ends_on, notes) VALUES (
  1,
  'Beispielwoche',
  '2026-11-16',
  '2026-11-22',
  'Ein Mittagessen, damit die Einkaufsliste den Kaiserschmarrn zeigt.'
);

INSERT INTO meal_plan_entries (
  id, meal_plan_id, plan_date, meal_slot, recipe_id, servings, notes
) VALUES (
  1, 1, '2026-11-16', 'Mittagessen', 1, 2, NULL
);
