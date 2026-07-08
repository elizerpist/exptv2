import 'package:exptv2/features/stats/data/stats_category_scope_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('occurrence can fall while value index rises', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 6000, 0, 0, 30000],
      window: 2,
    );

    expect(
      series.occurrence.last.value,
      lessThan(series.occurrence.first.value),
    );
    expect(
      series.valueIndex.last.value,
      greaterThan(series.valueIndex.first.value),
    );
  });

  test('occurrence-only improvement does not create a false high score', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 6000, 6000, 0, 0, 50000],
      window: 3,
    );

    expect(
      series.occurrence.last.value,
      lessThan(series.occurrence.first.value),
    );
    expect(
      series.valueIndex.last.value,
      greaterThan(series.valueIndex.first.value),
    );
    expect(series.kontrollScore, lessThan(65));
  });

  test(
    'risk segments distinguish improvement, divergence, worsening and flat',
    () {
      final segments = StatsCategoryScopeSeries.classifyRiskSegments(
        occurrenceValues: const [80, 60, 50, 70, 70],
        valueIndexValues: const [80, 60, 80, 90, 90],
        noiseThreshold: 0.5,
      );

      expect(segments[0].colorHex, '#10B981');
      expect(segments[1].colorHex, '#F97316');
      expect(segments[2].colorHex, '#EF4444');
      expect(segments[3].colorHex, isNull);
    },
  );

  test('macd maps worsening pressure to red and improvement to green', () {
    final worsening = StatsCategoryScopeSeries.fromPressureValues(
      const [10, 12, 16, 22, 31, 43, 58],
      shortWindow: 2,
      longWindow: 4,
      signalWindow: 2,
    );
    final improving = StatsCategoryScopeSeries.fromPressureValues(
      const [58, 43, 31, 22, 16, 12, 10],
      shortWindow: 2,
      longWindow: 4,
      signalWindow: 2,
    );

    expect(worsening.macd.last.value, greaterThan(0));
    expect(worsening.macd.last.colorHex, '#EF4444');
    expect(improving.macd.last.value, lessThan(0));
    expect(improving.macd.last.colorHex, '#22C55E');
  });

  test(
    'monthly bars keep top three categories and group every other category',
    () {
      final series = StatsCategoryScopeSeries.fromMonthlyCategoryTotals(
        monthlyCategoryTotals: const [
          {1: 10000.0, 2: 9000.0, 3: 8000.0, 4: 7000.0, 5: 6000.0},
        ],
        monthlyThresholdHitDays: const [4],
        categoryNames: const {
          1: 'Gyorskaja',
          2: 'Ruha',
          3: 'Bolt',
          4: 'Taxi',
          5: 'Mozi',
        },
      );

      final bar = series.monthlyBars.single;
      expect(bar.totalAmount, 40000);
      expect(bar.segments.map((segment) => segment.label), [
        'Gyorskaja',
        'Ruha',
        'Bolt',
        'Egyéb',
      ]);
      expect(bar.segments.last.amount, 13000);
      expect(bar.segments.last.colorHex, '#CBD5E1');
      expect(bar.impactValue, 10000);
      expect(series.latestImpactLabel, '10.0k');
    },
  );
}
