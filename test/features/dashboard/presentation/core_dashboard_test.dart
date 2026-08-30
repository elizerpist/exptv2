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
      await tester.pump();
      final sliderStages = FluviDiagnosticLogger.entries
          .map((entry) => entry.stage)
          .toList(growable: false);
      expect(
        sliderStages,
        containsAll(<String>[
          'MIND|SLIDER_MOUNT',
          'MIND|SLIDER_LAYOUT',
          'MIND|SLIDER_VISIBLE',
        ]),
        reason:
            'MR-01: a canonical ready range is not accepted until the real '
            'Mind host has mounted, laid out, and exposed the shared control.',
      );
    },
  );

  testWidgets(
    'MR-02: Mind renders an explicit retryable terminal range failure',
    (tester) async {
      final controller = DashboardCoreController(initialCoreRevision: 1);
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.income);
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: controller.currentQuery,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: const _FailMindFacetRepository(),
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
          mindQueryFacetLoader: loader,
        ),
      );

      await loader.start();
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mind-query-amount-range-error')),
        findsOneWidget,
        reason:
            'A completed canonical request failure must not continue to claim '
            'that loading is in progress.',
      );
      expect(
        find.byKey(const ValueKey('mind-query-amount-range-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-query-amount-range-retry')),
        findsOneWidget,
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

      final collapseGeometry = FluviDiagnosticLogger.entries.lastWhere(
        (entry) => entry.stage == 'COLLAPSE|GEOMETRY',
      );
      expect(collapseGeometry.scope, contains('mode=budget'));
      expect(collapseGeometry.scope, contains('progressBucket=10'));
      expect(
        collapseGeometry.scope,
        contains('header='),
        reason:
            'The intermediate collapse record must carry the moving Header '
            'bounds separately from the lower Chart/Rhythm candidate area.',
      );
      expect(collapseGeometry.scope, contains('chart='));
      expect(collapseGeometry.scope, contains('collapseHandle='));

      await tester.pump();
      final viewportProbe = FluviDiagnosticLogger.entries.lastWhere(
        (entry) =>
            entry.stage == 'COLLAPSE|LAYER' &&
            entry.scope?.contains('candidate=budgetDistributionViewport') ==
                true,
      );
      expect(viewportProbe.scope, contains('renderObject='));
      expect(viewportProbe.scope, contains('globalBounds='));
      expect(viewportProbe.scope, contains('paintBounds='));
      expect(viewportProbe.scope, contains('clip=ClipRRect'));
      expect(viewportProbe.scope, contains('surfaceOwner=splitCard2'));

      final logBoxProbe = FluviDiagnosticLogger.entries.lastWhere(
        (entry) =>
            entry.stage == 'COLLAPSE|LAYER' &&
            entry.scope?.contains('candidate=dashboardLogBoxViewport') == true,
      );
      expect(logBoxProbe.scope, contains('globalBounds='));
      expect(logBoxProbe.scope, contains('paintBounds='));
      expect(logBoxProbe.scope, contains('zOrder=modeContent<logBoxViewport'));

      final collapseHandleProbe = FluviDiagnosticLogger.entries.lastWhere(
        (entry) =>
            entry.stage == 'COLLAPSE|LAYER' &&
            entry.scope?.contains('candidate=collapseHandle') == true,
      );
      expect(collapseHandleProbe.scope, contains('globalBounds='));
      expect(
        collapseHandleProbe.scope,
        contains('zOrder=modeContent<logBoxViewport<collapseHandle'),
      );
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
      final avatarRail = find.byKey(
        const ValueKey('budget-target-avatar-rail'),
      );
      final rhythm = find.byKey(
        const ValueKey('partner-spending-rhythm-chart'),
      );
      final count = find.byKey(const ValueKey('dashboard-logbox-entry-count'));
      final handle = find.byKey(const ValueKey('dashboard-collapse-handle'));
      final transparentTrack = find.byKey(
        const ValueKey('spending-rhythm-track-2'),
      );
      final previousTrack = find.byKey(
        const ValueKey('spending-rhythm-track-1'),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final observations = <_G4CollapseObservation>[];
      final pager = find.byKey(const ValueKey('budget-distribution-pager'));
      final pageViewBefore = tester.widget<PageView>(pager);

      Future<void> assertNoSlabAcrossCollapse(
        String topology, {
        required bool chartFirst,
      }) async {
        observations.clear();
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
          final previousTrackBounds = tester.getRect(previousTrack);
          final countBounds = tester.getRect(count);
          final handleBounds = tester.getRect(handle);
          // The centered 42x4 collapse affordance legitimately crosses the
          // Rhythm lane at late collapse progress. Sample the lower-card
          // material beside that authored control instead of treating the
          // handle's own antialiased top edge or shadow as the reported slab.
          // A slab with the device-observed rectangular extent still reaches
          // this point, while an intended handle never does.
          final centerAwayFromHandle = Offset(
            rhythmBounds.left + rhythmBounds.width * .75,
            rhythmBounds.center.dy,
          );
          final handleAdjacentRhythm = Offset(
            (handleBounds.center.dx + 70)
                .clamp(rhythmBounds.left + 1, rhythmBounds.right - 1)
                .toDouble(),
            trackBounds.center.dy,
          );
          final samplePoints = <String, Offset>{
            'top': Offset(centerAwayFromHandle.dx, rhythmBounds.top + 1),
            'middleAwayFromHandle': centerAwayFromHandle,
            'bottom': Offset(centerAwayFromHandle.dx, rhythmBounds.bottom - 1),
            'leftInset': Offset(rhythmBounds.left + 1, rhythmBounds.center.dy),
            'rightInset': Offset(
              rhythmBounds.right - 1,
              rhythmBounds.center.dy,
            ),
            'barInterior': trackBounds.center,
            'betweenBars': Offset(
              (previousTrackBounds.right + trackBounds.left) / 2,
              trackBounds.center.dy,
            ),
            // This is immediately beside the real handle, far enough beyond
            // its 42dp bar and bounded blur that it cannot confuse the
            // handle's intentional material with an exposed footer slab.
            'handleAdjacentRhythm': handleAdjacentRhythm,
          };
          // Rendering a RepaintBoundary is comparatively expensive. One
          // image per collapse geometry preserves eight spatial samples while
          // keeping this forensic regression off the interaction hot path.
          final samples = await _g4PixelsAt(tester, boundary, samplePoints);
          observations.add(
            _G4CollapseObservation(
              progress: progress,
              cardBounds: cardBounds,
              rhythmBounds: rhythmBounds,
              countBounds: countBounds,
              handleBounds: handleBounds,
              samples: samples,
            ),
          );

          if (progress == 0) {
            final avatarRailBounds = tester.getRect(avatarRail);
            expect(
              chartFirst
                  ? cardBounds.top < avatarRailBounds.top
                  : avatarRailBounds.top < cardBounds.top,
              isTrue,
              reason:
                  '$topology must use the selected authored section order; '
                  'otherwise a cached/off-screen tuner control could make '
                  'this full-composition test a false green.',
            );
          }

          expect(
            cardBounds.overlaps(rhythmBounds),
            isTrue,
            reason:
                '$topology Rhythm must remain inside its moving authored '
                'Budget surface at progress=$progress.',
          );
          for (final entry in samples.entries) {
            expect(
              _isObservedPhysicalSlabColor(entry.value),
              isFalse,
              reason:
                  '$topology must not expose the device-observed opaque '
                  'neutral slab (#D3D4D5/#E1E2E4 families) at '
                  'progress=$progress, '
                  'sample=${entry.key}. samples=$observations',
            );
          }
        }
      }

      Future<void> selectTunerOption(Finder option) async {
        await tester.tap(
          find.byKey(const ValueKey('dashboard-header-visual-tuner-button')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final scrollable = find.descendant(
          of: find.byKey(
            const ValueKey<String>('dashboard-header-visual-tuner-list'),
          ),
          matching: find.byType(Scrollable),
        );
        // Start each production interaction from the top of the panel. This
        // makes every option selection an actual reachable-tuner path rather
        // than a test-only controller mutation.
        await tester.drag(scrollable, const Offset(0, 1200));
        await tester.pump();
        // ListView keeps a cache extent, so a finder becoming non-empty does
        // not yet mean its center can receive a physical pointer. Advance the
        // real scroll gesture until the complete RadioListTile is on screen;
        // this deliberately does not rely on scrollUntilVisible's
        // finder-exists shortcut.
        var optionIsTouchTarget = false;
        for (var attempt = 0; attempt < 20; attempt++) {
          if (option.evaluate().isNotEmpty) {
            final optionBounds = tester.getRect(option);
            if (optionBounds.top >= 0 &&
                optionBounds.bottom <= dashboardTestSurfaceSize.height) {
              optionIsTouchTarget = true;
              break;
            }
          }
          await tester.drag(scrollable, const Offset(0, -240));
          await tester.pump();
        }
        expect(
          optionIsTouchTarget,
          isTrue,
          reason: 'The tuner option must become physically touchable.',
        );
        final optionBounds = tester.getRect(option);
        expect(
          optionBounds.top,
          greaterThanOrEqualTo(0),
          reason: 'The tuner option must be physically touchable.',
        );
        expect(
          optionBounds.bottom,
          lessThanOrEqualTo(dashboardTestSurfaceSize.height),
          reason: 'The tuner option must be physically touchable.',
        );
        await tester.tap(option);
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('dashboard-header-visual-tuner-button')),
        );
        await tester.pump(const Duration(milliseconds: 300));
      }

      void expectTopology({required bool unified, required String topology}) {
        expect(
          find.byKey(const ValueKey('budget-unified-content-card-surface')),
          unified ? findsOneWidget : findsNothing,
          reason:
              '$topology must have exactly the physical surface selected by '
              'the production Budget layout setting.',
        );
        expect(
          find.byKey(const ValueKey('budget-distribution-card-shell')),
          unified ? findsNothing : findsOneWidget,
          reason:
              '$topology must not retain the other layout\'s physical Card2 '
              'surface.',
        );
        expect(
          tester.widget<PageView>(pager).controller,
          same(pageViewBefore.controller),
          reason:
              '$topology must not recreate the PageView controller or lose '
              'the selected Partner page.',
        );
        expect(
          find.byKey(const ValueKey('partner-spending-rhythm-chart')),
          findsOneWidget,
          reason: '$topology must retain the real Partner Rhythm footer.',
        );
      }

      // Exercise all production-supported surface/order combinations. The
      // lower Rhythm failure was observed only in the full moving composition,
      // so each topology receives the same dense collapse samples.
      expectTopology(unified: false, topology: 'Split avatars→chart');
      await assertNoSlabAcrossCollapse(
        'Split avatars→chart',
        chartFirst: false,
      );

      await selectTunerOption(
        find.byKey(
          const ValueKey<String>(
            'dashboard-budget-section-order-chartThenAvatars',
          ),
        ),
      );
      expectTopology(unified: false, topology: 'Split chart→avatars');
      await assertNoSlabAcrossCollapse('Split chart→avatars', chartFirst: true);

      await selectTunerOption(
        find.byKey(
          const ValueKey<String>('dashboard-budget-content-unifiedCard'),
        ),
      );
      expectTopology(unified: true, topology: 'Unified chart→avatars');
      await assertNoSlabAcrossCollapse(
        'Unified chart→avatars',
        chartFirst: true,
      );

      await selectTunerOption(
        find.byKey(
          const ValueKey<String>(
            'dashboard-budget-section-order-avatarsThenChart',
          ),
        ),
      );
      expectTopology(unified: true, topology: 'Unified avatars→chart');
      await assertNoSlabAcrossCollapse(
        'Unified avatars→chart',
        chartFirst: false,
      );

      for (final candidate in <String>[
        'budgetChartCascadeCard',
        'budgetDistributionViewport',
        'budgetDistributionPageContent',
        'partnerRhythmFooterLane',
        'spendingRhythmChart',
      ]) {
        final event = FluviDiagnosticLogger.entries.lastWhere(
          (entry) =>
              entry.stage == 'COLLAPSE|LAYER' &&
              entry.scope?.contains('candidate=$candidate') == true,
        );
        expect(event.scope, contains('globalBounds='));
        expect(event.scope, contains('paintBounds='));
        expect(event.scope, contains('clip='));
        expect(event.scope, contains('zOrder='));
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

final class _FailMindFacetRepository implements QueryMenuRepository {
  const _FailMindFacetRepository();

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope scope) =>
      Future<QueryMenuData>.error(StateError('native facets unavailable'));

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

Future<Map<String, Color>> _g4PixelsAt(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  Map<String, Offset> points,
) async {
  final colors = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = Uint8List.view(bytes!.buffer);
    final result = <String, Color>{
      for (final entry in points.entries)
        entry.key: _g4RgbaAt(rgba, image.width, image.height, entry.value),
    };
    image.dispose();
    return result;
  });
  return colors!;
}

