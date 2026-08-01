import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_data_source.dart';

void main() {
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
}
