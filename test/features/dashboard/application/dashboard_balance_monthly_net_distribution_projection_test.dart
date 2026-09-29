import 'package:fluvi/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'sum-distribution',
  indexGeneration: 7,
  coreRevision: 11,
);

void main() {
  test(
    'SUM-01: adaptive histogram assigns every closed month once with equal regular bin widths',
    () {
      final distribution =
          DashboardBalanceMonthlyNetDistributionProjection.build(
            stability: _stability(<int>[
              -194000,
              53000,
              -35000,
              128000,
              -18000,
              9000,
              -151000,
              24000,
              199000,
              -39500,
              70000,
              -109000,
              12000,
              57500,
              143000,
              39000,
              85000,
              18000,
              -30000,
              0,
              -172000,
              -97000,
              9000,
              -24000,
              223000,
              -2000,
              48000,
              -131000,
              158000,
              30000,
              -142000,
              101000,
              8000,
              -118000,
              4000,
              176000,
              -10000,
              115000,
            ]),
          );

      final histogram = distribution.histogram;
      expect(histogram.sampleCount, 38);
      expect(histogram.assignedSampleCount, histogram.sampleCount);
      expect(histogram.regularBins.length, inInclusiveRange(1, 11));
      expect(
        histogram.regularBins.map((bin) => bin.widthMinor).toSet().length,
        1,
      );
      expect(histogram.hasZeroRegularBoundary, isTrue);
      expect(histogram.regularBoundariesMinor, contains(0.0));
      expect(histogram.medianMinor, 9000);
      expect(histogram.typicalLowerMinor, -39500);
      expect(histogram.typicalUpperMinor, 57500);
    },
  );

  test('SUM-01: identical monthly nets retain one truthful regular bar', () {
    final histogram = DashboardBalanceMonthlyNetDistributionProjection.build(
      stability: _stability(<int>[42000, 42000, 42000, 42000]),
    ).histogram;

    expect(histogram.regularBins, hasLength(1));
    expect(
      histogram.regularBins.single.kind,
      DashboardBalanceHistogramBinKind.regular,
    );
    expect(histogram.regularBins.single.count, 4);
    expect(histogram.assignedSampleCount, 4);
    expect(histogram.regularBinWidthMinor, 0);
  });

  test(
    'SUM-01: robust core leaves extreme months in explicit overflow bins',
    () {
      final histogram = DashboardBalanceMonthlyNetDistributionProjection.build(
        stability: _stability(<int>[
          -15000,
          -12000,
          -8000,
          -3000,
          0,
          3000,
          8000,
          12000,
          15000,
          900000,
          -850000,
        ]),
      ).histogram;

      expect(histogram.underflowBin?.count, 1);
      expect(histogram.overflowBin?.count, 1);
      expect(histogram.assignedSampleCount, 11);
      expect(
        histogram.regularBins.map((bin) => bin.widthMinor).toSet().length,
        1,
      );
    },
  );

  test(
    'SUM-01: positive-only data does not widen a regular domain just to include zero',
    () {
      final histogram = DashboardBalanceMonthlyNetDistributionProjection.build(
        stability: _stability(<int>[12000, 18000, 22000, 27000, 34000]),
      ).histogram;

      expect(histogram.hasZeroRegularBoundary, isFalse);
      expect(histogram.regularStartMinor, greaterThan(0));
      expect(histogram.zeroIsExternalReference, isTrue);
    },
  );

  test(
    'SUM-03: longest positive streak keeps consecutive positive closed months only',
    () {
      final streak = DashboardBalanceMonthlyNetDistributionProjection.build(
        stability: _stability(<int>[-10, 50, 20, 10, 4, 1, 2, 0, 100, 50]),
      ).longestPositiveStreak;

      expect(streak.length, 6);
      expect(streak.netValuesMinor, <int>[50, 20, 10, 4, 1, 2]);
    },
  );

  test(
    'SUM-05: cashflow band maps the existing median and typical range over every closed month',
    () {
      final stability = _stability(<int>[
        -100000,
        -39500,
        0,
        9000,
        57500,
        140000,
      ]);
      final band = DashboardBalanceMonthlyNetDistributionProjection.build(
        stability: stability,
      ).cashflowBand;

      expect(band.sampleCount, 6);
      expect(band.observationNetTimesTwo, <int>[
        -200000,
        -79000,
        0,
        18000,
        115000,
        280000,
      ]);
      expect(band.medianNetTimesTwo, stability.medianNetTimesTwo);
      expect(band.typicalLowerTimesTwo, stability.typicalBandLowerTimesTwo);
      expect(band.typicalUpperTimesTwo, stability.typicalBandUpperTimesTwo);
      expect(band.xFractionForTimesTwo(0), inInclusiveRange(0.0, 1.0));
      expect(
        band.xFractionForTimesTwo(band.typicalLowerTimesTwo!),
        lessThan(band.xFractionForTimesTwo(band.typicalUpperTimesTwo!)),
      );
    },
  );
}

DashboardBalanceStabilityPresentation _stability(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  final medianTimesTwo = _medianTimesTwo(sorted);
  final deviations =
      values
          .map((value) => (value * 2 - medianTimesTwo).abs())
          .toList(growable: false)
        ..sort();
  return DashboardBalanceStabilityPresentation(
    identity: _identity,
    timeScope: const AllTimeScope(),
    observations: <DashboardBalanceMonthlyNetObservation>[
      for (var index = 0; index < values.length; index += 1)
        DashboardBalanceMonthlyNetObservation(
          id: 'month:$index',
          label: '2024 M$index',
          month: YearMonth(year: 2024 + index ~/ 12, month: index % 12 + 1),
          incomeMinor: values[index] > 0 ? values[index] : 0,
          expenseMinor: values[index] < 0 ? -values[index] : 0,
        ),
    ],
    medianNetTimesTwo: medianTimesTwo,
    typicalDeviationTimesTwo: _medianMinor(deviations),
  );
}

int _medianTimesTwo(List<int> sorted) {
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle] * 2
      : sorted[middle - 1] + sorted[middle];
}

int _medianMinor(List<int> sorted) {
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) ~/ 2;
}
