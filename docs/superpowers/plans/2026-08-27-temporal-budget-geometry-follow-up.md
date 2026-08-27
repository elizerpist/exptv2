# Temporal Budget preview and geometry follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish every prepared temporal crossing to the complete Budget and
LogBox presentation in one interaction epoch, then add the requested
presentation controls without changing accepted dashboard semantics.

**Architecture:** The existing `DashboardVisibleFrameStore` remains the one
temporal preview owner. `DashboardBudgetPresentationController`, rhythm,
partition, and Card2 must project that exact visible preview frame rather than
waiting for committed navigation or a cache-miss drawable warmup. The
distribution drawable bank keeps its bounded visual cache, but a missing Canvas
bank may not block a prepared semantic data projection; cache warming is
secondary and stale-guarded. All new visual preferences use immutable
dashboard-lifetime controllers/scopes, matching existing tuner conventions.

**Tech Stack:** Flutter/Dart, `ValueNotifier`, prepared dashboard snapshots,
custom-painted LogBox, existing BottomNav `CustomPainter`, `CenteredCarousel`.

## Global constraints

- Work only on `separated-core-modes`; `spendeetest` is read-only.
- Preserve the existing avatar/LogBox fling-parity route, bounded caches, one
  LogBox `ScrollController`/`ScrollPosition`, prepared text/scenes, and stale
  generation guards.
- Do not reduce crossing frequency, tune animation duration, debounce,
  settle-gate, query per crossing, or introduce a second temporal owner.
- Each behavior change starts with a targeted failing test that is observed
  red in Ubuntu/proot before production code changes.
- New visual settings reproduce current HEAD by default and remain independent
  of border, corner, shadow, row height, palette, Summary and Budget settings.
- Android APK verification runs on GitHub Actions after the production commit;
  local Termux builds are not used.

## Root-cause evidence before code

- Fluvi Logs Drive document `13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU`,
  revision **42** (2026-08-27 05:05:50Z) is the current trace source.
- In its day-fling sequence, `19:44:14.02`, `.13`, and `.23` each show
  `VERTICAL_PREVIEW_ROOT_ARM_*`, `BUDGET_HEADER_VALUE_BOUND`,
  `BUDGET_PROGRESS_BOUND`, and `LOGBOX_SCENE_SELECTED` for the same day/
  category query while physical preview continues.
- Those crossings have no matching `BUDGET_DISTRIBUTION_*` publish or
  `BUDGET_RHYTHM_BOUND` event. Current
  `CoreDashboard._onBudgetDistributionVisibleFrame` only calls
  `publishIfReadyForTimeScope`; on a cache miss it returns during
  `foregroundInputMotion`. `DashboardCoreController` likewise defers drawable
  warming while that motion lane is active. Thus prepared LogBox/header data
  advances, while the Card2 Canvas cache is not admitted until idle/settle.
- The fast Avatar control directly changes `DashboardBudgetPresentationController`
  from `BudgetTargetAvatarRail`; the current selected target updates without
  Card2 cache preparation. The temporal repair must preserve that direct route.

## File map

- `lib/features/dashboard/application/dashboard_core_controller.dart`:
  temporal accepted-crossing epoch and bounded secondary warmup scheduling.
- `lib/features/dashboard/application/dashboard_budget_presentation_controller.dart`,
  `dashboard_budget_rhythm_controller.dart`, and distribution controllers:
  shared visible-frame temporal projection and diagnostics.
- `lib/features/dashboard/presentation/core_dashboard.dart` and
  `core_modes/budget_category_distribution_visual_bank.dart`: Card2
  cache-hit binding plus prepared-data fallback without a motion/settle gate.
- `lib/core/design/dashboard_layout_metrics.dart`,
  `dashboard_mode_palette.dart`, and LogBox header/viewport widgets: central
  handle-count and SearchPill footprint resolution.
- `lib/app/shell/bnb03_bottom_navigation.dart`: sole BottomNav contour path,
  clipping and top-border painter.
- `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`,
  budget distribution/rhythm surfaces, Header controller/tuner: Header and
  Budget visual geometry.
