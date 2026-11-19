import io
import unittest
import zipfile
from nutrition.import_bls import number, xlsx_rows, convert


class NutritionImportTests(unittest.TestCase):
    def test_trace_and_detection_limits_are_not_zero(self):
        self.assertEqual(number('0'), 0)
        for marker in ('TR', '<LOD', '<LOQ', '<LOD or <LOQ', '-', None):
            self.assertIsNone(number(marker))
        for invalid in ('NaN', 'inf', '-1', 'unexpected'):
            with self.assertRaises(ValueError):
                number(invalid)

    def test_checksum_mismatch_stops_import(self):
        with self.assertRaisesRegex(ValueError, 'SHA-256'):
            convert(b'changed download', {'sha256': '0'*64})

    def test_sparse_xlsx_cells_and_shared_strings(self):
        ns='http://schemas.openxmlformats.org/spreadsheetml/2006/main'
        raw=io.BytesIO()
        with zipfile.ZipFile(raw, 'w') as z:
            z.writestr('xl/sharedStrings.xml', f'<sst xmlns="{ns}"><si><t>Food</t></si></sst>')
            z.writestr('xl/worksheets/sheet1.xml', f'<worksheet xmlns="{ns}"><sheetData><row r="1"><c r="A1" t="s"><v>0</v></c><c r="C1"><v>12.5</v></c></row></sheetData></worksheet>')
        self.assertEqual(list(xlsx_rows(raw.getvalue())), [{'A':'Food','C':'12.5'}])
