# SummaryPill Shell-to-Text Choreography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan inline, task-by-task. The shell, staged snapshots, and text region are one coupled presentation state machine; parallel implementation would create ownership conflicts.

**Goal:** Make horizontal SummaryPill navigation use complete-shell drag follow, smooth shell return, then title/subtitle crossfade, while applying the same committed shell-return staging to vertical navigation without affecting rail, query, or amount semantics.

**Architecture:** DashboardSummaryPill owns the sole paint-only shell offset and one 100 ms return controller. SummaryNavigationMotionController carries immutable staged title/subtitle snapshots and generation tokens but has no ticker or application dependency. SummaryNavigationMotionRegion renders frozen outgoing content during the shell return and delegates the post-return crossfade to the existing SummaryPillTextTransition.

**Tech Stack:** Flutter AnimationController, Curves.easeOutCubic, Flutter widget and golden tests, existing DashboardTimeNavigationController and CurrentQueryController.

## Global Constraints

- Do not modify lib/shared/motion/centered_carousel.
- Do not place animation state in DashboardTimeNavigationController, CurrentQueryController, DashboardCoreController, or DashboardSummaryAmountController.
- The GestureDetector remains outside the shell Transform and keeps its original SummaryPill bounds.
- Drag, return, and text motion are paint-only; do not animate constraints, padding, margin, size, or dashboard geometry.
- Navigation and query commit in the release turn; neither awaits shell/text motion.
- The title/subtitle text transition waits only for matching shell-return completion.
- Amount is inside the outer shell transform but outside the inner title/subtitle transition.
- Rail preview starts zero queries; rail haptic remains the only tick haptic.
- Use 0.10 pointer damping with an 8 px YEAR/MONTH cap, a 5 px SUM cap, a 100 ms shell return, and 190 ms existing text transition.

---

## File map

| File | Responsibility after this work |
| --- | --- |
| lib/features/dashboard/presentation/summary_navigation_motion_controller.dart | Presentation-only rail tick and generation-safe staged text snapshot intent. |
| lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart | Stable gesture hitbox, shared X/Y shell transform, 100 ms return state machine, commit snapshots. |
| lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart | Freeze outgoing text during shell return, trigger the common axis text transition after return, suppress tick visuals during axis motion. |
| lib/features/dashboard/presentation/widgets/summary_pill_text_transition.dart | Reused clipped latest-wins text transition; no duplicate axis engine is introduced. |
| test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart | Staged request generation and rail tick unit contracts. |
| test/features/dashboard/presentation/summary_navigation_motion_region_test.dart | Frozen outgoing content, X/Y axis purity, staged text and tick suppression. |
| test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart | Whole-pill transform, commit chronology, query parallelism, cancel, SUM and amount boundaries. |
| test/features/dashboard/time_navigation/summary_pill_gesture_test.dart | Vertical/horizontal gesture isolation and vertical staged return regression. |
| test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart | Keep the rail tick golden only. |
| test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart | New complete-pill drag, return, and post-return text golden frames. |
| test/goldens/summary_pill_shell_drag.png | Full SummaryPill during horizontal drag. |
| test/goldens/summary_pill_shell_return.png | Full SummaryPill during shell return with outgoing text frozen. |
| test/goldens/summary_pill_shell_text_transition.png | Full SummaryPill after shell return while title/subtitle crossfade. |
| docs/superpowers/checklists/2026-08-02-summary-pill-shell-text-choreography.md | Truthful final requirement status. |

## Task 1: Replace inner horizontal drag state with staged text presentation intents

**Files:**
- Modify: lib/features/dashboard/presentation/summary_navigation_motion_controller.dart
- Test: test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart

**Consumes:** SummaryTextContent, SummaryTransitionAxis, SummaryTransitionDirection, and the existing rail tick public API.

**Produces:** SummaryStagedTextTransition, SummaryStagedTextPhase, and generation-safe methods consumed by DashboardSummaryPill and SummaryNavigationMotionRegion.

- [ ] **Step 1: Write failing controller tests**

Replace tests that assert SummaryHorizontalMotion drag progress with tests for a held outgoing snapshot, an activated transition request, stale generation rejection, and rail tick preservation:

