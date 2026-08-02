# Dashboard summary index and rail latency checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LAT-01 | User FLOW timings | `DashboardSummaryPill` diagnostics | D10A–D10D distinguish bound, transition start, first painted frame, and completion; no marker falsely claims a build is painted | Widget test + diagnostic code inspection | DONE |
| LAT-02 | User: no 1 s amount delay | `DashboardSummaryPill` | Numeric change has one latest-wins, <=120 ms crossfade; stale/loading alone starts none | Widget test with interrupted updates | DONE |
| LAT-03 | User: diagnose pre-D8 | rail adapter/navigation/core | R1–R4 timing identifies center, idle, settled callback, and query commit without altering shared carousel | Controller/widget diagnostic test + code inspection | PARTIAL — R1–R4 added; truthful R0 remains unavailable because the generic engine keeps its physical target private and is frozen by the regression boundary. |
| LAT-04 | User: single tap should improve too | amount projection/index controller | A rail single-tap changes the amount on first preview from the loaded index, with no detailed query before settle | Controller test | DONE |
| LAT-05 | User: fling is slower but physics frozen | amount projection/index controller | Every preview during a fling is a map lookup; 100 previews produce zero detailed repository watches and zero native subscriptions | Controller test | DONE |
| LAT-06 | User grouped-index specification | core `FluviLedgerReadService` | One parent SQL `GROUP BY` produces year/month/day child totals, counts, keys and core revision through the canonical predicate | Kotlin core test + bridge test | PARTIAL — implemented and covered by source tests; remote Android compile/test pending. |
| LAT-07 | User filters/revision requirement | native DTO + Flutter decode | Index uses same direction/facets/refinements/query keys as the detailed scope; mismatched/stale revision cannot replace the amount | Dart tests | PARTIAL — Dart decode/latest-wins proof is green; remote native contract test pending. |
| LAT-08 | User cache requirement | amount projection controller | Bounded cache (<=36) reloads on parent/direction/facet/revision mismatch and turns missing child buckets into zero | Controller tests | DONE |
| LAT-09 | User detailed-query requirement | `DashboardCoreController` | Detailed selected-scope query continues to change only at settle, never for preview | Existing/extended core test | DONE |
| LAT-10 | User strict regression ban | `lib/shared/motion/centered_carousel/**` | No changed file below this directory; unchanged physics/controller/widget suites pass | `git diff` + focused suites | DONE |
| LAT-11 | User build/delivery standing instruction | GitHub Actions/release | Commit, push, successful online APK build and verified download to `/storage/emulated/0/Download/fluvi` | CI/release artifact SHA | NOT DONE |
