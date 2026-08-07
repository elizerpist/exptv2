# Dashboard Readiness Deadlock and Cache Contract Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make cold dashboard bootstrap deterministically reach `ready` while
retaining the bounded LogBox renderer and eliminating its warmup/runtime raster
cache mismatch.

**Architecture:** `DashboardInteractionReadiness` remains the single
lifecycle owner and records explicit task state. `FluviAppShell` captures the
immutable prepared raster set once and supplies it through the existing
dashboard composition path. The stable render surface acknowledges only its
deterministic attach/layout/text-cache tasks; paint, semantics and layer
first-use do not block interaction.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing dashboard diagnostics,
GitHub Actions for APK build.

## Global Constraints

- Preserve bounded `CustomPaint` LogBox architecture and explicit vertical paging.
- Do not modify rail physics, carousel, controller/position ownership, gesture recognition, snap, threshold, friction or item extent.
- No golden test and no production readiness timeout/watchdog/fallback.
- Run Flutter checks inside Ubuntu proot; build APK online through GitHub Actions.
- Preserve user-owned untracked `.tmp-*` files and `test/.../failures/`.

---

### Task 1: Make readiness task state and timeline explicit

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_interaction_readiness.dart`
- Modify: `lib/features/dashboard/application/dashboard_render_readiness_diagnostics.dart`
- Modify: `test/features/dashboard/application/dashboard_interaction_readiness_test.dart`
- Modify: `test/features/dashboard/application/dashboard_render_readiness_diagnostics_test.dart`

**Consumes:** Existing phase state, prepared visible frame and diagnostic ring.

**Produces:** Explicit `pending/running/completed/failed` task state, terminal
failure diagnostics and structured readiness phase/task events.

- [x] **Step 1: Write failing lifecycle tests**

Add tests that require a delayed deterministic LogBox task before `ready`,
require a failed task to produce `failed`, and require every started task to
have one terminal event.

- [x] **Step 2: Run the focused tests and verify RED**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/application/dashboard_interaction_readiness_test.dart test/features/dashboard/application/dashboard_render_readiness_diagnostics_test.dart'`

Expected: FAIL because the current readiness waits on an implicit frame
completer and diagnostics lacks terminal task/timeline events.

- [x] **Step 3: Implement the minimal explicit task state and timeline**

Keep the existing phase enum. Add typed task states and terminal failure
metadata to `DashboardInteractionReadiness`; expose reportable task states.
Extend the bounded diagnostic event schema with readiness entered, task
started/completed/failed and ready events. Include phase/task/start/duration,
query key, core revision and frame generation.

- [x] **Step 4: Run the focused tests and verify GREEN**

Run the Step 2 command. Expected: PASS.

### Task 2: Pass the prepared raster resource by identity

**Files:**
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify: `lib/features/dashboard/application/dashboard_interaction_readiness.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `test/core/assets/prepared_vector_asset_atlas_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`

**Consumes:** The existing singleton atlas and fixed-DPR `PreparedLogBoxRasterSet`.

**Produces:** One immutable resource bundle whose raster set is prepared and
rendered by identity; no surface-time global cache lookup.

- [x] **Step 1: Write failing cache-contract tests**

Require warmup output and renderer input to be the same raster-set object and
require a cold current viewport to produce zero category-raster miss.

- [x] **Step 2: Run the focused tests and verify RED**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/core/assets/prepared_vector_asset_atlas_test.dart test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart'`

Expected: FAIL because the surface computes and reads its own `View` DPR key.

- [x] **Step 3: Implement one resource handoff**

Have the shell capture `PreparedVectorAssetAtlas.instance.logBoxRastersFor`
immediately after its awaited warmup and place it in the readiness resource
bundle. Thread that immutable instance through `CoreDashboard` and
`DashboardLogBoxViewport` to the stable surface. Remove its
`didChangeDependencies` atlas lookup and its category-raster miss catch.

- [x] **Step 4: Run the focused tests and verify GREEN**

Run the Step 2 command. Expected: PASS.

### Task 3: Decouple deterministic warmup from paint completion

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Modify: `test/app/fluvi_app_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`

**Consumes:** Task callbacks from Task 1 and injected raster set from Task 2.

**Produces:** Explicit surface-attach, exact-layout and text-cache task
completion before ready, and no readiness dependency on layer/semantics/paint.

- [x] **Step 1: Write failing cold-shell/widget tests**

Require the shell to reach `ready`, retain the spinner/input gate until a
delayed text-cache task completes, then enable rail input; require all emitted
surface/text warmup events to terminate.

- [x] **Step 2: Run the focused tests and verify RED**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/app/fluvi_app_test.dart test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart'`

Expected: FAIL because `ready` currently waits for a post-paint acknowledgement.

- [x] **Step 3: Implement deterministic callback boundaries**

Complete surface attachment in `initState`; obtain the exact width from the
first normal layout constraints; start the existing bounded text-cache work
there; complete the readiness task when the cache completes. Report any error
to readiness and emit a terminal failed event. Do not register layer or
semantics callbacks as readiness tasks.

- [x] **Step 4: Run the focused tests and verify GREEN**

Run the Step 2 command. Expected: PASS.

### Task 4: Preserve the boundary and verify delivery

**Files:**
- Modify: `test/boundary/dashboard_cold_start_render_isolation_boundary_test.dart`
- Modify: `docs/superpowers/checklists/2026-08-07-dashboard-readiness-deadlock-cache-contract.md`
- Modify: `docs/dashboard/dashboard-cold-start-logbox-readiness-root-cause.md`

**Consumes:** Completed lifecycle, cache and widget tests.

**Produces:** A fail-closed source boundary, updated audit, final checklist and
online physical diagnostic APK.

- [x] **Step 1: Write the failing boundary assertion**

Assert that `dashboard_logbox_render_surface.dart` does not call
`PreparedVectorAssetAtlas.instance.logBoxRastersFor` and that no production
`Future.delayed` or golden test was added.

- [x] **Step 2: Run the boundary test and verify RED**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/boundary/dashboard_cold_start_render_isolation_boundary_test.dart'`

Expected: FAIL before the surface lookup is removed.

- [x] **Step 3: Update audit and checklist**

Record the exact readiness lifecycle, task boundaries, cache-key audit,
identity handoff, source freeze and truthful status of each checklist item.

- [x] **Step 4: Run complete verification**

Run focused tests, the complete non-golden test suite, `flutter analyze`, and
`git diff --check` in Ubuntu proot. Compare frozen rail/physics/controller
paths to base. Commit and push the target branch, trigger/monitor the existing
GitHub diagnostic APK workflow, download the resulting APK to
`/storage/emulated/0/Download/fluvi`, and verify its SHA-256 and ZIP integrity.