~~~dart
test('staged text holds outgoing content until its matching shell return completes', () {
  final controller = SummaryNavigationMotionController();
  addTearDown(controller.dispose);
  const outgoing = SummaryTextContent(title: 'Havi', subtitle: '2026. július');
  const incoming = SummaryTextContent(title: 'Havi', subtitle: '2026. augusztus');

  final generation = controller.holdTextForShellReturn(
    outgoing: outgoing,
    axis: SummaryTransitionAxis.horizontal,
    direction: SummaryTransitionDirection.forward,
  );
  controller.bindShellReturnIncoming(generation: generation, incoming: incoming);

  expect(controller.stagedText.phase, SummaryStagedTextPhase.holding);
  expect(controller.stagedText.outgoing, outgoing);
  expect(controller.stagedText.incoming, incoming);

  controller.completeShellReturn(generation: generation);
  expect(controller.stagedText.phase, SummaryStagedTextPhase.transitioning);
});

test('stale shell completion cannot activate a newer staged text request', () {
  final controller = SummaryNavigationMotionController();
  addTearDown(controller.dispose);
  final oldGeneration = controller.holdTextForShellReturn(
    outgoing: _current,
    axis: SummaryTransitionAxis.horizontal,
    direction: SummaryTransitionDirection.forward,
  );
  final newGeneration = controller.holdTextForShellReturn(
    outgoing: _next,
    axis: SummaryTransitionAxis.vertical,
    direction: SummaryTransitionDirection.backward,
  );

  controller.completeShellReturn(generation: oldGeneration);
  expect(controller.stagedText.generation, newGeneration);
  expect(controller.stagedText.phase, SummaryStagedTextPhase.holding);
});
~~~

- [ ] **Step 2: Run the focused controller test and verify red**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart'
~~~

Expected: compilation failures for SummaryStagedTextTransition, SummaryStagedTextPhase, holdTextForShellReturn, bindShellReturnIncoming, and completeShellReturn.

- [ ] **Step 3: Implement one immutable staged-text contract**

Remove SummaryHorizontalMotion and its begin/update/commit/cancel APIs. Add only the snapshot state needed by the text region:

~~~dart
enum SummaryStagedTextPhase { idle, holding, transitioning }

@immutable
class SummaryStagedTextTransition {
  const SummaryStagedTextTransition.idle()
    : phase = SummaryStagedTextPhase.idle,
      outgoing = null,
      incoming = null,
      axis = SummaryTransitionAxis.none,
      direction = SummaryTransitionDirection.forward,
      generation = 0;

  const SummaryStagedTextTransition({
    required this.phase,
    required this.outgoing,
    required this.incoming,
    required this.axis,
    required this.direction,
    required this.generation,
  });

  final SummaryStagedTextPhase phase;
  final SummaryTextContent? outgoing;
  final SummaryTextContent? incoming;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final int generation;

  bool get isAxisMotionActive => phase != SummaryStagedTextPhase.idle;
}
~~~

Implement these controller methods with notifyListeners only after their generation checks:

~~~dart
int holdTextForShellReturn({
  required SummaryTextContent outgoing,
  required SummaryTransitionAxis axis,
  required SummaryTransitionDirection direction,
});

void bindShellReturnIncoming({
  required int generation,
  required SummaryTextContent incoming,
});

void completeShellReturn({required int generation});

void completeTextTransition({required int generation});

void cancelStagedTextMotion();
~~~

holdTextForShellReturn must increment the controller generation, publish holding with outgoing and null incoming, and return that generation. bindShellReturnIncoming accepts only the active holding generation. completeShellReturn accepts only an active holding request with a non-null incoming. completeTextTransition accepts only the matching transitioning generation. cancelStagedTextMotion increments invalidation by publishing idle; it must not write navigation or query state.

Keep triggerRailTick and resetRailTickBaseline unchanged. Region-side suppression, not rail intent suppression, preserves rail diagnostics/haptics.

- [ ] **Step 4: Run controller tests and verify green**

Run the command from Step 2.

Expected: all controller tests pass; tests assert that a rail tick can still be recorded while staged text state has no navigation/query dependency.

- [ ] **Step 5: Commit the presentation contract**

