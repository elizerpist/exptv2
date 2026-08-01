import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/presentation/time_label_formatter.dart';

/// Dashboard adapter for the generic centered motion engine.
class TimeRefinementRail extends StatelessWidget {
  const TimeRefinementRail({
    super.key,
    required this.bounds,
    required this.controller,
  });

  final DashboardBounds bounds;
  final DashboardTimeNavigationController controller;

  @override
  Widget build(BuildContext context) {
    final tileWidth = AppSelectorMetrics.compactTileWidthForViewport(
      bounds.width,
    );
    final itemExtent = tileWidth + AppSelectorMetrics.carouselGap;
    final plane = controller.state.plane;

    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: CenteredCarousel<int>(
        key: const ValueKey('dashboard-time-rail'),
        dataSource: controller.childDataSource,
        controller: controller.timeCarousel,
        spec: CenteredCarouselPresets.timeRail(
          itemExtent: itemExtent,
          viewportTrailingGap: AppSelectorMetrics.carouselGap,
          selectorHeight: AppSelectorMetrics.yearTileHeight,
          selectorRadius: AppSelectorMetrics.compactTileRadius,
        ),
        height: bounds.height,
        semanticsLabelBuilder: (value) => _semanticsLabel(plane, value),
        onPreviewChanged: controller.previewChildLogicalIndex,
        onSelectionSettled: controller.settleChildLogicalIndex,
        itemBuilder: (context, label, metrics) {
          return SizedBox(
            width: tileWidth,
            height: AppSelectorMetrics.yearTileHeight,
            child: FluviRoundedBox(
              key: const ValueKey('fluvi-time-box'),
              color: metrics.isSelected ? null : FluviVisualTokens.surface,
              gradient: metrics.isSelected
                  ? FluviVisualTokens.appHighlightGradient
                  : null,
              border: metrics.isSelected
                  ? null
                  : const Border.fromBorderSide(
                      BorderSide(
                        color: FluviVisualTokens.border,
                        width: B3mReferenceMetrics.borderWidth,
                      ),
                    ),
              // The rail is transparent and its tiles sit directly on the
              // dashboard background. A card shadow here would be clipped by
              // the horizontal carousel viewport and create a false window
              // edge around the rail.
              boxShadow: const [],
              borderRadius: BorderRadius.circular(
                AppSelectorMetrics.compactTileRadius,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: tileWidth - 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        TimeRailLabelFormatter.labelFor(plane, label),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        style: metrics.isSelected
                            ? FluviVisualTokens.railActiveTextStyle
                            : FluviVisualTokens.railTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

abstract final class TimeRailLabelFormatter {
  static String labelFor(TimePlane plane, int value) => switch (plane) {
    TimePlane.sum => value.toString(),
    TimePlane.year => DashboardTimeLabelFormatter.monthName(value),
    TimePlane.month => value.toString(),
  };

  static String monthName(int month) =>
      DashboardTimeLabelFormatter.monthName(month);
}

String _semanticsLabel(TimePlane plane, int value) => switch (plane) {
  TimePlane.sum => 'Év $value',
  TimePlane.year => 'Hónap ${DashboardTimeLabelFormatter.monthName(value)}',
  TimePlane.month => 'Nap $value',
};
