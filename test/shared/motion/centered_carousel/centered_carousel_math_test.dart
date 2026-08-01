import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_math.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_spec.dart';

void main() {
  final spec = CenteredCarouselSpec(itemExtent: 72);

  test('uses the stepped continuous scale profile for neighbors', () {
    final center = CenteredCarouselMath.metricsFor(
      index: 3,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );
    final neighbor = CenteredCarouselMath.metricsFor(
      index: 4,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );
    final outer = CenteredCarouselMath.metricsFor(
      index: 5,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );
    final far = CenteredCarouselMath.metricsFor(
      index: 6,
      rawCenteredIndex: 3,
      selectedIndex: 3,
      spec: spec,
    );

    expect(center.scale, closeTo(1.0, .000001));
    expect(neighbor.scale, closeTo(.84, .000001));
    expect(outer.scale, closeTo(.72, .000001));
    expect(far.scale, closeTo(.62, .000001));
    expect(center.opacity, closeTo(1.0, .000001));
    expect(neighbor.opacity, closeTo(.82, .000001));
    expect(outer.opacity, closeTo(.64, .000001));
    expect(far.opacity, closeTo(.48, .000001));
  });

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
    expect(metrics.scale, 1.0);
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
    expect(metrics.scale, .62);
    expect(metrics.opacity, .48);
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

  test('selection highlight belongs to exactly one physical index', () {
    final metrics = List.generate(
      5,
      (index) => CenteredCarouselMath.metricsFor(
        index: index,
        rawCenteredIndex: 2.4,
        selectedIndex: 2,
        spec: spec,
      ),
    );

    expect(metrics.where((value) => value.isSelected), hasLength(1));
    expect(metrics.singleWhere((value) => value.isSelected).index, 2);
  });
}
