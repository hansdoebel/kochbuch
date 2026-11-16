#!/usr/bin/env python3
"""Prüft die archivierten Quellen ohne Netzwerkzugriff."""

import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1] / "quellen"
HOSTS = {"rainbowplantlife": "rainbowplantlife.com", "babish": "babi.sh", "joshuaweissman": "joshuaweissman.com"}


def check():
    for source, host in HOSTS.items():
        directory = ROOT / source
        manifest = json.loads((directory / "manifest.json").read_text())
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
