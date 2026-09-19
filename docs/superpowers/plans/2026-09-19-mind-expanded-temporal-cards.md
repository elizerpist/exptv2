# Mind expanded temporal cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the approved multi-page Mind visualizations without adding a
second Query, prepared-data, palette, formatter, or gesture owner.

**Architecture:** Extend immutable temporal frames only with bounded
presentation read models, reuse the existing aggregate-line renderer and the
Mind page region, and keep selection ephemeral inside the active viewport.

**Tech Stack:** Flutter/Dart, project-native immutable Mind projections,
WidgetTester and domain tests.

## Global Constraints

- Do not read Drive logs for this feature cycle.
- Use the three saved reference PNGs as visual source of truth.
- Keep the Sum tertiary multi-line card and the Year partial-bar card.
- Fixed range footer/always-inline legend and RangeSlider ownership remain
  outside all visual pagers.
- Do not change Avatar/Time/Summary physics, Query semantics, repository/Room,
  score calculations, schema, or `MILESTONE_COMMITS.md`.

### Task 1: Bounded shared temporal read models and chart layout

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_aggregate_line_chart.dart`
- Test: `test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_aggregate_line_chart_test.dart`

- [ ] Write failing domain tests for resident month daily totals and selected-day
  time markers, then run the focused test and observe the missing API failure.
- [ ] Expose only immutable, bounded frame read models from existing prepared
  contribution buckets; run the focused test to GREEN.
- [ ] Write failing widget tests for height-efficient aggregate plotting,
  multi-year minimum slots/scrolling, and twelve-month width fitting.
- [ ] Extend the one aggregate chart renderer and run its focused test GREEN.

### Task 2: Sum three-card contract and primary interactions

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart` only if audit shows a missing existing controller path
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

- [ ] Write RED tests for Sum primary/secondary/tertiary ordering, compact vs
  expanded layout, aligned month labels, and actual-cell popup position.
- [ ] Implement through existing settings/frame/chart owners and make focused
  tests GREEN.

### Task 3: Year card set and actual-cell day interaction

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`

- [ ] Write RED tests preserving heatmap/bar cards, adding the fit-width monthly
  line page, and testing day-cell anchor movement / MonthCard non-interaction.
- [ ] Implement/reuse aggregate chart and bounds-clamped popup; run GREEN.

### Task 4: Month daily rhythm and Day transaction timeline pages

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

- [ ] Write RED production-widget tests for Month page 1 rhythm bars, average,
  stat tiles and Day page 1 timed markers, legend, and stat tiles.
- [ ] Implement pages from immutable frame data and reference hierarchy; run
  focused tests GREEN.

### Task 5: Gesture, boundary, and delivery verification

**Files:**
- Test: relevant existing Mind widget/domain/boundary suites
- Modify: `docs/FLUVI_ENGINEERING_JOURNAL.md` only in separate journal commits

- [ ] Prove page/inner-scroll/slider/tap ownership boundaries with widget tests.
- [ ] Reinspect all three reference images and review changed visual states.
- [ ] Run format, focused suites, analyzer, boundary check, diff check, online
  CI/APK, then exact-source SCIP after final application SHA.

