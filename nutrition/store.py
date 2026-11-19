"""Load attributed text snapshots into the cookbook's relational nutrition tables."""
from datetime import date
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate_snapshot(document):
    if document['version'] != 1:
        raise ValueError('Unsupported nutrition snapshot version')
    dataset = document['dataset']
    date.fromisoformat(dataset['retrieved_on'])
    if len(dataset['sha256']) != 64 or not dataset['source_url'].startswith('https://'):
        raise ValueError('Dataset requires checksum and HTTPS source')
    definitions = document['nutrients']
    if any(n['unit'] != n['code'].rsplit('_', 1)[-1] for n in definitions):
        raise ValueError('Nutrient code/unit differs')
    if len({n['code'] for n in definitions}) != len(definitions):
        raise ValueError('Duplicate nutrient code')
    seen = set()
    for food in document['foods']:
        if food['code'] in seen:
            raise ValueError('Duplicate food code')
        seen.add(food['code'])
        if len(food['facts']) != len(definitions):
            raise ValueError('Nutrient columns differ')
        for value, origin, reference, qualifier in food['facts']:
            if value is not None and (not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(value) or value < 0):
                raise ValueError('Invalid nutrient value')
            if qualifier and value is not None:
                raise ValueError('Qualified unknown must not be a numeric zero')
            for index, array in [(origin, document['origins']), (reference, document['references'])]:
                if index is not None and (not isinstance(index, int) or index < 0 or index >= len(array)):
                    raise ValueError('Unknown provenance index')
    if len(seen) != dataset['expected_food_count']:
        raise ValueError('Food count differs from source manifest')


def execute_document(connection, script, document):
    for statement in script.read_text().split(';'):
        if statement.strip():
            connection.execute(statement, {'document': json.dumps(document, ensure_ascii=False, allow_nan=False)})


def load_nutrition(connection, root=ROOT):
    """Caller owns the transaction; all failures roll back before publication."""
    for path in sorted((root / 'nutrition/data').glob('*.json')):
        document = json.loads(path.read_text())
        validate_snapshot(document)
        d = document['dataset']
        connection.execute('INSERT INTO nutrition_datasets VALUES (?,?,?,?,?,?,?,?)', tuple(d[k] for k in ('id','publisher','version','source_url','license','citation','retrieved_on','sha256')))
        connection.executemany('INSERT OR IGNORE INTO nutrition_nutrients VALUES (?,?,?,?)', [tuple(n[k] for k in ('code','name','unit','source_code')) for n in document['nutrients']])
        connection.executemany('INSERT INTO nutrition_foods VALUES (?,?,?,?,?,?)', [(d['id']+':'+f['code'],d['id'],f['code'],f['name'],f['name_en'],d['source_url']) for f in document['foods']])
        def facts():
            for food in document['foods']:
                for nutrient, (amount, origin, ref, qualifier) in zip(document['nutrients'],food['facts']):
                    yield (d['id']+':'+food['code'],nutrient['code'],amount,document['origins'][origin] if origin is not None else None,document['references'][ref] if ref is not None else None,qualifier,nutrient['source_code'])
        connection.executemany('INSERT INTO nutrition_facts VALUES (?,?,?,?,?,?,?)',facts())
    matches = json.loads((root / 'nutrition/matches.json').read_text())
    if matches['version'] != 1:
        raise ValueError('Unsupported match version')
    for item in matches['matches'] + matches['weights']:
        date.fromisoformat(item['reviewed_on'])
        if not item['note'].strip():
            raise ValueError('Mappings and weights require an explanation')
    for match in matches['matches']:
        name = connection.execute('SELECT name FROM ingredients WHERE id=?', (match['ingredient_id'],)).fetchone()
        if not name or name[0] != match['ingredient_name']:
            raise ValueError(f'Ingredient ID/name changed: {match}')
    for weight in matches['weights']:
        if not weight['source_url'].startswith('https://') or not math.isfinite(weight['edible_grams']) or weight['edible_grams'] < 0:
            raise ValueError('Weights need a source and nonnegative grams')
    execute_document(connection, root / 'nutrition/load-matches.sql', matches)
