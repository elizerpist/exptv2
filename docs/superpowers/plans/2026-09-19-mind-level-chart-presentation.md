# Mind level transition, chart inspection, and presentation controls implementation plan

> **For agentic workers:** Execute inline with RED → GREEN checkpoints. The Core temporal frame, Header score, Mind body, palette resolver and range control are shared owners; parallel production edits would race or duplicate their contracts.

**Goal:** Restore immediate Month-body publication on DayScope → MonthScope level closure, and add the requested presentation controls without altering financial, query, Time, or score ownership.

**Architecture:** `DashboardCoreController` remains the only semantic target admission owner. Level and component paths converge through its accepted-target contract and publish the identical body and Header provenance. `MindYearHeatmapPresentationController` owns both visual scale and legend placement; `MindYearHeatmapPaletteResolver` remains the only palette authority. Crosshair state is ephemeral inside the Header-chart widget and a shared pure epoch-day projection owns all chart X geometry.

**Tech Stack:** Flutter/Dart, `ValueNotifier`, immutable Mind projections, `flutter_test`, existing Ubuntu/proot Flutter tooling.

## Global constraints

- Base application source: `c1b12ade9745ce96143ce3c6a275c2c12ac4d349`; prompt-time journal head: `97797ef4659aadccc582e6fd4364bf01a472a5c4`.
- Source evidence: Drive `Fluvi mind heatmap`, revision 6, SHA-256 `46682010d3a002a7b2eafc9414cc55c5d2bc71e355aef198c8e10990cb8daa95`; screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260919-073848.png`.
- No new Time plane, temporal notifier, Query/score owner, timer, delay, retry, persistence, repository/index work on an admitted target, or raw financial calculation in UI.
- Preserve Time/Avatar physics and controller identity, Query/range semantics, score maths and colour policy, LogBox, Room/Kotlin/schema, Budget, Day aggregation, Year inspection and `MILESTONE_COMMITS.md`.
- Each application change follows a separate journal-only `[skip ci]` commit. The final application commit is the build-triggering tip.

## Task 1: Lock the Day → Month level regression with real Core and host RED tests

**Files:**
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify: existing direct Mind-host test discovered in `test/features/dashboard/presentation/`

- [ ] Mount a real Month-plane DayScope with the rail open, then call `navigateExperimentalTemporalSelection(plane: TimePlane.month, isRailOpen: false)`.
- [ ] Assert the first accepted target is a `MindMonthHeatmapFrame` for the accepted Month, the Day frame/grid is absent, the Month grid has positive bounds and Header target provenance is Month.
- [ ] Run the named test at `c1b12ade`; record RED before production code changes.

## Task 2: Generalize the one Core-owned accepted target admission to level closure

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: Task 1 tests and existing Month component tests

- [ ] Route the exact accepted level candidate through the same existing Month body + score admission contract used for renderer-acknowledged component crossings.
- [ ] Retain latest-wins identity and fail closed if body and score cannot publish together.
- [ ] Verify repeated Day ↔ Month returns, zero repository/index/Query work, Header/body atomicity and component/Day positive controls.
- [ ] Commit the focused application change, then append one journal-only commit.

## Task 3: Add 10/20 colour resolution through the existing settings and resolver

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart`
- Modify: direct settings/resolver/tuner tests

- [ ] Add failing settings and exact-anchor tests for default ten, twenty selection and no-op revision behavior.
- [ ] Extend the existing controller and one resolver with the specified authored twenty-stop lists; retain byte-compatible ten-stop output.
- [ ] Pass the selected resolution to every Sum/Year/Month/Day tile and legend without replacing any financial frame.
- [ ] Commit the focused application change, then append one journal-only commit.

## Task 4: Compact and relocate the existing Mind legend without altering range ownership

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/query/presentation/query_amount_range_control.dart`
- Modify: Mind host/range widget tests

- [ ] First capture RED baseline Rects for temporal content, legend, footer, slider and Min/Max.
- [ ] Add the presentation-only placement setting; above reserves 16px and the compact footer reserves 68px only if mounted bounds prove no clipping.
- [ ] Pass an optional read-only center accessory to the compact Mind range row for the inline legend; standard Query remains unchanged.
- [ ] Verify hidden/above/inline modes, swatch sizes/counts, 18/34px body gains, RangeSlider identity and gesture semantics.
- [ ] Commit the focused application change, then append one journal-only commit.

## Task 5: Make Header-chart geometry temporal and add chart-local tap inspection

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_header_score_chart.dart`
- Modify only if explicit presentation context needs a typed view-model: its existing presentation/domain consumer
- Modify: direct chart and golden tests

- [ ] Add a sparse-series RED proving list-index X diverges from epoch-day X.
- [ ] Introduce one pure epoch-day → normalized X mapping used by line anchors, labels, nearest-point hit test and crosshair.
- [ ] Add chart-local selected point state, tap-slop observation that preserves Header vertical drag, mode-aware labels, same-point toggle and synchronous series-reset.
- [ ] Add one selected-crosshair golden and validate zero Core/score/query/data work on repeated taps.
- [ ] Commit the focused application change, then append one journal-only commit.

## Task 6: Switch Summary startup presentation defaults without manufacturing a transition

**Files:**
- Modify: `lib/features/dashboard/presentation/summary_pill_variant.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_summary_presentation.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: direct Summary/controller/widget tests

- [ ] Add RED assertions for default segmented + mirrored, transition epoch zero and a real first-frame segmented selector.
- [ ] Allow explicit initial variants for transition-specific tests, switch product defaults, and initialize Core bookkeeping from the actual controller value.
- [ ] Verify tuner reversibility and no synthetic Legacy → Segmented transition.
- [ ] Commit the focused application change, then append one journal-only commit.

## Task 7: Complete verification and delivery

- [ ] Run every named focused Flutter test in the specification inside Ubuntu/proot, then analyzer, fast suite, boundary verification and `git diff --check`.
- [ ] Freeze final app SHA, push with the final application commit at the tip, audit each CI job, download/hash/inspect the normal HUMAN_DIAGNOSTIC APK, and regenerate the exact-SHA SCIP graph.
- [ ] Append final journal-only evidence, re-read the acceptance checklist and report physical validation as user-only.
