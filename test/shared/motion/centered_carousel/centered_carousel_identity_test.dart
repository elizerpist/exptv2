import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  testWidgets(
    'keeps controller physics and ScrollPosition through data changes',
    (tester) async {
      final controller = CenteredCarouselController(initialIndex: 0);
      addTearDown(controller.dispose);
      var itemCount = 31;

      Widget subject() => MaterialApp(
        home: SizedBox(
          width: 360,
          height: 80,
          child: CenteredCarousel<int>(
            dataSource: CyclicCarouselDataSource<int>(
              List<int>.generate(itemCount, (index) => index),
            ),
            controller: controller,
            spec: CenteredCarouselPresets.timeRail(itemExtent: 56),
            height: 48,
            itemBuilder: (context, item, metrics) => Text('$item'),
          ),
        ),
      );

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();
      final scrollController = controller.scrollController;
      final position = scrollController.position;
      final physics = controller.physicsFor(
        CenteredCarouselPresets.timeRail(itemExtent: 56),
      );

      for (var iteration = 0; iteration < 100; iteration += 1) {
        itemCount = switch (iteration % 4) {
          0 => 30,
          1 => 12,
          2 => 28,
          _ => 31,
        };
        await tester.pumpWidget(subject());
        await tester.pump();
      }

      expect(identical(controller.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(
        identical(
          controller.physicsFor(
            CenteredCarouselPresets.timeRail(itemExtent: 56),
          ),
          physics,
        ),
        isTrue,
      );
      expect(controller.physicsCreationCount, 1);
    },
  );

  test('stable physics retains the existing dashboard motion constants', () {
    final controller = CenteredCarouselController(initialIndex: 0);
    addTearDown(controller.dispose);
    controller.updateConfiguration(
      itemCount: 31,
      itemExtent: 56,
      dataMode: CenteredCarouselDataMode.cyclic,
      finiteLength: 31,
    );
    final physics = controller.physicsFor(
      CenteredCarouselPresets.timeRail(itemExtent: 56),
    );

    expect(physics.itemExtent, 56);
    expect(physics.itemCount, CenteredCarouselController.virtualItemCount);
    expect(physics.frictionDrag, .135);
    expect(physics.velocityMultiplier, .66);
    expect(physics.minimumFlingVelocity, 140);
    expect(physics.maximumFlingVelocity, 5200);
    expect(physics.maxItemsPerFling, 5);
    expect(physics.forceOneItemOnFling, isTrue);
  });
}
