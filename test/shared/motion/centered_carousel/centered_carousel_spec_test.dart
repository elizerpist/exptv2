import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_spec.dart';

void main() {
  test('default spec exposes the shared motion policy', () {
    final spec = CenteredCarouselSpec(itemExtent: 72);

    expect(spec.minScale, .72);
    expect(spec.maxScale, 1.35);
    expect(spec.minOpacity, .50);
    expect(spec.maxOpacity, 1.0);
    expect(spec.influenceRadiusItems, 3.5);
    expect(spec.frictionDrag, .135);
    expect(spec.velocityMultiplier, .90);
    expect(spec.minimumFlingVelocity, 120);
    expect(spec.maximumFlingVelocity, 6000);
    expect(spec.maxItemsPerFling, 5);
    expect(spec.forceOneItemOnFling, isTrue);
    expect(spec.snapTolerance.distance, .01);
    expect(spec.snapTolerance.velocity, .01);
  });

  test('time and avatar presets change only domain configuration', () {
    final timeRail = CenteredCarouselPresets.timeRail(itemExtent: 72);
    final avatars = CenteredCarouselPresets.avatars(itemExtent: 88);

    expect(timeRail.maxScale, 1.35);
    expect(timeRail.velocityMultiplier, .90);
    expect(avatars.minScale, .62);
    expect(avatars.maxScale, 1.18);
    expect(avatars.velocityMultiplier, .82);
    expect(avatars.maxItemsPerFling, 4);
  });
}
