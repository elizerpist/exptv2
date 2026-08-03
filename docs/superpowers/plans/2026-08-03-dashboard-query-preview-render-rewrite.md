# Dashboard query–preview–render rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the dashboard query/presentation flow from `85f41ab` so one
revisioned snapshot drives SummaryPill, count, LogBox and child preview without
rail-motion I/O or direction/scope races.
**Architecture:** Canonical domain QueryKey → one query coordinator and
immutable PresentationStore → batch child index → memory-only preview lane →
single settle/commit lane → isolated presentation selectors. The accepted rail
engine at `85f41ab` is protected.
**Tech Stack:** Dart/Flutter, existing Room/native bridge, package:test and
Flutter widget tests, profile-mode benchmark through CI/device.

## Global Constraints

- Preserve `85f41ab1e17e28ca9702252deb3cbff327cd8520` rail physics and gesture
  semantics; do not add a manual fling or second motion owner.
- Do not run or add golden tests.
- Keep all changes behind the checklist in
  `docs/superpowers/checklists/2026-08-03-dashboard-query-preview-render-rewrite.md`.
- Preserve the backup refs and user `.tmp-*` files.

---

## Tasks

- [ ] **1. Baseline inventory and RED regression suite**
  - Inspect the existing query, summary, logbox, time-navigation and rail
    adapters at `85f41ab`.
  - Add non-golden failing tests under `test/features/dashboard/query/`,
    `test/features/dashboard/application/`, and
    `test/features/dashboard/presentation/` for direction toggle, preview
    sequence, motion isolation, promotion, header isolation and year swipe.
  - Verify RED with explicit targeted `flutter test` commands in Ubuntu proot.

- [ ] **2. Canonical domain identity**
  - Extend/reuse `QueryKey` and `QueryDescriptor` in
    `lib/features/dashboard/query/domain/` so direction, complete scope,
    filters and refinements are value identity.
  - Add raw-to-logical rail mapping as a pure domain function; raw physical
    indexes never enter QueryKey or cache keys.
  - Turn the QueryKey tests GREEN.

- [ ] **3. Immutable snapshot store and coordinator**
  - Introduce the smallest neutral `PresentationSnapshot` and
    `DashboardPresentationStore` in the application/query layer.
  - Make one coordinator own active descriptor, generation, stale-result
    rejection and committed-watch lease; infrastructure remains widget-free.
  - Add snapshot consistency and generation tests, then GREEN.

- [ ] **4. Batch child presentation index**
  - Add a repository/application batch API for the active parent’s children
    (`year→month`, `month→day`) returning immutable metrics and first-page row
    snapshots, including valid zero results.
  - Ensure both directions can be prewarmed outside the rail frame callback.
  - Test no N+1 reads and deterministic empty/dense targets.

- [ ] **5. Preview and commit lanes**
  - Wire the existing rail adapter to synchronous store lookup during every
    centered-child callback; no repository/native/watch/formatting work there.
  - On settle, promote the identical snapshot by identity/value, commit once,
    and defer/lease live observation without blocking motion.
  - Make preview sequence and no-side-effect tests GREEN.

- [ ] **6. Atomic direction and scope presentation**
  - Route SummaryPill amount, transaction count and LogBox selectors through
    the same snapshot publish.
  - Reject stale async results by queryKey + generation + revision.
  - Verify seeded July 2026 expense (68,900,000/94) and income
    (70,700,000/6) toggles atomically with no placeholder.

- [ ] **7. Rebuild boundaries and instrumentation**
  - Isolate rail, amount, count, LogBox and header selector boundaries without
    rebuilding the dashboard root per tick.
  - Add bounded numeric counters for preview/commit, motion I/O, cache,
    promotion and rebuilds; avoid verbose per-tick string formatting.
  - Add header-isolation and counter assertions.

- [ ] **8. Verification and delivery**
  - Run targeted non-golden unit/widget/integration tests, `dart format`, and
    `flutter analyze` in Ubuntu proot.
  - Run profile-mode empty-vs-dense rail, header, direction and parent-swipe
    benchmark against `85f41ab`; document p50/p95/p99/worst timings and any
    blocked device measurement honestly.
  - Update the checklist, commit in focused changes, push the rewrite branch,
    and report remaining risks. Never use a golden suite as completion proof.
