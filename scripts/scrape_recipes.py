#!/usr/bin/env python3
"""Sichert Rezeptkarten, keine Bilder/Artikel. Python-Standardbibliothek + curl.

python3 scripts/scrape_recipes.py --source ndr  # nur einzeln geprüfte Auswahl
python3 scripts/scrape_recipes.py --source rainbowplantlife
python3 scripts/scrape_recipes.py --source babish
python3 scripts/scrape_recipes.py --source joshuaweissman --refresh
"""

import argparse
import hashlib
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from ndr_source import extract_ndr, read_selection, reviewed_card
from html import unescape
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess
import time
from urllib.parse import urlparse, urljoin
from urllib.robotparser import RobotFileParser
import xml.etree.ElementTree as ET

BASE = "https://rainbowplantlife.com/"
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "quellen" / "rainbowplantlife"
NS = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
SOURCES = {
    "ndr": ("https://www.ndr.de/", "NDR"),
    "rainbowplantlife": ("https://rainbowplantlife.com/", "Rainbow Plant Life"),
    "babish": ("https://www.babi.sh/", "Babish"),
    "joshuaweissman": ("https://www.joshuaweissman.com/", "Joshua Weissman"),
}
PUBLISHER = "Rainbow Plant Life"


def same_site(url):
    p = urlparse(url)
    return p.scheme == "https" and p.netloc.removeprefix("www.") == urlparse(BASE).netloc.removeprefix("www.")


def download(url):
    if not same_site(url):
        raise ValueError(f"Fremde URL: {url}")
    result = subprocess.run(
        ["curl", "--user-agent", "KochbuchRecipeArchiver/1.0", "--fail", "--silent", "--show-error", "--location",
         "--proto", "=https", "--proto-redir", "=https", "--max-time", "45",
         "--retry", "2", "--retry-delay", "3", url],
        check=True, capture_output=True, text=True,
    )
    return result.stdout


def clean(value):
    return re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]*>", " ", str(value)))).strip()


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


class RecipePage(HTMLParser):
    def __init__(self):
        super().__init__()
        self.canonical = None
        self.scripts = []
        self.script = None
        self.notes = []
        self.note_depth = 0
        self.links = []
        self.stack = []
        self.richtext = {"ingredients-list": [], "directions-list": []}
        self.richtext_lines = {"ingredients-list": [], "directions-list": []}
        self.active_line = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "a" and attrs.get("href"):
            self.links.append((attrs["href"], attrs.get("aria-label", "")))
        if tag not in {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}:
            parent = self.stack[-1][1] if self.stack else None
            section = next((c for c in attrs.get("class", "").split() if c in self.richtext), parent)
            self.stack.append((tag, section))
            if section and tag in {"li", "p", "h2", "h3", "h4"} and self.active_line is None:
                self.active_line = (tag, section, [], len(self.stack))
        if tag == "link" and "canonical" in attrs.get("rel", "").split():
            self.canonical = attrs.get("href")
        if tag == "script" and attrs.get("type") == "application/ld+json":
            self.script = []
        if tag == "div":
            if self.note_depth:
                self.note_depth += 1
            elif "wprm-recipe-notes-container" in attrs.get("class", "").split():
                self.note_depth = 1
                self.notes.append([])

    def handle_endtag(self, tag):
        if self.active_line and self.active_line[0] == tag and self.active_line[3] == len(self.stack):
            _, section, parts, _ = self.active_line
            line = clean("".join(parts))
            if line:
                self.richtext_lines[section].append({"tag": tag, "text": line})
            self.active_line = None
        for idx in range(len(self.stack) - 1, -1, -1):
            if self.stack[idx][0] == tag:
                del self.stack[idx:]
                break
        if tag == "script" and self.script is not None:
            self.scripts.append("".join(self.script))
            self.script = None
        if tag == "div" and self.note_depth:
            self.note_depth -= 1

    def handle_data(self, data):
        if self.script is not None:
            self.script.append(data)
        if self.note_depth:
            self.notes[-1].append(data)
        if self.active_line:
            self.active_line[2].append(data)


