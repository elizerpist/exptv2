# SUM scale, Budget Header semantics, Summary reset and upper-dashboard gesture plan

> **For agentic workers:** Execute inline. The scope is deliberately coupled:
> one shared ring painter, one Budget Header projection, one temporal crossing
> route, and one existing Header expansion owner must remain authoritative.

**Goal:** Add SUM’s three circular reference markers, make Budget Header
numbers self-explanatory, provide a tick-driven Summary reset, and extend the
existing expand/collapse gesture safely across the upper dashboard.

**Architecture:** The existing selected-avatar ring receives a typed SUM scale
projection and reuses its sole 3D sphere material. `DashboardBudgetHeaderPresentation`
gains one scope-semantic projection consumed by the Budget Header. A bounded
Summary reset sequencer drives the existing selector `CenteredCarousel`
controllers, whose normal callbacks retain the prepared crossing pipeline.
`DashboardUpperVerticalGestureCoordinator` forwards eligible vertical input
to the existing `DashboardExpansionController`; nested content hands over only
unconsumed boundary overscroll.

**Tech Stack:** Flutter/Dart, existing prepared Dashboard frame publication,
`CenteredCarousel`, CustomPainter, `flutter_test`; local Flutter checks run in
Ubuntu/proot and the normal human APK is built and downloaded from GitHub
Actions only.

## Global constraints

- Keep the accepted DAY pace, MONTH utilization, YEAR fixed health cells and
  SUM typical-month analysis; no new Budget denominator or stored derivative.
- `BudgetProgressRingGeometry.source` and `BudgetProgressRingSphereMaterial`
  remain the only ring/sphere geometry and material authority.
- Auto-reset uses the canonical `DashboardCoreController.logicalAsOfDate` and
  normal experimental crossing/publication APIs, never a direct final-state
  assignment.
- Preserve real Summary selector Rect ownership in both orientations.
- Preserve one `DashboardExpansionController`, stable child scroll
  controller/position identities, the LogBox boundary, and higher-priority
  selector/avatar/pager gestures.
- No `TextPainter`, database I/O, or transaction scan in new paint or pointer
  hot paths.

## Architecture card

| Concern | Single owner / write path | Reused mechanism | Contract |
| --- | --- | --- | --- |
| SUM scale | `BudgetProgressRingSumScaleMarkers` → `_SelectionChromePainter` | source ring and DAY sphere material | .50/.75/.90 centres are polar points on `trackRadius`; typical marker stays independent below them |
| Header wording | `DashboardBudgetHeaderMetricPresentation` | immutable `DashboardBudgetScopeAnalysis` / live selection | Header formats one projection; no widget-local scope switch |
| Summary reset | `DashboardSummaryAutoResetController` | selector `CenteredCarousel.animateToIndex` and Core crossing methods | mode, year, month run sequentially; a generation token cancels stale automation |
| Upper drag | `DashboardUpperVerticalGestureCoordinator` | existing expansion controller and geometry mapper | one active vertical sequence; taps and child axes retain their owner |
| Nested list handoff | `DashboardUpperVerticalGestureCoordinator.consumeBoundaryOverscroll` | child `Scrollable` / `OverscrollNotification` | child consumes first; only unconsumed edge delta reaches existing expansion |

## Factual baseline / root-cause notes

- Baseline branch/local/remote is `separated-core-modes` at
  `79ce29e92a3e5bca018073ec3f1b89d8b02907f5`, clean and non-divergent.
