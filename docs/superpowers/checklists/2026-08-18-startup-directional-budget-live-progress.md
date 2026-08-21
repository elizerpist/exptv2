# Startup, directionális Budget és élő progress — elfogadási ellenőrzőlista

| ID | Forrás | Tulajdonos / kódterület | Elfogadási feltétel | Igazolás | Állapot |
| --- | --- | --- | --- | --- | --- |
| SCN-01 | §1A, §3–6 | `DashboardLogBoxPreparedSceneCache` | A `renderCriticalReadiness` preparationt Summary/retained maintenance nem cancel-eli. | A 34 zöld cache-teszt közül a dedikált 30→130 row RED/GREEN ownership regresszió. | DONE |
| SCN-02 | §4–6, §34 | ugyanaz az egy scene owner | Azonos cél join/promote, alacsony prioritás pedig csak a readiness után futhat; valódi hiba továbbra is failure. | Cache ownership, cancellation és readiness tesztek; owner/priority diagnosztika. | DONE |
| SCN-03 | §6 | shell + readiness | Egészséges fresh és seeded cold start pontosan egy próbálkozással READY, Retry nélkül. | Healthy first-attempt shell teszt, clean Room/seed és natív bridge CI zöld. | DONE |
| SCN-04 | CI profile regresszió | `DashboardLogBoxPreparedSceneCache` | A completion-proof/immutable lease nem örökli a kész scene utolsó UI-szeletét; csak kimerült időbudgetnél cooperatív. | Determinisztikus final-handoff RED/GREEN, teljes cache-suite és a `32188283013` Android profile CI zöld. | DONE |
| DOM-01 | §7–11 | Kotlin `FluviBudgetReadService` | A direction membership a canonical all-time ledgerből jön, nem limitből és nem aktuális periódusból; SQL alakja bounded. | Direction-fixture RED/GREEN, clean Room és natív bridge CI zöld. | DONE |
| DOM-02 | §10–13 | native/Dart prepared snapshot + codec | Income/Expense saját ordered IDs, handles és dense cells; v2 codec a régi verziót elutasítja. | Dart v2 codec/domain RED/GREEN, clean Room és natív bridge CI zöld. | DONE |
| DOM-03 | §14–16, §29–30 | Budget presentation + demo seed | Direction-local selection visszaáll, direction switch RAM-only; seed csak látható direction célokra ír limitet. | Presentation direction-local teszt, demo-seed/Room és natív bridge CI zöld. | DONE |
| PRG-01 | §17–21, §31–32 | `DashboardBudgetLiveSelectionState` + avatar artwork | Egy state köti direction/target/title/money/key/ringet; a festett ratio pontos, nincs százalék-kvantálás. | Controller és widget RED/GREEN tesztek zöldek. | DONE |
| PRG-02 | §19–20 | projection/artwork | Positive limit + zero actual: shell+0 arc; null/0 limit: shell nincs; over-limit: full, header valós. | Projection/widget tesztek zöldek. | DONE |
| PRG-03 | §22–26, §28 | limit edit controller + rail | Pointer lenyomva 0-ra: azonnal chrome nélkül; vissza pozitívra: azonnal megjelenik; ismételt zero no-op nincs. | Pointer-down zero-crossing widget és controller no-op teszt zöld. | DONE |
| PERF-01 | §28–29 | controller/rail/cache ownership | Limit tick és direction switch nem indít I/O-t, SVG/Query/LogBox/catalog rebuildet. | Hot-path/rebuild-isolation tesztek, forrásaudit és zöld Flutter/native CI. | DONE |
| VAL-01 | §36 | Flutter/Kotlin/boundary | Formázás, analyzer, célzott és védett regressziók zöldek. | Lokális célzott Flutter-suite (105 teszt), `flutter analyze`, majd a `32188283013` GitHub Flutter/native/profile kör zöld. | DONE |
| DEL-01 | §39 | GitHub Actions | Fókuszált commitok pushed; sikeres normál `lib/main.dart` APK letöltve és SHA-256 ellenőrizve. | `1404ae06` pushed; `fluvi_HUMAN_DIAGNOSTIC_1404ae0.apk` letöltve, SHA-256: `6c145bb975e575d6a41b580568af762d85788629ee30424f637eb9ba4f55ba35`. | DONE |

Nem módosítandó fizikai baseline: `8d559cfbb9c31bbe6d6e89b32cf036be3ed94b91`. Ez a lista nem jelent fizikai Android-elfogadást.
