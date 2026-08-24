import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';

import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/test_pump.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  for (final mode in DashboardModeSpec.values) {
    testWidgets('${mode.mode.name} expanded core geometry matches golden', (
      tester,
    ) async {
      final harness = await _pumpMode(tester, mode);
      addTearDown(harness.dispose);

      await expectLater(
        find.byKey(const ValueKey('core-dashboard')),
        matchesGoldenFile(_expandedGoldenPath(mode)),
      );
    });

    testWidgets('${mode.mode.name} collapsed Ledger geometry matches golden', (
      tester,
    ) async {
      final harness = await _pumpMode(tester, mode);
      addTearDown(harness.dispose);
      harness.controller.expansion.setProgress(
        harness.controller.metrics.collapseTravel,
      );
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('core-dashboard')),
        matchesGoldenFile(_collapsedGoldenPath(mode)),
      );
    });
  }
}

Future<_DashboardHarness> _pumpMode(
  WidgetTester tester,
  DashboardModeSpec mode,
) async {
  final controller = DashboardCoreController(initialCoreRevision: 1);
  await controller.bootstrap();
  final modeController = DashboardCoreModeController(initialMode: mode);
  await pumpDashboardSurface(
    tester,
    CoreDashboard(
      controller: controller,
      modeController: modeController,
      categoryCollection: emptyTestCategoryCollection,
    ),
  );
  return _DashboardHarness(controller, modeController);
}

String _expandedGoldenPath(DashboardModeSpec mode) {
  if (mode == DashboardModeSpec.balance) {
    return '../../../goldens/core_dashboard_expanded.png';
  }
  if (mode == DashboardModeSpec.budget) {
    return '../../../goldens/core_dashboard_budget_expanded.png';
  }
  if (mode == DashboardModeSpec.mind) {
    return '../../../goldens/core_dashboard_mind_expanded.png';
  }
  throw ArgumentError.value(mode, 'mode');
}

String _collapsedGoldenPath(DashboardModeSpec mode) {
  if (mode == DashboardModeSpec.balance) {
    return '../../../goldens/core_dashboard_collapsed.png';
  }
  if (mode == DashboardModeSpec.budget) {
    return '../../../goldens/core_dashboard_budget_collapsed.png';
  }
  if (mode == DashboardModeSpec.mind) {
    return '../../../goldens/core_dashboard_mind_collapsed.png';
  }
  throw ArgumentError.value(mode, 'mode');
}

class _DashboardHarness {
  const _DashboardHarness(this.controller, this.modeController);

  final DashboardCoreController controller;
  final DashboardCoreModeController modeController;

  void dispose() {
    modeController.dispose();
    controller.dispose();
  }
}
