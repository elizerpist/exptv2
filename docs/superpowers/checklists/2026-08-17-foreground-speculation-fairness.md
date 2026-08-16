# Foreground speculation fairness — acceptance checklist

## Architecture card

### Scope and sources

- User requirements: physical trace following `79ff00c` and the supplied delivery contract.
- Existing owners: `DashboardCoreController` (Query speculative lifecycle), `DashboardLogBoxPreparedSceneCache` (scene preparation), `DashboardLogBoxPartnerSwipeGestureRecognizer` (horizontal arena ownership), `_VerticalInteractionSessionOwner` (input diagnostics).
- Protected behavior: cache interaction arming / O(1) activation, exact facet Apply binding, `DragStartBehavior.down`, serial committed paging, immutable virtual geometry.

### Single source and write path

| State | Owner | Write path | Publication rule |
| --- | --- | --- | --- |
| Query speculative slot | `DashboardCoreController` | injected runtime scheduler grant | one admitted neighbour per grant |
| Rich projection progress | deferred viewport projection, driven by scene cache | bounded scene-preparation step | only completed immutable projection is exposed |
| Partner horizontal lease | partner recognizer | self-claimed left-horizontal arena win | no visual/focus side effect on passive acceptance |
| Pointer-only diagnostic evidence | vertical session owner | raw pointer lifecycle | never reads formal-session velocity fields |

### Reuse / boundary decision

- Extend the existing runtime scheduling boundary; no Flutter scheduler import is added to `DashboardCoreController`.
- Extend the existing deferred projection and scene cache; no second projection or cache is introduced.
- Keep Flutter `Scrollable` as the only vertical drag owner.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FSP-01 | Query prewarm trace | core + injected runtime scheduler | Every neighbour start requires a new input-fair scheduler grant; a pointer can interleave before neighbour N+1. | Controlled-scheduler RED/GREEN tests | DONE |
| FSP-02 | Clear-all constraint | core hotset ordering | Unfiltered Expense remains a lowest-priority logical neighbour and is only delayed by fairness. | Query application test | DONE |
| FSP-03 | 18 ms projection trace | deferred projection + scene cache | Rich row/group projection checkpoints within a payload and publishes only complete immutable results. | Deterministic work-clock scene-cache test | DONE |
| FSP-04 | Passive partner win trace | partner recognizer | Arena acceptance without self-claimed left-horizontal evidence has no swipe side effect. | Partner arena widget/recognizer tests | DONE |
| FSP-05 | Stale velocity trace | viewport session diagnostics | A pointer with no formal vertical session reports unavailable velocity and `noFormalVerticalInteraction`. | Viewport diagnostic regression | DONE |
| FSP-06 | Protected 79ff00c behavior | cache, viewport, core | First touch stays armed/O(1); no paging or physics workaround; identity/geometry invariants remain unchanged. | Existing focused suites + fast suite | DONE |
| FSP-07 | Delivery contract | Git / GitHub Actions | One final production commit and one normal `lib/main.dart` APK for its SHA. | Git, Actions, artifact SHA-256 | NOT DONE |
