import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_history_chart.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_topographic_chart.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';

void main() {
  test(
    'TOPO-02/03 RED: topographic terrain densely samples the real ridge into 32 fading contours and four atmospheric waves',
    () {
      final terrain = BalanceHeaderTopographicTerrain.resolve(
        series: _series(),
        minimumValue: 0,
        maximumValue: 90,
        size: const Size(346, 60),
      );

      expect(terrain.ridgeSamples.length, greaterThan(60));
      expect(terrain.depthContours, hasLength(32));
      expect(terrain.atmosphericWaves, hasLength(4));
      expect(terrain.depthContours.first.depth, 0);
      expect(terrain.depthContours.last.depth, closeTo(1, .001));
      expect(
        terrain.depthContours.first.opacity,
        greaterThan(terrain.depthContours.last.opacity),
      );
      expect(terrain.ridgeSamples.first.dx, closeTo(0, .01));
      expect(terrain.ridgeSamples.last.dx, closeTo(346, .01));
    },
  );

  test(
    'TOPO-05 RED: geometry cache retains paths for unchanged size and data but invalidates for a new size',
    () {
      final cache = BalanceHeaderTopographicGeometryCache();
      final first = cache.resolve(
        series: _series(),
        minimumValue: 0,
        maximumValue: 90,
        size: const Size(346, 60),
      );
      final repeated = cache.resolve(
        series: _series(),
        minimumValue: 0,
        maximumValue: 90,
        size: const Size(346, 60),
      );
      final resized = cache.resolve(
        series: _series(),
        minimumValue: 0,
        maximumValue: 90,
        size: const Size(300, 60),
      );

      expect(identical(first, repeated), isTrue);
      expect(identical(first, resized), isFalse);
    },
  );

  testWidgets(
    'TOPO-04 RED: the expanded Header mounts one repaint-bounded topographic painter while preserving the existing selection labels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Color(0xff786ce7), Color(0xff9bd7ed)],
                      ),
                    ),
                  ),
                  BalanceHeaderHistoryChart(
                    series: _historySeries(),
                    expansionProgress: 1,
                    lineChartPresentation:
                        BalanceHeaderLineChartPresentation.topographic,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-header-topographic-chart-repaint-boundary',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CustomPaint>(
              find.byKey(
                const ValueKey<String>('balance-header-history-chart-paint'),
              ),
            )
            .painter,
        isA<BalanceHeaderTopographicPainter>(),
      );

      await tester.tapAt(const Offset(190, 78));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-header-history-chart-selected-amount',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-header-history-chart-selected-temporal-label',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TOPO-02/03 visual: the monthly ridge is a clipped layered landscape rather than the flat current line',
    (tester) async {
      await tester.pumpWidget(const _TopographicGoldenHarness());
      await tester.pump();

      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-header-topographic-chart-golden'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_header_topographic_monthly.png',
        ),
      );
    },
  );
}

DashboardHeaderTrendSeries _series() => DashboardHeaderTrendSeries(
  startInclusiveTemporalCoordinate: 0,
  endInclusiveTemporalCoordinate: 31,
  points: const <DashboardHeaderTrendPoint>[
    DashboardHeaderTrendPoint(temporalCoordinate: 0, value: 18),
    DashboardHeaderTrendPoint(temporalCoordinate: 5, value: 72),
    DashboardHeaderTrendPoint(temporalCoordinate: 11, value: 26),
    DashboardHeaderTrendPoint(temporalCoordinate: 17, value: 90),
    DashboardHeaderTrendPoint(temporalCoordinate: 24, value: 40),
    DashboardHeaderTrendPoint(temporalCoordinate: 31, value: 68),
  ],
);

DashboardBalanceHistorySeries _historySeries() => DashboardBalanceHistorySeries(
  startInclusiveEpochMinute: 0,
  endInclusiveEpochMinute: 31,
  points: const <DashboardBalanceHistoryPoint>[
    DashboardBalanceHistoryPoint(
      entryId: 'start',
      epochDay: 0,
      epochMinute: 0,
      incomeTotalMinor: 50000,
      expenseTotalMinor: 0,
      balanceMinor: 50000,
    ),
    DashboardBalanceHistoryPoint(
      entryId: 'first',
      epochDay: 5,
      epochMinute: 10,
      incomeTotalMinor: 85000,
      expenseTotalMinor: 12000,
      balanceMinor: 73000,
    ),
    DashboardBalanceHistoryPoint(
      entryId: 'second',
      epochDay: 15,
      epochMinute: 20,
      incomeTotalMinor: 90000,
      expenseTotalMinor: 41000,
      balanceMinor: 49000,
    ),
    DashboardBalanceHistoryPoint(
      entryId: 'last',
      epochDay: 24,
      epochMinute: 31,
      incomeTotalMinor: 125000,
      expenseTotalMinor: 53000,
      balanceMinor: 72000,
    ),
  ],
);

final class _TopographicGoldenHarness extends StatelessWidget {
  const _TopographicGoldenHarness();

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: const ValueKey<String>(
            'balance-header-topographic-chart-golden',
          ),
          child: SizedBox(
            width: 378,
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xff8174ec), Color(0xffb5ddeb)],
                    ),
                  ),
                ),
                BalanceHeaderHistoryChart(
                  series: _historySeries(),
                  expansionProgress: 1,
                  lineChartPresentation:
                      BalanceHeaderLineChartPresentation.topographic,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
