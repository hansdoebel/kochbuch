"""NDR-specific regressions: reviewed URLs, quantities, alternatives and source changes."""
import json
from pathlib import Path
import tempfile
import unittest
from ndr_source import extract_ndr,source_digest,reviewed_card,read_selection
from lint_recipes import lint_text

URL='https://www.ndr.de/ratgeber/kochen/rezepte/test,test100.html'


def page(author=None,servings=2):
    recipe={'@type':'Recipe','name':'Test','author':author or {'name':'ndr.de','@type':'Organization'},'recipeYield':servings,'totalTime':'PT30M','recipeIngredient':['150 g beans'],'recipeInstructions':['Prepare beans.\n\nServe with vegetables.']}
    return f'<link rel="canonical" href="{URL}"><script type="application/ld+json">{json.dumps(recipe)}</script><input id="currentServing" data-previous="2"><ul class="ingredients"><li class="ingredient"><span>150 g </span><span>(Abtropfgewicht) Kichererbsen</span></li><li class="ingredient">alternativ: Blattspinat</li></ul><h2 id="Naehrwerte-pro-Portion">Nährwerte pro Portion</h2><p>circa 590 kcal, 28 g Eiweiß, 32 g Fett, 45 g Kohlenhydrate, 18 g Ballaststoffe</p><h2 id="Geeignet-u-a-bei">Stop</h2><p>999 kcal, 999 g Eiweiß</p>'


class NdrTests(unittest.TestCase):
    def test_visible_ingredients_keep_weights_and_alternatives_and_author_is_not_image_credit(self):
        result=extract_ndr(page(),URL);card=result['recipes'][0]
        self.assertEqual(card['ingredients'],['150 g (Abtropfgewicht) Kichererbsen','alternativ: Blattspinat'])
        self.assertEqual(card['authors'],['ndr.de']);self.assertEqual(card['instructions'],['Prepare beans.','Serve with vegetables.'])
        self.assertEqual(card['publisher_nutrition']['nutrients']['protein_g'],28)
        self.assertEqual(card['publisher_nutrition']['nutrients']['publisher_carbohydrates_g'],45)
        self.assertEqual(card['publisher_nutrition']['origin'],'publisher_estimate')

    def test_heading_variants_preserve_an_excluded_side(self):
        html=page().replace('id="Naehrwerte-pro-Portion"','id="Naehrwerte-pro-Portion-ohne-Salat"').replace('Nährwerte pro Portion</h2>','Nährwerte pro Portion (ohne Salat)</h2>')
        nutrition=extract_ndr(html,URL)['recipes'][0]['publisher_nutrition']
        self.assertEqual(nutrition['nutrients']['protein_g'],28)
        self.assertIn('ohne Salat',nutrition['note'])
        decomposed=page().replace('id="Naehrwerte-pro-Portion"','id="Nahrwerte-pro-Portion"').replace('Nährwerte pro Portion</h2>','Nährwerte pro Portion</h2>')
        self.assertEqual(extract_ndr(decomposed,URL)['recipes'][0]['publisher_nutrition']['nutrients']['fiber_g'],18)

    def test_canonical_host_and_serving_disagreement_fail(self):
        with self.assertRaises(ValueError):extract_ndr(page().replace(URL,'https://other.example/test'),URL)
        with self.assertRaises(ValueError):extract_ndr(page(servings=4),URL)
        with self.assertRaises(ValueError):extract_ndr(page(),URL+'?all=true')

    def test_source_changes_need_a_new_review_and_summary_is_used(self):
        data=extract_ndr(page(),URL)
        selected={'url':URL,'source_digest':source_digest(data),'editorial_instructions':['Our short summary.'],'reviewed_on':'2026-11-19'}
        result=reviewed_card(data,selected)
        self.assertEqual(result['recipes'][0]['instructions'],['Our short summary.'])
        self.assertEqual(result['recipes'][0]['instruction_representation'],'editorial_summary')
        with self.assertRaisesRegex(ValueError,'changed'):reviewed_card(extract_ndr(page().replace('28 g','29 g'),URL),selected)

    def test_selection_is_bounded_and_unique(self):
        item={'url':URL,'slug':'test','source_digest':'a'*64,'reason':'Individually reviewed','editorial_instructions':['Summary'],'reviewed_on':'2026-11-19'}
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'selection.json'
            p.write_text(json.dumps({'version':1,'recipes':[item]}));self.assertEqual(len(read_selection(p)['recipes']),1)
            p.write_text(json.dumps({'version':1,'recipes':[item,item]}))
            with self.assertRaises(ValueError):read_selection(p)

    def test_total_time_can_be_known_without_inventing_prep_or_cook_time(self):
        root=Path(__file__).resolve().parents[1]
        p=root/'rezepte/protein-bowl-mit-linsen-und-kichererbsen.md';text=p.read_text()
        self.assertEqual(lint_text(text,p.stem),[])
        self.assertTrue(lint_text(text.replace('total_minutes: 30','total_minutes: -1'),p.stem))
        self.assertTrue(lint_text(text.replace('cook_minutes: unbekannt','cook_minutes: -1'),p.stem))

    def test_author_array_preserves_recipe_byline(self):
        card=extract_ndr(page(author=[{'@type':'Person','name':'Tarik Rose'}]),URL)['recipes'][0]
        self.assertEqual(card['authors'],['Tarik Rose'])
        with self.assertRaises(ValueError):extract_ndr(page(author=[{'@type':'ImageObject','url':'https://example.com'}]),URL)
