import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_visual_resolver.dart';
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
    'RED YEAR-INFO-01/02/03/04/05: a MonthCard morphs locally into stable full-month information',
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

      final january = find.byKey(const ValueKey('mind-year-heatmap-month-1'));
      final januaryTap = find.byKey(
        const ValueKey('mind-year-heatmap-month-tap-1'),
      );
      final before = tester.getRect(january);
      final scrollExtentBefore = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('mind-year-heatmap-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .maxScrollExtent;
      await tester.tap(januaryTap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsOneWidget,
        reason:
            'A clean Year MonthCard tap opens local inspection, not Month navigation.',
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-morph-1')),
        findsOneWidget,
        reason:
            'The inspection content must have a measurable intermediate morph state.',
      );
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Hó végi maradék'), findsOneWidget);
      expect(find.text('Összbevétel'), findsOneWidget);
      expect(find.text('Összkiadás'), findsOneWidget);
      expect(find.text('3 800 Ft'), findsOneWidget);
      expect(find.text('5 000 Ft'), findsOneWidget);
      expect(find.text('1 200 Ft'), findsOneWidget);
      expect(find.text('Étel'), findsOneWidget);
      expect(find.text('1 000 Ft'), findsOneWidget);
      final scopeSpan =
          tester
                  .widget<Text>(
                    find.byKey(
                      const ValueKey(
                        'mind-year-heatmap-inspection-scope-label',
                      ),
                    ),
                  )
                  .textSpan!
              as TextSpan;
      expect(
        (scopeSpan.children!.single as TextSpan).style?.color,
        CategoryVisualResolver.resolve(
          colorId: 'orange',
          iconId: 'fork',
        ).gradient.middleColor,
        reason:
            'The scoped category uses the canonical category visual authority.',
      );
      expect(tester.getRect(january), before);
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(const ValueKey('mind-year-heatmap-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .maxScrollExtent,
        scrollExtentBefore,
      );
      expect(
        tester.getSemantics(januaryTap).flagsCollection.isToggled,
        Tristate.isTrue,
        reason: 'The same card remains the selected local inspection owner.',
      );

      await tester.tap(januaryTap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsNothing,
      );
      expect(tester.getRect(january), before);
    },
  );

  testWidgets(
    'RED YEAR-INFO-14: a Year scroll drag never becomes a MonthCard inspection tap',
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
        find.byKey(const ValueKey('mind-year-heatmap-month-tap-1')),
        const Offset(0, -100),
      );
      await tester.pump();

      expect(scrollController.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsNothing,
        reason: 'The tap observer must not enter the Scrollable gesture arena.',
      );
    },
  );

  testWidgets(
    'RED YEAR-INFO-04/06/13/15/17: inspection has one owner, survives same-Year data changes, and clears before a new Year paints',
    (tester) async {
      final frame = ValueNotifier(_inspectionProjection().preview(range));
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

      final january = find.byKey(
        const ValueKey('mind-year-heatmap-month-tap-1'),
      );
      final february = find.byKey(
        const ValueKey('mind-year-heatmap-month-tap-2'),
      );
      await tester.tap(january);
      await tester.pump(const Duration(milliseconds: 240));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-direct-1')),
        findsOneWidget,
      );

      // A new direction/frame for the same selected Year must update only
      // data. It must neither navigate nor close the local inspection.
      frame.value = _inspectionProjection(
        upstreamScopeKey: 'income|year:2025',
        coreRevision: 2,
      ).preview(range);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsOneWidget,
      );
      expect(find.text('Hó végi maradék'), findsOneWidget);
      expect(find.text('3 800 Ft'), findsOneWidget);

      settings
        ..setPaletteStyle(MindYearHeatmapPaletteStyle.meadowGreen)
        ..setShowHeatmapLegend(false)
        ..setAnnualSurfaceStyle(MindYearHeatmapAnnualSurfaceStyle.monthCards);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsOneWidget,
        reason:
            'Presentation-only changes retain a same-Year local inspection.',
      );

      await tester.tap(february);
      await tester.pump(const Duration(milliseconds: 480));
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
        findsOneWidget,
        reason:
            'A surface-style change updates only the shell, not the selected '
            'Year inspection state.',
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey('mind-year-heatmap-month-info-2')),
            )
            .size,
        isNot(Size.zero),
      );

      frame.value = _inspectionProjection(
        year: 2026,
        upstreamScopeKey: 'income|year:2026',
        coreRevision: 3,
      ).preview(range);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-info-2')),
        findsNothing,
        reason: 'A 2025 inspection must be cleared before a 2026 frame paints.',
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

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      await tester.pump();

      expect(frame.value.identity, identity);
      expect(color(), isNot(fluvi));
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
    'RED YEAR-INFO-16/17: four-column inspection stays inside its stable slot at supported mobile widths',
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
        final card = find.byKey(const ValueKey('mind-year-heatmap-month-1'));
        final slotBefore = tester.getRect(card);
        final scrollExtentBefore = tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(
                      const ValueKey('mind-year-heatmap-fit-scroll'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .maxScrollExtent;
        await tester.tap(
          find.byKey(const ValueKey('mind-year-heatmap-month-tap-1')),
        );
        await tester.pump(const Duration(milliseconds: 240));
        final info = tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-month-info-1')),
        );
        final slot = tester.getRect(card);
        expect(slot, slotBefore);
        expect(
          tester
              .state<ScrollableState>(
                find
                    .descendant(
                      of: find.byKey(
                        const ValueKey('mind-year-heatmap-fit-scroll'),
                      ),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position
              .maxScrollExtent,
          scrollExtentBefore,
        );
        expect(info.width, greaterThan(0));
        expect(info.height, greaterThan(0));
        expect(slot.contains(info.topLeft), isTrue);
        expect(
          slot.contains(info.bottomRight - const Offset(.01, .01)),
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
