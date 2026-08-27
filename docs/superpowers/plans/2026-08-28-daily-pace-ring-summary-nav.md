# Daily pace, fixed annual ring, and physical geometry implementation plan

> **For agentic workers:** Execute inline. The Budget controller publishes one
> immutable scope analysis to the Header and selected-avatar chrome; splitting
> its model and renderer across concurrent edits would make the scope contract
> harder to review.

**Goal:** Correct DAY Budget to explicit daily pace, render YEAR as twelve
fixed health cells, and close the outstanding Summary visual/hit-Rect contract
without regressing the shared BottomNav contour or dashboard interaction paths.

**Architecture:** `DashboardBudgetMonthEndProjection` remains the pure
prepared-data owner for secondary month-end projection, but grows explicit
daily-average and pace fields. `DashboardBudgetDayProjectionAnalysis` exposes
the DAY display pair separately from canonical monthly actual used by edits.
The one selected-ring geometry continues to own material/radius/caps; strategy
input changes its DAY markers and YEAR fixed-cell rendering. Summary receives
one actual Rect per section—no second content Rect or padded hidden hit lane.

**Tech Stack:** Flutter/Dart, prepared dashboard data, CustomPainter,
`package:flutter_test`, Android native financial-limit batch path already on
the branch. Run Flutter checks through Ubuntu/proot; Android APK is GitHub
Actions only.

## Global constraints

- Existing active financial-limit persistence is base monthly plus concrete
  monthly override; do not introduce daily, annual, or lifetime truth.
- Day/Month share the concrete month override key and existing edit controller.
- Keep all forecast/pace/ring fields pure and derived; canonical actual never
  becomes forecast or pace input in the edit context.
- Keep one ring geometry/material authority and no TextPainter in paint paths.
- Preserve prepared temporal publication, bounded scene/cache ownership and
  the one LogBox ScrollController/ScrollPosition.
- Preserve Rounded/Straight BottomNav modes, FAB bounds and hit testing.

---

## Daily pace architecture card

### Scope and sources

- User requirement: 2026-08-28 Daily pace correction prompt.
- Accepted visual evidence:
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-004609.png`
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-004552.png`
  - `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-003554.png`
  - read-only `spendeetest` artifact:
    `docs/prototypes/balance_b3m_budget_fluvi_avatar_disc_static_test.js`.
- Existing implementation:
  - `lib/features/dashboard/application/dashboard_budget_month_end_projection.dart`
  - `lib/features/dashboard/application/dashboard_budget_scope_analysis.dart`
  - `lib/features/dashboard/application/dashboard_budget_presentation_controller.dart`
  - `lib/core/categories/presentation/budget_category_avatar_artwork.dart`

### Single source and write path

- Persistent source of truth: base monthly limit plus concrete monthly override.
- Read model: prepared limit/rhythm snapshots and immutable scope analysis.
- Only write path: existing `DashboardBudgetLimitEditController` then financial
  limit repository; YEAR retains its existing one semantic batch mutation.
- DAY interaction never writes a pace, projection, or daily limit.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Logical as-of date | `DashboardCoreController` injection | Core lifetime | Passed once to presentation |
| Daily pace / projection | pure `DashboardBudgetMonthEndProjection` | Prepared revision/month/target/as-of | Rebuilt only on semantic key change |
| Canonical edit actual | prepared monthly cell | immutable prepared frame | Only value passed into limit edit context |
| Header/ring view data | `DashboardBudgetPresentationController` | visible-frame publication | One immutable live selection |
| Ring geometry/material | `BudgetProgressRingGeometry.source` | application static | All strategies consume it |
| Summary section Rect | `SummarySegmentedTrackGeometry` | layout pass | Same Rect builds visual, hit and semantics |

### Layer flow

Prepared snapshot → pure scope analysis → presentation controller → immutable
Header/selected-ring state → widgets/painter. UI forwards limit gesture intent
only to the existing edit controller.

### Verification

- Pure DAY pace and YEAR cell tests.
- Controller/header/edit identity tests.
- Ring painter contracts and widget raster/geometry tests.
- Summary direct-Rect fling tests; BottomNav composed raster symmetry tests.
- Prepared interaction and protected dashboard suites.

## Tasks

