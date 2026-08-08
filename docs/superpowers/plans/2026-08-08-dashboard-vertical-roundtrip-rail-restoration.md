# Dashboard Vertical Round-Trip and Rail-Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to
> implement this plan task-by-task. The user requires inline execution; do not
> delegate work.

**Goal:** Preserve the successful `adbb2d0` forward ready frontier while
eliminating reverse-scroll page-zero blanks and preventing committed vertical
state from rendering rail previews.

**Architecture:** Keep the existing cache/controller split. Add a cache-owned
pinned root page, add a frame-owned explicit render domain, and reset only the
existing vertical position on a changed committed scope identity. Do not alter
the rail engine, physics or forward page pipeline.

**Tech Stack:** Flutter/Dart, CustomPaint, keyset pagination,
`package:flutter_test`.

## Global Constraints

- Base: `adbb2d052be3e56f4e10d872ff9ca6f459d25224`.
- No rail, carousel, physics, controller ownership, or PreparedIndex hot-path
  source change; no golden test.
- No paint-time layout, paint-time paging, controller recreation, remount,
  timeout, debounce, placeholder blank content, or unbounded cache.
- Tests and analysis run through Ubuntu proot; profile APK is built by GitHub
  Actions then copied to `/storage/emulated/0/Download/fluvi`.

### Task 1: Lock root-page and terminal regressions (RED)

**Files:**

- Modify: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`
- Modify: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`

- [x] Add a cache test that deep-commits/retains past page zero, returns to
  top, and asserts root presence, canonical ordinal-zero geometry, bounded
  local pages and no root eviction.
- [x] Add a controller test asserting page-zero return performs no repository
  request, and an end-reached test asserting one event per generation after
  backward page commits.
- [x] Run the focused tests and record their expected RED failures.

### Task 2: Pin the committed root and preserve forward terminal state (GREEN)

**Files:**

- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Test: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`

- [x] Move ordinal-zero ownership from `_pages` to `_rootPage`; route page
  lookup, row lookup, reporting and retained-byte accounting through it.
- [x] Keep local LRU bounded independently, make ordinal-zero eviction
  impossible, and report the root identity/rows/rail-borrow state.
- [x] Scope `VERTICAL_END_REACHED` to the first forward terminal frontier;
  ensure a lower ordinal reload cannot modify forward progression.
- [x] Re-run cache tests until GREEN.

### Task 3: Make render-domain and scope reset explicit (RED then GREEN)

**Files:**

- Create: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_domain.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [x] Add failing tests proving preview mode selects the rail domain despite an
  active matching vertical cache, and a changed committed identity resets the
  same controller to top exactly once.
- [x] Resolve one immutable domain at the surface build boundary and use it in
  paint, semantics and hit-test; emit a transition-only diagnostic.
- [x] Detect exact committed scope changes in the stable viewport state and
  schedule one `jumpTo(minScrollExtent)` without recreating the controller;
  emit a scope-reset diagnostic.
- [x] Re-run renderer/viewport tests until GREEN.

### Task 4: Cross real page boundaries and rail restoration

**Files:**

- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`

- [x] Extend the existing forward-only 658/1000 flow with bottom-to-top and
  top-to-bottom round trips, checking first-row Y, root presence, zero cache
  misses and stable controller identity.
- [x] Add a committed-deep-scroll -> preview rail-frame transition assertion:
  preview selects rail domain and paints bounded scene rows even if the
  vertical cache is active.
- [x] Run the focused tests until GREEN.

### Task 5: Freeze, verify, deliver

**Files:**

- Modify: `docs/superpowers/checklists/2026-08-08-dashboard-vertical-roundtrip-rail-restoration.md`
- Modify: relevant audit/report documentation only

- [x] Hash frozen sources and prove the diff is empty.
- [x] Run targeted and full non-golden Flutter tests plus analyzer through
  Ubuntu proot; update every checklist status truthfully.
- [ ] Commit and push the branch, wait for the GitHub profile diagnostic APK,
  copy it to the requested Android download directory, verify SHA-256/ZIP, and
  record the physical-capture steps.
