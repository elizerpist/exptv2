import 'dart:ui';

import 'package:flutter/animation.dart';

import 'centered_carousel_metrics.dart';
import 'centered_carousel_spec.dart';

abstract final class CenteredCarouselMath {
  static CenteredCarouselItemMetrics metricsFor({
    required int index,
    required double rawCenteredIndex,
    required int selectedIndex,
    int? logicalIndex,
    int? selectedLogicalIndex,
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
      logicalIndex: logicalIndex ?? index,
      selectedLogicalIndex: selectedLogicalIndex ?? selectedIndex,
      rawCenteredIndex: rawCenteredIndex,
      signedDistanceItems: signedDistance,
      absoluteDistanceItems: absoluteDistance,
      proximity: proximity,
      scale: scaleForDistance(absoluteDistance, spec),
      opacity: opacityForDistance(absoluteDistance, spec),
      isSelected: index == selectedIndex,
    );
  }

  static double scaleForDistance(double distance, CenteredCarouselSpec spec) {
    final d = distance.abs();
    if (d <= 1) {
      return lerpDouble(
        spec.maxScale,
        spec.neighborScale,
        Curves.easeOutCubic.transform(d),
      )!;
    }
    if (d <= 2) {
      return lerpDouble(
        spec.neighborScale,
        spec.outerScale,
        Curves.easeInOutCubic.transform(d - 1),
      )!;
    }
    if (d <= 3) {
      return lerpDouble(
        spec.outerScale,
        spec.minScale,
        Curves.easeInOutCubic.transform(d - 2),
      )!;
    }
    return spec.minScale;
  }

  static double opacityForDistance(double distance, CenteredCarouselSpec spec) {
    final d = distance.abs();
    if (d <= 1) {
      return lerpDouble(spec.maxOpacity, spec.neighborOpacity, d)!;
    }
    if (d <= 2) {
      return lerpDouble(spec.neighborOpacity, spec.outerOpacity, d - 1)!;
    }
    if (d <= 3) {
      return lerpDouble(spec.outerOpacity, spec.minOpacity, d - 2)!;
    }
    return spec.minOpacity;
  }
}
