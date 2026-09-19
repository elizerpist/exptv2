# Mind paging and contained BottomNav implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finalize Mind’s permanent inline palette legend, equalize annual layout height, add Sum/Year visual pagers with resident-data charts, and add an additive contained-flat BottomNav style.

**Architecture:** Existing immutable Mind frames remain the only financial presentation input. `MindSumHeatmapProjection` is extended with bounded local-day amount buckets for the Sum trend; `MindYearHeatmapFrame` supplies Year bar values without a new Query. Page selection lives in each viewport state, outside the range footer. The existing shell presentation controller selects one of two BNB-03 physical geometries; its raised geometry is left unchanged.

**Tech Stack:** Flutter/Dart, existing immutable range-bucket projections, `flutter_test`, existing `ValueNotifier` presentation controllers, Ubuntu/proot Flutter tooling.

## Global Constraints

- Work only on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`, starting from docs head `9d39345779584e558db5d04d1c362901cda83699` and application source `5893b4568f7061c6e643e7ce767ac76716c7c8d1`; retain all pre-existing untracked paths.
- The 2026-09-19 feature contract explicitly excludes a fresh Drive runtime audit. Do not claim feature runtime causality from older traces.
- Preserve the protected `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` Avatar/Time interaction floor and do not modify Time/Avatar physics, controller or position identity.
- Never add a second Query/range/data/score owner, a second RangeSlider, timer, debounce, retry, Room/repository/raw-ledger access from paint/build/preview, or a pager over the existing range footer.
- Use the existing palette resolver, prepared membership and `MindHeatmapAmountRangeBucket`. UI owns rendering and local page selection only; Core/publication and Query state are not presentation-pager write targets.
- Do not build APKs locally. Flutter tests/analysis run only in Ubuntu proot; online CI produces the final human APK. Every application commit receives a separate file-only `[skip ci]` journal commit.

## Files and responsibilities

| File | Responsibility in this delivery |
| --- | --- |
| `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart` | remove obsolete legend preference; remove the four-column-only +50 envelope divergence while retaining the measured shared two-footer fit guard |
| `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart` | immutable Sum daily read model from resident prepared contributions/range buckets |
| `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart` | Sum header/heatmap/chart pager and shared compact money/chart painting |
| `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart` | Year page-local pager and full-vs-filtered twelve-bar rendering |
| `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart` | one permanent inline legend and pager outside the range footer |
| `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart` | delete legend controls; add BottomNav style control |
| `lib/features/dashboard/presentation/core_dashboard.dart` | remove only the special 4×3 envelope request |
| `lib/features/dashboard/presentation/dashboard_shell_presentation.dart` | BottomNav style enum/settings/controller write path |
| `lib/app/shell/bnb03_bottom_navigation.dart` | raised-preserving / contained-flat physical layout selection |

## Architecture card

| Concern | Single source/write path | Existing mechanism extended | Required proof |
| --- | --- | --- | --- |
| Legend visibility/location | Mind presentation settings | remove, rather than retain dead presentation state; inline resolver legend | no control/lane + one inline legend test |
| Sum daily chart data | `MindSumHeatmapProjection.build/preview` | retain one membership scan at projection build and fixed date buckets at preview | day-anchor/range counter tests |
| Year comparison data | `MindYearHeatmapFrame` | `monthlyAggregates` for full and `month()` for preview-filtered | direction/filter/zero math tests |
| Pager gesture | local `PageController` / active page state | PageView only around temporal content | slider drag and vertical handoff parent test |
| BottomNav variants | shell presentation controller | BNB-03 contour/paint layer parameterization | old raster plus new bounds/semantics test |

### Task 1: Lock the permanent inline legend and annual height geometry

**Files:**
- Modify: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`

**Interfaces:**
- Consume `MindYearHeatmapPresentationSettings`, `MindYearHeatmapPaletteResolver.legendSamples`, `QueryAmountRangeControl.compactMindCenterAccessory`.
- Produce a settings type without legend visibility/placement and a `_MindTemporalBody` that always supplies `_MindHeatmapInlineLegend`.

