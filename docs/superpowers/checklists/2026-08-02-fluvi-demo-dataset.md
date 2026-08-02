# Fluvi demo dataset acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DEMO-01 | Approved demo vertical-slice design | core/demo generator | Fixed version and PRNG produce byte-equivalent dataset plans | Kotlin generator test | DONE |
| DEMO-02 | User §7–§8 | core/catalog + seed use case | Ten demo categories use only valid catalog IDs and preserve one Uncategorized | Generator pass; Room execution blocked by local Robolectric native setup | PARTIAL |
| DEMO-03 | User §9 | core/demo generator | Reusable deterministic partner set has valid defaults and aliases | Generator/reference test and source inspection | DONE |
| DEMO-04 | User §10–§17 | core/demo generator | Seven local months contain exact dates, times, income/expense mix and target totals | Monthly invariant tests | DONE |
| DEMO-05 | User §19 | core seed use case | One atomic batch write rolls back on failure | Room transaction test | BLOCKED |
| DEMO-06 | User §5–§6 | core metadata | Same seed is a no-op; force reset removes only deterministic demo IDs | Room idempotency test | BLOCKED |
| DEMO-07 | User §20 | core revision/sync | Revision, projection and documented outbox behavior remain consistent | Core compile and code inspection; runtime test blocked | PARTIAL |
| DEMO-08 | User §22–§28 | native read service | Total and bounded page share one canonical scope and query key | Read contract test compiles; Robolectric execution blocked | PARTIAL |
| DEMO-09 | User §24–§25 | native bridge | Room invalidation emits a fresh dashboard result without manual refresh | EventChannel bridge test + Room observer test blocked by environment | PARTIAL |
| DEMO-10 | User §21, §27 | Flutter bridge | Seed report and paged rows map without DAO or Flutter visual types | Flutter bridge/EventChannel tests | DONE |
| DEMO-11 | User §29–§30 | Flutter query/navigation | Demo seed does not alter production default and debug mode navigates to July 2026 | Query observer + navigation controller tests | DONE |
| DEMO-12 | User §33–§35 | query/read model | Year, month, day totals, pages and revisions match real Room rows | Room end-to-end tests blocked by Conscrypt setup | BLOCKED |
| DEMO-13 | User §37 | performance | Seed and scope reads are measured; no Flutter-side full-list aggregation | Seed report duration field; benchmark not run | PARTIAL |
| DEMO-14 | User §38 | documentation | Dataset, totals, trigger, reset, invalidation and LogBox contract documented | `docs/demo-data/fluvi-demo-dataset.md` review | DONE |
| DEMO-15 | Structuring Apps architecture gate | all changed layers | Single write path, correct dependency direction, no demo logic in widgets | Boundary/source inspection | DONE |

## Dashboard amount end-to-end repair

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| E2E-01 | User diagnostic §1–§3 | Flutter/native query diagnostics | Active scope, DB identity, seed counts and Room observer emissions are observable in debug logs | Targeted code inspection; runtime log capture still needs the rebuilt APK | PARTIAL |
| E2E-02 | User §4–§6 | FluviLedgerReadService/query boundary | Year 2026 and July 2026 income/expense reads return the real seeded totals with correct direction and minor-unit semantics | Existing Room read/seed tests | DONE |
| E2E-03 | User §7–§11 | Flutter bridge and CurrentQueryController | The same query key, revision, totalMinor and entryCount reach Flutter through the observer stream | Bridge parser + controller stream + amount pipeline tests | DONE |
| E2E-04 | User §12–§13 | SummaryAmountPresentation/SummaryAmountView | Data renders a formatted amount; an empty or zero result renders `0 Ft`, never an empty amount region | Presenter and widget tests | DONE |
| E2E-05 | User §16–§18 | Demo orchestration | After debug seed the dashboard is explicitly navigated to July 2026 without changing production defaults | Core navigation/query wiring test | DONE |
| E2E-06 | User §16, §35–§36 | Room invalidation | A seed committed after an active July observer produces a new amount without manual refresh or polling | Existing Room observer test; local Room runtime is environment-blocked | PARTIAL |
| E2E-07 | User §21 | Regression boundary | Rail physics, SummaryPill gestures and time-navigation animation behavior remain unchanged | Existing regression suite and direct diff inspection | DONE |
