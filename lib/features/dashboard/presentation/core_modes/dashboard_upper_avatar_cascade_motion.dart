import 'dart:math' as math;

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/header_cascade_motion.dart';

/// Presentation-only retiming for the upper avatar/perspective lane.
///
/// The shared Header cascade remains the geometry authority for the physical
/// Mother Card and lower analytical content. This adapter samples that same
/// master progress with a slower collapse separation for just the visual upper
/// lane: `f(s) = s³`, where `s` is normalized separation. It preserves
/// both endpoints while holding the avatar row in its readable region longer.
final class DashboardUpperAvatarCascadeMotion {
  const DashboardUpperAvatarCascadeMotion._();

  static const double separationExponent = 3;

  static double retimedSeparation(double separation) {
    final bounded = separation.clamp(0.0, 1.0).toDouble();
    if (bounded == 0 || bounded == 1) return bounded;
    return math.pow(bounded, separationExponent).toDouble();
  }

  static double expansionFor(DashboardLayoutFrame frame) =>
      1 - retimedSeparation(1 - frame.headerExpansionProgress);

  /// Resolves only the visual upper geometry. The source [DashboardLayoutFrame]
  /// and its lower cascade are never modified or fed back into layout.
  static CascadedCardMotion resolve(DashboardLayoutFrame frame) =>
      HeaderCascadeMotion.calculate(
        masterProgress: expansionFor(frame),
        geometry: frame.motherCardCascadeGeometry,
      ).upper;
}
