import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

@immutable
class CenteredCarouselSpec {
  static const defaultProgrammaticScrollDuration = Duration(milliseconds: 280);
  static const defaultProgrammaticScrollCurve = Curves.easeOutCubic;

  CenteredCarouselSpec({
    required this.itemExtent,
    this.visibleItemCount = 5,
    this.viewportTrailingGap = 0,
    this.selectorHeight = 37,
    this.selectorRadius = 14,
    this.minScale = .62,
    this.maxScale = 1.0,
    this.neighborScale = .84,
    this.outerScale = .72,
    this.minOpacity = .48,
    this.maxOpacity = 1.0,
    this.neighborOpacity = .82,
    this.outerOpacity = .64,
    this.influenceRadiusItems = 3,
    this.emphasisCurve = Curves.easeOutCubic,
    this.frictionDrag = .135,
    this.velocityMultiplier = .66,
    this.minimumFlingVelocity = 140.0,
    this.maximumFlingVelocity = 5200.0,
    this.maxItemsPerFling = 5,
    this.forceOneItemOnFling = true,
    SpringDescription? snapSpring,
    this.snapTolerance = const Tolerance(distance: .01, velocity: .01),
    this.enableTapToCenter = true,
    this.enableHaptics = false,
    this.hapticThrottle = const Duration(milliseconds: 38),
    this.programmaticScrollDuration = defaultProgrammaticScrollDuration,
    this.programmaticScrollCurve = defaultProgrammaticScrollCurve,
  }) : snapSpring =
           snapSpring ??
           SpringDescription.withDampingRatio(
             mass: 1.0,
             stiffness: 420.0,
             ratio: 1.0,
           );

  final double itemExtent;
  final int visibleItemCount;
  final double viewportTrailingGap;
  final double selectorHeight;
  final double selectorRadius;
  final double minScale;
  final double maxScale;
  final double neighborScale;
  final double outerScale;
  final double minOpacity;
  final double maxOpacity;
  final double neighborOpacity;
  final double outerOpacity;
  final double influenceRadiusItems;
  final Curve emphasisCurve;
  final double frictionDrag;
  final double velocityMultiplier;
  final double minimumFlingVelocity;
  final double maximumFlingVelocity;
  final int maxItemsPerFling;
  final bool forceOneItemOnFling;
  final SpringDescription snapSpring;
  final Tolerance snapTolerance;
  final bool enableTapToCenter;
  final bool enableHaptics;
  final Duration hapticThrottle;
  final Duration programmaticScrollDuration;
  final Curve programmaticScrollCurve;
}

abstract final class CenteredCarouselPresets {
  static CenteredCarouselSpec timeRail({
    required double itemExtent,
    double viewportTrailingGap = 8,
    double selectorHeight = 37,
    double selectorRadius = 14,
  }) {
    return CenteredCarouselSpec(
      itemExtent: itemExtent,
      viewportTrailingGap: viewportTrailingGap,
      selectorHeight: selectorHeight,
      selectorRadius: selectorRadius,
      minScale: .76,
      maxScale: 1.12,
      neighborScale: .96,
      outerScale: .84,
      minOpacity: .48,
      maxOpacity: 1.0,
      neighborOpacity: .82,
      outerOpacity: .64,
      influenceRadiusItems: 3,
      frictionDrag: .135,
      velocityMultiplier: .66,
      minimumFlingVelocity: 140,
      maximumFlingVelocity: 5200,
      maxItemsPerFling: 5,
      forceOneItemOnFling: true,
      enableHaptics: true,
      hapticThrottle: const Duration(milliseconds: 38),
      snapSpring: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 420,
        ratio: 1,
      ),
    );
  }

  static CenteredCarouselSpec avatars({required double itemExtent}) {
    return CenteredCarouselSpec(
      itemExtent: itemExtent,
      minScale: .62,
      maxScale: 1.18,
      neighborScale: .92,
      outerScale: .78,
      minOpacity: .45,
      maxOpacity: 1.0,
      neighborOpacity: .80,
      outerOpacity: .62,
      influenceRadiusItems: 2.8,
      frictionDrag: .135,
      velocityMultiplier: .66,
      minimumFlingVelocity: 140,
      maximumFlingVelocity: 5000,
      maxItemsPerFling: 4,
      forceOneItemOnFling: true,
      snapSpring: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 380,
        ratio: 1,
      ),
    );
  }
}
