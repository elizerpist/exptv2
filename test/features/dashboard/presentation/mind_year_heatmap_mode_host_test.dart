import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_expansion_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_frame.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  testWidgets(
    'RED MYH-01/10/11: Mind Year owns card scroll while header expansion remains available',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final expansion = _ExpansionRecorder();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: expansion,
          showYearHeatmap: true,
        ),
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
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('dashboard-core-mode-content-gesture-region'),
        ),
        findsNothing,
      );

      final footerBefore = tester.getRect(
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
      );
      await tester.drag(
        find.byKey(const ValueKey('mind-year-heatmap-scroll')),
        const Offset(0, -160),
      );
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('mind-year-heatmap-grid')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
      expect(expansion.starts, 0);
      expect(
        tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        ),
        footerBefore,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
        const Offset(0, 80),
      );
      await tester.pump();
      expect(expansion.starts, 1);
      expect(expansion.ends, 1);
    },
  );

  testWidgets(
    'RED GESTURE-02: Year boundary overscroll hands only the unconsumed drag to the shared expansion owner',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final expansion = DashboardExpansionController();
      final coordinator = DashboardUpperVerticalGestureCoordinator(
        expansion: expansion,
        mapViewportDelta: (delta) => delta,
      );
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(expansion.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          upperVerticalGestures: coordinator,
          showYearHeatmap: true,
        ),
      );
      final scroll = find.byKey(
        const ValueKey<String>('mind-year-heatmap-scroll'),
      );
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
      );
      final interiorGesture = await tester.startGesture(
        tester.getCenter(scroll),
      );
      await interiorGesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(scrollable.position.pixels, greaterThan(0));
      expect(expansion.isDragging, isFalse);
      await interiorGesture.up();
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();

      final gesture = await tester.startGesture(tester.getCenter(scroll));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();

      expect(expansion.isDragging, isTrue);
      expect(expansion.progress, greaterThan(0));
      expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
      await gesture.up();
      expect(expansion.isDragging, isFalse);
    },
  );

  testWidgets(
    'GESTURE-04: a non-scroll Sum viewport hands its outward drag to the shared expansion owner',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final year = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final temporal = ValueNotifier<MindTemporalHeatmapFrame?>(_sumFrame());
      final rangeChanges = ValueNotifier<int>(0);
      final expansion = DashboardExpansionController();
      final coordinator = DashboardUpperVerticalGestureCoordinator(
        expansion: expansion,
        mapViewportDelta: (delta) => delta,
      );
      addTearDown(mode.dispose);
      addTearDown(year.dispose);
      addTearDown(temporal.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(expansion.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: year,
          temporalFrame: temporal,
          temporalPlane: TimePlane.sum,
          showTemporalHeatmap: true,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          upperVerticalGestures: coordinator,
          showYearHeatmap: false,
        ),
      );
      final scroll = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-scroll'),
      );
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      final gesture = await tester.startGesture(tester.getCenter(scroll));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(expansion.isDragging, isTrue);
      expect(expansion.progress, greaterThan(0));
      await gesture.up();
    },
  );

  testWidgets(
    'RED GESTURE-03/RANGE-ISOLATION-01: non-scroll Month content hands off while the compact range remains isolated',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final year = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final temporal = ValueNotifier<MindTemporalHeatmapFrame?>(_monthFrame());
      final rangeChanges = ValueNotifier<int>(0);
      final expansion = DashboardExpansionController();
      final coordinator = DashboardUpperVerticalGestureCoordinator(
        expansion: expansion,
        mapViewportDelta: (delta) => delta,
      );
      addTearDown(mode.dispose);
      addTearDown(year.dispose);
      addTearDown(temporal.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(expansion.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: year,
          temporalFrame: temporal,
          temporalPlane: TimePlane.month,
          showTemporalHeatmap: true,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          upperVerticalGestures: coordinator,
          showYearHeatmap: false,
        ),
      );
      final month = find.byKey(
        const ValueKey<String>('mind-month-heatmap-grid'),
      );
      final contentGesture = await tester.startGesture(tester.getCenter(month));
      await contentGesture.moveBy(const Offset(0, -80));
      await tester.pump();
      expect(expansion.isDragging, isTrue);
      expect(expansion.progress, greaterThan(0));
      await contentGesture.up();

      final slider = find.byKey(
        const ValueKey<String>('query-amount-range-slider'),
      );
      final sliderBounds = tester.getRect(slider);
      // Exercise both physical thumbs.  The shared direct-drag handoff must
      // never include the fixed compact range lane.
      final lowerThumbGesture = await tester.startGesture(
        Offset(sliderBounds.left + 4, sliderBounds.center.dy),
      );
      await lowerThumbGesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(expansion.isDragging, isFalse);
      expect(expansion.progress, 0);
      await lowerThumbGesture.up();

      final upperThumbGesture = await tester.startGesture(
        Offset(sliderBounds.right - 4, sliderBounds.center.dy),
      );
      await upperThumbGesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(expansion.isDragging, isFalse);
      expect(expansion.progress, 0);
      await upperThumbGesture.up();
    },
  );

  testWidgets(
    'LEGEND-FINAL-04/FTR-01: a scrolling Sum grid never moves the inline legend or compact range footer',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final year = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final temporal = ValueNotifier<MindTemporalHeatmapFrame?>(
        MindSumHeatmapProjection.build(
          identity: const MindTemporalHeatmapIdentity(
            upstreamScopeKey: 'expense|all-many-years',
            indexGeneration: 1,
            coreRevision: 1,
            timeScopeKey: 'all',
          ),
          contributions: <MindYearHeatmapPreparedContribution>[
            for (var year = 2017; year <= 2025; year += 1)
              _temporalContribution(
                year - 2017,
                100 + year,
                LocalDate(year: year, month: 1, day: 1),
              ),
          ],
        ).preview(_temporalRange),
      );
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(year.dispose);
      addTearDown(temporal.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: year,
          temporalFrame: temporal,
          temporalPlane: TimePlane.sum,
          showYearHeatmap: false,
          showTemporalHeatmap: true,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
        ),
      );
      final legend = find.byKey(
        const ValueKey<String>('mind-heatmap-inline-legend'),
      );
      final footer = find.byKey(
        const ValueKey<String>('mind-year-heatmap-fixed-footer'),
      );
      final beforeLegend = tester.getRect(legend);
      final beforeFooter = tester.getRect(footer);
      final scroll = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-scroll'),
      );
      expect(scroll, findsOneWidget);

      await tester.drag(scroll, const Offset(0, -120));
      await tester.pump();
      final state = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
      );
      expect(state.position.pixels, greaterThan(0));
      expect(tester.getRect(legend), beforeLegend);
      expect(tester.getRect(footer), beforeFooter);
      expect(find.byType(RangeSlider), findsOneWidget);
    },
  );

  testWidgets(
    'RED MYH-01: non-Year Mind composition does not mount the annual grid',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('dashboard-core-mode-content-gesture-region'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LEGEND-FINAL-05: the permanent inline Mind legend has ten or twenty resolver swatches',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-heatmap-inline-legend')),
        findsOneWidget,
      );
      for (var index = 0; index < 10; index += 1) {
        expect(
          find.byKey(ValueKey('mind-heatmap-inline-swatch-$index')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('mind-heatmap-inline-swatch-10')),
        findsNothing,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('mind-heatmap-inline-legend')))
            .bottom,
        lessThanOrEqualTo(
          tester
              .getRect(
                find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
              )
              .bottom,
        ),
      );

      settings.setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();
      for (var index = 0; index < 20; index += 1) {
        expect(
          find.byKey(ValueKey('mind-heatmap-inline-swatch-$index')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('mind-heatmap-inline-swatch-20')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'LEGEND-FINAL-01: four-column Year has no external legend lane and retains the inline legend',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: true,
          showMonthlyDirectionTotal: true,
          revision: 0,
        ),
      );
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
        ),
      );
      final inline = find.byKey(
        const ValueKey<String>('mind-heatmap-inline-legend'),
      );
      final footer = find.byKey(
        const ValueKey<String>('mind-year-heatmap-fixed-footer'),
      );
      final content = find.byKey(
        const ValueKey<String>('mind-year-heatmap-fit-scroll'),
      );
      final footerBefore = tester.getRect(footer);
      final contentBefore = tester.getRect(content);
      final cellsBefore = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-month-cells-1')),
      );
      final lastRowBefore = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-annual-row-2')),
      );
      expect(inline, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-legend-lane')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-palette-legend')),
        findsNothing,
      );

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.meadowGreen);
      await tester.pump();

      expect(tester.getRect(footer), footerBefore);
      final contentAfter = tester.getRect(content);
      expect(contentAfter, contentBefore);
      final cellsAfter = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-month-cells-1')),
      );
      final lastRowAfter = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-annual-row-2')),
      );
      expect(cellsAfter, cellsBefore);
      expect(lastRowAfter, lastRowBefore);
    },
  );

  testWidgets(
    'LEGEND-FINAL-02: permanent inline legend leaves a 68px compact footer and returns the whole former lane to temporal content',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
        ),
      );

      final body = tester.getRect(
        find.byKey(const ValueKey<String>('mind-temporal-content-viewport')),
      );
      final footer = tester.getRect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-fixed-footer')),
      );
      final slider = tester.getRect(
        find.byKey(const ValueKey<String>('query-amount-range-slider')),
      );
      final minimum = tester.getRect(find.text('Min.').last);
      final maximum = tester.getRect(find.text('Max.').last);
      final inline = tester.getRect(
        find.byKey(const ValueKey<String>('mind-heatmap-inline-legend')),
      );

      expect(footer.height, closeTo(68, .01));
      expect(footer.top, closeTo(body.bottom, .01));
      // The audited original source reserved 28 + 74 = 102px. The permanent
      // inline legend leaves only the 68px slider footer, returning 34px.
      expect(102 - footer.height, closeTo(34, .01));
      expect(slider.height, greaterThan(0));
      expect(minimum.width, greaterThan(0));
      expect(maximum.width, greaterThan(0));
      expect(inline.left, greaterThan(minimum.right));
      expect(inline.right, lessThan(maximum.left));
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-legend-lane')),
        findsNothing,
      );

      final rangeElement = tester.element(
        find.byKey(const ValueKey<String>('mind-query-amount-range')),
      );
      settings.setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();
      expect(
        tester.element(
          find.byKey(const ValueKey<String>('mind-query-amount-range')),
        ),
        same(rangeElement),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LEGEND-FINAL-03: inline legend owns no external lane and preserves 10/20 compact geometry',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.threeColumns,
          showMonthlyNetClose: false,
          showMonthlyDirectionTotal: false,
          revision: 0,
        ),
      );
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
        ),
      );

      final inline = find.byKey(
        const ValueKey<String>('mind-heatmap-inline-legend'),
      );
      final range = find.byKey(
        const ValueKey<String>('mind-query-amount-range'),
      );
      final rangeElement = tester.element(range);
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-legend-lane')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-palette-legend')),
        findsNothing,
      );
      expect(inline, findsOneWidget);
      final inlineRect = tester.getRect(inline);
      final minimum = tester.getRect(find.text('Min.').last);
      final maximum = tester.getRect(find.text('Max.').last);
      expect(inlineRect.left, greaterThan(minimum.right));
      expect(inlineRect.right, lessThan(maximum.left));
      for (var index = 0; index < 10; index += 1) {
        final swatch = tester.getRect(
          find.byKey(ValueKey('mind-heatmap-inline-swatch-$index')),
        );
        expect(swatch.width, closeTo(6, .01));
        expect(swatch.height, closeTo(6, .01));
      }

      settings.setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();
      expect(tester.element(range), same(rangeElement));
      final twentyInline = tester.getRect(inline);
      expect(twentyInline.width, lessThanOrEqualTo(100));
      for (var index = 0; index < 20; index += 1) {
        final swatch = tester.getRect(
          find.byKey(ValueKey('mind-heatmap-inline-swatch-$index')),
        );
        expect(swatch.width, closeTo(4, .01));
        expect(swatch.height, closeTo(4, .01));
      }

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.meadowGreen);
      await tester.pump();
      expect(inline, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-legend-lane')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-palette-legend')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SETTINGS-NO-DATA-MUTATION-01: presentation-only settings retain the admitted frame and compact range',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      const range = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 1000000,
        lowerScaled100: 100000,
        upperScaled100: 1000000,
      );
      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
          amountRange: range,
        ),
      );
      final admittedFrame = frame.value;
      final rangeElement = tester.element(
        find.byKey(const ValueKey<String>('mind-query-amount-range')),
      );
      settings
        ..setAnnualSurfaceStyle(MindYearHeatmapAnnualSurfaceStyle.directCells)
        ..setPaletteStyle(MindYearHeatmapPaletteStyle.fluviStretched)
        ..setScaleResolution(MindHeatmapScaleResolution.twenty);
      await tester.pump();

      expect(frame.value, same(admittedFrame));
      expect(
        tester.element(
          find.byKey(const ValueKey<String>('mind-query-amount-range')),
        ),
        same(rangeElement),
      );
      expect(
        tester
            .widget<RangeSlider>(
              find.byKey(const ValueKey<String>('query-amount-range-slider')),
            )
            .values,
        const RangeValues(100000, 1000000),
      );
    },
  );

  testWidgets(
    'LEGEND-FINAL-06: non-Year Mind uses the same fixed inline legend and range footer',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-heatmap-inline-legend')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('query-amount-range-slider')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'LEGEND-FINAL-03 RED: Sum, Year, Month and Day retain one always-inline legend and compact slider bounds',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final year = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final temporal = ValueNotifier<MindTemporalHeatmapFrame?>(_sumFrame());
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(year.dispose);
      addTearDown(temporal.dispose);
      addTearDown(rangeChanges.dispose);

      Future<(Rect footer, Rect legend, Rect slider, Rect minimum)> pumpPlane({
        required bool yearVisible,
        required TimePlane plane,
        bool temporalVisible = true,
      }) async {
        await tester.pumpWidget(
          _HostHarness(
            mode: mode,
            frame: year,
            temporalFrame: temporal,
            temporalPlane: plane,
            showYearHeatmap: yearVisible,
            showTemporalHeatmap: !yearVisible && temporalVisible,
            rangeChanges: rangeChanges,
            expansion: _ExpansionRecorder(),
          ),
        );
        return (
          tester.getRect(
            find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
          ),
          tester.getRect(
            find.byKey(const ValueKey('mind-heatmap-inline-legend')),
          ),
          tester.getRect(
            find.byKey(const ValueKey('query-amount-range-slider')),
          ),
          tester.getRect(find.text('Min.').last),
        );
      }

      final yearBounds = await pumpPlane(
        yearVisible: true,
        plane: TimePlane.year,
      );
      final sumBounds = await pumpPlane(
        yearVisible: false,
        plane: TimePlane.sum,
      );
      temporal.value = _monthFrame();
      final monthBounds = await pumpPlane(
        yearVisible: false,
        plane: TimePlane.month,
      );
      expect(
        find.byKey(const ValueKey('mind-month-heatmap-grid')),
        findsOneWidget,
      );
      // Day remains the existing Mind content (there is intentionally no
      // hourly heatmap), represented by the closed temporal projection lane.
      // Its compact range and palette footer must remain physically identical.
      final dayBounds = await pumpPlane(
        yearVisible: false,
        plane: TimePlane.month,
        temporalVisible: false,
      );

      expect(sumBounds.$1, yearBounds.$1);
      expect(monthBounds.$1, yearBounds.$1);
      expect(dayBounds.$1, yearBounds.$1);
      expect(sumBounds.$2, yearBounds.$2);
      expect(monthBounds.$2, yearBounds.$2);
      expect(dayBounds.$2, yearBounds.$2);
      expect(sumBounds.$3, yearBounds.$3);
      expect(monthBounds.$3, yearBounds.$3);
      expect(dayBounds.$3, yearBounds.$3);
      expect(sumBounds.$4, yearBounds.$4);
      expect(monthBounds.$4, yearBounds.$4);
      expect(dayBounds.$4, yearBounds.$4);
      expect(
        find.byKey(const ValueKey('mind-heatmap-legend-lane')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-heatmap-palette-legend')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-temporal-content-unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'FTR-03: one active compact range element keeps its held thumb values across Mind TimePlane changes',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final yearFrame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final temporalFrame = ValueNotifier<MindTemporalHeatmapFrame?>(
        _sumFrame(),
      );
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(yearFrame.dispose);
      addTearDown(temporalFrame.dispose);
      addTearDown(rangeChanges.dispose);

      Future<void> pumpPlane({
        required TimePlane plane,
        required bool yearVisible,
        required bool temporalVisible,
      }) => tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: yearFrame,
          temporalFrame: temporalFrame,
          temporalPlane: plane,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: yearVisible,
          showTemporalHeatmap: temporalVisible,
          amountRange: const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 1000000,
            lowerScaled100: 100000,
            upperScaled100: 1000000,
          ),
        ),
      );

      await pumpPlane(
        plane: TimePlane.year,
        yearVisible: true,
        temporalVisible: false,
      );
      final rangeFinder = find.byKey(
        const ValueKey<String>('mind-query-amount-range'),
      );
      final originalRangeElement = tester.element(rangeFinder);
      RangeSlider slider() => tester.widget<RangeSlider>(
        find.byKey(const ValueKey<String>('query-amount-range-slider')),
      );

      slider().onChangeStart!(const RangeValues(100000, 1000000));
      slider().onChanged!(const RangeValues(300000, 800000));
      await tester.pump();
      expect(slider().values, const RangeValues(300000, 800000));

      await pumpPlane(
        plane: TimePlane.sum,
        yearVisible: false,
        temporalVisible: true,
      );
      expect(tester.element(rangeFinder), same(originalRangeElement));
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(slider().values, const RangeValues(300000, 800000));

      temporalFrame.value = _monthFrame();
      await pumpPlane(
        plane: TimePlane.month,
        yearVisible: false,
        temporalVisible: true,
      );
      expect(tester.element(rangeFinder), same(originalRangeElement));
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(slider().values, const RangeValues(300000, 800000));

      // Day intentionally has no hourly heatmap, but its stable Mind body
      // slot must still retain the one physical slider while a drag is held.
      await pumpPlane(
        plane: TimePlane.month,
        yearVisible: false,
        temporalVisible: false,
      );
      expect(tester.element(rangeFinder), same(originalRangeElement));
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(slider().values, const RangeValues(300000, 800000));
      slider().onChangeEnd!(const RangeValues(300000, 800000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'YEAR-6R-09/10: four-column Year remains zero-scroll inside the real shared legend and footer envelope',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final settings = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: true,
          showMonthlyDirectionTotal: true,
          revision: 0,
        ),
      );
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: settings,
        ),
      );
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('mind-year-heatmap-fit-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.maxScrollExtent, 0);
      expect(find.byType(MindYearHeatmapMonthCard), findsNWidgets(12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'YEAR-HEIGHT-02 RED: 3 × 4 and 4 × 3 share one outer Mind envelope without shrinking the four-column card width',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final threeColumns = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.threeColumns,
          showMonthlyNetClose: false,
          showMonthlyDirectionTotal: false,
          revision: 0,
        ),
      );
      final fourColumns = MindYearHeatmapPresentationController(
        initial: const MindYearHeatmapPresentationSettings(
          paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
          monthCardLayout: MindYearMonthCardLayout.fourColumns,
          showMonthlyNetClose: false,
          showMonthlyDirectionTotal: false,
          revision: 0,
        ),
      );
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(threeColumns.dispose);
      addTearDown(fourColumns.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: threeColumns,
        ),
      );
      final threeColumnContent = tester.getRect(
        find.byKey(const ValueKey('mind-temporal-content-viewport')),
      );

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: true,
          presentationSettings: fourColumns,
        ),
      );
      final fourColumnContent = tester.getRect(
        find.byKey(const ValueKey('mind-temporal-content-viewport')),
      );
      final fourColumnCard = tester.getRect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
      );

      expect(fourColumnContent.height, closeTo(threeColumnContent.height, .01));
      expect(fourColumnCard.width, closeTo(83.5, .01));
      expect(
        MindYearHeatmapMonthCard.cellExtentFor(fourColumnCard.width),
        closeTo(8.5, .01),
        reason:
            'Parity is an outer-envelope change; the MonthCard width and its '
            'width-derived day-cell authority stay unchanged.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MBS-07 semantic Mind Header score updates independently from its paint lane',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final score = ValueNotifier<MindBehavioralScoreFrame?>(_score(63));
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(score.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
          score: score,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-header-score-text')),
        findsOneWidget,
      );
      expect(find.text('63/100'), findsOneWidget);
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-mind-header')),
      );
      final scoreRect = tester.getRect(
        find.byKey(const ValueKey('mind-header-score-text')),
      );
      expect(scoreRect.left - headerRect.left, closeTo(16, .01));
      expect(scoreRect.top - headerRect.top, closeTo(16, .01));
      expect(
        find.byKey(const ValueKey('mind-header-score-chart')),
        findsOneWidget,
      );

      score.value = _score(27);
      await tester.pump();
      expect(find.text('27/100'), findsOneWidget);
    },
  );

  testWidgets(
    'CHART-TAP-08/09: production Header forwards a chart clean tap passively while a vertical chart drag remains Header-owned',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final score = ValueNotifier<MindBehavioralScoreFrame?>(_score(63));
      final expansion = _ExpansionRecorder();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(score.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: expansion,
          showYearHeatmap: false,
          score: score,
        ),
      );
      final plot = find.byKey(
        const ValueKey<String>('mind-header-score-chart-paint'),
      );
      final drag = await tester.startGesture(tester.getCenter(plot));
      await drag.moveBy(const Offset(0, 48));
      await tester.pump();
      await drag.up();
      expect(expansion.starts, 1);
      expect(expansion.ends, 1);
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsNothing,
      );

      await tester.tap(plot, warnIfMissed: false);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsOneWidget,
      );
      expect(find.text('63/100'), findsNWidgets(2));
    },
  );

  testWidgets(
    'MHC-01 production Mind Header clips score history completely when collapsed',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final score = ValueNotifier<MindBehavioralScoreFrame?>(_score(63));
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(score.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
          score: score,
          collapseProgress: DashboardLayoutMetrics.reference.collapseTravel,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-header-score-chart')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-header-score-text')),
        findsOneWidget,
      );
    },
  );
}

