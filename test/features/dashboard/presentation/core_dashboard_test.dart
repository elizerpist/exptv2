import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/data/empty_category_repository.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';

import '../../../support/test_pump.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets('app shell renders the selected BNB-03 dashboard navigation', (
    tester,
  ) async {
    await pumpDashboardSurface(
      tester,
      const FluviApp(
        dashboardRepository: EmptyDashboardDataRuntimeRepository(),
        categoryRepository: EmptyCategoryRepository(),
      ),
    );

    expect(find.byKey(const ValueKey('fluvi-app-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-bootstrap-surface')),
      findsOneWidget,
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
    expect(find.byType(Bnb03BottomNavigation), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets(
    'RED: app shell lets the LogBox viewport reach the physical bottom behind navigation',
    (tester) async {
      await pumpDashboardSurface(
        tester,
        const FluviApp(
          dashboardRepository: EmptyDashboardDataRuntimeRepository(),
          categoryRepository: EmptyCategoryRepository(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final bottomNavigation = find.byType(Bnb03BottomNavigation);

      expect(scrollView, findsOneWidget);
      expect(bottomNavigation, findsOneWidget);
      expect(
        tester.getRect(scrollView).bottom,
        closeTo(
          tester.getRect(find.byKey(const ValueKey('fluvi-app-shell'))).bottom,
          0.1,
        ),
        reason:
            'The shell owns the navigation overlay. The LogBox viewport must '
            'reach the physical body bottom; only terminal scroll content may '
            'protect the final card.',
      );
      expect(
        tester.getRect(scrollView).bottom,
        greaterThan(tester.getRect(bottomNavigation).top),
      );
    },
  );

  for (final spec in DashboardModeSpec.values) {
    testWidgets('one CoreDashboard renders ${spec.mode.name}', (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: _modeControllerFor(spec),
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      expect(find.byType(CoreDashboard), findsOneWidget);
      expect(find.byKey(const ValueKey('core-dashboard')), findsOneWidget);
      expect(
        find.byKey(ValueKey('dashboard-core-mode-${spec.mode.name}-card-1')),
        spec == DashboardModeSpec.mind ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
        spec == DashboardModeSpec.mind ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('does not render the retired search and filter controls', (
    tester,
  ) async {
    final controller = DashboardCoreController(initialCoreRevision: 1);
    addTearDown(controller.dispose);
    await controller.bootstrap();

    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: controller,
        modeController: _modeControllerFor(DashboardModeSpec.balance),
        categoryCollection: emptyTestCategoryCollection,
      ),
    );

    expect(find.text('Keresés tranzakciók között…'), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.filter_list_rounded), findsNothing);
  });

  testWidgets('keeps the native dashboard content at its reference origin', (
    tester,
  ) async {
    const surfaceSize = Size(412, 892);
    final controller = DashboardCoreController(initialCoreRevision: 1);
    addTearDown(controller.dispose);
    await controller.bootstrap();
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
            controller: controller,
            modeController: _modeControllerFor(DashboardModeSpec.balance),
            categoryCollection: emptyTestCategoryCollection,
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
    final controller = DashboardCoreController(initialCoreRevision: 1);
    addTearDown(controller.dispose);
    await controller.bootstrap();
    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: controller,
        modeController: _modeControllerFor(DashboardModeSpec.balance),
        categoryCollection: emptyTestCategoryCollection,
      ),
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
    expect(controller.navigation.isRailOpen, isTrue);
    expect(find.byKey(const ValueKey('dashboard-time-rail')), findsOneWidget);

    final expansionBeforeRailDrag = controller.expansion.progress;
    final parentScopeBeforeRailDrag = controller.navigation.state.parentScope;
    await tester.drag(
      find.byKey(const ValueKey('dashboard-time-rail')),
      const Offset(-180, 0),
    );
    await tester.pump();
    expect(controller.expansion.progress, expansionBeforeRailDrag);
    expect(controller.navigation.state.parentScope, parentScopeBeforeRailDrag);

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
    final controller = DashboardCoreController(initialCoreRevision: 1);
    addTearDown(controller.dispose);
    await controller.bootstrap();
    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: controller,
        modeController: _modeControllerFor(DashboardModeSpec.balance),
        categoryCollection: emptyTestCategoryCollection,
      ),
    );

    final expandedLowerRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-balance-card-2')),
    );

    controller.expansion.setProgress(controller.metrics.collapseTravel);
    await tester.pump();

    final collapsedUpperRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-balance-card-1')),
    );
    final collapsedLowerRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-balance-card-2')),
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
    final controller = DashboardCoreController(initialCoreRevision: 1);
    addTearDown(controller.dispose);
    await controller.bootstrap();
    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: controller,
        modeController: _modeControllerFor(DashboardModeSpec.balance),
        categoryCollection: emptyTestCategoryCollection,
      ),
    );

    final expandedIndicatorTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('dashboard-core-mode-balance-dots')),
        )
        .dy;
    final expandedLowerTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('dashboard-core-mode-balance-card-2')),
        )
        .dy;

    controller.expansion.setProgress(90);
    await tester.pump();

    final collapsedIndicatorTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('dashboard-core-mode-balance-dots')),
        )
        .dy;
    final collapsedLowerTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('dashboard-core-mode-balance-card-2')),
        )
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
      final controller = DashboardCoreController(initialCoreRevision: 1);
      addTearDown(controller.dispose);
      await controller.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: _modeControllerFor(DashboardModeSpec.balance),
          categoryCollection: emptyTestCategoryCollection,
        ),
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

DashboardCoreModeController _modeControllerFor(DashboardModeSpec mode) {
  final controller = DashboardCoreModeController(initialMode: mode);
  addTearDown(controller.dispose);
  return controller;
}
