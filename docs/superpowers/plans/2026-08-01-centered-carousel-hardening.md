# Centered Carousel Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the shared centered carousel and selector tokens without changing the established dashboard vertical layout.

**Architecture:** Extend the shared engine with data-source modes, virtual physical indexing, logical mapping, rebase, velocity-profiled physics, and controller-owned preview/settled/haptic state. Keep time and avatar widgets as adapters. Promote selector height/radius to the design system and render the rail in a centered hard-clipped five-slot viewport.

**Tech Stack:** Flutter/Dart, `ScrollController`, `ScrollPhysics`, `FrictionSimulation`, `ScrollSpringSimulation`, Flutter widget/unit tests, GitHub Actions APK build.

## Global Constraints

- Golden tests are not required and are excluded from the final verification command.
- Preserve the current item extent, gap, rail top, search/date positions, and bottom navigation position.
- Use one shared CenteredCarousel engine for time and avatar consumers.
- Generated time data must support negative and positive logical indices.
- Physical virtual belt uses `virtualItemCount = 200001`, `virtualAnchorIndex = 100000`, and rebases after 5000 items while idle.
- Selector shape uses a fixed 18 px radius; no stadium/capsule shapes for controls.

### Task 1: Add failing shared-engine behavior tests

**Files:**
- Modify: `test/shared/motion/centered_carousel/centered_carousel_physics_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_math_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`
- Modify: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_primitives_test.dart`
- Modify: `test/boundary/centered_carousel_boundary_test.dart`

**Steps:**

- [ ] Add expectations for generated/cyclic data source mapping, velocity step caps, attenuated snap velocity, piecewise scale/opacity, single physical highlight, and the five-slot clipped viewport.
- [ ] Add expectations for common selector height/radius and a non-stadium shape.
- [ ] Run the focused tests inside Ubuntu proot and confirm the new expectations fail for the current 41-item/full-width implementation.

### Task 2: Implement shared data-source and physical/logical controller state

**Files:**
- Create: `lib/shared/motion/centered_carousel/centered_carousel_data_source.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`

**Steps:**

- [ ] Add `CenteredCarouselDataMode`, `CenteredCarouselDataSource<T>`, bounded list, cyclic list, and generated year source.
- [ ] Add virtual constants and controller getters for physical/logical selection, mapping, and physical item count.
- [ ] Make generated/cyclic belts use the virtual anchor and make `rebaseIfNeeded` preserve logical selection without preview, settled, or haptic emission.
- [ ] Keep legacy bounded list and `jumpToIndex` behavior compatible for existing consumers.
- [ ] Add preview and settled callbacks, selection-only haptic ticks with 38 ms throttle, and idle position-notifier handling.

### Task 3: Implement velocity-proportional physics and metrics

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_math.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_metrics.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`

**Steps:**

- [ ] Add shared `maximumStepForVelocity`, target-index projection, attenuated snap velocity, and speed-dependent spring helpers.
- [ ] Use effective velocity divided by item extent for the step profile, then use friction only as the projected landing suggestion.
- [ ] Clamp target steps to the configured maximum and preserve direction deterministically.
- [ ] Replace the broad single-curve metrics with the continuous 0/1/2/3 distance profile while keeping fixed slots.

### Task 4: Rebuild adapters on the shared engine

**Files:**
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Modify: `lib/features/dashboard/presentation/widgets/time_refinement_rail.dart`
- Modify: `lib/features/dashboard/application/dashboard_rail_controller.dart`
- Modify: `lib/features/profile/widgets/avatar_carousel.dart`

**Steps:**

- [ ] Replace the repeated 41-year list with a generated year data source centered on the current reference year.
- [ ] Keep item extent and horizontal slot spacing unchanged; use the shared selector height/radius and render only the logical year.
- [ ] Make avatars use the shared cyclic data source without local scroll or physics code.

### Task 5: Centralize selector shape and size; hard-clip rail

**Files:**
- Create: `lib/core/design/app_control_metrics.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart`
- Modify: `lib/core/design/dashboard_layout_metrics.dart`
- Modify: `lib/core/design/fluvi_rounded_box.dart`
- Modify: `lib/features/dashboard/presentation/widgets/transaction_direction_toggle.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`

**Steps:**

- [ ] Add centralized selector height and fixed 18 px radius tokens, and make all generic rounded boxes use the fixed radius.
- [ ] Tie action and rail base heights to the shared selector-height token without changing their top anchors or horizontal geometry.
- [ ] Set the direction controls to the shared height and use the same fixed-radius shape chain for surface, gradient, material, and ink behavior.
- [ ] Center the carousel in an explicit odd-slot viewport, use hard clipping, and remove `Clip.none` from the carousel.
- [ ] Audit stadium/capsule definitions and retain only the intentional decorative handle/circular exceptions.

### Task 6: Verify, commit, push, build, and download

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-01-centered-carousel-hardening.md`

**Steps:**

- [ ] Run focused shared, adapter, boundary, and non-golden regression tests in Ubuntu proot.
- [ ] Run `flutter analyze --no-fatal-infos` in Ubuntu proot and inspect all output.
- [ ] Update every checklist item honestly; do not run golden tests.
- [ ] Commit all implementation and documentation changes, push `refactor/fluvi-production`, wait for GitHub Actions APK success, and download the actual APK into `/storage/emulated/0/Download/fluvi/`.

