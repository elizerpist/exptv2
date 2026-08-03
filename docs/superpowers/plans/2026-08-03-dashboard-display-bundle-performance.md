# Dashboard display-bundle performance implementation plan

> **For agentic workers:** Apply systematic debugging and TDD to every production change; preserve all centered-carousel preset constants.

**Goal:** Make finite dashboard preview deterministic and content-independent by moving it from child-item LRUs to complete, pinned parent display bundles and by promoting equal preview data at settle without visual work.

**Architecture:** `DashboardParentDisplayBundleController` becomes the one owner for finite preview data/cache/pinning and the currently displayed immutable snapshot. Native code provides a parent-scoped batch payload; Flutter validates/projectors it once and publishes only a complete deck. `CurrentQueryController` remains the committed watch owner and centered-carousel remains the sole physics owner.

**Tech stack:** Flutter/Dart immutable models and notifier selectors, Kotlin Room read service/method channel, Flutter widget/domain tests, profile-mode DevTools and GitHub Actions Android build.

## Global constraints

- Do not change `frictionDrag`, velocity bands/multipliers, spring, snap/tolerance or `maxItemsPerFling` values.
- Do not issue SQL/platform reads, DTO projection, formatting, eviction or root dashboard publication from a preview tick.
- Run Flutter tests/analyze in Ubuntu proot; Android tests and APK builds on GitHub Actions.
- Treat empty preview as a stored value, never `null`.

### Task 1: Establish measured and deterministic baselines

**Files:**
- Create: `test/features/dashboard/performance/dashboard_display_bundle_baseline_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_physics_test.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`

- [ ] Write failing tests for 100 equal `RailFlingPlan` inputs and content-independent target output; assert all existing preset fields are unchanged.
- [ ] Run the tests red because `RailFlingPlan` and the pure plan API do not exist.
- [ ] Extract pure calculation result without changing existing calculation branches or constants; wire diagnostics as an observer only.
- [ ] Run focused physics tests green.

### Task 2: Add explicit immutable bundle contracts and native batch boundary

**Files:**
- Create: `lib/features/dashboard/application/dashboard_parent_display_bundle.dart`
- Create: `lib/features/dashboard/query/data/dashboard_parent_display_bundle_repository.dart`
- Modify: `lib/features/dashboard/query/data/dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviQueryModels.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Test: Flutter method-channel, Kotlin core and bridge tests

- [ ] Write red tests for a parent batch that returns all expected child keys, including explicit empty days, with one canonical revision.
- [ ] Add typed batch DTO/repository contracts and native parent query/projection using the existing canonical predicate.
- [ ] Decode only validated batch payloads; fill absent calendar children as explicit empty snapshots; reject incomplete/identity-mismatched payload.
- [ ] Run focused Dart/Kotlin/bridge tests green.

### Task 3: Replace finite child-item LRU with pinned whole-bundle cache

**Files:**
- Create: `lib/features/dashboard/application/dashboard_parent_display_bundle_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart`
- Test: new bundle controller/controller integration tests

- [ ] Write red tests for June-30 completeness, present-empty lookup, 500 zero-miss lookups, no child eviction after pressure, and atomic ready publication.
- [ ] Implement bundle-keyed LRU with current-direction/current-parent pinning and optional adjacent pinning; evict only whole non-pinned bundles.
- [ ] Route finite preview metric/LogBox selection through the one immutable displayed snapshot; keep SUM as a bounded fallback corridor.
- [ ] Remove finite `motionTargetResolved` detailed prefetch and prove its count is zero after deck ready.
- [ ] Run focused regressions green.

### Task 4: Centralize preview-to-committed promotion and no-op visual paths

**Files:**
- Modify: `dashboard_parent_display_bundle_controller.dart`
- Modify: `dashboard_summary_amount_controller.dart`
- Modify: `dashboard_log_page_coordinator.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: summary amount, LogBox coordinator, dashboard presentation tests

- [ ] Write red test for equal preview/committed key/revision/metrics/log snapshot with zero amount animation and zero first-page bind.
- [ ] Implement `canPromoteWithoutVisualChange`; retain displayed snapshot/list identity and emit `PREVIEW_PROMOTED_TO_COMMITTED` with `visualChange=false`.
- [ ] Short-circuit amount/count transitions for equal visual values; preserve detail watch/paging enablement without presentation emission.
- [ ] Run focused widget/controller tests green.

### Task 5: Isolate render and diagnostic hot paths

**Files:**
- Create: `lib/features/dashboard/performance/dashboard_performance_trace.dart`
- Modify: dashboard presentation selectors, `fluvi_diagnostic_logger.dart`, and targeted LogBox/header/rail widgets only after profile evidence
- Test: trace/logger/identity/rebuild tests

- [ ] Write red tests for stable rail/scroll/controller identity across 100 snapshot swaps and no header/rail rebuild from LogBox preview.
- [ ] Add opt-in numeric/timeline trace for plan, crossing, selected snapshot, first paint, promotion and bundle ready; do not materialize FLOW strings on a closed panel.
- [ ] Apply only profile-justified RepaintBoundary changes and preserve stable LogBox shell keys/controllers.
- [ ] Run focused tests green and document the physical-device matrix/p50/p90/p99/worst collection commands.

### Task 6: Adjacent warmup, horizontal atomic swap, full verification and delivery

**Files:**
- Modify: bundle controller/core/navigation presentation adapters and this checklist
- Test: parent navigation atomic-frame/startup warmup/boundary suites

- [ ] Write red tests for ready previous/current/next parent swap with no `—`, empty list or mixed-parent frame.
- [ ] Implement staged readiness: keep previous complete bundle until target is ready, then atomically swap parent label, metrics, count and LogBox.
- [ ] Run all focused/full Flutter, boundary, Kotlin/bridge and profile-instrumentation checks; re-read checklist and record physical-device limitations honestly.
- [ ] Commit, push, wait for GitHub Actions and download the successful APK to `/storage/emulated/0/Download/fluvi`.
