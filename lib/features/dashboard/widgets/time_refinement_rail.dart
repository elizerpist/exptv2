import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';

/// Dashboard adapter for the generic centered motion engine.
class TimeRefinementRail extends StatelessWidget {
  const TimeRefinementRail({
    super.key,
    required this.bounds,
    required this.controller,
  });

  final DashboardBounds bounds;
  final CenteredCarouselController controller;

  static const _dataSource = YearCarouselDataSource(anchorYear: 2028);

  @override
  Widget build(BuildContext context) {
    final tileWidth = AppSelectorMetrics.compactTileWidthForViewport(
      bounds.width,
    );
    final itemExtent = tileWidth + AppSelectorMetrics.carouselGap;

    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: CenteredCarousel<String>(
        key: const ValueKey('dashboard-time-rail'),
        dataSource: _StringYearDataSource(_dataSource),
        controller: controller,
        spec: CenteredCarouselPresets.timeRail(
          itemExtent: itemExtent,
          viewportTrailingGap: AppSelectorMetrics.carouselGap,
          selectorHeight: AppSelectorMetrics.compactTileHeight,
          selectorRadius: AppSelectorMetrics.compactTileRadius,
        ),
        height: bounds.height,
        semanticsLabelBuilder: (label) => 'Év $label',
        itemBuilder: (context, label, metrics) {
          return SizedBox(
            width: tileWidth,
            height: AppSelectorMetrics.compactTileHeight,
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
              borderRadius: BorderRadius.circular(
                AppSelectorMetrics.compactTileRadius,
              ),
              child: Center(
                child: Text(
                  label,
                  style: metrics.isSelected
                      ? FluviVisualTokens.railActiveTextStyle
                      : FluviVisualTokens.railTextStyle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StringYearDataSource implements CenteredCarouselDataSource<String> {
  const _StringYearDataSource(this.source);

  final YearCarouselDataSource source;

  @override
  CenteredCarouselDataMode get mode => source.mode;

  @override
  int? get finiteLength => source.finiteLength;

  @override
  String itemAtLogicalIndex(int logicalIndex) =>
      source.itemAtLogicalIndex(logicalIndex).toString();
}