~~~sh
git add lib/features/dashboard/presentation/summary_navigation_motion_controller.dart test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart
git commit -m "refactor(fluvi): stage summary text presentation"
~~~

## Task 2: Make the text region freeze snapshots and eliminate inner drag preview

**Files:**
- Modify: lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart
- Test: test/features/dashboard/presentation/summary_navigation_motion_region_test.dart
- Test: test/features/dashboard/presentation/summary_pill_transition_red_test.dart

**Consumes:** SummaryStagedTextTransition from Task 1 and canonical SummaryTextContent passed by the navigation slot.

**Produces:** A text region that renders the outgoing snapshot during shell return and starts one existing X/Y transition only after completeShellReturn.

- [ ] **Step 1: Write failing staged-region tests**

Delete tests that expect summary-navigation-drag-outgoing or summary-navigation-drag-incoming during a user drag. Add tests that operate on controller staged state:

~~~dart
testWidgets('holding shell return freezes outgoing text and starts no axis transition', (tester) async {
  final controller = SummaryNavigationMotionController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(_host(controller: controller, content: _next));

  final generation = controller.holdTextForShellReturn(
    outgoing: _current,
    axis: SummaryTransitionAxis.horizontal,
    direction: SummaryTransitionDirection.forward,
  );
  controller.bindShellReturnIncoming(generation: generation, incoming: _next);
  await tester.pump();

  expect(find.text(_current.subtitle), findsOneWidget);
  expect(find.text(_next.subtitle), findsNothing);
  expect(find.byKey(const ValueKey('summary-navigation-axis-outgoing')), findsNothing);
});

testWidgets('matching shell completion starts X-only text transition', (tester) async {
  final controller = SummaryNavigationMotionController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(_host(controller: controller, content: _next));
  final generation = controller.holdTextForShellReturn(
    outgoing: _current,
    axis: SummaryTransitionAxis.horizontal,
    direction: SummaryTransitionDirection.forward,
  );
  controller.bindShellReturnIncoming(generation: generation, incoming: _next);
  controller.completeShellReturn(generation: generation);
  await tester.pump();

  expect(_translation(tester, const ValueKey('summary-navigation-axis-outgoing')).dy, 0);
  expect(_translation(tester, const ValueKey('summary-navigation-axis-incoming')).dy, 0);
});
~~~

Add a rail tick composition test: triggerRailTick while holding and while transitioning, then assert the tick transform has Offset.zero and eventually remains zero. Retain the existing normal idle tick test.

- [ ] **Step 2: Run the focused region tests and verify red**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_navigation_motion_region_test.dart test/features/dashboard/presentation/summary_pill_transition_red_test.dart'
~~~

Expected: failures because the current region reads horizontalMotion and still renders interactive text preview.

- [ ] **Step 3: Implement staged rendering without a second text engine**

In SummaryNavigationMotionRegion:

1. Remove horizontalCandidate, horizontalCandidateBuilder, _HorizontalDragPreview, _returnController, drag progress continuation, and every SummaryHorizontalMotion branch.
2. Read controller.stagedText in build.
3. For holding, render a fixed clipped SummaryNavigationTextBlock containing staged.outgoing. It must not instantiate SummaryPillTextTransition.
4. For transitioning, instantiate the existing text transition with a stable ValueKey based on staged.generation, staged.incoming as content, staged.outgoing as initialPreviousContent, staged.axis/direction, and an onTransitionCompleted that calls completeTextTransition for exactly that generation.
5. For idle, retain the existing canonical content path and standard transition behavior for non-gesture programmatic changes.

The core rendering decision should have this shape:

~~~dart
final staged = widget.controller.stagedText;
if (staged.phase == SummaryStagedTextPhase.holding) {
  return _fixedText(staged.outgoing!);
}
if (staged.phase == SummaryStagedTextPhase.transitioning) {
  return SummaryPillTextTransition(
    key: ValueKey(staged.generation),
    content: staged.incoming!,
    axis: staged.axis,
    direction: staged.direction,
    initialPreviousContent: staged.outgoing,
    onTransitionCompleted: () =>
        widget.controller.completeTextTransition(generation: staged.generation),
  );
}
return SummaryPillTextTransition(
  content: widget.content,
  axis: widget.axis,
  direction: widget.direction,
  animate: widget.animateAxis,
  animateTitle: widget.animateTitle,
  compact: widget.compact,
  height: widget.height,
);
~~~