- Latest inspected *Fluvi Logs* is Drive revision **45** (2026-08-27 07:19
  UTC). The supplied SUM reference is
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-073311.png`;
  it is conceptual, not a pixel geometry source.
- `_SelectionChromePainter._paintTypicalMarker` currently paints only the
  current short SUM marker. DAY’s `BudgetProgressRingDayPaceMarkers` is the
  existing reusable 3D marker geometry/material language.
- `DashboardBudgetHeaderPresentation` currently forwards numbers plus a time
  label (`Összesen`, year/month/date); the Budget Header renders a scattered
  DAY-only formatter branch and static upper-right `budget` label.
- `SummaryPillExperiment` owns exact selector Rects and component crossing
  callbacks, but has no background gesture or sequencer. The hierarchy
  selectors already use `CenteredCarousel` callbacks to call
  `navigateExperimentalTemporalComponentCandidate`.
- `DashboardCoreModeHost` owns only the Header pan arbitration; the collapse
  handle calls the same expansion controller directly. Direction controls and
  Summary background have no expansion ownership. The Budget right legend is
  the existing vertically scrollable upper content and currently owns its
  normal `ListView` independently.

## Tasks

### Task 1: Add typed SUM circular scale markers

**Files:**
- Modify: `lib/core/categories/presentation/budget_category_avatar_artwork.dart`
- Test: `test/features/dashboard/presentation/budget_category_avatar_rail_test.dart`

- [x] Write RED pure assertions for exactly `.50`, `.75`, `.90` marker
  ratios, centreline radius, clockwise independent angles, green/yellow/red
  hue-family material, shared source IDs, painter ordering and independent
  existing SUM marker.
- [x] Add `BudgetProgressRingSumScaleMarkers` and hue-preserving colored
  sphere material projection from shared geometry; paint the scale after the
  current short typical marker.
- [x] Run the focused ring suite RED then GREEN. The selected-avatar painter
  itself consumes the markers; physical/device visual inspection remains a
  delivery validation item, not a claimed result here.

### Task 2: Centralize Budget Header scope semantics

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_budget_presentation_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Test: `test/features/dashboard/application/dashboard_budget_presentation_controller_test.dart`
- Test: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`

- [x] Write RED assertions for metric/mode labels and value source for each
  DAY/MONTH/YEAR/SUM scope.
- [x] Add immutable `DashboardBudgetHeaderMetricPresentation` with target,
  scope labels, per-day formatting intent and supporting-status semantic;
  expose it only from the existing Header presentation adapter.
- [x] Render target → metric label → value and bind the same projection to the
  upper-right Header label without changing Header geometry.
- [x] Run focused unit/widget tests GREEN.

### Task 3: Add bounded, visible Summary auto-reset sequencing

