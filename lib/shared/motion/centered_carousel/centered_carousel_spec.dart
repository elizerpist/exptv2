import 'dart:ui' show Clip;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// The physical contract for every centered carousel consumer.
///
/// Layout/emphasis values intentionally live in [CenteredCarouselSpec].  A
/// second renderer may therefore share a rail's drag, fling and snap behavior
/// without inheriting its tile geometry.
@immutable
class CenteredCarouselMotionProfile {
  const CenteredCarouselMotionProfile({
    required this.frictionDrag,
    required this.velocityMultiplier,
    required this.minimumFlingVelocity,
    required this.maximumFlingVelocity,
    required this.maxItemsPerFling,
    required this.forceOneItemOnFling,
    required this.snapSpring,
    required this.snapTolerance,
  });

  final double frictionDrag;
  final double velocityMultiplier;
  final double minimumFlingVelocity;
  final double maximumFlingVelocity;
  final int maxItemsPerFling;
  final bool forceOneItemOnFling;
  final SpringDescription snapSpring;
  final Tolerance snapTolerance;
}

/// The one physical source of truth for named centered-carousel interactions.
abstract final class CenteredCarouselMotionProfiles {
  static final CenteredCarouselMotionProfile timeRefinementRail =
      CenteredCarouselMotionProfile(
        frictionDrag: .135,
        velocityMultiplier: .66,
        minimumFlingVelocity: 140,
        maximumFlingVelocity: 5200,
        maxItemsPerFling: 5,
        forceOneItemOnFling: true,
        snapSpring: SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: 420,
          ratio: 1,
        ),
        snapTolerance: const Tolerance(distance: .01, velocity: .01),
      );

  /// Kept for the existing generic profile adapter. New Budget avatars must
  /// select [timeRefinementRail] instead of this visually named legacy
  /// profile, whose physics deliberately differs.
  static final CenteredCarouselMotionProfile legacyAvatar =
      CenteredCarouselMotionProfile(
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
        snapTolerance: const Tolerance(distance: .01, velocity: .01),
      );
}

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
    CenteredCarouselMotionProfile? motionProfile,
    this.enableTapToCenter = true,
    this.enableHaptics = false,
    this.hapticThrottle = const Duration(milliseconds: 38),
    this.programmaticScrollDuration = defaultProgrammaticScrollDuration,
    this.programmaticScrollCurve = defaultProgrammaticScrollCurve,
    this.clipBehavior = Clip.hardEdge,
  }) : motionProfile =
           motionProfile ?? CenteredCarouselMotionProfiles.timeRefinementRail;

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
  final CenteredCarouselMotionProfile motionProfile;
  final bool enableTapToCenter;
  final bool enableHaptics;
  final Duration hapticThrottle;
  final Duration programmaticScrollDuration;
  final Curve programmaticScrollCurve;
  final Clip clipBehavior;

  double get frictionDrag => motionProfile.frictionDrag;
  double get velocityMultiplier => motionProfile.velocityMultiplier;
  double get minimumFlingVelocity => motionProfile.minimumFlingVelocity;
  double get maximumFlingVelocity => motionProfile.maximumFlingVelocity;
  int get maxItemsPerFling => motionProfile.maxItemsPerFling;
  bool get forceOneItemOnFling => motionProfile.forceOneItemOnFling;
  SpringDescription get snapSpring => motionProfile.snapSpring;
  Tolerance get snapTolerance => motionProfile.snapTolerance;
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
      motionProfile: CenteredCarouselMotionProfiles.timeRefinementRail,
      enableHaptics: true,
      hapticThrottle: const Duration(milliseconds: 38),
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
      motionProfile: CenteredCarouselMotionProfiles.legacyAvatar,
    );
  }

  /// Five-position approved avatar geometry with the exact TimeRefinementRail
  /// motion profile. Its item canvas is 72px, while the reference disc is
  /// authored on a 66px canvas: 59.4px center, 46px inner and 36px outer.
  static CenteredCarouselSpec budgetCategoryAvatarRail({
    required double itemExtent,
  }) {
    return CenteredCarouselSpec(
      itemExtent: itemExtent,
      visibleItemCount: 5,
      selectorHeight: 72,
      minScale: 0,
      maxScale: 59.4 / 66,
      neighborScale: 46 / 66,
      outerScale: 36 / 66,
      minOpacity: 0,
      maxOpacity: 1,
      neighborOpacity: 1,
      outerOpacity: 1,
      influenceRadiusItems: 3,
      motionProfile: CenteredCarouselMotionProfiles.timeRefinementRail,
      enableHaptics: true,
      clipBehavior: Clip.none,
    );
  }
}
