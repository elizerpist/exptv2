/// Shared selector allocation across the focused time scopes.
abstract final class BalanceFocusedLayoutGeometry {
  /// The Day navigator occupies one stable compact bottom lane.
  static double dayMomentumRailHeight(double availableHeight) =>
      (availableHeight * .16).clamp(60.0, 80.0);

  static double topSectionHeight(double availableHeight) =>
      availableHeight * .21;
}
