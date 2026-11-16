"""Neue Quellformate, Zugriffsausschlüsse und Wiederaufnahme offline prüfen."""

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import check_sources
import scrape_recipes as scrape


class AdditionalExtractionTests(unittest.TestCase):
    def extract(self, source, node=None, extra=""):
        base, publisher = scrape.SOURCES[source]
        page = '<script type="application/ld+json">' + json.dumps(node or {}) + '</script>' + extra
        with patch.object(scrape, "BASE", base), patch.object(scrape, "PUBLISHER", publisher):
            return scrape.extract(page, base + "recipe/test")

    def test_pick_up_limes_nested_text_steps_and_notes(self):
        node = {"@type": "Recipe", "name": "Soup", "author": {"name": "Pick Up Limes"},
                "recipeIngredient": ["1&#189; cup beans"], "recipeInstructions": [["Mix.", "Cook."]]}
        result = self.extract("pickuplimes", node, '<div class="rp-callout"><h3>Notes</h3><p>Let cool.</p></div>')
        self.assertEqual(result["recipes"][0]["instructions"], ["Mix.", "Cook."])
        self.assertEqual(result["recipes"][0]["ingredients"], ["1½ cup beans"])
        self.assertIn("Let cool.", result["page_recipe_notes"][0])

    def test_cookwell_member_card_is_skipped_even_if_data_is_present(self):
        node = {"@type": "Recipe", "name": "Members only", "isAccessibleForFree": False,
                "author": {"name": "Cook Well Official"}, "recipeIngredient": ["secret"], "recipeInstructions": ["secret"]}
        result = self.extract("cookwell", node)
        self.assertEqual(result["recipes"], [])
        self.assertEqual(result["restricted_card_count"], 1)

    def test_mixed_page_keeps_only_the_public_card(self):
        node = [{"@type": "Recipe", "name": "Private", "isAccessibleForFree": "false"},
                {"@type": "Recipe", "name": "Public", "isAccessibleForFree": True,
                 "author": {"name": "Ethan Chlebowski"}, "recipeIngredient": ["Salt"], "recipeInstructions": ["Mix."]}]
        result = self.extract("cookwell", node)
        self.assertEqual([r["name"] for r in result["recipes"]], ["Public"])

    def test_maangchi_visible_card_repairs_partial_schema(self):
        node = {"@type": "Recipe", "name": "Kimchi", "author": {"name": "Maangchi"},
                "recipeIngredient": ["Salt"], "recipeInstructions": [{"@type": "HowToStep", "position": 1}]}
        extra = '<div class="recipe-card-ingredients"><ul><li>Cabbage</li><li>Salt</li></ul></div>'
        extra += '<div class="recipe-card-directions"><ol><li>Cut.</li><li>Mix.</li></ol></div>'
        result = self.extract("maangchi", node, extra)["recipes"][0]
        self.assertEqual(result["ingredients"], ["Cabbage", "Salt"])
        self.assertEqual(result["instructions"], ["Cut.", "Mix."])

    def test_maangchi_unclosed_image_paragraph_does_not_swallow_directions(self):
        node = {"@type": "Recipe", "name": "Pickles", "author": {"name": "Maangchi"}}
        extra = '<div class="recipe-card-ingredients"><p>Broccoli, salt, water</p><p><img src="photo.jpg"></div>'
        extra += '<div class="recipe-card-directions"><ol><li>Boil.<br>Cool.</li></ol></div>'
        result = self.extract("maangchi", node, extra)["recipes"][0]
        self.assertEqual(result["ingredients"], ["Broccoli, salt, water"])
        self.assertEqual(result["instructions"], ["Boil. Cool."])
        self.assertEqual(result["missing_fields"], [])

    def test_maangchi_without_recipe_schema_uses_visible_byline(self):
        extra = '<h1 class="entry-title">Rice</h1><p class="author postedby">By Guest Cook</p>'
        extra += '<div class="recipe-card-ingredients"><ul><li>Rice</li></ul></div>'
        extra += '<div class="recipe-card-directions"><ol><li>Cook.</li></ol></div>'
        result = self.extract("maangchi", {"@type": "Article"}, extra)
        self.assertEqual(result["recipes"][0]["authors"], ["Guest Cook"])
        self.assertEqual(result["recipes"][0]["name"], "Rice")
        self.assertTrue(result["extraction_warnings"])

    def test_zuckerjagdwurst_retains_german_language_and_person_credit(self):
        node = {"@type": "Recipe", "name": "Kuchen", "inLanguage": "de", "author": [{"name": "Katja Hansen"}],
                "recipeIngredient": ["100 g Mehl"], "recipeInstructions": [{"@type": "HowToStep", "text": "Backen."}]}
        result = self.extract("zuckerjagdwurst", node)["recipes"][0]
        self.assertEqual(result["language"], "de")
        self.assertEqual(result["authors"], ["Katja Hansen"])

    def test_maangchi_legacy_headings_stop_before_metadata_and_comments(self):
        extra = '<h1 class="entry-title">Stew</h1><p class="postedby">By Maangchi</p>'
        extra += '<h2>Ingredients</h2><h3>For the stew</h3><ul><li>Beans</li><li>Water</li></ul>'
        extra += '<h2>Description</h2><ol><li>Simmer.</li></ol>'
        extra += '<div class="entry-metadata">Published today</div><ol><li>Reader comment</li></ol>'
        result = self.extract('maangchi', {'@type': 'Article'}, extra)['recipes'][0]
        self.assertEqual(result['ingredients'], ['Beans', 'Water'])
        self.assertEqual(result['instructions'], ['Simmer.'])

    def test_maangchi_what_you_need_heading_keeps_the_material_list(self):
        extra = '<h1 class="entry-title">Sprouts</h1><p class="postedby">By Maangchi</p>'
        extra += '<h2>What you need</h2><ul><li>Mung beans</li><li>A planter</li></ul><h2>Directions</h2><ol><li>Soak.</li></ol>'
        result = self.extract('maangchi', {'@type': 'Article'}, extra)['recipes'][0]
        self.assertEqual(result['ingredients'], ['Mung beans', 'A planter'])
        self.assertEqual(result['instructions'], ['Soak.'])


