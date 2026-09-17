import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_header_score_chart.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_mind_score_color.dart';

void main() {
  testWidgets(
    'MHC-02/03/04 expanded Mind Header chart matches the inspected reference composition',
    (tester) async {
      final points = <MindBehavioralScorePoint>[
        for (var index = 0; index < 56; index += 1)
          MindBehavioralScorePoint(
            epochDay: index,
            score: _referenceLikeScore(index),
            noSignal: false,
          ),
      ];
      final series = MindBehavioralScoreChartSeries(
        startInclusiveEpochDay: points.first.epochDay,
        endInclusiveEpochDay: points.last.epochDay,
        points: points,
      );
      addTearDown(() {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xfff1f5f9),
            body: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  key: const ValueKey<String>('mind-header-chart-golden'),
                  width: 378,
                  height: 126,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          MindHeaderTrafficLightScale.sample(0),
                          MindHeaderTrafficLightScale.sample(28),
                          MindHeaderTrafficLightScale.sample(54),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        MindHeaderScoreChart(
                          series: series,
                          expansionProgress: 1,
                        ),
                        const Positioned(
                          left: 16,
                          top: 16,
                          child: Text(
                            '2/100',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              height: .96,
                              letterSpacing: -.76,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 12,
                          right: 62,
                          child: Text(
                            'mind',
                            style: TextStyle(
                              color: Color(0xff64748b),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(const ValueKey<String>('mind-header-chart-golden')),
        matchesGoldenFile(
          '../../../goldens/mind_header_score_chart_reference.png',
        ),
      );
    },
  );
}

double _referenceLikeScore(int index) {
  const anchors = <double>[
    98,
    36,
    24,
    30,
    18,
    26,
    42,
    18,
    8,
    22,
    35,
    54,
    17,
    8,
    24,
    2,
    30,
    55,
    38,
    16,
    22,
    8,
    28,
    45,
    12,
    5,
    17,
    9,
    30,
    13,
    2,
  ];
  if (index < anchors.length) return anchors[index];
  final tail = index - anchors.length;
  return (<double>[14, 4, 8, 16, 24, 13, 18, 9, 4, 11, 2][tail % 11]);
}
