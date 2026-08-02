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
