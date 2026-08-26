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
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

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
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('dashboard-action-row')))
            .dy,
        241,
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('dashboard-summary-shell-transform')),
            )
            .dy,
        304,
      );
      if (spec == DashboardModeSpec.mind) {
        final body = tester.getRect(
          find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
        );
        expect(body.top, 374);
        expect(body.bottom, 674);
      } else {
        expect(
          tester
              .getTopLeft(
                find.byKey(
                  ValueKey('dashboard-core-mode-${spec.mode.name}-card-1'),
                ),
              )
              .dy,
          374,
        );
        expect(
          tester
              .getTopLeft(
                find.byKey(
                  ValueKey('dashboard-core-mode-${spec.mode.name}-card-2'),
                ),
              )
              .dy,
          457,
        );
      }
    });
  }

  testWidgets(
    'keeps the SummaryPill amount while rendering Ledger count and SearchPill',
    (tester) async {
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

      expect(
        find.byKey(const ValueKey('dashboard-summary-shell-transform')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-logbox-result-amount')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dashboard-logbox-entry-count')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-logbox-search-pill')),
        findsOneWidget,
      );
      expect(find.text('Keresés a tranzakciókban'), findsOneWidget);
      expect(find.text('Keresés tranzakciók között…'), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsNothing);
      final summaryAmount =
          controller.visibleFrames.value!.amount.formattedAmount;
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('dashboard-summary-shell-transform')),
          matching: find.text(summaryAmount),
        ),
        findsOneWidget,
        reason: 'SummaryPill remains the only displayed transaction amount.',
      );

      final expandedCount = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-entry-count')),
      );
      final expandedSearch = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-search-pill')),
      );
      final expandedScroll = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
      );
      expect(expandedCount.top, lessThan(expandedSearch.top));
      expect(expandedSearch.bottom, lessThanOrEqualTo(expandedScroll.top));

      controller.expansion.setProgress(controller.metrics.collapseTravel);
      await tester.pump();

      final collapsedCount = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-entry-count')),
      );
      final collapsedSearch = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-search-pill')),
      );
      expect(collapsedCount.top, lessThan(expandedCount.top));
      expect(
        collapsedSearch.top - collapsedCount.top,
        closeTo(expandedSearch.top - expandedCount.top, .01),
      );
    },
  );

  testWidgets(
    'experimental SummaryPill variants transfer the physical rail footprint to Budget Card2',
    (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: _modeControllerFor(DashboardModeSpec.budget),
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      final lowerCard = find.byKey(
        const ValueKey('dashboard-core-mode-budget-card-2'),
      );
      final handle = find.byKey(const ValueKey('dashboard-collapse-handle'));
      final legacyHeight = tester.getRect(lowerCard).height;
      final legacyHandleTop = tester.getRect(handle).top;
      expect(legacyHeight, 217);
      expect(legacyHandleTop, 695);

      await tester.tap(
        find.byKey(const ValueKey('dashboard-header-visual-tuner-button')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey('dashboard-header-visual-tuner-input')),
            )
            .ignoring,
        isFalse,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('summary-pill-variant-segmented')),
      );
      await tester.pump();
      expect(
        find.byType(TimeRefinementRail),
        findsNothing,
        reason: 'Segmented keeps canonical DAY state without a physical rail.',
      );
      expect(tester.getRect(lowerCard).height, 275);
      expect(tester.getRect(handle).top, 753);
    },
  );

  for (final spec in DashboardModeSpec.values) {
    testWidgets(
      'Segmented keeps ${spec.mode.name} content above the Ledger boundary without a physical rail',
      (tester) async {
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

        final content = find.byKey(
          ValueKey<String>(switch (spec.mode) {
            DashboardMode.balance => 'dashboard-core-mode-balance-card-2',
            DashboardMode.budget => 'dashboard-core-mode-budget-card-2',
            DashboardMode.mind => 'dashboard-core-mode-mind-body',
          }),
        );
        final legacyHeight = tester.getRect(content).height;
        await tester.tap(
          find.byKey(const ValueKey('dashboard-header-visual-tuner-button')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(
          find.byKey(const ValueKey('summary-pill-variant-segmented')),
        );
        await tester.pump();

        final handle = tester.getRect(
          find.byKey(const ValueKey('dashboard-collapse-handle')),
        );
        final search = tester.getRect(
          find.byKey(const ValueKey('dashboard-logbox-search-pill')),
        );
        expect(find.byType(TimeRefinementRail), findsNothing);
        expect(tester.getRect(content).height, legacyHeight + 58);
        expect(search.top, greaterThanOrEqualTo(handle.bottom));
      },
    );
  }

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

  testWidgets(
    'expanded header gestures do not cover action or Summary interactions',
    (tester) async {
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

      final headerGesture = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      );
      final action = tester.getRect(
        find.byKey(const ValueKey('dashboard-action-row')),
      );
      final summary = tester.getRect(
        find.byKey(const ValueKey('dashboard-summary-shell-transform')),
      );

      expect(headerGesture.bottom, lessThan(action.top));
      expect(action.bottom, lessThan(summary.top));
      await tester.tap(find.text('Kiadás'));
      await tester.pump();
      expect(controller.transactionDirection.direction.name, 'expense');
      await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
      await tester.pump();
      expect(controller.navigation.isRailOpen, isTrue);
    },
  );

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

    final logBoxScrollable = find.descendant(
      of: find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
      matching: find.byType(Scrollable),
    );
    final initialLogBoxScrollable = tester.state<ScrollableState>(
      logBoxScrollable,
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
    expect(
      tester.state<ScrollableState>(logBoxScrollable),
      same(initialLogBoxScrollable),
      reason:
          'A Ledger chrome clipped below the physical bottom must retain the '
          'one vertical Scrollable and ScrollPosition identity.',
    );

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
      expect(
        find.byKey(const ValueKey('dashboard-logbox-search-pill')),
        findsOneWidget,
      );
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
