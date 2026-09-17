import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart';
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
    'RED MYHR-04/05: January 2025 starts at Wednesday and MonthCards have no expanded tail',
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
      // The one ListView builds only its visible/cache rows; its six two-card
      // rows are the structural proof of all twelve unique months.
      expect(find.byType(MindYearHeatmapMonthCard), findsAtLeastNWidgets(8));
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

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      await tester.pump();

      expect(frame.value.identity, identity);
      expect(color(), isNot(fluvi));
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
