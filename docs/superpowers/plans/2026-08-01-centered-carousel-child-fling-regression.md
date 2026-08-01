# Centered Carousel Child Fling Regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore multi-item velocity/friction/spring behavior for every child TimeRail while preserving the SummaryPill's intentional one-parent-step navigation.

**Architecture:** `CenteredCarousel` remains the sole owner of child drag, ballistic projection, spring snap, preview, settled selection, haptics, and retargeting. `DashboardTimeNavigationController` only maps shared logical indices to year/month/day values. Parent SummaryPill gestures remain outside the child Scrollable and continue to issue one-step domain intents.

**Tech Stack:** Flutter `ListView` + `ScrollPhysics`, Dart unit/widget tests, GitHub Actions online APK build.

## Global Constraints

- Do not replace `CenterSnapScrollPhysics` with `PageScrollPhysics` or manual ±1 navigation.
- Keep the existing friction projection, velocity bands, spring profile, haptics, infinite/rebase, tap-retarget, item extent, and scale/opacity behavior unchanged.
- Preview callbacks must not call `animateToIndex`, recreate the carousel controller, or schedule a recenter.
- The parent SummaryPill may remain one-step; the child rail must accept the full Scrollable release velocity.
- No golden test is required for this interaction-only regression.

## Architecture card

### Scope and sources

- User requirement: child year/month/day rails regain multi-item fling after the three-plane integration.
- Existing implementation: `lib/shared/motion/centered_carousel/centered_carousel.dart`, `centered_carousel_controller.dart`, `centered_carousel_physics.dart`, `lib/features/dashboard/widgets/time_refinement_rail.dart`.
- Regression source: commit `646b7f0`, which introduced the three-plane dashboard wiring.

### Single source and write path

- Source of truth: `CenteredCarousel` + `CenteredCarouselController` + `CenterSnapScrollPhysics`.
- Read model: `CenteredCarouselItemMetrics` and logical index callbacks.
- Only child selection write path: `CenteredCarouselController` emits preview/settled logical indices to `DashboardTimeNavigationController`.
- Parent write path: `DashboardSummaryPill` emits one-step parent intents directly to `DashboardTimeNavigationController`.

### State ownership

| State | Owner | Publication rule |
|---|---|---|
| Raw scroll/ballistic position | `CenteredCarouselController` / `ScrollPosition` | Every scroll frame for visual metrics |
| Child preview | `CenteredCarouselController` → `DashboardTimeNavigationController` | No query and no programmatic recenter |
| Child settled selection | `DashboardTimeNavigationController` | Commits effective time scope |
| Parent plane/cursor | `DashboardTimeNavigationController` | Only SummaryPill parent intents change it |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
|---|---|---|---|
| Child fling physics | `CenterSnapScrollPhysics` | Keep and repair lifecycle wiring only | Existing physics tests already assert multi-item targets |
| Parent one-step navigation | `DashboardTimeNavigationController` + SummaryPill gesture | Keep separate from child Scrollable | Parent gesture tests and child gesture isolation test |

### Layer flow

`Scrollable` → `CenteredCarouselController`/`CenterSnapScrollPhysics` → logical index → `DashboardTimeNavigationController` → query scope.

### Verification

- Domain/unit: physics projection and velocity-band regression matrix.
- Widget/integration: parent rebuild during active child fling, three data-source adapters, tap retarget, and parent one-step isolation.
- Boundary: existing `centered_carousel_boundary_test.dart` and `scripts/verify-fluvi-boundaries.sh`.
- Delivery: GitHub Actions tests/build, then APK in `/storage/emulated/0/Download/fluvi/`.

## Implementation tasks

### Task 1: Freeze the regression with a failing widget test

**Files:**
- Modify: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`

- [x] Add a stateful host whose `onPreviewChanged` calls `setState`, reproducing the dashboard parent rebuild during an active fling.
- [x] Fling a shared carousel with a velocity that the existing spec maps beyond one item.
- [x] Run the focused test red-first, then green after the lifecycle fix.

### Task 2: Remove only the stale rebuild recenter

**Files:**
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`

- [x] Keep `_scheduleRecenter()` for the initial/real viewport-width change.
- [x] Stop calling `_scheduleRecenter()` for ordinary `didUpdateWidget` rebuilds with the same controller and configuration.
- [x] Continue syncing callbacks/spec/data source; let `updateConfiguration()` handle genuine data-mode/item-count/item-extent changes.
- [x] Preserve a recenter only when the controller identity changes and the new controller needs a post-frame initial center.

### Task 3: Verify all child adapters and isolation

**Files:**
- Modify: `test/features/dashboard/time_navigation/time_rail_data_source_factory_test.dart` if coverage needs expansion.
- Modify: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`.
- Modify: `test/features/dashboard/time_navigation/summary_pill_gesture_test.dart` only if an isolation assertion is missing.

- [x] Assert the generated year source, cyclic month source, and cyclic day source all flow through `CenteredCarousel` without feature-local physics.
- [x] Assert a preview-driven rebuild does not reset the active scroll position or final multi-item target.
- [x] Assert parent SummaryPill navigation remains a single parent step and does not own child physics.
- [x] Preserve the existing tap-retarget and haptic tests.

### Task 4: Verify, document, and deliver

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-01-centered-carousel-child-fling-regression.md`.

- [x] Run focused Flutter tests, boundary verification, full non-golden Flutter tests, and `git diff --check`.
- [x] Record the exact root cause: preview-driven parent rebuild → `didUpdateWidget` → post-frame `jumpToIndex` → ballistic cancellation.
- [x] Commit and push the code plus the already-requested direct-release workflow change.
- [x] Run the online GitHub APK build, obtain its direct release download URL, download the APK to the Fluvi Download folder, and verify size/hash.
