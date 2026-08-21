# Query-dismiss committed ready-ahead priority

| ID | Source | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QRA-01 | User: route completion priority | `DashboardCoreController` + `ExplicitCommittedPagingController` | Committed initial ready-ahead is re-admitted before Query/rail/summary speculation after actual sheet dismissal | Controller/paging ordering test | DONE |
| QRA-02 | User: no paging started by active input | `ExplicitCommittedPagingController` | Live demand records its target during vertical input but does not start new repository/page preparation/publication work | Paging race regression | DONE |
| QRA-03 | User: no starvation | Existing paging idle callback | Deferred same-scope target resumes after input and speculation resumes after readiness/terminal state | Paging/controller regression | DONE |
| QRA-04 | User: preserve supersede and bounded cache | Existing committed paging owner | Same-target work is retained; structural replacement rejects stale output; page bounds unchanged | Existing paging/geometry tests | DONE |
| QRA-05 | User: preserve Query hotset | Query controller / scene cache | Chip admission, prepared Apply, direction reuse and first paint remain unchanged | Existing Query/preview tests | DONE |
| QRA-06 | User: architecture boundary | Existing controller/paging contracts | No second scheduler, cache, cursor, controller, or UI I/O owner | Boundary test + diff inspection | DONE |
| QRA-07 | Global delivery | GitHub Actions / human APK | Pushed commit's normal human APK downloaded and hashed | Exact Actions build + SHA-256 | DONE |
| QRA-08 | User: physical Android verification | normal `lib/main.dart` APK | Immediate post-Apply flick has zero new paging work during interaction | Human run and flow trace | PARTIAL |

## Architecture card

- **Single source of paging demand and execution:** `ExplicitCommittedPagingController`.
- **Lifecycle coordinator:** `DashboardCoreController`; it owns Query-sheet completion ordering and delegates only through the existing paging controller.
- **Read path:** viewport → controller demand → paging target → existing sequential cursor/repository/cache pipeline.
- **Write path:** the paging controller alone records ready targets and starts/resumes ready work; UI and painters only report viewport state.
- **Priority rule:** route completion → bounded committed ready-ahead → existing Query/rail/summary speculation.
- **No new engine:** extend the existing paging scheduling policy; retain scene-cache and Query-hotset ownership untouched.

## Current verification status

- QRA-01 through QRA-06: DONE by the final local test/analysis run and targeted diff review.
- QRA-07: DONE — GitHub Actions built and published the exact human APK; it was downloaded and SHA-256 verified locally.
- QRA-08: PARTIAL; physical Android verification is intentionally pending the human run on that exact APK.