class CrawlTests(unittest.TestCase):
    def test_annual_maangchi_sitemaps_are_discovered_without_other_post_types(self):
        base = scrape.SOURCES["maangchi"][0]
        index = '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><sitemap><loc>' + base + 'sitemap-posttype-post.2026.xml</loc></sitemap><sitemap><loc>' + base + 'sitemap-posttype-forum.xml</loc></sitemap></sitemapindex>'
        child = '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>' + base + 'recipe/test</loc></url></urlset>'
        robots = scrape.RobotFileParser()
        robots.parse([])
        with patch.object(scrape, "BASE", base), patch.object(scrape, "download", side_effect=[index, child]) as download:
            self.assertEqual(scrape.discover(base + 'sitemap.xml', robots), [base + 'recipe/test'])
            self.assertEqual(download.call_count, 2)

    def test_retry_uses_checkpoint_and_never_saves_restricted_card(self):
        base = scrape.SOURCES["cookwell"][0]
        urls = [base + 'recipe/a-public', base + 'recipe/b-restricted', base + 'recipe/c-retry']
        sitemap = '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + ''.join('<url><loc>' + url + '</loc></url>' for url in urls) + '</urlset>'
        card = {"@type": "Recipe", "name": "Test", "author": {"name": "Ethan Chlebowski"},
                "recipeIngredient": ["Salt"], "recipeInstructions": ["Mix."]}
        def page(node):
            return '<script type="application/ld+json">' + json.dumps(node) + '</script>'
        def download(url):
            if url.endswith('robots.txt'):
                return 'User-agent: *\nAllow: /'
            if url.endswith('sitemap.xml'):
                return sitemap
            if url == urls[2]:
                raise subprocess.CalledProcessError(22, ['curl'], stderr='temporary failure')
            return page({**card, "isAccessibleForFree": url == urls[0]})
        with tempfile.TemporaryDirectory() as folder, patch.multiple(scrape, ROOT=Path(folder), BASE=scrape.BASE, PUBLISHER=scrape.PUBLISHER, OUTPUT=scrape.OUTPUT), patch.object(scrape.time, 'sleep'), redirect_stdout(io.StringIO()):
            with patch.object(scrape, 'download', side_effect=download), patch.object(sys, 'argv', ['scrape', '--source', 'cookwell']):
                with self.assertRaises(SystemExit):
                    scrape.main()
            directory = Path(folder) / 'quellen' / 'cookwell'
            manifest = json.loads((directory / 'manifest.json').read_text())
            self.assertTrue(manifest['completed'])
            self.assertEqual([p['status'] for p in manifest['pages']], ['recipe', 'restricted', 'error'])
            self.assertNotIn('file', manifest['pages'][1])
            calls = []
            def retry(url):
                calls.append(url)
                return 'User-agent: *\nAllow: /' if url.endswith('robots.txt') else page(card)
            with patch.object(scrape, 'download', side_effect=retry), patch.object(sys, 'argv', ['scrape', '--source', 'cookwell', '--retry-errors']):
                scrape.main()
            self.assertEqual(set(calls), {base + 'robots.txt', urls[2]})
            self.assertEqual(json.loads((directory / 'manifest.json').read_text())['recipe_count'], 2)

    def test_excluded_source_never_fetches_recipe_pages(self):
        with tempfile.TemporaryDirectory() as folder, patch.multiple(scrape, ROOT=Path(folder), BASE=scrape.BASE, PUBLISHER=scrape.PUBLISHER, OUTPUT=scrape.OUTPUT), patch.object(scrape, 'download') as download, patch.object(sys, 'argv', ['scrape', '--source', 'seriouseats']), redirect_stdout(io.StringIO()):
            scrape.main()
            download.assert_not_called()
            manifest = json.loads((Path(folder) / 'quellen' / 'seriouseats' / 'manifest.json').read_text())
            self.assertEqual(manifest['source_status'], 'excluded')
            self.assertEqual(manifest['recipe_count'], 0)


class ArchiveIntegrityTests(unittest.TestCase):
    def test_pending_crawl_cannot_pass_ci(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(check_sources, 'ROOT', Path(folder)), patch.dict(check_sources.HOSTS, {'cookwell': 'app.cookwell.com'}, clear=True):
            path = Path(folder) / 'cookwell'
            path.mkdir()
            (path / 'manifest.json').write_text(json.dumps({'completed': False}))
            with self.assertRaisesRegex(AssertionError, 'noch nicht abgeschlossen'):
                check_sources.check()


if __name__ == '__main__':
    unittest.main()
