# Summary liveness, Sum density and Year profitability implementation plan

> **For agentic workers:** Execute inline with review checkpoints because the
> Summary liveness root cause gates later mutation and the Sum/Year renderers
> share presentation state.

**Goal:** Repair the exact-build Summary liveness failure only after a
production-parent reproducer, forensically close any real Sum pan-edge defect,
add the shared 1/2 Sum band-density setting, and add 3×4-only MonthCard
profitability tint controls.

**Architecture:** Keep Summary motion in the shared carousel controller;
centralize both Sum surfaces behind one pure visible-band geometry resolver;
extend the existing Mind presentation controller for all new preferences; and
render profit tint from the existing frame's `netForMonth` output.

**Tech stack:** Flutter/Dart, project-native `flutter_test`, existing Mind
presentation controller, existing immutable heatmap frames.

## Global constraints

- Do not read Drive beyond the frozen facts in the journal.
- Preserve Avatar/Time controller, ScrollPosition and physics identities.
- No PageView/exact annual Sum page, Query, Room, repository, schema or
  RangeSlider ownership change.
- No production code before its minimal RED test and expected failure.
- Push every app commit; append a separate journal-only `[skip ci]` child.

### Task 1: Prove the Summary liveness boundary

**Files:**
- Modify: `test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart`
- Modify only if diagnostic proof requires it: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`

- [ ] Write a production-parent test that enters segmented Sum, completes a
  small direct interaction into Hold, then starts a second selector drag and
  asserts accepted pointer/hit plus absent semantic crossing.
- [ ] Run the named test and record the expected RED failure.
- [ ] Add bounded lifecycle test diagnostics only when public gesture APIs
  cannot expose the first non-completing command/activity boundary.
- [ ] Implement the smallest stale-safe orphan-Hold liveness repair.
- [ ] Run shared carousel, Summary, Time and Avatar impacted tests; commit and
  journal separately.

### Task 2: Forensically test Sum pan edges

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Modify only when RED proves it: `lib/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart`
- Test: `test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

- [ ] Add bounded per-year completed-pan/pinch diagnostics (counts, digest,
  stable domain, first/last anchors and real outside neighbours).
- [ ] Create a sparse 2027 fixture and assert overlapping real anchors remain
  stable at a fixed resolution.
- [ ] Verify RED. If only strict crop loses a real edge segment, retain one
  nonselectable neighbour for paint and clip it; otherwise leave LOD logic
  unchanged and document legitimate sparsity.
- [ ] Validate no repository/Room/Query/index hot-path work; commit only if
  application source changes, then journal separately.

### Task 3: Add one shared Sum density preference

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Tests: existing Mind setting/tuner/viewport suites

- [ ] RED default/controller/tuner tests for one/two preference and no frame
  identity change.
- [ ] RED mounted line and bar tests for exact one/two band fit and scroll.
- [ ] Implement one pure geometry resolver consumed by both renderers.
- [ ] Verify Sum heatmap is unchanged; commit and journal separately.

### Task 4: Add 3×4 MonthCard profitability tint

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Tests: existing Mind settings, Year viewport and host suites

- [ ] RED settings and mounted 3×4 MonthCard tests: positive/negative/zero,
  enable flag, opacity-only tint mutation, and 4×3 unchanged.
- [ ] Implement the controller-owned fields and use existing `netForMonth`
  only to choose a semantic background tint.
- [ ] Verify cell/text/border/shadow/icon/financial semantics are unchanged;
  commit and journal separately.

### Task 5: Delivery evidence

- [ ] Reread this checklist and mark only proven requirements DONE.
- [ ] Run focused/full suites, analyze, format, fast/boundary checks.
- [ ] Push final source, dispatch exact-source CI/tag if needed, download and
  hash human APK, regenerate exact-source SCIP on tooling branch, then append
  final journal evidence as a docs-only `[skip ci]` commit.
