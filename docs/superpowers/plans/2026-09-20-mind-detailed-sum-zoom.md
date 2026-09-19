# Mind Detailed Sum Zoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to execute this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Upgrade the preserved detailed Sum page with analog temporal zoom,
adaptive LOD/bands/axes and a line/heatmap toggle while retaining existing
Mind cards and their one financial authority.

**Architecture:** Pure time-window and LOD calculations live in Mind domain
code and consume immutable Sum frame values. The detailed chart owns only
local interactive state; existing pager, range footer, palette resolver and
popup primitive are extended rather than duplicated.

**Tech Stack:** Flutter/Dart, existing Mind immutable projections, widget and
domain tests.

## Global Constraints

- Do not read Drive logs for this feature delivery.
- Keep exactly one Query/prepared-data/range owner.
- Preserve Sum page order 0 heatmap, 1 exact annual chart, 2 detailed chart.
- Preserve Time/Avatar controller, ScrollPosition and physics identities.
- Use the inspected reference images; physical approval remains user-only.

---

### Task 1: Detail temporal-window and LOD model

**Files:**
- Create: `lib/features/dashboard/mind/domain/mind_detailed_sum_chart_model.dart`
- Test: `test/features/dashboard/mind/domain/mind_detailed_sum_chart_model_test.dart`

- [ ] Write a failing test for January–December home extent, focal-point-stable
  zoom and clamp to the home minimum.
- [ ] Run the domain test and observe the missing-model failure.
- [ ] Implement immutable `MindDetailedSumTimeWindow` and a pure LOD sampler
  over real `MindSumHeatmapDailyPoint` values.
- [ ] Run the domain test green.

### Task 2: Detailed Sum widget and gestures

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart`
- Create: `lib/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`

- [ ] Write failing mounted tests for mini toggle, home-scale month labels,
  scale window change, 1/2/3-year band rules, and retained page-two identity.
- [ ] Run them RED.
- [ ] Implement the page-local chart using the pure model and existing palette
  resolver; route three-or-more year vertical overflow to the existing scroll
  owner.
- [ ] Run focused widget suite green.

### Task 3: Popup bound correctness and regression evidence

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_anchored_info_card.dart`
- Test: `test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`

- [ ] Write failing edge-cell tests that assert popup position follows the
  individual cell and is clamped within the actual page rect.
- [ ] Run RED.
- [ ] Strengthen the one shared popup primitive using its containing Stack
  bounds, without putting geometry policy into feature pages.
- [ ] Run both Sum and Year popup tests green.

### Task 4: Verify and deliver

- [ ] Run Dart formatting, focused domain/widget tests, analyzer, fast suite,
  boundary checks and `git diff --check` in Ubuntu proot.
- [ ] Re-read this plan and its acceptance checklist; mark only verified items
  DONE.
- [ ] Commit application code, append a journal-only `[skip ci]` commit, push
  the application SHA, monitor CI, download/hash its normal APK, and generate
  matching SCIP before final report.
