# Balance wave/defaults implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Add independent Balance wave/content-border controls and the requested app initialization defaults without changing accepted Balance mechanics.

**Architecture:** One immutable `BalancePresentationSettings` model and controller own all Balance presentation writes. A single phase owned by the existing carousel State is supplied to all mini-card painters. The existing accent resolver and shared ranked-list geometry resolver remain canonical.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing centered-carousel shared engine.

## Global Constraints

- Preserve carousel physics, external card bounds, focus scale, page selection and financial/ranking calculations.
- Reference path: `/storage/emulated/0/spendee/reference/carousel2.png`.
- Do not create per-card controllers/tickers or a second accent/ranked-layout resolver.
- Do not run an Android APK build locally; run Flutter checks in Ubuntu proot.
- Defaults seed existing controller state; later user writes keep their existing behavior.

---

### Task 1: Lock settings and startup defaults with RED tests

**Files:**
- Modify: `test/features/dashboard/presentation/balance_presentation_settings_test.dart`
- Modify: `test/core/design/fluvi_global_appearance_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Modify: `test/features/dashboard/mind/domain/mind_behavioral_score_settings_test.dart`
- Modify: `test/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings_test.dart`

**Interfaces:**
- Consumes: existing settings/default model factories.
- Produces: failing expectations for the requested two new booleans and all startup seeds.

- [x] Add tests requiring `balanceCarouselWaveAnimationEnabled == false` and `balanceContentCardColoredBorderEnabled == false`, independent writers, and preserved stored opacity.
- [x] Add tests requiring softened Header text/icon defaults, Balance/Mind chart softness, Balance 100% opacity/15% width/compound, Mind centered and dynamic mixed heatmap defaults.
- [x] Run the focused tests in Ubuntu proot; observe expected failures for absent fields/old defaults.

### Task 2: Implement typed state and default seeds

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_behavioral_score_settings.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart`

**Interfaces:**
- Produces: `setBalanceCarouselWaveAnimationEnabled(bool)` and `setBalanceContentCardColoredBorderEnabled(bool)` on the one existing Balance controller.

- [x] Add both typed fields through constructor, default, copy, equality/hash and single-write setters.
- [x] Seed each required existing startup owner with only its requested value.
- [x] Re-run Task 1 focused tests to GREEN.

### Task 3: Add the two tuner controls with RED/GREEN widget coverage

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`

- [x] Add failing widget expectations for exact labels and stable keys `balance-carousel-wave-animation-enabled` and `balance-content-card-colored-border-enabled`.
- [x] Add the existing boolean-choice widgets under their required group without changing slider geometry or values.
- [x] Re-run tuner tests to GREEN.

### Task 4: Animate the canonical wave and color-match the content border

**Files:**
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`

**Interfaces:**
- Consumes: `BalancePresentationSettings`, `_BalanceCarouselReferenceAccent`, existing shared carousel controller.
- Produces: a shared phase animation passed to `_BalanceCarouselCard` and selected-card accent into content-border paint.

- [x] Add RED tests for static/animated/reduced-motion wave phase, selection phase continuity, unchanged bounds, and content-border color/opacity independence.
- [x] Put one 6-second `AnimationController` in `_BalanceUpperCarouselState`; never reset it on card selection; pass it to each wave renderer.
- [x] Make painter phase deform only the existing path within 2–5 px-equivalent motion; skip animated rebuilds when disabled/reduced.
- [x] Resolve selected content topic to the already canonical carousel card and reuse its accent for optional colored border. Preserve neutral baseline when off.
- [x] Re-run surface tests and canonical mini-card golden to GREEN without golden regeneration.

### Task 5: Validate ranked-list regression and architecture boundaries

**Files:**
- Modify only if a regression test requires it: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`
- Run: `test/boundary/dashboard_motion_data_isolation_boundary_test.dart`

- [x] Add/extend test evidence for both category/partner stretch parity and fixed first-place avatar.
- [x] Run focused ranked-list, motion/architecture boundary, and full relevant widget suites.

### Task 6: Verify, document, commit and deliver

- [x] Format changed Dart/docs files.
- [x] Re-read the reference, this plan and checklist; replace every status with evidence-based final status.
- [x] Run the 306-test feature-focused Flutter suite in Ubuntu proot; all tests passed.
- [x] Run `flutter analyze` in Ubuntu proot; no issues found.
- [x] Diagnose the app-suite Query-sheet flake: the isolated case passes (1/1), while its full file remains order/timing-sensitive and outside this Balance-only scope.
- [x] Commit production code/tests, push this branch, monitor the exact GitHub human diagnostic APK job, download normal human APK to `/storage/emulated/0/Download/fluvi`, and verify SHA-256.
