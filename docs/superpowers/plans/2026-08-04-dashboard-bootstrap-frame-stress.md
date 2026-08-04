# Dashboard bootstrap, preview diagnostics and stress implementation plan

## Scope

Implement the approved 2026-08-04 slice from frozen best baseline `1430c50`.
Keep the work inline because diagnostics, bootstrap readiness and the existing
presentation store are tightly coupled and share ownership boundaries.

## Phase 1 — audit and RED tests

1. Record the preview event path and current shell startup path in
   `docs/dashboard/bootstrap-preview-stress-root-cause.md`.
2. Add focused failing tests for mode/origin separation, event ordering,
   frame coalescing, late-result rejection and bootstrap no-dash readiness.
3. Add failing bounded-row, deterministic-fixture and cache-eviction tests.
4. Run those tests in Ubuntu proot and capture expected RED failures before
   writing production code.

## Phase 2 — diagnostics and guards

1. Add immutable presentation mode/origin values to the existing snapshot
   ownership model without adding another visible state owner.
2. Add a typed bounded diagnostics ring buffer and counters.
3. Add an injectable frame scheduler so tests can prove latest-per-frame
   coalescing without requiring a physical device.
4. Emit crossing/selected/published/presented/settled-promotion events from
   the existing motion-to-presentation path.
5. Add interaction epoch/generation checks for late committed results; keep
   cache updates allowed and reject only stale visible activation.

## Phase 3 — bootstrap gate

1. Add `DashboardBootstrapPhase` and a controller that coordinates initial
   one-shot readiness using existing `DashboardCoreController` owners.
2. Ensure critical parent snapshot and current parent child preview readiness
   are established before `ready` is published.
3. Change `FluviAppShell` to render an external neutral skeleton until ready,
   then mount `CoreDashboard`; do not change dashboard visual components.
4. Cover success, zero-result, seed-gated and failure behavior with tests.

## Phase 4 — bounded stress and metrics

1. Make preview row budget explicit and test that aggregate values stay exact
   while rows stay within budget.
2. Add pure deterministic 10k/50k/100k fixture generation and test stable
   output, both directions and empty buckets.
3. Add bounded cache counters and batch metrics model. Document native
   `EXPLAIN QUERY PLAN`/profile commands and report unavailable measurements
   honestly.
4. Add tests for revision/direction invalidation and large-day paging shape.

## Phase 5 — verification and delivery

1. Format changed Dart files.
2. Run focused RED→GREEN tests, then the full non-golden test suite and
   `flutter analyze --no-fatal-infos` in Ubuntu proot.
3. Verify frozen rail files and compare baseline tests; do not run a local APK
   build.
4. Re-read the acceptance checklist and mark every item honestly.
5. Only when all feasible requirements are complete, create one final commit,
   push once, wait for online CI, and download the successful APK.
