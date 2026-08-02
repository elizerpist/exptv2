# Summary Navigation Motion Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline; these motion changes share one state machine and are not safe to delegate independently).

**Goal:** Restore rail tick and horizontal SummaryPill navigation motion without changing rail mechanics, query timing, or amount presentation.

**Architecture:** A presentation-only controller carries tick/drag intents from the rail and SummaryPill to one motion region.  The motion region owns all tick and axis animation controllers; application controllers retain navigation and query ownership.

**Tech Stack:** Flutter `AnimationController`, `SpringSimulation`, widget/unit tests, existing GitHub Actions Android build.

## Global Constraints

- Do not edit `lib/shared/motion/centered_carousel/**`.
- Do not add presentation state to navigation/query/amount controllers.
- Never await motion before navigation/query, or query before motion.
- Keep the amount outside both motion lanes and preserve preview-without-query.

---

### Task 1: Establish presentation motion contracts

**Files:**
- Create: `lib/features/dashboard/presentation/summary_navigation_motion_controller.dart`
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Modify: `test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart`
- Test: `test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart`

- [ ] Write failing tests for duplicate/initial tick suppression, horizontal drag intent, SUM rejection and read-only parent candidate.
- [ ] Run the focused tests and observe the expected missing-controller/API failures.
- [ ] Implement immutable presentation-only intent snapshots and the read-only parent candidate reusing the actual parent transition calculation.
- [ ] Re-run the focused tests and commit the contract.

### Task 2: Restore the two motion lanes

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart`
- Modify: `lib/features/dashboard/presentation/widgets/summary_pill_text_transition.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Test: `test/features/dashboard/presentation/summary_pill_transition_red_test.dart`
- Test: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`

- [ ] Write failing tests for 4-px Y-only tick, amount isolation, X-only forward/backward transition, interactive drag/cancel and rapid latest-wins replacement.
- [ ] Run the focused tests and observe the expected assertions fail.
- [ ] Implement `SummaryNavigationTextBlock`, one unbounded retargetable tick controller, and the shared axis transition/drag presentation in the clipped text region.
- [ ] Re-run the focused tests and commit the motion region.

### Task 3: Wire presentation intents without altering mechanics

**Files:**
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/widgets/time_refinement_rail.dart`
- Modify: `lib/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart`
- Modify: `test/features/dashboard/widgets/time_refinement_rail_test.dart`
- Modify: `test/features/dashboard/time_navigation/summary_pill_gesture_test.dart`
- Modify: `test/boundary/fluvi_boundary_test.dart`

- [ ] Write failing rail/pill integration tests for actual-index-only tick, no preview query, and gesture isolation.
- [ ] Run the tests and observe the expected absent callback/motion-region failures.
- [ ] Wire the local presentation controller through `CoreDashboard`; emit only old/new rail preview intent; add bounded S-TICK/S-HORIZONTAL diagnostics.
- [ ] Re-run focused boundary, rail, gesture, query and shared-carousel suites; inspect the forbidden directory diff.

### Task 4: Verify and deliver

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-02-summary-navigation-motion-recovery.md`

- [ ] Run targeted and full non-golden Flutter tests plus `flutter analyze` in Ubuntu proot.
- [ ] Re-read the checklist, inspect code/diff and record truthful statuses.
- [ ] Commit, push `refactor/fluvi-production`, wait for GitHub Actions debug build, download the exact APK into `/storage/emulated/0/Download/fluvi`, and record its SHA-256.
