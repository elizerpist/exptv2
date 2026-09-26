import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart';
import 'package:fluvi/core/design/dashboard_body_order.dart';
import 'package:fluvi/core/design/dashboard_core_mode_presentation.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/transaction_direction_toggle.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  test('appearance defaults expose independent Header and rail chrome', () {
    const appearance = FluviGlobalAppearance.defaults();

    expect(
      appearance.directionControlStyle,
      FluviDirectionControlStyle.splitButtons,
    );
    expect(appearance.collapseHandleStyle, FluviCollapseHandleStyle.standalone);
    expect(appearance.showsHeaderModeLabelAboveValue, isFalse);
    expect(
      appearance.inactiveDirectionLabelTone,
      FluviInactiveDirectionLabelTone.softenedGray,
    );
  });

  test('integrated handles reclaim the canonical lower handle footprint', () {
    final frame = DashboardGeometryResolver.resolve(
      metrics: DashboardLayoutMetrics.reference,
      mode: DashboardModeSpec.balance,
      collapseProgress: 0.0,
      isRailExpanded: false,
      hasStandaloneCollapseHandle: false,
    );

    expect(frame.collapseHandleBounds.height, 0.0);
    expect(frame.logBoxHeaderBounds.top, 695.0);
    expect(
      frame.headerCollapseHandleBounds!.top +
          frame.headerCollapseHandleBounds!.height / 2,
      frame.headerBounds.bottom,
    );
  });

  test('sliding rail keeps its gradient in full rail coordinates', () {
    const size = Size(300, 48);
    final start = DirectionRailGeometry.resolve(size: size, position: 0);
    final middle = DirectionRailGeometry.resolve(size: size, position: .5);
    final end = DirectionRailGeometry.resolve(size: size, position: 1);

    expect(start.fullGradientRect, Offset.zero & size);
    expect(middle.fullGradientRect, start.fullGradientRect);
    expect(end.fullGradientRect, start.fullGradientRect);
    expect(middle.pillRect.left, closeTo(size.width * .25, 3));
    expect(middle.pillRect.right, closeTo(size.width * .75, 3));
    expect(start.pillRect.left, lessThan(middle.pillRect.left));
    expect(end.pillRect.left, greaterThan(middle.pillRect.left));
  });

  test('appearance chrome choices preserve unrelated selections', () {
    const original = FluviGlobalAppearance.defaults();
    final changed = original.copyWith(
      directionControlStyle: FluviDirectionControlStyle.slidingRail,
      collapseHandleStyle: FluviCollapseHandleStyle.headerTranslucentPill,
      activeDirectionLabelTone: FluviActiveDirectionLabelTone.black,
      inactiveDirectionLabelTone: FluviInactiveDirectionLabelTone.black,
      showsHeaderModeLabelAboveValue: true,
    );

    expect(changed.directionColorProfile, original.directionColorProfile);
    expect(changed.avatarColorProfile, original.avatarColorProfile);
    expect(changed.showsDirectionArtwork, original.showsDirectionArtwork);
    expect(changed.typography, original.typography);
    expect(
      FluviInactiveDirectionLabelTone.values.contains(
        // This exact invalid alternative cannot be represented by the model.
        FluviInactiveDirectionLabelTone.softenedGray,
      ),
      isTrue,
    );
    expect(FluviInactiveDirectionLabelTone.values.length, 2);
  });

  test('Mind expanded surface defaults to separate cards', () {
    expect(
      const FluviGlobalAppearance.defaults().mindExpandedSurfaceStyle,
      MindExpandedSurfaceStyle.separateCards,
    );
  });

  test('Budget avatar/content relationship defaults to separate', () {
    expect(
      const FluviGlobalAppearance.defaults().budgetAvatarContentStyle,
      BudgetAvatarContentStyle.separate,
    );
  });

  test('seamless Mind geometry owns a real zero-radius internal seam', () {
    const header = BorderRadius.all(Radius.circular(20));
    const content = BorderRadius.all(Radius.circular(16));
    final midpoint = MindExpandedSurfaceShape.resolve(
      seamless: true,
      headerRadius: header,
      contentRadius: content,
      expansionProgress: .5,
    );
    final expanded = MindExpandedSurfaceShape.resolve(
      seamless: true,
      headerRadius: header,
      contentRadius: content,
      expansionProgress: 1,
    );

    expect(midpoint.headerRadius.bottomLeft.x, greaterThan(0));
    expect(midpoint.headerRadius.bottomLeft.x, lessThan(20));
    expect(expanded.headerRadius.bottomLeft, Radius.zero);
    expect(expanded.headerRadius.bottomRight, Radius.zero);
    expect(expanded.contentRadius.topLeft, Radius.zero);
    expect(expanded.contentRadius.topRight, Radius.zero);
    expect(expanded.headerRadius.topLeft.x, 20);
    expect(expanded.contentRadius.bottomLeft.x, 16);

    for (final progress in <double>[0, .5, 1]) {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.mind,
        collapseProgress:
            DashboardLayoutMetrics.reference.collapseTravel * progress,
        isRailExpanded: false,
        bodyOrder: DashboardBodyOrder(<DashboardBodyComponent>[
          DashboardBodyComponent.modeContent,
          DashboardBodyComponent.direction,
          DashboardBodyComponent.summary,
        ]),
        seamlessHeaderContent: true,
      );
      expect(frame.seamlessHeaderContent, isTrue);
      expect(frame.unifiedSubheaderBounds!.top, frame.headerBounds.bottom);
    }
  });

  test('Budget relationship moves only the detail card for overlap', () {
    const avatars = DashboardBounds(left: 17, top: 374, width: 378, height: 72);
    const chart = DashboardBounds(left: 17, top: 457, width: 378, height: 220);
    const dots = DashboardBounds(left: 17, top: 682, width: 378, height: 6);
    final separate = BudgetAvatarContentRelationship.resolve(
      avatarBounds: avatars,
      chartBounds: chart,
      indicatorBounds: dots,
      style: BudgetAvatarContentStyle.separate,
      avatarsLeadContent: true,
    );
    final overlap = BudgetAvatarContentRelationship.resolve(
      avatarBounds: avatars,
      chartBounds: chart,
      indicatorBounds: dots,
      style: BudgetAvatarContentStyle.overlappingGlow,
      avatarsLeadContent: true,
    );
    final rail = BudgetAvatarContentRelationship.resolve(
      avatarBounds: avatars,
      chartBounds: chart,
      indicatorBounds: dots,
      style: BudgetAvatarContentStyle.avatarRail,
      avatarsLeadContent: true,
    );

    expect(separate.avatarBounds, avatars);
    expect(separate.chartBounds, chart);
    expect(overlap.avatarBounds, avatars);
    expect(overlap.chartBounds.top, lessThan(chart.top));
    expect(overlap.indicatorBounds.top, lessThan(dots.top));
    expect(rail.avatarBounds, avatars);
    expect(rail.chartBounds, chart);
  });

  testWidgets('Mind seamless surface has one real Header/body silhouette', (
    tester,
  ) async {
    DashboardCoreModePresentation presentationFor(double collapseProgress) {
      final geometry = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.mind,
        collapseProgress: collapseProgress,
        isRailExpanded: false,
        bodyOrder: DashboardBodyOrder(<DashboardBodyComponent>[
          DashboardBodyComponent.modeContent,
          DashboardBodyComponent.direction,
          DashboardBodyComponent.summary,
        ]),
        seamlessHeaderContent: true,
      );
      return DashboardCoreModePresentation(
        geometry: geometry,
        palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.mind),
      );
    }

    for (final collapseProgress in <double>[0, 90, 180]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                MindDashboardCoreSurface(
                  presentation: presentationFor(collapseProgress),
                  expandedSurfaceStyle: MindExpandedSurfaceStyle.seamlessCard,
                ),
              ],
            ),
          ),
        ),
      );
      final header = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-mind-header')),
      );
      final body = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
      );
      expect(body.top, header.bottom);
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-mind-seamless-surface')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'appearance tuner exposes Header-handle and sliding-rail controls',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.toggleTunerSection(DashboardHeaderTunerSection.appearance);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('fluvi-direction-control-style-slidingRail'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('fluvi-collapse-handle-style-headerNotch'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('fluvi-header-mode-label-enabled')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('fluvi-mind-expanded-surface-seamlessCard'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('fluvi-budget-avatar-content-overlappingGlow'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('fluvi-direction-inactive-text-white'),
        ),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    },
  );

  testWidgets('sliding rail owns one surface and fixed semantic halves', (
    tester,
  ) async {
    final selections = <TransactionDirection>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionDirectionToggle(
            bounds: const DashboardBounds(
              left: 0,
              top: 0,
              width: 320,
              height: 48,
            ),
            selectedDirection: TransactionDirection.income,
            incomeIconScale: 1,
            expenseIconScale: 1,
            directionControlStyle: FluviDirectionControlStyle.slidingRail,
            onSelected: selections.add,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('fluvi-direction-sliding-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('fluvi-direction-sliding-rail-active-pill'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fluvi-income-button')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('fluvi-direction-rail-expense')),
    );
    expect(selections, <TransactionDirection>[TransactionDirection.expense]);
  });

  testWidgets('every handle chrome keeps the one tap target', (tester) async {
    var taps = 0;
    for (final style in FluviCollapseHandleStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: DashboardCollapseHandle(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 88,
                height: 28,
              ),
              style: style,
              onTap: () => taps += 1,
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-collapse-handle')),
      );
      expect(taps, FluviCollapseHandleStyle.values.indexOf(style) + 1);
      if (style != FluviCollapseHandleStyle.standalone) {
        expect(
          find.byKey(
            ValueKey<String>('dashboard-collapse-handle-${style.name}'),
          ),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('every handle chrome forwards the existing vertical drag path', (
    tester,
  ) async {
    for (final style in FluviCollapseHandleStyle.values) {
      var starts = 0;
      var updates = 0;
      var ends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: DashboardCollapseHandle(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 88,
                height: 28,
              ),
              style: style,
              onTap: () {},
              onVerticalDragStart: (_) => starts += 1,
              onVerticalDragUpdate: (_) => updates += 1,
              onVerticalDragEnd: (_) => ends += 1,
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey<String>('dashboard-collapse-handle')),
        ),
      );
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -12));
      await tester.pump();
      await gesture.up();
      expect(starts, 1, reason: '${style.name} must keep the shared start');
      expect(updates, greaterThan(0));
      expect(ends, 1, reason: '${style.name} must keep the shared end');
    }
  });
}
