#!/usr/bin/env python3
"""Erzeugt db/kochbuch.sqlite aus schema.sql und seed.sql und druckt eine Einkaufsliste.

Aufruf vom Repo aus:

  python3 db/build_db.py
  python3 db/build_db.py 2026-11-16 2026-11-22
  python3 db/build_db.py 2026-11-16 2026-11-22 --ohne-vorrat
  python3 db/build_db.py --check
"""

import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "kochbuch.sqlite"
SCHEMA = ROOT / "schema.sql"
SEED = ROOT / "seed.sql"
QUERY = ROOT / "shopping_list.sql"

EXAMPLE_FROM = "2026-11-16"
EXAMPLE_TO = "2026-11-22"

# Kaiserschmarrn für 2 Personen, Zucker aus Teig und Karamell zusammengezogen.
EXPECTED = [
    ("Obst & Gemüse", "Zitrone", None, 0.5, "Stk", 0.5, "Stk", 0),
    ("Milchprodukte & Eier", "Butter", None, 60, "g", 60, "g", 0),
    ("Milchprodukte & Eier", "Eier", "Gr. M", 4, "Stk", 4, "Stk", 0),
    ("Milchprodukte & Eier", "Milch", None, 200, "g", 200, "g", 0),
    ("Grundnahrungsmittel", "Feinkristallzucker", None, 80, "g", 80, "g", 1),
    ("Grundnahrungsmittel", "Mehl glatt", None, 120, "g", 120, "g", 1),
    ("Grundnahrungsmittel", "Staubzucker", None, 10, "g", 10, "g", 1),
    ("Gewürze & Backzutaten", "Rosinen", None, 30, "g", 30, "g", 0),
    ("Gewürze & Backzutaten", "Salz", None, 1, "Prise", None, None, 1),
    ("Gewürze & Backzutaten", "Vanillezucker", None, 1, "Pkt", 8, "g", 0),
    ("Konserven & Gläser", "Demel's Zwetschkenröster", None, 1, "Glas", None, None, 0),
    ("Getränke", "Rum", None, 10, "g", 10, "g", 0),
]


def build() -> sqlite3.Connection:
    for extra in ("", "-journal", "-wal", "-shm"):
        path = Path(str(DB_PATH) + extra) if extra else DB_PATH
        if path.exists():
            path.unlink()
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA.read_text(encoding="utf-8"))
    conn.executescript(SEED.read_text(encoding="utf-8"))
    conn.commit()
    return conn


def load_query(date_from: str, date_to: str, ohne_vorrat: bool) -> str:
    for label, value in (("von", date_from), ("bis", date_to)):
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
            raise SystemExit(f"Datum {label} als JJJJ-MM-TT angeben, nicht {value!r}.")
    sql = QUERY.read_text(encoding="utf-8")
    old = f"WHERE plan_date BETWEEN '{EXAMPLE_FROM}' AND '{EXAMPLE_TO}'"
    new = f"WHERE plan_date BETWEEN '{date_from}' AND '{date_to}'"
    if old not in sql:
        raise SystemExit(f"{QUERY.name} enthält die Beispiel-Zeitspanne nicht mehr.")
    sql = sql.replace(old, new, 1)
    if ohne_vorrat:
        needle = "-- AND pantry_staple = 0"
        if needle not in sql:
            raise SystemExit(f"{QUERY.name} enthält den Schalter für den Vorrat nicht mehr.")
        sql = sql.replace(needle, "AND pantry_staple = 0", 1)
    return sql


def fetch(conn: sqlite3.Connection, date_from: str, date_to: str, ohne_vorrat: bool):
    return list(conn.execute(load_query(date_from, date_to, ohne_vorrat)))


def format_menge(value) -> str:
    if value is None:
        return ""
    number = float(value)
    if abs(number - round(number)) < 1e-9:
        text = str(int(round(number)))
    else:
        text = f"{number:.2f}".rstrip("0").rstrip(".")
    return text.replace(".", ",")