final class _HostHarness extends StatelessWidget {
  const _HostHarness({
    required this.mode,
    required this.frame,
    required this.rangeChanges,
    required this.expansion,
    required this.showYearHeatmap,
    this.temporalFrame,
    this.temporalPlane,
    this.showTemporalHeatmap = false,
    this.presentationSettings,
    this.score,
    this.upperVerticalGestures,
    this.collapseProgress = 0,
    this.amountRange = const QueryAmountRangeValues(
      minimumScaled100: 1,
      maximumScaled100: 1000,
      lowerScaled100: 1,
      upperScaled100: 1000,
    ),
  });

  final DashboardCoreModeController mode;
  final ValueNotifier<MindYearHeatmapFrame?> frame;
  final ValueNotifier<MindTemporalHeatmapFrame?>? temporalFrame;
  final TimePlane? temporalPlane;
  final ValueNotifier<int> rangeChanges;
  final _ExpansionRecorder expansion;
  final bool showYearHeatmap;
  final bool showTemporalHeatmap;
  final MindYearHeatmapPresentationController? presentationSettings;
  final ValueNotifier<MindBehavioralScoreFrame?>? score;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;
  final double collapseProgress;
  final QueryAmountRangeValues amountRange;

  @override
  Widget build(BuildContext context) {
    final resolvedPlane =
        temporalPlane ?? (showYearHeatmap ? TimePlane.year : null);
    final modeContentExtraHeight =
        mode.committedMode == DashboardModeSpec.mind &&
            resolvedPlane == TimePlane.year
        ? presentationSettings?.value.requiredMindModeContentExtraHeight ?? 0.0
        : 0.0;
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: DashboardLayoutMetrics.reference.contentWidth + 34,
            height: DashboardLayoutMetrics.reference.canvasHeight,
            child: DashboardCoreModeHost(
              controller: mode,
              presentationFor: (mode) => DashboardCoreModePresentation(
                geometry: DashboardGeometryResolver.resolve(
                  metrics: DashboardLayoutMetrics.reference,
                  mode: mode,
                  collapseProgress: collapseProgress,
                  isRailExpanded: false,
                  modeContentExtraHeight: modeContentExtraHeight,
                ),
                palette: DashboardModePaletteResolver.resolve(mode),
              ),
              mindYearHeatmap: frame,
              mindTemporalHeatmap: temporalFrame,
              mindTemporalHeatmapPlane: temporalPlane,
              mindYearHeatmapPresentation: presentationSettings,
              mindBehavioralScore: score,
              mindYearHeatmapVisible: showYearHeatmap,
              mindTemporalHeatmapVisible: showTemporalHeatmap,
              mindQueryAmountRange: () => amountRange,
              mindQueryAmountRangeChanges: rangeChanges,
              onMindQueryAmountRangeCommitted: (_) {},
              onVerticalExpansionStart: expansion.begin,
              onVerticalExpansionDragBy: expansion.drag,
              onVerticalExpansionEnd: expansion.end,
              upperVerticalGestures: upperVerticalGestures,
            ),
          ),
        ),
      ),
    );
  }
}