- `lib/features/dashboard/presentation/dashboard_summary_presentation.dart`
  and `widgets/summary_pill_experiments.dart`: Dynamic Trio cooldown only.
- current dashboard tuner/settings files and corresponding existing test
  suites: immutable settings, reset and independence.

### Task 1: Establish temporal preview contracts

**Files:** visible-frame/Budget controller, rhythm/distribution controller
tests; boundary performance test.

- [ ] Write RED tests proving real prepared YEAR/MONTH/DAY crossings preserve
  the selected target and synchronously advance Header, avatar/progress,
  partition, distribution selection/frame, rhythm and LogBox with one epoch.
- [ ] Run the focused tests in Ubuntu/proot; capture current cache-miss
  distribution/rhythm failure and zero repository-call expected behavior.
- [ ] Extract only the shared temporal preview projection seam indicated by
  the tests; make cache-hit selection synchronous and data fallback
  lightweight/immutable while bounded Canvas warming is secondary.
- [ ] Assert rapid A→B→C→D stale work cannot replace D and Avatar control
  remains immediate.
- [ ] Run navigation, prepared-cache, Budget preview/rhythm/distribution and
  LogBox temporal suites green.

### Task 2: Central LogBox geometry and SearchPill visibility

**Files:** layout metrics/tokens, header, viewport, settings/tuner and tests.

- [ ] Write RED tests pinning current handle-to-count metric, one-half result,
  exact visible-viewport delta, SearchPill Show baseline, Hide no semantics or
  hit test, individual/combined footprint reclaim and scroll identity.
- [ ] Run them red from current HEAD.
- [ ] Halve the resolved current metric in the shared layout resolver; make
  SearchPill visibility a centralized presentation setting whose false branch
  removes its exact structural footprint only.
- [ ] Run LogBox geometry/search/scroll identity tests green.

### Task 3: BottomNav and Header presentation settings

**Files:** BNB-03 painter/path, header presentation settings/tuner, Budget
header surface and tests.

- [ ] Write RED path/geometry tests for rounded/straight outer edges and one
  thin contour following the unchanged FAB curve; add tests for defaults and
  immutable setting independence.
- [ ] Add one canonical BNB-03 contour builder shared by fill, clip and border.
- [ ] Write RED Header tests for symmetric partition insets, 0/50/100%
  centerline thickness, white/black foreground paint-only behavior and Budget
  target name semantics.
- [ ] Port the source-authored Spendee BudgetV2 typography only: title at
  x=20/y=16, 10px, w900, height 1; value below 7px gap at 19px, w900,
  height .96, letter spacing -.76; preserve Fluvi amount semantics.
- [ ] Run BNB/Header/tuner tests green.

### Task 4: Dynamic Trio and lower Budget geometry

**Files:** Summary presentation/experiment; unified page surface and partner
distribution geometry; tests.

- [ ] Write RED fake-time tests for ballistic-settle-only cooldown, immediate
  non-ballistic collapse, cancellation on new interaction/setting/dispose, and
  unchanged query/crossing sequence.
- [ ] Implement one bounded Dynamic Trio cooldown owner with a 2–3 second
  documented token; do not add selection state.
- [ ] Write RED geometry tests for positive Unified lower-dot gap in the
  avatars-first/chart-second case, Partner-only 90% diameter and equal rhythm
  plot gain, with category diameter unchanged.
- [ ] Apply smallest layout-space reallocation; retain outer card and avatar
  envelopes.
- [ ] Run Summary/Budget surface/page/rhythm suites green.

### Task 5: Documentation, review, delivery

- [ ] Update the companion checklist with r42 trace, root cause, exact metrics,
  source paths/defaults, tests and remaining physical validation.
- [ ] Read `MILESTONE_COMMITS.md` policy; update only if this delivery is a
  documented milestone candidate.
- [ ] Run full relevant Ubuntu/proot Flutter suites, `flutter analyze`,
  `git diff --check`, and inspect final status/diff.
- [ ] Commit one focused production change, push branch, monitor the exact
  GitHub Actions human diagnostic APK job, download it to
  `/storage/emulated/0/Download/fluvi`, and verify SHA-256.
