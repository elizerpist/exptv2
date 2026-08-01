import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_math.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_spec.dart';

void main() {
  final spec = CenteredCarouselSpec(itemExtent: 72);

  test('centered item receives maximum scale and opacity', () {
    final metrics = CenteredCarouselMath.metricsFor(
      index: 3,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );

    expect(metrics.signedDistanceItems, 0);
    expect(metrics.absoluteDistanceItems, 0);
    expect(metrics.proximity, 1);
    expect(metrics.scale, spec.maxScale);
    expect(metrics.opacity, spec.maxOpacity);
    expect(metrics.isSelected, isTrue);
  });

  test('distance beyond the influence radius receives minimum emphasis', () {
    final metrics = CenteredCarouselMath.metricsFor(
      index: 8,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );

    expect(metrics.absoluteDistanceItems, 5);
    expect(metrics.proximity, 0);
    expect(metrics.scale, spec.minScale);
    expect(metrics.opacity, spec.minOpacity);
  });

  test('scale and opacity remain symmetric around the center', () {
    final left = CenteredCarouselMath.metricsFor(
      index: 0,
      rawCenteredIndex: 1.4,
      selectedIndex: 1,
      spec: spec,
    );
    final right = CenteredCarouselMath.metricsFor(
      index: 3,
      rawCenteredIndex: 1.6,
      selectedIndex: 2,
      spec: spec,
    );

    expect(left.absoluteDistanceItems, right.absoluteDistanceItems);
    expect(left.scale, closeTo(right.scale, 0.000001));
    expect(left.opacity, closeTo(right.opacity, 0.000001));
  });
}
