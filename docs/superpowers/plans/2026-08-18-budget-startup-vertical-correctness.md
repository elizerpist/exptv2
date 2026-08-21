# Budget, startup and committed vertical correctness Implementation Plan

**Goal:** Correct target-bound Budget ring rendering, deterministic first-attempt dashboard bootstrap, and live committed-page readiness through vertical ballistics.

**Architecture:** The Budget presentation controller owns one immutable selected-limit visual state and the rail renders it without duplicating state. The existing explicit committed-paging controller remains the sole cursor owner while its admission policy distinguishes raw pointer contact from post-release live viewport demand. The shell remains the one startup coordinator and records bounded stage diagnostics instead of retrying automatically.

**Constraints:** Preserve current worktree changes; no golden or integration tests; no test harness in the human APK; normal APK entrypoint is `lib/main.dart`; do not modify `MILESTONE_COMMITS.md`.

### Task 1: Budget selected-limit state

- [ ] Write unit/widget RED cases for missing limit, positive-limit fractions, optimistic create/delete and A↔B handoff.
- [ ] Verify each test fails on the scalar/notifier implementation.
- [ ] Move the target/key/amount/progress contract into one immutable presentation state and render chrome only for its exact selected target with a positive limit.
- [ ] Run the focused Budget suites and the relevant boundary checks.
- [ ] Commit `fix: bind budget progress to exact limit identity`.

### Task 2: First-attempt startup diagnosis and correction

- [ ] Write RED app/core tests that record the first failed stage and reject a hidden second start.
- [ ] Reproduce the initial failure path with fresh and migrated storage collaborators, capture the bounded diagnostic, and trace the reported owner.
- [ ] Correct only the proven owner; preserve the visible manual Retry for persistent failures.
- [ ] Run startup/category/readiness and Kotlin migration/core tests.
- [ ] Commit `fix: make dashboard cold bootstrap first-attempt deterministic`.

### Task 3: Ballistic live committed-page readiness

- [ ] Write RED runtime/cache tests for pointer-contact deferral, decoded-page retention, chained >12-page demand, serial I/O, immutable geometry and ordinal-9/next-10 failure.
- [ ] Verify the current global interaction gate blocks live demand after pointer release.
- [ ] Split the existing controller admission policy into raw-contact protection and post-release live-demand readiness; fix the exact ordinal invariant owner.
- [ ] Run paging/cache/geometry/LogBox and boundary regressions.
- [ ] Commit `fix: keep committed pages ready through vertical ballistics` (and a distinct invariant commit only if the proof makes it independent).

### Task 4: Delivery

- [ ] Format changed Dart/Kotlin files, analyze and re-run the full required focused suites.
- [ ] Re-read the checklist, update every status from fresh evidence, stage only task files and push `separated-core-modes`.
- [ ] Monitor the exact pushed SHA’s normal human APK job, download its `lib/main.dart` artifact to `/storage/emulated/0/Download/fluvi`, and verify SHA-256.
