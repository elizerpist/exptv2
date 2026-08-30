import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/data/empty_category_repository.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_applied_query_facet_loader.dart';
import 'package:fluvi/features/dashboard/query/data/query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../support/test_pump.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../runtime/dashboard_runtime_test_fixtures.dart';

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
      if (spec == DashboardModeSpec.mind) {
        final scope = controller.currentQuery.scope;
        controller.currentQuery.replaceDirection(
          scope.direction,
          scope,
          facetPresentation: _readyMindQueryMenuData,
        );
      }

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
        final range = find.byKey(const ValueKey('mind-query-amount-range'));
        expect(range, findsOneWidget);
        expect(
          tester.widget<QueryAmountRangeControl>(range).values,
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 860000,
            lowerScaled100: 100000,
            upperScaled100: 860000,
          ),
          reason:
              'RG-G5: the production Mind host binds the exact canonical '
              'Query-menu domain rather than a presentation-null 1000/1000 '
              'fallback.',
        );
        expect(
          find.descendant(of: range, matching: find.byType(RangeSlider)),
          findsOneWidget,
          reason: 'G3: Mind renders the actual two-ended Query control.',
        );
        expect(
          tester.getRect(range).bottom,
          lessThanOrEqualTo(body.bottom),
          reason:
              'The shared Query amount range stays inside the first Mind card '
              'rather than adding an independent dashboard layer.',
        );
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
    'RG-G5: Mind represents a genuinely unavailable canonical domain explicitly',
    (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: _modeControllerFor(DashboardModeSpec.mind),
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-query-amount-range-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-query-amount-range')),
        findsNothing,
        reason:
            'A missing canonical domain is not a disabled 1,000/1,000 slider.',
      );
    },
  );

  testWidgets(
    'Mind mounts the shared range when the applied Query facet loader becomes ready',
    (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.income);
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: controller.currentQuery,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: const _MindFacetRepository(),
      );
      addTearDown(controller.dispose);
      addTearDown(direction.dispose);
      addTearDown(loader.dispose);
      await controller.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: _modeControllerFor(DashboardModeSpec.mind),
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-query-amount-range-unavailable')),
        findsOneWidget,
      );

      await loader.start();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mind-query-amount-range')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<QueryAmountRangeControl>(
              find.byKey(const ValueKey('mind-query-amount-range')),
            )
            .values
            .maximumScaled100,
        860000,
      );
    },
  );

  testWidgets(
    'Mind to Budget replays one new visible Budget epoch without an Avatar selection',
    (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(controller.dispose);
      addTearDown(modes.dispose);
      await controller.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: controller,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      FluviDiagnosticLogger.clear();

      expect(modes.setProgrammaticMode(DashboardModeSpec.budget), isTrue);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-budget-card-1')),
        findsOneWidget,
      );

      modes.setProgrammaticMode(DashboardModeSpec.mind);
      await tester.pump();
      modes.setProgrammaticMode(DashboardModeSpec.budget);
      await tester.pump();

      final replays = FluviDiagnosticLogger.entries
          .where(
            (event) => event.stage == 'BUDGET_VISIBLE_PUBLICATION_REPLAYED',
          )
          .toList(growable: false);
      expect(replays, hasLength(2));
      expect(replays.first.scope, contains('modeEpoch=1'));
      expect(replays.last.scope, contains('modeEpoch=3'));
    },
  );

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
          modeController: _modeControllerFor(DashboardModeSpec.budget),
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('budget-distribution-pager')),
        findsOneWidget,
      );
      expect(find.byType(BudgetDistributionCardShell), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-distribution-card-shell')),
        findsOneWidget,
        reason:
            'G4: Card2 owns its physical shell independently of the parent '
            'Budget composition style.',
      );
      expect(
        find.descendant(
          of: find.byType(BudgetDistributionCardShell),
          matching: find.byType(FluviRoundedBox),
        ),
        findsOneWidget,
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

  testWidgets(
    'Budget starts in the accepted Split composition with its one Card2 shell',
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

      expect(
        find.byKey(const ValueKey('budget-distribution-card-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'HOME layer diagnostics records the full Dashboard paint-order boundary during collapse',
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

      FluviDiagnosticLogger.clear();
      controller.expansion.setProgress(90);
      await tester.pump();

      final event = FluviDiagnosticLogger.entries.lastWhere(
        (entry) => entry.stage == 'HOME|LAYER_STACK',
      );
      expect(event.scope, contains('mode=budget'));
      expect(
        event.scope,
        contains(
          'paintOrder=DashboardCoreModeHost<DashboardLogBoxViewport<DashboardCollapseHandle',
        ),
      );
      expect(event.scope, contains('collapseProgress=90.0'));
    },
  );

  testWidgets(
    'G4 forensic proxy drives the real Partner Rhythm through every Dashboard collapse frame',
    (tester) async {
      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'color_01',
              iconId: 'icon_01',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      final controller = DashboardCoreController(
        initialCoreRevision: 7,
        initialDate: DateTime(2026, 7, 14),
        initialDirection: LedgerDirection.expense,
        yearWindowRadius: 1,
      );
      final boundaryKey = GlobalKey();
      addTearDown(categories.dispose);
      addTearDown(controller.dispose);
      await controller.bootstrap();
      await controller.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 7,
          initialYear: 2026,
          yearWindowRadius: 1,
        ),
        budgetLimitSnapshot: _g4LimitSnapshot(),
        partnerDistributionSnapshot: _g4PartnerSnapshot(),
      );

      FluviDiagnosticLogger.clear();
      await pumpDashboardSurface(
        tester,
        RepaintBoundary(
          key: boundaryKey,
          child: CoreDashboard(
            controller: controller,
            modeController: _modeControllerFor(DashboardModeSpec.budget),
            categoryCollection: categories,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final rhythmStates = FluviDiagnosticLogger.entries
          .where((entry) => entry.stage == 'SPENDING_RHYTHM|STATE')
          .toList(growable: false);
      expect(
        rhythmStates,
        isNotEmpty,
        reason:
            'G4 needs the real snapshot-to-footer state boundary. Without '
            'this event a missing Rhythm body cannot be distinguished from a '
            'clipped or overpainted one.',
      );
      expect(
        rhythmStates.last.scope,
        contains('availability=available'),
        reason:
            'The full Dashboard fixture provides a compatible prepared '
            'snapshot, visible frame and selected target. If this is not '
            'available, the lower Rhythm surface cannot be used to find the '
            'grey pixel owner. state=${rhythmStates.last.scope}',
      );

      await tester.drag(
        find.byKey(const ValueKey('budget-distribution-pager')),
        const Offset(-360, 0),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final afterPagerRhythmState = FluviDiagnosticLogger.entries.lastWhere(
        (entry) => entry.stage == 'SPENDING_RHYTHM|STATE',
      );
      expect(
        afterPagerRhythmState.scope,
        contains('availability=available'),
        reason:
            'A page transition may not clear the Partner footer input. '
            'state=${afterPagerRhythmState.scope}',
      );
      expect(
        find.byKey(const ValueKey('budget-partner-distribution-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-partner-distribution-preparing')),
        findsNothing,
        reason:
            'The real Partner page must be drawable before its footer can be '
            'sampled for G4 provenance.',
      );
      expect(
        find.byKey(const ValueKey('partner-spending-rhythm-chart')),
        findsOneWidget,
        reason:
            'This is a production-parent composition gate: a synthetic '
            'Card2 without the Partner footer cannot prove the reported slab.',
      );

      final lowerCard = find.byKey(
        const ValueKey('dashboard-core-mode-budget-card-2'),
      );
      final rhythm = find.byKey(
        const ValueKey('partner-spending-rhythm-chart'),
      );
      final count = find.byKey(const ValueKey('dashboard-logbox-entry-count'));
      final handle = find.byKey(const ValueKey('dashboard-collapse-handle'));
      final transparentTrack = find.byKey(
        const ValueKey('spending-rhythm-track-2'),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final observations = <_G4CollapseObservation>[];

      for (
        var progress = 0.0;
        progress <= controller.metrics.collapseTravel;
        progress += 9
      ) {
        controller.expansion.setProgress(progress);
        await tester.pump();
        final cardBounds = tester.getRect(lowerCard);
        final rhythmBounds = tester.getRect(rhythm);
        final trackBounds = tester.getRect(transparentTrack);
        final countBounds = tester.getRect(count);
        final handleBounds = tester.getRect(handle);
        final sample = await _g4PixelAt(tester, boundary, trackBounds.center);
        observations.add(
          _G4CollapseObservation(
            progress: progress,
            cardBounds: cardBounds,
            rhythmBounds: rhythmBounds,
            countBounds: countBounds,
            handleBounds: handleBounds,
            sample: sample,
          ),
        );

        expect(
          cardBounds.overlaps(rhythmBounds),
          isTrue,
          reason:
              'The real Rhythm footer must remain inside the moving Card2 '
              'composition at progress=$progress.',
        );
        expect(
          _isObservedPhysicalSlabColor(sample),
          isFalse,
          reason:
              'The transparent Rhythm-track interior must not become the '
              'device-observed opaque neutral slab (#E1E2E4 family) at '
              'progress=$progress. samples=$observations',
        );
      }
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

  testWidgets(
    'RG-G3: a Summary pointer immediately takes over a live time-rail ballistic',
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

      await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
      await tester.pump();
      final timeRail = find.byKey(const ValueKey('dashboard-time-rail'));
      expect(timeRail, findsOneWidget);
      final summary = find.byKey(
        const ValueKey('dashboard-summary-shell-transform'),
      );
      Future<void> takeOverAfter(Duration delay) async {
        await tester.fling(timeRail, const Offset(-320, 0), 2400);
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          controller.motion.state.activity,
          isNot(DashboardMotionActivity.idle),
          reason: 'The test must begin with a genuine active temporal motion.',
        );
        await tester.pump(delay);
        final summaryGesture = await tester.startGesture(
          tester.getCenter(summary),
        );
        await tester.pump();
        expect(controller.motion.state.activity, DashboardMotionActivity.idle);
        expect(
          controller.motion.carouselController.hasActiveScrollActivity,
          isFalse,
          reason:
              'RG-G3: raw Summary input interrupts the old time ScrollPosition '
              'before the Summary pan recognizer chooses its own axis.',
        );
        await summaryGesture.up();
        await tester.pump();
      }

      for (final delay in <Duration>[
        Duration.zero,
        const Duration(milliseconds: 16),
        const Duration(milliseconds: 50),
        const Duration(milliseconds: 100),
      ]) {
        await takeOverAfter(delay);
      }

      await tester.fling(timeRail, const Offset(-320, 0), 2400);
      await tester.pumpAndSettle();
      FluviDiagnosticLogger.clear();
      final settledGesture = await tester.startGesture(
        tester.getCenter(summary),
      );
      await tester.pump();
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_DIRECT_POINTER_PREEMPTED',
        ),
        hasLength(1),
        reason:
            'A first Summary pointer is still accepted immediately after settle.',
      );
      await settledGesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'TM diagnostics records the semantic settle that ends a time-rail flight',
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

      await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
      await tester.pump();
      FluviDiagnosticLogger.clear();
      await tester.fling(
        find.byKey(const ValueKey('dashboard-time-rail')),
        const Offset(-320, 0),
        2400,
      );
      await tester.pumpAndSettle();

      final settles = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'TM|FLING_SETTLED')
          .toList(growable: false);
      expect(settles, hasLength(1));
      expect(settles.single.scope, contains('motionActivity=idle'));
      expect(settles.single.scope, contains('logicalIndex='));
      expect(settles.single.scope, contains('motionEpoch='));
    },
  );

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

const QueryMenuData _readyMindQueryMenuData = QueryMenuData(
  result: QueryMenuResultSummary(entryCount: 18, amountScaled100: 860000),
  amountDomain: QueryMenuAmountDomain(
    minimumAmountScaled100: 100000,
    maximumAmountScaled100: 860000,
  ),
  availableMonths: <QueryMenuAvailableMonth>[],
  categories: <QueryMenuCategoryFacet>[],
  partners: <QueryMenuPartnerFacet>[],
);

final class _MindFacetRepository implements QueryMenuRepository {
  const _MindFacetRepository();

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope scope) async =>
      _readyMindQueryMenuData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PreparedBudgetLimitSnapshot _g4LimitSnapshot() {
  const yearWindowStart = 2025;
  const yearWindowEndInclusive = 2027;
  const periodSliceCount = 40;
  const targetCount = 2;
  const july2026Slice = 22;
  List<PreparedBudgetLimitCell> cells() {
    final values = List<PreparedBudgetLimitCell>.filled(
      periodSliceCount * targetCount,
      const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
    );
    values[july2026Slice * targetCount] = const PreparedBudgetLimitCell(
      actualScaled100: 750000,
      limitScaled100: 1000000,
      limitSource: PreparedBudgetLimitSource.base,
    );
    values[july2026Slice * targetCount + 1] = const PreparedBudgetLimitCell(
      actualScaled100: 750000,
      limitScaled100: 1000000,
      limitSource: PreparedBudgetLimitSource.base,
    );
    return values;
  }

  final julyFirst = _g4EpochDay(2026, 7, 1);
  final julyThird = _g4EpochDay(2026, 7, 3);
  PreparedSpendingRhythmDirectionBank rhythm() =>
      PreparedSpendingRhythmDirectionBank(
        targetCount: targetCount,
        targetOffsets: const <int>[0, 2, 4],
        epochDays: <int>[julyFirst, julyThird, julyFirst, julyThird],
        dailyActualScaled100: const <int>[500000, 250000, 500000, 250000],
        dayPartActualScaled100: const <int>[
          500000,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          250000,
          0,
          0,
          0,
          0,
          500000,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          250000,
          0,
          0,
          0,
          0,
        ],
      );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells(),
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: yearWindowStart,
    yearWindowEndInclusive: yearWindowEndInclusive,
    incomeBank: bank(),
    expenseBank: bank(),
    spendingRhythmSnapshot: PreparedSpendingRhythmSnapshot(
      coreRevision: 7,
      incomeBank: rhythm(),
      expenseBank: rhythm(),
    ),
  );
}

PreparedBudgetPartnerDistributionSnapshot _g4PartnerSnapshot() {
  const periodSliceCount = 40;
  const july2026Slice = 22;
  PreparedBudgetPartnerDistributionDirectionBank bank() {
    final cells = List<PreparedBudgetPartnerDistributionCell>.filled(
      periodSliceCount,
      const PreparedBudgetPartnerDistributionCell(
        actualScaled100: 0,
        dominantCategoryId: '',
      ),
    );
    cells[july2026Slice] = const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 750000,
      dominantCategoryId: 'food',
    );
    return PreparedBudgetPartnerDistributionDirectionBank(
      orderedPartnerIds: const <String>['fixture-partner'],
      orderedPartnerTitles: const <String>['Fixture partner'],
      cells: cells,
      orderedCategoryIds: const <String>['food'],
      categoryContributionOffsets: List<int>.filled(periodSliceCount + 1, 0),
    );
  }

  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2025,
    yearWindowEndInclusive: 2027,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

int _g4EpochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;

Future<Color> _g4PixelAt(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  Offset point,
) async {
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final x = point.dx.floor().clamp(0, image.width - 1);
    final y = point.dy.floor().clamp(0, image.height - 1);
    final rgba = Uint8List.view(bytes!.buffer);
    final offset = (y * image.width + x) * 4;
    final result = Color.fromARGB(
      rgba[offset + 3],
      rgba[offset],
      rgba[offset + 1],
      rgba[offset + 2],
    );
    image.dispose();
    return result;
  });
  return color!;
}

bool _isObservedPhysicalSlabColor(Color color) =>
    ((color.r * 255).round() - 225).abs() <= 8 &&
    ((color.g * 255).round() - 226).abs() <= 8 &&
    ((color.b * 255).round() - 228).abs() <= 8;

final class _G4CollapseObservation {
  const _G4CollapseObservation({
    required this.progress,
    required this.cardBounds,
    required this.rhythmBounds,
    required this.countBounds,
    required this.handleBounds,
    required this.sample,
  });

  final double progress;
  final Rect cardBounds;
  final Rect rhythmBounds;
  final Rect countBounds;
  final Rect handleBounds;
  final Color sample;

  @override
  String toString() =>
      'p=${progress.toStringAsFixed(1)} card=$cardBounds rhythm=$rhythmBounds '
      'count=$countBounds handle=$handleBounds sample=$sample';
}
