#!/usr/bin/env python3
"""Validate committed nutrition data and report the work with most reuse potential."""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from nutrition.store import load_nutrition


def build_report():
    db = sqlite3.connect(':memory:')
    db.row_factory = sqlite3.Row
    db.execute('PRAGMA foreign_keys=ON')
    db.executescript((ROOT / 'db/schema.sql').read_text())
    db.executescript((ROOT / 'db/seed.sql').read_text())
    load_nutrition(db)
    aliases = json.loads((ROOT / 'nutrition/aliases.json').read_text())
    seen = set()
    for item in aliases['aliases']:
        if not db.execute('SELECT id FROM nutrition_foods WHERE id=?', (item['food_id'],)).fetchone():
            raise ValueError('Alias references unknown food')
        for name in item['names']:
            key = ' '.join(name.casefold().split())
            if key in seen:
                raise ValueError('Duplicate food alias')
            seen.add(key)
    if list(db.execute('PRAGMA foreign_key_check')):
        raise ValueError('Nutrition foreign key failure')
    foods = list(db.execute('SELECT id,name FROM nutrition_foods'))
    unresolved = []
    for row in db.execute('''SELECT i.id,i.name,COUNT(DISTINCT ri.recipe_id) AS recipe_count
        FROM ingredients i JOIN recipe_ingredients ri ON ri.ingredient_id=i.id
        LEFT JOIN ingredient_nutrition_matches m ON m.ingredient_id=i.id
        WHERE m.food_id IS NULL GROUP BY i.id,i.name ORDER BY recipe_count DESC,i.name'''):
        candidates = sorted(foods, key=lambda f: difflib.SequenceMatcher(None,row['name'].casefold(),f['name'].casefold()).ratio(), reverse=True)[:3]
        unresolved.append({**dict(row), 'review_candidates':[dict(f) for f in candidates]})
    report = {
        'food_count': db.execute('SELECT COUNT(*) FROM nutrition_foods').fetchone()[0],
        'fact_count': db.execute('SELECT COUNT(*) FROM nutrition_facts').fetchone()[0],
        'matched_ingredients': db.execute('SELECT COUNT(*) FROM ingredient_nutrition_matches').fetchone()[0],
        'unmapped_ingredients': unresolved,
        'unknown_edible_weights': [dict(r) for r in db.execute('''SELECT l.recipe_ingredient_id,r.slug,l.ingredient_name
          FROM v_recipe_nutrition_lines l JOIN recipes r ON r.id=l.recipe_id WHERE l.edible_grams IS NULL AND l.optional=0 ORDER BY r.slug,l.recipe_ingredient_id''')],
        'note': 'Candidate similarity is only a review aid. No fuzzy match or weight is applied automatically.',
    }
    db.close()
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    lock = json.loads((ROOT / 'nutrition/snapshot-lock.json').read_text())
    for file, checksum in lock.items():
        if hashlib.sha256((ROOT / file).read_bytes()).hexdigest() != checksum:
            raise SystemExit('Nutrition snapshot checksum differs: '+file)
    snapshot = json.loads((ROOT / 'nutrition/data/bls-4.0.json').read_text())
    if snapshot['dataset'] != json.loads((ROOT / 'nutrition/bls-source.json').read_text()):
        raise SystemExit('BLS manifest differs from snapshot')
    report = build_report()
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print(f"Nutrition OK: {report['food_count']} foods, {report['fact_count']} facts, {report['matched_ingredients']} ingredient matches; {len(report['unmapped_ingredients'])} matches and {len(report['unknown_edible_weights'])} weights pending review.")


if __name__ == '__main__':
    main()
