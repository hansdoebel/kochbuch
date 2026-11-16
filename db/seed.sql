-- Seed im Gleichschritt mit rezepte/*.md.
-- Neue Zeilen mit fester id (MAX(id)+1), damit dieselbe Datei in Postgres läuft.
-- Freie ids vor Ergänzungen mit SELECT MAX(id) + 1 ermitteln.

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

-- Rainbow Plant Life: deutsche Übertragungen, Originalquellen in recipes.source.
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes) VALUES (2, 'rotes-linsen-curry', 'Rotes Linsen-Curry', 4, 'Portionen', 10, 35, 'Nisha Vora – Rainbow Plant Life – https://rainbowplantlife.com/vegan-red-lentil-curry/', 'Deutsche, gekürzte Übertragung der Original-Rezeptkarte. Mengen und Zeiten stammen aus der Quelle; abgerufen am 16.11.2026. Für die Einkaufsliste werden die oberen Enden der Quellspannen verwendet: 190 g Linsen und 2 Chilis. Die Quelle erlaubt, die Chilis ganz wegzulassen; deshalb sind sie optional erfasst. 2 inch Ingwer sind als ca. 5 cm umgerechnet. Keine Grammzahl für das Ingwerstück schätzen. Statt frischem Kurkuma erlaubt die Quelle 1 TL gemahlenen Kurkuma; diesen erst mit den übrigen Gewürzen zugeben. Für eine milde Variante weniger Chili verwenden. Reis/Fladenbrot hat keine Quellmenge und bleibt unbeziffert.');
INSERT INTO tags (id, name) VALUES (5, 'Vegan');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (2, 5);
INSERT INTO tags (id, name) VALUES (6, 'Hauptgericht');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (2, 6);
INSERT INTO tags (id, name) VALUES (7, 'Rainbow Plant Life');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (2, 7);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (13, 'Kokosöl', 5, 5, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (14, 2, 13, 1.0, 5, '1 EL Kokosöl', NULL, 'Curry', 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (14, 'Knoblauchzehen', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (15, 2, 14, 4.0, 9, '4 Stk. Knoblauchzehen, gehackt', 'gehackt', 'Curry', 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (15, 'Ingwer', 1, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (16, 2, 15, NULL, NULL, '1 Stück Ingwer, ca. 5 cm lang, geschält und gehackt', 'geschält und gehackt', 'Curry', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (16, 'Kurkuma frisch', 1, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (17, 2, 16, 1.0, 5, '1 EL frischer Kurkuma, gehackt', 'gehackt', 'Curry', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (17, 'Serrano-Chilis', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (18, 2, 17, 2.0, 9, '1–2 Stk. Serrano-Chilis, gewürfelt', 'gewürfelt', 'Curry', 1, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (18, 'Kreuzkümmel', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (19, 2, 18, 1.0, 6, '1 TL Kreuzkümmel, gemahlen', 'gemahlen', 'Curry', 0, 60);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (19, 'Koriander gemahlen', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (20, 2, 19, 0.5, 6, '0,5 TL Koriander, gemahlen', NULL, 'Curry', 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (20, 'Indisches rotes Chilipulver', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (21, 2, 20, 0.5, 6, '0,5 TL indisches rotes Chilipulver', NULL, 'Curry', 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (21, 'Currypulver', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (22, 2, 21, 2.0, 6, '2 TL Currypulver', NULL, 'Curry', 0, 90);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (22, 'Garam Masala', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (23, 2, 22, 1.0, 6, '1 TL Garam Masala', NULL, 'Curry', 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (24, 2, 5, NULL, NULL, 'Salz nach Geschmack', NULL, 'Curry', 0, 110);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (23, 'Schwarzer Pfeffer', 6, NULL, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (25, 2, 23, NULL, NULL, 'Schwarzer Pfeffer nach Geschmack', 'frisch gemahlen', 'Curry', 0, 120);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (24, 'Rote Linsen', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (26, 2, 24, 190.0, 1, '180–190 g rote Linsen', 'gespült', 'Curry', 0, 130);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (25, 'Gemüsebrühe', 5, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (27, 2, 25, 480.0, 3, '480 ml Gemüsebrühe, salzarm', 'salzarm', 'Curry', 0, 140);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (26, 'Tomaten aus der Dose', 7, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (28, 2, 26, 400.0, 1, '400 g zerkleinerte Tomaten aus der Dose', 'zerkleinert', 'Curry', 0, 150);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (27, 'Kokosmilch', 7, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (29, 2, 27, 400.0, 3, '400 ml Kokosmilch, vollfett', NULL, 'Curry', 0, 160);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (28, 'Mandelmus', 7, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (30, 2, 28, 3.0, 5, '3 EL Mandelmus, ungesüßt und cremig', NULL, 'Curry', 0, 170);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (31, 2, 6, 0.5, 9, 'Saft von 0,5 Stk. kleiner Zitrone', 'ausgepresst', 'Curry', 0, 180);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (29, 'Koriander frisch', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (32, 2, 29, 8.0, 1, 'ca. 8 g frischer Koriander, grob gehackt', 'grob gehackt', 'Curry', 0, 190);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (30, 'Reis oder indisches Fladenbrot', 5, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (33, 2, 30, NULL, NULL, 'Basmati- oder Jasminreis und/oder indisches Fladenbrot nach Bedarf', NULL, 'Zum Servieren', 0, 200);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes) VALUES (3, 'linsen-bolognese', 'Linsen-Bolognese', 6, 'Portionen', 10, 45, 'Nisha Vora – Rainbow Plant Life – https://rainbowplantlife.com/10-ingredient-vegan-red-lentil-bolognese/', 'Deutsche, gekürzte Übertragung der Original-Rezeptkarte. Abgerufen am 16.11.2026. Die Einweichzeit von 30–60 Minuten kommt zur Vorbereitung hinzu; die Quell-Rezeptkarte nennt 10 Minuten Vorbereitung und 45 Minuten Kochen. Die Quelle nennt 340–454 g Pasta; für die Einkaufsliste sind 454 g gewählt. Statt Walnüssen sind Pekannüsse, statt Thymian mehr Oregano möglich. Kräuter und Rotwein sind in der Quelle ausdrücklich optional. Kosher-Salz ist gröber als feines Speisesalz; die TL-Menge nicht ungeprüft durch dieselbe Menge feines Salz ersetzen. Übrige Sauce getrennt von Pasta aufbewahren.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (3, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (3, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (3, 7);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (31, 'Olivenöl', 5, 5, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (34, 3, 31, 1.5, 5, '1,5 EL Olivenöl', NULL, 'Sauce', 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (32, 'Zwiebel', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (35, 3, 32, 1.0, 9, '1 Stk. große Zwiebel, gewürfelt', 'gewürfelt', 'Sauce', 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (36, 3, 14, 4.0, 9, '4 Stk. Knoblauchzehen, gehackt', 'gehackt', 'Sauce', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (33, 'Oregano', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (37, 3, 33, 1.0, 6, '1 TL Oregano, getrocknet', 'getrocknet', 'Sauce', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (34, 'Thymian getrocknet', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (38, 3, 34, 1.0, 6, '1 TL Thymian, getrocknet', NULL, 'Sauce', 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (39, 3, 5, 1.5, 6, '1,5 TL Kosher-Salz, zusätzlich nach Geschmack', NULL, 'Sauce', 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (40, 3, 23, NULL, NULL, 'Schwarzer Pfeffer nach Geschmack', 'frisch gemahlen', 'Sauce', 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (35, 'Tomatenmark', 7, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (41, 3, 35, 150.0, 1, '150 g Tomatenmark', NULL, 'Sauce', 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (36, 'Rotwein', 9, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (42, 3, 36, 120.0, 3, '120 ml trockener Rotwein, optional', NULL, 'Sauce', 1, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (43, 3, 25, 720.0, 3, '720 ml Gemüsebrühe', NULL, 'Sauce', 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (44, 3, 24, 185.0, 1, '185 g rote Linsen, vor dem Einweichen gewogen', '30–60 Minuten eingeweicht', 'Sauce', 0, 110);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (37, 'Walnüsse', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (45, 3, 37, 32.0, 1, '32 g Walnüsse, fein zerkleinert', 'fein zerkleinert', 'Sauce', 0, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (46, 3, 26, 410.0, 1, '410 g zerkleinerte Tomaten aus der Dose', 'zerkleinert', 'Sauce', 0, 130);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (38, 'Pasta', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (47, 3, 38, 454.0, 1, '340–454 g lange, breite Pasta', NULL, 'Pasta', 0, 140);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (39, 'Balsamico', 7, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (48, 3, 39, 1.0, 5, '1 EL hochwertiger Balsamico', NULL, 'Zum Abschmecken', 0, 150);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (40, 'Petersilie oder Basilikum', 1, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (49, 3, 40, NULL, NULL, 'Petersilie oder Basilikum nach Bedarf, optional', 'gehackt', 'Zum Servieren', 1, 160);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes) VALUES (4, 'tofu-scramble', 'Tofu-Scramble', 3, 'Portionen', 15, 10, 'Nisha Vora – Rainbow Plant Life – https://rainbowplantlife.com/eggy-tofu-scramble/', 'Deutsche, gekürzte Übertragung der Original-Rezeptkarte. Abgerufen am 16.11.2026. Die Quelle nennt 3–4 Portionen und einen Tofublock mit 400 oder 454 g. Hier und in der Datenbank sind 3 Portionen und 400 g gewählt. Der großzügige EL Tahin bleibt als 1 EL mit Mengentext erfasst; keine Gramm-Schätzung. Kala Namak sorgt für den Ei-Geschmack. Etwas davon erst kurz vor dem Servieren ergänzen, da sein Aroma beim Erhitzen nachlässt. Andere cremige Pflanzenmilch ist laut Quelle möglich.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (4, 5);
INSERT INTO tags (id, name) VALUES (8, 'Frühstück');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (4, 8);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (4, 7);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (41, 'Tofu fest', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (50, 4, 41, 400.0, 1, '400 g fester Tofu', 'gepresst und zerbröselt', 'Tofu', 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (42, 'Knoblauchpulver', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (51, 4, 42, 0.5, 6, '0,5 TL Knoblauchpulver', NULL, 'Sauce', 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (43, 'Zwiebelpulver', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (52, 4, 43, 0.5, 6, '0,5 TL Zwiebelpulver', NULL, 'Sauce', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (44, 'Chipotle-Chiliflocken', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (53, 4, 44, 0.5, 6, '0,5 TL Chipotle-Chiliflocken', NULL, 'Sauce', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (45, 'Paprikapulver', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (54, 4, 45, 0.25, 6, '0,25 TL Paprikapulver', NULL, 'Sauce', 0, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (46, 'Kurkuma gemahlen', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (55, 4, 46, 0.25, 6, '0,25 TL Kurkuma, gemahlen', NULL, 'Sauce', 0, 60);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (47, 'Kala Namak', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (56, 4, 47, 0.5, 6, '0,5 TL Kala Namak, zusätzlich etwas zum Fertigstellen', NULL, 'Sauce', 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (57, 4, 23, NULL, NULL, 'Schwarzer Pfeffer nach Geschmack', 'frisch gemahlen', 'Sauce', 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (48, 'Tahin', 7, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (58, 4, 48, 1.0, 5, '1 großzügiger EL Tahin', NULL, 'Sauce', 0, 90);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (49, 'Hefeflocken', 5, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (59, 4, 49, 2.0, 5, '2 EL Hefeflocken', NULL, 'Sauce', 0, 100);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (50, 'Hafermilch', 5, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (60, 4, 50, 120.0, 3, '120 ml vollmundige Hafermilch', NULL, 'Sauce', 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (61, 4, 31, 1.0, 5, '1 EL Olivenöl', NULL, 'Zum Braten', 0, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (62, 4, 5, NULL, NULL, 'Meersalz oder Kosher-Salz nach Geschmack', NULL, 'Zum Abschmecken', 0, 130);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes) VALUES (5, 'pilz-stroganoff', 'Cremiges Pilz-Stroganoff', 6, 'Portionen', 20, 50, 'Nisha Vora – Rainbow Plant Life – https://rainbowplantlife.com/creamy-vegan-mushroom-stroganoff/', 'Deutsche, gekürzte Übertragung der Original-Rezeptkarte. Abgerufen am 16.11.2026. Die Quelle nennt 3–4 EL Öl und 2 große oder 3 kleinere Lauchstangen; die Einkaufsliste verwendet 4 EL und 2 große Stangen. Für Brühe und Dill gilt offengelegt 1 US-Cup ≈ 240 ml: 1,5 Cups = 360 ml, 0,25 Cup = 60 ml. Für Dill kein Grammgewicht erfinden. Frischen Thymian kann laut Quelle 1 TL getrockneter Thymian ersetzen. Kosher-Salz vorsichtig dosieren, wenn feines Speisesalz verwendet wird. Worcestersauce muss vegan sein.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (5, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (5, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (5, 7);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (63, 5, 31, 4.0, 5, '3–4 EL Olivenöl, aufgeteilt', 'aufgeteilt', 'Pilze', 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (51, 'Lauch', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (64, 5, 51, 2.0, 9, '2 Stk. große Lauchstangen, geschnitten und gewaschen', 'geschnitten und gewaschen', 'Pilze', 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (52, 'Gemischte Pilze', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (65, 5, 52, 560.0, 1, 'ca. 560 g gemischte Pilze, geschnitten oder gezupft', 'geschnitten oder gezupft', 'Pilze', 0, 30);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (66, 5, 14, 6.0, 9, '6 Stk. Knoblauchzehen, gehackt', 'gehackt', 'Pilze', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (53, 'Thymian frisch', 1, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (67, 5, 53, 1.0, 5, '1 EL frische Thymianblätter, grob gehackt', 'grob gehackt', 'Pilze', 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (68, 5, 5, NULL, NULL, 'Kosher-Salz nach Geschmack', NULL, 'Pilze', 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (69, 5, 25, 360.0, 3, '360 ml Gemüsebrühe, umgerechnet aus 1,5 US-Cups', NULL, 'Sauce', 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (54, 'Tamari oder Sojasauce', 7, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (70, 5, 54, 2.0, 5, '2 EL Tamari oder Sojasauce', NULL, 'Sauce', 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (55, 'Vegane Worcestersauce', 7, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (71, 5, 55, 1.0, 5, '1 EL vegane Worcestersauce, optional', NULL, 'Sauce', 1, 90);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (56, 'Weizenmehl', 5, 1, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (72, 5, 56, 30.0, 1, 'ca. 30 g Weizenmehl', NULL, 'Sauce', 0, 100);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (57, 'Weißwein', 9, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (73, 5, 57, 120.0, 3, 'ca. 120 ml trockener Weißwein', NULL, 'Sauce', 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (74, 5, 27, 400.0, 3, '400 ml Kokosmilch, vollfett', NULL, 'Sauce', 0, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (75, 5, 48, 2.0, 5, '2 EL Tahin', NULL, 'Sauce', 0, 130);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (76, 5, 49, 2.0, 5, '2 EL Hefeflocken', NULL, 'Sauce', 0, 140);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (77, 5, 45, 1.0, 6, '1 TL Paprikapulver', NULL, 'Sauce', 0, 150);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (58, 'Senf', 7, 6, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (78, 5, 58, 0.5, 6, '0,5 TL Dijon-Senf oder grober Senf', NULL, 'Sauce', 0, 160);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (79, 5, 38, 340.0, 1, '340 g Pasta', NULL, 'Pasta', 0, 170);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (59, 'Dill frisch', 1, 3, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (80, 5, 59, 60.0, 3, '60 ml frischer Dill, gehackt, umgerechnet aus 0,25 US-Cup', 'gehackt', 'Zum Fertigstellen', 0, 180);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (81, 5, 23, NULL, NULL, 'Schwarzer Pfeffer nach Geschmack', 'frisch gemahlen', 'Zum Fertigstellen', 0, 190);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, source, notes) VALUES (6, 'veganer-apfel-crisp', 'Veganer Apfel-Crisp', 10, 'Portionen', 30, 35, 'Nisha Vora – Rainbow Plant Life – https://rainbowplantlife.com/vegan-apple-crisp/', 'Deutsche, gekürzte Übertragung der Original-Rezeptkarte. Abgerufen am 16.11.2026. Die Quellkarte nennt 35 Minuten Backzeit; im Schritt steht 35–40 Minuten. Zusätzlich 20–45 Minuten Ruhezeit einplanen. Die 1,3 kg Äpfel stammen aus der metrischen Quellangabe und sind das Einkaufsgewicht. Nach Schälen und Entkernen bleiben laut Quelle etwa 1 kg. Säuerliche und süße Äpfel mischen. Gehäufte 0,75 TL Salz bleiben mit entsprechendem Mengentext erfasst. Statt frisch geriebener Muskatnuss erlaubt die Quelle 0,25 TL vorgemahlene Muskatnuss; statt Pekannüssen Walnüsse. Öl/Butter für die Form stammt aus dem Zubereitungsschritt und hat keine feste Quellmenge.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (6, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (6, 2);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (6, 7);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (60, 'Äpfel', 1, 2, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (82, 6, 60, 1.3, 2, '1,3 kg Äpfel, vor dem Schälen gewogen', 'geschält, entkernt und geschnitten', 'Apfelfüllung', 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (61, 'Zitronensaft', 1, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (83, 6, 61, 1.5, 5, '1,5 EL Zitronensaft', NULL, 'Apfelfüllung', 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (62, 'Ahornsirup', 7, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (84, 6, 62, 80.0, 1, '80 g Ahornsirup', NULL, 'Apfelfüllung', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (63, 'Vanilleextrakt', 6, 6, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (85, 6, 63, 1.5, 6, '1,5 TL Vanilleextrakt', NULL, 'Apfelfüllung', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (64, 'Zimt', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (86, 6, 64, 1.5, 6, '1,5 TL Zimt, gemahlen', 'gemahlen', 'Apfelfüllung', 0, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (65, 'Muskatnuss', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (87, 6, 65, 0.5, 6, '0,5 TL Muskatnuss, frisch gerieben', 'frisch gerieben', 'Apfelfüllung', 0, 60);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (66, 'Ingwer gemahlen', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (88, 6, 66, 0.5, 6, '0,5 TL Ingwer, gemahlen', NULL, 'Apfelfüllung', 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (67, 'Nelken gemahlen', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (89, 6, 67, 0.25, 6, '0,25 TL Nelken, gemahlen', NULL, 'Apfelfüllung', 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (68, 'Kardamom', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (90, 6, 68, 0.125, 6, '0,125 TL Kardamom, gemahlen, optional', 'gemahlen', 'Apfelfüllung', 1, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (91, 6, 56, 2.0, 5, '2 EL Weizenmehl', NULL, 'Apfelfüllung', 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (92, 6, 5, 1.0, 8, '1 Prise Meersalz', NULL, 'Apfelfüllung', 0, 110);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (69, 'Vegane Butter', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (93, 6, 69, 112.0, 1, '112 g vegane Butter, in dicken Scheiben', 'in dicken Scheiben', 'Streusel', 0, 120);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (70, 'Pekannüsse', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (94, 6, 70, 60.0, 1, '60 g Pekannüsse, gehackt', 'gehackt', 'Streusel', 0, 130);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (95, 6, 56, 110.0, 1, '110 g Weizenmehl', NULL, 'Streusel', 0, 140);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (71, 'Haferflocken', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (96, 6, 71, 100.0, 1, '100 g kernige Haferflocken', NULL, 'Streusel', 0, 150);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (97, 6, 5, 0.75, 6, '0,75 TL Meersalz, gehäuft', NULL, 'Streusel', 0, 160);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (72, 'Rohrzucker', 5, 1, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (98, 6, 72, 80.0, 1, '80 g Rohrzucker', NULL, 'Streusel', 0, 170);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (99, 6, 62, 80.0, 1, '80 g Ahornsirup', NULL, 'Streusel', 0, 180);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (73, 'Leinsamen geschrotet', 5, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (100, 6, 73, 1.0, 5, '1 EL geschrotete Leinsamen', NULL, 'Streusel', 0, 190);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (101, 6, 64, 0.5, 6, '0,5 TL Zimt, gemahlen', 'gemahlen', 'Streusel', 0, 200);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (74, 'Öl oder vegane Butter', 5, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (102, 6, 74, NULL, NULL, 'Öl oder vegane Butter zum Einfetten, nach Bedarf', NULL, 'Für die Form', 0, 210);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (75, 'Veganes Vanilleeis oder Schlagcreme', 8, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, optional, sort_order) VALUES (103, 6, 75, NULL, NULL, 'Veganes Vanilleeis oder pflanzliche Schlagcreme nach Bedarf', NULL, 'Zum Servieren', 0, 220);
