"""Offline-Prüfungen: python3 -m unittest discover -s scripts -v"""

import json
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch

import scrape_recipes as scrape
import lint_recipes
import run_lint
import subprocess

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "db"))
import build_db


class ExtractionTests(unittest.TestCase):
    def extract(self, node, source="rainbowplantlife", extra=""):
        base, publisher = scrape.SOURCES[source]
        page = '<link rel="canonical" href="' + base + 'test/">'
        page += '<script type="application/ld+json">' + json.dumps(node) + '</script>' + extra
        with patch.object(scrape, "BASE", base), patch.object(scrape, "PUBLISHER", publisher):
            return scrape.extract(page, base + "test/")

    def test_resolves_original_author_and_keeps_multiple_cards(self):
        card = {"@type": "Recipe", "@id": "#one", "name": "One", "author": {"@id": "#author"},
                "recipeIngredient": ["1 cup beans"],
                "recipeInstructions": [{"@type": "HowToSection", "name": "Sauce", "itemListElement": [
                    {"@type": "HowToStep", "text": "<b>Mix</b> &amp; cook."}]}]}
        result = self.extract({"@graph": [{"@id": "#author", "name": "Nisha Vora"}, card, {**card, "@id": "#two", "name": "Two"}]})
        self.assertEqual(len(result["recipes"]), 2)
        self.assertEqual(result["recipes"][0]["authors"], ["Nisha Vora"])
        self.assertEqual(result["recipes"][0]["instructions"], ["Mix & cook."])

    def test_webflow_recipe_uses_visible_ingredients_and_directions(self):
        node = {"@type": "Recipe", "name": "Test", "author": {"name": "Joshua Weissman"}}
        extra = '<div class="ingredients-list"><p>Sauce:</p><ul><li>1 tsp <a>salt</a></li></ul></div>'
        extra += '<div class="directions-list"><p><strong>Sauce:</strong></p><ol><li>Mix <b>well</b>.</li></ol></div>'
        result = self.extract(node, "joshuaweissman", extra)["recipes"][0]
        self.assertEqual(result["ingredients"], ["1 tsp salt"])
        self.assertEqual(result["instructions"], ["Mix well."])
        self.assertEqual(result["instruction_sections"][0]["text"], "Sauce:")

    def test_missing_source_author_is_explicit_and_not_invented(self):
        result = self.extract({"@type": "Recipe", "name": "Unknown", "recipeIngredient": ["salt"],
                               "recipeInstructions": [{"@type": "HowToStep", "text": "Mix"}]})["recipes"][0]
        self.assertEqual(result["authors"], [])
        self.assertEqual(result["missing_fields"], ["authors"])

    def test_external_canonical_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Originalquelle"):
            scrape.extract('<link rel="canonical" href="https://unrelated.example/">', scrape.BASE)

    def test_article_without_recipe_is_not_imported(self):
        self.assertEqual(self.extract({"@type": "Article", "name": "Not a recipe"})["recipes"], [])

    def test_webflow_unescaped_newline_in_json(self):
        page = '<script type="application/ld+json">{"@type":"Article","name":"a\nb"}</script>'
        self.assertEqual(scrape.extract(page, scrape.BASE)["recipes"], [])

    def test_webflow_nested_paragraphs_do_not_drop_ingredients(self):
        node = {"@type": "Recipe", "name": "Test", "author": {"name": "Joshua Weissman"}}
        extra = '<div class="ingredients-list"><ul><li><p>1 tsp salt</p></li></ul></div>'
        extra += '<div class="directions-list"><ol><li><p>Mix.</p></li></ol></div>'
        result = self.extract(node, "joshuaweissman", extra)["recipes"][0]
        self.assertEqual(result["ingredients"], ["1 tsp salt"])
        self.assertEqual(result["instructions"], ["Mix."])

    def test_babish_guide_without_directions_stays_explicitly_incomplete(self):
        node = {"@type": "Recipe", "name": "Bar Essentials", "author": {"name": "bingingwithbabish"},
                "recipeIngredient": ["Gin"], "recipeInstructions": []}
        result = self.extract(node, "babish")["recipes"][0]
        self.assertEqual(result["missing_fields"], ["instructions"])
        self.assertEqual(result["instructions"], [])

    def test_webflow_unescaped_quotes_recover_only_source_fields(self):
        page = '<script type="application/ld+json">{"@type":"Recipe", "name":"The "Best" Soup", "description":"x", "author":{"name":"Joshua Weissman"}}</script>'
        page += '<div class="ingredients-list"><ul><li>Salt</li></ul></div><div class="directions-list"><ol><li>Cook.</li></ol></div>'
        with patch.object(scrape, "BASE", scrape.SOURCES["joshuaweissman"][0]), patch.object(scrape, "PUBLISHER", "Joshua Weissman"):
            result = scrape.extract(page, scrape.BASE + 'recipes/test')
        self.assertEqual(result["recipes"][0]["name"], 'The "Best" Soup')
        self.assertEqual(result["recipes"][0]["authors"], ["Joshua Weissman"])
        self.assertEqual(len(result["extraction_warnings"]), 1)


