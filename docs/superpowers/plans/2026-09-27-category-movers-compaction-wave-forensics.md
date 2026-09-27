# Category Movers Compaction and Balance Wave Forensics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fit Category Movers’ useful content into the normal mode-content card, surface explanations and metrics only on demand, make the existing Balance wave runtime observable and correct its proven startup/runtime behavior.

**Architecture:** Keep presentation data immutable and localize only page/overlay selection in `BalanceCategoryMoversCard`. Keep the carousel’s existing one-state ticker ownership, but add a bounded telemetry observer that receives clock and painter samples and writes to the existing diagnostic ring. Extend the existing debug-console filter and user-marker extension points rather than adding state stores.

**Tech Stack:** Flutter, `flutter_test`, existing `FluviDiagnosticLogger`, existing Dashboard geometry/settings.

## Global Constraints

- Preserve carousel physics, selection, financial projection, query boundaries and count-safe BottomNav clamp.
- The category overlays are in-card, transient, mutually exclusive and do not alter outer geometry.
- `BALANCE_WAVE|` logs are milestone/interval events, never per-frame logs.
- Physical wave acceptance remains user-only.

### Task 1: Red tests and default stretch

**Files:**
- Modify: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`
- Modify: `test/features/dashboard/presentation/dynamic_mind_flat_bottomnav_test.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_shell_presentation.dart`

- [x] Add failing Page-1/Page-2 overlay, compact-selector, and real 412×892 five-row geometry assertions.
- [x] Add failing shell-default/reset/user-override assertions for `modeContent`.
- [x] Run the focused tests and confirm each fails because current layout retains copy/KPIs and default is `off`.
- [x] Change the shell default only; rerun default/stretch tests.

### Task 2: Compact Category Movers rendering

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_category_movers_card.dart`
- Modify: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`

- [x] Introduce one local `CategoryMoverOverlay` owner, compact info target and compact selector.
- [x] Remove permanent Page-1 explanatory/footer surfaces and Page-2 explanatory/KPI/footer surfaces from normal layout.
- [x] Render grey transient explanation/three-row metrics overlays in the existing clipped card Stack, with reduced-motion-safe transition.
- [x] Give the cumulative chart all reclaimed height and bind tap handling strictly to the chart bounds.
- [x] Run focused widget tests to green and update changed goldens only after inspection.

### Task 3: Wave forensics runtime and tests

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_carousel_wave_diagnostics.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`
- Modify: `test/features/dashboard/presentation/balance_carousel_wave_motion_test.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Add failing tests for clock/geometry progression, enabled/static/reduced-motion states and bounded diagnostic samples.
- [x] Add pure digest/geometry helpers and a bounded telemetry observer; wire it to the existing one carousel controller and painter callback.
- [x] Set the wave startup animation to the intended enabled state, retain user toggle semantics, and preserve one ticker/per-card paint-only invalidation.
- [x] Register the mounted carousel’s latest telemetry snapshot with the existing marker-context lifecycle.
- [x] Run motion and carousel surface tests to green.

### Task 4: Onscreen diagnostic projection

**Files:**
- Modify: `lib/core/debug/debug_console.dart`
- Modify: `test/core/debug/debug_console_test.dart` or the existing console test owner
- Modify: `test/core/diagnostics/fluvi_diagnostic_logger_test.dart` if marker behavior needs coverage

- [x] Add failing Balance Wave filter/copy and marker-menu tests.
- [x] Extend the existing enum/dropdown/filter/map and bug marker only; do not add a logger store.
- [x] Project the latest already-sampled registered wave context above the filtered list by a console-build pull only; no ticker, polling loop, second notifier, or second history is added.
- [x] Run debug-console/logger tests to green.

### Task 5: Verification and delivery

- [x] Run `dart format --output=none --set-exit-if-changed` for every changed Dart file and `git diff --check`.
- [x] Run focused presentation, wave, diagnostic, shell and core geometry suites inside Ubuntu proot (121 tests), then `flutter analyze --no-pub --no-fatal-infos` (no issues).
- [x] Re-read the checklist, inspect refreshed golden states, and remediate the final review findings (real five-row lower-card overflow, finite diagnostics retention, sampled console status).
- [x] Commit/push production code (`867b67d4`) and complete human APK delivery from Actions run `36311698137`.
