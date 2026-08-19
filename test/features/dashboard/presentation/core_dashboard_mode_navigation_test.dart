import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';

import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/test_pump.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'header mode navigation preserves shared dashboard and LogBox owners without runtime reads',
    (tester) async {
      final repository = _CountingDashboardRepository();
      final dashboard = DashboardCoreController(
        dataRepository: repository,
        initialCoreRevision: 1,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(dashboard.dispose);
      addTearDown(modes.dispose);
      await dashboard.bootstrap();
      final readsBeforeNavigation = repository.totalReads;

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: dashboard,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      final logBoxState = tester.state(find.byType(DashboardLogBoxViewport));
      final committedViewport = dashboard.committedLogViewport;
      final currentQuery = dashboard.currentQuery;
      final queryComposer = dashboard.queryComposer;
      final coreWidget = tester.widget<CoreDashboard>(
        find.byType(CoreDashboard),
      );

      for (var index = 0; index < 30; index += 1) {
        await _dragHeader(tester, const Offset(-260, 0));
        expect(find.byType(DashboardLogBoxViewport), findsOneWidget);
        expect(
          identical(
            tester.state(find.byType(DashboardLogBoxViewport)),
            logBoxState,
          ),
          isTrue,
        );
      }

      expect(modes.committedMode, DashboardModeSpec.balance);
      expect(repository.totalReads, readsBeforeNavigation);
      expect(
        identical(dashboard.committedLogViewport, committedViewport),
        isTrue,
      );
      expect(identical(dashboard.currentQuery, currentQuery), isTrue);
      expect(identical(dashboard.queryComposer, queryComposer), isTrue);
      expect(
        identical(
          tester.widget<CoreDashboard>(find.byType(CoreDashboard)).controller,
          coreWidget.controller,
        ),
        isTrue,
      );
      expect(
        identical(
          tester
              .widget<CoreDashboard>(find.byType(CoreDashboard))
              .modeController,
          modes,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'unaccepted horizontal input is inert and mode replacement has no trailing frames',
    (tester) async {
      final dashboard = DashboardCoreController(initialCoreRevision: 1);
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(dashboard.dispose);
      addTearDown(modes.dispose);
      await dashboard.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: dashboard,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      final rootBuildsBefore = dashboard.performanceCounters.value(
        DashboardPerformanceMetric.dashboardRootBuild,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(
            const ValueKey('dashboard-core-mode-header-gesture-region'),
          ),
        ),
      );
      await gesture.moveBy(const Offset(-8, 0));
      await tester.pump();

      expect(
        dashboard.performanceCounters.value(
          DashboardPerformanceMetric.dashboardRootBuild,
        ),
        rootBuildsBefore,
      );
      expect(modes.committedMode, DashboardModeSpec.balance);
      expect(find.byType(DashboardLogBoxViewport), findsOneWidget);

      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      expect(modes.committedMode, DashboardModeSpec.budget);
      final buildsAfterAtomicSwitch = dashboard.performanceCounters.value(
        DashboardPerformanceMetric.dashboardRootBuild,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        dashboard.performanceCounters.value(
          DashboardPerformanceMetric.dashboardRootBuild,
        ),
        buildsAfterAtomicSwitch,
      );
      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'vertical header expansion remains independent from runtime core-mode navigation',
    (tester) async {
      final dashboard = DashboardCoreController(initialCoreRevision: 1);
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(dashboard.dispose);
      addTearDown(modes.dispose);
      await dashboard.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: dashboard,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      await _dragHeader(tester, const Offset(0, -180));
      expect(dashboard.expansion.progress, dashboard.metrics.collapseTravel);
      expect(modes.committedMode, DashboardModeSpec.balance);

      await _dragHeader(tester, const Offset(-260, 0));
      expect(modes.committedMode, DashboardModeSpec.budget);
      expect(dashboard.expansion.progress, dashboard.metrics.collapseTravel);
    },
  );

  testWidgets(
    'Budget card1 rail consumes the root category inventory without runtime reads or a core-mode gesture',
    (tester) async {
      final repository = _CountingDashboardRepository();
      final dashboard = DashboardCoreController(
        dataRepository: repository,
        initialCoreRevision: 1,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.budget,
      );
      addTearDown(dashboard.dispose);
      addTearDown(modes.dispose);
      final categories = ValueNotifier<List<FluviCategory>>(
        _categoryInventory(),
      );
      addTearDown(categories.dispose);
      await dashboard.bootstrap();
      final readsBeforeRail = repository.totalReads;

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: dashboard,
          modeController: modes,
          categoryCollection: categories,
        ),
      );
      await tester.pump();

      final rail = find.byKey(const ValueKey('budget-target-avatar-carousel'));
      expect(rail, findsOneWidget);
      final railBounds = tester.getRect(
        find.byKey(const ValueKey('budget-target-avatar-rail')),
      );
      final cardBounds = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-budget-card-1')),
      );
      expect(railBounds.center, cardBounds.center);
      expect(railBounds.height, 112);
      expect(cardBounds.height, dashboard.metrics.subheaderOneHeight);
      expect(find.byType(DashboardLogBoxViewport), findsOneWidget);
      final dashboardBuildsBeforeRailFling = dashboard.performanceCounters
          .value(DashboardPerformanceMetric.dashboardRootBuild);

      await tester.fling(
        find.descendant(of: rail, matching: find.byType(ListView)),
        const Offset(-420, 0),
        2200,
      );
      await tester.pumpAndSettle();

      expect(modes.committedMode, DashboardModeSpec.budget);
      expect(repository.totalReads, readsBeforeRail);
      expect(
        dashboard.performanceCounters.value(
          DashboardPerformanceMetric.dashboardRootBuild,
        ),
        dashboardBuildsBeforeRailFling,
      );
      expect(
        dashboard.currentQuery.scopeFor(LedgerDirection.income).categoryIds,
        isEmpty,
      );
      expect(find.byType(DashboardLogBoxViewport), findsOneWidget);
    },
  );
}

Future<void> _dragHeader(WidgetTester tester, Offset offset) async {
  await tester.drag(
    find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
    offset,
  );
  await tester.pump();
}

List<FluviCategory> _categoryInventory() => const <FluviCategory>[
  FluviCategory(
    id: 'groceries',
    name: 'Groceries',
    colorId: 'color_08',
    iconId: 'icon_08',
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  ),
  FluviCategory(
    id: 'travel',
    name: 'Travel',
    colorId: 'color_13',
    iconId: 'icon_11',
    isSystemUncategorized: false,
    createdAtUtcMs: 2,
    updatedAtUtcMs: 2,
  ),
];

final class _CountingDashboardRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _delegate =
      const EmptyDashboardDataRuntimeRepository();
  var prepareIndexCalls = 0;
  var pageReadCalls = 0;

  int get totalReads => prepareIndexCalls + pageReadCalls;

  @override
  Stream<int> watchCoreRevision() => _delegate.watchCoreRevision();

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    prepareIndexCalls += 1;
    return _delegate.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    pageReadCalls += 1;
    return _delegate.readCommittedPage(request);
  }

  @override
  Map<String, Object?> performanceReport() => _delegate.performanceReport();
}
