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
}

Widget _chart({
  required MindBehavioralScoreChartSeries series,
  required double expansion,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox(
    width: 378,
    height: 126,
    child: Stack(
      children: <Widget>[
        MindHeaderScoreChart(series: series, expansionProgress: expansion),
      ],
    ),
  ),
);
