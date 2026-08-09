# Rail-Critical Visible Continuity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish prepared dashboard data and complete rail-preview visuals as
one revision-safe product so a visible non-empty payload always paints rows.

**Architecture:** Reuse the existing cancellation-atomic prepared-scene cache
as an explicit immutable `RailCriticalSceneBank`. Build it from the whole
prepared index's bounded rail universe, then publish a revision bundle and the
renderer-visible bank in one synchronous transaction. The separate committed
vertical cache and background maintenance coordinator keep their existing
roles.

**Tech Stack:** Dart, Flutter `CustomPainter`, `flutter_test`, immutable
prepared dashboard index and LogBox scene models.

## Global Constraints

- Base is `245ab81dee09f09d5d627f6f5a27a8559cb748dd`.
- No golden tests, rail-physics changes, input cooldown, synchronous
  `TextPainter` fallback, scene build, wait, SQL, or data fetch on rail input.
- Preserve committed vertical paging and its keyset/page-size semantics.
- Runtime ownership is committed before test/CI consolidation.

---

### Task 1: Encode the rail-critical bank contract

**Files:**
- Modify: `lib/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`

**Consumes:** immutable `PreparedDashboardIndex` preview payloads and existing
complete prepared scenes.

**Produces:** `RailCriticalSceneBank` identity/manifest/report, exact O(1)
lookup, and separate rail lookup diagnostics.

- [ ] **Step 1: Write failing cache-bank tests**

```dart
expect(cache.railCriticalSceneFor(payload), isNotNull);
expect(cache.railCriticalLookupMissCount, 0);
expect(cache.railCriticalSceneCount, window.sceneCount);
```

- [ ] **Step 2: Run the cache test and verify the missing API fails.**

Run: `flutter test test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`

- [ ] **Step 3: Add the public complete-only bank model and exact lookup.**

- [ ] **Step 4: Re-run the focused cache test.**

### Task 2: Publish a complete revision rail universe

**Files:**
- Create: `lib/features/dashboard/runtime/domain/dashboard_prepared_revision_bundle.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_scene_window_rotation_test.dart`

**Consumes:** a complete index and Task 1 rail-bank manifest.

**Produces:** a full SUM/year/month, income/expense bounded preview window
and an atomic core publication transaction.

- [ ] **Step 1: Write a failing controller test for a 2025 sibling payload absent from the old background coverage.**
- [ ] **Step 2: Run the focused controller test and verify it fails.**
- [ ] **Step 3: Add the immutable revision bundle and derive all rail-reachable payloads from `PreparedDashboardIndex.catalogs`.**
- [ ] **Step 4: Publish only after the matching complete bank is activated; preserve the old bundle on cancellation.**
- [ ] **Step 5: Re-run controller and cache tests.**

### Task 3: Make rail rendering and diagnostics bank-owned

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/presentation/dashboard_visible_scene_continuity_test.dart`

**Consumes:** Task 1 bank lookup and Task 2 revision bundle.

**Produces:** frame correctness counters independent of preparation state and
the authoritative physical regression test.

- [ ] **Step 1: Write the failing 2025 July → cancelled prepare → June test.**
- [ ] **Step 2: Run it and verify `payload=24, drawable=0, painted=0` fails.**
- [ ] **Step 3: Route rail preview selection through the rail-critical lookup and record non-empty drawable/paint violations without suppression.**
- [ ] **Step 4: Extend the same test with the deterministic sibling/day chaos sequence.**
- [ ] **Step 5: Run the continuity test, cache tests, scene-rotation tests, viewport tests, controller tests, and analyze.**

### Task 4: Runtime checkpoint A

**Files:** runtime and test files from Tasks 1-3 only.

- [ ] **Step 1: Re-read the acceptance checklist in the design document.**
- [ ] **Step 2: Run the focused matrix and inspect `git diff`.**
- [ ] **Step 3: Commit only runtime ownership, diagnostics, and continuity tests.**

Commit: `fix: make visible rail scenes revision critical`

### Task 5: Consolidate tests after checkpoint A

**Files:** dashboard test inventory/report and selected dashboard tests.

- [ ] **Step 1: Classify the audited overlap groups into keep, merge, delete, profile, and nightly owners.**
- [ ] **Step 2: Make one deletion/merge group at a time with focused tests.**
- [ ] **Step 3: Run the curated fast suite and full non-golden suite once.**
- [ ] **Step 4: Commit test-only cleanup.**

Commit: `test: consolidate dashboard correctness gates`

### Task 6: Split CI lanes after tests are consolidated

**Files:** `.github/workflows/fluvi-core.yml` and any invoked workflow helper.

- [ ] **Step 1: Write/extend workflow verification for path-filtered profile eligibility.**
- [ ] **Step 2: Create fast correctness, dashboard-profile, and scheduled nightly lanes.**
- [ ] **Step 3: Remove the always-run fixed baseline emulator; keep human APK after fast gates only.**
- [ ] **Step 4: Commit CI-only changes.**

Commit: `ci: split fast profile and nightly dashboard gates`