Use the existing SummaryPillTextTransitionMath unchanged. Do not create an AnimatedSwitcher, Timer, Future.delayed, or a second axis transition widget.

Before triggering a normal rail tick impulse, gate it by staged.isAxisMotionActive:

~~~dart
if (widget.controller.stagedText.isAxisMotionActive) {
  _tickController
    ..stop()
    ..value = 0;
  return;
}
~~~

The gate changes only the visual impulse; it neither removes the rail tick intent nor calls haptics.

- [ ] **Step 4: Run region and axis tests and verify green**

Run the command from Step 2.

Expected: the normal -4 px tick still returns to zero, staged return displays only outgoing text, staged horizontal text has dy == 0, staged vertical text has dx == 0, and no inner drag-preview keys exist.

- [ ] **Step 5: Commit the text presentation change**

~~~sh
git add lib/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart test/features/dashboard/presentation/summary_navigation_motion_region_test.dart test/features/dashboard/presentation/summary_pill_transition_red_test.dart
git commit -m "feat(fluvi): stage summary text after shell return"
~~~

## Task 3: Implement the shared full-shell return choreography

**Files:**
- Modify: lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart
- Test: test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart
- Test: test/features/dashboard/time_navigation/summary_pill_gesture_test.dart

**Consumes:** Task 1 staged text APIs and Task 2 frozen/transitioning region.

**Produces:** One fixed gesture hitbox, common X/Y shell drag follow, generation-safe 100 ms return, immediate navigation/query callback, and post-return text start.

- [ ] **Step 1: Write failing whole-pill chronology tests**

Replace the existing test named SummaryPill horizontal drag moves only navigation text and commits once. Its new assertions must prove the opposite:

~~~dart
final shell = _translation(
  tester,
  const ValueKey('dashboard-summary-shell-transform'),
);
expect(shell.dx, lessThan(0));
expect(shell.dy, 0);
expect(
  find.ancestor(
    of: find.text('707 000 Ft'),
    matching: find.byKey(const ValueKey('dashboard-summary-shell-transform')),
  ),
  findsOneWidget,
);
expect(find.byKey(const ValueKey('summary-navigation-axis-outgoing')), findsNothing);
~~~

Add a T0–T6 committed-swipe test:

~~~dart
await gesture.up();
await tester.pump();
expect(queryScopeGeneration.value, 1); // T2: release turn
expect(_translation(tester, shellKey).dx, lessThan(0)); // T3: return active
expect(find.byKey(axisOutgoingKey), findsNothing); // text still frozen

await tester.pump(const Duration(milliseconds: 100));
expect(_translation(tester, shellKey), Offset.zero); // T4
expect(find.byKey(axisOutgoingKey), findsOneWidget); // T5
~~~

Add tests for:

- amount is within the shell transform but not an ancestor/descendant of summary-navigation-axis-outgoing or summary-navigation-axis-incoming;
- commit haptic happens once, cancel has none;
- horizontal cancel returns full shell with no query or text transition;
- SUM returns full shell resistance within 4–6 px and makes no commit/query;
- vertical committed swipe has dx == 0 during shell return, no text transition before 100 ms, then uses only Y offsets;
- a second gesture during return and during text transition invalidates the first generation and produces no old axis transition.

- [ ] **Step 2: Run the widget and gesture tests and verify red**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart test/features/dashboard/time_navigation/summary_pill_gesture_test.dart'
~~~

Expected: the new whole-shell and chronological assertions fail because the current horizontal drag moves only inner text and committed gestures reset the shell synchronously.

- [ ] **Step 3: Refactor DashboardSummaryPill to own one shell state machine**

Add stable constants and state beside the existing gesture values:

~~~dart
static const _shellDragFactor = .10;
static const _maximumShellTravel = 8.0;
static const _maximumSumResistance = 5.0;
static const _shellReturnDuration = Duration(milliseconds: 100);

