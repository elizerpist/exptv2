import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_experiments.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'structural dashboard changes preserve the segmented selector controller, position and physics',
    (tester) async {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      final modeController = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);
      addTearDown(modeController.dispose);
      await controller.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: CoreDashboard(
            controller: controller,
            modeController: modeController,
            categoryCollection: emptyTestCategoryCollection,
          ),
        ),
      );
      await tester.pump();
      final selector = find.byKey(
        const ValueKey('summary-pill-segmented-mode-selector'),
      );
      final selectorState = tester.state(selector);
      final carouselFinder = find.descendant(
        of: selector,
        matching: find.byType(CenteredCarousel<SummaryPillExperimentLevel>),
      );
      final carousel = tester
          .widget<CenteredCarousel<SummaryPillExperimentLevel>>(carouselFinder)
          .controller;
      final scrollController = carousel.scrollController;
      final position = scrollController.position;
      final physicsCreationCount = carousel.physicsCreationCount;

      for (var index = 0; index < 16; index += 1) {
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

      expect(identical(tester.state(selector), selectorState), isTrue);
      expect(
        identical(
          tester
              .widget<CenteredCarousel<SummaryPillExperimentLevel>>(
                carouselFinder,
              )
              .controller,
          carousel,
        ),
        isTrue,
      );
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(carousel.physicsCreationCount, physicsCreationCount);
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
