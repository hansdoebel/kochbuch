# Kochbuch für Android

Die App enthält beim ersten Start den gesamten Rezeptkatalog dieses Checkouts. Suche nach Titel, Quelle oder Zutat, merke Rezepte und plane einzelne oder automatisch vorgeschlagene Mahlzeiten. Der Wochenplan lässt sich über das Android-Teilen-Menü weitergeben. Für die Tagesanalyse im Rezept die tatsächlich gegessenen Portionen erfassen. Fehlende Zutatenwerte bleiben als Teilsummen erkennbar.

Unter Profil können Name, Größe, Gewicht, Ernährungsweise und Ziele für Trainings- und Ruhetage gespeichert werden. Persönliche Eingaben bleiben lokal. Der automatische Plan verwendet die gemeinsamen Planungs- und Nährwertfunktionen der Web-App. Für Zielplanung den Anteil einer Mahlzeit am Tagesziel festlegen. Für Rezeptkarten ohne skalierbare Portionsbasis ist die manuelle Planung möglich.

## Synchronisieren

Die gebaute App funktioniert offline. Für neue Rezepte die HTTPS-Adresse einer laufenden Instanz der Kochbuch-API mit diesem Commit unter Profil eingeben. „Jetzt synchronisieren“ lädt den versionierten Katalog mit Conditional GET. Erst nach erfolgreicher Validierung und abgeschlossener IndexedDB-Transaktion erscheint der neue Stand. Die Synchronisierung überträgt ausschließlich den Rezeptkatalog vom Server zum Gerät. Favoriten, Profil, Plan und Verzehr gehören zur lokalen App-Installation.

## Android-Build

Capacitor 8, Svelte 5, Vite 8 und TypeScript. Das Android-Projekt verwendet die zur stabilen Capacitor-Version gehörenden Gradle-/SDK-Versionen. Für lokale Builds JDK 21, Android SDK 36, Gradle 8.14.3, Node 24 und Bun 1.4.5 installieren. Im Repository:

```sh
(cd web && bun install --frozen-lockfile)
(cd mobile && npm ci && npm run build)
(cd mobile/android && gradle assembleDebug)
adb install -r mobile/android/app/build/outputs/apk/debug/app-debug.apk
```

Der Workflow Android APK erstellt denselben Debug-Build als herunterladbares Artefakt. Der generierte Katalog, Binärdateien und Signaturschlüssel gehören nicht ins Repository.

## Vergleich ähnlicher Apps

| App | Beobachtung | Umsetzung im Kochbuch |
| --- | --- | --- |
| KptnCook | Entdecken, Favoriten, Wochenplan und Kochschritte sind eng verbunden. [Produkt-FAQ](https://www.kptncook.com/faqs) | Gemerkte Rezepte, Zutaten und Anleitung direkt beim Rezept; ausgewähltes Datum beim Wechsel vom Plan zur Suche beibehalten. |
| Mealime | Der Anbieter kündigte die Einstellung zum 21. Oktober 2026 an. Im bisherigen Produkt begann die Planung mit Ernährungspräferenzen und führt zu einer konkreten Rezeptauswahl. [Mealime](https://www.mealime.com/) | Vegetarisch/vegan sowie eigene Trainings- und Ruhetagsziele fließen in Vorschläge ein. |
| Paprika | Rezepte organisieren, Mahlzeiten planen und Sammlungen auf Mobilgeräten verfügbar halten. [Paprika für Android](https://www.paprikaapp.com/android/) | Lokal gespeicherter Katalog und Plan, gezielter Katalogabruf vom eigenen Server. |
