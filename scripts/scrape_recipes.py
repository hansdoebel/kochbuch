#!/usr/bin/env python3
"""Sichert Rezeptkarten, keine Bilder/Artikel. Python-Standardbibliothek + curl.

python3 scripts/scrape_recipes.py --source rainbowplantlife
python3 scripts/scrape_recipes.py --source babish
python3 scripts/scrape_recipes.py --source joshuaweissman --refresh
"""

import argparse
import hashlib
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
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
    "rainbowplantlife": ("https://rainbowplantlife.com/", "Rainbow Plant Life"),
    "babish": ("https://www.babi.sh/", "Babish"),
    "joshuaweissman": ("https://www.joshuaweissman.com/", "Joshua Weissman"),
    "cookwell": ("https://app.cookwell.com/", "Cook Well"),
    "recipetineats": ("https://www.recipetineats.com/", "RecipeTin Eats"),
    "zuckerjagdwurst": ("https://www.zuckerjagdwurst.com/", "Zucker & Jagdwurst"),
    "maangchi": ("https://www.maangchi.com/", "Maangchi"),
    "pickuplimes": ("https://www.pickuplimes.com/", "Pick Up Limes"),
    "seriouseats": ("https://www.seriouseats.com/", "Serious Eats"),
}
PUBLISHER = "Rainbow Plant Life"
USER_AGENT = "KochbuchRecipeArchiver/1.0 (user-requested public recipe archive)"
SITEMAPS = {"rainbowplantlife": "sitemap_index.xml", "recipetineats": "sitemap_index.xml"}
PATH_PREFIXES = {"babish": "/recipes/", "cookwell": "/recipe/", "zuckerjagdwurst": "/de/rezepte/",
                 "maangchi": "/recipe/", "pickuplimes": "/recipe/"}
EXCLUDED = {"seriouseats": "Der Herausgeber untersagt automatisiertes Content-Archiving ohne vorherige schriftliche Erlaubnis in https://www.seriouseats.com/robots.txt. Keine Rezeptseiten abgerufen."}


def same_site(url):
    p = urlparse(url)
    return p.scheme == "https" and p.netloc.removeprefix("www.") == urlparse(BASE).netloc.removeprefix("www.")


