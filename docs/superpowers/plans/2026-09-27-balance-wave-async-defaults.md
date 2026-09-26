# Balance asynchronous wave and Header defaults implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Make Balance carousel waves deterministic, visually distinct and
seamless while adding tint-opacity control and the requested Balance Header
startup defaults.

**Architecture:** One pure identity-to-geometry motion core is consumed by one
carousel-owned clock. Cards repaint only their clipped decorative wave; the
existing settings controllers remain the sole write paths.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing centered carousel.

## Global Constraints

- Preserve the reference-locked mini-card shell, outer geometry, physics,
  selection and data paths.
- Reference: `/storage/emulated/0/spendee/reference/carousel2.png`.
- No local Android APK build; run tests/analyze in Ubuntu proot.
- No runtime random values or per-card animation controllers.

---

### Task 1: Lock defaults and opacity state with RED tests

**Files:**
- Modify: `test/features/dashboard/presentation/balance_presentation_settings_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

- [x] Add failing expectations for hidden Balance labels, Balance white/enabled veil,
  `balanceCarouselBackgroundOpacity == 1`, clamping and independent preservation.
- [x] Run the three focused test files in Ubuntu proot; observe failures for the
  missing background-opacity API and old defaults.
- [x] Implement only the immutable setting/controller/default changes and verify
  the same tests pass.

### Task 2: Introduce pure deterministic seamless wave motion with RED tests

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart`
- Create: `test/features/dashboard/presentation/balance_carousel_wave_motion_test.dart`
- Modify: `test/boundary/balance_presentation_settings_boundary_test.dart`

- [x] Write failing pure tests for stable identity, three distinct authored
  geometries, same-clock desynchronization, phase-zero/one equality and
  near-seam tangent continuity.
- [x] Implement a three-family authored profile resolver plus periodic motion.
- [x] Run the pure/boundary suite to green.

### Task 3: Attach the shared paint-only renderer with RED widget tests

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Write failing widget tests for per-card geometry diversity, stable
  identity across selection, static reduced-motion/off behavior, layer order,
  clipped bounds and unchanged card rectangles.
- [x] Replace the animated builder with a repaint-listenable CustomPainter
  wrapped in the current inner clip/RepaintBoundary; retain exactly one ticker.
- [x] Run the surface and canonical carousel suite to green.

### Task 4: Add the Balance submenu slider with RED/GREEN coverage

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: tuner/settings/surface tests above

- [x] Add a failing assertion for stable key
  `balance-carousel-background-opacity`, Hungarian label and 0–100% value.
- [x] Add the slider beside the existing background toggle; multiply only tint
  alpha by the stored setting.
- [x] Verify 0/intermediate/100 and toggle-value preservation without border or
  wave changes.

### Task 5: Verify and deliver

- [x] Format changed Dart files.
- [x] Run all focused tests plus `flutter analyze` in Ubuntu proot.
- [x] Re-read this checklist/reference and update only evidence-supported statuses.
- [ ] Commit, push, await the exact human diagnostic APK job, download the normal
  APK to `/storage/emulated/0/Download/fluvi`, and record SHA-256.
