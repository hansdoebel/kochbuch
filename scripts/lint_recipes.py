#!/usr/bin/env python3
"""Prüft das flache Rezeptformat und den SQL-Abgleich, ohne Agentenanweisungen."""

from pathlib import Path
import re
import sqlite3
import sys
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "db"))
import build_db

KEYS = {"title", "slug", "servings", "servings_label", "prep_minutes", "cook_minutes", "source", "tags"}
HEADINGS = ["## Zutaten", "## Zubereitung", "## Tipps"]


def lint_text(text, slug):
    errors = []
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug):
        errors.append("Dateiname muss ein kleingeschriebener ASCII-Slug sein")
    match = re.match(r"\A---\n(.*?)\n---\n(.*)\Z", text, re.S)
    if not match:
        return errors + ["Flaches YAML-Frontmatter mit --- fehlt"]
    fields = {}
    for line in match[1].splitlines():
        key, separator, value = line.partition(": ")
        if not separator or not value.strip() or key in fields:
            errors.append(f"Ungültiges oder doppeltes Frontmatter-Feld: {line}")
        fields[key] = value.strip()
        # Das unterstützte Importformat verwendet ausschließlich einfache,
        # unquotierte Skalare. Verschachteltes YAML ist hier nicht zulässig.
        if value.startswith(("[", "{", "|", ">", "&", "*", "!", "\"", "'")) or ": " in value or " #" in value:
            errors.append(f"{key}: nur einfacher unquotierter Skalar erlaubt")
    if fields.keys() != KEYS:
        errors.append("Frontmatter braucht exakt: " + ", ".join(sorted(KEYS)))
    for key in ("servings", "prep_minutes", "cook_minutes"):
        value = fields.get(key, "")
        if not re.fullmatch(r"\d+", value) or (key == "servings" and int(value) == 0):
            errors.append(f"{key}: ganze {'positive' if key == 'servings' else 'nicht negative'} Zahl erforderlich")
    if fields.get("slug") != slug:
        errors.append("Frontmatter-Slug und Dateiname weichen ab")
    body = match[2]
    if not body.lstrip().startswith("# " + fields.get("title", "") + "\n"):
        errors.append("Sichtbarer H1-Titel und title müssen übereinstimmen")
    headings = re.findall(r"^## .*", body, re.M)
    if headings != HEADINGS:
        return errors + ["Abschnitte müssen genau Zutaten, Zubereitung, Tipps in dieser Reihenfolge sein"]
    source = fields.get("source", "")
    intro = body.split("## Zutaten", 1)[0]
    urls = re.findall(r"https?://[^\s]+", source)
    if not source:
        errors.append("Quelle fehlt")
    elif urls:
        if not source.split("http", 1)[0].strip(" –-|"):
            errors.append("source braucht zusätzlich zur URL eine Urheber-/Herkunftsangabe")
        for url in urls:
            if not url.startswith("https://") or f"]({url})" not in intro:
                errors.append("Originalquelle braucht HTTPS und einen sichtbaren Link unter dem Titel")
            if urlparse(url).path in {"", "/", "/recipes", "/recipes/"}:
                errors.append("Startseiten oder Rezeptindizes sind keine Original-Rezeptquelle")
    elif not re.match(r"^(Eigenes Rezept von |Foto von |Familienrezept von )", source) and not (source == "Demel via Kurier TV" and slug == "kaiserschmarrn"):
        # Belegte Transkription im bestehenden Kaiserschmarrn; keine URL erfinden.
        errors.append("Online-Quelle braucht eine direkte Rezept-URL; nicht öffentliche Herkunft ausdrücklich kennzeichnen")
    if "Quelle:" not in intro:
        errors.append("Sichtbare Quellenangabe unter dem Titel fehlt")
    tags = fields.get("tags", "").split(",")
    if any(not tag.strip() for tag in tags) or len({tag.strip() for tag in tags}) != len(tags):
        errors.append("Tags müssen ein eindeutiger, nicht leerer Kommastring sein")
    ingredients = body.split("## Zutaten", 1)[1].split("## Zubereitung", 1)[0]
    group = False
    for line in ingredients.splitlines():
        if line.startswith("### "):
            group = True
        elif line.startswith("- ") and not group:
            errors.append("Zutaten brauchen eine ###-Gruppe")
    if not re.search(r"^- \S", ingredients, re.M):
        errors.append("Zutatenliste fehlt")
    if re.search(r"\b(?:cups?|ounces?|oz|pounds?|lbs?|inches|inch|tablespoons?|teaspoons?|tbsp|tsp)\b|°F", ingredients, re.I):
        # Erklärte Originalangaben in einer Umrechnung sind erlaubt.
        for line in ingredients.splitlines():
            if re.search(r"\b(?:cups?|ounces?|oz|pounds?|lbs?|inches|inch|tablespoons?|teaspoons?|tbsp|tsp)\b|°F", line, re.I) and "umgerechnet aus" not in line:
                errors.append("Nicht metrische Zutatenmenge: " + line)
    steps = body.split("## Zubereitung", 1)[1].split("## Tipps", 1)[0]
    numbers = [int(n) for n in re.findall(r"^(\d+)\. ", steps, re.M)]
    if not numbers or numbers != list(range(1, len(numbers) + 1)):
        errors.append("Zubereitung braucht fortlaufend nummerierte Schritte ab 1")
    tips = body.split("## Tipps", 1)[1]
    if not re.search(r"^- \S", tips, re.M):
        errors.append("Tipps brauchen mindestens einen Aufzählungspunkt")
    if re.search(r"!\[|<[/!a-zA-Z]|\[\[|\[\^|^- \[[ xX]\]", body, re.M):
        errors.append("Bilder, HTML, Wiki-Links, Fußnoten und Aufgabenlisten sind nicht erlaubt")
    return errors


def main():
    errors = []
    paths = sorted((ROOT / "rezepte").glob("*.md"))
    if not paths:
        errors.append("Keine Rezeptdateien gefunden")
    for path in paths:
        errors.extend(f"{path.relative_to(ROOT)}: {error}" for error in lint_text(path.read_text(), path.stem))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        raise SystemExit(1)
    with sqlite3.connect(":memory:") as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        conn.executescript(build_db.SCHEMA.read_text())
        conn.executescript(build_db.SEED.read_text())
        build_db.check_recipe_files(conn)
        if list(conn.execute("PRAGMA foreign_key_check")):
            raise SystemExit("Fremdschlüssel im Rezept-Seed verletzt")
    print(f"{len(paths)} Rezepte: Format, Quellen und Datenbank stimmen überein.")


if __name__ == "__main__":
    main()
