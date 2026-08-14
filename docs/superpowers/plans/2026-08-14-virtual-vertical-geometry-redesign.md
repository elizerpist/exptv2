# Virtual Vertical Geometry Redesign — Implementation Plan

> **Execution:** inline in one isolated worktree. The user explicitly
> instructed no subagents and immediate implementation, so this plan records
> the design and checkpoints rather than awaiting design approval.

**Goal:** remove the `page commit → content extent → active ballistic restart`
coupling while preserving current Query correctness and bounded resource
ownership.

**Starting point:** `324f212e78e0a376415e8e65476d4f481986838a`; production
parent `674c95634a3fbbd24b5ce0f8fddc8988ccb6614c`.

## Checkpoint 1 — Establish contracts and RED coverage

- Add a pure `CommittedVerticalGeometryManifest` compiler from ordered daily
  counts and fixed LogBox tokens.
- Add codec/index tests for geometry seeds, cache tests for geometry-neutral
  page commits, and widget tests for stable scroll extent/ballistic activity.
- Run those tests before implementation and record their expected failures.

## Checkpoint 2 — Prepared-index geometry seed

- Add compact daily count models to Kotlin `FluviPreparedDashboardIndex` and
  `DashboardBinaryCodec` (version bump).
- Decode and validate those records in Dart on the index decode isolate.
- Retain them per `PreparedDashboardDirectionalPartition`, including
  direction-reuse composition.
- Compile a manifest for the exact committed scope and validate its count
  against the already authoritative prepared frame.

## Checkpoint 3 — Geometry-neutral committed cache and renderer

- Require a manifest when a nonempty committed scope is seeded.
- Replace mutable `_CommittedPageGeometry` with the immutable manifest.
- Make page commits validate, materialize resources and advance only a
  resource/render generation.
- Make committed `SizedBox` height derive from the manifest and update the
  painter, semantics and viewport demand paths to map virtual offsets through
  it.
- Keep repaint invalidation separate from structural/geometry invalidation.

## Checkpoint 4 — Resumable resource preparation

- Change page text preparation from one synchronous full page into a private,
  resumable complete-page builder with an injected work-budget probe.
- Keep publication atomic, cancellation structural, and the serial paging
  owner intact.
- Ensure active vertical resource work does not yield to unrelated speculation.

## Checkpoint 5 — Verification and delivery

- Run focused Dart/widget/Query suites in Ubuntu proot, project fast checks,
  analysis and relevant Kotlin tests.
- Update the checklist and forensic handoff with factual results.
- Commit coherent refactor/perf/docs changes, push the implementation to
  `origin/query`, monitor the exact GitHub Actions run, and download the
  normal human APK to `/storage/emulated/0/Download/fluvi`.