int _shellGeneration = 0;
int? _stagedTextGeneration;
_SummaryGestureAxis? _returnAxis;
bool _returnStartsTextTransition = false;
~~~

Rename the current return controller to clarify that it is the shell return, give it _shellReturnDuration, and retain Curves.easeOutCubic. Give the outer transform a stable key:

~~~dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  // existing pan callbacks
  child: Transform.translate(
    key: const ValueKey('dashboard-summary-shell-transform'),
    offset: _gestureOffset,
    child: completeSummaryPill,
  ),
)
~~~

On every axis-locked drag, write exactly one component:

~~~dart
_gestureOffset = switch (axis) {
  _SummaryGestureAxis.horizontal => Offset(
      (_dx * _shellDragFactor).clamp(
        -maximumTravel,
        maximumTravel,
      ),
      0,
    ),
  _SummaryGestureAxis.vertical => Offset(
      0,
      (_dy * _shellDragFactor).clamp(
        -_maximumShellTravel,
        _maximumShellTravel,
      ),
    ),
};
~~~

For YEAR/MONTH horizontal maximumTravel is _maximumShellTravel. For SUM it is _maximumSumResistance. Continue to use the pure horizontalCandidateBuilder only to decide whether the application layer allows parent navigation and whether committed haptic is allowed; it no longer renders a text candidate.

Replace synchronous _resetGestureState on every gesture end with one _startShellReturn helper. The helper must:

1. Capture the local shell generation and _returnStartOffset.
2. For a committed gesture, call holdTextForShellReturn with outgoing SummaryTextContent and the explicit axis/direction before the callback, then store its returned controller token in _stagedTextGeneration.
3. Start the local 100 ms controller immediately.
4. Call the existing navigation callback immediately and without awaiting the return animation.
5. Read navigationPresentationBuilder after the synchronous callback and bind the immutable incoming title/subtitle to _stagedTextGeneration.
6. On the matching AnimationStatus.completed only, set the shell offset to zero and call completeShellReturn with _stagedTextGeneration for committed gestures.

Its completion must be generation-guarded:

~~~dart
if (shellGeneration != _shellGeneration || !mounted) return;
setState(() => _gestureOffset = Offset.zero);
final stagedGeneration = _stagedTextGeneration;
if (_returnStartsTextTransition && stagedGeneration != null) {
  _motionController.completeShellReturn(generation: stagedGeneration);
}
~~~

On cancel and SUM, call the same helper with _returnStartsTextTransition = false and never call a navigation callback. On a new drag, stop the return controller, increment _shellGeneration, call cancelStagedTextMotion, reset both _dx/_dy and set _gestureOffset to zero before accepting the new axis. Keep threshold and committed haptic semantics unchanged.

The navigation listeneable still rebuilds only the text slot for rail preview. Do not add the shell controller to DashboardCoreController or any query listener.

- [ ] **Step 4: Run the widget chronology suite and verify green**

Run the command from Step 2.

Expected: full shell X movement during horizontal drag, smooth shell return before text keys appear, query notification in the release turn, vertical Y-only parity, stable hitbox/gesture behavior, SUM resistance, and amount boundary assertions all pass.

- [ ] **Step 5: Commit the shell choreography**

~~~sh
git add lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart test/features/dashboard/time_navigation/summary_pill_gesture_test.dart
git commit -m "feat(fluvi): stage summary pill shell return"
~~~

## Task 4: Add golden evidence and preserve rail/query integration boundaries

**Files:**
- Modify: test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart
- Create: test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart
- Create: test/goldens/summary_pill_shell_drag.png
- Create: test/goldens/summary_pill_shell_return.png
- Create: test/goldens/summary_pill_shell_text_transition.png
- Modify: test/features/dashboard/widgets/time_refinement_rail_test.dart

**Consumes:** Completed Tasks 1–3 and existing TimeRefinementRail callback contract.

**Produces:** Visual evidence for all three horizontal phases and regression proof that rail gesture/query behavior remains unchanged.

- [ ] **Step 1: Write failing goldens and rail-isolation assertions**

Create a DashboardSummaryPill golden host with a RepaintBoundary around the complete 378 by 59 pill. Capture:

