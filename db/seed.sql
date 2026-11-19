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

-- NDR: einzeln geprüfte Fitness-Auswahl, 19.11.2026; keine Vollarchiv-Übernahme.
INSERT INTO units (id, code, name, dimension, base_unit_code, factor_to_base) VALUES (13, 'Handvoll', 'Handvoll', 'qualitative', NULL, NULL);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (76, 'Beluga-Linsen', 5, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (77, 'Kichererbsen abgetropft', 7, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (78, 'Möhre', 1, 9, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (79, 'Paprika', 1, 9, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (80, 'Gurke', 1, 9, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (81, 'Rucola', 1, 13, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (82, 'Feta', 2, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (83, 'Leinöl', 5, 5, 1);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (84, 'Haselnussmus', 7, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (85, 'Sojaschnetzel', 5, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (86, 'Bratöl', 5, 5, 1);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (87, 'Kräuter der Provence', 6, 6, 1);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (88, 'Kidneybohnen mit Bohnenwasser', 7, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (89, 'Lorbeerblätter', 6, 9, 1);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (90, 'Chilipulver', 6, NULL, 1);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (91, 'Quinoa', 5, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (92, 'Hähnchenbrust', 3, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (93, 'Zucchini', 1, 9, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (94, 'Karotte', 1, 9, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (95, 'TK-Erbsen', 8, 1, 0);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (96, 'Petersilie frisch', 1, NULL, 0);
INSERT INTO tags (id, name) VALUES (9, 'NDR');
INSERT INTO tags (id, name) VALUES (10, 'Fitness-Auswahl');
INSERT INTO tags (id, name) VALUES (11, 'Vegetarisch');
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (7, 'protein-bowl-mit-linsen-und-kichererbsen', 'Protein-Bowl mit Linsen und Kichererbsen', 2, 'Portionen', NULL, NULL, 30, 'Team Ernährungs-Docs – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/gesunde-protein-bowl-mit-linsen-und-kichererbsen,proteinbowl-102.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Originalmengen und bestätigte zwei Portionen, geprüft am 19.11.2026. Die Quelle nennt 30 Minuten Gesamtzeit, keine getrennte Vorbereitungs- oder Garzeit. Rucola ist die Basis; Blattspinat ist eine Alternative und wird nicht zusätzlich eingekauft. Kichererbsen sind mit Abtropfgewicht erfasst. Leinöl nicht erhitzen. Stück und Handvoll bleiben ohne erfundene Grammgewichte. NDR-Schätzwerte je Portion: ca. 590 kcal, 28 g Protein, 45 g Kohlenhydrate, 32 g Fett und 18 g Ballaststoffe. Separat von der unvollständigen BLS-Zutatenbilanz betrachten.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (7, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (7, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (7, 10);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (7, 11);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (104, 7, 76, 100, 1, '100 g Beluga-Linsen', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (105, 7, 77, 150, 1, '150 g Kichererbsen, Abtropfgewicht aus Dose oder Glas', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (106, 7, 31, 1, 6, '1 TL Olivenöl', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (107, 7, 18, NULL, NULL, 'Gemahlener Kreuzkümmel nach Bedarf', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (108, 7, 78, 1, 9, '1 große Möhre', NULL, 'Hauptzutaten', 'groß', 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (109, 7, 79, 1, 9, '1 gelbe Paprika', NULL, 'Hauptzutaten', 'gelb', 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (110, 7, 80, 0.5, 9, '0,5 Gurke', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (111, 7, 81, 2, 13, '2 Handvoll Rucola', NULL, 'Hauptzutaten', NULL, 0, 80);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (112, 7, 82, 80, 1, '80 g Feta', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (113, 7, 83, 2, 5, '2 EL Leinöl', NULL, 'Hauptzutaten', NULL, 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (114, 7, 61, 2, 5, '2 EL Zitronensaft', NULL, 'Hauptzutaten', NULL, 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (115, 7, 84, 20, 1, '20 g Haselnussmus', NULL, 'Hauptzutaten', NULL, 0, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (116, 7, 65, 1, 8, '1 Prise Muskatnuss', NULL, 'Hauptzutaten', NULL, 0, 130);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (117, 7, 64, 0.5, 6, '0,5 TL Zimt', NULL, 'Hauptzutaten', NULL, 0, 140);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (118, 7, 5, NULL, NULL, 'Salz nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 150);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (119, 7, 23, NULL, NULL, 'Pfeffer nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 160);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (8, 'chili-sin-carne-mit-sojageschnetzeltem', 'Chili sin Carne mit Sojageschnetzeltem', 4, 'Portionen', NULL, NULL, 40, 'ndr.de – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Chili-sin-Carne-mit-Sojageschnetzeltem,chilisincarne112.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; vier Portionen laut Rezeptkarte, geprüft am 19.11.2026. Als Urheber nennt die Karte ndr.de, keine persönliche Byline. Die Quelle nennt 40 Minuten Gesamtzeit, keine getrennte Vorbereitungs- oder Garzeit. Die 300 g Sojaschnetzel werden vor dem Einweichen gewogen. Kidneybohnen ausdrücklich mit Bohnenwasser verwenden; kein Abtropfgewicht unterstellen. Italienische Kräuter können Kräuter der Provence ersetzen; scharfes Paprikapulver ist eine Alternative zum optionalen Chilipulver. Alternativen nicht zusätzlich einkaufen. NDR-Schätzwerte je Portion: ca. 484 kcal, 46 g Protein, 35 g Kohlenhydrate, 15 g Fett und 23 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (8, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (8, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (8, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (8, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (120, 8, 85, 300, 1, '300 g feine Sojaschnetzel', NULL, 'Hauptzutaten', 'fein', 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (121, 8, 25, 1, 4, '1 l Gemüsebrühe', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (122, 8, 32, 2, 9, '2 Zwiebeln', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (123, 8, 14, 2, 9, '2 Knoblauchzehen', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (124, 8, 79, 1, 9, '1 rote Paprika', NULL, 'Hauptzutaten', 'rot', 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (125, 8, 79, 1, 9, '1 gelbe Paprika', NULL, 'Hauptzutaten', 'gelb', 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (126, 8, 79, 1, 9, '1 grüne Paprika', NULL, 'Hauptzutaten', 'grün', 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (127, 8, 86, 3, 5, '3 EL Bratöl', NULL, 'Hauptzutaten', NULL, 0, 80);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (128, 8, 87, 1, 6, '1 TL Kräuter der Provence', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (129, 8, 45, 0.5, 6, '0,5 TL geräuchertes Paprikapulver', NULL, 'Hauptzutaten', 'geräuchert', 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (130, 8, 39, 1, 5, '1 EL dunkler Balsamico-Essig', NULL, 'Hauptzutaten', 'dunkel', 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (131, 8, 26, 400, 1, '400 g stückige Tomaten aus der Dose', NULL, 'Hauptzutaten', NULL, 0, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (132, 8, 88, 400, 1, '400 g Kidneybohnen aus der Dose, nicht abgetropft', NULL, 'Hauptzutaten', NULL, 0, 130);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (133, 8, 45, 1, 6, '1 TL edelsüßes Paprikapulver', NULL, 'Hauptzutaten', 'edelsüß', 0, 140);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (134, 8, 89, 2, 9, '2 Lorbeerblätter', NULL, 'Hauptzutaten', NULL, 0, 150);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (135, 8, 5, NULL, NULL, 'Salz nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 160);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (136, 8, 23, NULL, NULL, 'Pfeffer nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 170);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (137, 8, 90, NULL, NULL, 'Chilipulver nach Belieben', NULL, 'Hauptzutaten', NULL, 1, 180);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (9, 'bunte-quinoa-pfanne-mit-haehnchen', 'Bunte Quinoa-Pfanne mit Hähnchen', 2, 'Portionen', NULL, NULL, 40, 'Team Ernährungs-Docs – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/bunte-quinoa-pfanne-mit-haehnchen-gemuese,quinoapfanne-100.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; zwei Portionen, geprüft am 19.11.2026. Kanonische Rezept-URL verwendet. Die Quelle nennt 40 Minuten Gesamtzeit einschließlich Marinieren, keine getrennte Vorbereitungs- oder Garzeit. Quinoa und Hähnchen sind vor dem Garen gewogen. Gemüse in Stück bleibt ohne pauschale Grammumrechnung; Zitronensaft ist optional. Laut Quelle kann eine TK-Gemüsemischung die frischen Gemüse ersetzen. Die Basisliste bleibt bei den einzeln genannten Zutaten. NDR-Schätzwerte je Portion: ca. 582 kcal, 42 g Protein, 47 g Kohlenhydrate, 24 g Fett und 11 g Ballaststoffe. Separat von der unvollständigen BLS-Zutatenbilanz betrachten.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (9, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (9, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (9, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (138, 9, 91, 100, 1, '100 g bunte Quinoa (Tricolore)', NULL, 'Hauptzutaten', 'Tricolore', 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (139, 9, 92, 200, 1, '200 g Hähnchenbrust', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (140, 9, 5, 0.25, 6, '0,25 TL Salz', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (141, 9, 23, 0.25, 6, '0,25 TL Pfeffer', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (142, 9, 45, 1, 6, '1 TL Paprikapulver', NULL, 'Hauptzutaten', NULL, 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (143, 9, 42, 0.25, 6, '0,25 TL Knoblauchpulver', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (144, 9, 31, 2, 5, '2 EL Olivenöl', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (145, 9, 79, 1, 9, '1 rote Paprika', NULL, 'Hauptzutaten', 'rot', 0, 80);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (146, 9, 93, 1, 9, '1 Zucchini', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (147, 9, 94, 1, 9, '1 Karotte', NULL, 'Hauptzutaten', NULL, 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (148, 9, 95, 75, 1, '75 g TK-Erbsen', NULL, 'Hauptzutaten', NULL, 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (149, 9, 61, NULL, NULL, 'Zitronensaft nach Belieben', NULL, 'Hauptzutaten', NULL, 1, 120);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (150, 9, 82, 80, 1, '80 g Feta', NULL, 'Hauptzutaten', NULL, 0, 130);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (151, 9, 96, NULL, NULL, 'Frische Petersilie, gehackt', NULL, 'Hauptzutaten', NULL, 0, 140);

-- Weitere einzeln geprüfte NDR-Fitness-Rezepte, 19.11.2026.
INSERT INTO units (id, code, name, dimension, base_unit_code, factor_to_base) VALUES (14, 'Scheibe', 'Scheibe', 'qualitative', NULL, NULL);
INSERT INTO units (id, code, name, dimension, base_unit_code, factor_to_base) VALUES (15, 'Schuss', 'Schuss', 'qualitative', NULL, NULL);
INSERT INTO units (id, code, name, dimension, base_unit_code, factor_to_base) VALUES (16, 'Spritzer', 'Spritzer', 'qualitative', NULL, NULL);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (10, 'blumenkohl-curry-mit-tofu', 'Blumenkohl-Curry mit Tofu', 4, 'Portionen', NULL, NULL, 30, 'ndr.de – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Blumenkohl-Curry-mit-Tofu,rezept5548.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Mengen und Portionen am 19.11.2026 geprüft. Nur Gesamtzeit veröffentlicht; getrennte Vorbereitungs- und Garzeiten bleiben unbekannt. Die veröffentlichte Gesamtzeit beträgt 30 Minuten; die Quelle nennt zugleich 3 Minuten Anrösten und 25 Minuten Köcheln. Zusätzliche Vorbereitung kann mehr Zeit beanspruchen. Die Kurkuma-Zeile nennt keine Form. In dieser gekürzten Fassung wird gemahlener Kurkuma verwendet; die Nährwertbilanz bleibt als Schätzung gekennzeichnet. NDR-Schätzung je Portion: ca. 360 kcal, 26 g Protein, 20 g Kohlenhydrate, 17 g Fett und 12 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (10, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (10, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (10, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (10, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (97, 'Blumenkohl', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (152, 10, 97, 750, 1, '750 g Blumenkohl', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (153, 10, 32, 1, 9, '1 Zwiebel', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (154, 10, 14, 2, 9, '2 Knoblauchzehen', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (98, 'Rote Chilischoten', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (155, 10, 98, 2, 9, '2 kleine rote Chilischoten', NULL, 'Hauptzutaten', 'klein', 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (99, 'Rapsöl', 5, 5, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (156, 10, 99, 2, 5, '2 EL Rapsöl', NULL, 'Hauptzutaten', NULL, 0, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (100, 'Meersalz', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (157, 10, 100, 1, 6, '1 TL Meersalz', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (158, 10, 21, 2, 5, '2 EL Currypulver', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (159, 10, 46, 1, 6, '1 TL Kurkuma', NULL, 'Hauptzutaten', NULL, 0, 80);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (160, 10, 25, 500, 3, '500 ml Gemüsebrühe', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (101, 'Zuckerschoten', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (161, 10, 101, 250, 1, '250 g Zuckerschoten', NULL, 'Hauptzutaten', NULL, 0, 100);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (102, 'Tofu natur', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (162, 10, 102, 400, 1, '400 g Tofu natur', NULL, 'Hauptzutaten', NULL, 0, 110);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (163, 10, 61, 2, 5, '2 EL Zitronensaft', NULL, 'Hauptzutaten', NULL, 0, 120);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (103, 'Kokosflocken', 6, 5, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (164, 10, 103, 1, 5, '1 EL Kokosflocken', NULL, 'Hauptzutaten', NULL, 0, 130);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (11, 'gemuesepfanne-mit-tofu', 'Gemüsepfanne mit Tofu', 1, 'Portionen', NULL, NULL, 15, 'ndr.de – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Gemuesepfanne-mit-Tofu,rezept3014.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Mengen und Portionen am 19.11.2026 geprüft. Nur Gesamtzeit veröffentlicht; getrennte Vorbereitungs- und Garzeiten bleiben unbekannt. Die Quelle erlaubt gekochte Hülsenfrüchte statt Basilikum-Tofu, nennt dafür aber keine eigene Menge oder Nährwertberechnung. Die Basis bleibt Basilikum-Tofu. Sojasoße ist laut Zubereitung nach Belieben und wird deshalb optional geführt. Keine pauschale Milliliterzahl für einen Schuss. NDR-Schätzung je Portion: ca. 296 kcal, 26 g Protein, 15 g Kohlenhydrate, 14 g Fett und 7 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (11, 5);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (11, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (11, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (11, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (165, 11, 94, 1, 9, '1 Karotte', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (166, 11, 93, 0.5, 9, '0,5 Zucchini', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (104, 'Spitzpaprika', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (167, 11, 104, 1, 9, '1 kleine Spitzpaprika', NULL, 'Hauptzutaten', 'klein', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (105, 'Lauchzwiebel', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (168, 11, 105, 1, 9, '1 Lauchzwiebel', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (106, 'Basilikum-Tofu', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (169, 11, 106, 150, 1, '150 g Basilikum-Tofu', NULL, 'Hauptzutaten', NULL, 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (170, 11, 31, 1, 6, '1 TL Olivenöl', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (171, 11, 5, 1, 8, '1 Prise Salz', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (107, 'Sojasoße', 7, 15, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (172, 11, 107, 1, 15, '1 Schuss Sojasoße nach Belieben', NULL, 'Hauptzutaten', NULL, 1, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (108, 'Italienische Kräuter getrocknet', 6, 6, 1);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (173, 11, 108, 1, 6, '1 TL getrocknete italienische Kräuter', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (12, 'lachs-paeckchen-mit-gemuese-und-feta', 'Lachs-Päckchen mit Gemüse und Feta', 2, 'Portionen', NULL, NULL, 30, 'ndr.de – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Lachs-Paeckchen-mit-Gemuese-und-Feta,rezept2548.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Mengen und Portionen am 19.11.2026 geprüft. Nur Gesamtzeit veröffentlicht; getrennte Vorbereitungs- und Garzeiten bleiben unbekannt. Die Quelle nennt Schafskäse in der Zutatenliste und Feta im Titel. Shrimps oder mehr Lachs sind Alternativen zu Krabben; sie werden nicht zusätzlich eingekauft. Pergamentpapier und Küchengarn bereitlegen. Die Quelle nennt 180 °C ohne Angabe der Heizart. Mengen von Bund, Stück und Spritzer werden nicht in Gramm umgerechnet. NDR-Schätzung je Portion: ca. 473 kcal, 42 g Protein, 13 g Kohlenhydrate, 28 g Fett und 6 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (12, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (12, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (12, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (109, 'Frühlingszwiebeln', 1, 11, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (174, 12, 109, 1, 11, '1 Bund Frühlingszwiebeln', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (175, 12, 79, 1, 9, '1 rote Paprika', NULL, 'Hauptzutaten', 'rot', 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (110, 'Zucchino', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (176, 12, 110, 0.5, 9, '0,5 Zucchino', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (111, 'Champignons', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (177, 12, 111, 200, 1, '200 g Champignons', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (112, 'Lachsfilet', 4, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (178, 12, 112, 150, 1, '150 g Lachsfilet', NULL, 'Hauptzutaten', NULL, 0, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (113, 'Krabben', 4, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (179, 12, 113, 100, 1, '100 g Krabben', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (114, 'Schafskäse', 2, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (180, 12, 114, 150, 1, '150 g Schafskäse', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (181, 12, 23, NULL, NULL, 'Pfeffer aus der Mühle nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 80);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (182, 12, 5, NULL, NULL, 'Salz nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (115, 'Kräuter', 1, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (183, 12, 115, NULL, NULL, 'Kräuter nach Belieben', NULL, 'Hauptzutaten', NULL, 1, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (184, 12, 61, 1, 16, '1 Spritzer Zitronensaft', NULL, 'Hauptzutaten', NULL, 0, 110);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (13, 'strammer-max-vegetarisch', 'Strammer Max vegetarisch', 1, 'Portionen', NULL, NULL, 15, 'ndr.de – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Strammer-Max-vegetarisch,strammermax132.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Mengen und Portionen am 19.11.2026 geprüft. Nur Gesamtzeit veröffentlicht; getrennte Vorbereitungs- und Garzeiten bleiben unbekannt. Die NDR-Nährwerte gelten ausdrücklich ohne Salat. Die erwähnte Salat- oder Rohkostbeilage ist keine zusätzliche berechnete Zutat und muss bei Bedarf separat geplant werden. Vollkornbrot ist eine Alternative zu Eiweißbrot, keine zusätzliche Scheibe. Die veröffentlichte Schätzung gehört zur Basis; Brot- und Tofuprodukt können abweichen. NDR-Schätzung je Portion: ca. 410 kcal, 32 g Protein, 13 g Kohlenhydrate, 26 g Fett und 6 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (13, 6);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (13, 8);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (13, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (13, 10);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (13, 11);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (116, 'Räuchertofu', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (185, 13, 116, 80, 1, '80 g geräucherter Tofu', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (186, 13, 86, 1, 6, '1 TL Bratöl', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (117, 'Eiweißbrot', 5, 14, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (187, 13, 117, 1, 14, '1 große Scheibe Eiweißbrot', NULL, 'Hauptzutaten', 'groß', 0, 30);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (118, 'Tomate', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (188, 13, 118, 1, 9, '1 Tomate', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (189, 13, 1, 2, 9, '2 Eier, Größe S', NULL, 'Hauptzutaten', 'Gr. S', 0, 50);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (190, 13, 5, NULL, NULL, 'Salz nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (191, 13, 23, NULL, NULL, 'Pfeffer nach Geschmack', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO recipes (id, slug, title, servings, servings_label, prep_minutes, cook_minutes, total_minutes, source, notes) VALUES (14, 'quarkfruehstueck-doc-klasen', 'Quarkfrühstück mit Gemüse und Obst ("Doc-Klasen-Spezial")', 1, 'Portionen', NULL, NULL, 10, 'Jörn Klasen – NDR – https://www.ndr.de/ratgeber/kochen/rezepte/Quarkfruehstueck-mit-Gemuese-und-Obst-Doc-Klasen-Fruehstueck,fruehstueck2230.html', 'Einzeln ausgewählte, gekürzte und neu formulierte NDR-Fassung; Mengen und Portionen am 19.11.2026 geprüft. Nur Gesamtzeit veröffentlicht; getrennte Vorbereitungs- und Garzeiten bleiben unbekannt. Nüsse bleiben eine nicht näher festgelegte Mischung. Die Quellbeispiele für Nusssorten werden nicht zu zusätzlichen Zutaten. EL-Mengen von Skyr, Quark, Früchten und Kernen erhalten keine erfundenen Grammwerte. Art und Menge eines optionalen Haferdrinks verändern die Bilanz. NDR-Schätzung je Portion: ca. 653 kcal, 33 g Protein, 62 g Kohlenhydrate, 31 g Fett und 17 g Ballaststoffe. Nicht mit BLS-Teilsummen vermischen.');
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (14, 8);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (14, 9);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (14, 10);
INSERT INTO recipe_tags (recipe_id, tag_id) VALUES (14, 11);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (119, 'Skyr', 2, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (192, 14, 119, 3, 5, '3 EL Skyr', NULL, 'Hauptzutaten', NULL, 0, 10);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (120, 'Magerquark', 2, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (193, 14, 120, 1, 5, '1 EL Magerquark', NULL, 'Hauptzutaten', NULL, 0, 20);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (194, 14, 83, 1, 5, '1 EL Leinöl', NULL, 'Hauptzutaten', NULL, 0, 30);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (195, 14, 71, 40, 1, '40 g Haferflocken', NULL, 'Hauptzutaten', NULL, 0, 40);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (121, 'Haferdrink', 9, NULL, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (196, 14, 121, NULL, NULL, 'Haferdrink nach Belieben', NULL, 'Hauptzutaten', NULL, 1, 50);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (122, 'Kohlrabi', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (197, 14, 122, 30, 1, '30 g Kohlrabi', NULL, 'Hauptzutaten', NULL, 0, 60);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (123, 'Pastinake', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (198, 14, 123, 30, 1, '30 g Pastinake', NULL, 'Hauptzutaten', NULL, 0, 70);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (124, 'Rote Bete', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (199, 14, 124, 30, 1, '30 g Rote Bete', NULL, 'Hauptzutaten', NULL, 0, 80);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (125, 'Fenchel', 1, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (200, 14, 125, 30, 1, '30 g Fenchel', NULL, 'Hauptzutaten', NULL, 0, 90);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (201, 14, 78, 0.5, 9, '0,5 Möhre', NULL, 'Hauptzutaten', NULL, 0, 100);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (202, 14, 79, 0.25, 9, '0,25 Paprika', NULL, 'Hauptzutaten', NULL, 0, 110);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (126, 'Apfel', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (203, 14, 126, 0.25, 9, '0,25 Apfel', NULL, 'Hauptzutaten', NULL, 0, 120);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (127, 'Birne', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (204, 14, 127, 0.25, 9, '0,25 Birne', NULL, 'Hauptzutaten', NULL, 0, 130);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (128, 'Pflaume', 1, 9, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (205, 14, 128, 0.5, 9, '0,5 Pflaume', NULL, 'Hauptzutaten', NULL, 0, 140);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (129, 'Heidelbeeren', 1, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (206, 14, 129, 1, 5, '1 EL Heidelbeeren', NULL, 'Hauptzutaten', NULL, 0, 150);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (130, 'Granatapfelkerne', 1, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (207, 14, 130, 1, 5, '1 EL Granatapfelkerne', NULL, 'Hauptzutaten', NULL, 0, 160);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (131, 'Kürbiskerne', 5, 5, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (208, 14, 131, 1, 5, '1 EL Kürbiskerne', NULL, 'Hauptzutaten', NULL, 0, 170);
INSERT INTO ingredients (id, name, category_id, default_unit_id, pantry_staple) VALUES (132, 'Nüsse', 5, 1, 0);
INSERT INTO recipe_ingredients (id, recipe_id, ingredient_id, quantity, unit_id, amount_text, preparation, ingredient_group, variant, optional, sort_order) VALUES (209, 14, 132, 25, 1, '25 g Nüsse', NULL, 'Hauptzutaten', NULL, 0, 180);
