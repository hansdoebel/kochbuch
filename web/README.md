# Kochbuch Web

Schlanke Svelte-5-/shadcn-svelte-Oberfläche mit Bun-API, SQLite-FTS5, Light/Dark Mode und mobiler Typst-Einkaufsliste. Die App liest die auf dem Checkout vorhandenen `rezepte/`, `db/` und `quellen/`. Neue Archive benötigen keinen Frontend-Neubau; der Index wird beim Neustart automatisch anhand der Dateien invalidiert. Die Recherche und Architekturentscheidung stehen in [docs/webui-research.md](../docs/webui-research.md).

## Starten

Bun 1.4.5 oder neuer installieren, dann vom Repository aus:

```bash
cd web
bun install --frozen-lockfile
bun run setup:typst
bun run build
bun run start
```

Die App läuft standardmäßig auf `http://127.0.0.1:3000`. `PORT` und `HOST` sind konfigurierbar. Für den Zugriff vom eigenen Handy im vertrauten LAN kann `HOST=0.0.0.0 bun run start` verwendet werden; die App hat bewusst keine Benutzerverwaltung und ist für lokalen Betrieb gedacht.

`setup:typst` installiert den fest versionierten, mit SHA-256 geprüften Linux-x64-Compiler nur in das ignorierte `.tools/typst/`. Auf anderen Plattformen [Typst installieren](https://github.com/typst/typst/releases), in den `PATH` aufnehmen oder `TYPST_BIN=/absoluter/pfad/typst` setzen. Ohne Compiler bleiben Typst- und JSON-Download verfügbar. Die Typst-Datei enthält ihre Daten selbst und lässt sich unabhängig mit `typst compile einkaufsliste.typ einkaufsliste.pdf` übersetzen. Generierte PDFs und Binärdateien werden nicht eingecheckt.

Für UI-Entwicklung: in einem Terminal `bun run dev` (API mit Watch-Modus), in einem zweiten `bun run dev:ui` (Vite mit API-Proxy). Der Produktionsserver braucht nur die gebauten Assets und Bun. Die Quelle `web/templates/shopping-list.typ` erzeugt Seiten mit 108 × 192 mm, lesbarer Schrift und Checkboxen.

## Verhalten

- Volltext-/Präfixsuche nach Namen, Zutaten und Quelle; Quelle und skalierbare Rezepte filtern. `/` fokussiert die Suche. Maximal 30 Karten im Browser pro Seite; Rezeptdetails auf Abruf.
- Bis zu 24 Rezepte auswählen, kuratierte Portionen anpassen, Vorrat und optionale Zutaten berücksichtigen, Liste abhaken und PDF/Typst/JSON herunterladen.
- Archivrezepte behalten ihre Originalmengen. Ihre Zutaten werden separat pro Rezept angezeigt. Es werden keine US-Cups oder unbekannten Portionen stillschweigend skaliert oder in Gramm umgerechnet.
- Auswahl, Design, persönliche Nährwertziele und tatsächlicher Verzehr bleiben in `localStorage`. Geplante Portionen werden nicht automatisch als gegessen protokolliert. Der lokale Speicher kann über die Browser-Einstellungen gelöscht werden.
- Die Ernährungsansicht unterstützt Energie, Protein, Ballaststoffe, Kohlenhydrate und weitere Makro-/Mikronährstoffe. Sie zeigt derzeit keine erfundenen Werte: Die analysierten Profile sind noch leer. Datenformat und nächster Schritt stehen in [nutrition/README.md](../nutrition/README.md).

## Prüfung und Leistung

```bash
bun run check
bun test
bun run build
bun run bench
```

Mit installiertem Typst testet die Suite auch echte PDF-Erzeugung und das eigenständige Template. Der CI-Job installiert den Compiler vor den Tests; er prüft außerdem den Build und die komprimierten Bundle-Budgets (100 KiB je JS-Chunk, 20 KiB je CSS-Datei). Die Ernährungsansicht ist ein separat geladenes Modul. Die Bun-API liefert vorab komprimierte Assets mit unveränderlichen Cache-Headern aus.

Lokaler Suchbenchmark auf dem Stand mit 5.679 indexierten Rezepten: Median 1,25 ms, p95 5,46 ms für serverseitige Suchabfragen, ohne Netzwerk und Browser. Der erste Indexaufbau dauerte in diesem Lauf etwa 0,9 Sekunden. Werte hängen von Datenbestand und Hardware ab. `bun run bench` misst den jeweiligen Checkout. Die Datenbank in `.cache/web.sqlite` ist abgeleitet und kann jederzeit gelöscht werden.

Svelte-/TypeScript-, API-, Mengen-, Nährwert-Abdeckungs- und PDF-Prüfungen werden automatisiert ausgeführt. Eine visuelle Browserprüfung war in der bereitgestellten Umgebung mangels Browser-QA-Werkzeug nicht möglich. Responsivität, Tastaturbedienung und Light/Dark Mode sollten zusätzlich im Zielbrowser geprüft werden.
