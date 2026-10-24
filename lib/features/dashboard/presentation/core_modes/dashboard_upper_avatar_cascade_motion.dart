import 'dart:math' as math;

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/header_cascade_motion.dart';

/// Presentation-only retiming for the upper avatar/perspective lane.
///
/// The shared Header cascade remains the geometry authority for the physical
/// Mother Card and lower analytical content. This adapter samples that same
/// master progress with a slower collapse separation for just the visual upper
/// lane: `f(s) = a*s + (1-a)*s³`, where `s` is normalized separation. The
/// positive linear component starts position, scale and opacity motion on the
/// first fractional swipe frame, while the cubic component keeps the lane
/// slower than the lower analytical cascade.
final class DashboardUpperAvatarCascadeMotion {
  const DashboardUpperAvatarCascadeMotion._();

  /// `f'(0)`. Keep this positive: a pure cubic creates a perceptible initial
  /// hold even though it is mathematically continuous.
  static const double initialSlope = .30;

  static double retimedSeparation(double separation) {
    final bounded = separation.clamp(0.0, 1.0).toDouble();
    if (bounded == 0 || bounded == 1) return bounded;
    final cubic = math.pow(bounded, 3).toDouble();
    return initialSlope * bounded + (1 - initialSlope) * cubic;
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
