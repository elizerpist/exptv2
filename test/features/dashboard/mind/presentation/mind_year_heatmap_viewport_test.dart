import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_aggregate_line_chart.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  const range = QueryAmountRangeValues(
    minimumScaled100: 100000,
    maximumScaled100: 1000000,
    lowerScaled100: 100000,
    upperScaled100: 1000000,
  );

  testWidgets(
    'RED MYHR-04/05: 12 compact MonthCards form four calendar-driven annual rows',
    (tester) async {
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
      final grid = tester.widget<ListView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      expect(grid.childrenDelegate.estimatedChildCount, isNotNull);
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-annual-row-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-annual-row-3')),
        findsOneWidget,
      );
      expect(find.byType(MindYearHeatmapMonthCard), findsNWidgets(12));
      expect(find.text('szeptember'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'YEAR-BAR-01/02/03 RED: a Year frame exposes twelve full-versus-filtered directional bars and a zero-based nice scale',
    () {
      final aggregates =
          MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
            year: 2025,
            incomeEntries: <DashboardLedgerEntry>[
              _directionEntry(
                'income-jan',
                300000,
                const LocalDate(year: 2025, month: 1, day: 2),
                'income',
              ),
              _directionEntry(
                'income-feb',
                700000,
                const LocalDate(year: 2025, month: 2, day: 2),
                'income',
              ),
            ],
            expenseEntries: <DashboardLedgerEntry>[
              _entry(
                'expense-jan-full',
                1000000,
                const LocalDate(year: 2025, month: 1, day: 2),
              ),
              _entry(
                'expense-feb-full',
                5000000,
                const LocalDate(year: 2025, month: 2, day: 2),
              ),
            ],
          );
      final expense = MindYearHeatmapProjection.build(
        identity: const MindYearHeatmapIdentity(
          upstreamScopeKey: 'expense|category:food|year:2025',
          indexGeneration: 1,
          coreRevision: 1,
          year: 2025,
          navigationEpoch: 1,
        ),
        entries: <DashboardLedgerEntry>[
          _entry(
            'food-jan',
            400000,
            const LocalDate(year: 2025, month: 1, day: 3),
          ),
          _entry(
            'food-feb',
            1000000,
            const LocalDate(year: 2025, month: 2, day: 3),
          ),
        ],
        monthlyAggregates: aggregates,
      ).preview(range);

      final expenseBars = MindYearHeatmapPartialBarSeries.fromFrame(expense);
      expect(expenseBars.values, hasLength(12));
      expect(expenseBars.values[0].fullAmount, 1000000);
      expect(expenseBars.values[0].filteredAmount, 400000);
      expect(expenseBars.values[1].fullAmount, 5000000);
      expect(expenseBars.values[1].filteredAmount, 1000000);
      expect(expenseBars.values[2].fullAmount, 0);
      expect(expenseBars.values[2].filteredAmount, 0);
      expect(expenseBars.scale.levels.first, 0);
      expect(expenseBars.scale.top, greaterThanOrEqualTo(5000000));

      final income = MindYearHeatmapProjection.build(
        identity: const MindYearHeatmapIdentity(
          upstreamScopeKey: 'income|partner:salary|year:2025',
          indexGeneration: 1,
          coreRevision: 2,
          year: 2025,
          navigationEpoch: 2,
        ),
        entries: <DashboardLedgerEntry>[
          _directionEntry(
            'salary-jan',
            300000,
            const LocalDate(year: 2025, month: 1, day: 3),
            'income',
          ),
          _directionEntry(
            'salary-feb',
            200000,
            const LocalDate(year: 2025, month: 2, day: 3),
            'income',
          ),
        ],
        monthlyAggregates: aggregates,
      ).preview(range);
      final incomeBars = MindYearHeatmapPartialBarSeries.fromFrame(income);
      expect(incomeBars.values[0].fullAmount, 300000);
      expect(incomeBars.values[0].filteredAmount, 300000);
      expect(incomeBars.values[1].fullAmount, 700000);
      expect(incomeBars.values[1].filteredAmount, 200000);
    },
  );

  testWidgets(
    'YEAR-BAR-04 RED: the annual heatmap and partial-bar pages share one frame and leave the Year scroll on page zero',
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
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      final admitted = frame.value;
      final pager = find.byKey(
        const ValueKey<String>('mind-year-heatmap-pager'),
      );
      expect(pager, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-page-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-grid')),
        findsOneWidget,
      );

      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-page-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-partial-bar-chart')),
        findsOneWidget,
      );
      expect(frame.value, same(admitted));
      expect(find.text('J'), findsNWidgets(3));
      expect(find.text('D'), findsOneWidget);

      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-page-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-monthly-line-chart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-aggregate-line-plot')),
        findsOneWidget,
      );
      final monthlyChart = tester.widget<MindAggregateLineChart>(
        find.byKey(const ValueKey('mind-year-monthly-line-chart')),
      );
      expect(monthlyChart.points, hasLength(12));
      expect(monthlyChart.points.first.total, 100000);
      expect(monthlyChart.points[8].total, 900000);
      final yearlyLineScroll = find.byKey(
        const ValueKey('mind-aggregate-line-scroll'),
      );
      final yearlyLinePosition = tester.state<ScrollableState>(
        find.descendant(
          of: yearlyLineScroll,
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        yearlyLinePosition.position.maxScrollExtent,
        0,
        reason:
            'All twelve selected-year month anchors must fit this card without a horizontal scroll domain.',
      );
      final pageRect = tester.getRect(
        find.byKey(const ValueKey('mind-year-heatmap-page-2')),
      );
      final plotRect = tester.getRect(
        find.byKey(const ValueKey('mind-aggregate-line-plot')),
      );
      expect(
        plotRect.height,
        greaterThan(pageRect.height * .55),
        reason:
            'The line plot must use the available Year card height rather than float inside a shallow box.',
      );
      await tester.tapAt(
        tester.getCenter(
          find.byKey(const ValueKey<String>('mind-aggregate-line-plot')),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-aggregate-line-infocard')),
        findsOneWidget,
      );
      expect(find.textContaining('2025.'), findsOneWidget);
      expect(frame.value, same(admitted));

      await tester.drag(pager, const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.drag(pager, const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-page-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-grid')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'YEAR-BAR-05: the secondary page consumes the current range-preview frame without a second Query path',
    (tester) async {
      final aggregates =
          MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
            year: 2025,
            incomeEntries: const <DashboardLedgerEntry>[],
            expenseEntries: <DashboardLedgerEntry>[
              _entry(
                'full-jan',
                600000,
                const LocalDate(year: 2025, month: 1, day: 2),
              ),
            ],
          );
      final projection = MindYearHeatmapProjection.build(
        identity: const MindYearHeatmapIdentity(
          upstreamScopeKey: 'expense|category:food|year:2025',
          indexGeneration: 1,
          coreRevision: 1,
          year: 2025,
          navigationEpoch: 1,
        ),
        entries: <DashboardLedgerEntry>[
          _entry(
            'food-low',
            100000,
            const LocalDate(year: 2025, month: 1, day: 3),
          ),
          _entry(
            'food-high',
            500000,
            const LocalDate(year: 2025, month: 1, day: 4),
          ),
        ],
        monthlyAggregates: aggregates,
      );
      final frame = ValueNotifier(projection.preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );
      final pager = find.byKey(
        const ValueKey<String>('mind-year-heatmap-pager'),
      );
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-page-1')),
        findsOneWidget,
      );
      MindYearHeatmapPartialBarPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey<String>('mind-year-partial-bar-chart'),
                    ),
                  )
                  .painter!
              as MindYearHeatmapPartialBarPainter;
      expect(painter().series.values.first.filteredAmount, 600000);

      frame.value = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 1000000,
          lowerScaled100: 450000,
          upperScaled100: 1000000,
        ),
      );
      await tester.pump();
      expect(painter().series.values.first.fullAmount, 600000);
      expect(painter().series.values.first.filteredAmount, 500000);
    },
  );

  testWidgets(
    'YEAR-LINE-01: the third card reads current filtered month totals from the same range-preview frame',
    (tester) async {
      final projection = MindYearHeatmapProjection.build(
        identity: const MindYearHeatmapIdentity(
          upstreamScopeKey: 'expense|category:food|year:2025',
          indexGeneration: 1,
          coreRevision: 1,
          year: 2025,
          navigationEpoch: 1,
        ),
        entries: <DashboardLedgerEntry>[
          _entry('low', 100000, const LocalDate(year: 2025, month: 1, day: 3)),
          _entry('high', 500000, const LocalDate(year: 2025, month: 1, day: 4)),
        ],
      );
      final frame = ValueNotifier(projection.preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );
      final pager = find.byKey(
        const ValueKey<String>('mind-year-heatmap-pager'),
      );
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();
      MindAggregateLineChart chart() => tester.widget<MindAggregateLineChart>(
        find.byKey(const ValueKey('mind-year-monthly-line-chart')),
      );
      expect(chart().points.first.total, 600000);

      frame.value = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 1000000,
          lowerScaled100: 450000,
          upperScaled100: 1000000,
        ),
      );
      await tester.pump();
      expect(chart().points.first.total, 500000);
    },
  );

  testWidgets(
    'RED YEAR-6R-01: every Year MonthCard reserves the same six-row envelope',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      final january = tester.getSize(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
      );
      final march = tester.getSize(
        find.byKey(const ValueKey('mind-year-heatmap-month-3')),
      );
      expect(
        january.height,
        closeTo(march.height, .001),
        reason:
            'A five-real-row month reserves the same sixth display row as a '
            'six-real-row month; only real dates are painted.',
      );
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-01/02: MonthCards are no longer tap targets and a colored day owns the bounded infocard',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-tap-1')),
        findsNothing,
      );
      final day = find.byKey(
        const ValueKey('mind-year-heatmap-day-tap-2025-1-2'),
      );
      expect(day, findsOneWidget);
      await tester.tap(day);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsOneWidget,
      );
      expect(find.textContaining('2025.'), findsOneWidget);
      expect(find.textContaining('1 000 Ft'), findsOneWidget);
      final dismiss = find.byKey(
        const ValueKey('mind-year-day-infocard-dismiss'),
      );
      expect(dismiss, findsOneWidget);
      await tester.tap(dismiss);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
        reason: 'An anchored popup retains an explicit accessible dismissal.',
      );
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-03: a Year scroll drag never becomes a colored-day inspection tap',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      final scrollController = ScrollController();
      addTearDown(frame.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 180,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
        const Offset(0, -100),
      );
      await tester.pump();

      expect(scrollController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
        reason: 'The tap observer must not enter the Scrollable gesture arena.',
      );
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-ANCHOR-01: day infocards follow their actual colored cells instead of a fixed annual origin',
    (tester) async {
      final frame = ValueNotifier(
        _inspectionProjection(includeSeptemberDay: true).preview(range),
      );
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      final januaryDay = find.byKey(
        const ValueKey('mind-year-heatmap-day-tap-2025-1-2'),
      );
      await tester.tap(januaryDay);
      await tester.pump();
      final januaryPopup = tester.getRect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
      );
      expect(
        (januaryPopup.center.dx - tester.getRect(januaryDay).center.dx).abs(),
        lessThan(100),
      );

      final septemberDay = find.byKey(
        const ValueKey('mind-year-heatmap-day-tap-2025-9-2'),
      );
      await tester.tap(septemberDay);
      await tester.pump();
      final septemberPopup = tester.getRect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
      );
      expect(septemberPopup.center.dx, greaterThan(januaryPopup.center.dx));
      expect(
        (septemberPopup.center.dx - tester.getRect(septemberDay).center.dx)
            .abs(),
        lessThan(100),
      );
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-04/05: a same-Year day selection retains current frame identity and clears before another Year paints',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsOneWidget,
      );

      frame.value = _inspectionProjection(
        upstreamScopeKey: 'income|year:2025',
        coreRevision: 2,
      ).preview(range);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsOneWidget,
      );

      frame.value = _inspectionProjection(
        year: 2026,
        upstreamScopeKey: 'income|year:2026',
        coreRevision: 3,
      ).preview(range);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
      // QueryAmountRangeControl intentionally crosses its display-frame
      // coalescing boundary before publishing a hot-path preview. The thumb
      // remains held here; this second frame proves the live preview rather
      // than waiting for its terminal commit.
      await tester.pump();

      final after = monthPainter().colorForDate(secondJanuary);
      expect(frame.value.range, isNot(range));
      expect(after, isNot(before));
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
      final gridBefore = tester.widget<ListView>(
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
        tester.widget<ListView>(
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

  testWidgets(
    'RED YEAR-6R-02/03/04: January 2025 preserves real slots while its reserved sixth row stays unpainted',
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

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey('mind-year-heatmap-month-cells-1'),
                    ),
                  )
                  .painter!
              as MindYearHeatmapMonthPainter;
      expect(
        painter.slotIndexForDate(const LocalDate(year: 2025, month: 1, day: 1)),
        2,
      );
      expect(
        painter.slotIndexForDate(
          const LocalDate(year: 2025, month: 1, day: 31),
        ),
        32,
      );
      expect(painter.dayAtSlot(0), isNull);
      expect(painter.dayAtSlot(1), isNull);
      expect(painter.dayAtSlot(2), 1);
      // January 2025 uses five real calendar rows. The sixth display row is
      // owned by the card envelope, not the calendar painter: its geometry
      // has no slots there at all, so it cannot render fake no-data cells.
      expect(painter.geometry.rowCount, 5);
      expect(painter.geometry.slotCount, 35);
      expect(MindYearHeatmapMonthCard.displayCalendarRowCount, 6);
      expect(
        painter.colorForDate(const LocalDate(year: 2025, month: 1, day: 1)),
        FluviVisualTokens.mindHeatmapEmpty,
      );
      expect(
        painter.colorForDate(const LocalDate(year: 2025, month: 1, day: 2)),
        isNot(FluviVisualTokens.mindHeatmapEmpty),
      );

      final monthCard = tester.getSize(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
      );
      final cells = tester.getSize(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
      );
      expect(monthCard.height - cells.height, lessThanOrEqualTo(32));
    },
  );

  testWidgets(
    'RED MYHR-09: viewport logs one bounded geometry and paint summary per identity',
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
      await tester.pump();

      List<String> heatmapStages() => FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .where((stage) => stage.startsWith('MIND_HEATMAP|'))
          .toList(growable: false);

      expect(
        heatmapStages(),
        containsAll(<String>[
          'MIND_HEATMAP|CALENDAR_GEOMETRY',
          'MIND_HEATMAP|DIRECTION_VISIBLE',
          'MIND_HEATMAP|PAINTED',
        ]),
      );
      expect(
        heatmapStages().length,
        3,
        reason: 'There is no day-cell or pixel diagnostic fan-out.',
      );
      final calendar = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'MIND_HEATMAP|CALENDAR_GEOMETRY',
      );
      expect(calendar.scope, contains('columns=7'));
      expect(calendar.scope, contains('weekdayOrder=monday-sunday'));
      expect(calendar.scope, isNot(contains('partner')));
      expect(calendar.scope, isNot(contains('category')));

      frame.value = _projection().preview(
        const QueryAmountRangeValues(
          minimumScaled100: 1,
          maximumScaled100: 1000,
          lowerScaled100: 500,
          upperScaled100: 1000,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        heatmapStages().length,
        3,
        reason: 'Amount-only preview does not add a paint-log storm.',
      );
    },
  );

  testWidgets(
    'HMP-06/08 two-column layout fills width and keeps one scroll owner',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.b3mMy3,
          monthCardLayout: MindYearMonthCardLayout.twoColumns,
          showMonthlyNetClose: false,
          showMonthlyDirectionTotal: false,
          revision: 0,
        ),
      );
      final scrollController = ScrollController();
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      final grid = tester.widget<ListView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      // ListView.separated contributes one separator between each annual row.
      expect(grid.childrenDelegate.estimatedChildCount, 11);
      // The fixed six-row envelope deliberately makes each two-card row
      // taller than the former variable-height card. The one ListView still
      // structurally owns all six rows (estimatedChildCount == 11 above),
      // while this constrained viewport only has to build its first three.
      expect(find.byType(MindYearHeatmapMonthCard), findsAtLeastNWidgets(6));
      final twoColumnWidth = tester
          .getSize(find.byKey(const ValueKey('mind-year-heatmap-month-1')))
          .width;
      expect(twoColumnWidth, greaterThan(150));

      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      settings.setMonthCardLayout(MindYearMonthCardLayout.threeColumns);
      await tester.pump();
      await tester.pump();
      final threeColumnWidth = tester
          .getSize(find.byKey(const ValueKey('mind-year-heatmap-month-1')))
          .width;
      expect(threeColumnWidth, lessThan(twoColumnWidth));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsOneWidget,
      );
      expect(
        identical(
          tester
              .widget<ListView>(
                find.byKey(const ValueKey('mind-year-heatmap-grid')),
              )
              .controller,
          scrollController,
        ),
        isTrue,
      );
      expect(
        scrollController.offset,
        lessThanOrEqualTo(scrollController.position.maxScrollExtent),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HMP-05 palette switching repaints from the same frame identity',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController();
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 480,
            child: MindYearHeatmapViewport(
              frameListenable: frame,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      final painterFinder = find.byKey(
        const ValueKey('mind-year-heatmap-month-cells-1'),
      );
      Color color() =>
          (tester.widget<CustomPaint>(painterFinder).painter!
                  as MindYearHeatmapMonthPainter)
              .colorForDate(const LocalDate(year: 2025, month: 1, day: 2));
      final identity = frame.value.identity;
      final fluvi = color();

      expect(
        (tester.widget<CustomPaint>(painterFinder).painter!
                as MindYearHeatmapMonthPainter)
            .scaleResolution,
        MindHeatmapScaleResolution.ten,
      );

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      await tester.pump();

      expect(frame.value.identity, identity);
      expect(color(), isNot(fluvi));

      settings.setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();

      expect(frame.value.identity, identity);
      expect(
        (tester.widget<CustomPaint>(painterFinder).painter!
                as MindYearHeatmapMonthPainter)
            .scaleResolution,
        MindHeatmapScaleResolution.twenty,
      );
    },
  );

  testWidgets(
    'RED YEAR-SURFACE-01: direct annual cells use the same frame without a muted MonthCard shell',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.threeColumns,
          showMonthlyNetClose: false,
          showMonthlyDirectionTotal: false,
          annualSurfaceStyle: MindYearHeatmapAnnualSurfaceStyle.directCells,
          revision: 0,
        ),
      );
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 500,
            child: MindYearHeatmapViewport(
              frameListenable: frame,
              presentationSettings: settings,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-direct-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
      );
      expect(frame.value.identity.year, 2025);
    },
  );

  testWidgets('HMP-09/12 MonthCard footers use admitted full-month totals', (
    tester,
  ) async {
    final noFooterHeight = MindYearHeatmapMonthCard.heightFor(
      width: 100,
      calendarRowCount: 5,
    );
    final oneFooterHeight = MindYearHeatmapMonthCard.heightFor(
      width: 100,
      calendarRowCount: 5,
      footerRowCount: 1,
    );
    final bothFooterHeight = MindYearHeatmapMonthCard.heightFor(
      width: 100,
      calendarRowCount: 5,
      footerRowCount: 2,
    );
    expect(oneFooterHeight, greaterThan(noFooterHeight));
    expect(bothFooterHeight, greaterThan(oneFooterHeight));
    final aggregates = MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
      year: 2025,
      incomeEntries: <DashboardLedgerEntry>[
        DashboardLedgerEntry(
          id: 'income',
          partnerId: 'salary',
          categoryId: 'income',
          direction: 'income',
          amountMinor: 500000,
          bookedLocalEpochDay: const LocalDate(
            year: 2025,
            month: 1,
            day: 1,
          ).epochDay,
          bookedLocalTimeMinutes: 0,
        ),
      ],
      expenseEntries: <DashboardLedgerEntry>[
        _entry(
          'expense',
          120000,
          const LocalDate(year: 2025, month: 1, day: 2),
        ),
      ],
    );
    final projection = MindYearHeatmapProjection.build(
      identity: const MindYearHeatmapIdentity(
        upstreamScopeKey: 'expense|year:2025',
        indexGeneration: 1,
        coreRevision: 1,
        year: 2025,
        navigationEpoch: 1,
      ),
      entries: <DashboardLedgerEntry>[
        _entry(
          'focused',
          100000,
          const LocalDate(year: 2025, month: 1, day: 2),
        ),
      ],
      monthlyAggregates: aggregates,
    );
    final frame = ValueNotifier(projection.preview(range));
    final settings = MindYearHeatmapPresentationController(
      initial: const MindYearHeatmapPresentationSettings(
        paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
        monthCardLayout: MindYearMonthCardLayout.threeColumns,
        showMonthlyNetClose: true,
        showMonthlyDirectionTotal: true,
        revision: 0,
      ),
    );
    addTearDown(frame.dispose);
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 500,
          child: MindYearHeatmapViewport(
            frameListenable: frame,
            presentationSettings: settings,
          ),
        ),
      ),
    );
    expect(find.text('Zárás'), findsAtLeastNWidgets(1));
    expect(find.text('Kiadás'), findsAtLeastNWidgets(1));
    expect(find.text('3 800 Ft'), findsAtLeastNWidgets(1));
    expect(find.text('1 200 Ft'), findsAtLeastNWidgets(1));

    final incomeProjection = MindYearHeatmapProjection.build(
      identity: const MindYearHeatmapIdentity(
        upstreamScopeKey: 'income|year:2025',
        indexGeneration: 1,
        coreRevision: 2,
        year: 2025,
        navigationEpoch: 2,
      ),
      entries: const <DashboardLedgerEntry>[],
      monthlyAggregates: aggregates,
    );
    frame.value = incomeProjection.preview(range);
    await tester.pump();
    expect(find.text('Bevétel'), findsAtLeastNWidgets(1));
    expect(find.text('5 000 Ft'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'RED H43-01/04: four-column Year mode solves one non-scrolling 4 × 3 viewport including both footer rows',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: true,
          showMonthlyDirectionTotal: true,
          revision: 0,
        ),
      );
      final scrollController = ScrollController();
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MindYearHeatmapMonthCard), findsNWidgets(12));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-annual-row-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-annual-row-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-annual-row-3')),
        findsNothing,
      );
      expect(scrollController.hasClients, isTrue);
      expect(scrollController.position.maxScrollExtent, 0);
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MindYearHeatmapMonthCard),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
        reason:
            'Only the single viewport owner may exist; MonthCards never scroll.',
      );
      final january = tester.widget<MindYearHeatmapMonthCard>(
        find.byType(MindYearHeatmapMonthCard).first,
      );
      final april = tester.widget<MindYearHeatmapMonthCard>(
        find.byType(MindYearHeatmapMonthCard).at(3),
      );
      expect(january.width, closeTo(april.width, .001));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('mind-year-heatmap-month-12')))
            .bottom,
        lessThanOrEqualTo(
          tester
              .getRect(
                find.byKey(const ValueKey('mind-year-heatmap-fit-scroll')),
              )
              .bottom,
        ),
      );

      // The solver accounts for every optional footer configuration. Each
      // setting still consumes the same one viewport controller and keeps the
      // annual content physically within its finite bounds.
      final sameController = scrollController;
      for (final (showNet, showDirection) in <(bool, bool)>[
        (true, false),
        (false, true),
        (false, false),
      ]) {
        settings.setShowMonthlyNetClose(showNet);
        settings.setShowMonthlyDirectionTotal(showDirection);
        await tester.pump();
        expect(scrollController, same(sameController));
        expect(scrollController.position.maxScrollExtent, 0);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('mind-year-heatmap-month-12')))
              .bottom,
          lessThanOrEqualTo(
            tester
                .getRect(
                  find.byKey(const ValueKey('mind-year-heatmap-fit-scroll')),
                )
                .bottom,
          ),
        );
        expect(tester.takeException(), isNull);
      }

      // Changing the presentation back to a scrolling layout and then to the
      // fit layout preserves the one controller object; no new scroll owner
      // is introduced for 4 × 3.
      settings.setMonthCardLayout(MindYearMonthCardLayout.threeColumns);
      await tester.pump();
      expect(scrollController, same(sameController));
      settings.setMonthCardLayout(MindYearMonthCardLayout.fourColumns);
      await tester.pump();
      expect(scrollController, same(sameController));
      expect(scrollController.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-06: four-column colored-day inspection stays inside the annual card at supported mobile widths',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: true,
          showMonthlyDirectionTotal: true,
          revision: 0,
        ),
      );
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);

      for (final width in <double>[360, 390, 412, 430]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                height: 420,
                child: MindYearHeatmapViewport(
                  key: ValueKey<String>('mind-year-info-width-$width'),
                  frameListenable: frame,
                  presentationSettings: settings,
                ),
              ),
            ),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
        );
        await tester.pump();
        final info = tester.getRect(
          find.byKey(const ValueKey('mind-year-day-infocard')),
        );
        final page = tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-page-0')),
        );
        expect(info.width, greaterThan(0));
        expect(info.height, greaterThan(0));
        expect(page.contains(info.topLeft), isTrue);
        expect(
          page.contains(info.bottomRight - const Offset(.01, .01)),
          isTrue,
        );
        expect(tester.takeException(), isNull, reason: 'width=$width');
      }
    },
  );

  testWidgets(
    'YEAR-SURFACE-02: direct four-column annual groups retain zero-scroll fit without MonthCard shells',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.b3mMy3,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: true,
          showMonthlyDirectionTotal: true,
          annualSurfaceStyle: MindYearHeatmapAnnualSurfaceStyle.directCells,
          revision: 0,
        ),
      );
      final scrollController = ScrollController();
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );
      expect(scrollController.position.maxScrollExtent, 0);
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-direct-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
        findsNothing,
      );
      expect(find.byType(MindYearHeatmapMonthCard), findsNWidgets(12));
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
    _entry('a', 100000, const LocalDate(year: 2025, month: 1, day: 2)),
    _entry('b', 900000, const LocalDate(year: 2025, month: 9, day: 2)),
  ],
);