**Files:**
- Create: `lib/features/dashboard/presentation/dashboard_summary_auto_reset_controller.dart`
- Modify: `lib/features/dashboard/presentation/widgets/summary_pill_experiments.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: `test/features/dashboard/presentation/dashboard_summary_auto_reset_controller_test.dart`
- Test: `test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart`

- [x] Write RED pure tests for target resolution, MONTH/current-Y/current-M
  sequence, skipped matching dimensions, no-op, generations and cancellation.
- [x] Write RED widget tests for background-only tap and selector exclusion;
  normal/mirrored bounds, drag-not-tap exclusion and actual selector command
  registration.
- [x] Implement the reset state machine and a narrow selector-motion command
  seam. It drives `CenteredCarousel.animateToIndex`; each visible crossing
  continues to use the existing callbacks into Core’s prepared navigation
  route.
- [x] Cancel from foreground Summary, avatar, direction and upper-drag input;
  run unit/widget tests GREEN.

### Task 4: Centralize upper vertical gesture and nested handoff

**Files:**
- Create: `lib/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart`
- Modify: `lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_pager.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart`
- Test: `test/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`
- Test: `test/features/dashboard/presentation/budget_distribution_page_surface_test.dart`

- [x] Write RED coordinator tests for existing sign mapping, one active
  sequence, cancellation and boundary overscroll handoff.
- [x] Route Header and handle through the coordinator; add background layers
  for non-scrollable upper mode space, Summary and direction controls. Native
  tap-vs-vertical-drag arena semantics keep taps exclusive.
- [x] Add a stable explicit ListView controller and a notification-based
  child-first overscroll handoff. Preserve it through Header expansion and
  test controller/position identity.
- [x] Run focused direction-arena and nested-scroll identity/handoff tests
  GREEN.

### Task 5: Boundary, documentation, delivery verification

**Files:**
- Create: `docs/superpowers/checklists/2026-08-28-sum-header-reset-upper-gestures-checklist.md`
- Modify: focused boundary tests if production source contracts need pinning
- Test: existing prepared-navigation, Budget avatar/pager, LogBox identity and
  MILESTONE suites

- [x] Add fail-closed source/boundary contracts for no second expansion
  controller, no direct reset state assignment and one ring/sphere authority.
- [x] Update plan/checklist with exact marker coordinates, labels, state
  transitions, cancellation and scroll handoff evidence.
- [ ] Run full protected, analyzer, formatting and diff checks. Re-read
  every checklist row before commit; push one focused production commit,
  monitor its normal-human APK job and download its APK with SHA-256.

## Implemented evidence

### SUM circular scale

`BudgetProgressRingSumScaleMarkers.resolve` uses the shared source-space
formula `angle = BudgetProgressRingGeometry.canonicalClockwiseStartAngle +
2π × ratio`. With source centre `(154, 154)` and `trackRadius = 107.52`, the
three centres are `.50 → (154, 261.52)`, `.75 → (46.48, 154)`, and `.90 →
approximately (90.82, 67.01)`. `_paintTypicalMarker` paints the pre-existing
short current arc first, then the three scale spheres. `forHealthColor` only
changes HSL lightness, so it cannot introduce category hue rotation.

### Header vocabulary

`DashboardBudgetHeaderMetricPresentation.forAnalysis` is the one owner for:

| Scope | Metric label | upper-right label | primary pair |
| --- | --- | --- | --- |
| DAY | `Napi tempó` | `tempó` | actual daily average / allowed daily average |
| MONTH | `Havi állás` | `havi budget` | monthly actual / resolved month limit |
| YEAR | `Éves állás` | `éves budget` | annual actual / summed resolved limits |
| SUM | `Havi átlag` | `alap budget` | average monthly spend / base monthly limit |

### Reset and upper-input ownership

The reset phase order is `idle → navigatingMode → navigatingYear →
navigatingMonth → completed` (or `cancelled`). It plans from
`DashboardCoreController.logicalAsOfDate`; it never constructs a day target
or writes final navigation state. Mounted mode/year/month selectors register
their existing `CenteredCarousel` commands, hence each crossing still invokes
Core’s prepared publication callbacks. A generation token and direct-input
hooks cancel obsolete automation. The selector-motion registry has its own
motion generation as well: cancellation while a target selector is not yet
mounted invalidates the waiting command before that selector can attach.

`DashboardUpperVerticalGestureCoordinator` has no progress field: it maps
viewport delta into the pre-existing `DashboardExpansionController`. Header,
handle, direction controls, Summary background and unclaimed mode-card surface
use that owner. `BudgetDistributionPageSurface` retains one `ScrollController`;
only a real `OverscrollNotification` feeds unconsumed delta to the coordinator.

### Local verification record

- `flutter analyze` completed with **No issues found** (127.5 seconds) in the
  Ubuntu/proot environment.
- Focused Header, reset/sequencer, coordinator, Summary normal/mirrored
  background, SUM-ring, direction-arena, distribution-handoff and two
  previously-overflowing app tests passed. The Header metric now occupies the
  fixed seven-pixel title/value lane that existed before this task; it does not
  increase the collapsed Header or partition geometry.
- A full `flutter test` attempt initially found a task-created 1.2px Budget
  Header overflow. It was fixed, and both affected app tests pass directly.
- The rerun reached 499 passing tests before it was stopped after four
  unrelated failures were classified against a clean detached
  `79ce29e9` worktree. All reproduce without this change:
  1. `dashboard_budget_rhythm_controller_test.dart` — injected-clock midnight
     test null-checks a null value at line 174;
  2. `core_dashboard_test.dart` — Budget pager is absent in the Summary/LogBox
     test;
  3. `dashboard_rail_density_trace_test.dart` — month/day trace flings an
     off-screen carousel at y=721 in a 600px test root, then finds no element;
  4. the corresponding year/month trace has the same off-screen-fling/no-
     element failure.

These inherited failures prevent a locally green complete suite. They are not
changed or masked by this delivery; online CI remains required before physical
device acceptance is claimed.
