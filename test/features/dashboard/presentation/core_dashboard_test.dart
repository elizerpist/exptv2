import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';

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
    await tester.drag(
      find.byKey(const ValueKey('dashboard-time-rail')),
      const Offset(-180, 0),
    );
    await tester.pump();
    expect(controller.expansion.progress, expansionBeforeRailDrag);

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

    expect(collapsedUpperRect.top, closeTo(223, .01));
    expect(collapsedLowerRect.top, closeTo(263, .01));
    expect(collapsedLowerRect.width, closeTo(328.32, .01));
    expect(collapsedLowerRect.width, lessThan(expandedLowerRect.width));
    expect(collapsedLowerRect.top, lessThan(expandedLowerRect.top));
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
