import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_sum_focused_chart_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

const identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'filtered-history',
  indexGeneration: 7,
  coreRevision: 19,
);
BalanceAlternativeSumPresentation scope(
  List<int> values, {
  int? medianTimesTwo,
  int? deviationTimesTwo,
}) {
  final stability = DashboardBalanceStabilityPresentation(
    identity: identity,
    timeScope: const AllTimeScope(),
    observations: [
      for (var index = 0; index < values.length; index++)
        DashboardBalanceMonthlyNetObservation(
          id: 'month:$index',
          label: '2026-${index + 1}',
          month: YearMonth(year: 2026, month: index + 1),
          incomeMinor: values[index] > 0 ? values[index] : 0,
          expenseMinor: values[index] < 0 ? -values[index] : 0,
        ),
    ],
    medianNetTimesTwo: medianTimesTwo,
    typicalDeviationTimesTwo: deviationTimesTwo,
  );
  return BalanceAlternativeSumPresentation(
    timeScope: const AllTimeScope(),
    sourcePresentationId: 761,
    stability: stability,
    distribution: DashboardBalanceMonthlyNetDistributionProjection.build(
      stability: stability,
    ),
    savings: const BalanceAlternativeSavingsPresentation(
      netMinor: 123456,
      retentionBasisPoints: -123,
    ),
  );
}

void main() {
  test(
    'empty prepared sample has no invented ratio median interval or streak',
    () {
      final chart = BalanceSumFocusedChartPresentation.fromScope(scope([]));
      expect(chart.sampleCount, 0);
      expect(chart.histogramMaximumCount, 1);
      expect(chart.positiveRatio, isNull);
      expect(chart.positiveRatioLabel, '—');
      expect(chart.medianLabel, '—');
      expect(chart.histogramMinimumLabel, '—');
      expect(chart.histogramMaximumLabel, '—');
      expect(chart.stabilityMinimumLabel, '—');
      expect(chart.stabilityMaximumLabel, '—');
      expect(chart.typicalIntervalLabel, '—');
      expect(chart.streakLabel, '—');
      expect(chart.stabilityDeviationLabel, '—');
      expect(chart.stabilityRangeLabel, '—');
      expect(chart.positiveCount, 0);
      expect(chart.negativeCount, 0);
      expect(chart.zeroCount, 0);
    },
  );
  test(
    'partial sample ratio is truthful while stability remains unavailable',
    () {
      final chart = BalanceSumFocusedChartPresentation.fromScope(
        scope([10000]),
      );
      expect(chart.sampleCount, 1);
      expect(chart.positiveCount, 1);
      expect(chart.positiveRatio, 1);
      expect(chart.positiveRatioLabel, '100%');
      expect(chart.medianLabel, '+100 Ft');
      expect(chart.typicalIntervalLabel, '—');
      expect(chart.stabilityDeviationLabel, '—');
      expect(chart.cashflowBand.isAvailable, isFalse);
    },
  );
  test(
    'all positive sample retains exact existing histogram band streak and savings identities',
    () {
      final source = scope(
        [100, 200, 300],
        medianTimesTwo: 400,
        deviationTimesTwo: 200,
      );
      final chart = BalanceSumFocusedChartPresentation.fromScope(source);
      expect(chart.sourcePresentationId, 761);
      expect(identical(chart.histogram, source.distribution.histogram), isTrue);
      expect(
        identical(chart.cashflowBand, source.distribution.cashflowBand),
        isTrue,
      );
      expect(identical(chart.stability, source.stability), isTrue);
      expect(identical(chart.savings, source.savings), isTrue);
      expect(
        identical(
          chart.longestPositiveStreak,
          source.distribution.longestPositiveStreak,
        ),
        isTrue,
      );
      expect(chart.stability.identity, identity);
      expect(chart.positiveRatio, 1);
      expect(chart.positiveCount, 3);
      expect(chart.positiveObservationCount, 3);
      expect(chart.streakLabel, '3 hónap');
      expect(chart.savingsLabel, '+1 k Ft');
      expect(chart.savingsRetentionLabel, '-1,2%');
    },
  );
  test(
    'mixed sample counts and statistics use prepared values without resampling',
    () {
      final source = scope(
        [-10000, 10000, 30000],
        medianTimesTwo: 20000,
        deviationTimesTwo: 40000,
      );
      final chart = BalanceSumFocusedChartPresentation.fromScope(source);
      expect(chart.sampleCount, 3);
      expect(
        chart.histogramMaximumCount,
        chart.histogram.bins
            .map((bin) => bin.count)
            .reduce((a, b) => a > b ? a : b),
      );
      expect(chart.positiveCount, 2);
      expect(chart.negativeCount, 1);
      expect(chart.zeroCount, 0);
      expect(chart.positiveRatio, closeTo(2 / 3, .000001));
      expect(chart.positiveRatioLabel, '67%');
      expect(chart.medianLabel, '+100 Ft');
      expect(chart.histogramMinimumLabel, '-100 Ft');
      expect(chart.histogramMaximumLabel, '+300 Ft');
      expect(chart.stabilityMinimumLabel, '-100 Ft');
      expect(chart.stabilityMaximumLabel, '+300 Ft');
      expect(chart.typicalIntervalLabel, '-100 Ft – +300 Ft');
      expect(chart.stabilityDeviationLabel, '±200 Ft/hó');
      expect(chart.stabilityRangeLabel, '-100 Ft – +300 Ft');
      expect(chart.distributionStats, [
        'Medián: +100 Ft',
        'Jellemző sáv: -100 Ft – +300 Ft',
        'Negatív: 1 · Nulla: 0 · Pozitív: 2',
      ]);
      expect(chart.positiveRatioStats.first, '2 / 3 pozitív hónap');
      expect(chart.positiveRatioStats.last, 'Megtakarítási arány: -1,2%');
      expect(chart.stabilityStats.first, 'Tipikus eltérés: ±200 Ft/hó');
      expect(() => chart.distributionStats.clear(), throwsUnsupportedError);
      expect(() => chart.positiveRatioStats.clear(), throwsUnsupportedError);
      expect(() => chart.stabilityStats.clear(), throwsUnsupportedError);
    },
  );
  test('zero month belongs to denominator and is not positive or negative', () {
    final chart = BalanceSumFocusedChartPresentation.fromScope(
      scope([-100, 0, 100], medianTimesTwo: 0, deviationTimesTwo: 200),
    );
    expect(chart.zeroCount, 1);
    expect(chart.positiveRatio, closeTo(1 / 3, .000001));
    expect(chart.negativeObservationCount, 1);
    final negative = BalanceSumFocusedChartPresentation.fromScope(
      scope([-300, -200, -100], medianTimesTwo: -400, deviationTimesTwo: 200),
    );
    expect(negative.positiveRatio, 0);
    expect(negative.positiveRatioLabel, '0%');
  });
}
