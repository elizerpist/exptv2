# Daily Budget and Summary parity acceptance checklist

**Baseline:** `separated-core-modes` local and `origin` at
`44b1992a8c0d5b66ce0c39acaf44155515dc1131`; clean worktree; Drive Fluvi Logs
revision **45**; screenshot
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260827-092059.png`.

| ID | Source / required behavior | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DB-01 | A1–A2 | Financial limit domain + period resolver | No Day financial-limit period/entity/Room row; DAY and MONTH resolve the exact same monthly key. | `dashboard_budget_distribution_scope_test.dart`, controller key regression, source inspection | DONE |
| DB-02 | A3–A4, A20 | Budget presentation | Forecast, display numerator and canonical edit actual are separate typed values. | pure state + edit-context regression | DONE |
| DB-03 | A5–A12 | Projection resolver | Core-owned injected as-of date; current/past/future semantics, rounding, month length and zero-spend days are deterministic; bounded/no-I/O same-month Day navigation. | pure projection + rhythm/controller tests | DONE |
| DB-04 | A8–A9 | Projection key/cache | Selected day does not affect same-month forecast; month/core/target/as-of changes do. | multi-day controller regression | DONE |
| DB-05 | A13–A18 | Header + avatar chrome | DAY Header shows projected end / monthly limit; selected avatar vertical gauge maps raw ratio × .75, marker .75 and existing raw-ratio health tones; MONTH ring unchanged. | controller + pure geometry + chrome source tests | DONE |
| DB-06 | A19–A21 | existing limit edit controller | DAY uses unchanged monthly edit controller/key/rules; forecast never enters editor actual; optimistic denominator updates Day gauge and remains visible in MONTH. | controller + gesture regression | DONE |
| SP-01 | B1–B6, r45 | Presentation controller + Core scheduler | Prepared segmented YEAR/MONTH/DAY crossing publishes visible frame/LogBox before coverage preparation, repository I/O or settle. | prepared-frame controller tests + scene-window test | DONE |
| SP-02 | B7–B8 | existing scheduler | Secondary scene/hotset maintenance remains bounded, stale-guarded and input-preemptible; Legacy and Current/Trio routes preserve parity. | scene-window, visible-frame and Summary suites | DONE |
| DT-01 | C1–C4 | `_HierarchyValueSelectorState` | Dynamic Trio is visible exactly while physical motion is active and collapses at first idle; no post-settle timer exists. | deterministic Summary widget tests | DONE |
| SG-01 | D1–D6 | segmented track layout resolver | Each active visual MODE↔YEAR↔MONTH↔DAY gap is half its current resolved reference; separators follow; amount zone and typography stay unchanged; hit areas remain valid. | resolver + Summary widget tests | DONE |
| BN-01 | E1–E5 | BNB canonical contour + Stack composition | Existing path supplies both FAB sides; one foreground non-interactive contour is visible fully above FAB, no double stroke; rounded/straight × off/on all work. | path + composed Stack + actual raster samples for both FAB sides; physical visual check still pending | PARTIAL |
| RG-01 | protected invariants | full dashboard | Query semantics, one visible-frame owner, bounded caches, one LogBox controller/position, Budget target identity, established surfaces and FAB interaction remain intact. | protected regression suites; one inherited r45 pager assertion documented below | DONE |
| DOC-01 | documentation | docs | Source evidence, root cause, final ownership, formula, metrics and validation are factual; no unperformed physical claim. | documentation review | DONE |
| DEL-01 | delivery | git/Actions | One focused production commit, pushed SHA, exact normal human APK from matching Actions run downloaded and SHA-256 verified. | Actions + file hash | NOT DONE |

## Test-boundary note

`test/features/dashboard/presentation/budget_distribution_pager_test.dart`
fails on both the implementation worktree and a clean detached r45 worktree:
the existing Partner donut assertion expects `height > 104`, while both report
`100.8`. It is therefore an inherited baseline failure, not changed or masked
by this delivery.
