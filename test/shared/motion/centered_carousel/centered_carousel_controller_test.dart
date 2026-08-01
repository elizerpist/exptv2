import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

void main() {
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
}
