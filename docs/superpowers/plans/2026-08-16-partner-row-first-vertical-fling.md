# Partner-row first vertical fling implementation plan

> **For agentic workers:** This task is executed inline because the gesture
> reproduction and the production setting share the same Scrollable owner.

**Goal:** Preserve the first single-move vertical fling through partner-row
gesture arbitration with Flutter's native drag-start contract.

**Architecture:** The partner recognizer remains an arena participant that
rejects vertical intent. The existing Flutter vertical recognizer remains the
only vertical owner; its existing `CustomScrollView` receives a down-origin
drag-start setting so the pending pre-arena displacement is delivered by the
framework itself.

**Tech stack:** Flutter 3.41.4 / Dart widget tests.

## Global constraints

- One final production commit and one normal online `lib/main.dart` APK.
- No paging, cache, physics, controller, position, or velocity changes.
- No second recognizer, raw-event replay, synthetic delta, or custom ballistic.
- Preserve intentional left partner swipe behavior.

### Task 1: Reproduce the real arena handoff before production code

**Files:**

- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [x] Add a widget test using `_readyFixture` with a real
  `DashboardLogBoxPartnerSwipeController`, a pointer down on the first eligible
  row, one `Offset(0, -192)` move, and immediate up.
- [x] Assert the real `ScrollableState.position.pixels` advances, the partner
  controller never owns focus, and framework lifecycle diagnostics show a
  normal interaction rather than an application-created velocity.
- [x] Run the named test on `464255c`; it fails because `start` removes the
  sole pending drag delta after the partner recognizer resolves vertical.

### Task 2: Use the existing Flutter Scrollable native contract

**Files:**

- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [x] Set the existing `CustomScrollView.dragStartBehavior` to
  `DragStartBehavior.down`.
- [x] Run the red test; it passes only if the framework's own vertical drag
  recognizer applies the pending one-move displacement.
- [x] Run the focused partner-swipe and viewport suites to prove horizontal,
  multi-move vertical, tap/cancel, and terminal behavior remains intact.

### Task 3: Verify protected owners and delivery

**Files:**

- Test only: existing paging, cache, viewport, query, scene, geometry, and
  boundary suites.

- [x] Re-read the acceptance checklist and mark each item truthfully.
- [x] Run required local test/analyze/boundary commands through Ubuntu proot.
- [ ] Create one commit named `fix: preserve first vertical fling through
  gesture arbitration`, push it once, wait for its online human APK workflow,
  download exactly that `lib/main.dart` APK, and record its SHA-256.
