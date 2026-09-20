# Mind Sum Three-Mode Refinement Implementation Plan

> **For agentic workers:** Execute in this worktree with test-first steps and
> update `2026-09-20-mind-detailed-sum-zoom.md` after every verified unit.

**Goal:** Give Mind/Sum three button-selected surfaces while making detailed
zoom usefully deep, inspectable and vertically complete.

**Architecture:** Core continues to publish one immutable Sum frame. A local
Sum visualization enum selects its renderer; a pure temporal model defines
zoom reachability, and a neutral monthly comparison read model is supplied by
Sum and Year adapters without changing Query ownership.

**Tech Stack:** Flutter/Dart, immutable Mind projections, Flutter widget tests.

## Global constraints

- Do not read Drive logs for this delivery.
- No Sum PageView, PageController, page dots or horizontal mode swipe.
- Do not restore the removed exact yearly Sum page.
- Keep the existing `QueryAmountRangeControl` outside chart gesture owners.
- Preserve the `6e96218` Avatar/Time interaction floor.

### Task 1: Three-mode topology and neutral overlay model

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Create: `lib/features/dashboard/mind/domain/mind_monthly_overlay_series.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Test: `test/features/dashboard/mind/domain/mind_monthly_overlay_series_test.dart`

1. Add failing tests for three toggle choices, no Sum PageView, bar rendering,
   full/filtered values, palette-resolved foreground and range update.
2. Run them RED in Ubuntu proot.
3. Extract only generic monthly overlay values/scale/painter geometry; adapt
   Year from its existing frame and Sum from its immutable preview frame.
4. Add the third top-right toggle and direct bar composition, then run GREEN.

### Task 2: Useful cumulative detailed zoom and tap inspection

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Test: `test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

1. Add domain RED tests for a six-month-or-less reachable window and
   compounded scale sessions.
2. Add mounted RED test tapping between anchors and asserting the nearest
   actual anchor's local date/amount infocard.
3. Define a bounded zoom sensitivity in the pure time-window model and route
   scale updates through it; keep focal point temporal position stable.
4. Reuse `MindAnchoredInfoCard` for the selected anchor, make selection
   local/identity-reset, then run tests GREEN.

### Task 3: Detailed band completeness and separators

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

1. Add RED geometry test for two full bands and their second X-axis labels.
2. Add RED painter/semantics test for visible dashed month separators.
3. Allocate two-band height only after allowing the axis footer, retain the
   minimum band for 3+ scrolling, and restore calendar-boundary dashes.
4. Run the focused suite GREEN.

### Task 4: Full verification and delivery

1. Format changed Dart files in Ubuntu proot.
2. Run focused Mind domain/viewport/host/range/Year smoke tests, analyzer,
   fast and boundary suites, and `git diff --check`.
3. Re-read this checklist, mark only verified rows DONE, commit each logical
   application unit, and append separate `[skip ci]` journal-only evidence.
4. Push the final application SHA, audit each CI lane, download/hash the
   normal human APK, regenerate exact-source SCIP, then append final journal
   evidence without changing application source.
