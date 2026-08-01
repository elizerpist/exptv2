import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/app_control_metrics.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_spec.dart';

void main() {
  test('default spec exposes the shared motion policy', () {
    final spec = CenteredCarouselSpec(itemExtent: 72);

    expect(spec.minScale, .62);
    expect(spec.maxScale, 1.0);
    expect(spec.neighborScale, .84);
    expect(spec.outerScale, .72);
    expect(spec.minOpacity, .48);
    expect(spec.maxOpacity, 1.0);
    expect(spec.neighborOpacity, .82);
    expect(spec.outerOpacity, .64);
    expect(spec.influenceRadiusItems, 3);
    expect(spec.frictionDrag, .135);
    expect(spec.velocityMultiplier, .66);
    expect(spec.minimumFlingVelocity, 140);
    expect(spec.maximumFlingVelocity, 5200);
    expect(spec.maxItemsPerFling, 5);
    expect(spec.forceOneItemOnFling, isTrue);
    expect(spec.snapTolerance.distance, .01);
    expect(spec.snapTolerance.velocity, .01);
  });

  test('time and avatar presets change only domain configuration', () {
    final timeRail = CenteredCarouselPresets.timeRail(
      itemExtent: 72,
      selectorHeight: AppSelectorMetrics.yearTileHeight,
    );
    final avatars = CenteredCarouselPresets.avatars(itemExtent: 88);

    expect(timeRail.maxScale, 1.12);
    expect(timeRail.neighborScale, .96);
    expect(timeRail.outerScale, .84);
    expect(timeRail.minScale, .76);
    expect(timeRail.selectorHeight, closeTo(33.3, .0001));
    expect(timeRail.selectorRadius, 14);
    expect(timeRail.viewportTrailingGap, 8);
    expect(timeRail.velocityMultiplier, .66);
    expect(avatars.minScale, .62);
    expect(avatars.maxScale, 1.18);
    expect(avatars.velocityMultiplier, .66);
    expect(avatars.maxItemsPerFling, 4);
  });
}
