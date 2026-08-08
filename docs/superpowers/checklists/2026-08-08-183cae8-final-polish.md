# 183cae8 final polish — acceptance checklist

Base: `183cae85898ea3bf1d214a6b694e9b2e9c5cd3bf`  
Working branch: `fix/final-polish-scope-reset-summary`

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| POL-01 | §3–7 | `DashboardLogBoxViewport` | Metadata-only committed promotion resets the stable vertical scope exactly once. | Same-payload widget regression | DONE |
| POL-02 | §5–12 | viewport lifecycle | Preview crossings do not reset; direction and plane committed changes reset once at the canonical top. | Stable-viewport widget tests | DONE |
| POL-03 | §8–10 | viewport lifecycle | July → June → May → April uses one store, cache, viewport, controller, position and render object. | Sequential widget test + identity assertions | DONE |
| POL-04 | §11, §38 | core diagnostics | Physical report exposes committed-scope reset count. | Controller/report unit test | DONE |
| POL-05 | §13–17 | render extent diagnostics | Preview rendering reports preview rows/extent separately from background committed-cache values. | Snapshot/report tests | DONE |
| POL-06 | §16 | render extent contract | Committed cache extent, surface height and exposed scroll extent remain consistent. | Existing 24→48→72→94 regression tests | DONE |
| POL-07 | §18–32 | SummaryPill projector | SUM and closed labels stay unchanged; open year/month child labels retain typed parent temporal context. | Projector/widget/width tests | DONE |
| POL-08 | §24–30 | summary presentation | Live rail preview uses `visible.scope.timeScope`, never query parsing or retained-child state. | Parent/year boundary tests | DONE |
| POL-09 | §33, §39 | frozen runtime | Rail, physics, demand planner, paging cursor flow, index hot path and lane separation have no diff. | Base diff + SHA audit | DONE |
| POL-10 | §35 | verification | Relevant non-golden tests and Flutter analysis pass. | Ubuntu/proot test and analyze | DONE |
| POL-11 | §37 | delivery | Normal `lib/main.dart` HUMAN_DIAGNOSTIC profile APK is built, downloaded, SHA-256 and ZIP integrity checked. | GitHub Actions + local artifact checks | PARTIAL |
| POL-12 | §34, §40 | physical validation | Human device flow validates resets, labels and scroll. | User physical capture | BLOCKED |

## Architecture card

- **Scope-reset owner:** the existing `logBoxPresentationLane` is the sole lifecycle signal. The stable viewport observes it; `DashboardCoreController` only records the reset metric through a callback.
- **Render diagnostics:** `DashboardLogBoxRenderExtentSnapshot` reports both the current rendered domain and, separately, any background committed-cache state. It does not own paging or layout.
- **Summary copy:** the existing `SummaryNavigationProjector` remains the single formatter/projector. It gains a typed live-child projection using `LedgerTimeScope`; no query-key parsing or navigation ownership changes.
- **Frozen ownership:** the rail, physics, prepared index, demand planner, paging cursor flow, cache ownership and payload/presentation lane separation remain untouched.
