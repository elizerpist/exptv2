import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_calendar_geometry.dart';
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
    'MY-AMOUNT-RED-01: a Year day cell never exposes the retired detail popup',
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
        find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
        findsNothing,
        reason: 'Year day detail inspection is retired in every amount mode.',
      );
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'RED MYHR-04/05: 12 compact MonthCards form four calendar-driven annual rows',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
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
      expect(find.byType(MindYearHeatmapMonthGroup), findsNWidgets(12));
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
        find.byKey(const ValueKey('mind-year-direct-month-1')),
      );
      final march = tester.getSize(
        find.byKey(const ValueKey('mind-year-direct-month-3')),
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
    'YEAR-AMOUNT-MODES-01: hidden, inline and veil retire day popups without changing resident cells',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      final settings = MindYearHeatmapPresentationController()
        ..setYearMonthlyAmountPresentation(
          MindYearMonthlyAmountPresentation.hidden,
        );
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-year-month-scope-total-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
      );

      settings.setYearMonthlyAmountPresentation(
        MindYearMonthlyAmountPresentation.inline,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-month-scope-total-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
      );

      settings.setYearMonthlyAmountPresentation(
        MindYearMonthlyAmountPresentation.veil,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-month-scope-total-1')),
        findsNothing,
      );
      final month = find.byKey(const ValueKey('mind-year-heatmap-month-tap-1'));
      expect(month, findsOneWidget);
      await tester.tap(month);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
        findsOneWidget,
      );
      for (var index = 1; index <= 12; index += 1) {
        expect(
          find.byKey(
            ValueKey<String>('mind-year-monthly-amount-veil-total-$index'),
          ),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-03: retired day inspection leaves the existing Year scroll owner intact',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      final scrollController = ScrollController();
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(scrollController.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 180,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );
      await tester.drag(
        find.byKey(const ValueKey('mind-year-direct-month-1')),
        const Offset(0, -100),
      );
      await tester.pump();

      expect(scrollController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
        reason: 'No removed per-day listener may enter the Scrollable arena.',
      );
    },
  );

  testWidgets(
    'YEAR-VEIL-01: one month trigger opens an annual overlay without a per-day popup',
    (tester) async {
      final frame = ValueNotifier(
        _inspectionProjection(includeSeptemberDay: true).preview(range),
      );
      final settings = MindYearHeatmapPresentationController()
        ..setYearMonthlyAmountPresentation(
          MindYearMonthlyAmountPresentation.veil,
        );
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('mind-year-heatmap-month-tap-1')),
      );
      await tester.pump();
      final veil = find.byKey(const ValueKey('mind-year-monthly-amount-veil'));
      expect(veil, findsOneWidget);
      expect(
        tester.getRect(veil),
        tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-fit-scroll')),
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-year-day-infocard')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'YEAR-VEIL-02: a new Year frame closes its open annual amount veil',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      final settings = MindYearHeatmapPresentationController()
        ..setYearMonthlyAmountPresentation(
          MindYearMonthlyAmountPresentation.veil,
        );
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('mind-year-heatmap-month-tap-1')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
        findsOneWidget,
      );

      frame.value = _inspectionProjection(
        year: 2026,
        upstreamScopeKey: 'income|year:2026',
        coreRevision: 3,
      ).preview(range);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-monthly-amount-veil')),
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
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(scrollController.dispose);
      addTearDown(settings.dispose);

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
                      presentationSettings: settings,
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
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 480,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );
      final gridBefore = tester.widget<ListView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      final januaryBefore = tester.widget<MindYearHeatmapMonthGroup>(
        find.byType(MindYearHeatmapMonthGroup).first,
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
        tester.widget<MindYearHeatmapMonthGroup>(
          find.byType(MindYearHeatmapMonthGroup).first,
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
          of: find.byKey(const ValueKey('mind-year-direct-month-1')),
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
      expect(MindYearHeatmapMonthGroup.displayCalendarRowCount, 6);
      expect(
        painter.colorForDate(const LocalDate(year: 2025, month: 1, day: 1)),
        FluviVisualTokens.mindHeatmapEmpty,
      );
      expect(
        painter.colorForDate(const LocalDate(year: 2025, month: 1, day: 2)),
        isNot(FluviVisualTokens.mindHeatmapEmpty),
      );

      final monthCard = tester.getSize(
        find.byKey(const ValueKey('mind-year-direct-month-1')),
      );
      final cells = tester.getSize(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
      );
      expect(
        monthCard.height,
        greaterThan(cells.height),
        reason:
            'The direct annual group reserves only its title and 3x4 footer '
            'content; it no longer relies on a painted MonthCard surface.',
      );
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
    'YEAR-DIRECT-03: three-by-four direct groups retain one scroll owner',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final scrollController = ScrollController();
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(scrollController.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      final grid = tester.widget<ListView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      expect(grid.childrenDelegate.estimatedChildCount, 7);
      expect(find.byType(MindYearHeatmapMonthGroup), findsAtLeastNWidgets(6));
      final threeColumnWidth = tester
          .getSize(find.byKey(const ValueKey('mind-year-direct-month-1')))
          .width;
      expect(threeColumnWidth, greaterThan(80));

      scrollController.jumpTo(scrollController.position.maxScrollExtent);
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
    'YEAR-DIRECT-01: default annual cells use the same frame without a muted surface shell',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 500,
            child: MindYearHeatmapViewport(frameListenable: frame),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-year-direct-month-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
      );
      expect(frame.value.identity.year, 2025);
    },
  );

  testWidgets('MIND-SQ-03: three-by-four MonthCards reclaim both footer rows', (
    tester,
  ) async {
    final noFooterHeight = MindYearHeatmapMonthGroup.heightFor(
      width: 100,
      calendarRowCount: 5,
    );
    final bothFooterHeight = MindYearHeatmapMonthGroup.heightFor(
      width: 100,
      calendarRowCount: 5,
      footerRowCount: 2,
    );
    expect(bothFooterHeight, greaterThan(noFooterHeight));
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
    final settings = MindYearHeatmapPresentationController()
      ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
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
    expect(find.text('Zárás'), findsNothing);
    expect(find.text('Scope'), findsNothing);

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
    expect(find.text('Scope'), findsNothing);
  });

  testWidgets(
    'YEAR-DIRECT-05: four-by-three direct grid solves one non-scrolling viewport',
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
              height: 420,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(MindYearHeatmapMonthGroup), findsNWidgets(12));
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
      expect(scrollController.position.maxScrollExtent, closeTo(0, .001));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MindYearHeatmapMonthGroup),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
        reason:
            'Only the single viewport owner may exist; MonthCards never scroll.',
      );
      final january = tester.widget<MindYearHeatmapMonthGroup>(
        find.byType(MindYearHeatmapMonthGroup).first,
      );
      final april = tester.widget<MindYearHeatmapMonthGroup>(
        find.byType(MindYearHeatmapMonthGroup).at(3),
      );
      expect(january.width, closeTo(april.width, .001));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('mind-year-direct-month-12')))
            .bottom,
        closeTo(
          tester
              .getRect(
                find.byKey(const ValueKey('mind-year-heatmap-fit-scroll')),
              )
              .bottom,
          .5,
        ),
        reason:
            'The direct 4x3 field must fill its live annual viewport instead '
            'of leaving the width-limited square-cell gap at the bottom.',
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'YEAR-SETTINGS-ONLY-01: the Year content card never exposes layout pills',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 420,
            child: MindYearHeatmapViewport(frameListenable: frame),
          ),
        ),
      );

      for (final label in <String>['3×4', '4×3', '2×6']) {
        expect(find.text(label), findsNothing);
      }
    },
  );

  test(
    '4x3 fit derives independent live vertical cells without changing width',
    () {
      final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
        12,
        (index) => MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: index + 1,
        ),
        growable: false,
      );
      final fit = MindYearHeatmapFourColumnFit.resolve(
        viewportHeight: 390,
        cardWidth: 82,
        geometries: geometries,
        footerRowCount: 0,
        viewportTopPadding: 5,
        viewportBottomPadding: 0,
        rowGap: 4,
        compactChrome: true,
      );

      expect(fit.staticHeight, closeTo(88, .001));
      expect(fit.cellHeight, greaterThan(fit.cellWidth));
      expect(fit.extraHeightPerCell, closeTo(fit.verticalSurplus / 18, .0001));
      expect(fit.resolvedContentHeight, closeTo(fit.annualViewportHeight, .5));
    },
  );

  test(
    'MIND-SQ-02: square 4x3 cells preserve their calculated free region without a body selector',
    () {
      final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
        12,
        (index) => MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: index + 1,
        ),
        growable: false,
      );
      final fit = MindYearHeatmapFourColumnFit.resolve(
        viewportHeight: 530,
        cardWidth: 99.5,
        geometries: geometries,
        footerRowCount: 0,
        viewportTopPadding: 5,
        viewportBottomPadding: 0,
        rowGap: 4,
        compactChrome: true,
        style: MindYearFourColumnCellStyle.squareCells,
      );

      expect(fit.cellHeight, closeTo(fit.cellWidth, .0001));
      expect(fit.freeHeight, greaterThan(0));
      expect(fit.gridConsumedHeight, lessThan(fit.annualViewportHeight));
    },
  );

  test(
    'MIND-SQ-02: constrained square 4x3 retains its fixed day-cell geometry',
    () {
      final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
        12,
        (index) => MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: index + 1,
        ),
        growable: false,
      );
      final fit = MindYearHeatmapFourColumnFit.resolve(
        viewportHeight: 150,
        cardWidth: 82,
        geometries: geometries,
        footerRowCount: 0,
        viewportTopPadding: 5,
        viewportBottomPadding: 0,
        rowGap: 4,
        compactChrome: true,
        style: MindYearFourColumnCellStyle.squareCells,
      );

      expect(fit.cellHeight, closeTo(fit.cellWidth, .0001));
    },
  );

  testWidgets(
    'MIND-SQ-02: tall square 4x3 keeps the free region free of layout controls',
    (tester) async {
      final settings = MindYearHeatmapPresentationController()
        ..setFourColumnCellStyle(MindYearFourColumnCellStyle.squareCells);
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(settings.dispose);
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 560,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(find.text('3×4'), findsNothing);
      expect(find.text('4×3'), findsNothing);
      expect(find.text('2×6'), findsNothing);
    },
  );

  test(
    '4x3 physical-size seamless/stretched fixture fills the full annual field',
    () {
      final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
        12,
        (index) => MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: index + 1,
        ),
        growable: false,
      );
      // 430×560 is the focused production-size golden viewport. The 30px
      // in-card title/selector lane leaves 530px for the annual field.
      final fit = MindYearHeatmapFourColumnFit.resolve(
        viewportHeight: 530,
        cardWidth: 99.5,
        geometries: geometries,
        footerRowCount: 0,
        viewportTopPadding: 5,
        viewportBottomPadding: 0,
        rowGap: 4,
        compactChrome: true,
      );

      expect(fit.annualViewportHeight, 530);
      expect(fit.staticHeight, 88);
      expect(fit.cellWidth, closeTo(75.5 / 7, .001));
      expect(fit.squareConsumedHeight, closeTo(88 + 18 * (75.5 / 7), .001));
      expect(fit.verticalSurplus, closeTo(530 - (88 + 18 * (75.5 / 7)), .001));
      expect(
        fit.extraHeightPerCell,
        closeTo((530 - (88 + 18 * (75.5 / 7))) / 18, .001),
      );
      expect(fit.cellHeight, closeTo((530 - 88) / 18, .001));
      expect(fit.resolvedContentHeight, closeTo(530, .5));
    },
  );

  test(
    '4x3 painter exposes the same rectangle geometry that day hit targets use',
    () {
      final geometry = MindYearHeatmapCalendarGeometry.forMonth(
        year: 2025,
        month: 1,
      );
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);
      final painter = MindYearHeatmapMonthPainter(
        month: 1,
        geometry: geometry,
        frameListenable: frame,
        cellExtent: 10,
        cellHeight: 18,
      );

      final painted = painter.cellRectForSlot(
        geometry.slotIndexForDay(2),
        const Size(82, 120),
      );
      expect(painted.width, 10);
      expect(painted.height, 18);
      expect(painted.left, (geometry.slotIndexForDay(2) % 7) * (10 + 2));
      expect(painted.top, 0);
    },
  );

  testWidgets(
    '4x3 painted cells remain one paint field with no individual day hit targets',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 440,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      final paint = find.byKey(
        const ValueKey('mind-year-heatmap-month-cells-1'),
      );
      final painter =
          tester.widget<CustomPaint>(paint).painter!
              as MindYearHeatmapMonthPainter;
      expect(
        painter.slotIndexForDate(const LocalDate(year: 2025, month: 1, day: 2)),
        greaterThanOrEqualTo(0),
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
        findsNothing,
      );
    },
  );

  test(
    '4x3 fit contracts cell height in a short viewport without vertical overflow',
    () {
      final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
        12,
        (index) => MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: index + 1,
        ),
        growable: false,
      );
      final fit = MindYearHeatmapFourColumnFit.resolve(
        viewportHeight: 150,
        cardWidth: 82,
        geometries: geometries,
        footerRowCount: 0,
        viewportTopPadding: 5,
        viewportBottomPadding: 0,
        rowGap: 4,
        compactChrome: true,
      );

      expect(fit.cellHeight, lessThan(fit.cellWidth));
      expect(fit.cellHeight, greaterThanOrEqualTo(0));
      expect(fit.resolvedContentHeight, closeTo(fit.annualViewportHeight, .5));
    },
  );

  testWidgets(
    'YEAR-DAY-INFO-06: no retired day detail surface appears at supported mobile widths',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      addTearDown(frame.dispose);

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
                ),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('mind-year-heatmap-day-tap-2025-1-2')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('mind-year-day-infocard')),
          findsNothing,
        );
        expect(tester.takeException(), isNull, reason: 'width=$width');
      }
    },
  );

  testWidgets(
    'YEAR-DIRECT-06: direct four-by-three annual groups retain zero-scroll fit',
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
              height: 420,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );
      expect(scrollController.position.maxScrollExtent, closeTo(0, .001));
      expect(
        find.byKey(const ValueKey('mind-year-direct-month-1')),
        findsOneWidget,
      );
      expect(find.byType(MindYearHeatmapMonthGroup), findsNWidgets(12));
    },
  );

  testWidgets(
    'Y26-01/02/03/04/05: 2x6 renders card-only chrome, inline values and Month-style day numbers',
    (tester) async {
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.twoBySix);
      final frame = ValueNotifier(_inspectionProjection().preview(range));
      addTearDown(settings.dispose);
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindYearHeatmapViewport(
                frameListenable: frame,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MindYearHeatmapMonthGroup), findsAtLeastNWidgets(4));
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-scope-total-1')),
        findsOneWidget,
      );
      expect(
        find.text('Zárás'),
        findsNothing,
        reason:
            'Monthly amounts use the shared mini-header, never a second footer.',
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-year-heatmap-day-number-2025-1-1'),
        ),
        findsOneWidget,
      );
      final cellColorBefore =
          (tester
                      .widget<CustomPaint>(
                        find.byKey(
                          const ValueKey<String>(
                            'mind-year-heatmap-month-cells-1',
                          ),
                        ),
                      )
                      .painter!
                  as MindYearHeatmapMonthPainter)
              .colorForDate(const LocalDate(year: 2025, month: 1, day: 2));
      settings.setYearMonthCardBorderEnabled(false);
      settings.setYearMonthCardProfitabilityTintEnabled(true);
      settings.setYearMonthCardProfitabilityTintOpacity(.42);
      await tester.pump();
      final card = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-1')),
      );
      final decoration = card.decoration as BoxDecoration;
      expect(decoration.border, isNull);
      expect(decoration.color, isNot(FluviVisualTokens.surface));
      expect(
        (tester
                    .widget<CustomPaint>(
                      find.byKey(
                        const ValueKey<String>(
                          'mind-year-heatmap-month-cells-1',
                        ),
                      ),
                    )
                    .painter!
                as MindYearHeatmapMonthPainter)
            .colorForDate(const LocalDate(year: 2025, month: 1, day: 2)),
        cellColorBefore,
        reason: 'Card tint never reaches the heatmap palette authority.',
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('mind-year-heatmap-grid')),
        const Offset(0, -1000),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-12')),
        findsOneWidget,
        reason:
            'The sixth 2x6 row remains reachable through the sole vertical owner.',
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-annual-row-5')),
        findsOneWidget,
      );

      settings.setYearGridLayout(MindYearHeatmapGridLayout.fourByThree);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-1')),
        findsNothing,
        reason: 'Direct 4x3 never receives MonthCard chrome.',
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-year-heatmap-day-number-2025-1-1'),
        ),
        findsNothing,
        reason: 'Date labels are a 2x6 card-only treatment.',
      );
    },
  );

  testWidgets(
    'YEAR-DIRECT-01/02/04: fresh Year uses direct 4x3 without content selectors',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 440,
              child: MindYearHeatmapViewport(frameListenable: frame),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-year-direct-title')),
        findsOneWidget,
      );
      expect(find.text('3×4'), findsNothing);
      expect(find.text('4×3'), findsNothing);
      expect(find.text('2×6'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('mind-year-direct-month-1')),
        findsOneWidget,
      );
      expect(find.text('Scope'), findsNothing);
      expect(find.text('Zárás'), findsNothing);

      final annualScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('mind-year-heatmap-scroll'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(annualScroll.position.maxScrollExtent, closeTo(0, .001));
      expect(find.text('Scope'), findsNothing);
    },
  );

  testWidgets(
    'YEAR-PROFIT-01 RED: 3x4 keeps a rounded MonthCard surface while 4x3 remains untouched',
    (tester) async {
      final frame = ValueNotifier(_projection().preview(range));
      final settings = MindYearHeatmapPresentationController()
        ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 440,
            child: MindYearHeatmapViewport(
              frameListenable: frame,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-1')),
        findsOneWidget,
        reason: 'Every 3x4 month must remain inside its own rounded card.',
      );

      settings.setYearGridLayout(MindYearHeatmapGridLayout.fourByThree);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('mind-year-month-card-surface-1')),
        findsNothing,
        reason: 'Profitability MonthCards are strictly a 3x4 presentation.',
      );
    },
  );

  testWidgets(
    'YEAR-PROFIT-02/03/04: the 3x4 card tint uses only monthly net and its opacity leaves cells unchanged',
    (tester) async {
      final settings = MindYearHeatmapPresentationController();
      final aggregates =
          MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
            year: 2025,
            incomeEntries: <DashboardLedgerEntry>[
              _directionEntry(
                'income-jan',
                500000,
                const LocalDate(year: 2025, month: 1, day: 2),
                'income',
              ),
              _directionEntry(
                'income-feb',
                100000,
                const LocalDate(year: 2025, month: 2, day: 2),
                'income',
              ),
            ],
            expenseEntries: <DashboardLedgerEntry>[
              _entry(
                'expense-jan',
                100000,
                const LocalDate(year: 2025, month: 1, day: 3),
              ),
              _entry(
                'expense-feb',
                500000,
                const LocalDate(year: 2025, month: 2, day: 3),
              ),
            ],
          );
      final projection = MindYearHeatmapProjection.build(
        identity: const MindYearHeatmapIdentity(
          upstreamScopeKey: 'expense|year:2025',
          indexGeneration: 4,
          coreRevision: 6,
          year: 2025,
          navigationEpoch: 8,
        ),
        entries: <DashboardLedgerEntry>[
          _entry(
            'focused-jan',
            100000,
            const LocalDate(year: 2025, month: 1, day: 3),
          ),
          _entry(
            'focused-feb',
            500000,
            const LocalDate(year: 2025, month: 2, day: 3),
          ),
        ],
        monthlyAggregates: aggregates,
      );
      final frame = ValueNotifier(projection.preview(range));
      addTearDown(frame.dispose);
      addTearDown(settings.dispose);
      settings.setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 440,
            child: MindYearHeatmapViewport(
              frameListenable: frame,
              presentationSettings: settings,
            ),
          ),
        ),
      );

      BoxDecoration cardDecoration(int month) =>
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      ValueKey<String>('mind-year-month-card-surface-$month'),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final januaryPainter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey<String>('mind-year-heatmap-month-cells-1'),
                    ),
                  )
                  .painter!
              as MindYearHeatmapMonthPainter;
      final januaryCellBefore = januaryPainter.colorForDate(
        const LocalDate(year: 2025, month: 1, day: 3),
      );

      expect(cardDecoration(1).color, FluviVisualTokens.surface);
      expect(cardDecoration(2).color, FluviVisualTokens.surface);
      expect(cardDecoration(3).color, FluviVisualTokens.surface);

      settings
        ..setYearThreeColumnProfitabilityTintEnabled(true)
        ..setYearThreeColumnProfitabilityTintOpacity(.30);
      await tester.pump();

      expect(
        cardDecoration(1).color,
        mindYearThreeColumnMonthCardBackground(
          monthlyNetMinor: aggregates.netForMonth(1),
          profitabilityTintEnabled: true,
          tintOpacity: .30,
        ),
      );
      expect(
        cardDecoration(2).color,
        mindYearThreeColumnMonthCardBackground(
          monthlyNetMinor: aggregates.netForMonth(2),
          profitabilityTintEnabled: true,
          tintOpacity: .30,
        ),
      );
      expect(cardDecoration(3).color, FluviVisualTokens.surface);
      expect(cardDecoration(1).color, isNot(cardDecoration(2).color));
      expect(
        cardDecoration(1).border,
        isNull,
        reason: 'MonthCard tint is independent from the border-off default.',
      );
      expect(
        (tester
                    .widget<CustomPaint>(
                      find.byKey(
                        const ValueKey<String>(
                          'mind-year-heatmap-month-cells-1',
                        ),
                      ),
                    )
                    .painter!
                as MindYearHeatmapMonthPainter)
            .colorForDate(const LocalDate(year: 2025, month: 1, day: 3)),
        januaryCellBefore,
        reason: 'Tint opacity cannot reach the day-cell palette authority.',
      );
      expect(frame.value.identity, projection.preview(range).identity);

      settings.setYearThreeColumnProfitabilityTintEnabled(false);
      await tester.pump();
      expect(cardDecoration(1).color, FluviVisualTokens.surface);
      expect(cardDecoration(2).color, FluviVisualTokens.surface);
    },
  );

  testWidgets(
    'YEAR-SCOPE-01/02/03: direct 4x3 month headers show live scope totals on their existing row only when enabled',
    (tester) async {
      final settings = MindYearHeatmapPresentationController();
      final frame = ValueNotifier(_projection().preview(range));
      addTearDown(settings.dispose);
      addTearDown(frame.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 440,
            child: MindYearHeatmapViewport(
              frameListenable: frame,
              presentationSettings: settings,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-year-month-scope-total-1')),
        findsOneWidget,
        reason:
            'The January scope amount must occupy the existing 4x3 mini-header row.',
      );
      for (var month = 1; month <= 12; month += 1) {
        expect(
          find.byKey(ValueKey<String>('mind-year-month-scope-total-$month')),
          findsOneWidget,
        );
      }
      final januaryName = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-month-name-1')),
      );
      final januaryAmount = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-month-scope-total-1')),
      );
      expect(januaryName.center.dy, closeTo(januaryAmount.center.dy, .01));
      expect(januaryAmount.top, closeTo(januaryName.top, .01));
      expect(januaryAmount.bottom, closeTo(januaryName.bottom, .01));
      final amountText = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mind-year-month-scope-total-1')),
      );
      final nameText = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mind-year-month-name-1')),
      );
      expect(amountText.data, '1 k');
      expect(amountText.style?.color, nameText.style?.color);
      expect(amountText.style?.fontSize, nameText.style?.fontSize);
      expect(find.byType(MindYearHeatmapMonthGroup), findsNWidgets(12));
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
      );

      frame.value = _projection().preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 1000000,
          lowerScaled100: 200000,
          upperScaled100: 1000000,
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-year-month-scope-total-1'),
              ),
            )
            .data,
        '0',
        reason: 'The header consumes the current range-preview day totals.',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>('mind-year-month-scope-total-9'),
              ),
            )
            .data,
        '9 k',
      );

      settings.setYearMonthlyAmountPresentation(
        MindYearMonthlyAmountPresentation.hidden,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-year-month-scope-total-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-month-cells-1')),
        findsOneWidget,
        reason: 'The switch changes header metadata only, not heatmap cells.',
      );
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