- [x] **Step 1: Write failing setting/tuner tests.** Assert the settings no longer expose legend visibility/placement, the tuner has neither legend control, and 10/20 palette scale options still exist.
- [x] **Step 2: Write failing mounted footer/geometry tests.** Mount Sum/Year/Month/Day at equal card bounds and assert exactly one `mind-heatmap-inline-legend`, no `mind-heatmap-legend-lane`, stable `mind-query-amount-range` element identity, equal 3×4/4×3 envelope bounds, and unchanged reference cell extent.
- [x] **Step 3: Run RED tests in Ubuntu proot.** The baseline contained the old setting/lane; removing the four-column +50 initially exposed the measured 15px two-footer chrome deficit, which was separately RED before its shared annual fit guard was implemented.
- [x] **Step 4: Implement the minimal settings/surface/Core changes.** Delete the obsolete enum/fields/setters/tuner controls and external lane branch; always pass one resolver-owned inline child; retire the four-column-only +50 request and retain only the measured shared two-footer annual fit guard.
- [x] **Step 5: Run focused GREEN tests.** Settings, tuner, mode-host, Year viewport and range-control suites pass in Ubuntu/proot; final device rect comparison remains pending.
- [x] **Step 6: Commit and journal.** Application commit `1bf1fa1e6ae4218e8abc8c351b0e7dae3dc3b9da` and the separate journal commit `6382e2cdfcbe5a18526ccc8766397936a61893a0` recorded the evidence and physical uncertainty; `3e05d97c` later corrected its CI result.

### Task 2: Add a bounded Sum daily trend read model and two-page Sum viewport

**Files:**
- Modify: `test/features/dashboard/mind/domain/mind_temporal_heatmap_projection_test.dart`
- Modify: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`

**Interfaces:**
- Consume `MindYearHeatmapPreparedContribution.bookedLocalEpochDay/amountMinor`, `MindHeatmapAmountRangeBucket.sumWithin`, `MindSumHeatmapFrame.identity/range/yearTotal`.
- Produce `MindSumHeatmapFrame.dailyPointsForYear(int)` immutable points and a Sum viewport-local `PageController` whose pages consume only that frame.

- [x] **Step 1: Write domain RED tests.** Nonuniform local days and range changes assert real epoch-day totals, no synthetic dates and a bounded range-preview read count.
- [x] **Step 2: Run domain RED.** Before the implementation, the missing frame type/method/counter caused compilation failure, proving no daily-point read model existed.
- [x] **Step 3: Extend the existing Sum projection.** Build now groups resident prepared contributions by local epoch day into amount-range buckets; preview exposes only real nonempty daily aggregates under the same range and retains existing monthly behavior.
- [x] **Step 4: Write viewport/parent RED tests.** The baseline lacked approved header/page/painter APIs. The parent coverage asserts slider isolation, no frame replacement, non-scroll direct handoff and long-list boundary handoff.
- [x] **Step 5: Implement the local pager and renderers.** The `PageView` is limited to Sum visual content; page/scroll state is local, footer/range remains outside. A passive boundary-only observer reuses the existing expansion coordinator because PageView suppresses the child overscroll notification.
- [x] **Step 6: Run GREEN suites and commit/journal.** Domain, temporal viewport and mode-host suites are green; application and separate journal commits are the next step.

### Task 3: Add the Year full-versus-filtered bar page

**Files:**
- Modify: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/mind_year_heatmap_mode_host_test.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`

**Interfaces:**
- Consume `MindYearHeatmapFrame.monthlyAggregates`, `MindYearHeatmapFrame.month(month)`, `MindYearHeatmapDay.total`, and active direction already carried by the viewport.
- Produce a viewport-local page index and pure bounded scale model where `foreground <= background` is debug-asserted and paint-clamped only as a safe fallback.

