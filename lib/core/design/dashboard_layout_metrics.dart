import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Shared logical dimensions for the dashboard reference canvas.
@immutable
class DashboardLayoutMetrics {
  const DashboardLayoutMetrics({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.contentGutter,
    required this.contentWidth,
    required this.brandLockupLeft,
    required this.brandLockupTop,
    required this.brandLockupWidth,
    required this.brandLockupHeight,
    required this.headerTop,
    required this.headerExpandedHeight,
    required this.headerCollapsedHeight,
    required this.standardGap,
    required this.subheaderOneHeight,
    required this.zone2CardHeight,
    required this.dotGap,
    required this.dotHeight,
    required this.actionHeight,
    required this.summaryHeight,
    required this.searchHeight,
    required this.railHeight,
    required this.handleHeight,
    required this.collapseTravel,
    this.viewportVerticalDragToControllerScale = 1,
  });

  static const reference = DashboardLayoutMetrics(
    canvasWidth: 412,
    canvasHeight: 892,
    contentGutter: 17,
    contentWidth: 378,
    brandLockupLeft: 28,
    brandLockupTop: 52,
    brandLockupWidth: 252,
    brandLockupHeight: 42,
    headerTop: 104,
    headerExpandedHeight: 126,
    headerCollapsedHeight: 104,
    standardGap: 11,
    subheaderOneHeight: 72,
    zone2CardHeight: 208,
    dotGap: 4,
    dotHeight: 6,
    actionHeight: 52,
    summaryHeight: 59,
    searchHeight: 39,
    railHeight: 37,
    handleHeight: 20,
    collapseTravel: 180,
    viewportVerticalDragToControllerScale: 1,
  );

  final double canvasWidth;
  final double canvasHeight;
  final double contentGutter;
  final double contentWidth;
  final double brandLockupLeft;
  final double brandLockupTop;
  final double brandLockupWidth;
  final double brandLockupHeight;
  final double headerTop;
  final double headerExpandedHeight;
  final double headerCollapsedHeight;
  final double standardGap;
  final double subheaderOneHeight;
  final double zone2CardHeight;
  final double dotGap;
  final double dotHeight;
  final double actionHeight;
  final double summaryHeight;
  final double searchHeight;
  final double railHeight;
  final double handleHeight;
  final double collapseTravel;

  /// Converts a physical viewport vertical drag into controller coordinates.
  ///
  /// The controller stays in the reference metric coordinate system while the
  /// renderer can scale to a smaller viewport.
  final double viewportVerticalDragToControllerScale;

  double get subheaderOneTop => headerTop + headerExpandedHeight + standardGap;
  double get zone2Top => subheaderOneTop + subheaderOneHeight + standardGap;
  double get actionTop =>
      zone2Top + zone2CardHeight + dotGap + dotHeight + standardGap;
  double get summaryTop => actionTop + actionHeight + standardGap;
  double get searchTop => summaryTop + summaryHeight + standardGap;
  double get railTop => searchTop + searchHeight + standardGap;
  double get zone2IndicatorTop => zone2Top + zone2CardHeight + dotGap;

  /// Returns the same geometry with the native status/design origin removed.
  ///
  /// The web viewport starts below the Android status bar, so web rendering
  /// supplies its own 20px design inset before this content-origin geometry.
  DashboardLayoutMetrics get forWebContentOrigin {
    final origin = brandLockupTop;
    return copyWith(brandLockupTop: 0, headerTop: headerTop - origin);
  }

  /// Fits the reference geometry to a viewport while retaining one resolver.
  DashboardLayoutMetrics fitToViewport(Size viewport) {
    if (viewport.isEmpty) return this;
    final scale = math.min(
      viewport.width / canvasWidth,
      viewport.height / canvasHeight,
    );
    final horizontalInset = (viewport.width - canvasWidth * scale) / 2;
    return copyWith(
      canvasWidth: viewport.width,
      canvasHeight: viewport.height,
      contentGutter: horizontalInset + contentGutter * scale,
      contentWidth: contentWidth * scale,
      brandLockupLeft: horizontalInset + brandLockupLeft * scale,
      brandLockupTop: brandLockupTop * scale,
      brandLockupWidth: brandLockupWidth * scale,
      brandLockupHeight: brandLockupHeight * scale,
      headerTop: headerTop * scale,
      headerExpandedHeight: headerExpandedHeight * scale,
      headerCollapsedHeight: headerCollapsedHeight * scale,
      standardGap: standardGap * scale,
      subheaderOneHeight: subheaderOneHeight * scale,
      zone2CardHeight: zone2CardHeight * scale,
      dotGap: dotGap * scale,
      dotHeight: dotHeight * scale,
      actionHeight: actionHeight * scale,
      summaryHeight: summaryHeight * scale,
      searchHeight: searchHeight * scale,
      railHeight: railHeight * scale,
      handleHeight: handleHeight * scale,
      collapseTravel: collapseTravel * scale,
      viewportVerticalDragToControllerScale:
          viewportVerticalDragToControllerScale / scale,
    );
  }

  DashboardLayoutMetrics copyWith({
    double? canvasWidth,
    double? canvasHeight,
    double? contentGutter,
    double? contentWidth,
    double? brandLockupLeft,
    double? brandLockupTop,
    double? brandLockupWidth,
    double? brandLockupHeight,
    double? headerTop,
    double? headerExpandedHeight,
    double? headerCollapsedHeight,
    double? standardGap,
    double? subheaderOneHeight,
    double? zone2CardHeight,
    double? dotGap,
    double? dotHeight,
    double? actionHeight,
    double? summaryHeight,
    double? searchHeight,
    double? railHeight,
    double? handleHeight,
    double? collapseTravel,
    double? viewportVerticalDragToControllerScale,
  }) {
    return DashboardLayoutMetrics(
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      contentGutter: contentGutter ?? this.contentGutter,
      contentWidth: contentWidth ?? this.contentWidth,
      brandLockupLeft: brandLockupLeft ?? this.brandLockupLeft,
      brandLockupTop: brandLockupTop ?? this.brandLockupTop,
      brandLockupWidth: brandLockupWidth ?? this.brandLockupWidth,
      brandLockupHeight: brandLockupHeight ?? this.brandLockupHeight,
      headerTop: headerTop ?? this.headerTop,
      headerExpandedHeight: headerExpandedHeight ?? this.headerExpandedHeight,
      headerCollapsedHeight:
          headerCollapsedHeight ?? this.headerCollapsedHeight,
      standardGap: standardGap ?? this.standardGap,
      subheaderOneHeight: subheaderOneHeight ?? this.subheaderOneHeight,
      zone2CardHeight: zone2CardHeight ?? this.zone2CardHeight,
      dotGap: dotGap ?? this.dotGap,
      dotHeight: dotHeight ?? this.dotHeight,
      actionHeight: actionHeight ?? this.actionHeight,
      summaryHeight: summaryHeight ?? this.summaryHeight,
      searchHeight: searchHeight ?? this.searchHeight,
      railHeight: railHeight ?? this.railHeight,
      handleHeight: handleHeight ?? this.handleHeight,
      collapseTravel: collapseTravel ?? this.collapseTravel,
      viewportVerticalDragToControllerScale:
          viewportVerticalDragToControllerScale ??
          this.viewportVerticalDragToControllerScale,
    );
  }
}
