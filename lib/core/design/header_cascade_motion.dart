import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

@immutable
class CascadedCardMotion {
  const CascadedCardMotion({
    required this.top,
    required this.left,
    required this.right,
    required this.opacity,
    required this.scale,
    required this.progress,
  });

  final double top;
  final double left;
  final double right;
  final double opacity;
  final double scale;
  final double progress;
}

@immutable
class HeaderCascadeGeometry {
  const HeaderCascadeGeometry({
    required this.upperCollapsedTop,
    required this.upperExpandedTop,
    required this.upperHeight,
    required this.upperCollapsedInset,
    required this.upperExpandedInset,
    required this.upperCollapsedScale,
    required this.upperExpandedScale,
    required this.lowerExpandedTop,
    required this.lowerExpandedInset,
    required this.lowerHiddenOverlap,
    required this.lowerNestedInset,
    required this.lowerCollapsedScale,
    required this.lowerExpandedScale,
  });

  final double upperCollapsedTop;
  final double upperExpandedTop;
  final double upperHeight;
  final double upperCollapsedInset;
  final double upperExpandedInset;
  final double upperCollapsedScale;
  final double upperExpandedScale;
  final double lowerExpandedTop;
  final double lowerExpandedInset;
  final double lowerHiddenOverlap;
  final double lowerNestedInset;
  final double lowerCollapsedScale;
  final double lowerExpandedScale;
}

@immutable
class HeaderCascadeResult {
  const HeaderCascadeResult({required this.upper, required this.lower});

  final CascadedCardMotion upper;
  final CascadedCardMotion lower;
}

/// Calculates both split header card layers from one reveal progress.
abstract final class HeaderCascadeMotion {
  static const upperIntervalStart = 0.0;
  static const upperIntervalEnd = 0.72;
  static const lowerIntervalStart = 0.18;
  static const lowerIntervalEnd = 1.0;

  static double intervalProgress(double progress, double start, double end) {
    if (end <= start) return progress >= end ? 1.0 : 0.0;
    return ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  static HeaderCascadeResult calculate({
    required double masterProgress,
    required HeaderCascadeGeometry geometry,
  }) {
    final progress = masterProgress.clamp(0.0, 1.0).toDouble();
    final upperProgress = Curves.easeOutCubic.transform(
      intervalProgress(progress, upperIntervalStart, upperIntervalEnd),
    );
    final lowerProgress = Curves.easeOutCubic.transform(
      intervalProgress(progress, lowerIntervalStart, lowerIntervalEnd),
    );

    final upperTop = lerpDouble(
      geometry.upperCollapsedTop,
      geometry.upperExpandedTop,
      upperProgress,
    )!;
    final upperInset = lerpDouble(
      geometry.upperCollapsedInset,
      geometry.upperExpandedInset,
      upperProgress,
    )!;
    // Keep the fade distributed across the complete master reveal. The
    // upper card's position is eased/staggered independently, so deriving
    // opacity from the already-eased upper progress would make it reach 1.0
    // too early and visually remove the reveal effect.
    final upperOpacity = Curves.easeOut.transform(progress);

    final upper = CascadedCardMotion(
      top: upperTop,
      left: upperInset,
      right: upperInset,
      opacity: upperOpacity,
      scale: lerpDouble(
        geometry.upperCollapsedScale,
        geometry.upperExpandedScale,
        upperProgress,
      )!,
      progress: upperProgress,
    );

    final lowerCollapsedTop =
        upper.top + geometry.upperHeight - geometry.lowerHiddenOverlap;
    final lowerTop = lerpDouble(
      lowerCollapsedTop,
      geometry.lowerExpandedTop,
      lowerProgress,
    )!;
    final lowerCollapsedInset = upper.left + geometry.lowerNestedInset;
    final lowerInset = lerpDouble(
      lowerCollapsedInset,
      geometry.lowerExpandedInset,
      lowerProgress,
    )!;
    final lowerOpacity = Curves.easeOut.transform(
      intervalProgress(lowerProgress, 0.04, 0.82),
    );

    final lower = CascadedCardMotion(
      top: lowerTop,
      left: lowerInset,
      right: lowerInset,
      opacity: lowerOpacity,
      scale: lerpDouble(
        geometry.lowerCollapsedScale,
        geometry.lowerExpandedScale,
        lowerProgress,
      )!,
      progress: lowerProgress,
    );

    return HeaderCascadeResult(upper: upper, lower: lower);
  }
}
