# Balance Carousel Polish Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recover and complete the interrupted Balance presentation refinement without changing financial, Query, repository, or shared-carousel semantics.

**Architecture:** Extend three existing presentation owners only. The Balance mini-card renderer becomes the canonical visual component; a neutral entity template serves category and partner detail pages; the pure shell geometry resolver applies the minimum of the released contained-FAB envelope and the count-safe gain.

**Tech Stack:** Flutter/Dart, existing widget/golden tests, Ubuntu-proot Flutter tooling, GitHub Actions human diagnostic APK.

## Global Constraints

- Preserve `CenteredCarousel` controller, motion profile, focus behaviour, and outer geometry.
- Use existing immutable prepared data and visual token/palette owners only.
- Keep rank-detail selection local to the lower card.
- Do not create repository, Query, prepared-index, or asynchronous work in presentation.
- Verify changed visual states with focused widget/golden evidence; physical Android validation remains user-only.

### Task 1: Re-establish recovered visual regression tests

**Files:**

- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`
- Modify: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`
- Modify: `test/features/dashboard/presentation/dynamic_mind_flat_bottomnav_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`

- [ ] Add a widget assertion that each selected Balance topic has title, leading visual, primary and secondary nodes with shared visual-slot and type hierarchy.
- [ ] Add cross-topic rank-row and detail geometry assertions, including the production 210px detail envelope.
- [ ] Add resolver and real-app-shell assertions for released-envelope/count-safe gain and count clearance.
- [ ] Run each test selection before production edits and record the expected RED failure.

### Task 2: Canonical Balance mini card

**Files:**

- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [ ] Create one metric spec consumed by every mini-card topic: title, 42–46px visual slot, 14–16px horizontal padding, 12px top padding, two-line text hierarchy, and icon fallback in that same slot.
- [ ] Run the focused Balance surface test and regenerate only its changed golden.
- [ ] Confirm the existing shared carousel engine and its scales are untouched.

### Task 3: Shared entity rank/detail template

**Files:**

- Modify: `lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart`
- Test: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`

- [ ] Make category and partner page-one rows consume the same layout metrics and leave semantic data differences in supplied immutable view data only.
- [ ] Make category and partner page-two bodies consume one return/hero/pill/chip/distribution scaffold, adapting only entity label, icon and data.
- [ ] Run the focused detail test, generate compact goldens, and inspect the changed image states.

### Task 4: Count-safe global BottomNav gain

**Files:**

- Modify: `lib/features/dashboard/presentation/dashboard_shell_presentation.dart`
- Test: `test/features/dashboard/presentation/dynamic_mind_flat_bottomnav_test.dart`
- Test: `test/features/dashboard/presentation/core_dashboard_test.dart`

- [ ] Resolve the physical contained-FAB release separately from count-safe clearance.
- [ ] Apply `min(desiredGain, releasedEnvelope, countSafeGain)` only for the existing eligible BottomNav state.
- [ ] Run the pure resolver test, then the mounted E2E test, and finally the full CoreDashboard presentation test.

### Task 5: Verify and deliver

**Files:**

- Modify: checklist and journal evidence only after results are known.

- [ ] Run changed-file format verification, `git diff --check`, focused tests, fast/boundary suite, and `flutter analyze --no-pub --no-fatal-infos` inside Ubuntu proot.
- [ ] Re-read this checklist and mark only evidenced items `DONE`.
- [ ] Commit production changes, append factual journal evidence in a separate `[skip ci]` commit, push the recovery branch, monitor exact-SHA Actions, and download/verify the normal human APK.
