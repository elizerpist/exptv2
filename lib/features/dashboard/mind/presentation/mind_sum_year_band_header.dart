import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';

/// Format an already-admitted annual total for the compact Sum band header.
/// This is formatting only; the immutable frame remains the financial owner.
String formatMindCompactForints(int forints) =>
    DashboardPreparedFormatter.compactForints(forints);

/// Shared visual header for every annually stacked Sum renderer. Detailed
/// lines and monthly overlay bars therefore share year placement, typography,
/// compact formatting and the same admitted yearly-total authority.
final class MindSumYearBandHeader extends StatelessWidget {
  const MindSumYearBandHeader({
    super.key,
    required this.frame,
    required this.year,
    required this.surface,
    this.visualStyle = MindSumVisualStyle.current,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final String surface;
  final MindSumVisualStyle visualStyle;

  @override
  Widget build(BuildContext context) => visualStyle == MindSumVisualStyle.sumB
      ? _SumBYearCard(frame: frame, year: year, surface: surface)
      : SizedBox(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: KeyedSubtree(
                    key: surface == 'heatmap'
                        ? ValueKey<String>('mind-sum-heatmap-total-$year')
                        : null,
                    child: Text(
                      formatMindCompactForints(frame.yearTotal(year) ~/ 100),
                      key: ValueKey<String>(
                        'mind-sum-$surface-year-total-$year',
                      ),
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

/// SUM-B's annual identity is intentionally a separate raised surface while
/// month tiles continue to use the existing SUM-A/current grammar.
final class _SumBYearCard extends StatelessWidget {
  const _SumBYearCard({
    required this.frame,
    required this.year,
    required this.surface,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final String surface;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey<String>('mind-sum-b-year-card-$year'),
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xfffaffff), Color(0xffe6f3f2)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x337d9faf)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x2b6f8a98),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
        BoxShadow(
          color: Color(0x99ffffff),
          blurRadius: 2,
          offset: Offset(-1, -1),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Text(
          '$year',
          key: ValueKey<String>('mind-sum-$surface-year-label-$year'),
          style: const TextStyle(
            color: Color(0xff465d75),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const Icon(Icons.bar_chart_rounded, size: 15, color: Color(0xff6d9d9b)),
        const SizedBox(width: 5),
        Text(
          formatMindCompactForints(frame.yearTotal(year) ~/ 100),
          key: ValueKey<String>('mind-sum-$surface-year-total-$year'),
          style: const TextStyle(
            color: Color(0xff355467),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
