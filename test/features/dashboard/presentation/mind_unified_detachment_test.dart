import '../../../support/mother_card_raster_comparator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_frame.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

const capture = ValueKey('mind-detachment-capture');
Future<void> pumpMind(
  WidgetTester tester,
  double travel,
  Listenable changes, {
  TimePlane plane = TimePlane.year,
  bool day = false,
  ValueNotifier<MindYearHeatmapFrame?>? year,
  ValueNotifier<MindTemporalHeatmapFrame?>? temporal,
  MindYearHeatmapPresentationController? heatmapSettings,
  ValueChanged<QueryAmountRangeValues>? onCommitted,
  ValueNotifier<DashboardHeaderVisualFrame>? colors,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xffe9edf6),
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: capture,
          child: SizedBox(
            width: 412,
            height: 700,
            child: Stack(
              children: [
                MindDashboardCoreSurface(
                  temporalPlane: plane,
                  headerVisualFrame: colors,
                  showTemporalDayHeatmap: day,
                  yearHeatmap: year,
                  temporalHeatmap: temporal,
                  showYearHeatmap: year != null,
                  showTemporalHeatmap: temporal != null,
                  yearHeatmapPresentation: heatmapSettings,
                  queryAmountRange: () => const QueryAmountRangeValues(
                    minimumScaled100: 0,
                    maximumScaled100: 100000000,
                    lowerScaled100: 0,
                    upperScaled100: 100000000,
                  ),
                  queryAmountRangeChanges: changes,
                  onQueryAmountRangeCommitted: onCommitted ?? (_) {},
                  presentation: DashboardCoreModePresentation(
                    geometry: DashboardGeometryResolver.resolve(
                      metrics: DashboardLayoutMetrics.reference,
                      mode: DashboardModeSpec.mind,
                      collapseProgress: travel,
                      isRailExpanded: false,
                      hasPhysicalRail: false,
                      seamlessHeaderContent: true,
                    ),
                    palette: DashboardModePaletteResolver.resolve(
                      DashboardModeSpec.mind,
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
);
void main() {
  final originalComparator = goldenFileComparator;
  setUpAll(() {
    if (originalComparator is LocalFileComparator) {
      goldenFileComparator = MotherCardRasterComparator(
        originalComparator.basedir.resolve('mind_unified_detachment_test.dart'),
      );
    }
  });
  tearDownAll(() => goldenFileComparator = originalComparator);

  for (final scope in [
    (TimePlane.sum, false),
    (TimePlane.year, false),
    (TimePlane.month, false),
    (TimePlane.month, true),
  ]) {
    testWidgets(
      'Mind physical/content identity and reverse ${scope.$1} day=${scope.$2}',
      (tester) async {
        final changes = ChangeNotifier();
        addTearDown(changes.dispose);
        await pumpMind(tester, 0, changes, plane: scope.$1, day: scope.$2);
        final body = find.byKey(
          const ValueKey('dashboard-core-mode-mind-body'),
        );
        final material = find.byKey(const ValueKey('mind-unified-moving-body'));
        final range = find.byType(QueryAmountRangeControl);
        final bodyElement = tester.element(body);
        final rangeElement = scope.$2 ? null : tester.element(range);
        final original = tester.getRect(material);
        final initialContentOffset = tester.getTopLeft(body) - original.topLeft;
        for (final travel in [
          0.1,
          .5,
          1.0,
          3.0,
          9.0,
          18.0,
          36.0,
          90.0,
          144.0,
          171.0,
          180.0,
          63.0,
          18.0,
          126.0,
          0.0,
        ]) {
          await pumpMind(
            tester,
            travel,
            changes,
            plane: scope.$1,
            day: scope.$2,
          );
          expect(tester.element(body), same(bodyElement));
          if (rangeElement != null) {
            expect(tester.element(range), same(rangeElement));
          }
          final header = tester.widget<DashboardCoreModeHeaderScaffold>(
            find.byType(DashboardCoreModeHeaderScaffold),
          );
          expect(header.depthProgress, closeTo(travel / 180, 1e-8));
          expect(header.borderProgress, closeTo(travel / 180, 1e-8));
          if (travel == 90) {
            expect(tester.getRect(material).width, lessThan(original.width));
            expect(
              tester.getTopLeft(body) - tester.getRect(material).topLeft,
              isNot(initialContentOffset),
            );
            expect(tester.getRect(material).height, lessThan(original.height));
          }
          expect(tester.takeException(), isNull);
        }
        expect(tester.getRect(material), original);
      },
    );
  }
  for (final scope in [
    (TimePlane.sum, false),
    (TimePlane.year, false),
    (TimePlane.month, false),
    (TimePlane.month, true),
  ]) {
    testWidgets(
      'real Mind heatmap/scroll/range state survives reversed collapse ${scope.$1} day=${scope.$2}',
      (tester) async {
        final changes = ChangeNotifier();
        final settings = MindYearHeatmapPresentationController()
          ..setYearGridLayout(MindYearHeatmapGridLayout.threeByFour);
        if (scope.$2) settings.setShowDayContentViewChooser(true);
        const rangeValues = QueryAmountRangeValues(
          minimumScaled100: 0,
          maximumScaled100: 100000000,
          lowerScaled100: 0,
          upperScaled100: 100000000,
        );
        final year = ValueNotifier<MindYearHeatmapFrame?>(
          MindYearHeatmapProjection.build(
            identity: const MindYearHeatmapIdentity(
              upstreamScopeKey: 'test|year:2025',
              indexGeneration: 1,
              coreRevision: 1,
              year: 2025,
              navigationEpoch: 1,
            ),
            entries: [
              for (var month = 1; month <= 12; month++)
                DashboardLedgerEntry(
                  id: '$month',
                  partnerId: 'p',
                  categoryId: 'c',
                  direction: 'expense',
                  amountMinor: month * 100000,
                  bookedLocalEpochDay: LocalDate(
                    year: 2025,
                    month: month,
                    day: 2,
                  ).epochDay,
                  bookedLocalTimeMinutes: 120,
                ),
            ],
          ).preview(rangeValues),
        );
        final contributions = [
          for (var month = 1; month <= 12; month++)
            MindYearHeatmapPreparedContribution(
              ordinal: month,
              bookedLocalEpochDay: LocalDate(
                year: 2025,
                month: month,
                day: 2,
              ).epochDay,
              bookedLocalTimeMinutes: 120,
              amountMinor: month * 100000,
            ),
        ];
        const identity = MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'test|resident',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'resident',
        );
        final temporal = ValueNotifier<MindTemporalHeatmapFrame?>(
          scope.$2
              ? MindDayHeatmapProjection.build(
                  identity: identity,
                  date: const LocalDate(year: 2025, month: 7, day: 2),
                  contributions: contributions,
                ).preview(rangeValues)
              : scope.$1 == TimePlane.sum
              ? MindSumHeatmapProjection.build(
                  identity: identity,
                  contributions: contributions,
                ).preview(rangeValues)
              : MindMonthHeatmapProjection.build(
                  identity: identity,
                  year: 2025,
                  month: 7,
                  contributions: contributions,
                ).preview(rangeValues),
        );
        addTearDown(changes.dispose);
        addTearDown(year.dispose);
        addTearDown(temporal.dispose);
        addTearDown(settings.dispose);
        var commits = 0;
        Future<void> render(double travel) => pumpMind(
          tester,
          travel,
          changes,
          plane: scope.$1,
          day: scope.$2,
          year: scope.$1 == TimePlane.year ? year : null,
          temporal: scope.$1 == TimePlane.year ? null : temporal,
          heatmapSettings: settings,
          onCommitted: (_) => commits++,
        );
        await render(0);
        await tester.pumpAndSettle();
        final range = find.byType(QueryAmountRangeControl);
        expect(range, findsOneWidget);
        final rangeElement = tester.element(range);
        var scrollStates = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .toList();
        var positions = [for (final state in scrollStates) state.position];
        if (scope.$1 == TimePlane.year) {
          expect(scrollStates, isNotEmpty);
          positions.first.jumpTo(
            40.clamp(0, positions.first.maxScrollExtent).toDouble(),
          );
          await tester.pumpAndSettle();
          scrollStates = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .toList();
          positions = [for (final state in scrollStates) state.position];
        }
        final offsets = [for (final p in positions) p.pixels];
        if (scope.$1 == TimePlane.year ||
            (scope.$1 == TimePlane.month && !scope.$2)) {
          await expectLater(
            find.byKey(capture),
            matchesGoldenFile(
              '../../../goldens/mind_unified_detachment_${scope.$1.name}_heatmap_expanded.png',
            ),
          );
        }
        for (final travel in [0.1, 9.0, 63.0, 18.0, 126.0, 90.0, 0.0]) {
          await render(travel);
          await tester.pump();
          expect(tester.element(range), same(rangeElement));
          final currentStates = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .toList();
          expect(currentStates.length, scrollStates.length);
          for (var i = 0; i < currentStates.length; i++) {
            expect(currentStates[i], same(scrollStates[i]));
            expect(currentStates[i].position, same(positions[i]));
            expect(currentStates[i].position.pixels, offsets[i]);
          }
          if (travel == 90 &&
              (scope.$1 == TimePlane.year ||
                  (scope.$1 == TimePlane.month && !scope.$2))) {
            await expectLater(
              find.byKey(capture),
              matchesGoldenFile(
                '../../../goldens/mind_unified_detachment_${scope.$1.name}_heatmap_half.png',
              ),
            );
          }
          expect(tester.takeException(), isNull);
        }
        final slider = find.byType(RangeSlider);
        expect(slider, findsOneWidget);
        final rect = tester.getRect(slider);
        await tester.dragFrom(
          Offset(rect.right - 24, rect.center.dy),
          const Offset(-60, 0),
        );
        await tester.pumpAndSettle();
        expect(commits, greaterThan(0));
        if (scope.$1 == TimePlane.month && !scope.$2) {
          final pager = find.byKey(const ValueKey('mind-month-heatmap-pager'));
          final widget = tester.widget<PageView>(pager);
          final controller = widget.controller!;
          expect(controller.page, 0);
          await tester.drag(pager, const Offset(-240, 0));
          await tester.pumpAndSettle();
          expect(controller.page, closeTo(1, .01));
        }
        if (scope.$2) {
          final timeline = find.byKey(
            const ValueKey('mind-day-all-slider-view-timeline'),
          );
          expect(timeline, findsOneWidget);
          await tester.tap(timeline);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('mind-day-timeline-chart')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Mind reactive bridge stays inside moving physical viewport', (
    tester,
  ) async {
    final changes = ChangeNotifier();
    final colors = ValueNotifier(
      const DashboardHeaderVisualFrame(
        colors: [Colors.purple, Colors.teal],
        stops: [0, 1],
        opacity: 1,
        colorA: Colors.purple,
        colorB: Colors.teal,
      ),
    );
    addTearDown(changes.dispose);
    addTearDown(colors.dispose);
    for (final state in [(0.0, 'expanded'), (90.0, 'half')]) {
      await pumpMind(tester, state.$1, changes, colors: colors);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-seamless-header-color-bleed')),
        findsOneWidget,
      );
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/mind_unified_detachment_bridge_${state.$2}.png',
        ),
      );
    }
    colors.value = const DashboardHeaderVisualFrame(
      colors: [Colors.blue, Colors.pink],
      stops: [0, 1],
      opacity: 1,
      colorA: Colors.blue,
      colorB: Colors.pink,
    );
    await tester.pump();
    final bridge = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mind-seamless-header-color-bleed')),
    );
    final gradient =
        (bridge.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors.first, Colors.pink.withValues(alpha: .14));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Mind intermediate physical golden states', (tester) async {
    final changes = ChangeNotifier();
    addTearDown(changes.dispose);
    for (final state in [
      (0.0, 'expanded'),
      (.1, 'first'),
      (9.0, 'early'),
      (63.0, 'thirty_five'),
      (90.0, 'half'),
      (117.0, 'sixty_five'),
      (171.0, 'near'),
      (180.0, 'collapsed'),
    ]) {
      await pumpMind(tester, state.$1, changes);
      await tester.pump();
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/mind_unified_detachment_${state.$2}.png',
        ),
      );
    }
  });
}
