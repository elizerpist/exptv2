# Committed Vertical Runway Implementation Plan

> **For agentic workers:** Execute inline in this session. The user explicitly prohibits subagents.

**Goal:** Stop lost idle prewarm opportunities and page-by-page content-dimension churn without changing Flutter physics or paging ownership.

**Architecture:** Keep the cursor chain in `ExplicitCommittedPagingController`. It retains an exact-scope bounded-hotset intent until an existing lifecycle boundary opens its gate. Keep all page/text/geometry state in `CommittedLogViewportCache`, whose private prepared frontier is allowed to advance independently of its explicitly exposed Flutter runway.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`, `ScrollNotification`, exact-width `TextPainter` preparation, existing keyset repository.

## Global Constraints

- No physics, velocity, controller, position, page-size or retention-limit tuning.
- No second page cache, cursor owner, fake extent, partial page, render-time layout or timer polling.
- Root remains separately pinned; movable page cap stays five; cursor acquisition remains serial.
- Run TDD RED → GREEN → REFACTOR and use only the normal `lib/main.dart` APK for later human testing.

### Task 1: Retained bounded hotset intent

**Files:**
- Modify: `lib/features/dashboard/runtime/application/explicit_committed_paging_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`

- [ ] Write failing tests for a gate-closed root retaining an intent, a lifecycle retry starting it exactly once, stale scope invalidation, and in-flight foreground promotion reuse.
- [ ] Run the named tests and observe failure because a closed gate currently returns `false` without retained state.
- [ ] Add one identity-scoped controller intent and idempotent `tryStart...`/retry lifecycle; wire existing core boundaries only.
- [ ] Re-run focused tests, refactor names/diagnostics, then commit `fix: retry bounded vertical hotset after foreground gates`.

### Task 2: Prepared versus exposed runway

**Files:**
- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart`
- Test: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [ ] Write failing tests for private preparation, silent private commits, one atomic multiple-page runway publication, low-watermark/idle flush, and exposed-page retention.
- [ ] Run named tests and observe failure because the current cache exposes `_geometry` immediately on every commit.
- [ ] Introduce explicit prepared/exposed cache geometry and batch runway publication, keeping pages private until complete and only exposing contiguous exact pages.
- [ ] Adapt render surface, demand and diagnostics to exposed geometry; verify stable controller/position/physics and no render-time TextPainter work.
- [ ] Re-run focused/broader tests, refactor, then commit `perf: publish committed vertical runway in stable batches`.

## Execution evidence required

- Focused controller/cache/viewport tests, relevant dashboard/query tests and `flutter analyze` in Ubuntu proot.
- Existing boundary suite and remote GitHub build before delivery.
- Physical Android trace remains required to prove improved fling smoothness.