- [x] **Step 1: Write math/widget RED tests.** Cover expense/income full versus filtered values, zero totals, nice scale, pager mount and current range-preview refresh.
- [x] **Step 2: Run RED.** `MindYearHeatmapPartialBarSeries` did not exist; the Year-BAR test failed to compile before implementation.
- [x] **Step 3: Implement pure scale calculation and the secondary page.** Background reads selected directional monthly aggregate; foreground sums current frame month days. A deterministic zero-based nice scale, thin grid and month initials render in a constrained page-two painter.
- [x] **Step 4: Verify mounted gestures.** Page selection remains inside the Year visualization region; external Year controller identity is retained on page zero. A shared passive pager-boundary adapter handles both Sum and Year without a second recognizer or duplicate handoff path.
- [x] **Step 5: Run GREEN suites and commit/journal.** Year viewport, Sum viewport and production host suites are green; application and separate journal commits are next.

### Task 4: Add an additive contained-flat BottomNav layout style

**Files:**
- Modify: `test/app/bnb03_bottom_navigation_test.dart`
- Modify: `test/app/fluvi_app_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_shell_presentation.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify: `lib/app/shell/bnb03_bottom_navigation.dart`

**Interfaces:**
- Consume shell settings in `FluviAppShell` and the existing BNB item callbacks.
- Produce `DashboardBottomNavLayoutStyle.raisedFab/containedFlat`, default `raisedFab`, and `Bnb03BottomNavigation(layoutStyle: ...)`.

- [ ] **Step 1: Write RED settings/tuner tests.** Require the default existing raised choice and reversible selection of contained flat style.
- [ ] **Step 2: Write RED geometry/raster/semantics tests.** Freeze existing raised contour constants. For contained, assert 75px bar envelope, top-contour center at y=0, zero FAB overflow, a visible circle smaller than 84px within physical bar, and a ≥48px semantic/hit rect.
- [ ] **Step 3: Run RED.** Expected failure: style enum/input and contained bounds do not exist.
- [ ] **Step 4: Implement alternate physical geometry.** Preserve raised constants/positions exactly. For contained style use a horizontal contour with existing outer-corner option, a token-aligned visible circle that fits in 75px, and an independently ≥48px transparent interaction shell.
- [ ] **Step 5: Run GREEN and inspect focused raster.** Verify both variants, top-border/edge-shape independence, actions and safe-area mount; do not replace old golden/raster proof.
- [ ] **Step 6: Commit and journal.** Make atomic application then one-file journal commit.

### Task 5: Whole-package verification and delivery evidence

- [ ] **Step 1: Re-read this plan, the acceptance checklist, journal, milestone file and screenshot references.** Mark only verified rows `DONE`; preserve `PARTIAL`/`NOT DONE` honestly.
- [ ] **Step 2: Format and run required local suites in Ubuntu proot.** At minimum run settings, temporal viewport, Year viewport, mode host, tuner, range, BNB03 and app tests; then `flutter analyze --no-pub`, `./scripts/test-fluvi-fast.sh`, `./scripts/verify-fluvi-boundaries.sh`, and `git diff --check`.
- [ ] **Step 3: Audit no-touch boundaries and commits.** Confirm no protected files/systems changed and every app commit has a separate journal child.
- [ ] **Step 4: Push the final application SHA as branch tip.** Monitor individual GitHub Actions lanes; do not call profile globally green if `frame_timing_headroom` remains null.
- [ ] **Step 5: Download and verify the normal human APK.** Store it at `/storage/emulated/0/Download/fluvi`, hash it and verify its exact embedded build SHA.
- [ ] **Step 6: Regenerate exact-source SCIP in the tooling worktree.** Require manifest `source_head` equal final application SHA; test/push tooling separately; append final journal-only evidence after build/graph.

## Plan self-review

The plan maps every approved feature to a stable checklist section. It removes rather than hides obsolete legend state, extends existing prepared/range-bucket data instead of creating a query source, and makes page selection local rendering state outside the slider’s hit region. Raised BottomNav geometry is a protected positive control, not a base to clip. The remaining concrete presentation choices—contained FAB diameter and painter split—are constrained by explicit mounted bounds and semantics RED tests before implementation.
