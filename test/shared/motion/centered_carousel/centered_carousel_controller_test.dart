import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  test(
    'silent jump changes the centered index without preview or settle callbacks',
    () {
      final controller = CenteredCarouselController(initialIndex: 0);
      addTearDown(controller.dispose);
      final preview = <int>[];
      final settled = <int>[];
      controller.setCallbacks(
        onPreviewChanged: preview.add,
        onSelectionSettled: settled.add,
      );

      controller.jumpToIndexSilently(4);

      expect(controller.selectedIndex, 4);
      expect(preview, isEmpty);
      expect(settled, isEmpty);
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  test('selection callback emits only when the index changes', () {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);
    final changes = <int>[];
    controller.onSelectedChanged = changes.add;
    controller.updateConfiguration(itemCount: 10, itemExtent: 72);

    controller.jumpToIndex(2);
    controller.jumpToIndex(3);
    controller.jumpToIndex(3);
    controller.jumpToIndex(1);

    expect(changes, [3, 1]);
  });

  test('configuration clamps selection for a single item and empty list', () {
    final controller = CenteredCarouselController(initialIndex: 4);
    addTearDown(controller.dispose);

    controller.updateConfiguration(itemCount: 1, itemExtent: 72);
    expect(controller.selectedIndex, 0);

    controller.updateConfiguration(itemCount: 0, itemExtent: 72);
    expect(controller.selectedIndex, 0);
    expect(controller.rawCenteredIndex, 0);
  });

  test('an identical configuration is a notifier no-op', () {
    final controller = CenteredCarouselController(initialIndex: 2);
    addTearDown(controller.dispose);
    controller.updateConfiguration(itemCount: 10, itemExtent: 72);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.updateConfiguration(itemCount: 10, itemExtent: 72);

    expect(notifications, 0);
    expect(controller.selectedIndex, 2);
    expect(controller.rawCenteredIndex, 2);
  });

  test('generated controller keeps logical index across an idle rebase', () {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);

    controller.updateConfiguration(
      itemCount: 0,
      finiteLength: null,
      dataMode: CenteredCarouselDataMode.generated,
      itemExtent: 72,
    );

    expect(controller.physicalItemCount, 200001);
    expect(controller.logicalIndexForPhysical(100000), 0);
    expect(controller.logicalIndexForPhysical(99997), -3);
    expect(controller.physicalIndexForLogical(4), 100004);
  });

  test('haptic callback emits once per logical index and honors throttle', () {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);
    var hapticTicks = 0;
    controller.onHapticTick = () => hapticTicks += 1;
    controller.updateConfiguration(
      itemCount: 0,
      dataMode: CenteredCarouselDataMode.generated,
      itemExtent: 72,
      enableHaptics: true,
      hapticThrottle: Duration.zero,
    );

    controller
      ..jumpToIndex(1)
      ..jumpToIndex(1)
      ..jumpToIndex(2);

    expect(hapticTicks, 2);
  });

  testWidgets(
    'semantic installation preserves or reconciles the physical belt explicitly',
    (tester) async {
      final controller = CenteredCarouselController(initialIndex: 4);
      addTearDown(controller.dispose);
      var previews = 0;
      var settles = 0;
      var motions = 0;
      var haptics = 0;
      controller.onHapticTick = () => haptics += 1;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 360,
            height: 72,
            child: CenteredCarousel<int>(
              items: List<int>.generate(10, (index) => index),
              controller: controller,
              spec: CenteredCarouselPresets.timeRail(itemExtent: 72),
              itemBuilder: (_, item, _) => Text('$item'),
              onPreviewChanged: (_) => previews += 1,
              onSelectionSettled: (_) => settles += 1,
              onMotionStarted: (_) => motions += 1,
            ),
          ),
        ),
      );
      await tester.pump();
      final scrollController = controller.scrollController;
      final position = scrollController.position;
      final physics = controller.physicsFor(
        CenteredCarouselPresets.timeRail(itemExtent: 72),
      );

      controller.jumpToIndex(1);
      final preservedPhysicalIndex = controller.rawCenteredIndex.round();
      controller.installSemanticDomain(
        dataMode: CenteredCarouselDataMode.bounded,
        finiteLength: 10,
        selectedLogicalIndex: 4,
        policy:
            CenteredCarouselSemanticInstallPolicy.preservePhysicalContinuity,
      );
      expect(controller.selectedLogicalIndex, 4);
      expect(controller.rawCenteredIndex.round(), preservedPhysicalIndex);

      final previewCountBefore = previews;
      final settleCountBefore = settles;
      final motionCountBefore = motions;
      final hapticCountBefore = haptics;
      final staleCommand = controller.beginMotionCommand();
      controller.installSemanticDomain(
        dataMode: CenteredCarouselDataMode.bounded,
        finiteLength: 10,
        selectedLogicalIndex: 7,
        policy:
            CenteredCarouselSemanticInstallPolicy.reconcileCanonicalSelection,
      );
      await tester.pump();

      expect(controller.isCurrentMotionCommand(staleCommand), isFalse);
      expect(controller.selectedLogicalIndex, 7);
      expect(controller.selectedPhysicalIndex, 7);
      expect(controller.rawCenteredLogicalIndex.round(), 7);
      expect(controller.hasActiveScrollActivity, isFalse);
      expect(previews, previewCountBefore);
      expect(settles, settleCountBefore);
      expect(motions, motionCountBefore + 1);
      expect(haptics, hapticCountBefore);
      expect(identical(controller.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(
        identical(
          controller.physicsFor(
            CenteredCarouselPresets.timeRail(itemExtent: 72),
          ),
          physics,
        ),
        isTrue,
      );
    },
  );
}