1. after a left horizontal move of 40 px: complete shell is displaced left and only the outgoing text exists;
2. 50 ms after committed release: shell is between its drag displacement and zero, outgoing text still exists, no axis text keys exist;
3. 100 ms after release: shell equals zero and outgoing/incoming text crossfade keys both exist.

In time_refinement_rail_test, wire a SummaryNavigationMotionController to the existing preview callback, fling the rail, then assert:

~~~dart
expect(motion.railTick, isNotNull);
expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
~~~

This proves that rail input can continue to publish its visual tick intent but cannot create a shell/text parent-navigation request.

- [ ] **Step 2: Run golden and rail tests in red mode**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart'
~~~

Expected: the new golden test is absent or fails and the shell-return frame assertions fail before Task 3 implementation.

- [ ] **Step 3: Generate and review focused golden baselines**

Keep summary_navigation_motion_golden_test limited to the rail tick golden; remove its old interactive-horizontal-text golden because drag no longer moves internal text. Implement the new shell golden host and generate:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --update-goldens test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart'
~~~

Inspect all three generated PNGs through the local image viewer before accepting them. They must show no layout shift, no text crossfade during shell return, no amount crossfade, and no off-axis motion.

- [ ] **Step 4: Run golden and rail tests in green mode**

Run the command from Step 2.

Expected: all golden frames match, rail tick tests remain green, and no horizontal shell state is produced by rail input.

- [ ] **Step 5: Commit visual and integration proof**

~~~sh
git add test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart test/goldens/summary_pill_shell_drag.png test/goldens/summary_pill_shell_return.png test/goldens/summary_pill_shell_text_transition.png
git commit -m "test(fluvi): cover summary shell motion phases"
~~~

## Task 5: Run protected regressions, update checklist, commit, and deliver

**Files:**
- Modify: docs/superpowers/checklists/2026-08-02-summary-pill-shell-text-choreography.md

**Consumes:** All implementation and test changes from Tasks 1–4.

**Produces:** Verified status for every SPM requirement, a clean protected mechanics diff, one final source commit, and a pushed branch for GitHub Actions.

- [ ] **Step 1: Run the complete focused regression suite**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/summary_navigation_motion_controller_test.dart test/features/dashboard/presentation/summary_navigation_motion_region_test.dart test/features/dashboard/presentation/summary_pill_transition_red_test.dart test/features/dashboard/presentation/summary_pill_presentation_widget_test.dart test/features/dashboard/presentation/summary_navigation_motion_golden_test.dart test/features/dashboard/presentation/summary_pill_shell_motion_golden_test.dart test/features/dashboard/time_navigation/summary_pill_gesture_test.dart test/features/dashboard/widgets/time_refinement_rail_test.dart test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart test/features/dashboard/query/current_query_controller_test.dart test/features/dashboard/application/dashboard_summary_amount_controller_test.dart'
~~~

Expected: every selected test passes.

- [ ] **Step 2: Run analysis and protected-directory check**

Run:

~~~sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze'
git diff --check
git diff --name-only 0b6427d..HEAD -- lib/shared/motion/centered_carousel
~~~

Expected: flutter analyze exits 0, git diff --check exits 0, and the protected-directory command has no output.

- [ ] **Step 3: Re-read and update the acceptance checklist**

For SPM-01 through SPM-13, update Status to DONE only when its named test or inspection evidence exists. Keep any failed or unverified row PARTIAL or NOT DONE and report it; do not substitute a build for a missing acceptance item.

- [ ] **Step 4: Final source/checklist commit and push**

Run:

~~~sh
git add docs/superpowers/checklists/2026-08-02-summary-pill-shell-text-choreography.md
git commit -m "docs(fluvi): verify summary shell choreography"
git push origin refactor/fluvi-production
~~~

If source or test changes remain uncommitted, commit them with their focused task before this checklist commit. Do not amend prior milestone commits.

- [ ] **Step 5: Verify the remote Android build**

Use the pushed commit's GitHub Actions run. After its debug build succeeds, download the exact APK to:

~~~text
/storage/emulated/0/Download/fluvi/
~~~

Record the commit SHA, workflow URL, APK filename, and SHA-256 in the completion report. Do not attempt a local Termux APK build.
