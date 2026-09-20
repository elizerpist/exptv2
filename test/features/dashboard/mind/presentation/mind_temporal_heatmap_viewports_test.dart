import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_frame.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_detailed_sum_chart.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_monthly_overlay_bar_chart.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/application/dashboard_expansion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_menu_formatters.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 100,
    maximumScaled100: 1000,
    lowerScaled100: 100,
    upperScaled100: 1000,
  );

  final contributions = <MindYearHeatmapPreparedContribution>[
    _entry(0, 100, const LocalDate(year: 2024, month: 1, day: 2)),
    _entry(1, 500, const LocalDate(year: 2025, month: 5, day: 3)),
    _entry(2, 1000, const LocalDate(year: 2025, month: 5, day: 4)),
  ];

  testWidgets(
    'SUM-HEATMAP-01/02 RED: Sum starts on the approved two-row multi-year heatmap hierarchy',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.text('Többéves aktivitás'), findsOneWidget);
      expect(find.text('2024–2025 · 24 hónap'), findsOneWidget);
      expect(find.text('Éves aktivitás'), findsNothing);
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-header-2025')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-2024')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-2025')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-total-2025')),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsOneWidget);
    },
  );

  test(
    'SUM-HEATMAP-02 RED: compact Mind annual amounts use the approved units',
    () {
      expect(formatMindCompactForints(7728364), '7,73 M Ft');
      expect(formatMindCompactForints(645560), '646 k Ft');
    },
  );

  testWidgets(
    'SUM-TOPO-01 RED: Sum has only heatmap/detail surfaces and no visualization PageView swipe',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('mind-sum-heatmap-page-1')),
        findsNothing,
      );
      expect(
        find.text('Többéves alakulás'),
        findsNothing,
        reason: 'The obsolete exact annual Sum surface is not reachable.',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        findsOneWidget,
      );
      expect(identical(listenable.value, frame), isTrue);

      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        const Offset(-180, 0),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        findsOneWidget,
        reason: 'One-finger horizontal input cannot switch a Sum surface.',
      );
    },
  );

  testWidgets(
    'SUM3-TOPO-01 RED: the top control selects the third monthly overlay surface without a Sum pager',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.byType(PageView), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-bars')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-bars')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('mind-sum-monthly-overlay-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-chart-2025'),
        ),
        findsOneWidget,
      );
      expect(identical(listenable.value, frame), isTrue);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_SUM|MODE' &&
              (event.scope?.contains('mode=monthlyOverlay') ?? false) &&
              (event.scope?.contains('reason=topToggle') ?? false),
        ),
        isTrue,
        reason: 'The user-copyable Mind panel receives the actual mode writer.',
      );
    },
  );

  testWidgets(
    'SUM3-DETAIL-TAP-01: a plot tap resolves the nearest real rendered anchor and shows its date and amount',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 100, const LocalDate(year: 2025, month: 1, day: 2)),
          _entry(1, 700, const LocalDate(year: 2025, month: 10, day: 9)),
        ],
      ).preview(range);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindDetailedSumChart(
                frame: frame,
                lineColor: Colors.deepPurple,
                scrollController: controller,
              ),
            ),
          ),
        ),
      );

      final plot = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-plot-2025')),
      );
      expect(
        tester
            .widget<Semantics>(
              find.byKey(
                const ValueKey('mind-sum-detailed-month-separator-count-2025'),
              ),
            )
            .properties
            .label,
        '11',
        reason: 'The full-year plot restores all eleven dashed month bounds.',
      );
      await tester.tapAt(Offset(plot.left + 38, plot.center.dy));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mind-sum-detailed-infocard-2025')),
        findsOneWidget,
      );
      expect(find.textContaining('2025.'), findsOneWidget);
      expect(find.textContaining('január 2.'), findsOneWidget);
      expect(
        find.textContaining(QueryMenuFormatters.money(100)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SUM3-MATERIAL-01: tappable Sum month cells do not require a Material ancestor',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 100, const LocalDate(year: 2025, month: 1, day: 2)),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (context) => SizedBox(
                  width: 360,
                  height: 260,
                  child: MindSumHeatmapViewport(frameListenable: listenable),
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('mind-sum-heatmap-tap-2025-1')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('mind-sum-month-infocard')),
        findsOneWidget,
      );
    },
  );

  test(
    'SUM3-BARS-01: Sum overlay keeps full direction and live preview totals separate',
    () {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 200, const LocalDate(year: 2025, month: 1, day: 2)),
        ],
        fullContributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 200, const LocalDate(year: 2025, month: 1, day: 2)),
          _entry(1, 800, const LocalDate(year: 2025, month: 1, day: 3)),
        ],
      ).preview(range);

      final series = mindSumMonthlyOverlaySeries(frame: frame, year: 2025);
      expect(series.values.first.fullAmount, 1000);
      expect(series.values.first.filteredAmount, 200);
      expect(series.values[1].fullAmount, 0);
      expect(series.values[1].filteredAmount, 0);
    },
  );

  testWidgets(
    'SUM3-BARS-02: the overlay foreground follows the same live range preview and heatmap palette authority',
    (tester) async {
      const identity = MindTemporalHeatmapIdentity(
        upstreamScopeKey: 'expense|all',
        indexGeneration: 1,
        coreRevision: 1,
        timeScopeKey: 'all',
      );
      final projection = MindSumHeatmapProjection.build(
        identity: identity,
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 200, const LocalDate(year: 2025, month: 1, day: 2)),
          _entry(1, 800, const LocalDate(year: 2025, month: 1, day: 3)),
        ],
      );
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(
        projection.preview(range),
      );
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('mind-sum-detail-toggle-bars')),
      );
      await tester.pump();

      MindMonthlyOverlayBarPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(
                      const ValueKey('mind-sum-monthly-overlay-chart-2025'),
                    ),
                  )
                  .painter!
              as MindMonthlyOverlayBarPainter;
      expect(painter().series.values.first.fullAmount, 1000);
      expect(painter().series.values.first.filteredAmount, 1000);

      final narrowed = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 100,
          maximumScaled100: 1000,
          lowerScaled100: 100,
          upperScaled100: 200,
        ),
      );
      listenable.value = narrowed;
      await tester.pump();
      expect(painter().series.values.first.fullAmount, 1000);
      expect(painter().series.values.first.filteredAmount, 200);
      expect(
        painter().foregroundForValue(painter().series.values.first),
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.fluvi,
          isEmpty: false,
          intensity: narrowed.month(year: 2025, month: 1).intensity,
          paletteIntensity: narrowed
              .month(year: 2025, month: 1)
              .paletteIntensity,
        ).background,
      );
      expect(identical(narrowed.identity, identity), isTrue);
    },
  );

  testWidgets(
    'SUM-GEST-01 RED: a noisy production-parent pinch never begins Dashboard expansion',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          for (var day = 1; day <= 31; day += 1)
            _entry(
              day,
              100 + day,
              LocalDate(year: 2025, month: 1, day: day),
              localTimeMinutes: day * 10,
            ),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      final expansion = DashboardExpansionController();
      final upper = DashboardUpperVerticalGestureCoordinator(
        expansion: expansion,
        mapViewportDelta: (delta) => delta,
      );
      addTearDown(listenable.dispose);
      addTearDown(expansion.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(
                frameListenable: listenable,
                upperVerticalGestures: upper,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();
      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-plot-2025')),
      );
      final window = find.byKey(
        const ValueKey<String>('mind-sum-detailed-window-2025'),
      );
      final beforeWindow = tester.widget<Semantics>(window).properties.label;
      final first = await tester.startGesture(
        Offset(plot.center.dx - 18, plot.center.dy - 4),
        pointer: 1,
      );
      final second = await tester.startGesture(
        Offset(plot.center.dx + 23, plot.center.dy + 7),
        pointer: 2,
      );
      await first.moveTo(Offset(plot.center.dx - 52, plot.center.dy - 46));
      await second.moveTo(Offset(plot.center.dx + 68, plot.center.dy + 102));
      await tester.pump();

      expect(
        tester
            .widget<Semantics>(
              find.byKey(
                const ValueKey<String>('mind-sum-detailed-pinch-state'),
              ),
            )
            .properties
            .label,
        'active',
        reason:
            'The local detailed surface explicitly owns active pinch state.',
      );
      expect(
        tester.widget<Semantics>(window).properties.label,
        isNot(beforeWindow),
        reason: 'The scale recognizer narrows the real detailed time window.',
      );
      expect(
        expansion.progress,
        0,
        reason:
            'A live two-pointer pinch must not begin collapse before it ends.',
      );
      expect(expansion.isDragging, isFalse);
      await first.up();
      await second.up();
      await tester.pump();

      expect(
        tester
            .widget<Semantics>(
              find.byKey(
                const ValueKey<String>('mind-sum-detailed-pinch-state'),
              ),
            )
            .properties
            .label,
        'idle',
      );
      expect(expansion.progress, 0);
      expect(expansion.isDragging, isFalse);
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        findsOneWidget,
      );
      expect(identical(listenable.value, frame), isTrue);
    },
  );

  testWidgets(
    'SUM-PRESENT-02/03 and SUM-MONTH-TAP-01: one-row labels and a real month infocard are presentation-local',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(listenable.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(
                frameListenable: listenable,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      settings
        ..setSumYearRowLayout(MindSumYearRowLayout.oneRowCompact)
        ..setSumMonthLabelPlacement(MindSumMonthLabelPlacement.belowEachRow);
      await tester.pump();
      final compactYear = find.byKey(
        const ValueKey('mind-sum-heatmap-compact-year-2025'),
      );
      final compactCells = find.byKey(
        const ValueKey('mind-sum-heatmap-compact-cells-2025'),
      );
      final compactTotal = find.byKey(
        const ValueKey('mind-sum-heatmap-compact-total-2025'),
      );
      expect(compactYear, findsOneWidget);
      expect(compactCells, findsOneWidget);
      expect(compactTotal, findsOneWidget);
      expect(
        tester.getRect(compactYear).right,
        lessThan(tester.getRect(compactCells).left),
      );
      expect(
        tester.getRect(compactCells).right,
        lessThan(tester.getRect(compactTotal).left),
      );
      for (var month = 1; month <= 12; month += 1) {
        final label = find.byKey(
          ValueKey('mind-sum-heatmap-month-label-2025-$month'),
        );
        final cell = find.byKey(ValueKey('mind-sum-heatmap-cell-2025-$month'));
        expect(label, findsOneWidget);
        expect(
          tester.getRect(label).center.dx,
          closeTo(tester.getRect(cell).center.dx, .01),
          reason:
              'Every month label owns the same horizontal centre as its cell.',
        );
      }

      settings.setSumMonthLabelPlacement(
        MindSumMonthLabelPlacement.insideMonthCells,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-header-2025')),
        findsNothing,
      );
      expect(find.text('M'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('mind-sum-heatmap-tap-2024-1')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-sum-month-infocard')),
        findsOneWidget,
      );
      expect(find.textContaining('2024.'), findsOneWidget);
      final januaryPopup = tester.getRect(
        find.byKey(const ValueKey('mind-sum-month-infocard')),
      );
      final januaryCell = tester.getRect(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2024-1')),
      );
      expect(
        (januaryPopup.center.dx - januaryCell.center.dx).abs(),
        lessThan(80),
        reason: 'The popup follows the actual January cell, not card origin.',
      );

      await tester.tap(
        find.byKey(const ValueKey('mind-sum-heatmap-tap-2025-5')),
      );
      await tester.pump();
      expect(find.textContaining('2025.'), findsOneWidget);
      final mayPopup = tester.getRect(
        find.byKey(const ValueKey('mind-sum-month-infocard')),
      );
      expect(mayPopup.center.dx, greaterThan(januaryPopup.center.dx));
      expect(
        (mayPopup.center.dx -
                tester
                    .getRect(
                      find.byKey(
                        const ValueKey('mind-sum-heatmap-cell-2025-5'),
                      ),
                    )
                    .center
                    .dx)
            .abs(),
        lessThan(80),
        reason: 'A second tap moves the anchored infocard to its own cell.',
      );
    },
  );

  testWidgets(
    'RED SUM-PAINT-01: a non-empty Sum month has a visible bounded rectangle',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final viewport = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-scroll'),
      );
      final cell = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-cell-2025-5'),
      );
      final cellRect = tester.getRect(cell);
      final viewportRect = tester.getRect(viewport);
      final decoration =
          tester.widget<DecoratedBox>(cell).decoration as BoxDecoration;

      expect(cellRect.width, greaterThan(0));
      expect(cellRect.height, greaterThan(0));
      expect(viewportRect.overlaps(cellRect), isTrue);
      expect(
        decoration.color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.fluvi,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );
    },
  );

  testWidgets(
    'RED MONTH-B3M-REAL-ROW-01: July 2026 uses five real calendar rows with numbered days and only the horizontal visual pager',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2026-07',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2026-07',
        ),
        year: 2026,
        month: 7,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.text('Napi aktivitás'), findsOneWidget);
      expect(find.text('31 nap'), findsOneWidget);
      expect(find.text('július 2026'), findsOneWidget);
      expect(find.text('0 aktív nap'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-month-heatmap-grid')),
        findsOneWidget,
      );
      final grid = tester.getSize(
        find.byKey(const ValueKey('mind-month-heatmap-grid')),
      );
      final cellExtent = (282 - 6 * 4) / 7;
      expect(
        grid.height,
        closeTo(cellExtent * 5 + 4 * 4, .01),
        reason: 'July 2026 occupies five real Monday–Sunday rows.',
      );
      final titleRect = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-title')),
      );
      final dayCountRect = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-day-count')),
      );
      final monthRect = tester.getRect(find.text('július 2026'));
      final activeRect = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-active-days')),
      );
      expect(titleRect.center.dy, closeTo(dayCountRect.center.dy, .01));
      expect(monthRect.center.dy, closeTo(activeRect.center.dy, .01));
      expect(titleRect.left, lessThan(dayCountRect.left));
      expect(monthRect.left, lessThan(activeRect.left));
      expect(
        find.byKey(const ValueKey('mind-month-heatmap-pager')),
        findsOneWidget,
        reason:
            'The new secondary card adds only the horizontal pager; the grid itself remains non-scrollable.',
      );
    },
  );

  testWidgets(
    'DAY-UI-01/02/03/04: Day presents one bounded chronological 4 by 6 grid from the shared palette authority',
    (tester) async {
      const date = LocalDate(year: 2026, month: 7, day: 14);
      final frame = MindDayHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'income|day:2026-07-14',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'day:2026-07-14',
        ),
        date: date,
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 100, date, localTimeMinutes: 0),
          _entry(1, 500, date, localTimeMinutes: 1439),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings.defaults(),
      )..setPaletteStyle(MindYearHeatmapPaletteStyle.meadowGreen);
      addTearDown(listenable.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindDayHeatmapViewport(
                frameListenable: listenable,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Óránkénti aktivitás'), findsOneWidget);
      expect(find.text('2 aktív óra'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-date')),
        findsOneWidget,
      );
      expect(find.text('Összesen'), findsOneWidget);
      final summaryTotal = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mind-day-heatmap-summary-total')),
      );
      final footerTotal = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mind-day-heatmap-total')),
      );
      expect(summaryTotal.data, footerTotal.data);
      for (var hour = 0; hour < 24; hour += 1) {
        expect(
          find.byKey(
            ValueKey<String>(
              'mind-day-heatmap-cell-${hour.toString().padLeft(2, '0')}',
            ),
          ),
          findsOneWidget,
        );
      }
      final hour00 = find.byKey(
        const ValueKey<String>('mind-day-heatmap-cell-00'),
      );
      final hour23 = find.byKey(
        const ValueKey<String>('mind-day-heatmap-cell-23'),
      );
      final hour00Rect = tester.getRect(hour00);
      final hour23Rect = tester.getRect(hour23);
      expect(hour00Rect.width, greaterThan(0));
      expect(hour00Rect.height, closeTo(hour00Rect.width, .01));
      expect(hour23Rect.top, greaterThan(hour00Rect.top));
      expect(hour23Rect.left, greaterThan(hour00Rect.left));
      expect(
        find.byKey(const ValueKey('mind-day-heatmap-pager')),
        findsOneWidget,
        reason:
            'The new secondary card adds only the horizontal pager; the 4×6 grid remains non-scrollable.',
      );
      final decoration =
          tester.widget<DecoratedBox>(hour23).decoration as BoxDecoration;
      expect(
        decoration.color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.meadowGreen,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );
    },
  );

  testWidgets(
    'MONTH-RHYTHM-UI-01 RED: Month preserves its heatmap primary page and exposes the daily-rhythm secondary page from resident daily totals',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 200, const LocalDate(year: 2025, month: 5, day: 2)),
          _entry(1, 700, const LocalDate(year: 2025, month: 5, day: 2)),
          _entry(2, 400, const LocalDate(year: 2025, month: 5, day: 31)),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final pager = find.byKey(const ValueKey('mind-month-heatmap-pager'));
      expect(pager, findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-month-heatmap-page-0')),
        findsOneWidget,
      );
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mind-month-heatmap-page-1')),
        findsOneWidget,
      );
      expect(find.text('Napi költési ritmus'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-month-rhythm-chart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-month-rhythm-average')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-month-rhythm-bar-02')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-month-rhythm-stat-total')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-month-rhythm-stat-strongest')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'DAY-TIMELINE-UI-01 RED: Day preserves its hourly heatmap primary page and exposes a real-time-marker timeline secondary page',
    (tester) async {
      const date = LocalDate(year: 2026, month: 7, day: 14);
      final frame = MindDayHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|day:2026-07-14',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'day:2026-07-14',
        ),
        date: date,
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 100, date, localTimeMinutes: 15),
          _entry(1, 700, date, localTimeMinutes: 721),
          _entry(2, 400, date, localTimeMinutes: 721),
          _entry(3, 900, date, localTimeMinutes: 1438),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindDayHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final pager = find.byKey(const ValueKey('mind-day-heatmap-pager'));
      expect(pager, findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-day-heatmap-page-0')),
        findsOneWidget,
      );
      await tester.drag(pager, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mind-day-heatmap-page-1')),
        findsOneWidget,
      );
      expect(find.text('Napi tranzakciók idővonala'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-day-timeline-chart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-marker-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-stat-total')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-stat-range')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RED MONTH-B3M-01: wide Month content centers its grid at the 282px reference width',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final grid = find.byKey(
        const ValueKey<String>('mind-month-heatmap-grid'),
      );
      final rect = tester.getRect(grid);
      expect(rect.width, closeTo(282, .01));
      expect(rect.left, closeTo((360 - 282) / 2, .01));
      final day = find.text('3');
      expect(day, findsOneWidget);
      final dayText = tester.widget<Text>(day);
      expect(dayText.style?.fontSize, 7);
      expect(dayText.style?.fontWeight, FontWeight.w900);
      expect(mindMonthHeatmapCellCornerRadius, 6);
      expect(
        find.ancestor(of: day, matching: find.byType(Center)),
        findsNothing,
      );
    },
  );

  testWidgets(
    'MONTH-B3M-REAL-ROW-02: a real six-row Month uses its sixth row rather than a five-row shortcut',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-06',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-06',
        ),
        year: 2025,
        month: 6,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final grid = tester.getSize(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
      );
      final cellExtent = (282 - 6 * 4) / 7;
      expect(
        grid.height,
        closeTo(cellExtent * 6 + 4 * 5, .01),
        reason: 'June 2025 starts on Sunday and needs six real rows.',
      );
      expect(find.text('június 2025'), findsOneWidget);
      expect(find.text('30 nap'), findsOneWidget);
    },
  );

  testWidgets(
    'MONTH-B3M-02: narrow Month content preserves the responsive centered seven-column grid',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              height: 420,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final grid = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
      );
      expect(grid.width, closeTo(216, .01));
      expect(grid.left, closeTo(12, .01));
      expect(grid.height, closeTo((216 - 6 * 4) / 7 * 5 + 4 * 4, .01));
    },
  );

  testWidgets(
    'SUM/MONTH-HM-10/11: the one palette setting repaints both temporal heatmaps without frame replacement',
    (tester) async {
      final sum = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final month = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final sumListenable = ValueNotifier<MindTemporalHeatmapFrame?>(sum);
      final monthListenable = ValueNotifier<MindTemporalHeatmapFrame?>(month);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(sumListenable.dispose);
      addTearDown(monthListenable.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 360,
                  height: 220,
                  child: MindSumHeatmapViewport(
                    frameListenable: sumListenable,
                    presentationSettings: settings,
                  ),
                ),
                SizedBox(
                  width: 360,
                  height: 220,
                  child: MindMonthHeatmapViewport(
                    frameListenable: monthListenable,
                    presentationSettings: settings,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final before = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
      );
      expect(
        (before.decoration as BoxDecoration).color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.fluvi,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      await tester.pump();
      final after = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
      );
      expect(
        (after.decoration as BoxDecoration).color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.b3mMy3,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );

      settings.setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();
      expect(settings.value.scaleResolution, MindHeatmapScaleResolution.twenty);
      expect(identical(sumListenable.value, sum), isTrue);
      expect(identical(monthListenable.value, month), isTrue);
      expect(identical(sumListenable.value, sum), isTrue);
      expect(identical(monthListenable.value, month), isTrue);
    },
  );

  testWidgets(
    'DSUM-04/05/06: detailed Sum is toggle-selected, uses adaptive bands, and returns to heatmap locally',
    (tester) async {
      final detailedContributions = <MindYearHeatmapPreparedContribution>[
        for (var year = 2024; year <= 2026; year += 1)
          for (var day = 1; day <= 18; day += 1)
            _entry(
              year * 100 + day,
              100 + day,
              LocalDate(year: year, month: 1, day: day),
            ),
      ];
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: detailedContributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mind-sum-detailed-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-band-2024')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-axis-month-2024-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-axis-y-2024-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detail-toggle-heatmap')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-window-2024')),
        findsOneWidget,
      );
      final detailedScroll = find.byKey(
        const ValueKey<String>('mind-sum-detailed-scroll'),
      );
      final detailedScrollState = tester.state<ScrollableState>(
        find
            .descendant(of: detailedScroll, matching: find.byType(Scrollable))
            .first,
      );
      expect(detailedScrollState.position.maxScrollExtent, greaterThan(0));
      await tester.drag(detailedScroll, const Offset(0, -80));
      await tester.pump();
      expect(detailedScrollState.position.pixels, greaterThan(0));

      await tester.drag(
        find.byKey(const ValueKey('mind-sum-detailed-plot-2024')),
        const Offset(350, 0),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-surface')),
        findsOneWidget,
        reason: 'An unzoomed one-finger chart drag cannot page Sum.',
      );

      await tester.tap(
        find.byKey(const ValueKey('mind-sum-detail-toggle-heatmap')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detail-toggle-line')),
        findsOneWidget,
      );
      expect(
        identical(listenable.value, frame),
        isTrue,
        reason: 'The visualization toggle is local presentation state only.',
      );
    },
  );

  testWidgets(
    'DSUM-02/03 RED: a two-pointer gesture narrows the real detailed Sum time window without changing the admitted frame',
    (tester) async {
      final denseContributions = <MindYearHeatmapPreparedContribution>[
        for (var day = 1; day <= 31; day += 1)
          _entry(day, 100 + day, LocalDate(year: 2025, month: 1, day: day)),
      ];
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: denseContributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();

      final window = find.byKey(
        const ValueKey('mind-sum-detailed-window-2025'),
      );
      final before = tester.widget<Semantics>(window).properties.label;
      final plot = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-plot-2025')),
      );
      final plotCenterX = plot.left + 34 + (plot.width - 34 - 3) / 2;
      final first = await tester.startGesture(
        Offset(plotCenterX - 18, plot.center.dy),
        pointer: 1,
      );
      final second = await tester.startGesture(
        Offset(plotCenterX + 18, plot.center.dy),
        pointer: 2,
      );
      await first.moveTo(Offset(plotCenterX - 56, plot.center.dy));
      await second.moveTo(Offset(plotCenterX + 56, plot.center.dy));
      await tester.pump();
      await first.up();
      await second.up();

      final after = tester.widget<Semantics>(window).properties.label;
      expect(after, isNot(before));
      expect(identical(listenable.value, frame), isTrue);
      final afterBounds = after!.split(':').map(int.parse).toList();
      final homeBounds = before!.split(':').map(int.parse).toList();
      expect(
        (afterBounds[0] + afterBounds[1]) / 2,
        closeTo((homeBounds[0] + homeBounds[1]) / 2, 2),
        reason:
            'A pinch at the visible plot centre keeps the calendar time '
            'under the fingers stable, excluding the left Y-axis gutter.',
      );

      await tester.drag(
        find.byKey(const ValueKey('mind-sum-detailed-plot-2025')),
        const Offset(-96, 0),
      );
      await tester.pump();
      expect(
        tester.widget<Semantics>(window).properties.label,
        isNot(after),
        reason: 'At a narrowed window, one pointer pans only local time.',
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-surface')),
        findsOneWidget,
        reason: 'A zoomed detailed-chart pan stays local and must not page.',
      );
    },
  );

  testWidgets(
    'SUM3-ZOOM-02: two ordinary pinch sessions reach a materially useful half-year detailed window',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          for (var month = 1; month <= 12; month += 1)
            _entry(
              month,
              100 + month,
              LocalDate(year: 2025, month: month, day: 15),
            ),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();

      final window = find.byKey(
        const ValueKey<String>('mind-sum-detailed-window-2025'),
      );
      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-plot-2025')),
      );
      final center = Offset(
        plot.left + 34 + (plot.width - 34 - 3) / 2,
        plot.center.dy,
      );

      Future<void> ordinaryPinch(int firstPointer, int secondPointer) async {
        final first = await tester.startGesture(
          Offset(center.dx - 18, center.dy),
          pointer: firstPointer,
        );
        final second = await tester.startGesture(
          Offset(center.dx + 18, center.dy),
          pointer: secondPointer,
        );
        // Move far enough to cross Flutter's ScaleGestureRecognizer slop.
        await first.moveTo(Offset(center.dx - 56, center.dy));
        await second.moveTo(Offset(center.dx + 56, center.dy));
        await tester.pump();
        await first.up();
        await second.up();
        await tester.pump();
      }

      await ordinaryPinch(1, 2);
      await ordinaryPinch(1, 2);

      final bounds = tester
          .widget<Semantics>(window)
          .properties
          .label!
          .split(':')
          .map(int.parse)
          .toList();
      expect(
        bounds[1] - bounds[0] + 1,
        lessThanOrEqualTo(184),
        reason:
            'Two realistic, cumulative pinches must reach about six months, '
            'not merely a technically non-zero annual zoom.',
      );
      expect(identical(listenable.value, frame), isTrue);
    },
  );

  testWidgets(
    'XR-SUM-03 RED: horizontal pan keeps the detailed yearly Y domain stable',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(1, 900, const LocalDate(year: 2025, month: 1, day: 5)),
          for (var month = 3; month <= 12; month += 1)
            _entry(
              month,
              100 + month,
              LocalDate(year: 2025, month: month, day: 15),
            ),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();

      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-plot-2025')),
      );
      final first = await tester.startGesture(
        Offset(plot.center.dx - 18, plot.center.dy),
        pointer: 41,
      );
      final second = await tester.startGesture(
        Offset(plot.center.dx + 18, plot.center.dy),
        pointer: 42,
      );
      await first.moveTo(Offset(plot.center.dx - 26, plot.center.dy - 2));
      await second.moveTo(Offset(plot.center.dx + 26, plot.center.dy + 2));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pump();

      final topAxis = find.byKey(
        const ValueKey<String>('mind-sum-detailed-axis-y-2025-3'),
      );
      final before = tester.widget<Text>(topAxis).data;
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-plot-2025')),
        Offset(plot.width, 0),
      );
      await tester.pump();
      final after = tester.widget<Text>(topAxis).data;

      expect(
        after,
        before,
        reason:
            'A high January outlier may enter the cropped window, but '
            'horizontal pan alone must not vertically re-normalize the same '
            'admitted year.',
      );
      final panSnapshot = FluviDiagnosticLogger.entries.lastWhere(
        (event) =>
            event.stage == 'MIND_SUM|BAND_SNAPSHOT' &&
            (event.scope?.contains('reason=PAN_END year=2025') ?? false),
      );
      expect(panSnapshot.scope, contains('sourcePoints='));
      expect(panSnapshot.scope, contains('visibleSourcePoints='));
      expect(panSnapshot.scope, contains('anchors='));
      expect(panSnapshot.scope, contains('paintAnchors='));
      expect(panSnapshot.scope, contains('bucketMinutes='));
      expect(panSnapshot.scope, contains('stableYMaximum='));
      expect(panSnapshot.scope, contains('anchorDigest='));
      expect(panSnapshot.scope, contains('leftPaintContinuation='));
    },
  );

  testWidgets(
    'RED SUMD-02: a pinch in one visible detailed-year band synchronizes every visible yearly window',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          for (final year in <int>[2024, 2025])
            for (var month = 1; month <= 12; month += 1)
              _entry(
                year * 100 + month,
                100 + month,
                LocalDate(year: year, month: month, day: 15),
              ),
        ],
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();

      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-plot-2024')),
      );
      final center = Offset(
        plot.left + 34 + (plot.width - 34 - 3) / 2,
        plot.center.dy,
      );
      Future<void> pinch(int firstPointer, int secondPointer) async {
        final first = await tester.startGesture(
          Offset(center.dx - 18, center.dy - 2),
          pointer: firstPointer,
        );
        final second = await tester.startGesture(
          Offset(center.dx + 18, center.dy + 3),
          pointer: secondPointer,
        );
        await first.moveTo(Offset(center.dx - 56, center.dy - 5));
        await second.moveTo(Offset(center.dx + 56, center.dy + 7));
        await tester.pump();
        await first.up();
        await second.up();
        await tester.pump();
      }

      await pinch(1, 2);
      await pinch(1, 2);

      int spanFor(int year) {
        final label = tester
            .widget<Semantics>(
              find.byKey(ValueKey<String>('mind-sum-detailed-window-$year')),
            )
            .properties
            .label!;
        final bounds = label.split(':').map(int.parse).toList();
        return bounds[1] - bounds[0] + 1;
      }

      expect(spanFor(2024), lessThanOrEqualTo(184));
      expect(
        spanFor(2025),
        lessThanOrEqualTo(184),
        reason:
            'The detailed Sum owns one shared temporal viewport; a '
            'multi-year pinch must not leave the untouched band at home.',
      );
      expect(identical(listenable.value, frame), isTrue);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_SUM|SCALE_UPDATE' &&
              (event.scope?.contains('pointers=2') ?? false) &&
              (event.scope?.contains('synced=true') ?? false),
        ),
        isTrue,
        reason: 'The debug console records the live shared-pinch path.',
      );
      final bandSnapshots = FluviDiagnosticLogger.entries
          .where(
            (event) =>
                event.stage == 'MIND_SUM|BAND_SNAPSHOT' &&
                (event.scope?.contains('reason=SCALE_END') ?? false),
          )
          .toList(growable: false);
      expect(bandSnapshots, hasLength(4));
      for (final snapshot in bandSnapshots) {
        expect(snapshot.scope, contains('visibleSourcePoints='));
        expect(snapshot.scope, contains('bucketMinutes='));
        expect(snapshot.scope, contains('stableYMaximum='));
        expect(snapshot.scope, contains('anchorDigest='));
        expect(snapshot.scope, contains('leftNeighbours='));
        expect(snapshot.scope, contains('leftPaintContinuation='));
      }
    },
  );

  testWidgets(
    'DSUM-02R RED: a new admitted same-year frame resets local detailed-chart zoom',
    (tester) async {
      MindSumHeatmapFrame buildFrame(int revision) =>
          MindSumHeatmapProjection.build(
            identity: MindTemporalHeatmapIdentity(
              upstreamScopeKey: 'expense|all',
              indexGeneration: 1,
              coreRevision: revision,
              timeScopeKey: 'all',
            ),
            contributions: <MindYearHeatmapPreparedContribution>[
              for (var day = 1; day <= 31; day += 1)
                _entry(
                  day,
                  100 + day,
                  LocalDate(year: 2025, month: 1, day: day),
                ),
            ],
          ).preview(range);

      final controller = ScrollController();
      addTearDown(controller.dispose);
      Future<void> mount(MindSumHeatmapFrame frame) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindDetailedSumChart(
                frame: frame,
                lineColor: Colors.deepPurple,
                scrollController: controller,
              ),
            ),
          ),
        ),
      );

      final firstFrame = buildFrame(1);
      await mount(firstFrame);

      final window = find.byKey(
        const ValueKey('mind-sum-detailed-window-2025'),
      );
      final plot = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-plot-2025')),
      );
      final first = await tester.startGesture(
        Offset(plot.center.dx - 18, plot.center.dy),
        pointer: 1,
      );
      final second = await tester.startGesture(
        Offset(plot.center.dx + 18, plot.center.dy),
        pointer: 2,
      );
      await first.moveTo(Offset(plot.center.dx - 56, plot.center.dy));
      await second.moveTo(Offset(plot.center.dx + 56, plot.center.dy));
      await tester.pump();
      await first.up();
      await second.up();
      final zoomed = tester.widget<Semantics>(window).properties.label;

      final secondFrame = buildFrame(2);
      await mount(secondFrame);
      final reset = tester.widget<Semantics>(window).properties.label;
      expect(reset, isNot(zoomed));
      expect(
        reset,
        '${LocalDate(year: 2025, month: 1, day: 1).epochDay}:${LocalDate(year: 2025, month: 12, day: 31).epochDay}',
        reason:
            'A new admitted frame must not retain a stale local range window.',
      );
    },
  );

  testWidgets(
    'DSUM-04/05 RED: one year expands, two share the plot, and three retain the two-year minimum band before scrolling',
    (tester) async {
      Future<double> mountAndMeasure(List<int> years) async {
        final frame = MindSumHeatmapProjection.build(
          identity: const MindTemporalHeatmapIdentity(
            upstreamScopeKey: 'expense|all',
            indexGeneration: 1,
            coreRevision: 1,
            timeScopeKey: 'all',
          ),
          contributions: <MindYearHeatmapPreparedContribution>[
            for (final year in years)
              _entry(year, 100, LocalDate(year: year, month: 1, day: 1)),
          ],
        ).preview(range);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 260,
                child: MindDetailedSumChart(
                  frame: frame,
                  lineColor: Colors.deepPurple,
                  scrollController: controller,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return tester
            .getSize(
              find.byKey(
                ValueKey<String>('mind-sum-detailed-band-${years.first}'),
              ),
            )
            .height;
      }

      final oneYearHeight = await mountAndMeasure(<int>[2024]);
      final twoYearHeight = await mountAndMeasure(<int>[2024, 2025]);
      final threeYearHeight = await mountAndMeasure(<int>[2024, 2025, 2026]);

      expect(oneYearHeight, greaterThan(twoYearHeight));
      expect(twoYearHeight, greaterThan(1));
      expect(
        threeYearHeight,
        closeTo(twoYearHeight, .1),
        reason:
            'The default two-band density keeps every additional year at the '
            'same complete-band height and reaches it through vertical scroll.',
      );
      expect(
        find.byKey(const ValueKey('mind-sum-detailed-scroll')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SUM3-FIT-01: two detailed bands keep the second month axis wholly inside the chart viewport',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 500, const LocalDate(year: 2024, month: 1, day: 2)),
          _entry(1, 600, const LocalDate(year: 2025, month: 1, day: 2)),
        ],
      ).preview(range);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindDetailedSumChart(
                frame: frame,
                lineColor: Colors.deepPurple,
                scrollController: controller,
              ),
            ),
          ),
        ),
      );

      final viewport = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-scroll')),
      );
      final secondBand = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-band-2025')),
      );
      final secondAxis = tester.getRect(
        find.byKey(const ValueKey('mind-sum-detailed-axis-month-2025-1')),
      );
      expect(secondBand.bottom, lessThanOrEqualTo(viewport.bottom + .01));
      expect(secondAxis.bottom, lessThanOrEqualTo(secondBand.bottom + .01));
    },
  );

  testWidgets(
    'SUM-DENSITY-01/02 RED: one presentation preference sizes detailed and overlay yearly bands without changing the Sum frame',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          for (final year in <int>[2024, 2025, 2026])
            for (var month = 1; month <= 12; month += 1)
              _entry(
                year * 100 + month,
                100 + month,
                LocalDate(year: year, month: month, day: 15),
              ),
        ],
      ).preview(range);
      final frameListenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(frameListenable.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindSumHeatmapViewport(
                frameListenable: frameListenable,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-sum-heatmap-surface')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-line')),
      );
      await tester.pumpAndSettle();
      final detailedScroll = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
      );
      final detailed2024 = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2024')),
      );
      final detailed2025 = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2025')),
      );
      expect(detailed2024.height, closeTo((detailedScroll.height - 8) / 2, .1));
      expect(
        detailed2025.bottom,
        lessThanOrEqualTo(detailedScroll.bottom + .1),
      );
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2026')),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2026')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      settings.setSumVisibleChartCount(MindSumVisibleChartCount.one);
      await tester.pumpAndSettle();
      final oneDetailed2024 = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2024')),
      );
      expect(oneDetailed2024.height, closeTo(detailedScroll.height, .1));
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2025')),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-sum-detailed-band-2025')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-detailed-scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      settings.setSumVisibleChartCount(MindSumVisibleChartCount.two);
      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-bars')),
      );
      await tester.pumpAndSettle();
      final overlayScroll = tester.getRect(
        find.byKey(const ValueKey<String>('mind-sum-monthly-overlay-scroll')),
      );
      final overlay2024 = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2024'),
        ),
      );
      final overlay2025 = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2025'),
        ),
      );
      expect(overlay2024.height, closeTo((overlayScroll.height - 13) / 2, .1));
      expect(overlay2025.bottom, lessThanOrEqualTo(overlayScroll.bottom + .1));
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2026'),
        ),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-monthly-overlay-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2026'),
        ),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-monthly-overlay-scroll')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      settings.setSumVisibleChartCount(MindSumVisibleChartCount.one);
      await tester.pumpAndSettle();
      final oneOverlay2024 = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2024'),
        ),
      );
      expect(oneOverlay2024.height, closeTo(overlayScroll.height - 5, .1));
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2025'),
        ),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('mind-sum-monthly-overlay-scroll')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-monthly-overlay-band-2025'),
        ),
        findsOneWidget,
      );
      expect(identical(frameListenable.value, frame), isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('mind-sum-detail-toggle-heatmap')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mind-sum-heatmap-surface')),
        findsOneWidget,
        reason: 'The density choice is ignored by the Sum heatmap surface.',
      );
      expect(identical(frameListenable.value, frame), isTrue);
    },
  );
}

MindYearHeatmapPreparedContribution _entry(
  int ordinal,
  int amount,
  LocalDate date, {
  int localTimeMinutes = 0,
}) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  bookedLocalEpochDay: date.epochDay,
  bookedLocalTimeMinutes: localTimeMinutes,
  amountMinor: amount,
);
