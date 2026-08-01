import 'dart:ui';

import 'centered_carousel_metrics.dart';
import 'centered_carousel_spec.dart';

abstract final class CenteredCarouselMath {
  static CenteredCarouselItemMetrics metricsFor({
    required int index,
    required double rawCenteredIndex,
    required int selectedIndex,
    required CenteredCarouselSpec spec,
  }) {
    final signedDistance = index - rawCenteredIndex;
    final absoluteDistance = signedDistance.abs();
    final normalizedDistance = spec.influenceRadiusItems <= 0
        ? 1.0
        : (absoluteDistance / spec.influenceRadiusItems).clamp(0.0, 1.0);
    final proximity = spec.emphasisCurve.transform(1.0 - normalizedDistance);

    return CenteredCarouselItemMetrics(
      index: index,
      selectedIndex: selectedIndex,
      rawCenteredIndex: rawCenteredIndex,
      signedDistanceItems: signedDistance,
      absoluteDistanceItems: absoluteDistance,
      proximity: proximity,
      scale: lerpDouble(spec.minScale, spec.maxScale, proximity)!,
      opacity: lerpDouble(spec.minOpacity, spec.maxOpacity, proximity)!,
      isSelected: index == selectedIndex,
    );
  }
}