def extract(page, url):
    if PUBLISHER == "NDR":
        return extract_ndr(page, url)
    parser = RecipePage()
    parser.feed(page)
    nodes = []
    warnings = []
    for script in parser.scripts:
        try:
            # Webflow setzt teils echte Zeilenumbrüche in JSON-Zeichenketten.
            nodes.extend(walk(json.loads(script, strict=False)))
        except json.JSONDecodeError:
            if PUBLISHER != "Joshua Weissman" or not re.search(r'"@type"\s*:\s*"Recipe"', script):
                raise
            # Einige Webflow-Titel/Beschreibungen enthalten zusätzlich nicht
            # maskierte Anführungszeichen. Nur belegbare Metadaten rekonstruieren;
            # Zutaten/Schritte kommen weiterhin aus den sichtbaren Rezeptlisten.
            def field(name, end):
                match = re.search(r'"' + name + r'"\s*:\s*"(.*?)"\s*,\s*"' + end + r'"', script, re.S)
                return clean(match[1]) if match else None
            author = re.search(r'"author"\s*:\s*\{.*?"name"\s*:\s*"([^"]+)"', script, re.S)
            nodes.append({"@type": "Recipe", "name": field("name", "description"),
                          "author": {"name": author[1]} if author else None,
                          "prepTime": field("prepTime", "cookTime"),
                          "cookTime": field("cookTime", "totalTime"),
                          "totalTime": field("totalTime", "recipeYield"),
                          "recipeYield": field("recipeYield", "video")})
            warnings.append("Ungültiges Quell-JSON; Metadaten aus den Quellfeldern und Rezepttext aus sichtbaren Listen extrahiert.")
    by_id = {n["@id"]: n for n in nodes if "@id" in n and "name" in n}

    def authors(value):
        if isinstance(value, list):
            return [name for item in value for name in authors(item)]
        if isinstance(value, dict):
            value = value.get("name") or by_id.get(value.get("@id"), {}).get("name")
        return [clean(value)] if value else []

    canonical = parser.canonical or url
    if not same_site(canonical):
        raise ValueError(f"Ungültige Originalquelle: {canonical}")
    cards = []
    seen = set()
    for node in nodes:
        if "Recipe" not in node.get("@type", []):
            continue
        key = node.get("@id") or node.get("name")
        if key in seen:
            continue
        seen.add(key)
        steps = [clean(s["text"]) for s in walk(node.get("recipeInstructions", []))
                 if s.get("@type") == "HowToStep" and s.get("text")]
        ingredients = [clean(i) for i in node.get("recipeIngredient", [])]
        if PUBLISHER == "Joshua Weissman":
            ingredients = ingredients or [line["text"] for line in parser.richtext_lines["ingredients-list"] if line["tag"] == "li"]
            steps = steps or [line["text"] for line in parser.richtext_lines["directions-list"] if line["tag"] == "li"]
        author = authors(node.get("author"))
        missing = [name for name, value in (("ingredients", ingredients), ("instructions", steps),
                                             ("authors", author), ("name", node.get("name"))) if not value]
        cards.append({
            "name": clean(node.get("name") or ""), "source_url": canonical,
            "recipe_id": node.get("@id"), "authors": author,
            "publisher": PUBLISHER, "language": "en",
            "yield": node.get("recipeYield"), "prep_time": node.get("prepTime"),
            "cook_time": node.get("cookTime"), "total_time": node.get("totalTime"),
            "ingredients": ingredients, "instructions": steps,
            "ingredient_sections": parser.richtext_lines["ingredients-list"],
            "instruction_sections": parser.richtext_lines["directions-list"],
            "missing_fields": missing,
        })
    # Manche Artikel enthalten mehrere Karten. Notizen deshalb explizit auf Seitenebene.
    return {"source_url": canonical, "recipes": cards, "extraction_warnings": warnings,
            "page_recipe_notes": [clean(" ".join(n)) for n in parser.notes]}


def discover(url, robots):
    if not same_site(url) or not robots.can_fetch("*", url):
        raise ValueError(f"Sitemap nicht erlaubt: {url}")
    root = ET.fromstring(download(url))
    if root.tag.endswith("sitemapindex"):
        urls = []
        for loc in root.findall("s:sitemap/s:loc", NS):
            # Beiträge und Seiten; keine Kategorie-/Tag-Archive.
            if re.search(r"/(post|page)-sitemap\d*\.xml$", loc.text):
                urls.extend(discover(loc.text, robots))
        return urls
    return [loc.text for loc in root.findall("s:url/s:loc", NS)]