def download(url):
    if not same_site(url):
        raise ValueError(f"Fremde URL: {url}")
    result = subprocess.run(
        ["curl", "--fail", "--silent", "--show-error", "--location",
         "--proto", "=https", "--proto-redir", "=https", "--max-time", "45",
         "--retry", "2", "--retry-delay", "3", "--user-agent", USER_AGENT, url],
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


def instruction_texts(value):
    """Schema.org erlaubt Texte, verschachtelte Listen und HowToSection/Step."""
    if isinstance(value, str):
        if clean(value):
            yield clean(value)
    elif isinstance(value, list):
        for item in value:
            yield from instruction_texts(item)
    elif isinstance(value, dict):
        if value.get("text"):
            yield clean(value["text"])
        yield from instruction_texts(value.get("itemListElement", []))
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

    def finish_line(self):
        if self.active_line:
            tag, section, parts, _ = self.active_line
            line = clean("".join(parts))
            if line:
                self.richtext_lines[section].append({"tag": tag, "text": line})
            self.active_line = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if self.active_line and self.active_line[0] == "p" and tag in {"p", "div", "ol", "ul", "h2", "h3", "h4"}:
            depth = self.active_line[3]
            self.finish_line()
            del self.stack[depth - 1:]
        if tag == "br" and self.active_line:
            self.active_line[2].append(" ")
        if tag == "a" and attrs.get("href"):
            self.links.append((attrs["href"], attrs.get("aria-label", "")))
        if tag not in {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}:
            parent = self.stack[-1][1] if self.stack else None
            classes = attrs.get("class", "").split()
            aliases = {"recipe-card-ingredients": "ingredients-list", "recipe-card-directions": "directions-list"}
            section = next((aliases.get(c, c) for c in classes if c in self.richtext or c in aliases), parent)
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
            elif "wprm-recipe-notes-container" in attrs.get("class", "").split() or attrs.get("class", "") == "rp-callout":
                self.note_depth = 1
                self.notes.append([])

    def handle_endtag(self, tag):
        closing_index = next((i for i in range(len(self.stack) - 1, -1, -1) if self.stack[i][0] == tag), None)
        if self.active_line and closing_index is not None and closing_index + 1 <= self.active_line[3]:
            self.finish_line()
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


class MaangchiLegacyCard(RecipePage):
    """Ältere Beiträge grenzen Rezeptteile über Überschriften statt CSS ab."""
    def __init__(self):
        super().__init__()
        self.mode = None
        self.heading = None

    def handle_starttag(self, tag, attrs):
        if tag in {"h2", "h3", "h4"}:
            self.heading = (tag, [])
        if tag == "ol":
            self.mode = "directions-list"
        attrs = dict(attrs)
        if self.mode and tag in {"p", "li", "ol", "ul"}:
            attrs["class"] = attrs.get("class", "") + " " + self.mode
        super().handle_starttag(tag, list(attrs.items()))

    def handle_data(self, data):
        if self.heading:
            self.heading[1].append(data)
        super().handle_data(data)

    def handle_endtag(self, tag):
        super().handle_endtag(tag)
        if self.heading and self.heading[0] == tag:
            text = clean("".join(self.heading[1]))
            self.heading = None
            if re.match(r"^(Ingredients|What\s+you\s+need)\b", text, re.I):
                self.mode = "ingredients-list"
            elif re.match(r"^(Directions|Description|Instructions|Method|Preparing)\b", text, re.I):
                self.mode = "directions-list"
            if self.mode:
                self.richtext_lines[self.mode].append({"tag": tag, "text": text})


def maangchi_legacy_sections(page):
    start = re.search(r'<h[234]\b[^>]*>\s*(?:Ingredients|What\s+you\s+need|Directions|Description|Instructions|Method|Preparing)\b', page, re.I)
    if not start:
        return None
    fragment = page[start.start():]
    end = re.search(r'<(?:div|section)\b[^>]*class="[^"]*(?:entry-metadata|newsletter-module|newsletter-signup-embed)[^"]*"', fragment)
    if end:
        fragment = fragment[:end.start()]
    parser = MaangchiLegacyCard()
    parser.feed(fragment)
    return parser.richtext_lines


def extract(page, url):
    parser = RecipePage()
    parser.feed(page)
    if PUBLISHER == "Maangchi":
        if not all(any(line["tag"] in {"li", "p"} for line in lines) for lines in parser.richtext_lines.values()):
            legacy = maangchi_legacy_sections(page)
            if legacy:
                for key, lines in legacy.items():
                    if not any(line["tag"] in {"li", "p"} for line in parser.richtext_lines[key]):
                        parser.richtext_lines[key] = lines
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
    if PUBLISHER == "Maangchi" and not any("Recipe" in n.get("@type", []) for n in nodes):
        if parser.richtext_lines["ingredients-list"] or parser.richtext_lines["directions-list"]:
            title = re.search(r'<h1\b[^>]*class="[^"]*entry-title[^"]*"[^>]*>(.*?)</h1>', page, re.S)
            byline = re.search(r'<p\b[^>]*class="[^"]*postedby[^"]*"[^>]*>(.*?)</p>', page, re.S)
            credit = re.sub(r"^By\s+", "", clean(byline[1])) if byline else None
            nodes.append({"@type": "Recipe", "name": clean(title[1]) if title else "",
                          "author": {"name": credit} if credit else None})
            warnings.append("Kein Recipe-JSON-LD; sichtbare Rezeptkarte mit Originaltitel und sichtbarer Byline erfasst.")

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
    restricted_cards = 0
    seen = set()
    for node in nodes:
        if "Recipe" not in node.get("@type", []):
            continue
        if node.get("isAccessibleForFree") in (False, "false", "False"):
            restricted_cards += 1
            continue
        key = node.get("@id") or node.get("name")
        if key in seen:
            continue
        seen.add(key)
        steps = list(instruction_texts(node.get("recipeInstructions", [])))
        ingredients = [clean(i) for i in node.get("recipeIngredient", [])]
        if PUBLISHER == "Joshua Weissman":
            ingredients = ingredients or [line["text"] for line in parser.richtext_lines["ingredients-list"] if line["tag"] == "li"]
            steps = steps or [line["text"] for line in parser.richtext_lines["directions-list"] if line["tag"] == "li"]
        if PUBLISHER == "Maangchi":
            # Manche Quell-JSONs lassen einen Teil der Zutaten aus. Die sichtbare
            # Rezeptkarte enthält die vollständige Liste und ist maßgeblich.
            visible = [line["text"] for line in parser.richtext_lines["ingredients-list"] if line["tag"] == "li"]
            if not visible:
                visible = [line["text"] for line in parser.richtext_lines["ingredients-list"] if line["tag"] == "p"
                           and not re.match(r"^(Makes|Serves|Yields)\b", line["text"], re.I)]
            if visible:
                ingredients = visible
            visible_steps = [line["text"] for line in parser.richtext_lines["directions-list"] if line["tag"] == "li"]
            if not visible_steps:
                visible_steps = [line["text"] for line in parser.richtext_lines["directions-list"] if line["tag"] == "p"]
            if visible_steps:
                steps = visible_steps
        author = authors(node.get("author"))
        missing = [name for name, value in (("ingredients", ingredients), ("instructions", steps),
                                             ("authors", author), ("name", node.get("name"))) if not value]
        cards.append({
            "name": clean(node.get("name") or ""), "source_url": canonical,
            "recipe_id": node.get("@id"), "authors": author,
            "publisher": PUBLISHER, "language": node.get("inLanguage") or ("de" if PUBLISHER == "Zucker & Jagdwurst" else "en"),
            "yield": node.get("recipeYield"), "prep_time": node.get("prepTime"),
            "cook_time": node.get("cookTime"), "total_time": node.get("totalTime"),
            "ingredients": ingredients, "instructions": steps,
            "ingredient_sections": parser.richtext_lines["ingredients-list"],
            "instruction_sections": parser.richtext_lines["directions-list"],
            "missing_fields": missing,
        })
    # Manche Artikel enthalten mehrere Karten. Notizen deshalb explizit auf Seitenebene.
    return {"source_url": canonical, "recipes": cards, "restricted_card_count": restricted_cards, "extraction_warnings": warnings,
            "page_recipe_notes": [clean(" ".join(n)) for n in parser.notes]}


def discover(url, robots):
    if not same_site(url) or not robots.can_fetch(USER_AGENT, url):
        raise ValueError(f"Sitemap nicht erlaubt: {url}")
    root = ET.fromstring(download(url))
    if root.tag.endswith("sitemapindex"):
        urls = []
        for loc in root.findall("s:sitemap/s:loc", NS):
            # Beiträge und Seiten; keine Kategorie-/Tag-Archive.
            if re.search(r"/(post|page)-sitemap\d*\.xml$|/sitemap-posttype-post(?:\.\d+)?\.xml$", loc.text):
                urls.extend(discover(loc.text, robots))
        return urls
    return [loc.text for loc in root.findall("s:url/s:loc", NS)]


def main():
    global BASE, OUTPUT, PUBLISHER
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", choices=SOURCES, required=True)
    ap.add_argument("--retry-errors", action="store_true", help="Nur Fehler des letzten Manifests erneut abrufen; Index nicht neu durchsuchen")
    ap.add_argument("--retry-incomplete", action="store_true", help="Unvollständige Quellkarten erneut prüfen")
    ap.add_argument("--retry-no-recipe", action="store_true", help="Nach Parseränderungen Seiten ohne erkannte Rezeptkarte erneut prüfen")
    ap.add_argument("--refresh", action="store_true", help="Auch bereits erfasste Seiten neu laden")
    ap.add_argument("--workers", type=int, default=2, choices=range(1, 5), help="Parallele Abrufe (1–4); mindestens eine Sekunde Pause pro Arbeiter")
    args = ap.parse_args()
    BASE, PUBLISHER = SOURCES[args.source]
    OUTPUT = ROOT / "quellen" / args.source
    OUTPUT.mkdir(parents=True, exist_ok=True)
    if args.source in EXCLUDED:
        manifest = {"publisher": PUBLISHER, "sitemap_url": BASE + "robots.txt",
                    "scraped_at": datetime.now(timezone.utc).isoformat(), "completed": True,
                    "scope": EXCLUDED[args.source], "page_count": 0, "recipe_count": 0,
                    "source_status": "excluded", "exclusion_reason": EXCLUDED[args.source], "pages": []}
        (OUTPUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        print(EXCLUDED[args.source])
        return
    robots = RobotFileParser()
    try:
        robots.parse(download(BASE + "robots.txt").splitlines())
    except subprocess.CalledProcessError as exc:
        if "404" not in exc.stderr:
            raise
        robots.parse([])  # HTTP 404: keine robots.txt vorhanden.
    manifest_path = OUTPUT / "manifest.json"
    if args.retry_errors:
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
            if not robots.can_fetch(USER_AGENT, next_page):
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
        sitemap_url = BASE + SITEMAPS.get(args.source, "sitemap.xml")
        urls = sorted(set(discover(sitemap_url, robots)))
        if args.source in PATH_PREFIXES:
            urls = [url for url in urls if urlparse(url).path.startswith(PATH_PREFIXES[args.source])]
    old = {}
    manifest_path = OUTPUT / "manifest.json"
    if manifest_path.exists() and not args.refresh:
        old = {p["url"]: p for p in json.loads(manifest_path.read_text())["pages"]
               if p["status"] in {"recipe", "incomplete", "no_recipe", "disallowed", "restricted"}
               and not (args.retry_incomplete and p["status"] == "incomplete")
               and not (args.retry_no_recipe and p["status"] == "no_recipe")}

    def process(url):
        if not same_site(url) or not robots.can_fetch(USER_AGENT, url):
            return {"url": url, "status": "disallowed"}
        cached = old.get(url)
        if cached and (cached["status"] not in {"recipe", "incomplete"} or (OUTPUT / cached["file"]).exists()):
            return cached
        time.sleep(max(1, robots.crawl_delay(USER_AGENT) or 0))
        try:
            data = extract(download(url), url)
            if not data["recipes"]:
                if data["restricted_card_count"]:
                    return {"url": url, "status": "restricted", "reason": "Quellkarte als nicht frei zugänglich ausgezeichnet; keine Rezeptdaten gespeichert."}
                return {"url": url, "status": "no_recipe"}
            slug = urlparse(url).path.strip("/").replace("/", "--") or "index"
            if not re.fullmatch(r"[a-zA-Z0-9_-]+", slug) or len(slug) > 180:
                slug = re.sub(r"[^a-zA-Z0-9_-]+", "-", slug).strip("-")[:180] + "-" + hashlib.sha256(url.encode()).hexdigest()[:10]
            file = slug + ".json"
            (OUTPUT / file).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            status = "incomplete" if any(r["missing_fields"] for r in data["recipes"]) else "recipe"
            return {"url": url, "status": status, "file": file, "recipe_count": len(data["recipes"])}
        except (ValueError, OSError, subprocess.SubprocessError) as exc:
            detail = getattr(exc, "stderr", None) or str(exc)
            return {"url": url, "status": "error", "error": detail.strip()}

    pages = []
    def save_manifest(completed):
        manifest = {
            "publisher": PUBLISHER, "sitemap_url": sitemap_url,
            "scraped_at": datetime.now(timezone.utc).isoformat(), "completed": completed,
            "scope": "Öffentliche Rezeptkarten aus Sitemap bzw. vollständigem Rezeptindex; kein Paywall-/Buchinhalt.",
            "page_count": len(urls), "recipe_count": sum(p.get("recipe_count", 0) for p in pages),
            "pages": pages + [{"url": url, "status": "pending"} for url in urls[len(pages):]],
        }
        temporary = manifest_path.with_suffix(".tmp")
        temporary.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(manifest_path)
        return manifest
    save_manifest(False)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(process, urls):
            pages.append(result)
            if len(pages) % 20 == 0 or result["status"] == "error":
                print(f'{len(pages)}/{len(urls)} {result["status"]}: {result["url"]}', flush=True)
                save_manifest(False)
    manifest = save_manifest(True)
    errors = [p for p in pages if p["status"] == "error"]
    print(f'{manifest["recipe_count"]} Rezeptkarten; {len(errors)} Fehler. {manifest_path}')
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
