# Acceptance checklist — Daily pace and fixed annual Budget ring

**Baseline:** `separated-core-modes`; local/remote
`212e0c11dca22ace2f1031e256a005113bea8c1c`; clean linked worktree; latest
Fluvi Logs revision **45** (2026-08-27 07:19 UTC); screenshots listed in the
active implementation plan. The user’s 2026-08-28 prompt is authoritative.
No physical Android acceptance is claimed by this document.

| ID | Source / code owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- |
| ARC-01 | User; Budget controller/snapshots | Limits remain base-month + concrete month override; DAY/MONTH same key/edit write path | domain/controller/edit tests | DONE |
| ARC-02 | User; scope-analysis/ring APIs | One immutable scope analysis and one ring geometry/material owner; UI has no domain/persistence workflow | boundary/source contract + tests | DONE |
| DAY-01 | Daily correction; projection | Explicit actual daily average, allowed daily average and pace ratio exist; projection is secondary | pure RED/GREEN tests | DONE |
| DAY-02 | Daily correction; Header | DAY Header displays formatted daily average / allowed daily average, never selected day or forecast primary numerator | controller + widget test | DONE |
| DAY-03 | Daily correction; as-of/rhythm | Selected day does not change pace; zero calendar days count; past/current/future deterministic; no same-month repository I/O | pure/controller prepared-path tests | DONE |
| DAY-04 | Daily correction; edit | Existing monthly key/controller/steps/haptics retained; edit receives canonical monthly actual; optimistic limit immediately updates allowed pace | edit/controller tests | DONE |
| DAY-05 | Day visual; shared ring | Same geometry/material, bottom-up `.75 × paceRatio`, raw pace health, no separate bar | ring source + visual tests | DONE |
| DAY-06 | Day visual; marker | Exactly two symmetric 3D sphere markers at `.75` ring height; no horizontal marker line | geometry/painter test | DONE |
| MON-01 | Protected MONTH | Classic clockwise ring, actual/limit Header and category-accent/yellow/red semantics unchanged | Month regression suite | DONE |
| YR-01 | Year visual; controller/ring | Header denominator is 12 resolved limits and no annual truth participates | annual/controller tests | DONE |
| YR-02 | Year visual; ring | Exactly twelve fixed equal Jan→Dec cells; no partial mini-progress | pure ring/painter tests | DONE |
| YR-03 | Year visual; health | Healthy green, warning yellow, danger red; future/missing limit neutral | pure/controller/ring tests | DONE |
| YR-04 | Annual editing | Existing proportional, exact-sum, atomic/batch monthly override edit remains true | annual edit/repository tests | DONE |
| SUM-01 | Protected SUM | Typical-month marker/base monthly semantics retain shared geometry | SUM regression tests | DONE |
| SUMM-01 | Summary root cause; `SummarySegmentedTrackGeometry` | No offsets or widened hidden hit lane; one Rect is visual/clip/hit/semantics owner | geometry + fling tests | DONE |
| SUMM-02 | Summary layout | Large icon only; left inset == top inset; all content fits, equal half-baseline gaps, separators and amount zone stable | geometry/widget tests | DONE |
| NAV-01 | BottomNav contour | FAB/nav centre and left/right contour/clearance mirror exactly | pure path test | DONE |
| NAV-02 | BottomNav compositing | fill and optional border consume one top path; one final non-interactive stroke visible both FAB sides | Stack/raster rounded×straight matrix | DONE |
| PRF-01 | Milestone contracts | Prepared temporal/data paths, bounded caches, one LogBox controller/position and no hot paint text layout remain intact | protected suites + source inspection | PARTIAL — protected run has one inherited Scroll-milestone failure documented below |
| DOC-01 | User documentation | Evidence includes r45, source root causes, scope semantics and no false device claim | checklist/plan review | DONE |
| DEL-01 | User delivery | Fresh verify, commit/push, matching successful human APK and SHA-256 downloaded | commands + Actions evidence | NOT DONE |

## Factual verification notes

- RED: before the production change, the new pace tests failed because the
  projection did not expose `actualDailyAverageScaled100`,
  `allowedDailyAverageScaled100`, `paceRatio`, or a separate Header
  denominator. The old controller path displayed the month-end projection over
  the monthly limit.
- GREEN: the focused 96-test run covering projection, controller, partition,
  Header, ring, Summary, and BottomNav completed with `All tests passed`.
- The repository-curated `./scripts/test-fluvi-fast.sh` suite completed with
  **273 passing tests** in Ubuntu/proot. `flutter analyze` reported
  `No issues found`, and `./scripts/verify-fluvi-boundaries.sh` plus
  `git diff --check` passed.
- BottomNav required no new production geometry in this delivery: current
  `Bnb03BottomNavigationContour` already owns a mirrored circle-derived top
  edge for both fill and contour, and the final `IgnorePointer` stroke overlay
  is above the FAB. Its symmetry/composited-raster tests passed.
- Dynamic Trio has no cooldown/timer owner in current source. It derives
  neighbor visibility from `CenteredCarouselController.hasActiveScrollActivity`;
  immediate-idle tests passed.
- The protected multi-suite run found one failure in
  `dashboard_scroll_milestone_test.dart` at `FluviDiagnosticLogger.entries…single`:
  `Bad state: No element`. Re-running it alone still failed, and the same
  isolated run failed in the clean `c5f68c4d` reference worktree. It is
  inherited and outside this delivery's files; it remains a required follow-up
  before human physical acceptance.