def main():
    global BASE, OUTPUT, PUBLISHER
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", choices=SOURCES, required=True)
    ap.add_argument("--retry-errors", action="store_true", help="Nur Fehler des letzten Manifests erneut abrufen; Index nicht neu durchsuchen")
    ap.add_argument("--refresh", action="store_true", help="Auch bereits erfasste Seiten neu laden")
    args = ap.parse_args()
    BASE, PUBLISHER = SOURCES[args.source]
    OUTPUT = ROOT / "quellen" / args.source
    OUTPUT.mkdir(parents=True, exist_ok=True)
    robots = RobotFileParser()
    try:
        robots.parse(download(BASE + "robots.txt").splitlines())
    except subprocess.CalledProcessError as exc:
        if "404" not in exc.stderr:
            raise
        robots.parse([])  # HTTP 404: keine robots.txt vorhanden.
    manifest_path = OUTPUT / "manifest.json"
    selection = read_selection() if args.source == "ndr" else None
    selected = {r['url']: r for r in selection['recipes']} if selection else {}
    if args.source == "ndr":
        if args.retry_errors and args.refresh:ap.error("--retry-errors und --refresh nicht kombinieren")
        sitemap_url = None
        urls = sorted(selected)
    elif args.retry_errors:
        if args.refresh:
            ap.error("--retry-errors und --refresh nicht kombinieren")
        previous = json.loads(manifest_path.read_text())
        sitemap_url = previous["sitemap_url"]
        urls = [p["url"] for p in previous["pages"]]
    elif args.source == "joshuaweissman":
        sitemap_url = BASE + "recipes"
        next_page = sitemap_url
        found, visited = set(), set()
        while next_page and next_page not in visited:
            if not robots.can_fetch("*", next_page):
                raise ValueError(f"Index nicht erlaubt: {next_page}")
            visited.add(next_page)
            p = RecipePage()
            p.feed(download(next_page))
            for href, _ in p.links:
                link = urljoin(next_page, href)
                if same_site(link) and urlparse(link).path.startswith("/recipes/"):
                    found.add(link.split("?")[0].split("#")[0])
            next_page = next((urljoin(next_page, h) for h, label in p.links if label == "Next Page"), None)
            print(f"Index {len(visited)}: {len(found)} Rezept-URLs", flush=True)
            time.sleep(1)
        urls = sorted(found)
    else:
        sitemap_url = BASE + ("sitemap_index.xml" if args.source == "rainbowplantlife" else "sitemap.xml")
        urls = sorted(set(discover(sitemap_url, robots)))
        if args.source == "babish":
            urls = [url for url in urls if urlparse(url).path.startswith("/recipes/")]
    old = {}
    manifest_path = OUTPUT / "manifest.json"
    if manifest_path.exists() and not args.refresh:
        old = {p["url"]: p for p in json.loads(manifest_path.read_text())["pages"]
               if p["status"] in {"recipe", "incomplete", "no_recipe", "disallowed"}}

    def process(url):
        if not same_site(url) or not robots.can_fetch("KochbuchRecipeArchiver" if args.source == "ndr" else "*", url):
            return {"url": url, "status": "disallowed"}
        cached = old.get(url)
        if cached and args.source == 'ndr':
            cached_file = OUTPUT / cached.get('file','missing')
            if not cached_file.is_file():
                cached = None
            else:
                saved = json.loads(cached_file.read_text())
                if (saved.get('reviewed_source_digest') != selected[url]['source_digest'] or saved['recipes'][0]['instructions'] != selected[url]['editorial_instructions'] or saved['recipes'][0]['publisher_nutrition']['reviewedAt'] != selected[url]['reviewed_on'] or cached.get('sha256') != hashlib.sha256(cached_file.read_bytes()).hexdigest()):
                    cached = None
        if cached and (cached["status"] not in {"recipe", "incomplete"} or (OUTPUT / cached["file"]).exists()):
            return cached
        time.sleep(max(1, robots.crawl_delay("*") or 0))
        try:
            data = extract(download(url), url)
            if args.source == "ndr":data = reviewed_card(data, selected[url])
            if not data["recipes"]:
                return {"url": url, "status": "no_recipe"}
            slug = urlparse(url).path.strip("/").replace("/", "--") or "index"
            if not re.fullmatch(r"[a-zA-Z0-9_-]+", slug):
                slug = re.sub(r"[^a-zA-Z0-9_-]+", "-", slug).strip("-") + "-" + hashlib.sha256(url.encode()).hexdigest()[:10]
            file = (selected[url]["slug"] if args.source == "ndr" else slug) + ".json"
            (OUTPUT / file).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            status = "incomplete" if any(r["missing_fields"] for r in data["recipes"]) else "recipe"
            result = {"url": url, "status": status, "file": file, "recipe_count": len(data["recipes"])}
            if args.source == "ndr":result['sha256'] = hashlib.sha256((OUTPUT/file).read_bytes()).hexdigest()
            return result
        except (ValueError, OSError, subprocess.SubprocessError) as exc:
            detail = getattr(exc, "stderr", None) or str(exc)
            return {"url": url, "status": "error", "error": detail.strip()}

    pages = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        for result in pool.map(process, urls):
            pages.append(result)
            if len(pages) % 20 == 0 or result["status"] == "error":
                print(f'{len(pages)}/{len(urls)} {result["status"]}: {result["url"]}', flush=True)
    manifest = {
        "publisher": PUBLISHER, "sitemap_url": sitemap_url,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "scope": "Öffentliche Rezeptkarten aus Sitemap bzw. vollständigem Rezeptindex; kein Paywall-/Buchinhalt.",
        "page_count": len(pages), "recipe_count": sum(p.get("recipe_count", 0) for p in pages),
        "pages": pages,
    }
    if args.source == "ndr":
        manifest.update(scope=selection['scope'],selection_file='selection.json',selection_sha256=hashlib.sha256((OUTPUT/'selection.json').read_bytes()).hexdigest(),completed=all(p['status']=='recipe' for p in pages))
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    errors = [p for p in pages if p["status"] == "error" or (args.source == "ndr" and p["status"] != "recipe")]
    print(f'{manifest["recipe_count"]} Rezeptkarten; {len(errors)} Fehler. {manifest_path}')
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
