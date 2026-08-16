# Immediate Committed Interaction Readiness Implementation Plan

> **For agentic workers:** Execute inline with RED → GREEN → REFACTOR. This task deliberately creates one final production commit only.

**Goal:** Restore immediate committed vertical readiness after Query publication without discarding the later reservation, candidate-promotion, deferred-presentation, or truthful-diagnostics invariants.

**Architecture:** `DashboardCoreController` remains the lifecycle/priority owner. `ExplicitCommittedPagingController` remains the one serial cursor owner and gains an explicit full-drain continuation behind a presentation-only operation. The prepared scene cache remains the single capacity owner; the controller receives a cache-owned admission answer and never mirrors limits.

**Tech Stack:** Flutter/Dart, existing controller/runtime/cache/widget tests; Android human APK via GitHub Actions only.

## Global Constraints

- One final production commit and one final human APK only.
- No controller, position, physics, page-size, cache-capacity, virtual-geometry, placeholder, timer, or second-scheduler workaround.
- No repository acquisition during raw pointer contact or formal vertical ballistic.
- Keep Query publication reservation, directional Query state, and exact hotset promotion.

### Task 1: Paging state model

**Files:** runtime paging controller and its focused tests.

- [ ] Add RED 67-row structural-idle reproduction: deferred ordinal 1 must continue to ordinal 2 automatically.
- [ ] Add RED full-drain arriving behind presentation-only and ballistic-only no-next-read tests.
- [ ] Make the active serial operation carry an explicit full-versus-presentation-only intent; retain a full continuation when required and resume it only through the same serial owner once acquisition safety returns.
- [ ] Verify focused paging tests green.

### Task 2: Typed motion and priority orchestration

**Files:** core controller, core Query tests, scene rotation tests.

- [ ] Add RED motion-lane tests for incompatible rail/structural versus decorative Summary/amount motion.
- [ ] Make paging safety depend only on typed incompatible lanes while keeping aggregate diagnostic motion truthful and conservative cache-only speculation gates intact.
- [ ] Reorder motion-idle lifecycle: formal vertical interaction gets presentation-only; otherwise full ready-ahead gets first ownership.
- [ ] Verify Query reservation/sheet/pointer/supersede/foreground-miss tests green.

### Task 3: Cache admission and bounded diagnostics

**Files:** scene-window contracts, prepared scene cache, core controller and their tests.

- [ ] Add RED cache-owned retained-window admission/rejection-epoch test and bounded-key diagnostic test.
- [ ] Expose an opaque cache-owned admission epoch; skip identical inadmissible Summary candidates before preparation and retry only after that epoch or index identity changes.
- [ ] Replace emitted full retained/candidate keys with existing-style short digests while retaining full identities internally.
- [ ] Verify cache capacity/lease and Summary tests green.

### Task 4: Vertical terminal lifecycle

**Files:** scroll observer, viewport and viewport tests.

- [ ] Add RED real-ballistic/no-simulation/boundary terminal ordering tests.
- [ ] Defer ScrollEnd terminal classification only while the framework `goBallistic` handoff is unresolved; classify after the unmodified framework outcome is observed.
- [ ] Verify no physics/controller identity changes and existing pointer takeover tests remain green.

### Task 5: Full verification and one delivery

- [ ] Run all named focused suites, `test-fluvi-fast.sh`, Ubuntu-proot `flutter analyze`, and boundary verification.
- [ ] Re-read this checklist, inspect diff against `3f4a684`, and mark every automated requirement honestly.
- [ ] Create exactly one commit: `fix: restore immediate committed interaction readiness`.
- [ ] Push once; monitor/download exactly one normal human APK for that SHA to `/storage/emulated/0/Download/fluvi`; record SHA-256.
