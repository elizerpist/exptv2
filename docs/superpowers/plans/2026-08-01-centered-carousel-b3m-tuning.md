# Centered Carousel B3M Tuning Implementation Plan

> **For agentic workers:** This plan is executed inline in the current Fluvi worktree. Golden tests are explicitly excluded.

**Goal:** Tune the existing shared centered carousel to the Balance B3M compact geometry, remove the rail shadow/window artifact, and widen the low/medium fling bands without changing the engine architecture or dashboard structure.

**Architecture:** Extend the existing shared carousel spec with a neutral trailing-gap packing value and keep all motion/viewport math in the shared engine. Centralize B3M selector geometry in `AppSelectorMetrics`; domain adapters only provide the time tile renderer and generated source.

**Tech Stack:** Flutter/Dart, `flutter_test`, shared `CenteredCarousel`, Ubuntu proot for local Flutter verification, GitHub Actions for the APK build.

## Global Constraints

- Preserve generated/infinite year data, rebase, friction projection, spring snap, haptics, single highlight, five complete tiles, dashboard geometry, and bottom navigation.
- Use Balance B3M HTML as the geometry source.
- Do not introduce a second carousel or physics implementation.
- Golden tests are not added or run.
- APK builds run on GitHub Actions, not local Termux Flutter.

### Task 1: Add the B3M geometry contract and failing tests

**Files:**
- Modify: `lib/core/design/app_control_metrics.dart`
- Modify: `test/features/dashboard/presentation/dashboard_primitives_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_spec_test.dart`

- [ ] Add tests for the B3M-derived values: compact height 37, base radius 14, gap 8, responsive width formula, and `itemExtent = tileWidth + gap`.
- [ ] Run the focused tests and confirm they fail against the current 52/18/72 configuration.
- [ ] Add `B3mReferenceMetrics` and `AppSelectorMetrics`; retain compatibility aliases only where existing non-selector code needs them.
- [ ] Re-run the focused tests and confirm they pass.

### Task 2: Extend shared viewport packing and update time/direction adapters

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Modify: `lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart`
- Modify: `lib/core/design/fluvi_rounded_box.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_primitives_test.dart`

- [ ] Add a failing widget assertion that the time rail packs five tile widths plus four gaps into the viewport and uses the compact height/radius.
- [ ] Add `viewportTrailingGap` to the shared spec and calculate visible slots/rail width as `visibleCount * itemExtent - trailingGap`.
- [ ] Set the time rail spec to the responsive B3M tile width plus 8px gap, and render the compact tile in a fixed slot.
- [ ] Center compact direction controls inside the existing outer dashboard row; use the same height/radius tokens and keep inactive controls white.
- [ ] Add an explicit selector radius to `FluviRoundedBox` so other dashboard surfaces retain their existing semantic radius.
- [ ] Disable scrollbars and overscroll indicators through the shared carousel `ScrollConfiguration`.
- [ ] Run focused widget tests.

### Task 3: Remove the rail window/shadow artifact and tune the time scale profile

**Files:**
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_math.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_math_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_primitives_test.dart`

- [ ] Add failing assertions that the selected time tile has no shadow and both states use the fixed B3M radius.
- [ ] Remove the selected time tile shadow; keep the rail and fixed slots transparent.
- [ ] Set only the time preset scale profile to 1.12/0.96/0.84/0.76 and keep continuous distance interpolation.
- [ ] Ensure the existing outer rail height centers the shorter tile so the selected scale is not vertically clipped.
- [ ] Run math and primitive tests.

### Task 4: Widen velocity bands and add debug telemetry

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_physics_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_spec_test.dart`

- [ ] Add failing boundary tests for 0.79/0.80, 4.99/5.00, 9.99/10.00, 15.99/16.00, and 23.99/24.00 in both directions.
- [ ] Implement the new centralized velocity bands and set the shared preset multiplier to 0.66 without changing friction or spring attenuation.
- [ ] Add assert-only release telemetry with raw/effective px/s, item/s, band, projected index, capped target, delta, and settling estimate.
- [ ] Run the focused physics/spec tests.

### Task 5: Regression verification and delivery

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-01-centered-carousel-b3m-tuning.md`

- [ ] Run focused shared carousel and dashboard tests in Ubuntu proot.
- [ ] Run the full non-golden Flutter test suite and `flutter analyze --no-fatal-infos`.
- [ ] Run `git diff --check` and a static audit for rail shadows/surfaces and duplicate physics.
- [ ] Update the checklist honestly, commit, and push the code.
- [ ] Wait for GitHub Actions tests and debug APK build, download the APK directly into `/storage/emulated/0/Download/fluvi`, and verify it is an Android package.
- [ ] Commit/push the final checklist status with `[skip ci]` if it is documentation-only; do not run golden tests.
