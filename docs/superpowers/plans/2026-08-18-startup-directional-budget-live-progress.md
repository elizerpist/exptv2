# Startup, Directional Budget and Live Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline here; the requested workflow forbids subagents). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make first-attempt dashboard readiness, Budget target directionality, and the selected progress chrome correct without adding I/O or renderer work to the gesture hot path.

**Architecture:** The existing prepared-scene cache remains the sole paragraph-preparation owner and gains typed priority arbitration. Native acquisition produces two immutable direction-local Budget banks, which a single Flutter live-selection object binds atomically to header and selected chrome. The edit controller remains the only optimistic-limit write path.

**Tech Stack:** Flutter/Dart, Kotlin, Room, compact binary MethodChannel payload, `flutter_test`, JUnit/Gradle, GitHub Actions.

## Global Constraints

- No golden, integration harness, automatic gesture driver, or alternate human entrypoint.
- Preserve `lib/main.dart`, immutable LogBox geometry, normal carousel/time-rail physics, and protected baseline `8d559cf`.
- No startup retry/delay workaround; no direction filtering in widget build; no limit-tick I/O.
- Use RED → GREEN → REFACTOR and run Flutter commands in Ubuntu proot.

### Task 1: Protect render-critical scene preparation

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`

- [ ] Write cache ownership tests: low-priority retained request during a yielding render-critical request does not cancel it; identical target joins; terminal scene error still propagates.
- [ ] Run the focused cache test and observe the new assertions fail against token-only supersession.
- [ ] Add typed preparation intent, active-request join/promotion, lower-priority deferral and owner/priority diagnostics in the existing cache.
- [ ] Mark the mounted text-layout warmup as `renderCriticalReadiness`; keep retained Summary work maintenance-only.
- [ ] Re-run focused cache and readiness tests, then commit `fix: protect render-critical scene preparation`.

### Task 2: Prepare direction-local native Budget banks

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviBudgetReadService.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviPreparedBudgetLimitSnapshot.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/dashboard/DashboardBinaryCodec.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/usecase/SeedFluviDemoDatasetUseCase.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetVersion.kt`
- Test: prepared Budget/seed Kotlin test suites.

- [ ] Write direction-membership, time-independence, local-handle and deterministic-seed RED tests.
- [ ] Run the Kotlin targeted test command and observe global-category-domain failures.
- [ ] Build income/expense banks from the one grouped all-time ledger scan, map limits only inside their bank, version the binary layout, and update deterministic fixture cardinality.
- [ ] Run affected Kotlin tests and commit `fix: separate budget target domains by direction`.

### Task 3: Decode and bind direction-local Budget presentation

**Files:**
- Modify: `lib/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart`
- Modify: `lib/features/dashboard/runtime/data/prepared_budget_limit_snapshot_binary_codec.dart`
- Modify: `lib/features/dashboard/application/dashboard_budget_presentation_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart`
- Modify: `lib/core/categories/presentation/budget_category_avatar_artwork.dart`
- Test: prepared snapshot codec/domain, Budget controller, rail and artwork tests.

- [ ] Write Dart RED tests for two banks, direction-local handle restoration and ratio identity handoffs.
- [ ] Run focused Flutter tests and observe v1/global-domain failures.
- [ ] Decode v2 banks, build each catalog from snapshot membership, retain selected identity independently by direction, and publish one canonical live selection object directly to selected artwork.
- [ ] Re-run focused Flutter tests and commit `fix: bind budget rail to directional target banks`.

### Task 4: Make the live progress and zero crossing exact

**Files:**
- Modify: `lib/core/categories/presentation/budget_category_avatar_artwork.dart`
- Modify: `lib/features/dashboard/application/dashboard_budget_limit_edit_controller.dart`
- Test: Budget controller, avatar rail/artwork and quick-edit tests.

- [ ] Write RED tests for 0/20/25/50/80/99/99.9/100/125 percent, no-positive-limit non-rendering, zero-floor no-op, and pointer-down zero crossing/reappearance.
- [ ] Run them to observe the legacy minimum arc/mirror-state/repeated-zero behavior fail.
- [ ] Use exact `rawProgress`/`visualProgress`, make no-positive-limit mount nothing, remove the rail mirror, and suppress unchanged zero ticks.
- [ ] Re-run focused tests and commit `fix: bind live budget progress directly to selection`.

### Task 5: Verify and deliver

**Files:** no product-source changes unless a test/CI defect identifies its owner.

- [ ] Run `dart format` for changed Dart files, `git diff --check`, focused Flutter/Kotlin/boundary/protected regressions, and `flutter analyze` through Ubuntu proot.
- [ ] Re-read `2026-08-18-startup-directional-budget-live-progress.md` checklist and update status only from fresh evidence.
- [ ] Push `separated-core-modes`, wait for the workflow’s normal human APK job for the final SHA, download under `/storage/emulated/0/Download/fluvi`, and record SHA-256.
