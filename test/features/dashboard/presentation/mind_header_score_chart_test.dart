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

  testWidgets('MHC foreground line color is independent from score data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chart(series: series, expansion: 1, lineColor: const Color(0xff000000)),
    );

    final painter = _painter(tester);
    expect(painter.lineColor, const Color(0xff000000));
    expect(painter.points, series.points);
  });

  testWidgets(
    'HIV: Mind receives an independent optional chart-underlay veil',
    (tester) async {
      await tester.pumpWidget(
        _chart(
          series: series,
          expansion: 1,
          lineColor: const Color(0xff000000),
          areaFadeColor: const Color(0xd114213a),
          showsAreaFade: false,
        ),
      );

      final painter = _painter(tester);
      expect(painter.lineColor, const Color(0xff000000));
      expect(painter.areaFadeColor, const Color(0xd114213a));
      expect(painter.showsAreaFade, isFalse);
      expect(painter.points, series.points);
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

  test(
    'CHART-X-01/02: sparse points, label anchors and hit testing share one epoch-day projection',
    () {
      final sparse = MindBehavioralScoreChartSeries(
        startInclusiveEpochDay: 0,
        endInclusiveEpochDay: 100,
        points: const <MindBehavioralScorePoint>[
          MindBehavioralScorePoint(epochDay: 0, score: 100, noSignal: false),
          MindBehavioralScorePoint(epochDay: 10, score: 80, noSignal: false),
          MindBehavioralScorePoint(epochDay: 90, score: 20, noSignal: false),
          MindBehavioralScorePoint(epochDay: 100, score: 0, noSignal: false),
        ],
      );
      const projection = MindHeaderScoreChartTemporalProjection(
        startInclusiveEpochDay: 0,
        endInclusiveEpochDay: 100,
      );
      final painter = MindHeaderScoreChartPainter(series: sparse);
      const plotSize = Size(100, 60);

      expect(
        List<double>.generate(
          sparse.points.length,
          (index) => painter.pointOffsetAt(index, plotSize, projection).dx,
        ),
        <double>[0, 10, 90, 100],
        reason:
            'The c1b12 index authority was 0/33/66/100; every chart X user '
            'must now receive the actual epoch-day geometry.',
      );
      expect(projection.normalizedEpochDay(10), .1);
      expect(projection.normalizedEpochDay(90), .9);
      expect(
        projection.nearestPointForPlotX(sparse.points, 11, plotSize.width),
        sparse.points[1],
      );
      expect(
        projection.nearestPointForPlotX(sparse.points, 88, plotSize.width),
        sparse.points[2],
      );
      expect(
        MindHeaderScoreChart.projectedTimeLabelEpochDays(sparse),
        const <int>[0, 25, 50, 75, 100],
      );
    },
  );

  testWidgets(
    'CHART-TAP-01/02/03/04/07: clean taps select, move and toggle immutable points independently of static labels',
    (tester) async {
      final sparse = MindBehavioralScoreChartSeries(
        startInclusiveEpochDay: 0,
        endInclusiveEpochDay: 100,
        points: const <MindBehavioralScorePoint>[
          MindBehavioralScorePoint(epochDay: 0, score: 100, noSignal: false),
          MindBehavioralScorePoint(epochDay: 10, score: 80, noSignal: false),
          MindBehavioralScorePoint(epochDay: 90, score: 20, noSignal: false),
          MindBehavioralScorePoint(epochDay: 100, score: 0, noSignal: false),
        ],
      );
      await tester.pumpWidget(
        _chart(
          series: sparse,
          expansion: 1,
          temporalContext: MindHeaderScoreChartTemporalContext.month,
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsNothing,
      );

      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-header-score-chart-paint')),
      );
      await tester.tapAt(Offset(plot.left + plot.width * .1, plot.center.dy));
      await tester.pump();
      expect(find.text('80/100'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(_painter(tester).selectedEpochDay, 10);

      await tester.tapAt(Offset(plot.left + plot.width * .9, plot.center.dy));
      await tester.pump();
      expect(find.text('20/100'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(_painter(tester).selectedEpochDay, 90);

      await tester.tapAt(Offset(plot.left + plot.width * .9, plot.center.dy));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        _chart(
          series: sparse,
          expansion: 1,
          showTimeLabels: true,
          temporalContext: MindHeaderScoreChartTemporalContext.month,
        ),
      );
      await tester.tapAt(Offset(plot.left + plot.width * .1, plot.center.dy));
      await tester.pump();
      expect(find.text('80/100'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-0'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'CHART-X-02: static time labels use the same rounded epoch-day projection as the line',
    (tester) async {
      final nonUniformDomain = MindBehavioralScoreChartSeries(
        startInclusiveEpochDay: 0,
        endInclusiveEpochDay: 3,
        points: const <MindBehavioralScorePoint>[
          MindBehavioralScorePoint(epochDay: 0, score: 30, noSignal: false),
          MindBehavioralScorePoint(epochDay: 3, score: 80, noSignal: false),
        ],
      );
      await tester.pumpWidget(
        _chart(series: nonUniformDomain, expansion: 1, showTimeLabels: true),
      );
      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-header-score-chart-paint')),
      );
      final firstQuarter = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-1'),
        ),
      );
      final midpoint = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-2'),
        ),
      );
      final thirdQuarter = tester.getCenter(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-time-label-3'),
        ),
      );

      // projectedTimeLabelEpochDays rounds 0.75/1.5/2.25 to 1/2/2, so the
      // labels must land at 1/3, 2/3 and 2/3—not artificial 25/50/75% slots.
      expect(firstQuarter.dx, closeTo(plot.left + plot.width / 3, .001));
      expect(midpoint.dx, closeTo(plot.left + plot.width * 2 / 3, .001));
      expect(thirdQuarter.dx, closeTo(plot.left + plot.width * 2 / 3, .001));
    },
  );

  testWidgets(
    'CHART-TAP-05/06/10: series change clears selection, labels honor explicit mode, and edge boxes clamp inside Header',
    (tester) async {
      final first = _seriesFor(
        DateTime.utc(2027, 8, 1),
        DateTime.utc(2027, 8, 31),
      );
      await tester.pumpWidget(
        _chart(
          series: first,
          expansion: 1,
          temporalContext: MindHeaderScoreChartTemporalContext.year,
        ),
      );
      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-header-score-chart-paint')),
      );
      await tester.tapAt(Offset(plot.left, plot.center.dy));
      await tester.pump();
      final score = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
      );
      final temporal = tester.getRect(
        find.byKey(
          const ValueKey<String>(
            'mind-header-score-chart-selected-temporal-label',
          ),
        ),
      );
      final header = tester.getRect(
        find.byKey(const ValueKey<String>('mind-header-score-chart')),
      );
      expect(score.left, greaterThanOrEqualTo(header.left));
      expect(temporal.left, greaterThanOrEqualTo(header.left));
      expect(score.right, lessThanOrEqualTo(header.right));
      expect(temporal.right, lessThanOrEqualTo(header.right));

      final second = _seriesFor(
        DateTime.utc(2028, 1, 1),
        DateTime.utc(2028, 1, 31),
      );
      await tester.pumpWidget(
        _chart(
          series: second,
          expansion: 1,
          temporalContext: MindHeaderScoreChartTemporalContext.year,
        ),
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsNothing,
      );

      final august26 = MindBehavioralScorePoint(
        epochDay: DateTime.utc(
          2027,
          8,
          26,
        ).difference(DateTime.utc(1970)).inDays,
        score: 42,
        noSignal: false,
      );
      expect(
        MindHeaderScoreChart.selectedTemporalLabel(
          august26,
          MindHeaderScoreChartTemporalContext.year,
        ),
        'aug 26',
      );
      expect(
        MindHeaderScoreChart.selectedTemporalLabel(
          august26,
          MindHeaderScoreChartTemporalContext.sum,
        ),
        '2027. aug',
      );
      expect(
        MindHeaderScoreChart.selectedTemporalLabel(
          august26,
          MindHeaderScoreChartTemporalContext.month,
        ),
        '26',
      );
      expect(
        MindHeaderScoreChart.selectedTemporalLabel(
          august26,
          MindHeaderScoreChartTemporalContext.day,
        ),
        'aug 26',
      );
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
  MindHeaderScoreChartTemporalContext temporalContext =
      MindHeaderScoreChartTemporalContext.year,
  Color lineColor = MindHeaderScoreChartStyle.lineColor,
  Color? areaFadeColor,
  bool showsAreaFade = true,
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
          temporalContext: temporalContext,
          lineColor: lineColor,
          areaFadeColor: areaFadeColor,
          showsAreaFade: showsAreaFade,
        ),
      ],
    ),
  ),
);

MindHeaderScoreChartPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(
                const ValueKey<String>('mind-header-score-chart-paint'),
              ),
            )
            .painter!
        as MindHeaderScoreChartPainter;
