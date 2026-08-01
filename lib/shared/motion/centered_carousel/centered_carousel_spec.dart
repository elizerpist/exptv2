import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

@immutable
class CenteredCarouselSpec {
  static const defaultProgrammaticScrollDuration = Duration(milliseconds: 280);
  static const defaultProgrammaticScrollCurve = Curves.easeOutCubic;

  CenteredCarouselSpec({
    required this.itemExtent,
    this.minScale = .72,
    this.maxScale = 1.35,
    this.minOpacity = .50,
    this.maxOpacity = 1.0,
    this.influenceRadiusItems = 3.5,
    this.emphasisCurve = Curves.easeOutCubic,
    this.frictionDrag = .135,
    this.velocityMultiplier = .90,
    this.minimumFlingVelocity = 120.0,
    this.maximumFlingVelocity = 6000.0,
    this.maxItemsPerFling = 5,
    this.forceOneItemOnFling = true,
    SpringDescription? snapSpring,
    this.snapTolerance = const Tolerance(distance: .01, velocity: .01),
    this.enableTapToCenter = true,
    this.enableHaptics = false,
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
  final double minScale;
  final double maxScale;
  final double minOpacity;
  final double maxOpacity;
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
  final Duration programmaticScrollDuration;
  final Curve programmaticScrollCurve;
}

abstract final class CenteredCarouselPresets {
  static CenteredCarouselSpec timeRail({required double itemExtent}) {
    return CenteredCarouselSpec(
      itemExtent: itemExtent,
      minScale: .72,
      maxScale: 1.35,
      minOpacity: .50,
      maxOpacity: 1.0,
      influenceRadiusItems: 3.5,
      frictionDrag: .135,
      velocityMultiplier: .90,
      minimumFlingVelocity: 120,
      maximumFlingVelocity: 6000,
      maxItemsPerFling: 5,
      forceOneItemOnFling: true,
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
      minOpacity: .45,
      maxOpacity: 1.0,
      influenceRadiusItems: 2.8,
      frictionDrag: .135,
      velocityMultiplier: .82,
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