class RecipeLintTests(unittest.TestCase):
    def setUp(self):
        self.text = (lint_recipes.ROOT / "rezepte" / "rotes-linsen-curry.md").read_text()

    def test_verified_recipe_passes(self):
        self.assertEqual(lint_recipes.lint_text(self.text, "rotes-linsen-curry"), [])

    def test_source_without_visible_matching_link_fails(self):
        text = self.text.replace(
            "[Nisha Vora – Rainbow Plant Life](https://rainbowplantlife.com/vegan-red-lentil-curry/)", "Nisha Vora")
        self.assertTrue(any("sichtbaren Link" in error for error in lint_recipes.lint_text(text, "rotes-linsen-curry")))

    def test_imperial_quantity_and_missing_group_fail(self):
        text = self.text.replace("### Curry\n", "").replace("480 ml Gemüsebrühe", "2 cups Gemüsebrühe")
        errors = lint_recipes.lint_text(text, "rotes-linsen-curry")
        self.assertTrue(any("###-Gruppe" in error for error in errors))
        self.assertTrue(any("Nicht metrische" in error for error in errors))

    def test_homepage_cannot_replace_original_recipe(self):
        text = self.text.replace("https://rainbowplantlife.com/vegan-red-lentil-curry/", "https://rainbowplantlife.com/")
        self.assertTrue(any("Startseiten" in error for error in lint_recipes.lint_text(text, "rotes-linsen-curry")))

    def test_parallel_runner_keeps_failure_when_other_checks_pass(self):
        def result(name, command):
            return name, subprocess.CompletedProcess(command, 1 if name == "bad" else 0, "", "")
        with patch.dict(run_lint.CHECKS, {"good": ["test"], "bad": ["test"]}, clear=True), patch.object(run_lint, "run", side_effect=result):
            with self.assertRaises(SystemExit) as caught:
                run_lint.main()
        self.assertEqual(caught.exception.code, 1)


class RecipeDatabaseTests(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.conn.executescript(build_db.SCHEMA.read_text())
        self.conn.executescript(build_db.SEED.read_text())

    def tearDown(self):
        self.conn.close()

    def test_all_recipe_files_match_database(self):
        build_db.check_recipe_files(self.conn)

    def test_incorrect_source_in_database_is_rejected(self):
        self.conn.execute("UPDATE recipes SET source = 'Wrong source' WHERE slug = 'rotes-linsen-curry'")
        with self.assertRaisesRegex(SystemExit, "source weicht"):
            build_db.check_recipe_files(self.conn)

    def test_missing_visible_source_link_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            for path in (build_db.ROOT.parent / "rezepte").glob("*.md"):
                text = path.read_text().replace(
                    "[Nisha Vora – Rainbow Plant Life](https://rainbowplantlife.com/vegan-red-lentil-curry/)", "Nisha Vora")
                (Path(folder) / path.name).write_text(text)
            with self.assertRaisesRegex(SystemExit, "sichtbarer Link"):
                build_db.check_recipe_files(self.conn, Path(folder))

    def test_imported_quantities_scale_and_duplicate_ingredients_sum(self):
        self.conn.execute("INSERT INTO meal_plan_entries VALUES (2, 1, '2026-11-18', 'Abendessen', 2, 8, NULL)")
        rows = build_db.fetch(self.conn, "2026-11-18", "2026-11-18", False)
        by_name = {r["zutat"]: r for r in rows}
        self.assertEqual(by_name["Rote Linsen"]["menge"], 380)
        self.assertEqual(by_name["Kokosmilch"]["menge"], 800)
        self.assertIsNone(by_name["Ingwer"]["menge"])
        self.conn.execute("INSERT INTO meal_plan_entries VALUES (3, 1, '2026-11-19', 'Nachspeise', 6, 10, NULL)")
        rows = build_db.fetch(self.conn, "2026-11-19", "2026-11-19", False)
        self.assertEqual(next(r for r in rows if r["zutat"] == "Ahornsirup")["menge"], 160)


if __name__ == "__main__":
    unittest.main()
