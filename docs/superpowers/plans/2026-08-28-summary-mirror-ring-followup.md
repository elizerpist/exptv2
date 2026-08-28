# Segmented Summary mirror and Budget ring geometry follow-up

> **For agentic workers:** Execute inline. The three changes share existing
> immutable presentation owners and have a small, coordinated test surface.

**Goal:** Add an opt-in mirrored segmented Summary and correct the accepted
DAY/YEAR ring presentation defects without changing Budget or navigation
semantics.

**Baseline:** `separated-core-modes` local/remote
`004bbfc36444309d1fc3de618d611f269cd7b53a`, clean linked worktree. Latest
Fluvi Logs is revision **45** (2026-08-27 07:19 UTC). The two supplied visual
references are `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-023109.png`
and `Screenshot_20260828-022803.png`; neither is a new human acceptance.

## Architecture card

- **Summary orientation state:** `DashboardSummaryPresentationSettings` owns a
  session-lifetime `SummarySegmentedOrientation`; its existing controller is
  the sole write path and tuner adapter. Legacy does not consume the setting.
- **Summary geometry:** `SummarySegmentedTrackGeometry` remains the single
  owner of visual, clipping, hit and semantics Rects. It receives orientation
  and lays out the navigation/amount zones from one shared metrics model; no
  transformed text or hidden lanes are allowed.
- **DAY marker:** `BudgetProgressRingDayPaceMarkers` remains the pure static
  geometry projection. Its centres are the two circle intersections of the
  75%-gauge Y with `BudgetProgressRingGeometry.trackRadius`; painter z-order
  remains after the DAY fill.
- **YEAR cells:** `BudgetProgressRingAnnualSegment` owns equal slots, one
  source-space visible-gap token and cap-aware centerline spacing. The painter
  gets hue-preserving health material only; it must not use category-gradient
  hue rotation.

## Baseline root-cause evidence

- `BudgetProgressRingDayPaceMarkers.resolve` derived X with
  `trackRadius + trackWidth / 2 + markerRadius + 7`, intentionally placing
  sphere centres beyond the ring. The DAY screenshot visibly confirms air
  gaps.
- `_paintAnnualSegments` passed green/yellow/red values through
  `_SelectionArcGradient.fromCategoryColor`, which hue-shifts its end by
  -46°. It can turn red magenta/purple. Its `.018` radian centerline gap is
  only about 1.9 source units at radius 107.52, while the two 12-unit round
  caps consume roughly 24 units.

## Implemented geometry and ownership

### Summary mirror

`DashboardSummaryPresentationSettings.segmentedOrientation` is session-owned,
defaults to `normal`, participates in equality/reset and is written only by
`DashboardSummaryPresentationController` through the existing Header tuner.
`SummarySegmentedTrackGeometry` receives that orientation and owns all actual
component Rects. Normal uses the outer left inset; mirrored uses the same
inset at the outer right. The amount zone and navigation zone swap as whole
zones, so mirrored DAY is `amount → day → month → year → mode` without text,
glyph or fling-direction mirroring. Dynamic Trio is additionally `ClipRect`
bounded by the selector's owned Rect.

### DAY marker

The fixed break-even Y is `100.24` in shared source space. With source centre
`(154, 154)` and track radius `107.52`, the circle-intersection result is:

```text
dy = -53.76
xOffset = sqrt(107.52² - 53.76²) = 93.115051
left = (60.884949, 100.24)
right = (247.115051, 100.24)
```

Both marker centres are therefore exactly one `trackRadius` from the ring
centre. The existing sphere material and post-fill paint order are unchanged.

### YEAR cells

Each calendar month is independently placed in `slotSweep = 2π / 12`.
`annualSegmentVisibleGap = 8` source units and track width `24` yield
`centerlineGapLength = 32`, `centerlineGapRadians = 0.297619048` and fixed
painted sweep `0.225979728`. Each start is:

