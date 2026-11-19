"""NDR recipe-card extraction; no sitemap discovery, images or disease tags."""
from datetime import date
from hashlib import sha256
from html import unescape
from html.parser import HTMLParser
import json
from pathlib import Path
import re
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
VOID = {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}


def clean(text):
    return re.sub(r'\s+', ' ', unescape(text)).strip()


def ndr_url(url):
    p = urlparse(url)
    return p.scheme == 'https' and p.netloc == 'www.ndr.de' and p.path.startswith('/ratgeber/kochen/rezepte/') and p.path.endswith('.html') and not p.query and not p.fragment


class NdrPage(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack=[]; self.script=None; self.scripts=[]; self.canonical=None
        self.ingredients=[]; self.active=None; self.nutrition_section=False; self.paragraph=None; self.nutrition_text=[]
        self.servings=None

    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if tag=='link' and 'canonical' in attrs.get('rel','').split(): self.canonical=attrs.get('href')
        if tag=='script' and attrs.get('type')=='application/ld+json': self.script=[]
        if tag=='input' and attrs.get('id')=='currentServing': self.servings=attrs.get('data-previous') or attrs.get('value')
        if tag not in VOID:self.stack.append(tag)
        if tag=='li' and 'ingredient' in attrs.get('class','').split(): self.active=(len(self.stack),[])
        if tag=='h2': self.nutrition_section=attrs.get('id')=='Naehrwerte-pro-Portion'
        if tag=='p' and self.nutrition_section:self.paragraph=(len(self.stack),[])

    def handle_endtag(self, tag):
        if tag=='script' and self.script is not None:self.scripts.append(''.join(self.script));self.script=None
        if self.active and tag=='li' and len(self.stack)==self.active[0]:
            self.ingredients.append(clean(''.join(self.active[1])));self.active=None
        if self.paragraph and tag=='p' and len(self.stack)==self.paragraph[0]:
            self.nutrition_text.append(clean(''.join(self.paragraph[1])));self.paragraph=None
        for i in range(len(self.stack)-1,-1,-1):
            if self.stack[i]==tag:del self.stack[i:];break

    def handle_data(self,text):
        if self.script is not None:self.script.append(text)
        if self.active:self.active[1].append(text)
        if self.paragraph:self.paragraph[1].append(text)


def walk(value):
    if isinstance(value,dict):
        yield value
        for child in value.values():yield from walk(child)
    elif isinstance(value,list):
        for child in value:yield from walk(child)


def extract_ndr(html,url):
    if not ndr_url(url):raise ValueError('NDR recipe URL required')
    p=NdrPage();p.feed(html)
    if not p.canonical or not ndr_url(p.canonical):raise ValueError('Invalid NDR canonical URL')
    nodes=[n for s in p.scripts for n in walk(json.loads(s)) if n.get('@type')=='Recipe' or isinstance(n.get('@type'),list) and 'Recipe' in n['@type']]
    if len(nodes)!=1:raise ValueError('Expected exactly one NDR recipe')
    node=nodes[0]
    servings=node.get('recipeYield')
    if not isinstance(servings,int) or isinstance(servings,bool) or servings<=0 or str(servings)!=p.servings:raise ValueError('NDR serving counts missing or disagree')
    a=node.get('author')
    authors=[clean(a.get('name',''))] if isinstance(a,dict) else []
    if not authors or not authors[0]:raise ValueError('NDR author missing; never use image/video credits')
    instructions=[]
    for item in node.get('recipeInstructions',[]):
        if isinstance(item,str):instructions.extend(clean(v) for v in re.split(r'\n\s*\n',item) if clean(v))
        elif isinstance(item,dict) and item.get('text'):instructions.append(clean(item['text']))
    if not p.ingredients or not instructions:raise ValueError('NDR recipe content missing')
    text=' '.join(p.nutrition_text)
    fields={'energy_kcal':r'(\d+(?:[.,]\d+)?)\s*kcal','protein_g':r'(\d+(?:[.,]\d+)?)\s*g\s*(?:Eiweiß|Protein)','fat_g':r'(\d+(?:[.,]\d+)?)\s*g\s*Fett','publisher_carbohydrates_g':r'(\d+(?:[.,]\d+)?)\s*g\s*Kohlenhydrate','fiber_g':r'(\d+(?:[.,]\d+)?)\s*g\s*Ballaststoffe'}
    values={key:float(m[1].replace(',','.')) for key,pattern in fields.items() if (m:=re.search(pattern,text))}
    if len(values)!=len(fields):raise ValueError('NDR nutrition fields missing')
    card={'name':clean(node.get('name','')),'source_url':p.canonical,'recipe_id':p.canonical,'authors':authors,'publisher':'NDR','language':'de','yield':servings,'prep_time':None,'cook_time':None,'total_time':node.get('totalTime'),'ingredients':p.ingredients,'instructions':instructions,'missing_fields':[],
          'publisher_nutrition':{'basis':'per_serving','origin':'publisher_estimate','sourceUrl':p.canonical,'nutrients':values,'note':'NDR-Schätzung pro veröffentlichter Portion; Kohlenhydratdefinition nicht unabhängig geprüft. Nicht mit BLS-Teilsummen verrechnen.'}}
    if not card['name'] or not re.fullmatch(r'PT\d+M',card['total_time'] or ''):raise ValueError('NDR title or total time missing')
    return {'source_url':p.canonical,'recipes':[card],'page_recipe_notes':[],'extraction_warnings':['Sichtbare Zutaten statt verlustbehaftetem JSON-LD; Alternativen bleiben ausdrücklich erhalten.']}


def source_digest(data):
    return sha256(json.dumps(data,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()


def read_selection(path=None):
    doc=json.loads((path or ROOT/'quellen/ndr/selection.json').read_text())
    if doc.get('version')!=1 or not 1<=len(doc['recipes'])<=20:raise ValueError('NDR selection must contain 1–20 individually reviewed recipes')
    urls=set();slugs=set()
    for item in doc['recipes']:
        date.fromisoformat(item['reviewed_on'])
        if not ndr_url(item['url']) or item['url'] in urls or item['slug'] in slugs:raise ValueError('Invalid or duplicate NDR selection')
        if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*',item['slug']) or not item['reason'].strip() or not re.fullmatch(r'[a-f0-9]{64}',item['source_digest']):raise ValueError('NDR selection needs slug, reason and reviewed digest')
        if not item.get('editorial_instructions') or any(not s.strip() for s in item['editorial_instructions']):raise ValueError('Reviewed editorial instructions required')
        urls.add(item['url']);slugs.add(item['slug'])
    return doc


def reviewed_card(data,selection):
    if data['source_url']!=selection['url'] or source_digest(data)!=selection['source_digest']:raise ValueError('NDR recipe changed: review source, quantities and nutrition before refreshing')
    # Store our short editorial summary, not full publisher paragraphs.
    card=data['recipes'][0]
    card['instructions']=selection['editorial_instructions']
    card['instruction_representation']='editorial_summary'
    card['publisher_nutrition']['reviewedAt']=selection['reviewed_on']
    data['reviewed_source_digest']=selection['source_digest']
    data['page_recipe_notes']=['Zubereitung redaktionell gekürzt und neu formuliert; keine wörtliche Volltextkopie.']
    return data
