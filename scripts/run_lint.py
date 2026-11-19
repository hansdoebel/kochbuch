#!/usr/bin/env python3
"""Führt die unabhängigen Lint-Prüfungen parallel aus; jeder Fehler zählt."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CHECKS = {
    "Nährwertdaten": ["python3", "nutrition/check.py"],
    "Markdown": ["npm", "run", "lint:markdown"],
    "Rezeptdaten": ["python3", "scripts/lint_recipes.py"],
    "Quellenarchiv": ["python3", "scripts/check_sources.py"],
}


def run(name, command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    return name, result


def main():
    failed = False
    with ThreadPoolExecutor(max_workers=len(CHECKS)) as pool:
        futures = [pool.submit(run, name, command) for name, command in CHECKS.items()]
        for future in as_completed(futures):
            name, result = future.result()
            print(f"{name}: {'FEHLER' if result.returncode else 'OK'}", flush=True)
            print(result.stdout + result.stderr, end="", flush=True)
            failed = failed or result.returncode != 0
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
