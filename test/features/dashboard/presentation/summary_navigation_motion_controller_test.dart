import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

void main() {
  test('rail tick intent accepts only an actual logical-index change', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 8, newLogicalIndex: 8),
      isFalse,
    );
    expect(controller.railTick, isNull);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 8, newLogicalIndex: 9),
      isTrue,
    );
    expect(controller.railTick, const SummaryRailTick(8, 9));

    expect(
      controller.triggerRailTick(oldLogicalIndex: 9, newLogicalIndex: 9),
      isFalse,
    );
    expect(controller.railTick, const SummaryRailTick(8, 9));
  });

  test('horizontal presentation progress is clamped and SUM can reject it', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);

    controller.beginHorizontalDrag(
      direction: SummaryTransitionDirection.forward,
      canNavigate: false,
    );
    expect(
      controller.horizontalMotion.phase,
      SummaryHorizontalMotionPhase.resisting,
    );

    controller.beginHorizontalDrag(
      direction: SummaryTransitionDirection.backward,
      canNavigate: true,
    );
    controller.updateHorizontalDragProgress(.8);
    expect(controller.horizontalMotion.progress, .8);

    controller.updateHorizontalDragProgress(2);
    expect(controller.horizontalMotion.progress, 1);

    controller.commitHorizontalDrag();
    expect(
      controller.horizontalMotion.phase,
      SummaryHorizontalMotionPhase.committed,
    );
    expect(
      controller.horizontalMotion.direction,
      SummaryTransitionDirection.backward,
    );
  });

  test('rapid rail ticks replace the last intent without a queue', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    expect(
      controller.triggerRailTick(oldLogicalIndex: 11, newLogicalIndex: 12),
      isTrue,
    );
    expect(
      controller.triggerRailTick(oldLogicalIndex: 12, newLogicalIndex: 13),
      isTrue,
    );
    expect(controller.railTick, const SummaryRailTick(12, 13));
    expect(notifications, 2);

    controller.resetRailTickBaseline(13);
    expect(
      controller.triggerRailTick(oldLogicalIndex: 13, newLogicalIndex: 13),
      isFalse,
    );
    expect(notifications, 2);
  });

  test('a newer horizontal drag wins over an interrupted commit', () {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.forward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.4)
      ..commitHorizontalDrag()
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.backward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.6)
      ..commitHorizontalDrag();

    expect(
      controller.horizontalMotion.direction,
      SummaryTransitionDirection.backward,
    );
    expect(controller.horizontalMotion.progress, .6);
    expect(
      controller.horizontalMotion.phase,
      SummaryHorizontalMotionPhase.committed,
    );
  });

  test('committed ease-out input preserves interactive visual progress', () {
    const dragProgress = .5;
    final controllerInput =
        SummaryPillTextTransitionMath.easeOutCubicInputForVisualProgress(
          dragProgress,
        );

    expect(Curves.easeOutCubic.transform(controllerInput), closeTo(.5, .003));
  });
}