def print_list(rows, date_from: str, date_to: str, ohne_vorrat: bool) -> None:
    header = f"Einkaufsliste {date_from} – {date_to}"
    if ohne_vorrat:
        header += " (ohne Vorrat)"
    print(header)
    print(f"Datenbank: {DB_PATH}")
    if not rows:
        print("\nKeine Einträge in diesem Zeitraum.")
        return
    current = None
    showed_basis = False
    for row in rows:
        if row["kategorie"] != current:
            current = row["kategorie"]
            print(f"\n{current}")
        name = row["zutat"]
        if row["variante"]:
            name = f"{name} ({row['variante']})"
        menge = format_menge(row["menge"])
        einheit = row["einheit"] or ""
        line = f"  {menge} {einheit}  {name}".rstrip()
        if row["mengentext"]:
            line += f" ({row['mengentext']})"
        basis = row["basis_einheit"]
        if basis and basis != row["einheit"] and row["basis_menge"] is not None:
            line += f"  [Basis {format_menge(row['basis_menge'])} {basis}]"
            showed_basis = True
        print(line)
    if showed_basis:
        print(
            "\nBasis-Angaben sind Umrechnungen (1 Pkt. Vanillezucker = 8 g, übliches Packerl), nicht die Menge aus der Quelle."
        )


def near(actual, expected) -> bool:
    if expected is None:
        return actual is None
    if actual is None:
        return False
    return abs(float(actual) - float(expected)) < 1e-6


def assert_rows(rows, expected, label: str) -> None:
    got = [
        (
            row["kategorie"],
            row["zutat"],
            row["variante"],
            row["menge"],
            row["einheit"],
            row["basis_menge"],
            row["basis_einheit"],
            row["vorrat"],
        )
        for row in rows
    ]
    if len(got) != len(expected):
        raise SystemExit(f"{label}: {len(got)} Zeilen, erwartet {len(expected)}.\n{got}")
    for actual, want in zip(got, expected):
        text_ok = actual[0] == want[0] and actual[1] == want[1] and actual[2] == want[2]
        text_ok = text_ok and actual[4] == want[4] and actual[6] == want[6] and actual[7] == want[7]
        if not (text_ok and near(actual[3], want[3]) and near(actual[5], want[5])):
            raise SystemExit(f"{label}: abweichende Zeile.\n  ist:    {actual}\n  soll:   {want}")


def check(conn: sqlite3.Connection) -> None:
    fk = list(conn.execute("PRAGMA foreign_key_check"))
    if fk:
        raise SystemExit(f"Fremdschlüssel verletzt: {fk}")
    check_recipe_files(conn)
    count = conn.execute("SELECT COUNT(*) AS n FROM recipe_ingredients WHERE recipe_id = 1").fetchone()["n"]
    if count != 13:
        raise SystemExit(f"Kaiserschmarrn hat {count} Zutatenzeilen, erwartet 13.")
    lemon = conn.execute(
        """
        SELECT amount_text, preparation
        FROM recipe_ingredients
        WHERE id = 6
        """
    ).fetchone()
    if lemon["amount_text"] != "geriebene Schale von einer halben Zitrone":
        raise SystemExit("Zitronenzeile hat den Quelltext nicht in amount_text.")
    if lemon["preparation"] != "geriebene Schale":
        raise SystemExit("Zitronenzeile ohne preparation geriebene Schale.")

    rows = fetch(conn, EXAMPLE_FROM, EXAMPLE_TO, False)
    assert_rows(rows, EXPECTED, "volle Liste")
    print_list(rows, EXAMPLE_FROM, EXAMPLE_TO, False)

    ohne = fetch(conn, EXAMPLE_FROM, EXAMPLE_TO, True)
    expected_ohne = [row for row in EXPECTED if row[7] == 0]
    assert_rows(ohne, expected_ohne, "ohne Vorrat")

    # Skalierung: 4 Portionen sind das Doppelte, danach zurückrollen.
    conn.execute("BEGIN")
    conn.execute(
        """
        INSERT INTO meal_plan_entries (
          id, meal_plan_id, plan_date, meal_slot, recipe_id, servings, notes
        ) VALUES (2, 1, '2026-11-17', 'Abendessen', 1, 4, NULL)
        """
    )
    doubled = [
        (cat, name, variant, qty * 2, unit, None if base is None else base * 2, base_unit, pantry)
        for cat, name, variant, qty, unit, base, base_unit, pantry in EXPECTED
    ]
    scaled = fetch(conn, "2026-11-17", "2026-11-17", False)
    assert_rows(scaled, doubled, "4 Portionen")
    conn.execute("ROLLBACK")
    left = conn.execute("SELECT COUNT(*) AS n FROM meal_plan_entries").fetchone()["n"]
    if left != 1:
        raise SystemExit("Prüf-Eintrag für 4 Portionen ist in der Datenbank hängen geblieben.")
    print("\nPrüfung in Ordnung: Mengen, Summe des Zuckers (80 g), Vorrat, Skalierung auf 4 Portionen.")


