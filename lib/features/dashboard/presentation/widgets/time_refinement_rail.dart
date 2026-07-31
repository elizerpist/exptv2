import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// The only leaf that owns scrolling: static, horizontal time refinement pills.
class TimeRefinementRail extends StatelessWidget {
  const TimeRefinementRail({super.key, required this.bounds});

  final DashboardBounds bounds;

  static const _labels = ['2021', '2022', '2023', '2024', '2025'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: SingleChildScrollView(
        key: const ValueKey('dashboard-time-rail'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final label in _labels) ...[
              _TimePill(label: label, selected: label == '2024'),
              if (label != _labels.last)
                const SizedBox(width: FluviVisualTokens.railPillGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? FluviVisualTokens.railActiveSurface
        : FluviVisualTokens.surface;
    final textColor = selected
        ? FluviVisualTokens.railActiveText
        : FluviVisualTokens.textPrimary;
    return DecoratedBox(
      key: const ValueKey('fluvi-time-pill'),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: FluviVisualTokens.border),
        borderRadius: FluviVisualTokens.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FluviVisualTokens.pillHorizontalInset,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: FluviVisualTokens.bodyFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
