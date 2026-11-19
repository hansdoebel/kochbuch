#!/usr/bin/env python3
"""Reproducible, dependency-free BLS XLSX -> compact, attributed JSON snapshot."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import date
import hashlib
import html
import io
import json
import math
from pathlib import Path
import re
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
# Stable source codes, not spreadsheet column positions. Folate is food folate,
# not folate equivalents; carbohydrate is available carbohydrate (EU definition).
NUTRIENTS = {
    'ENERCC': ('energy_kcal', 'kcal'), 'PROT625': ('protein_g', 'g'),
    'CHO': ('carbs_g', 'g'), 'FIBT': ('fiber_g', 'g'), 'FAT': ('fat_g', 'g'),
    'SUGAR': ('sugar_g', 'g'), 'FASAT': ('saturated_fat_g', 'g'),
    'NA': ('sodium_mg', 'mg'), 'CA': ('calcium_mg', 'mg'), 'FE': ('iron_mg', 'mg'),
    'MG': ('magnesium_mg', 'mg'), 'K': ('potassium_mg', 'mg'), 'ZN': ('zinc_mg', 'mg'),
    'VITB12': ('vitamin_b12_ug', 'ug'), 'VITD': ('vitamin_d_ug', 'ug'),
    'FOLFD': ('folate_ug', 'ug'), 'ID': ('iodine_ug', 'ug'),
}


def xlsx_rows(raw):
    """Read sparse numeric/string XLSX cells without third-party packages."""
    with zipfile.ZipFile(io.BytesIO(raw)) as book:
        strings = []
        if 'xl/sharedStrings.xml' in book.namelist():
            strings = [''.join(s.itertext()) for s in ET.fromstring(book.read('xl/sharedStrings.xml'))]
        with book.open('xl/worksheets/sheet1.xml') as sheet:
            for _, element in ET.iterparse(sheet, events=('end',)):
                if element.tag != NS + 'row':
                    continue
                row = {}
                for cell in element:
                    value = cell.find(NS + 'v')
                    value = value.text if value is not None else ''
                    if cell.get('t') == 's':
                        value = strings[int(value)]
                    elif cell.get('t') == 'inlineStr':
                        value = ''.join(cell.itertext())
                    row[re.sub(r'\d+', '', cell.get('r'))] = value
                yield row
                element.clear()


def number(raw):
    if raw in ('', '-', 'NA', 'N/A', '<LOQ', '<LOD', '<LOD or <LOQ', 'TR', None):
        return None
    value = float(raw)
    if not math.isfinite(value) or value < 0:
        raise ValueError(f'Invalid nutrient amount: {raw}')
    return value


def convert(archive, spec):
    digest = hashlib.sha256(archive).hexdigest()
    if digest != spec['sha256']:
        raise ValueError(f'Archive SHA-256 differs: {digest}; review a new release explicitly')
    with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
        path = next(n for n in bundle.namelist() if n.endswith('BLS_4_0_Daten_2025_DE.xlsx'))
        rows = xlsx_rows(bundle.read(path))
        header = next(rows)
        cols = list(header)
        definitions, positions = [], []
        for source_code, (code, unit) in NUTRIENTS.items():
            col = next(c for c, title in header.items() if title.startswith(source_code + ' ') and '/100g]' in title)
            title = header[col]
            source_unit = re.search(r'\[([^/]+)/100g\]', title).group(1).replace('µg', 'ug')
            if source_unit != unit:
                raise ValueError(f'Unit changed for {source_code}: {source_unit}')
            definitions.append({'code': code, 'name': title.split(' ', 1)[1].split(' [')[0], 'unit': unit, 'source_code': source_code})
            index = cols.index(col)
            positions.append((col, cols[index + 1], cols[index + 2]))
        origins, references, foods = [], [], []
        def intern(items, text):
            if not text or text == '-':
                return None
            if text not in items:
                items.append(text)
            return items.index(text)
        seen = set()
        for row in rows:
            code = row.get('A', '')
            if not code:
                continue
            if not re.fullmatch(r'[A-Z][A-Z0-9]{6}', code) or code in seen:
                raise ValueError(f'Invalid or duplicate BLS food code: {code}')
            seen.add(code)
            facts = []
            for col, origin, reference in positions:
                raw = row.get(col)
                value = number(raw)
                facts.append([value, intern(origins, row.get(origin)), intern(references, row.get(reference)), raw if value is None else None])
            foods.append({'code': code, 'name': row['B'], 'name_en': row.get('C'), 'facts': facts})
    if len(foods) != spec['expected_food_count']:
        raise ValueError(f'Food count changed: {len(foods)}')
    return {'version': 1, 'dataset': spec, 'nutrients': definitions, 'origins': origins, 'references': references, 'foods': sorted(foods, key=lambda f: f['code'])}


def download(spec, destination):
    """Bounded ranged download; truncated responses never become valid inputs."""
    size = spec['archive_bytes']
    step = 262144
    def chunk(start):
        end = min(size - 1, start + step - 1)
        for attempt in range(3):
            try:
                request = urllib.request.Request(spec['download_url'], headers={'Range': f'bytes={start}-{end}'})
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = response.read(step + 1)
                    if response.status != 206 or response.headers.get('Content-Range') != f'bytes {start}-{end}/{size}' or len(data) != end - start + 1:
                        raise ValueError('Incomplete or unexpected BLS download response')
                return data
            except (OSError, ValueError):
                if attempt == 2:
                    raise
    with ThreadPoolExecutor(max_workers=4) as pool:
        raw = b''.join(pool.map(chunk, range(0, size, step)))
    if hashlib.sha256(raw).hexdigest() != spec['sha256']:
        raise ValueError('Download checksum differs; existing snapshot has not been changed')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(raw)
    return raw


def render(snapshot):
    # One record per line keeps the committed text snapshot small and diffable.
    encode = lambda obj: json.dumps(obj, ensure_ascii=False, separators=(',', ':'), allow_nan=False)
    head = {key: value for key, value in snapshot.items() if key != 'foods'}
    return encode(head)[:-1] + ',"foods":[\n' + ',\n'.join(encode(f) for f in snapshot['foods']) + '\n]}\n'


def check_upstream(spec):
    with urllib.request.urlopen(spec['source_url'], timeout=30) as response:
        page = html.unescape(response.read(1_000_000).decode('utf-8'))
    files = set(re.findall(r'BLS_[0-9_]+_DE\.zip', page))
    expected = spec['download_url'].rsplit('/', 1)[-1]
    if files != {expected}:
        raise ValueError(f'BLS download listing changed: {sorted(files)}; review the new source release')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive', type=Path, help='existing official ZIP (offline)')
    parser.add_argument('--download', action='store_true')
    parser.add_argument('--check-upstream', action='store_true', help='also detect a newly advertised official release')
    parser.add_argument('--check', action='store_true', help='reproduce and compare instead of replacing')
    args = parser.parse_args()
    spec = json.loads((ROOT / 'nutrition/bls-source.json').read_text())
    date.fromisoformat(spec['retrieved_on'])
    if args.check_upstream:
        check_upstream(spec)
    archive = args.archive or ROOT / '.cache/nutrition/BLS_4_0_2025_DE.zip'
    raw = download(spec, archive) if args.download else archive.read_bytes()
    output = render(convert(raw, spec))
    destination = ROOT / 'nutrition/data/bls-4.0.json'
    if args.check:
        if destination.read_text() != output:
            raise SystemExit('Snapshot differs from the pinned official archive')
        print('BLS snapshot reproducible')
    else:
        temporary = destination.with_suffix('.tmp')
        temporary.write_text(output, encoding='utf-8')
        temporary.replace(destination)
        lock = ROOT / 'nutrition/snapshot-lock.json'
        entries = json.loads(lock.read_text()) if lock.exists() else {}
        entries[str(destination.relative_to(ROOT))] = hashlib.sha256(output.encode('utf-8')).hexdigest()
        lock.write_text(json.dumps(entries, indent=2) + '\n')
        print(f'Imported {spec["expected_food_count"]} BLS foods into {destination}')


if __name__ == '__main__':
    main()
