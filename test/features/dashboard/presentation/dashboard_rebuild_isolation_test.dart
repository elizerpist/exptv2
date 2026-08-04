import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/motion/dashboard_motion_host.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';

void main() {
  testWidgets(
    'a query result tick does not rebuild the dashboard motion host',
    (tester) async {
      final controller = DashboardCoreController(autoStartQuery: false);
      addTearDown(controller.dispose);
      var hostBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardMotionHost(
            controller: controller,
            mode: DashboardModeSpec.balance,
            builder: (context, frame) {
              hostBuildCount += 1;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final countBeforeQuery = hostBuildCount;
      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.dashboardRootBuild,
        ),
        countBeforeQuery,
      );
      final scope = controller.query.state.scope;

      expect(
        controller.query.commitPreparedResult(
          scope,
          DashboardLedgerResult(
            totalMinor: 12345,
            entryCount: 7,
            coreRevision: 2,
            scopeKey: scope.key.value,
            direction: scope.direction.name,
          ),
          reason: 'rebuildIsolationProbe',
        ),
        isTrue,
      );
      await tester.pump();

      expect(hostBuildCount, countBeforeQuery);
      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.dashboardRootBuild,
        ),
        countBeforeQuery,
      );
    },
  );

  testWidgets(
    'a child preview tick does not rebuild the dashboard motion host',
    (tester) async {
      final controller = DashboardCoreController(autoStartQuery: false);
      addTearDown(controller.dispose);
      var hostBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardMotionHost(
            controller: controller,
            mode: DashboardModeSpec.balance,
            builder: (context, frame) {
              hostBuildCount += 1;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final countBeforePreview = hostBuildCount;

      controller.rail.previewChildLogicalIndex(
        controller.rail.selectedChildLogicalIndex + 1,
      );
      await tester.pump();

      expect(hostBuildCount, countBeforePreview);
    },
  );
}
