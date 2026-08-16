# Filtered dashboard interaction readiness Implementation Plan

> **For agentic workers:** Execute inline in this existing isolated `query` worktree. The user explicitly requires no subagents, one final production commit, and one final normal human APK.

**Goal:** Make the filtered dashboard's first vertical interaction resource-work-free and bind exact in-flight Query facets to an accepted Apply without changing paging or physics.

**Architecture:** Extend the existing `CommittedLogViewportCache` with an identity-bound armed resource state separate from `verticalRenderingActive`; the viewport remains the only domain activator. Extend the existing `QueryMenuDataController` with exact, shared facet-request ownership, while the shell joins it to `DashboardCoreController.applyQuery`; `CurrentQueryController` remains the only applied presentation owner.

**Tech Stack:** Flutter/Dart, package:flutter_test, existing prepared scene/cache/paging owners.

## Global Constraints

- Do not add a cache, scheduler, Query applied state, vertical recognizer, synthetic velocity, or physics mutation.
- Preserve `CustomScrollView.dragStartBehavior = DragStartBehavior.down` and all controller/position/physics identities.
- Keep virtual geometry immutable and rendering fail-closed; no paint-time paragraph creation, placeholder, or stale page.
- Use TDD: run each focused RED test before its production change, then run it GREEN.
- Make no production commit or human APK build until all changes and verification are green.

### Task 1: Arm cache-owned interaction resources before input

**Files:**
- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Test: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

1. Add RED coverage for a seeded exact committed cache with rail-preview inactive domain and retained pages: a first vertical start must not call page preparation or rebuild prepared resources.
2. Run the focused test to observe the existing activation-side repair failure.
3. Add a cache-owned exact armed state, cooperative pre-input resource arming, and an O(1) activation that only flips render-domain ownership when the exact state is armed.
4. Add bounded activation complete/not-ready diagnostics and ensure pointer input prevents a late arming task from doing resource work.
5. Run the cache/viewport focused tests GREEN, including the existing one-move partner-row fling.

### Task 2: Join exact Query facets to Apply

**Files:**
- Modify: `lib/features/dashboard/query/application/query_menu_data_controller.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_core_query_application_test.dart`
- Test: relevant Query-menu data/sheet tests

1. Add RED controllable-future coverage where final exact facets are in flight at Apply and finish before candidate publication; assert no null applied presentation/hotset clear, no duplicate acquisition, directional/supersession safety.
2. Run it RED against the early `null` snapshot path.
3. Reuse one identity-keyed facet request in `QueryMenuDataController`, join it from the shell Apply boundary concurrently with candidate readiness, then pass its exact result to publication and log a bounded bind diagnostic.
4. Add immediate composer visual-state coverage with downstream futures unresolved.
5. Run focused Query controller/widget tests GREEN.

### Task 3: Integrate and verify one final change set

**Files:** all Task 1/2 files plus this checklist and plan.

1. Run nearest cache, viewport, partner-swipe, paging, Query application/menu/directional, scene-cache and geometry suites in Ubuntu proot.
2. Run `./scripts/test-fluvi-fast.sh`, `flutter analyze`, and `./scripts/verify-fluvi-boundaries.sh` in the approved environment; report an environment-specific timeout without weakening a test.
3. Re-read this checklist, inspect the final diff, update every status, and use verification evidence before committing.
4. Create one commit named `fix: make filtered dashboard interaction immediately ready`, push it once, monitor the exact GitHub Action, and download exactly one normal `lib/main.dart` APK to `/storage/emulated/0/Download/fluvi`.
