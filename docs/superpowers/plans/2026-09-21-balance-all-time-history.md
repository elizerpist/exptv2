# Balance all-time history Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Make Balance all-time and Summary-independent, add a Mind-parity cumulative Balance Header chart, and make every carousel card explicitly Fluvi white.

**Architecture:** `DashboardCoreController` publishes one immutable all-time Balance model keyed only by prepared data revision and canonical non-temporal query/focus provenance. A neutral Header trend kernel owns fixed chart geometry and paint behavior; Mind and Balance pass typed data/format adapters. Balance UI only renders that model and keeps the existing shared carousel engine untouched.

**Tech Stack:** Flutter/Dart, existing prepared dashboard index, `ValueNotifier` presentation contracts, `CustomPainter`, Flutter widget/golden tests, GitHub Actions human diagnostic APK, SCIP Dart 1.6.2.

## Global constraints

- Preserve the physical interaction floor `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- Never make a renderer read a repository, Room, raw ledger collection, or LogBox rows.
- Summary navigation must not compute/rebuild/publish Balance data.
- Reuse `FluviVisualTokens.surface` and the shared `CenteredCarouselMotionProfiles.timeRefinementRail` object.
- Do not claim physical acceptance; it remains user-only.

### Task 0: Classify the profile baseline

**Files:**
- Inspect: `integration_test/dashboard_interaction_profile_test.dart`, `dashboard_core_controller.dart`, `dashboard_core_ephemeral_focus_test.dart`

- [x] Reproduce the score/heatmap held-range mismatch in a production-parent deterministic test.
- [x] Compare the exact binding/publication sequence with pre-`b799af3b` source.
- [x] Repair the branch-introduced complete-frame/live-range ordering defect in a separate application+journal unit.
- [ ] Run the focused Core/profile-contract suite and commit this as a separate application+journal unit if production source changes.

### Task 1: Replace current-scope Balance data with one all-time Core model

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_balance_presentation.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`

- [x] Add a failing production-parent all-time fixture whose month net differs materially from its all-time net.
- [x] Derive both directional all-time frames from canonical non-temporal scope and construct one immutable identity independent of visible Summary scope.
- [x] Add all-time newest-across-directions and positive data/query revision tests.
- [x] Verify no Summary-only movement publishes Balance or starts repository/index work.
- [ ] Commit the Core read-model unit and its separate journal entry.

### Task 2: Add immutable cumulative Balance history

**Files:**
- Modify: Balance Core presentation/projection owner identified in Task 1
- Test: Balance Core and presentation tests

- [x] Add RED fixtures for two-month, two-year, sparse, one-point and empty domain mapping.
- [x] Build cumulative values from existing prepared immutable all-time membership, preserving actual start/end/extrema and tie ordering.
- [x] Verify each point is cumulative income minus expense and changes only for real upstream provenance changes.
- [ ] Commit with Task 1 only if the read-model diff remains one cohesive Core projection.

### Task 3: Extract the neutral Header trend renderer and mount Balance

**Files:**
- Modify: `lib/features/dashboard/mind/presentation/mind_header_score_chart.dart`
- Create/modify: neutral Header trend renderer selected by source audit
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/mind_header_score_chart_test.dart`, golden suite, Balance surface tests

- [x] Add failing Balance parity/domain tests before refactoring painter code.
- [x] Extract constants/paint/reveal/pointer-observer behavior without changing Mind pixels or interaction ownership.
- [x] Supply score and money adapters; map earliest/latest Balance history to fixed left/right plot edges.
- [x] Mount the Balance amount at `left=16, top=16`, and the trend beneath it under existing Header expansion progress.
- [x] Run Mind golden tests unchanged; commit/journal remains the final delivery step.

### Task 4: White carousel surfaces and final delivery

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Add RED test for all five cards using `FluviVisualTokens.surface`.
- [x] Replace only the theme-dependent fill token.
- [ ] Run Balance/shared carousel/Budget/no-regression suites, analyzer, formatter and boundary checks.
- [ ] Push the final application SHA, obtain/download the matching human APK, regenerate exact-source SCIP on tooling, and record journal evidence.
