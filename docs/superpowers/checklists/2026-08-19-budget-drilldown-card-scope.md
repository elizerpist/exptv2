# Budget drill-down / Card2 scope acceptance checklist

| ID | Requirement source | Owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BD-01 | Current Budget drill-down request §5, §8 | Core focus command boundary + Budget rail/card intents | Settled Category intents replace only the ephemeral Category focus, clear Partner atomically; aggregate restores the applied Query without mutating it. A manual chip clear is respected. | Focus/controller tests | NOT DONE |
| BD-02 | §5 Partner drill-down, §9 | Existing Ephemeral Focus + Partner visual bank/card | Partner row/pie selects the existing partner focus, retains Category intersection and has prewarmed selected SVG/list variants. | Visual-bank and widget tests | NOT DONE |
| BD-03 | §10 rhythm placement | Shared distribution surface, category/partner cards | Category returns to a 150px donut; Partner owns the compact donut plus target-aware rhythm. Rhythm has no monetary labels. | Widget tests | NOT DONE |
| BD-04 | §11 dedicated physical cards | Budget distribution pager/surface | The stable PageView pages each own one shared white Card2 surface; no fixed white parent remains; dots/controller/physics remain local and stable. | Pager widget test | NOT DONE |
| BD-05 | §12 analysis scope | Prepared Budget/Partner snapshots, budget presentation/distribution controllers | Day child analytics use exact sparse day data; Month/Year/Sum use exact child frames, while persisted limits retain their existing containing-period keys. | Domain/codec/controller tests | NOT DONE |
| BD-06 | §13 child drawable readiness | Existing Budget drawable time-preparer | Directly reachable rail children publish only from retained renderer-ready category+partner frames; input hot path has no I/O or SVG preparation. | Time-publication tests/counters | NOT DONE |
| BD-07 | §15–16 delivery | Targeted test suite, analyzer, GitHub human APK | Focused tests and analyzer pass; exact branch APK is downloaded after successful workflow. | Commands/actions artifact SHA-256 | NOT DONE |

## Architecture card

- **Single write paths:** `DashboardCoreController` remains the sole focus
  publisher; `DashboardEphemeralFocusController` remains the sole temporary
  entity state. `DashboardBudgetPresentationController` remains Budget visual
  selection only. The local `BudgetDistributionPageController` remains pager
  state only.
- **Reuse:** extend the existing Core focus command path, the one production
  clay-donut generator/hit-test, one renderer prewarm owner, and the stable
  Flutter `PageController`. No Budget filter, second partner selection state,
  second SVG generator or motion owner is introduced.
- **Flow:** rail/card intent -> narrow Budget drill-down coordinator -> Core
  focus command -> existing prepared focus publication -> immutable Focus
  state -> Partner/card visual binding. Prepared day data -> distribution
  frame/visual bank -> O(1) handle/partner variant lookup -> UI.
- **Evidence:** focused pure/controller, renderer-bank and widget tests; no
  goldens; Flutter analysis; the normal `lib/main.dart` human APK build.