```text
canonicalStart + monthIndex * slotSweep + centerlineGapRadians / 2
```

so DEC→JAN has the same cap-aware 8-unit visible void as every other pair.
`BudgetProgressRingAnnualHealthMaterial` applies only lightness changes to
canonical health green/yellow/red (or neutral grey); it cannot rotate hue.
The annual branch now bypasses `_SelectionArcGradient.fromCategoryColor`
entirely.

## Tasks

### Task 1: Test and add Summary mirror orientation

- [x] Add RED settings/geometry/widget tests for normal and mirrored rect
  order, unchanged widths/gap, mirrored mode inset, separator midpoint and
  direct selector flings.
- [x] Extend settings/controller/tuner with the default-normal orientation.
- [x] Make the existing Rect resolver mirror zones and component Rects without
  changing content direction or selector ownership.
- [x] Run focused Summary tests green.

### Task 2: Test and correct DAY marker circle intersections

- [x] Add RED geometry tests for `distance(center, marker) == trackRadius`,
  mirrored X, fixed 75%-gauge Y, unchanged radius/material and no line.
- [x] Replace outside-offset placement with the circle-intersection formula.
- [x] Run DAY ring and MONTH regression tests green.

### Task 3: Test and correct YEAR cell material and cap-aware gaps

- [x] Add RED tests for twelve independent equal slots, equal positive
  cap-aware visible gap including DEC→JAN, and green/yellow/red/neutral
  hue-preserving material.
- [x] Derive angular centerline gap from a named visible-gap token plus one
  track-width cap allowance, then derive each start from `index * slotSweep`.
- [x] Introduce a dedicated annual health material resolver and remove the
  category hue-shift path from annual paint.
- [x] Run ring painter/raster tests green and inspect the mixed-health raster.

### Task 4: Documentation and delivery verification

- [x] Update this plan/checklist with final formulas, tokens, tests and
  truthful physical-validation status.
- [x] Run targeted/protected suites, analyzer, diff check and online Android
  CI for the production commit.

## Verification record before commit

- Focused Summary settings/tuner/geometry/presentation suite: **45 passed**.
- Budget controller, pace, selected-ring and surface suite: **63 passed**;
  final complete selected-avatar rail/raster suite: **30 passed**.
- Prepared Budget snapshot/rhythm, scene cache and vertical-scroll suite:
  **53 passed**.
- Time-navigation/visible-scene/scroll-contract/limit-edit suite: **60
  passed**.
- `flutter analyze`: **No issues found** (96.2 seconds).
- `dart format --set-exit-if-changed` and `git diff --check`: pass.

The mixed-health YEAR raster is
`test/goldens/budget_annual_fixed_health_cells.png`; it was visually inspected
after creation. It shows twelve equally slotted capsules and no category-hued
active segment.

### Inherited baseline failures, not changed or golden-updated

At both this worktree and detached baseline `004bbfc`,
`dashboard_scroll_milestone_test.dart` fails at line 155 with `Bad state: No
element`. At both revisions the complete Core geometry golden suite differs in
all six expected images (6.25–7.98% pixels) and the Core Dashboard test cannot
find `budget-distribution-pager` at line 173. The same output was reproduced
before classifying it as inherited. No baseline golden was updated. Physical
Android validation remains required and has not been claimed.

## Delivery evidence

- Production commit: `ab33fe048dc6b1b9ac12b613f5b9239fc0793249`
  (`fix(dashboard): mirror summary and correct budget ring`).
- Pushed remote production SHA: the same `ab33fe0`.
- GitHub Actions run `33132627613`: success for Flutter, Android/Room core,
  human diagnostic APK and A–J dashboard profile.
- Human APK:
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_ab33fe0.apk`
  (79,746,249 bytes), SHA-256
  `8d92e76b7efc2213b62468c7615ea852d9b6d0b780c8218f107fc052721a579a`.

This is a build artifact for human device validation, not a claim that the
requested physical checks have been performed.
