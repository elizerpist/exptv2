# Acceptance checklist — Summary mirror and Budget ring geometry follow-up

**Baseline:** `separated-core-modes` at
`004bbfc36444309d1fc3de618d611f269cd7b53a`; clean linked worktree; Fluvi Logs
r45. The current screenshots show external DAY markers and merged/magenta YEAR
cells. No physical Android acceptance is claimed.

| ID | Source / owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- |
| SM-01 | User; summary settings | Default normal and selectable mirrored segmented orientation; Legacy unaffected | settings/controller tests | DONE |
| SM-02 | User; `SummarySegmentedTrackGeometry` | Mirrored component/amount Rects reverse zones while preserving width, gap, readable text and visual/hit/semantics parity | pure/widget/fling tests | DONE |
| SM-03 | User; Summary tuner | Existing tuner owns the Hungarian normal/mirrored control; reset restores normal; no query/controller reset | widget/controller tests | DONE |
| DM-01 | User; `BudgetProgressRingDayPaceMarkers` | Exactly two same-material 3D spheres lie on the track centreline at the 75% gauge level | pure geometry/painter tests | DONE |
| DM-02 | User; DAY painter | Markers are painted over track/fill; no horizontal line; DAY pace semantics unchanged | painter/controller regressions | DONE |
| YR-01 | User; annual segment geometry | Twelve equal slots, equal fixed sweep, cap-aware positive visible gap at all twelve boundaries | pure/raster geometry tests | DONE |
| YR-02 | User; annual material | Active YEAR material is hue-preserving green/yellow/red only; future/missing is neutral; no category hue shift | source/material/raster tests | DONE |
| PR-01 | User; protected paths | DAY/MONTH/YEAR/SUM semantics, prepared navigation, controller identities and bounded paint path remain intact | protected suites/source inspection | DONE |
| DOC-01 | User documentation | Records exact source root causes, formulas/tokens and no false physical claim | plan/checklist review | DONE |
| DEL-01 | User delivery | Commit/push, matching successful human APK and SHA-256 | command/Actions evidence | NOT DONE |

**Inherited verification note:** the starting `004bbfc` revision reproduces
the same `dashboard_scroll_milestone_test.dart:155` `Bad state: No element`,
six Core golden pixel diffs, and missing `budget-distribution-pager` Core test
failure as this worktree. No task-produced failure remains; physical Android
validation is still not performed or claimed.
