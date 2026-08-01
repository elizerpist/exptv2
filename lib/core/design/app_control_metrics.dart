/// Shared dimensions for every elongated selector/control surface.
abstract final class AppRadii {
  static const double selector = 18.0;
  static const double control = 18.0;
  static const double card = 22.0;
  static const double small = 12.0;
}

abstract final class AppControlMetrics {
  /// The existing reference action height, promoted so the rail and actions
  /// cannot drift apart while the dashboard geometry remains stable.
  static const double selectorHeight = 52.0;
  static const double selectorRadius = AppRadii.selector;
}