### Task 1: Add explicit DAY pace semantics

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_budget_month_end_projection.dart`
- Modify: `lib/features/dashboard/application/dashboard_budget_scope_analysis.dart`
- Test: `test/features/dashboard/application/dashboard_budget_month_end_projection_test.dart`
- Test: `test/features/dashboard/application/dashboard_budget_scope_analysis_test.dart`

- [x] Write RED tests for 120k on day 10 of a 30-day month with 300k limit:
  monthly utilization `.40`, actual daily average `12k`, allowed daily average
  `10k`, pace ratio `1.20`, visual fill `.90`.
- [x] Run the focused test and confirm the current projection-first API fails
  the new daily-average assertions.
- [x] Add immutable `actualDailyAverageScaled100`,
  `allowedDailyAverageScaled100`, and `paceRatio`; retain
  `projectedMonthEndScaled100` as explicit secondary derived information.
- [x] Make future pace unavailable, keep past/current as-of policies, and
  retain half-up scaled-money division.
- [x] Run focused tests green, including zero-spend and 28/29/30/31-day cases.

### Task 2: Publish pace display without contaminating edits

**Files:**
- Modify: `dashboard_budget_scope_analysis.dart`
- Modify: `dashboard_budget_presentation_controller.dart`
- Modify: `dashboard_prepared_formatter.dart`
- Modify: `budget_dashboard_core_surface.dart`
- Test: `dashboard_budget_presentation_controller_test.dart`
- Test: focused Header widget test if required by current harness

- [x] Write RED controller/Header tests for `Ft/nap / Ft/nap`, selected-day
  invariance, same monthly edit key, and optimistic allowed-average/pace
  recomputation.
- [x] Verify RED against the current forecast/limit Header binding.
- [x] Give DAY its own typed display pair while preserving canonical monthly
  actual for the edit context and partition code.
- [x] Add presentation-level amount-per-day formatting; do not add Hungarian
  copy to domain calculation code.
- [x] Run controller/Header/edit tests green.

### Task 3: Refactor shared ring strategies

**Files:**
- Modify: `budget_category_avatar_artwork.dart`
- Modify: `dashboard_budget_presentation_controller.dart`
- Test: `budget_category_avatar_rail_test.dart`
- Test: `dashboard_budget_presentation_controller_test.dart`

- [x] Write RED tests for two symmetric DAY marker centres at `.75` height,
  common 3D marker material and absence of a horizontal break-even line.
- [x] Write RED tests that YEAR has twelve fixed equal sections; healthy is
  Fluvi green, future/missing are neutral, and section length is independent
  of each month ratio.
- [x] Implement marker geometry from `BudgetProgressRingGeometry.source`; use
  one reusable sphere material for both sides.
- [x] Replace variable YEAR mini-sweeps with full fixed capsule sections,
  independent green/yellow/red/neutral state, and preserve the shared track,
  cap language and SUM/MONTH strategies.
- [x] Run painter and controller tests green.

### Task 4: Correct Summary Rect ownership

**Files:**
- Modify: `summary_pill_experiments.dart`
- Test: `summary_pill_experiments_widget_test.dart`

- [x] Write RED assertions that each content Rect is literally its owner/hit/
  semantics Rect, with no touch-envelope widening; retain equal half-baseline
  gaps, large icon insets and amount-zone bounds.
- [x] Verify RED against the current wider section Rect implementation.
- [x] Remove the secondary `visualContentRect`/touch-width model and make one
  calculated Rect own `Positioned`, clipping, semantics and carousel input.
- [x] Run geometry and direct selector fling tests green.

### Task 5: Revalidate BottomNav common geometry

**Files:**
- Inspect/Test: `bnb03_bottom_navigation.dart`
- Test: `bnb03_bottom_navigation_test.dart`

- [x] Run source and raster symmetry matrix on current common circle path.
- [x] Change production geometry only if an actual failing test proves a
  remaining divergence; keep one fill/top-edge path and one foreground stroke.

### Task 6: Documentation, protected verification, delivery

- [x] Update the focused checklist with factual baseline, r45 evidence,
  source root causes and truthful statuses.
- [x] Run all targeted and protected tests in Ubuntu/proot, analyzer and
  `git diff --check`.
- [ ] Inspect diff/status, commit focused production + tests/docs, push
  `separated-core-modes`.
- [ ] Monitor Actions for that exact SHA and download the normal human APK to
  `/storage/emulated/0/Download/fluvi`; verify SHA-256.
