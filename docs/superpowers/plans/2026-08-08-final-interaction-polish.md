# Final Interaction Polish Implementation Plan

> **For agentic workers:** Execute inline because the two edits share the same visible-frame notification boundary and the user explicitly requested one agent.

**Goal:** Atomically reset deep vertical scroll before a sibling LogBox preview paints, and map SummaryPill vertical gestures to the canonical plane order.

**Architecture:** Extend the existing presentation-lane listener in the stable viewport with one visible-scope identity. Reorder staged-lane notifications so the lightweight reset precedes payload rendering. Keep navigation semantics and visual no-op settle unchanged.

**Tech Stack:** Flutter, `ValueListenable`, `ScrollController`, `flutter_test`.

## Global Constraints

- No rail, physics, paging, prepared-scene, post-settle-rebase or Summary-label changes.
- No new `ScrollController`, viewport key/remount, timer, debounce, animation-to-top or golden test.
- Run Flutter verification inside Ubuntu proot; build the human profile APK on GitHub Actions.

### Task 1: Capture the failing scope-transition contracts

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `test/features/dashboard/visible/dashboard_visible_frame_store_test.dart`
- Modify: `test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart`

- [ ] Write a May-deep → April-preview first-frame test expecting pixels zero immediately, then run it against the current committed-only listener and observe failure.
- [ ] Add rapid sibling, day/year hierarchy, no-double-reset and lane-order regressions.
- [ ] Add down/up Summary gesture matrix tests that fail under the old mapping.

### Task 2: Implement the minimal presentation-boundary correction

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: `lib/features/dashboard/visible/application/dashboard_visible_frame_store.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`

- [ ] Replace committed-only scope tracking with visible-scope tracking and immediate native reset only for a real non-top scope change.
- [ ] Flush presentation metadata before LogBox payload, retaining all staged pointer atomicity.
- [ ] Invert only Summary vertical commit mapping.
- [ ] Run focused tests after each change.

### Task 3: Verify frozen boundaries and deliver

**Files:**
- Modify: this checklist with final evidence/statuses.

- [ ] Run focused tests, full non-golden suite and `flutter analyze` in proot.
- [ ] Audit frozen file diffs against the base and re-read this checklist.
- [ ] Commit/push; monitor GitHub Actions; build/download only the normal-entrypoint HUMAN_DIAGNOSTIC APK; verify SHA-256 and ZIP integrity.