def check_recipe_files(conn: sqlite3.Connection, directory: Path | None = None) -> None:
    """Alle Rezepte prüfen; das Beispielrezept darf weitere Rezepte nicht blockieren."""
    directory = directory or ROOT.parent / "rezepte"
    recipes = {row["slug"]: row for row in conn.execute("SELECT * FROM recipes")}
    files = {path.stem: path for path in directory.glob("*.md")}
    if files.keys() != recipes.keys():
        raise SystemExit("Markdown-Dateien und recipes.slug stimmen nicht überein.")
    for slug, path in files.items():
        text = path.read_text(encoding="utf-8")
        parts = text.split("---", 2)
        if len(parts) != 3 or parts[0].strip():
            raise SystemExit(f"{slug}: YAML-Frontmatter fehlt.")
        fields = dict(line.split(": ", 1) for line in parts[1].strip().splitlines())
        recipe = recipes[slug]
        for key in ("title", "slug", "servings", "servings_label", "prep_minutes", "cook_minutes", "source"):
            if fields.get(key) != str(recipe[key]):
                raise SystemExit(f"{slug}: {key} weicht zwischen Markdown und Datenbank ab.")
        source = fields.get("source", "").strip()
        if not source:
            raise SystemExit(f"{slug}: Quelle fehlt.")
        for url in re.findall(r"https?://\S+", source):
            if f"]({url})" not in parts[2]:
                raise SystemExit(f"{slug}: sichtbarer Link zur Originalquelle fehlt.")
        tags = {row[0] for row in conn.execute(
            "SELECT t.name FROM tags t JOIN recipe_tags rt ON rt.tag_id = t.id WHERE rt.recipe_id = ?",
            (recipe["id"],),
        )}
        if tags != {tag.strip() for tag in fields.get("tags", "").split(",")}:
            raise SystemExit(f"{slug}: Tags weichen ab.")
        ingredients_text = parts[2].split("## Zutaten", 1)[1].split("## Zubereitung", 1)[0]
        lines, group = [], None
        for line in ingredients_text.splitlines():
            if line.startswith("### "):
                group = line[4:]
            elif line.startswith("- "):
                lines.append((group, line[2:]))
        rows = list(conn.execute(
            "SELECT ingredient_group, amount_text FROM recipe_ingredients WHERE recipe_id = ? ORDER BY sort_order",
            (recipe["id"],),
        ))
        if len(lines) != len(rows) or any(g != row[0] for (g, _), row in zip(lines, rows)):
            raise SystemExit(f"{slug}: Zutatenzahl oder Gruppen weichen ab.")
        # Neue Importe behalten jede übersetzte Mengenzeile zusätzlich in amount_text.
        if "https://rainbowplantlife.com/" in source and any(line != row[1] for (_, line), row in zip(lines, rows)):
            raise SystemExit(f"{slug}: Zutatenzeilen weichen zwischen Markdown und Datenbank ab.")


def main(argv: list[str]) -> None:
    flags = {arg for arg in argv if arg.startswith("--")}
    dates = [arg for arg in argv if not arg.startswith("--")]
    known = {"--check", "--ohne-vorrat"}
    unknown = flags - known
    if unknown:
        raise SystemExit(f"Unbekannter Schalter: {', '.join(sorted(unknown))}")
    if len(dates) > 2:
        raise SystemExit("Aufruf: python3 db/build_db.py [von bis] [--ohne-vorrat] [--check]")

    conn = build()
    try:
        if "--check" in flags:
            check(conn)
            return
        date_from = dates[0] if dates else EXAMPLE_FROM
        date_to = dates[1] if len(dates) > 1 else EXAMPLE_TO
        ohne = "--ohne-vorrat" in flags
        print_list(fetch(conn, date_from, date_to, ohne), date_from, date_to, ohne)
    finally:
        conn.close()


if __name__ == "__main__":
    main(sys.argv[1:])
