# Dashboard presentation and LogBox restoration acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DPR-01 | User prompt §§0, 32 | Git history | Baseline `5429aae44ee72a262be50e08a5a4676916d41f55` remains unchanged and work starts on a feature branch | `git show`, branch audit | DONE |
| DPR-02 | User prompt §§4–6 | query/domain, presentation store | One visible target and presentation epoch determine the expected visible QueryKey | target/store tests | DONE — immutable target and epoch are wired through the store and summary controller |
| DPR-03 | User prompt §§5, 9 | presentation store | Candidates compete only within the expected QueryKey; fresh same-key cache suppresses dash/loading | store regression tests | DONE — fresh same-key placeholder suppression and cross-key rejection are covered |
| DPR-04 | User prompt §§7–8 | core controller/store | Rail open/close publishes one atomic child/parent selection before lease/watch work | target/store tests | DONE — cached child/parent selection is synchronous and single-publish |
| DPR-05 | User prompt §§10 | SummaryPill amount | Amount generation, QueryKey and epoch reject delayed child completions | widget/animation tests | DONE — latest-wins amount transition suite is green with QueryKey/epoch guards |
| DPR-06 | User prompt §§11 | navigation/presentation | YEAR month child and MONTH mother have identical amount/count/key/revision | parity test | DONE — shared month snapshot parity test is green |
| DPR-07 | User prompt §§12–13 | navigation/presentation | Cached year navigation has no dash; cold navigation retains a complete outgoing snapshot without mixing fields | unit/widget tests | PARTIAL — store-level cold outgoing retention and navigation-label guard are covered; a dedicated cold-year title/field-consistency widget test remains |
| DPR-08 | User prompt §§14 | direction/query/presentation | Income/expense changes amount, count, LogBox, key and direction atomically | target/store tests | DONE — direction key and snapshot atomicity are covered |
| DPR-09 | User prompt §§15–16 | logbox/application | Pure projector derives immutable day/row view models outside widget build | projector tests | DONE — projector is pure, deterministic and tested |
| DPR-10 | User prompt §§17–18 | logbox/presentation | Preview swaps count, groups and rows in one frame with stable viewport identity and zero I/O | adapter/store tests | DONE — immediate adapter swap and zero-I/O are covered; the widget test confirms viewport State and Scrollable identity survive swaps |
| DPR-11 | User prompt §§19, 23 | logbox/application | Identical preview→committed promotion causes no visible publish, list rebind, animation or scroll reset | adapter/store tests | DONE — promotion preserves projected group list identity and avoids visible rebind |
| DPR-12 | User prompt §§20–21 | logbox/presentation | Day-grouped lazy sliver, central catalog, O(1) prepared icon/color lookup and token radius are used | code inspection + widget suite | DONE — day-grouped lazy slivers, central catalog/token usage and a 1000-row lazy-build test are green |
| DPR-13 | User prompt §§23 | logbox/application | Paging is committed-only, cursor-deduplicated and stale-result guarded | paging coordinator tests | DONE — committed-only, duplicate cursor and late-result tests are green |
| DPR-14 | User prompt §§24–25 | dashboard/presentation | LogBox changes do not rebuild root/header/rail or recreate rail controller/position | existing rebuild/identity coverage + code inspection | PARTIAL — isolated Listenable lanes and stable viewport shell are implemented; explicit 100-swap counter instrumentation remains |
| DPR-15 | User prompt §§26–30 | rail/performance | Crossing sequence and final target match baseline; preview I/O/paging counters remain zero; logger is off for benchmark | deterministic tests | PARTIAL — rail determinism and preview zero-I/O tests are green; physical L0–L6 p50/p90/p99 profile is not available in this environment |
| DPR-16 | User prompt §28 | test suite | Close stress, delayed callback, zero-result, direction, year, parity, and paging regressions pass without golden tests | full non-golden suite | DONE — final non-golden suite passed 257 tests; golden tests were not run |
| DPR-17 | User prompt §34 | delivery | Final report includes root causes, QueryKey sequences, rejection counters, restored/rejected components, benchmark and risks | final report | IN PROGRESS — final delivery follows after checklist review, one commit, push, CI build and APK download |

## Delivery rule

No APK build or push is performed at intermediate commits. The final push and
single GitHub Actions build happen only after the verified implementation is
committed and the remaining PARTIAL items are explicitly reported rather than
silently treated as complete.
