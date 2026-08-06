import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/motion/dashboard_motion_host.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  testWidgets('one hundred visible child frames do not rebuild motion host', (
    tester,
  ) async {
    final controller = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 1,
    );
    addTearDown(controller.dispose);
    await controller.bootstrap();
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
    controller.setRailOpen(true);
    await tester.pumpAndSettle();
    final countBeforeCrossings = hostBuildCount;

    for (var index = 0; index < 100; index += 1) {
      controller.semanticCrossed(index);
    }
    await tester.pump();

    expect(hostBuildCount, countBeforeCrossings);
    expect(
      controller.performanceCounters.value(
        DashboardPerformanceMetric.dashboardRootBuild,
      ),
      countBeforeCrossings,
    );
    expect(controller.frameCoalescer.maximumPublishesInOneDisplayFrame, 1);
  });

  testWidgets('visible data publication does not restart direction pulse', (
    tester,
  ) async {
    final controller = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 1,
    );
    addTearDown(controller.dispose);
    await controller.bootstrap();
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
    controller.setRailOpen(true);
    await tester.pumpAndSettle();
    final pulseRevision = controller.transactionDirection.pulseRevision;
    final builds = hostBuildCount;

    controller.semanticCrossed(20);
    await tester.pump();

    expect(controller.transactionDirection.pulseRevision, pulseRevision);
    expect(hostBuildCount, builds);
  });

  testWidgets(
    'semantic child frames rebuild the count leaf, not header shell',
    (tester) async {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: CoreDashboard(
            mode: DashboardModeSpec.balance,
            controller: controller,
          ),
        ),
      );
      controller.setRailOpen(true);
      await tester.pumpAndSettle();
      final headerBuilds = controller.performanceCounters.value(
        DashboardPerformanceMetric.headerSubtreeBuild,
      );

      controller.semanticCrossed(18);
      await tester.pump();
      controller.semanticCrossed(19);
      await tester.pump();

      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.headerSubtreeBuild,
        ),
        headerBuilds,
      );
      expect(
        find.byKey(const ValueKey('dashboard-logbox-entry-count')),
        findsOne,
      );
    },
  );

  testWidgets(
    'rail State, controller, physics and ScrollPosition survive 100 changes',
    (tester) async {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: CoreDashboard(
            mode: DashboardModeSpec.balance,
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      final rail = find.byKey(const ValueKey('dashboard-time-rail'));
      final railState = tester.state(rail);
      final carousel = controller.motion.carouselController;
      final scrollController = carousel.scrollController;
      final position = scrollController.position;
      final physics = controller.motion.dashboardPhysics;

      for (var index = 0; index < 100; index += 1) {
        switch (index % 4) {
          case 0:
            controller.setRailOpen(!controller.navigation.state.isRailOpen);
          case 1:
            controller.navigatePlane(finer: index.isEven);
          case 2:
            controller.selectDirection(
              index.isEven
                  ? TransactionDirection.income
                  : TransactionDirection.expense,
            );
          case 3:
            if (controller.navigation.state.plane == TimePlane.sum) {
              controller.navigatePlane(finer: true);
            } else {
              controller.navigateParent(
                index.isEven
                    ? DashboardTimeNavigationChangeDirection.forward
                    : DashboardTimeNavigationChangeDirection.backward,
              );
            }
        }
        await tester.pump();
      }

      expect(identical(tester.state(rail), railState), isTrue);
      expect(identical(controller.motion.carouselController, carousel), isTrue);
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(identical(controller.motion.dashboardPhysics, physics), isTrue);
      expect(carousel.physicsCreationCount, 1);
      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.controllerRecreation,
        ),
        0,
      );
      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.physicsRecreation,
        ),
        0,
      );
      expect(
        controller.performanceCounters.value(
          DashboardPerformanceMetric.scrollPositionRecreation,
        ),
        0,
      );
    },
  );
}
