import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';

import '../../../support/test_pump.dart';

void main() {
  testWidgets(
    'app shell fixes Dashboard active and disables placeholder actions',
    (tester) async {
      await pumpDashboardSurface(tester, const FluviApp());

      expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard-nav-item')), findsOneWidget);
      expect(find.byKey(const ValueKey('fluvi-center-fab')), findsOneWidget);
      final fabSemantics = tester.getSemantics(
        find.byKey(const ValueKey('fluvi-center-fab')),
      );
      final settingsSemantics = tester.getSemantics(
        find.byKey(const ValueKey('settings-nav-item')),
      );
      expect(fabSemantics.flagsCollection.isButton, isTrue);
      expect(fabSemantics.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      expect(settingsSemantics.flagsCollection.isButton, isTrue);
      expect(
        settingsSemantics.flagsCollection.isEnabled.toBoolOrNull(),
        isFalse,
      );

      await tester.tap(
        find.byKey(const ValueKey('fluvi-center-fab')),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-nav-item')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    },
  );

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
}
