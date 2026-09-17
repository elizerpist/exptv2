import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_header_score_chart.dart';

void main() {
  final series = MindBehavioralScoreChartSeries(
    startInclusiveEpochDay: 10,
    endInclusiveEpochDay: 14,
    points: const <MindBehavioralScorePoint>[
      MindBehavioralScorePoint(epochDay: 10, score: 94, noSignal: false),
      MindBehavioralScorePoint(epochDay: 11, score: 42, noSignal: false),
      MindBehavioralScorePoint(epochDay: 12, score: 61, noSignal: false),
      MindBehavioralScorePoint(epochDay: 13, score: 18, noSignal: false),
      MindBehavioralScorePoint(epochDay: 14, score: 2, noSignal: false),
    ],
  );

  testWidgets(
    'MHC-01 expanded-only chart is absent when Header expansion is zero',
    (tester) async {
      await tester.pumpWidget(_chart(series: series, expansion: 0));

      expect(
        find.byKey(const ValueKey<String>('mind-header-score-chart')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'MHC-01 chart reveal is continuously clipped by existing Header expansion',
    (tester) async {
      await tester.pumpWidget(_chart(series: series, expansion: .5));

      expect(
        find.byKey(const ValueKey<String>('mind-header-score-chart')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-reveal'),
              ),
            )
            .height,
        closeTo(MindHeaderScoreChartStyle.plotHeight * .5, .01),
      );

      await tester.pumpWidget(_chart(series: series, expansion: 1));
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-reveal'),
              ),
            )
            .height,
        MindHeaderScoreChartStyle.plotHeight,
      );
    },
  );

  testWidgets(
    'MHC-03/04 plot keeps the reference line, endpoint and white fade specification',
    (tester) async {
      await tester.pumpWidget(_chart(series: series, expansion: 1));

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey<String>('mind-header-score-chart-paint'),
                    ),
                  )
                  .painter!
              as MindHeaderScoreChartPainter;
      expect(MindHeaderScoreChartStyle.plotLeft, 16);
      expect(MindHeaderScoreChartStyle.plotTop, 48);
      expect(MindHeaderScoreChartStyle.plotWidth, 346);
      expect(MindHeaderScoreChartStyle.plotHeight, 60);
      expect(painter.points.last.score, 2);
      expect(painter.lineColor, MindHeaderScoreChartStyle.lineColor);
      expect(painter.lineWidth, MindHeaderScoreChartStyle.lineWidth);
      expect(painter.endpointRadius, MindHeaderScoreChartStyle.endpointRadius);
      expect(painter.smoothsBetweenDailySamples, isTrue);
      expect(painter.areaFadeStartOpacity, greaterThan(0));
      expect(painter.areaFadeEndOpacity, 0);
    },
  );

  testWidgets(
    'RED CLB-01/03: visible time-label projection renders exactly five actual-domain dates without changing the plot',
    (tester) async {
      await tester.pumpWidget(
        _chart(series: series, expansion: 1, showTimeLabels: true),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-header-score-chart-paint')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-0'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-3'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-4'),
        ),
        findsOneWidget,
      );
      expect(
        MindHeaderScoreChart.projectedTimeLabelEpochDays(series),
        const <int>[10, 11, 12, 13, 14],
      );
      final chartRect = tester.getRect(
        find.byKey(const ValueKey<String>('mind-header-score-chart-paint')),
      );
      final start = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-0'),
        ),
      );
      final firstQuarter = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-1'),
        ),
      );
      final center = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-2'),
        ),
      );
      final thirdQuarter = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-3'),
        ),
      );
      final end = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-4'),
        ),
      );
      expect(start.left, closeTo(chartRect.left, .001));
      expect(
        firstQuarter.dx,
        closeTo(chartRect.left + chartRect.width * .25, .001),
      );
      expect(center.dx, closeTo(chartRect.left + chartRect.width * .5, .001));
      expect(
        thirdQuarter.dx,
        closeTo(chartRect.left + chartRect.width * .75, .001),
      );
      expect(end.right, closeTo(chartRect.right, .001));
      expect(MindHeaderScoreChartStyle.plotLeft, 16);
      expect(MindHeaderScoreChartStyle.plotTop, 48);
      expect(MindHeaderScoreChartStyle.plotWidth, 346);
      expect(MindHeaderScoreChartStyle.plotHeight, 60);
    },
  );

  testWidgets('RED CLB-01: time labels stay absent by default and collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(_chart(series: series, expansion: 1));
    expect(
      find.byKey(
        const ValueKey<String>('mind-header-score-chart-time-label-0'),
      ),
      findsNothing,
    );

    await tester.pumpWidget(
      _chart(series: series, expansion: 0, showTimeLabels: true),
    );
    expect(
      find.byKey(
        const ValueKey<String>('mind-header-score-chart-time-label-0'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'RED CLB-02: time labels reproject from each immutable chart domain without changing score points',
    (tester) async {
      final year = _seriesFor(
        DateTime.utc(2027, 1, 1),
        DateTime.utc(2027, 12, 31),
      );
      await tester.pumpWidget(
        _chart(series: year, expansion: 1, showTimeLabels: true),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-time-label-0'),
              ),
            )
            .data,
        'jan',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-time-label-4'),
              ),
            )
            .data,
        'dec',
      );

      final sum = _seriesFor(
        DateTime.utc(2025, 1, 1),
        DateTime.utc(2027, 12, 31),
      );
      await tester.pumpWidget(
        _chart(series: sum, expansion: 1, showTimeLabels: true),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-time-label-0'),
              ),
            )
            .data,
        '2025. jan',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-time-label-4'),
              ),
            )
            .data,
        '2027. dec',
      );
      expect(sum.points, hasLength(2));
      expect(sum.points.last.score, 80);
    },
  );
}

MindBehavioralScoreChartSeries _seriesFor(DateTime start, DateTime end) {
  final epoch = DateTime.utc(1970);
  final startEpochDay = start.difference(epoch).inDays;
  final endEpochDay = end.difference(epoch).inDays;
  return MindBehavioralScoreChartSeries(
    startInclusiveEpochDay: startEpochDay,
    endInclusiveEpochDay: endEpochDay,
    points: <MindBehavioralScorePoint>[
      MindBehavioralScorePoint(
        epochDay: startEpochDay,
        score: 20,
        noSignal: false,
      ),
      MindBehavioralScorePoint(
        epochDay: endEpochDay,
        score: 80,
        noSignal: false,
      ),
    ],
  );
}

Widget _chart({
  required MindBehavioralScoreChartSeries series,
  required double expansion,
  bool showTimeLabels = false,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox(
    width: 378,
    height: 126,
    child: Stack(
      children: <Widget>[
        MindHeaderScoreChart(
          series: series,
          expansionProgress: expansion,
          showTimeLabels: showTimeLabels,
        ),
      ],
    ),
  ),
);
