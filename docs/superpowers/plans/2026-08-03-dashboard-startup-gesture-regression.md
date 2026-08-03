# Dashboard startup gesture regression implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or equivalent inline task-by-task execution. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent a hidden or newly configured time rail from publishing a child selection until a user starts a rail gesture, while retaining normal user drag/tap navigation.

**Architecture:** `DashboardTimeNavigationController` remains the canonical owner of plane, parent, rail-open and settled child state. `CenteredCarouselController` owns physical viewport position but has an explicit non-user positioning gate. `DashboardCoreController` remains the sole query/cache workflow owner and treats a matching finite bundle that is loading as authoritative, not as a fallback-prefetch miss.

**Tech Stack:** Flutter, `ChangeNotifier`, `flutter_test`, existing MethodChannel/Room finite bundle boundary.

## Global Constraints

- Do not change friction, velocity bands/multiplier, spring, snap tolerance, or `maxItemsPerFling`.
- No reset or checkout; `a526738`/`bf1691e` are comparison references only.
- Run Flutter commands only through Ubuntu proot.
- A mount/reconfiguration is never a rail gesture.

---

### Task 1: Establish the canonical initial rail index

**Files:**
- Modify: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Modify: `test/features/dashboard/widgets/time_refinement_rail_test.dart`

- [x] Write the failing mounted closed-rail test asserting July 14 starts at logical day index 13, has no preview and has navigation revision zero.
- [x] Run the named test and observe the current failing `previewChild` value.
- [x] Initialize `timeCarousel` silently from `selectedChildLogicalIndex` immediately after creating navigation state; do not call preview/settle callbacks.
- [x] Re-run the named test and verify the canonical child survives first viewport attachment.

### Task 2: Gate non-user carousel callback publication

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Modify: `test/features/dashboard/widgets/time_refinement_rail_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`

- [x] Add failing tests for cyclic mount/recenter producing no preview, crossing or settle, then for a user `fling` producing the normal preview/settle sequence.
- [x] Use one controller-owned non-user positioning gate. Configuration, post-frame centering, plane/parent silent center and rebase keep physical position but cannot mutate semantic logical selection.
- [x] Arm the gate only from a rail pointer drag or tile tap. Preserve current fling plan and physics calculation.
- [x] Run controller and rail widget tests; verify bootstrap is inert and a real fling still settles once.

### Task 3: Preserve finite-bundle ownership across direction changes

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `test/features/dashboard/application/dashboard_core_controller_test.dart`

- [x] Add a failing recording-repository regression for rail-open direction change while the matching finite parent bundle is loading; expect zero motion-target child prefetches.
- [x] Ensure a direction change requests the matching current finite bundle and blocks motion-target fallback while that parent/plane is active or loading.
- [x] Run the real-core regression and assert no stale-direction preview reads, then test a deliberate user vertical/horizontal intent still commits one scope.

### Task 4: Completion evidence

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-03-dashboard-display-bundle-performance.md`

- [x] Run targeted rail, SummaryPill, core, bundle, LogBox and carousel tests in Ubuntu proot.
- [x] Run `flutter analyze` and the full golden-excluded Flutter suite in Ubuntu proot.
- [x] Update DBR-01 through DBR-05 only with measured evidence; do not claim device performance data without a device.
