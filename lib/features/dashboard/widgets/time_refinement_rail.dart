import 'package:flutter/material.dart';

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

  static const _labels = [
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
  ];
  static const _itemCount = 41;

  List<String> get _items => List<String>.generate(
    _itemCount,
    (index) => _labels[index % _labels.length],
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: CenteredCarousel<String>(
        key: const ValueKey('dashboard-time-rail'),
        items: _items,
        controller: controller,
        spec: CenteredCarouselPresets.timeRail(
          itemExtent: FluviVisualTokens.railItemExtent,
        ),
        height: bounds.height,
        semanticsLabelBuilder: (label) => 'Év $label',
        itemBuilder: (context, label, metrics) {
          return SizedBox(
            width: FluviVisualTokens.railVisualWidth,
            height: bounds.height,
            child: FluviRoundedBox(
              key: const ValueKey('fluvi-time-box'),
              color: metrics.isSelected ? null : FluviVisualTokens.surface,
              gradient: metrics.isSelected
                  ? FluviVisualTokens.appHighlightGradient
                  : null,
              border: metrics.isSelected
                  ? null
                  : const Border.fromBorderSide(
                      BorderSide(color: FluviVisualTokens.border),
                    ),
              boxShadow: metrics.isSelected
                  ? const [FluviVisualTokens.appHighlightShadow]
                  : null,
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
