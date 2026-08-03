import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../support/test_pump.dart';

void main() {
  testWidgets('app shell renders the selected BNB-03 dashboard navigation', (
    tester,
  ) async {
    await pumpDashboardSurface(tester, const FluviApp());

    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.byType(Bnb03BottomNavigation), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  for (final spec in DashboardModeSpec.values) {
    testWidgets('one CoreDashboard renders ${spec.mode.name}', (tester) async {
      final controller = DashboardCoreController();
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: spec, controller: controller),
      );

      expect(find.byType(CoreDashboard), findsOneWidget);
      expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-split-subheader-one')),
        spec == DashboardModeSpec.mind ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-unified-subheader')),
        spec == DashboardModeSpec.mind ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('does not render the retired search and filter controls', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);

    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    expect(find.text('Keresés tranzakciók között…'), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.filter_list_rounded), findsNothing);
  });

  testWidgets('keeps the native dashboard content at its reference origin', (
    tester,
  ) async {
    const surfaceSize = Size(412, 892);
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: surfaceSize,
          viewPadding: EdgeInsets.only(top: 32),
          padding: EdgeInsets.only(top: 32),
          textScaler: TextScaler.linear(1),
          disableAnimations: true,
        ),
        child: MaterialApp(
          home: CoreDashboard(
            mode: DashboardModeSpec.balance,
            controller: controller,
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('fluvi-brand-mark'))).dy,
      52,
    );
  });

  testWidgets('shared gestures map only to their owning controllers', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    final handle = find.byKey(const ValueKey('dashboard-collapse-handle'));
    await tester.drag(handle, const Offset(0, -180));
    await tester.pump();
    expect(
      controller.expansion.progress,
      DashboardLayoutMetrics.reference.collapseTravel,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('dashboard-action-row'))).dy,
      DashboardLayoutMetrics.reference.headerTop +
          DashboardLayoutMetrics.reference.headerCollapsedHeight +
          DashboardLayoutMetrics.reference.standardGap,
    );

    await tester.tap(handle);
    await tester.pump();
    expect(controller.expansion.progress, 0);

    await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
    await tester.pump();
    expect(controller.rail.isExpanded, isTrue);
    expect(find.byKey(const ValueKey('dashboard-time-rail')), findsOneWidget);

    final expansionBeforeRailDrag = controller.expansion.progress;
    final parentScopeBeforeRailDrag = controller.rail.state.parentScope;
    await tester.drag(
      find.byKey(const ValueKey('dashboard-time-rail')),
      const Offset(-180, 0),
    );
    await tester.pump();
    expect(controller.expansion.progress, expansionBeforeRailDrag);
    expect(controller.rail.state.parentScope, parentScopeBeforeRailDrag);

    await tester.tap(find.text('Kiadás'));
    await tester.pump();
    expect(controller.transactionDirection.direction.name, 'expense');
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('dashboard-action-row')))
          .properties
          .label,
      'Kiadás',
    );
  });

  testWidgets('closed dashboard does not mount the time rail viewport', (
    tester,
  ) async {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.rail.isRailOpen, isFalse);
      expect(find.byType(TimeRefinementRail), findsNothing);
      expect(find.byKey(const ValueKey('dashboard-time-rail')), findsNothing);
      expect(controller.rail.state.navigationRevision, 0);
      expect(controller.rail.state.previewChild, isNull);
      expect(controller.rail.state.settledChildDay, 14);
      expect(controller.rail.timeCarousel.selectedLogicalIndex, 13);

      controller.rail.setRailOpen(true);
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.byType(TimeRefinementRail), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard-time-rail')), findsOneWidget);
    },
  );

  testWidgets(
    'SummaryPill commits one vertical plane and one horizontal parent transition',
    (tester) async {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );
      final pill = find.byType(DashboardSummaryPill);

      await tester.drag(pill, const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 120));
      expect(controller.rail.state.plane, TimePlane.sum);
      expect(controller.rail.state.navigationRevision, 1);
      expect(
        controller.query.state.scope.timeScope,
        controller.rail.state.effectiveScope,
      );

      await tester.drag(pill, const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 120));
      expect(controller.rail.state.plane, TimePlane.month);
      expect(controller.rail.state.navigationRevision, 2);

      await tester.drag(pill, const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        controller.rail.state.monthCursor,
        const YearMonth(year: 2026, month: 8),
      );
      expect(controller.rail.state.navigationRevision, 3);
      expect(
        controller.query.state.scope.timeScope,
        controller.rail.state.effectiveScope,
      );
    },
  );

  testWidgets('split header lower card reveals from behind the upper card', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    final expandedLowerRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-split-zone2')),
    );

    controller.expansion.setProgress(controller.metrics.collapseTravel);
    await tester.pump();

    final collapsedUpperRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-split-subheader-one')),
    );
    final collapsedLowerRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-split-zone2')),
    );

    expect(collapsedUpperRect.top, closeTo(160, .01));
    expect(collapsedLowerRect.top, closeTo(200, .01));
    expect(collapsedLowerRect.width, closeTo(293.76, .01));
    expect(collapsedLowerRect.width, lessThan(expandedLowerRect.width));
    expect(collapsedLowerRect.top, lessThan(expandedLowerRect.top));
  });

  testWidgets('split header indicators slide with the lower card', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    final expandedIndicatorTop = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-zone2-indicators')))
        .dy;
    final expandedLowerTop = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-split-zone2')))
        .dy;

    controller.expansion.setProgress(90);
    await tester.pump();

    final collapsedIndicatorTop = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-zone2-indicators')))
        .dy;
    final collapsedLowerTop = tester
        .getTopLeft(find.byKey(const ValueKey('dashboard-split-zone2')))
        .dy;

    expect(
      collapsedIndicatorTop - expandedIndicatorTop,
      closeTo(collapsedLowerTop - expandedLowerTop, .01),
    );
  });

  testWidgets(
    'maps a normalized half-scale collapse drag to the controller endpoint',
    (tester) async {
      const halfSurface = Size(206, 446);
      final controller = DashboardCoreController();
      addTearDown(controller.dispose);
      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
        surfaceSize: halfSurface,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-collapse-handle')),
        const Offset(0, -90),
      );
      await tester.pump();

      final viewportMetrics = controller.metrics.fitToViewport(halfSurface);
      expect(controller.expansion.progress, controller.metrics.collapseTravel);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('dashboard-action-row')))
            .dy,
        viewportMetrics.headerTop +
            viewportMetrics.headerCollapsedHeight +
            viewportMetrics.standardGap,
      );
    },
  );
}