final class _ExpansionRecorder {
  int starts = 0;
  int ends = 0;
  double delta = 0;

  void begin() => starts += 1;
  void drag(double value) => delta += value;
  void end() => ends += 1;
}

MindYearHeatmapFrame _frame() =>
    MindYearHeatmapProjection.build(
      identity: const MindYearHeatmapIdentity(
        upstreamScopeKey: 'expense|year:2025',
        indexGeneration: 1,
        coreRevision: 1,
        year: 2025,
        navigationEpoch: 0,
      ),
      entries: List<DashboardLedgerEntry>.generate(
        48,
        (index) => DashboardLedgerEntry(
          id: 'entry-$index',
          partnerId: 'p',
          categoryId: 'c',
          direction: 'expense',
          amountMinor: index + 1,
          bookedLocalEpochDay: LocalDate(
            year: 2025,
            month: index % 12 + 1,
            day: index % 4 + 1,
          ).epochDay,
          bookedLocalTimeMinutes: 0,
        ),
        growable: false,
      ),
    ).preview(
      const QueryAmountRangeValues(
        minimumScaled100: 1,
        maximumScaled100: 1000,
        lowerScaled100: 1,
        upperScaled100: 1000,
      ),
    );

MindSumHeatmapFrame _sumFrame() => MindSumHeatmapProjection.build(
  identity: const MindTemporalHeatmapIdentity(
    upstreamScopeKey: 'expense|all',
    indexGeneration: 1,
    coreRevision: 1,
    timeScopeKey: 'all',
  ),
  contributions: <MindYearHeatmapPreparedContribution>[
    _temporalContribution(
      0,
      100,
      const LocalDate(year: 2024, month: 1, day: 1),
    ),
    _temporalContribution(
      1,
      500,
      const LocalDate(year: 2025, month: 5, day: 2),
    ),
  ],
).preview(_temporalRange);

