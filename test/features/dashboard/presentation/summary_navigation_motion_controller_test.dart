import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';

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
}
