/// Shared dimensions for every elongated selector/control surface.
abstract final class AppRadii {
  static const double selector = 18.0;
  static const double control = 18.0;
  static const double card = 22.0;
  static const double small = 12.0;
  /// Shared outer shape for one joined, day-grouped dashboard LogBox surface.
  static const double logGroup = 18.0;
}

/// Geometry copied from the Balance B3M time-scope year chip.
///
/// Source: `balance_latest_layout.html`,
/// `.stage2-redesign-time-scope-year-rail` and
/// `.stage2-redesign-time-scope-year-pill`.
abstract final class B3mReferenceMetrics {
  static const double compactTileHeight = 37.0;
  static const double compactTileRadius = 14.0;
  static const double carouselGap = 8.0;
  static const double horizontalPadding = 4.0;
  static const double verticalPadding = 0.0;
  static const double borderWidth = 1.0;
  static const double inactiveFontSize = 11.0;
  static const double activeFontSize = 15.0;

  /// The Fluvi reference content width is 378px. The HTML source expresses
  /// the same width responsively as `(100% - 32px) / 5` with four 8px gaps.
  static const double referenceContentWidth = 378.0;
  static const double referenceCompactTileWidth =
      (referenceContentWidth - (4 * carouselGap)) / 5;
  static const double referenceItemExtent =
      referenceCompactTileWidth + carouselGap;

  static double compactTileWidthForViewport(double viewportWidth) {
    final availableWidth = viewportWidth - (4 * carouselGap);
    return availableWidth <= 0 ? 0 : availableWidth / 5;
  }

  static double itemExtentForViewport(double viewportWidth) {
    return compactTileWidthForViewport(viewportWidth) + carouselGap;
  }
}

/// Shared selector dimensions. The selector token owns the geometry; control
/// aliases below keep existing dashboard callers source-compatible.
abstract final class AppSelectorMetrics {
  static const double compactTileHeight = B3mReferenceMetrics.compactTileHeight;
  static const double yearTileHeight = compactTileHeight * .9;
  // Transaction-direction controls are restored to the 1.20x control height;
  // the year tile remains independently reduced to 90% of the B3M base.
  static const double directionControlHeight = compactTileHeight * 1.20;
  static const double compactTileRadius = B3mReferenceMetrics.compactTileRadius;
  static const double compactTileWidth =
      B3mReferenceMetrics.referenceCompactTileWidth;
  static const double carouselGap = B3mReferenceMetrics.carouselGap;
  static const double itemExtent = B3mReferenceMetrics.referenceItemExtent;

  static double compactTileWidthForViewport(double viewportWidth) {
    return B3mReferenceMetrics.compactTileWidthForViewport(viewportWidth);
  }

  static double itemExtentForViewport(double viewportWidth) {
    return B3mReferenceMetrics.itemExtentForViewport(viewportWidth);
  }
}

/// Compatibility aliases for existing controls and dashboard layout metrics.
abstract final class AppControlMetrics {
  static const double compactTileHeight = AppSelectorMetrics.compactTileHeight;
  static const double compactTileRadius = AppSelectorMetrics.compactTileRadius;
  static const double selectorHeight = compactTileHeight;
  static const double selectorRadius = compactTileRadius;
  static const double carouselViewportHeight = 52.0;
}