MindMonthHeatmapFrame _monthFrame() => MindMonthHeatmapProjection.build(
  identity: const MindTemporalHeatmapIdentity(
    upstreamScopeKey: 'expense|month:2025-05',
    indexGeneration: 1,
    coreRevision: 1,
    timeScopeKey: 'month:2025-05',
  ),
  year: 2025,
  month: 5,
  contributions: <MindYearHeatmapPreparedContribution>[
    _temporalContribution(
      1,
      500,
      const LocalDate(year: 2025, month: 5, day: 2),
    ),
  ],
).preview(_temporalRange);

const _temporalRange = QueryAmountRangeValues(
  minimumScaled100: 1,
  maximumScaled100: 1000,
  lowerScaled100: 1,
  upperScaled100: 1000,
);

MindYearHeatmapPreparedContribution _temporalContribution(
  int ordinal,
  int amount,
  LocalDate date,
) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  bookedLocalEpochDay: date.epochDay,
  amountMinor: amount,
);

MindBehavioralScoreFrame _score(double value) {
  final point = MindBehavioralScorePoint(
    epochDay: const LocalDate(year: 2025, month: 1, day: 1).epochDay,
    score: value,
    noSignal: false,
  );
  return MindBehavioralScoreFrame(
    identity: const MindBehavioralScoreIdentity(
      upstreamScopeKey: 'expense|all',
      indexGeneration: 1,
      coreRevision: 1,
      direction: LedgerDirection.expense,
    ),
    range: const QueryAmountRangeValues(
      minimumScaled100: 1,
      maximumScaled100: 1000,
      lowerScaled100: 1,
      upperScaled100: 1000,
    ),
    point: point,
    chartSeries: MindBehavioralScoreChartSeries(
      startInclusiveEpochDay: point.epochDay,
      endInclusiveEpochDay: point.epochDay,
      points: <MindBehavioralScorePoint>[point],
    ),
  );
}
