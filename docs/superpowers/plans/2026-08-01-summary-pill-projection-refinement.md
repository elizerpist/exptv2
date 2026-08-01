# SummaryPill Projection and Motion Refinement Implementation Plan

> **For agentic workers:** Execute this plan inline in the current worktree. Do not commit, push, or build unless the user explicitly asks.

**Goal:** Split SummaryPill navigation and amount presentation, add stable axis-specific latest-wins transitions and cyclic plane navigation, while preserving the child CenteredCarousel engine exactly.

**Architecture:** The application navigation controller remains the owner of plane/cursor transitions. Two immutable presentation projections are produced from navigation and query state independently. A stable SummaryPill shell renders title, subtitle transition, amount transition, and chevron as separate regions. The child rail remains an unchanged consumer of the existing CenteredCarousel.

**Tech Stack:** Flutter/Dart, ChangeNotifier, existing dashboard controllers, Flutter widget tests, Ubuntu/proot Flutter test runner.

## Global Constraints

- Do not modify CenteredCarousel physics, controller, spec, item geometry, data-source mapping, callbacks, haptics, or wiring.
- Navigation title/subtitle must never await or depend on query completion.
- Amount must remain stale-but-visible while a new query is loading.
- Plane changes are vertical-only; parent changes are horizontal-only; rail toggles morph subtitle only.
- Do not add AnimatedSwitcher around the complete SummaryPill content, AnimatedSize, transition queues, debounce, or Future.delayed.
- Do not commit, push, or build in this task.

## Files and ownership

- Create `lib/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart` for immutable synchronous title/subtitle state and explicit transition reason.
- Create `lib/features/dashboard/time_navigation/presentation/summary_amount_presentation.dart` for immutable amount/loading/stale/error state.
- Modify `lib/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart` to expose separate navigation and amount projection methods.
- Modify `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart` and `dashboard_time_navigation_controller.dart` to carry a monotonic navigation revision/change intent and cyclic plane transitions.
- Modify `lib/features/dashboard/query/application/current_query_controller.dart` only to retain the last result during loading, preserving latest-wins behavior.
- Create `lib/features/dashboard/presentation/widgets/summary_pill_text_transition.dart` for one-controller latest-wins axis-specific text animation.
- Modify `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart` into a stable shell with separate title/subtitle/amount regions and axis-locked gesture feedback.
- Modify `lib/features/dashboard/presentation/core_dashboard.dart` to pass the two projections without changing child rail construction.
- Modify `lib/features/dashboard/widgets/time_refinement_rail.dart` only so YEAR labels contain the localized month name without the parent year.
- Update existing docs/spec acceptance rows after implementation; no golden test is required by the user.

## TDD execution steps

### Task 1: RED checklist and regression tests

**Files:**
- Create `docs/superpowers/checklists/2026-08-01-summary-pill-refinement.md`.
- Create/update targeted tests under `test/features/dashboard/time_navigation/` and `test/features/dashboard/presentation/`.

- [x] Write SP-01–SP-12 checklist with source, ownership, acceptance, verification, and status.
- [x] Add failing tests for split projections and exact title strings.
- [x] Add failing cyclic plane-ring tests in both directions.
- [x] Add failing fake-delayed-query test proving subtitle updates before amount.
- [x] Add failing rail-toggle, axis-purity, latest-wins, gesture feedback, haptic, and month-label tests.
- [x] Run the targeted tests in Ubuntu/proot and record the expected RED failures.

### Task 2: Navigation projection and cyclic plane ring

**Files:**
- Modify `dashboard_time_navigation_state.dart` and `dashboard_time_navigation_controller.dart`.
- Create `summary_navigation_presentation.dart`.
- Modify `summary_pill_presenter.dart`.

- [x] Add typed transition metadata and monotonic revision without importing widgets/query services into domain/application code.
- [x] Refactor finer/broader intents through a modulo-3 plane transition while preserving existing promotion, clamping, and cursor values.
- [x] Implement exact `Összesen`, `Éves`, `Havi` title projection and context-only subtitle projection.
- [x] Run controller and presenter tests.

### Task 3: Amount projection and stale-while-revalidate

**Files:**
- Create `summary_amount_presentation.dart`.
- Modify `current_query_controller.dart` and `core_dashboard.dart`.

- [x] Preserve the previous `DashboardLedgerResult` when a new scope enters loading, while retaining latest-wins generation checks.
- [x] Project amount/loading/stale/error independently from navigation.
- [x] Verify delayed query behavior with a fake repository.

### Task 4: Stable SummaryPill text transition

**Files:**
- Create `summary_pill_text_transition.dart`.
- Modify `dashboard_summary_pill.dart`.

- [x] Use a fixed-size Stack with explicit previous/current snapshots and one AnimationController per transition component.
- [x] Interrupt current animation immediately on new content; use a generation token to ignore stale completions.
- [x] Keep title stable for rail toggles and use subtitle-only transitions.
- [x] Enforce `dx == 0` for vertical and `dy == 0` for horizontal transitions.
- [x] Keep amount crossfade isolated from navigation transition.

### Task 5: Gesture feedback and SummaryPill haptic

**Files:**
- Modify `dashboard_summary_pill.dart` and focused gesture test helpers.

- [x] Add touch-slop axis lock, bounded axis-only drag offset, and cancellation return animation.
- [x] Commit parent/plane transitions using distance or velocity threshold.
- [x] Emit one injectable selection haptic at threshold/commit; never on cancelled gesture.
- [x] Compose gesture offset and text transition in one controlled transform layer so no stale X offset survives a vertical transition.

### Task 6: Child label-only adapter change and regression verification

**Files:**
- Modify `lib/features/dashboard/widgets/time_refinement_rail.dart` only for YEAR label formatting.
- Update docs/checklist statuses.

- [x] Render month-only labels in YEAR child rail.
- [x] Run the unchanged shared carousel physics/controller/spec/data-source tests.
- [x] Audit `git diff --name-only` against SP-12 protected paths.
- [x] Run focused dashboard tests and the relevant full non-golden test suite in Ubuntu/proot. Flutter analyze was attempted but the Termux/proot analysis server did not complete; test compilation and execution are clean.
- [x] Mark checklist statuses honestly; do not claim completion if any item is partial.

## Verification commands

Run focused tests with:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/time_navigation test/features/dashboard/presentation test/features/dashboard/query'
```

Run analysis with:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze'
```

No APK build or Git operation is part of this task.
