# Dashboard Vertical Ready-Frontier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove blank vertical LogBox space by publishing only fully drawable
keyset pages, while keeping page resources and diagnostics bounded.

**Architecture:** `CommittedLogViewportCache` becomes the one owner of a
contiguous drawable frontier and target-safe retention. The paging controller
becomes the one request-state/demand coordinator. UI converts scroll position
to demand only; renderer reads complete pages only. Diagnostics use dedicated
O(1) general/capture rings.

**Tech Stack:** Flutter/Dart, CustomPaint, keyset Room bridge, package:flutter_test.

## Global Constraints

- Do not modify frozen rail, carousel, controller, physics or prepared-index
  hot-path sources.
- No golden test, timeout workaround, paint-time layout/paging, full-list
  materialization or placeholder blank page.
- Run Flutter tests/analyze only through Ubuntu proot; create APK only via
  GitHub Actions.

---

### Task 1: Lock failing phantom-extent and commit-terminal regressions

**Files:**
- Modify: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`
- Modify: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`

- [x] Write tests that seed 658 rows with one ready page, assert extent ends at
  page zero/loading tail, and demand page 1; assert page 1 becomes drawable
  before extent grows.
- [x] Write tests for request ordinal 6 that assert exactly one terminal
  committed/frontier event or one explicit rejection reason.
- [x] Run each targeted test and record expected RED failures.

### Task 2: Implement transactional drawable frontier and safe page retention

**Files:**
- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Test: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`

- [x] Replace total-count base geometry with append-only actual drawable page
  geometry; make offset lookup, semantics and content height clamp to it.
- [x] Prepare page resources before cache/geometry publication and publish
  page, cursor anchor, frontier and extent atomically.
- [x] Separate target and drawable windows; only evict after a new drawable
  window exists, retaining current plus bounded neighbors.
- [x] Run focused cache tests until GREEN.

### Task 3: Implement page demand state and explicit reject diagnostics

**Files:**
- Modify: `lib/features/dashboard/runtime/application/explicit_committed_paging_controller.dart`
- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Test: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`

- [x] Add identity-indexed request states and bounded forward demand drain.
- [x] Emit data-ready, presentation-ready, committed, rejection and frontier
  transitions with identity/reason fields; advance cursor and ordinal only in
  the atomic success branch.
- [x] Run controller tests until GREEN.

### Task 4: Make viewport and painter drawable-only consumers

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`

- [x] Convert scroll updates to demand/window updates only; never call the
  repository path directly per update.
- [x] Limit paint/semantics loops to the ready frontier and make a missing
  drawable page an invariant diagnostic, not normal control flow.
- [x] Add a real 658-row widget flow crossing rows 24/25 through 658 with
  asynchronous page completion and no blank/miss assertions.

### Task 5: Replace diagnostic shifts with capture-aware O(1) rings

**Files:**
- Modify: `lib/core/diagnostics/fluvi_diagnostic_logger.dart`
- Modify: `lib/core/debug/debug_console.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/core/diagnostics/fluvi_diagnostic_logger_test.dart`
- Test: `test/core/debug/debug_console_test.dart`

- [x] Add general/capture circular buffers, capture lifecycle and repeated
  state-failure aggregation without `removeAt(0)`.
- [x] Add START/STOP/CLEAR capture controls and capture snapshot export.
- [x] Prove frozen capture survives 10k general events and report includes
  vertical counters/state.

### Task 6: Scale, freeze and delivery verification

**Files:**
- Modify: relevant dashboard cache/controller/widget tests and checklist

- [x] Traverse 1k, 10k, 50k and 100k deterministic page chains; assert
  frontier/cursor monotonicity, end-of-list correctness and bounded heavy
  pages/layouts.
- [ ] Rehash frozen components; run focused tests, full non-golden suite and
  Ubuntu analysis; push then wait for GitHub profile build.
- [ ] Download the CI profile APK to `/storage/emulated/0/Download/fluvi`,
  verify SHA-256/ZIP integrity, update checklist and request physical capture.
