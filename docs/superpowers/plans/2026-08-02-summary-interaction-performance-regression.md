# Summary interaction performance regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove presentation-layer full-subtree rebuilds from SummaryPill drag/return and rail-tick hot paths while preserving all navigation and query behavior.

**Architecture:** The existing `DashboardSummaryPill` remains the local owner of full-pill shell movement, but a local `ValueNotifier<Offset>` drives a child-hoisted transform. `SummaryNavigationMotionRegion` retains its existing tick controller and stages only text changes; a tick changes the paint transform without rebuilding the axis lane. The time-navigation, centered-carousel, query, and amount owners are untouched.

**Tech Stack:** Flutter widgets, `ValueNotifier`, `AnimatedBuilder`, Flutter widget tests, existing GitHub Actions Android debug build.

## Global Constraints

- Do not change `CenteredCarouselController` physics, snap, haptic, rebase, or selection semantics.
- Do not add a query, watch, native subscription, or amount update to rail preview.
- Do not await animation in navigation or query code.
- Keep the 8 px normal shell bound, 5 px SUM resistance, 100 ms shell return, and existing text transition language.
- Run Flutter commands only inside Ubuntu proot; build the APK through GitHub Actions.

---

### Task 1: Prove and remove full SummaryPill rebuilds during shell motion

**Files:**

- Modify: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`

**Interfaces:**

- Consumes: `DashboardSummaryPill`, its `navigationPresentationBuilder` and `amountPresentationBuilder` contracts.
- Produces: a shell transform driven by a local `ValueNotifier<Offset>` with the complete pill as a stable builder child.

- [x] **Step 1: Write the failing test**

Add a widget test that starts a committed vertical drag, records navigation and amount builder invocation counts after release, pumps a 50 ms shell-return frame, and expects neither count to change. It must also assert the shell transform remains on the Y axis and staged text is still holding.

- [x] **Step 2: Run test to verify it fails**

Run:

```sh
proot-distro login ubuntu -- bash -lc 'cd /home/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart --plain-name "shell return repaints only the transform"'
```

Expected: failure because the current shell return invokes the navigation and amount builders on the animation frame.

- [x] **Step 3: Write minimal implementation**

Replace `_gestureOffset` state rebuilds with a local `ValueNotifier<Offset>`. Make the gesture and return listener assign only its value. Wrap the full `FluviRoundedBox` in `ValueListenableBuilder<Offset>` and pass it through the builder `child` parameter so only `Transform.translate` rebuilds for hot frames. Preserve generation, staging, callbacks, haptic, axis locking, and disposal behavior.

- [x] **Step 4: Run test to verify it passes**

Run the command from Step 2. Expected: PASS.

### Task 2: Keep rail-tick frames out of the text-axis rebuild path

**Files:**

- Modify: `test/features/dashboard/presentation/summary_navigation_motion_region_test.dart`
- Modify: `lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart`

**Interfaces:**

- Consumes: `SummaryNavigationMotionController.railTick` and `.stagedText`.
- Produces: a rail-tick path that starts/re-targets the existing tick controller without scheduling an axis-lane state rebuild.

- [x] **Step 1: Write the failing test**

Add a widget regression test that triggers two different rail ticks while idle, advances a tick frame, and asserts the axis lane has no outgoing/incoming transition while the tick transform has Y displacement and X remains zero. Keep the test scoped to the real motion region and controller.

- [x] **Step 2: Run test to verify it fails or expose the redundant rebuild**

Run:

```sh
proot-distro login ubuntu -- bash -lc 'cd /home/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_navigation_motion_region_test.dart --plain-name "rail ticks repaint only the Y lane"'
```

Expected: the new test fails before the implementation because the current controller listener rebuilds the complete axis lane for each tick; if the public visual assertion cannot distinguish it, use the direct widget-build assertion introduced by the test to expose it.

- [x] **Step 3: Write minimal implementation**

Cache the last staged-text object in the state. On a controller notification, re-target the tick controller for a new tick. Call `setState` only when the staged-text object changed; do not rebuild for a pure tick. Build the axis lane from that cached staged state.

- [x] **Step 4: Run test to verify it passes**

Run the command from Step 2. Expected: PASS.

### Task 3: Run preserved interaction and architecture regressions

**Files:**

- Modify: `docs/superpowers/specs/2026-08-02-summary-interaction-performance-regression-design.md`

**Interfaces:**

- Consumes: focused tests from Tasks 1--2 and existing query, rail, amount, shell, and boundary suites.
- Produces: truthful checklist evidence.

- [x] **Step 1: Run focused presentation and query suites**

```sh
proot-distro login ubuntu -- bash -lc 'cd /home/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart test/features/dashboard/presentation/summary_navigation_motion_region_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart test/features/dashboard/application/dashboard_core_controller_test.dart'
```

- [x] **Step 2: Run protected physics, boundary, and analysis checks**

```sh
proot-distro login ubuntu -- bash -lc 'cd /home/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/shared/motion/centered_carousel/centered_carousel_controller_test.dart test/shared/motion/centered_carousel/centered_carousel_widget_test.dart test/boundary/fluvi_boundary_test.dart && /home/flutteruser/flutter/bin/flutter analyze --no-fatal-infos'
```

- [x] **Step 3: Update checklist statuses**

Record the exact command evidence for SIP-01 through SIP-05 and SIP-07. Retain any unrelated known baseline failure honestly.

### Task 4: Commit, push, build, and retrieve the verified APK

**Files:**

- Modify: `docs/superpowers/specs/2026-08-02-summary-interaction-performance-regression-design.md`

**Interfaces:**

- Consumes: verified working tree and GitHub Actions workflow.
- Produces: a remote commit and copied APK artifact.

- [x] **Step 1: Final verification**

Run `git diff --check`, `git status --short --branch`, and re-read the acceptance checklist before committing.

- [ ] **Step 2: Commit and push**

Commit only the verified regression repair and its tests/docs on `refactor/fluvi-production`, then push that branch to `origin`.

- [ ] **Step 3: Verify online build and download**

Wait for the GitHub Actions Android debug APK job for the pushed SHA to complete successfully. Download its APK artifact, copy it to `/storage/emulated/0/Download/fluvi/fluvi_<short-sha>.apk`, and record its SHA-256 in the checklist.
