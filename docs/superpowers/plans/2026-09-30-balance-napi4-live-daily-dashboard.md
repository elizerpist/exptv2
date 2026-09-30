# Napi 4 élő Balance – implementációs terv

Kapcsolódó elfogadási lista: `docs/superpowers/specs/2026-09-30-balance-napi4-live-daily-dashboard.md`.

## Architecture card

- **Adatút:** resident income/expense `DashboardLedgerEntry` → `DashboardBalanceDailyInsightsProjection` → `DashboardBalanceLinkedPresentation.dailyInsights` → `BalanceAlternativeDayPresentation` → három kizárólag renderelő child card.
- **Egyetlen write path:** a már létező időnavigáció `DayScope` kiválasztott napja. Nem vezetünk be tap/persisted külön napi diagram-state-et.
- **Megosztott core:** egy epoch-day indexelt napi idősor építi a momentum 60 eredményt és daily impact bemeneteket. A ritmus nem lehet külön chart-aggregátor.
- **Meglévő tulajdonosok:** a Mother Card / 70–30–40 geometriát `BalanceExtendedSheetLayout` tartja; a child surface és HTML pixel tokenek közös tulajdonosa változatlanul a balance alternative render-réteg.
- **Új renderer-határ:** `balance_alternative_day_cards.dart` csak immutable presentation adatot kap, nem ledger-entryt, Query-t vagy controller-t.
- **Vizuális token:** a Napi 4 színek a `BalanceAlternativeHtmlTokens` közös, theme-aware tokenforrásából jönnek; nincs másolt feature-local paletta.

## Lépések

1. Domain tesztet írni a 30×30 napi momentumra, cutoffra, azonos 60 elemű ritmusra, kvadránsra, daily impactre, p95 dinamikus skálára és unavailable esetre; RED futás.
2. Létrehozni a tiszta `dashboard_balance_daily_insights_projection.dart` modellt és aggregátort, majd a domain tesztet zöldre hozni.
3. A linked projectionhez és alternative Day adapterhez egyetlen `dailyInsights` mezőt kötni; boundary teszttel ellenőrizni, hogy Day scope az új immutable read modelt kapja.
4. RED widget/boundary tesztet írni az Napi 4 extended-sheet slotokra, az összevont jobb kártyára, a piros negatív impact pillre és a ritmus szín-/kiválasztás szabályára.
5. A három source-truth renderert megírni: 500×400 koordinátapainter, vertikális daily-impact card, és alsó 60 napos rhythm strip. Kódrajzolás, a prototípus nem rasteresítése.
6. A `balance_dashboard_core_surface.dart` Day routerét az új extended-sheet kompozícióra váltani. Mother Card és `BalanceExtendedSheetLayout` érintetlen.
7. Formázás, célzott tesztek és `flutter analyze` Ubuntu prootban; Android screenshot ellenőrzés Napi 4 referenciával; checklist státuszok frissítése.
8. Csak a saját app-, teszt- és dokumentációs fájlokat commitolni, pusholni. A pontos SHA GitHub Actions human APK-ját figyelni, letölteni `/storage/emulated/0/Download/fluvi` alá és SHA-256-tal ellenőrizni.

## Nem cél

- A SUM, Havi vagy Éves child tartalom és minden Mother Card geometria változtatása.
- A korábbi általános `DashboardBalanceMomentumProjection` másolása vagy átalakítása: annak eltérő szemantikája van.
- Képfájl vagy screenshot beágyazása bármelyik grafikonba.
