import 'package:flutter/foundation.dart';

/// Shared logical dimensions for the dashboard reference canvas.
@immutable
class DashboardLayoutMetrics {
  const DashboardLayoutMetrics({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.contentGutter,
    required this.contentWidth,
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
  });

  static const reference = DashboardLayoutMetrics(
    canvasWidth: 412,
    canvasHeight: 892,
    contentGutter: 17,
    contentWidth: 378,
    headerTop: 104,
    headerExpandedHeight: 126,
    headerCollapsedHeight: 104,
    standardGap: 11,
    subheaderOneHeight: 72,
    zone2CardHeight: 208,
    dotGap: 4,
    dotHeight: 6,
    actionHeight: 42,
    summaryHeight: 59,
    searchHeight: 39,
    railHeight: 37,
    handleHeight: 20,
    collapseTravel: 180,
  );

  final double canvasWidth;
  final double canvasHeight;
  final double contentGutter;
  final double contentWidth;
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

  double get subheaderOneTop =>
      headerTop + headerExpandedHeight + standardGap;
  double get zone2Top => subheaderOneTop + subheaderOneHeight + standardGap;
  double get actionTop =>
      zone2Top + zone2CardHeight + dotGap + dotHeight + standardGap;
  double get summaryTop => actionTop + actionHeight + standardGap;
  double get searchTop => summaryTop + summaryHeight + standardGap;
  double get railTop => searchTop + searchHeight + standardGap;

  DashboardLayoutMetrics copyWith({
    double? canvasWidth,
    double? canvasHeight,
    double? contentGutter,
    double? contentWidth,
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
  }) {
    return DashboardLayoutMetrics(
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      contentGutter: contentGutter ?? this.contentGutter,
      contentWidth: contentWidth ?? this.contentWidth,
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
    );
  }
}