Color _g4RgbaAt(Uint8List rgba, int width, int height, Offset point) {
  final x = point.dx.floor().clamp(0, width - 1);
  final y = point.dy.floor().clamp(0, height - 1);
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    rgba[offset + 3],
    rgba[offset],
    rgba[offset + 1],
    rgba[offset + 2],
  );
}

/// Device screenshots captured both the opaque #D3D4D5 rectangle itself and
/// its lighter #E1E2E4-family edge/composite. Neither is an authored Rhythm
/// material. Keep both observed physical signatures in the production-parent
/// probe; it must not turn green merely because the same slab rasterises one
/// shade darker at a different collapse fraction or device scale.
bool _isObservedPhysicalSlabColor(Color color) =>
    _isNearRgb(color, red: 211, green: 212, blue: 213) ||
    _isNearRgb(color, red: 225, green: 226, blue: 228);

bool _isNearRgb(
  Color color, {
  required int red,
  required int green,
  required int blue,
}) =>
    ((color.r * 255).round() - red).abs() <= 8 &&
    ((color.g * 255).round() - green).abs() <= 8 &&
    ((color.b * 255).round() - blue).abs() <= 8;

final class _G4CollapseObservation {
  const _G4CollapseObservation({
    required this.progress,
    required this.cardBounds,
    required this.rhythmBounds,
    required this.countBounds,
    required this.handleBounds,
    required this.samples,
  });

  final double progress;
  final Rect cardBounds;
  final Rect rhythmBounds;
  final Rect countBounds;
  final Rect handleBounds;
  final Map<String, Color> samples;

  @override
  String toString() =>
      'p=${progress.toStringAsFixed(1)} card=$cardBounds rhythm=$rhythmBounds '
      'count=$countBounds handle=$handleBounds samples=$samples';
}
