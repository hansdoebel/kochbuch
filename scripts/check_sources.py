#!/usr/bin/env python3
"""Prüft die archivierten Quellen ohne Netzwerkzugriff."""

import json
import hashlib
from ndr_source import read_selection
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1] / "quellen"
HOSTS = {"ndr": "ndr.de", "rainbowplantlife": "rainbowplantlife.com", "babish": "babi.sh", "joshuaweissman": "joshuaweissman.com"}


def check():
    for source, host in HOSTS.items():
        directory = ROOT / source
        manifest = json.loads((directory / "manifest.json").read_text())
        selected = None
        if source == 'ndr':
            selection = read_selection(directory/'selection.json')
            selected = {item['url']:item for item in selection['recipes']}
            assert {p['url'] for p in manifest['pages']} == set(selected), 'NDR selection differs from manifest'
            assert manifest['selection_sha256'] == hashlib.sha256((directory/'selection.json').read_bytes()).hexdigest()
            assert manifest.get('completed') is True
        count = 0
        urls = set()
        errors = []
        for page in manifest["pages"]:
            assert page["url"] not in urls, page["url"]
            urls.add(page["url"])
            status = page["status"]
            if status == "error":
                errors.append(page["url"])
                continue
            assert status in {"recipe", "incomplete", "no_recipe", "disallowed"}, status
            if status not in {"recipe", "incomplete"}:
                continue
            assert Path(page["file"]).name == page["file"], page["file"]
            data = json.loads((directory / page["file"]).read_text())
            if source == 'ndr':
                assert page['sha256'] == hashlib.sha256((directory/page['file']).read_bytes()).hexdigest()
                assert data['source_url'] == page['url']
                assert data['reviewed_source_digest'] == selected[page['url']]['source_digest']
                assert data['recipes'][0]['instructions'] == selected[page['url']]['editorial_instructions']
                assert data['recipes'][0]['instruction_representation'] == 'editorial_summary'
                assert data['recipes'][0]['publisher_nutrition']['origin'] == 'publisher_estimate'

            url = urlparse(data["source_url"])
            assert url.scheme == "https" and url.netloc.removeprefix("www.") == host, data["source_url"]
            assert len(data["recipes"]) == page["recipe_count"] > 0, page["url"]
            for recipe in data["recipes"]:
                assert recipe["source_url"] == data["source_url"], page["url"]
                missing = [key for key in ("ingredients", "instructions", "authors", "name") if not recipe[key]]
                assert missing == recipe.get("missing_fields", []), page["url"]
                assert (not missing) or status == "incomplete", page["url"]
                assert all(isinstance(x, str) and x.strip() for x in recipe["ingredients"] + recipe["instructions"]), page["url"]
            count += len(data["recipes"])
        assert manifest["page_count"] == len(urls), source
        assert manifest["recipe_count"] == count, source
        print(f"{source}: {count} Rezeptkarten aus {len(urls)} geprüften Seiten, {len(errors)} Fehler")
        if errors:
            raise SystemExit("Noch fehlgeschlagene Seiten: " + ", ".join(errors))


if __name__ == "__main__":
    check()