MindYearHeatmapProjection _inspectionProjection({
  int year = 2025,
  String upstreamScopeKey = 'expense|year:2025',
  int coreRevision = 1,
  bool includeSeptemberDay = false,
}) => MindYearHeatmapProjection.build(
  identity: MindYearHeatmapIdentity(
    upstreamScopeKey: upstreamScopeKey,
    indexGeneration: 1,
    coreRevision: coreRevision,
    year: year,
    navigationEpoch: 1,
  ),
  entries: <DashboardLedgerEntry>[
    _entry('a', 100000, LocalDate(year: year, month: 1, day: 2)),
    if (includeSeptemberDay)
      _entry('september', 200000, LocalDate(year: year, month: 9, day: 2)),
  ],
  monthlyAggregates: MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
    year: year,
    incomeEntries: <DashboardLedgerEntry>[
      _entry('income', 500000, LocalDate(year: year, month: 1, day: 2)),
    ],
    expenseEntries: <DashboardLedgerEntry>[
      _entry('expense', 120000, LocalDate(year: year, month: 1, day: 3)),
    ],
  ),
  scopedMonthlyAggregates:
      MindYearHeatmapScopedMonthlyAggregates.fromPreparedContributions(
        year: year,
        contributions: <MindYearHeatmapPreparedContribution>[
          MindYearHeatmapPreparedContribution(
            ordinal: 0,
            bookedLocalEpochDay: LocalDate(
              year: year,
              month: 1,
              day: 2,
            ).epochDay,
            amountMinor: 100000,
          ),
          if (includeSeptemberDay)
            MindYearHeatmapPreparedContribution(
              ordinal: 1,
              bookedLocalEpochDay: LocalDate(
                year: year,
                month: 9,
                day: 2,
              ).epochDay,
              amountMinor: 200000,
            ),
        ],
      ),
  inspectionScope: const MindYearHeatmapInspectionScope(
    facets: <MindYearHeatmapInspectionFacet>[
      MindYearHeatmapInspectionFacet(
        kind: MindYearHeatmapInspectionFacetKind.category,
        id: 'food',
        displayName: 'Étel',
        colorId: 'orange',
        iconId: 'fork',
      ),
    ],
  ),
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

DashboardLedgerEntry _directionEntry(
  String id,
  int amount,
  LocalDate date,
  String direction,
) => DashboardLedgerEntry(
  id: id,
  partnerId: 'p',
  categoryId: 'c',
  direction: direction,
  amountMinor: amount,
  bookedLocalEpochDay: date.epochDay,
  bookedLocalTimeMinutes: 0,
);
