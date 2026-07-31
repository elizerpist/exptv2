import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';

import '../../../support/test_pump.dart';

void main() {
  testWidgets('renders the reference expanded dashboard at 412 by 892', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    addTearDown(controller.dispose);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    await expectLater(
      find.byKey(const ValueKey('core-dashboard')),
      matchesGoldenFile('../../../goldens/core_dashboard_expanded.png'),
    );
  });

  testWidgets('renders the fully collapsed dashboard at 412 by 892', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    controller.expansion.setProgress(controller.metrics.collapseTravel);
    addTearDown(controller.dispose);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    await expectLater(
      find.byKey(const ValueKey('core-dashboard')),
      matchesGoldenFile('../../../goldens/core_dashboard_collapsed.png'),
    );
  });
}
