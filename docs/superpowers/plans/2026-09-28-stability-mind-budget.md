# Stability, Mind Year, and Budget Surface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver reference-locked Stability work when its source images are available, the Mind 4×3 fill/default changes, and a Budget unified Header/content surface.

**Architecture:** Keep all data and settings in their existing canonical owners. Extend the Mind pure layout contract for vertical cells and extract the already-proven Mind seamless surface shape only where Budget's existing `unifiedCard` selects the same physical relationship.

**Tech Stack:** Flutter/Dart, existing ValueNotifier settings owners, Flutter widget/golden tests, GitHub Actions human APK.

## Global Constraints

- Never change financial projections, Query membership, slider behavior, or global carousel physics.
- `stabil1.png` and `stabil2.png` must be opened before reference visual work; until then Stability visual implementation is blocked.
- Use test-first red/green cycles and Ubuntu proot Flutter commands.
- Preserve all previously accepted defaults except the explicit new Mind defaults.

### Task 1: Mind settings and pure 4×3 geometry

**Files:**
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Modify: `lib/core/design/fluvi_global_appearance.dart`
- Test: `test/features/dashboard/mind/domain/mind_presentation_settings_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Test: `test/core/design/fluvi_global_appearance_test.dart`

- [x] Write failing pure tests for 4×3 `cellHeight`, vertical surplus, final fill, four-by-three default, border-off default, and seamless global default.
- [x] Run the focused tests in Ubuntu and confirm the failures describe the current square/default behavior.
- [x] Add the canonical grid-layout setting and use it in the existing selector; calculate width and height separately for direct 4×3.
- [x] Run focused tests and confirm pass.

### Task 2: Mind painter, hit geometry, and 2×6 footer

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart`
- Test: `test/features/dashboard/mind/presentation/mind_year_heatmap_2x6_golden_test.dart`

- [x] Write failing tests that a direct 4×3 painted cell and its hit rect share rectangular dimensions, and 2×6 has one footer without `Zárás`.
- [x] Run tests and confirm red output.
- [x] Thread the explicit vertical cell size through MonthGroup/painter/hits and set 2×6 `showMonthlyClosing: false`, `showScopeAmount: true`.
- [x] Regenerate/verify the focused golden only after the behavior tests pass.

### Task 3: Budget Header/content seamless surface

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart`
- Test: `test/features/dashboard/presentation/selectable_header_direction_chrome_test.dart`

- [x] Write a failing unified-Budget test for one outer Header/content surface, zero-radius seam, and no second content-card surface; preserve split behavior.
- [x] Run the focused test and confirm red output.
- [x] Extract the neutral seamless shape/shell primitive and consume it from Mind and Budget unified mode.
- [x] Run Budget/Mind surface tests and confirm pass.

### Task 4: Balance membership and Stability visual work

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_cashflow_stability_card.dart`
- Tests: Balance presentation/core/detail suites and Stability goldens

- [ ] Do not begin visual Stability edits until both mandatory references exist and have been inspected.
- [ ] Once unblocked, write red tests for default dual view, stable card bounds, child gesture priority, membership filtering, selected-card fallback, indicators, and one/two-card configurations.
- [ ] Implement typed membership settings and filter before the carousel datasource, then implement the reference-matched local Stability renderer and goldens.
- [ ] Run every Balance-focused regression and compare both card states against both source images.

### Task 5: Delivery verification

**Files:**
- Modify: this checklist with exact final statuses and evidence.

- [ ] Run formatting, diff check, targeted suites, complete required analysis, and architecture-boundary suite in Ubuntu.
- [x] Re-read checklist and references; do not call blocked reference work complete.
- [ ] Commit production changes, push the feature branch, wait for the exact SHA's human diagnostic APK job, download it to `/storage/emulated/0/Download/fluvi`, and record SHA-256. Blocked because the mandatory source-of-truth files are unavailable.
