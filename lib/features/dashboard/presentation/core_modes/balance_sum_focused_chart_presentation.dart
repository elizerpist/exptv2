import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_monthly_net_distribution_projection.dart';
import '../../application/dashboard_balance_retention_stability_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_alternative_scope_presentation.dart';

/// A formatting-only view of SUM's existing prepared financial projections.
/// Renderers share the exact histogram and stability band; no sample is rebuilt.
@immutable
final class BalanceSumFocusedChartPresentation {
  BalanceSumFocusedChartPresentation._({
    required this.sourcePresentationId,
    required this.histogram,
    required this.histogramMaximumCount,
    required this.cashflowBand,
    required this.stability,
    required this.longestPositiveStreak,
    required this.savings,
    required this.positiveRatio,
    required this.medianLabel,
    required this.histogramMinimumLabel,
    required this.histogramMaximumLabel,
    required this.stabilityMinimumLabel,
    required this.stabilityMaximumLabel,
    required this.typicalIntervalLabel,
    required this.stabilityDeviationLabel,
    required this.stabilityRangeLabel,
    required this.positiveRatioLabel,
    required this.streakLabel,
    required this.savingsLabel,
    required this.savingsRetentionLabel,
    required List<String> distributionStats,
    required List<String> positiveRatioStats,
    required List<String> stabilityStats,
  }) : distributionStats = List<String>.unmodifiable(distributionStats),
       positiveRatioStats = List<String>.unmodifiable(positiveRatioStats),
       stabilityStats = List<String>.unmodifiable(stabilityStats);

  factory BalanceSumFocusedChartPresentation.fromScope(
    BalanceAlternativeSumPresentation source,
  ) {
    final histogram = source.distribution.histogram;
    final stability = source.stability;
    final sampleCount = histogram.sampleCount;
    final ratio = sampleCount == 0
        ? null
        : histogram.positiveObservationCount / sampleCount;
    final median = sampleCount == 0
        ? '—'
        : _signedCompactMinor(histogram.medianMinor.round());
    final typical =
        histogram.typicalLowerMinor == null ||
            histogram.typicalUpperMinor == null ||
            sampleCount == 0
        ? '—'
        : '${_signedCompactMinor(histogram.typicalLowerMinor!.round())} – '
              '${_signedCompactMinor(histogram.typicalUpperMinor!.round())}';
    final deviation = !stability.isAvailable
        ? '—'
        : '±${_compactTimesTwo(stability.typicalDeviationTimesTwo!)}/hó';
    final stabilityRange = !stability.isAvailable
        ? '—'
        : '${_signedCompactTimesTwo(stability.typicalBandLowerTimesTwo!)} – '
              '${_signedCompactTimesTwo(stability.typicalBandUpperTimesTwo!)}';
    final ratioLabel = ratio == null ? '—' : '${(ratio * 100).round()}%';
    final streakLabel = sampleCount == 0
        ? '—'
        : '${source.distribution.longestPositiveStreak.length} hónap';
    final savingsLabel = _signedCompactMinor(source.savings.netMinor);
    final retention = source.savings.retentionBasisPoints;
    final savingsRetentionLabel = retention == null
        ? '—'
        : '${(retention / 100).toStringAsFixed(1).replaceAll('.', ',')}%';
    final countLabel = '$sampleCount lezárt hónap';
    return BalanceSumFocusedChartPresentation._(
      sourcePresentationId: source.sourcePresentationId,
      histogram: histogram,
      histogramMaximumCount: histogram.bins.fold<int>(
        1,
        (maximum, bin) => bin.count > maximum ? bin.count : maximum,
      ),
      cashflowBand: source.distribution.cashflowBand,
      stability: stability,
      longestPositiveStreak: source.distribution.longestPositiveStreak,
      savings: source.savings,
      positiveRatio: ratio,
      medianLabel: median,
      histogramMinimumLabel: sampleCount == 0
          ? '—'
          : _signedCompactMinor(histogram.minimumObservedMinor.round()),
      histogramMaximumLabel: sampleCount == 0
          ? '—'
          : _signedCompactMinor(histogram.maximumObservedMinor.round()),
      stabilityMinimumLabel: source.distribution.cashflowBand.sampleCount == 0
          ? '—'
          : _signedCompactTimesTwo(
              source.distribution.cashflowBand.axisMinimumTimesTwo,
            ),
      stabilityMaximumLabel: source.distribution.cashflowBand.sampleCount == 0
          ? '—'
          : _signedCompactTimesTwo(
              source.distribution.cashflowBand.axisMaximumTimesTwo,
            ),
      typicalIntervalLabel: typical,
      stabilityDeviationLabel: deviation,
      stabilityRangeLabel: stabilityRange,
      positiveRatioLabel: ratioLabel,
      streakLabel: streakLabel,
      savingsLabel: savingsLabel,
      savingsRetentionLabel: savingsRetentionLabel,
      distributionStats: [
        'Medián: $median',
        'Jellemző sáv: $typical',
        'Negatív: ${histogram.negativeObservationCount} · Nulla: ${sampleCount - histogram.positiveObservationCount - histogram.negativeObservationCount} · Pozitív: ${histogram.positiveObservationCount}',
      ],
      positiveRatioStats: [
        '${histogram.positiveObservationCount} / $sampleCount pozitív hónap',
        'Leghosszabb sorozat: $streakLabel',
        'Megtakarítási arány: $savingsRetentionLabel',
      ],
      stabilityStats: [
        'Tipikus eltérés: $deviation',
        'Jellemző sáv: $stabilityRange',
        countLabel,
      ],
    );
  }

  final int sourcePresentationId;
  final DashboardBalanceMonthlyNetHistogramPresentation histogram;
  final int histogramMaximumCount;
  final DashboardBalanceCashflowStabilityBandPresentation cashflowBand;
  final DashboardBalanceStabilityPresentation stability;
  final DashboardBalancePositiveStreakPresentation longestPositiveStreak;
  final BalanceAlternativeSavingsPresentation savings;
  int get sampleCount => histogram.sampleCount;
  int get positiveCount => histogram.positiveObservationCount;
  int get positiveObservationCount => positiveCount;
  int get negativeCount => histogram.negativeObservationCount;
  int get negativeObservationCount => negativeCount;
  int get zeroCount => sampleCount - positiveCount - negativeCount;
  final double? positiveRatio;
  final String medianLabel;
  final String histogramMinimumLabel;
  final String histogramMaximumLabel;
  final String stabilityMinimumLabel;
  final String stabilityMaximumLabel;
  final String typicalIntervalLabel;
  final String stabilityDeviationLabel;
  final String stabilityRangeLabel;
  final String positiveRatioLabel;
  final String streakLabel;
  final String savingsLabel;
  final String savingsRetentionLabel;
  final List<String> distributionStats;
  final List<String> positiveRatioStats;
  final List<String> stabilityStats;
}

String _compactTimesTwo(int value) =>
    DashboardPreparedFormatter.compactAmountMinor((value / 2).round());
String _signedCompactTimesTwo(int value) =>
    _signedCompactMinor((value / 2).round());
String _signedCompactMinor(int value) {
  final formatted = DashboardPreparedFormatter.compactAmountMinor(value);
  return value > 0 ? '+$formatted' : formatted;
}
