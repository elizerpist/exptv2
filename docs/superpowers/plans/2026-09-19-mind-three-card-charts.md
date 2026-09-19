# Mind three-card charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved Sum and Year three-card Mind visualizations,
presentation choices and cell/point inspection without changing financial or
gesture ownership.

**Architecture:** Extend the existing immutable Mind projections with annual
and monthly aggregate points, then render both new charts through one shared
aggregate-chart and anchored-infocard primitive. Existing `PageView`, range
control and vertical-boundary handoff remain owners; each new selection is
ephemeral viewport state.

**Tech Stack:** Flutter/Dart, existing immutable Mind frames, `CustomPainter`,
WidgetTester, Ubuntu-proot Flutter validation.

## Global Constraints

- No fresh Drive audit unless a deterministic unexpected runtime defect forces it.
- No Query/Time/Avatar/Room/Kotlin/schema/score/LogBox/MILESTONE change.
- Slider remains outside the pager and the sole range owner.
- Production code follows an observed RED → minimal GREEN cycle.
- Each production application commit gets a separate journal-only `[skip ci]` child.

---

### Task 1: Aggregate read models and Sum presentation settings

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Test: `test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart`
- Test: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`

**Interfaces:**
- Produces `MindAggregateLinePoint`, `MindSumHeatmapFrame.yearlyPoints`,
  `MindSumYearRowLayout`, and `MindSumMonthLabelPlacement`.
- A point is `(ordinal, label, total)` and is immutable/presentation-neutral.

- [ ] **Step 1: Write RED domain/settings tests.** Require continuous internal
  zero years, one current-preview total per year, default expanded/no labels,
  setters that revision only on real change, and no Query/Time mutation API.
- [ ] **Step 2: Run RED.**
  Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart test/features/dashboard/mind/domain/mind_presentation_settings_test.dart --reporter expanded'`
  Expected: FAIL because annual-point/settings APIs do not exist.
- [ ] **Step 3: Implement minimal immutable projection and settings.** Bucket
  no additional source rows at preview; build continuous annual values from
  existing year totals; add controller/tuner paths only for presentation.
- [ ] **Step 4: Run GREEN and commit.** Re-run the exact command, format
  changed Dart, commit `feat(mind): add aggregate chart presentation data`,
  append a journal entry, then make its journal-only child.

### Task 2: Shared line-chart, clean-tap and anchored infocard primitive

**Files:**
- Create: `lib/features/dashboard/mind/presentation/mind_aggregate_line_chart.dart`
- Test: `test/features/dashboard/mind/presentation/mind_aggregate_line_chart_test.dart`

**Interfaces:**
- Consumes `List<MindAggregateLinePoint>`, palette color and bounded plot
  constraints.
- Produces `MindAggregateLineChart` with `onSelectionChanged`, point geometry,
  minimum slot width, an optional internal horizontal scroll and a clamped
  popup. `MindCleanTapRegion` is passive and uses movement slop.

- [ ] **Step 1: Write RED widget/painter tests.** Cover one/two/many points,
  selected tooltip, left/right popup clamp, clean tap vs drag, fixed year slot
  width and scroll only when content is wider than the plot.
- [ ] **Step 2: Run RED.**
  Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/mind/presentation/mind_aggregate_line_chart_test.dart --reporter expanded'`
  Expected: FAIL because the primitive is absent.
- [ ] **Step 3: Implement minimal shared primitive.** Draw reference-family
  line/fade/guides/ticks; keep one local selected ordinal; expose a bounded
  plot hit region so outer page swipes remain available elsewhere.
- [ ] **Step 4: Run GREEN and commit.** Re-run, format, commit
  `feat(mind): add reusable aggregate chart inspection`, journal, then
  journal-only child.

### Task 3: Sum three-card stack, heatmap choices and month inspection

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Test: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`

**Interfaces:**
- Consumes Task 1 settings/year points and Task 2 primitive.
- Keeps `_MindSumLinePage` semantic daily anchors as page index 2; page index
  1 is exact annual aggregate chart.

- [ ] **Step 1: Write RED mounted tests.** Require page order `0/1/2`, old
  daily page still mounted at 2, exact title/subtitle, month cell tap/popup,
  both Sum layouts, all label placements, stable slider element, and page
  switches that retain frame identity.
- [ ] **Step 2: Run RED.**
  Run the two exact test files in Ubuntu proot; expected failure is missing
  third-page/settings/inspection keys.
- [ ] **Step 3: Implement Sum composition.** Keep range footer outside;
  render page 0 variants from the central palette resolver; use one Sum-local
  selected month and shared popup; insert annual chart and move existing
  daily page without altering its data semantics.
- [ ] **Step 4: Run GREEN and commit.** Include page/slider/vertical-hand-off
  test coverage, format, application commit, factual journal child.

### Task 4: Year monthly chart and day-cell inspection migration

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Test: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`

**Interfaces:**
- Consumes current frame month-day totals and Task 2 primitive.
- Produces page order heatmap/bar/monthly-line, and a local non-empty day
  selection. MonthCard no longer receives an inspection `onTap`.

- [ ] **Step 1: Write RED tests.** Require three pages, 12 filtered monthly
  points, range replacement update, bar page preservation, no MonthCard
  button semantics, non-empty day cell tap/popup and empty-day noninteractivity.
- [ ] **Step 2: Run RED.** Run the Year viewport/host tests in Ubuntu proot;
  expected failure is missing line page/day-cell selection.
- [ ] **Step 3: Implement minimal Year integration.** Derive 12 values only
  from current immutable frame days; add hit overlays at calendar geometry
  cells; use shared clean-tap/popup; retain existing annual scroll controller
  and bar-page controller.
- [ ] **Step 4: Run GREEN and commit.** Format, run focused host tests,
  application commit and journal-only child.

### Task 5: Gesture regression, full verification and delivery

**Files:**
- Modify: relevant Task 3/4 tests only as required
- Modify: `docs/superpowers/checklists/2026-09-19-mind-three-card-charts.md`

- [ ] **Step 1: Write RED parent gesture tests.** Establish that the slider
  cannot page, chart drag cannot select, chart plot drag scrolls only when
  wider, outer-card swipe works outside plot, and vertical boundary handoff
  remains singular.
- [ ] **Step 2: Run RED, then minimal GREEN repair.** Do not add a second
  recognizer; reuse passive listener/handoff patterns already in the Mind
  viewport.
- [ ] **Step 3: Run final verification.** Required focused Mind tests,
  `dart format --output=none --set-exit-if-changed`, `flutter analyze --no-pub`,
  `./scripts/test-fluvi-fast.sh`, `./scripts/verify-fluvi-boundaries.sh`, and
  `git diff --check` in Ubuntu proot where Flutter is used.
- [ ] **Step 4: Push final application SHA and deliver evidence.** Monitor
  each Actions lane, download the normal Human APK to
  `/storage/emulated/0/Download/fluvi`, verify SHA-256, regenerate exact-SHA
  SCIP, append final journal-only evidence, and leave physical acceptance to
  the user.
