# SpendeeTest Header Stage, Carousel, Diagram, and Logo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete SpendeeTest header design repair package in one code pass, then run one final GitHub APK build.

**Architecture:** Keep the existing split between pure controllers/specs and the experimental dashboard widget. Put threshold/physics behavior in testable controllers, centralize source-of-truth constants in the visual spec/controller, and keep the UI file changes scoped to header layout, carousel rendering, pie selection, logbox avatar styling, and logo editor sheet.

**Tech Stack:** Flutter/Dart, existing `flutter_test`, Ubuntu proot for local Flutter commands, GitHub Actions for APK build.

## Global Constraints

- Source of truth is `docs/prototypes/color_lab.html`.
- C2 is stage 1 bottom and C3 is stage 2 bottom.
- Do not run local Flutter APK builds on Termux/Android.
- Run local `flutter test` and `flutter analyze` through Ubuntu proot.
- Trigger exactly one online APK build at the end after commit/push.
- Download the final APK to `/storage/emulated/0/Download/spendee`.

---

### Task 1: Header Stage Geometry and Spring Semantics

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_header_stage_controller.dart`
- Modify: `test/spendeetest/spendee_dashboard_foundation_test.dart`

**Interfaces:**
- Consumes: `SpendeeHeaderStageGeometry.html(screenHeight:)`
- Produces: `SpendeeHeaderRelease.springBack` true for all animated collapse/overshoot releases, and trigger distances derived from stage target heights.

- [ ] Add failing tests that assert stage 1 trigger distance is `stage1Height - stage0Height`, stage 2 trigger distance is `stage2Height - stage1Height`, and overshoot/collapse releases spring.
- [ ] Update `SpendeeHeaderStageController` to derive thresholds from geometry target heights and classify collapse/overshoot releases as springing.
- [ ] Run targeted controller tests in Ubuntu proot.

### Task 2: Carousel Wheel Inertia, Snap, and Center Pulse

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_center_carousel_controller.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/spendee_center_carousel_inertia_test.dart`

**Interfaces:**
- Consumes: selected category index and drag/fling deltas.
- Produces: wheel-like live ticks, inertial settle, programmatic travel to selected category, and center avatar pulse.

- [ ] Add failing tests for fast fling multi-slot travel and programmatic shortest-path travel to a target index.
- [ ] Tune controller travel so fast flings do not move the whole row permanently and always settle at residual 0.
- [ ] In the dashboard, route list-row selection through the same carousel tick path and add a center pulse token.

### Task 3: C2 Layout, Progress Bar Move, and Avatar/Logbox Gloss

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: widget tests under `test/spendeetest/`

**Interfaces:**
- Consumes: C2 layout constants: stage1 layer top 96, left/right 16, height 130; avatar sizes 66/46/36.
- Produces: partition bar in header core under limit value, avatar-only stage1 glossy container, glossy logbox avatars.

- [ ] Add widget assertions for partition bar placement and removal of spent/remaining labels from stage1 glossy container.
- [ ] Add shared glossy avatar helper/painter and use it for context avatars plus logbox avatars.
- [ ] Verify stage 1/2 visual structure with targeted widget tests.

### Task 4: C3 Donut Diagram and Tappable List Selection

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: tests under `test/spendeetest/`

**Interfaces:**
- Consumes: `CategoryBudgetBarData` and selected category.
- Produces: C3 donut geometry and tappable list rows that update selected category, donut highlight, and avatar carousel target.

- [ ] Add tests for row tap selecting category and updating focused label.
- [ ] Match donut panel geometry and painter constants to C3: 112 visual, 120 viewBox scale, radius 40, center disc 29, selected stroke 17, glow blur 8.
- [ ] Connect row tap to category selection and carousel animation.

### Task 5: D1A Brand Lockup and Logo Editor Sheet

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: tests under `test/spendeetest/` or `test/widget_test.dart`

**Interfaces:**
- Consumes: D1A brand lockup constants and HTML palette/custom slot behavior.
- Produces: tappable brand logo that opens a slide-up editor with preview, palette slots, 5 custom gradient slots, and path recoloring.

- [ ] Add widget tests for D1A brand geometry and bottom sheet open.
- [ ] Implement editable logo path colors in Flutter using the packaged Fluvi SVG asset as the reference component set.
- [ ] Add palette/custom gradient slots and preview.
- [ ] Verify with targeted widget tests.

### Task 6: Verification, Commit, Push, One Build, APK Download

**Files:**
- Modify: checklist statuses after verification.

**Interfaces:**
- Consumes: all tasks complete.
- Produces: one commit, one pushed branch, one GitHub Actions build, APK in `/storage/emulated/0/Download/spendee`.

- [ ] Run targeted Flutter tests in Ubuntu proot.
- [ ] Run Flutter analyze in Ubuntu proot.
- [ ] Update checklist statuses honestly.
- [ ] Commit all implementation changes once.
- [ ] Push `spendeetest`.
- [ ] Trigger one GitHub Actions APK build.
- [ ] Download final APK to `/storage/emulated/0/Download/spendee` and verify file exists.
