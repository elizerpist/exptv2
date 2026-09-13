import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 1,
    upperScaled100: 1000,
  );

  testWidgets('RED MYH-02/13: 12 compact MonthCards form a 3x4 year grid', (
    tester,
  ) async {
    final frame = ValueNotifier(_projection().preview(range));
    addTearDown(frame.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 500,
            child: MindYearHeatmapViewport(frameListenable: frame),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('mind-year-heatmap-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mind-year-heatmap-grid')),
      findsOneWidget,
    );
    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('mind-year-heatmap-grid')),
    );
    expect(grid.childrenDelegate.estimatedChildCount, 12);
    expect(find.text('szeptember'), findsOneWidget);
    expect(
      grid.gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>().having(
        (delegate) => delegate.crossAxisCount,
        'crossAxisCount',
        3,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RED MYH-09: a held physical slider drag recolors tiles before release',
    (tester) async {
      final projection = _projection();
      final frame = ValueNotifier(projection.preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 540,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: MindYearHeatmapViewport(frameListenable: frame),
                  ),
                  QueryAmountRangeControl(
                    values: range,
                    presentation: QueryAmountRangePresentation.compactMind,
                    onRangeCommitted: (_) {},
                    onRangePreviewChanged: (next) =>
                        frame.value = projection.preview(next),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final painterFinder = find.byKey(
        const ValueKey('mind-year-heatmap-month-cells-1'),
      );
      MindYearHeatmapMonthPainter monthPainter() =>
          tester.widget<CustomPaint>(painterFinder).painter!
              as MindYearHeatmapMonthPainter;
      const secondJanuary = LocalDate(year: 2025, month: 1, day: 2);
      final before = monthPainter().colorForDate(secondJanuary);
      final slider = find.byKey(const ValueKey('query-amount-range-slider'));
      final sliderRect = tester.getRect(slider);
      final gesture = await tester.startGesture(
        Offset(sliderRect.left + 12, sliderRect.center.dy),
      );
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();

      final after = monthPainter().colorForDate(secondJanuary);
      expect(after, isNot(before));
      expect(frame.value.range, isNot(range));
      await gesture.up();
    },
  );

  testWidgets(
    'RED MYH-10: MonthCards scroll while the footer stays fixed and interactive',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final scrollController = ScrollController();
      addTearDown(frame.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 360,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: MindYearHeatmapViewport(
                      frameListenable: frame,
                      scrollController: scrollController,
                    ),
                  ),
                  SizedBox(
                    key: const ValueKey('mind-year-heatmap-fixed-footer'),
                    height: 74,
                    child: QueryAmountRangeControl(
                      values: range,
                      presentation: QueryAmountRangePresentation.compactMind,
                      onRangeCommitted: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final footerBefore = tester.getRect(
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
      );
      await tester.drag(
        find.byKey(const ValueKey('mind-year-heatmap-scroll')),
        const Offset(0, -180),
      );
      await tester.pump();

      expect(scrollController.offset, greaterThan(0));
      expect(
        tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        ),
        footerBefore,
      );
      expect(
        find.byKey(const ValueKey('query-amount-range-slider')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RED MYH-12: a range frame repaints tiles without replacing static grid chrome',
    (tester) async {
      final projection = _projection();
      final frame = ValueNotifier(projection.preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 480,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );
      final gridBefore = tester.widget<GridView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      final januaryBefore = tester.widget<MindYearHeatmapMonthCard>(
        find.byType(MindYearHeatmapMonthCard).first,
      );
      frame.value = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 1,
          maximumScaled100: 1000,
          lowerScaled100: 500,
          upperScaled100: 1000,
        ),
      );
      await tester.pump();

      expect(
        tester.widget<GridView>(
          find.byKey(const ValueKey('mind-year-heatmap-grid')),
        ),
        same(gridBefore),
      );
      expect(
        tester.widget<MindYearHeatmapMonthCard>(
          find.byType(MindYearHeatmapMonthCard).first,
        ),
        same(januaryBefore),
      );
    },
  );

  testWidgets(
    'RED MYH-18: a month preview uses one paint field instead of day widgets',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 480,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('mind-year-heatmap-month-1')),
          matching: find.byType(GridView),
        ),
        findsNothing,
      );
      expect(find.byType(CustomPaint), findsWidgets);
    },
  );
}

MindYearHeatmapProjection _projection() => MindYearHeatmapProjection.build(
  identity: const MindYearHeatmapIdentity(
    upstreamScopeKey: 'expense|year:2025',
    indexGeneration: 1,
    coreRevision: 1,
    year: 2025,
    navigationEpoch: 1,
  ),
  entries: <DashboardLedgerEntry>[
    _entry('a', 100, const LocalDate(year: 2025, month: 1, day: 2)),
    _entry('b', 900, const LocalDate(year: 2025, month: 9, day: 2)),
  ],
);

DashboardLedgerEntry _entry(String id, int amount, LocalDate date) =>
    DashboardLedgerEntry(
      id: id,
      partnerId: 'p',
      categoryId: 'c',
      direction: 'expense',
      amountMinor: amount,
      bookedLocalEpochDay: date.epochDay,
      bookedLocalTimeMinutes: 0,
    );
