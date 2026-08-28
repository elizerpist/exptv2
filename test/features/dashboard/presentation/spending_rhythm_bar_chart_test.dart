import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/header_cascade_motion.dart';
import 'package:fluvi/features/dashboard/application/dashboard_spending_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/spending_rhythm_bar_chart.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  testWidgets(
    'normalizes against its own buckets and includes zero in average',
    (tester) async {
      await tester.pumpWidget(_host(_state(<int>[5000, 20000, 10000, 0])));

      expect(
        find.byKey(const ValueKey('spending-rhythm-fill-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spending-rhythm-average')),
        findsOneWidget,
      );
      expect(find.text('Átlag'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    },
  );

  testWidgets(
    'all-zero rhythm retains bars but omits a false average reference',
    (tester) async {
      await tester.pumpWidget(_host(_state(<int>[0, 0, 0, 0])));

      expect(
        find.byKey(const ValueKey('spending-rhythm-fill-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spending-rhythm-average')),
        findsNothing,
      );
      expect(find.text('Nincs adat'), findsOneWidget);
    },
  );

  testWidgets(
    'SUM keeps every concrete year and scrolls only beyond 31 slots',
    (tester) async {
      await tester.pumpWidget(_host(_sumState(32)));

      final scroll = find.byKey(const ValueKey('spending-rhythm-sum-scroll'));
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(find.text('1990'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.drag(scroll, const Offset(-80, 0));
      await tester.pump();
      expect(position.pixels, greaterThan(0));
    },
  );

  testWidgets(
    'DAY exposes all eight compact hours with full bucket semantics',
    (tester) async {
      await tester.pumpWidget(
        _host(
          DashboardSpendingRhythmState(
            analysis: DaySpendingRhythm(
              coreRevision: 1,
              direction: LedgerDirection.expense,
              targetHandle: 0,
              scope: const DayScope(LocalDate(year: 2022, month: 3, day: 1)),
              buckets: const <SpendingRhythmBucket>[
                SpendingRhythmBucket(
                  label: '0',
                  accessibilityLabel: 'Éjfél',
                  actualScaled100: 1,
                ),
                SpendingRhythmBucket(
                  label: '3',
                  accessibilityLabel: 'Hajnal',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '6',
                  accessibilityLabel: 'Reggel',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '9',
                  accessibilityLabel: 'Délelőtt',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '12',
                  accessibilityLabel: 'Kora délután',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '15',
                  accessibilityLabel: 'Délután',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '18',
                  accessibilityLabel: 'Este',
                  actualScaled100: 0,
                ),
                SpendingRhythmBucket(
                  label: '21',
                  accessibilityLabel: 'Késő este',
                  actualScaled100: 0,
                ),
              ],
            ),
            startColorArgb: 0xff000000,
            middleColorArgb: 0xff111111,
            endColorArgb: 0xff222222,
          ),
        ),
      );

      for (final hour in <String>['0', '3', '6', '9', '12', '15', '18', '21']) {
        expect(find.text(hour), findsOneWidget);
      }
      final semantics = tester.ensureSemantics();
      final chartSemantics = tester.getSemantics(
        find
            .descendant(
              of: find.byType(SpendingRhythmBarChart),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(chartSemantics.label, contains('Éjfél: 1'));
      expect(chartSemantics.label, contains('Késő este: 0'));
      semantics.dispose();
    },
  );

  testWidgets(
    'RED: dense zero slots use discrete outlines, never an opaque neutral '
    'Rhythm slab',
    (tester) async {
      await tester.pumpWidget(_host(_state(const <int>[])));

      final track = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('spending-rhythm-track-0')),
      );
      final decoration = track.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
    },
  );

  testWidgets(
    'Budget Card2 keeps its authored opaque material through every '
    'intermediate cascade reveal instead of alpha-blending into a grey slab',
    (tester) async {
      final boundary = GlobalKey();

      Future<Color> renderAndSample(double progress) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 300,
                height: 150,
                child: Stack(
                  children: <Widget>[
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xff666666)),
                    ),
                    DashboardCoreModeCascadeCard(
                      bounds: const DashboardBounds(
                        left: 0,
                        top: 10,
                        width: 300,
                        height: 100,
                      ),
                      motion: CascadedCardMotion(
                        top: 10,
                        left: 0,
                        right: 0,
                        opacity: progress,
                        scale: 1,
                        progress: progress,
                      ),
                      semanticKey: const ValueKey('cascade-card2'),
                      showPlaceholderSurface: false,
                      clipOpaqueContentDuringReveal: true,
                      content: const ColoredBox(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return _sampleBoundaryColor(tester, boundary, x: 20, y: 20);
      }

      expect(await renderAndSample(0), const Color(0xff666666));
      for (final progress in <double>[.25, .50, .75, 1]) {
        expect(
          await renderAndSample(progress),
          Colors.white,
          reason:
              'collapse progress $progress must reveal white Card2, '
              'not a blended grey placeholder.',
        );
      }
    },
  );
}

Future<Color> _sampleBoundaryColor(
  WidgetTester tester,
  GlobalKey boundary, {
  required int x,
  required int y,
}) async {
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => renderBoundary.toImage(pixelRatio: 1),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Cascade raster bytes unavailable.');
    final offset = (y * image.width + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
  } finally {
    image.dispose();
  }
}

Widget _host(DashboardSpendingRhythmState state) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 358,
      height: 120,
      child: SpendingRhythmBarChart(state: state),
    ),
  ),
);

DashboardSpendingRhythmState _state(List<int> values) =>
    DashboardSpendingRhythmState(
      analysis: MonthSpendingRhythm(
        coreRevision: 1,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        scope: const MonthScope(YearMonth(year: 2022, month: 3)),
        buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
          for (var index = 0; index < 31; index += 1)
            SpendingRhythmBucket(
              label: '${index + 1}',
              accessibilityLabel: '${index + 1}',
              actualScaled100: index < values.length ? values[index] : 0,
            ),
        ]),
      ),
      startColorArgb: 0xff000000,
      middleColorArgb: 0xff111111,
      endColorArgb: 0xff222222,
    );

DashboardSpendingRhythmState _sumState(int count) =>
    DashboardSpendingRhythmState(
      analysis: SumSpendingRhythm(
        coreRevision: 1,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        scope: const AllTimeScope(),
        buckets: List<SpendingRhythmBucket>.unmodifiable(<SpendingRhythmBucket>[
          for (var index = 0; index < count; index += 1)
            SpendingRhythmBucket(
              label: '${1990 + index}',
              accessibilityLabel: '${1990 + index}',
              actualScaled100: index + 1,
            ),
        ]),
      ),
      startColorArgb: 0xff000000,
      middleColorArgb: 0xff111111,
      endColorArgb: 0xff222222,
    );
