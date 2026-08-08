# Final Vertical Handoff + 2025 High-Density Seed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure a sibling-scope handoff kills stale vertical input and makes the first genuine vertical gesture immediately promote the committed virtual surface, while adding deterministic high-density 2025 diagnostic data.

**Architecture:** `DashboardLogBoxViewport` remains the sole scroll-controller owner. It gains one scope-bound interaction session used by the existing notification path to reject old scroll updates and to atomically activate the existing committed cache on a genuine new interaction. The Room-backed native demo generator remains the only demo-data owner and is extended by a versioned deterministic 2025 plan; Flutter only reports its compact aggregate.

**Tech Stack:** Flutter/Dart widget tests; Kotlin/JUnit/Robolectric; existing Room demo seed; GitHub Actions profile APK.

## Global Constraints

- Work from `34ff2455a9c0b884dad5d82d29348560dddfc4e5`; do not reset prior fixes.
- No golden tests, no rail/physics change, no paging/demand planner rewrite, no scene-window or Summary formatter change.
- No timer, debounce, controller recreation, remount, eager preloading, paint-time layout, or input blocking.
- HUMAN_DIAGNOSTIC must use the normal `lib/main.dart` entry point.

---

### Task 1: Document and lock the source-level handoff reproduction

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-08-final-vertical-handoff.md`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

**Interfaces:**
- Consumes: presentation binding, stable viewport, committed cache and explicit paging controller.
- Produces: a failing widget test in which a sibling reset is followed by a stale update that must not load a page or leave the render domain in `railPreview`.

- [x] **Step 1: Write the failing interaction-boundary test**

  Create one stable viewport, deep-scroll scope A, publish sibling preview/committed C, then dispatch the old continuation and the first genuine C start/update. Assert stale continuation has no paging/activation effect and the genuine start activates the committed domain before page 1 can be requested.

- [x] **Step 2: Run the focused test to verify RED**

  Run the focused Flutter test in Ubuntu proot. Expected: it fails because an update can reach the fallback `onLoadNextPage(1)` path without a session or demand epoch.

### Task 2: Add one scope-bound vertical interaction session

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

**Interfaces:**
- Consumes: `DashboardLogBoxVisibleScopeIdentity`, authoritative presentation binding, existing committed cache callbacks.
- Produces: a private immutable/session state with `visibleScope`, `presentationEpoch`, and a monotonic generation.

- [x] **Step 1: Invalidate at the pre-paint visible-scope boundary**

  Invalidate the current session before native `jumpTo(0)` when `DashboardLogBoxVisibleScopeIdentity` changes. Log a bounded invalidation event; retain controller and position identities.

- [x] **Step 2: Start only genuine committed interactions**

  On `ScrollStartNotification`, bind a fresh session only when the authoritative binding is committed and exact. Invoke the existing demand-epoch callback, activate the existing committed cache, publish the first-gesture promotion event, then make the existing demand request.

- [x] **Step 3: Reject unbound/stale updates and ends**

  Route update/end work only through a currently matching session. A rejected legacy notification only records a deduplicated diagnostic and cannot call paging/cache methods.

- [x] **Step 4: Run RED/GREEN focused tests**

  Re-run Task 1 plus existing reset, lazy paging and render-domain widget tests. Expected: session test turns green; current behavior remains green.

### Task 3: Extend deterministic 2025 native diagnostic seed

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetVersion.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/DemoDatasetGenerator.kt`
- Modify: `android/fluvi-core/src/test/kotlin/com/fluvi/core/demo/DemoDatasetGeneratorTest.kt`
- Modify: `android/fluvi-core/src/test/kotlin/com/fluvi/core/demo/SeedFluviDemoDatasetUseCaseTest.kt`

**Interfaces:**
- Consumes: existing deterministic IDs, categories/partners, `DemoMonthReport`, Room seed manifest.
- Produces: versioned 2025 monthly reports and an idempotent plan with existing 2026 output retained.

- [x] **Step 1: Write failing 2025 monthly invariant tests**

  Verify all 12 2025 months have 280–320 rows, income/expense each in 60,000,000..70,000,000 minor units, abs(net) ≤5,000,000, varied day density, deterministic equality, and unchanged 2026 monthly regressions.

- [x] **Step 2: Run Kotlin generator tests to verify RED**

  Run the module test for the new assertion. Expected: it fails because 2025 rows do not exist.

- [x] **Step 3: Implement deterministic high-density year**

  Bump the seed version; append 2025 entries with unique deterministic ordinals and microtransaction distributions, exact bounded totals, varied calendar dates, and existing partners/categories. Preserve generator and manifest single ownership.

- [ ] **Step 4: Verify generator and Room idempotency tests** — blocked locally by the documented AAPT2 daemon startup failure; queued for CI.

  Run Kotlin generator and seed use-case tests. Expected: all data bounds and no-duplicate rerun behavior pass.

### Task 4: Verify bounded, first-fling lifecycle end-to-end

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `docs/superpowers/checklists/2026-08-08-final-vertical-handoff.md`

**Interfaces:**
- Consumes: Task 2 session flow and existing paging fixture.
- Produces: non-golden A→B→C first-fling, rapid-cycle and cache/domain diagnostic regression proof.

- [x] **Step 1: Add failing first-fling and stale-session tests**

  Use the real stable viewport and explicit paging controller fixture. Assert scope C first start is `committedVertical`, its first fling requests/contributes multiple pages, and an A generation cannot move/paginate C.

- [x] **Step 2: Add 2025 high-density native/unit coverage**

  Assert January/February/month-day coverage through generator reports; retain the existing 2026 94-row and large-data tests as regressions.

- [x] **Step 3: Execute focused and full non-golden test suites** — Flutter: 370 passing; native module is CI-pending because of the local AAPT2 limitation.

  Run Flutter focused/full tests in Ubuntu proot and the native Kotlin test task. Run `flutter analyze` in Ubuntu proot. Update checklist only with observed results.

### Task 5: Deliver verified human diagnostic APK

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-08-final-vertical-handoff.md`

- [ ] **Step 1: Inspect frozen diff and commit**

  Confirm frozen paths are unchanged; commit only tracked implementation/tests/docs and leave user untracked logs untouched.

- [ ] **Step 2: Push and monitor GitHub Actions**

  Push the branch, monitor human diagnostic and profile jobs independently, and never substitute the automated harness artifact for the human APK.

- [ ] **Step 3: Download and integrity-check the human APK**

  Download the successful normal-entrypoint HUMAN_DIAGNOSTIC artifact to `/storage/emulated/0/Download/fluvi`, calculate SHA-256, verify ZIP integrity, and mark delivery honestly.

## Coverage self-review

- VH01–VH06 map to Tasks 1, 2 and 4; SD01–SD02 map to Task 3; VR01 and FR01 map to Task 4/5; DL01 maps to Task 5.
- No golden test or frozen rail/paging architecture task is included.
- The plan uses one existing owner per responsibility: stable viewport session and native generator.
