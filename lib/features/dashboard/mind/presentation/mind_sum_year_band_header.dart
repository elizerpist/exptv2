import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../domain/mind_temporal_heatmap_projection.dart';

/// Format an already-admitted annual total for the compact Sum band header.
/// This is formatting only; the immutable frame remains the financial owner.
String formatMindCompactForints(
  int forints, {
  bool includeCurrencySuffix = true,
}) => DashboardPreparedFormatter.compactForints(
  forints,
  includeCurrencySuffix: includeCurrencySuffix,
);

/// Shared one-row total header for Mind temporal scopes. It owns geometry and
/// visual hierarchy only; its caller remains the authority for the admitted
/// total string. This keeps Month aligned with annual Sum without introducing
/// a second aggregation or formatter path.
final class MindSumScopeTotalHeader extends StatelessWidget {
  const MindSumScopeTotalHeader({
    super.key,
    required this.label,
    required this.amount,
    required this.surface,
    this.labelKey,
    this.amountKey,
    this.amountCompatibilityKey,
  });

  static const height = 18.0;

  final String label;
  final String amount;
  final String surface;
  final Key? labelKey;
  final Key? amountKey;
  final Key? amountCompatibilityKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey<String>('mind-sum-$surface-total-header'),
    height: height,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              key: labelKey,
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
              key: amountCompatibilityKey,
              child: Text(
                amount,
                key: amountKey,
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
  Widget build(BuildContext context) => MindSumScopeTotalHeader(
    key: ValueKey<String>('mind-sum-$surface-year-header-$year'),
    label: '$year',
    amount: formatMindCompactForints(frame.yearTotal(year) ~/ 100),
    surface: surface,
    labelKey: ValueKey<String>('mind-sum-$surface-year-label-$year'),
    amountKey: ValueKey<String>('mind-sum-$surface-year-total-$year'),
    amountCompatibilityKey: surface == 'heatmap'
        ? ValueKey<String>('mind-sum-heatmap-total-$year')
        : null,
  );
}
