import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../domain/mind_temporal_heatmap_projection.dart';

/// Format an already-admitted annual total for the compact Sum band header.
/// This is formatting only; the immutable frame remains the financial owner.
String formatMindCompactForints(int forints) {
  final absolute = forints.abs();
  final sign = forints < 0 ? '-' : '';
  if (absolute >= 1000000) {
    final millions = (absolute / 1000000)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    return '$sign$millions M Ft';
  }
  if (absolute >= 1000) return '$sign${(absolute / 1000).round()} k Ft';
  return '$forints Ft';
}

/// Shared visual header for every annually stacked Sum renderer. Detailed
/// lines and monthly overlay bars therefore share year placement, typography,
/// compact formatting and the same admitted yearly-total authority.
final class MindSumYearBandHeader extends StatelessWidget {
  const MindSumYearBandHeader({
    super.key,
    required this.frame,
    required this.year,
    required this.surface,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final String surface;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey<String>('mind-sum-$surface-year-header-$year'),
    height: 18,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$year',
              key: ValueKey<String>('mind-sum-$surface-year-label-$year'),
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: KeyedSubtree(
              key: surface == 'heatmap'
                  ? ValueKey<String>('mind-sum-heatmap-total-$year')
                  : null,
              child: Text(
                formatMindCompactForints(frame.yearTotal(year) ~/ 100),
                key: ValueKey<String>('mind-sum-$surface-year-total-$year'),
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
