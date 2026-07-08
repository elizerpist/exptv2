import 'package:exptv2/features/stats/data/stats_heatmap_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cluster density measures rolling hot-day ratio', () {
    final series = StatsHeatmapSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [0, 6000, 8000, 0],
      densityWindow: 2,
      pulseShortWindow: 2,
      pulseLongWindow: 3,
    );

    expect(series.density[0].value, 0);
    expect(series.density[2].value, 1);
    expect(series.density[3].value, 0.5);
    expect(series.densityLineColorHex, '#06B6D4');
  });

  test('heat pulse maps fresh heat pressure to blue and cooling to gray', () {
    final heating = StatsHeatmapSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [0, 0, 5000, 10000, 15000],
      densityWindow: 2,
      pulseShortWindow: 2,
      pulseLongWindow: 4,
    );
    final cooling = StatsHeatmapSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [15000, 10000, 5000, 0, 0],
      densityWindow: 2,
      pulseShortWindow: 2,
      pulseLongWindow: 4,
    );

    expect(heating.pulse.last.value, greaterThan(0));
    expect(heating.pulse.last.colorHex, '#06B6D4');
    expect(cooling.pulse.last.value, lessThan(0));
    expect(cooling.pulse.last.colorHex, '#CBD5E1');
  });

  test(
    'monthly heat load combines frequency and threshold overshoot severity',
    () {
      final series = StatsHeatmapSeries.fromDailySamples(
        threshold: 5000,
        dailyScopeAmounts: const [5000, 10000, 20000, 0],
        monthIndexes: const [0, 0, 0, 0],
        densityWindow: 2,
        pulseShortWindow: 2,
        pulseLongWindow: 4,
      );

      final bar = series.monthlyBars.single;
      expect(bar.heatLoad, 6);
      expect(bar.hotDayCount, 3);
      expect(bar.segments.map((segment) => segment.colorHex), [
        '#DDF8FD',
        '#67E8F9',
        '#06B6D4',
      ]);
    },
  );
}
