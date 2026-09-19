import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_logbox_drilldown_coordinator.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_live_interaction_coordinator.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_segmented_target_acceptance.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_logbox_presentation_binding.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_pump.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  test(
    'focus publication narrows a derived index and clearing restores the retained base without a repository read',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final baseIndex = core.preparedIndex!;
      final baseQuery = core.currentQuery.scopeFor(LedgerDirection.income);

      final focused = await core.requestCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
      );

      expect(focused, isTrue);
      expect(repository.prepareCalls, 1, reason: 'the tap must not read Room');
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.preparedIndex, isNot(same(baseIndex)));
      expect(
        core.preparedIndex!
            .frameFor(core.navigation.state.parentQueryScope)
            .entryCount,
        1,
      );

      final restored = await core.clearAllEphemeralFocus();

      expect(restored, isTrue);
      expect(repository.prepareCalls, 1);
      expect(core.focus.state, isNull);
      expect(core.preparedIndex, same(baseIndex));
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
    },
  );

  test(
    'RED: a prepared membership hit reports a no-worker no-base-scan fast path',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );

      final ready = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'FOCUS_DERIVED_SCOPE_READY',
      );
      expect(ready.scope, contains('preparedMembershipHit=true'));
      expect(ready.scope, contains('workerDispatched=false'));
      expect(ready.scope, contains('fullBaseRowsScanned=0'));
      expect(ready.scope, contains('copiedPreparedRows=0'));
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RG-G2: a new base revision cannot request a focused catalog from the retired ephemeral index',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
      );
      FluviDiagnosticLogger.clear();

      final published = await core.installPreparedIndex(
        buildRuntimeTestIndex(revision: 2, generation: 2),
        publicationState: core.navigation.state,
      );

      expect(
        published,
        isTrue,
        reason: FluviDiagnosticLogger.entries
            .where(
              (event) => event.message == 'INDEX_SCENE_WINDOW_PREPARE_FAILED',
            )
            .map((event) => event.error)
            .join('\n'),
      );
      expect(core.focus.state, isNull);
      expect(core.navigation.state.parentQueryScope.categoryIds, isEmpty);
      expect(core.visibleFrames.value!.coreRevision, 2);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.message == 'INDEX_SCENE_WINDOW_PREPARE_FAILED',
        ),
        isEmpty,
        reason:
            'A revision activation may retire the ephemeral focus, but the '
            'new base scene bank must never ask its index for that retired '
            'category catalog.',
      );
    },
  );

  test(
    'partner focus composes with category focus and clears each dimension without rebuilding its base',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final baseIndex = core.preparedIndex!;
      final baseQuery = core.currentQuery.scopeFor(LedgerDirection.income);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      expect(
        await core.requestPartnerFocus(
          const DashboardFocusFacet(
            id: 'partner-utility',
            displayName: 'Utility partner',
          ),
        ),
        isTrue,
      );
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.focus.state?.partner?.id, 'partner-utility');
      expect(repository.prepareCalls, 1);

      expect(await core.clearPartnerFocus(), isTrue);
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.focus.state?.partner, isNull);
      expect(repository.prepareCalls, 1);

      expect(await core.clearCategoryFocus(), isTrue);
      expect(core.focus.state, isNull);
      expect(core.preparedIndex, same(baseIndex));
      expect(core.currentQuery.scopeFor(LedgerDirection.income), baseQuery);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'Budget category replacement preserves the orthogonal Partner facet',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      await core.requestCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
      );
      await core.requestPartnerFocus(
        const DashboardFocusFacet(
          id: 'partner-utility',
          displayName: 'Utility partner',
        ),
      );

      await core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
      );

      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.focus.state?.partner?.id, 'partner-utility');
      expect(
        repository.prepareCalls,
        1,
        reason: 'Budget drill-down must reuse the prepared focus membership.',
      );
    },
  );

  test('an already-active focus is a semantic publication no-op', () async {
    final repository = _FocusSeedRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
      initialDate: DateTime.utc(2026, 7, 1),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.income,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    const facet = DashboardFocusFacet(
      id: 'utilities',
      displayName: 'Utilities',
    );

    expect(await core.requestCategoryFocus(facet), isTrue);
    final focusedIndex = core.preparedIndex;
    final presentationEpoch = core.visibleFrames.value!.presentationEpoch;
    FluviDiagnosticLogger.clear();

    expect(await core.requestCategoryFocus(facet), isTrue);

    expect(core.preparedIndex, same(focusedIndex));
    expect(core.visibleFrames.value!.presentationEpoch, presentationEpoch);
    expect(repository.prepareCalls, 1);
    expect(
      FluviDiagnosticLogger.entries.any(
        (event) => event.stage == 'FOCUS_REQUEST_ALREADY_ACTIVE',
      ),
      isTrue,
    );
    expect(
      FluviDiagnosticLogger.entries.any(
        (event) => event.stage == 'FOCUS_DERIVED_SCOPE_READY',
      ),
      isFalse,
    );
  });

  test(
    'live SearchPill text composes through the prepared facet projection',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final baseAmount = core.visibleFrames.amountLane.value!.amount.totalMinor;

      expect(await core.updateLiveSearch('utility'), isTrue);
      expect(core.focus.state?.normalizedSearch, 'utility');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 500);

      expect(await core.updateLiveSearch('food'), isTrue);
      expect(core.focus.state?.normalizedSearch, 'food');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 700);

      expect(await core.updateLiveSearch('   '), isTrue);
      expect(core.focus.state, isNull);
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        baseAmount,
      );
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'rapid live Search generations reject out-of-order rich scene completions',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final gates = <Completer<void>>[];
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {
          final gate = Completer<void>();
          gates.add(gate);
          await gate.future;
        },
        activate: (_) {},
      );

      for (final query in <String>['f', 'fo', 'foo', 'food']) {
        expect(await core.updateLiveSearch(query), isTrue);
      }
      expect(gates, hasLength(4));
      expect(core.focus.state?.normalizedSearch, 'food');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 700);

      for (final gate in gates.reversed) {
        gate.complete();
      }
      await Future<void>.delayed(Duration.zero);

      expect(core.focus.state?.normalizedSearch, 'food');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 700);
      expect(core.liveInteractions.frame?.normalizedSearch, 'food');
    },
  );

  test(
    'live Search pages beyond the prepared root stay in RAM and never fall through to native paging',
    () async {
      final rows = List<DashboardLedgerEntry>.generate(
        5,
        (index) => DashboardLedgerEntry(
          id: 'needle-$index',
          partnerId: 'partner-$index',
          categoryId: 'utilities',
          direction: 'income',
          amountMinor: 100 + index,
          bookedLocalEpochDay: 20635 + index,
          bookedLocalTimeMinutes: 600,
          partnerDisplayName: 'Needle partner $index',
          categoryDisplayName: 'Utilities',
          categoryColorId: 'fallback',
          categoryIconId: 'fallback',
        ),
      );
      final repository = _FocusSeedRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        pageSize: 2,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      expect(await core.updateLiveSearch('needle'), isTrue);
      final focusedFrame = core.preparedIndex!.frameFor(
        core.navigation.state.parentQueryScope,
      );
      expect(focusedFrame.entryCount, rows.length);
      expect(focusedFrame.logBox.nextCursor, isNotNull);

      core.committedLogViewport.configureSurfaceWidth(378);
      expect(await core.requestForwardPageDemand(1), isTrue);

      expect(core.paging.preparedPageReadCount, 1);
      expect(repository.committedPageReads, 0);
      final page = core.committedLogViewport.pageForOrdinal(1)!;
      expect(page.queryKey, core.visibleFrames.value!.queryKey);
      expect(page.rowCount, 2);
    },
  );

  test(
    'category acceptance publishes one live interaction provenance frame',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );

      final frame = core.liveInteractions.frame!;
      expect(frame.source, DashboardLiveInteractionSource.logBoxCategory);
      expect(frame.category?.id, 'utilities');
      expect(frame.direction, LedgerDirection.income);
      expect(
        frame.temporalCandidate.effectiveScope,
        core.navigation.state.effectiveScope,
      );
    },
  );

  test(
    'RED MYHP-15: an unprimed Mind slider fails closed instead of lazy-admitting a source membership',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.mindAmountPreparedBaseCount, 0);
      FluviDiagnosticLogger.clear();

      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 100000,
            upperScaled100: 900000,
          ),
        ),
        isFalse,
      );

      expect(
        core.mindAmountPreparedBaseCount,
        0,
        reason:
            'A pointer/slider path must not register the installed index and '
            'scan its raw entries merely to service the first thumb tick.',
      );
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'MIND|DRAG_START')
            .scope,
        contains('baseReady=false'),
      );
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'MIND|PREVIEW_REJECTED')
            .scope,
        contains('reason=baseUnavailable'),
      );
    },
  );

  test(
    'Mind amount drag publishes an exact resident preview without a Query build or committed navigation mutation',
    () async {
      final rows = <DashboardLedgerEntry>[
        for (final (index, amount) in <int>[100000, 200000, 300000].indexed)
          DashboardLedgerEntry(
            id: 'amount-$amount',
            partnerId: 'partner-$index',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: amount,
            bookedLocalEpochDay: 20636 - index,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Partner $index',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
      ];
      final repository = _FocusSeedRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final committed = core.visibleFrames.value!;
      final navigation = core.navigation.state;
      final applied = core.currentQuery.scopeFor(LedgerDirection.income);
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 600000,
          ),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 100000,
            maximumAmountScaled100: 300000,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(repository.prepareCalls, 1);

      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 300000,
            lowerScaled100: 150000,
            upperScaled100: 250000,
          ),
        ),
        isTrue,
      );

      expect(core.visibleFrames.value, same(committed));
      expect(core.navigation.state, same(navigation));
      expect(core.currentQuery.scopeFor(LedgerDirection.income), applied);
      expect(core.visibleFrames.countLane.value!.count.entryCount, 1);
      expect(
        core.visibleFrames.logBoxLane.value!.preparedFrame.stableRowIdentities,
        <String>['amount-200000'],
      );
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'MIND|PREVIEW_FRAME')
            .scope,
        contains('repositoryRequests=0 indexBuilds=0 canonicalCommits=0'),
      );
    },
  );

  test(
    'AMD-04: Mind publishes the visible 2027 amount maximum, not an all-time rent maximum',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'rent-2026',
              direction: 'expense',
              categoryId: 'housing',
              partnerId: 'landlord',
              amount: 26000000,
              date: const LocalDate(year: 2026, month: 1, day: 5),
            ),
            _mindYearEntry(
              id: 'fastfood-min-2027',
              direction: 'expense',
              categoryId: 'fastfood',
              partnerId: 'kfc',
              amount: 180000,
              date: const LocalDate(year: 2027, month: 1, day: 5),
            ),
            _mindYearEntry(
              id: 'fastfood-max-2027',
              direction: 'expense',
              categoryId: 'fastfood',
              partnerId: 'mcdonalds',
              amount: 1350000,
              date: const LocalDate(year: 2027, month: 12, day: 5),
            ),
          ],
        ),
        initialDate: DateTime.utc(2027, 6, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      final binding = core.mindAmountRangeBindingFor(LedgerDirection.expense)!;

      expect(binding.values.maximumScaled100, 1350000);
      expect(binding.values.minimumScaled100, 100000);
      expect(binding.values.upperScaled100, 1350000);
    },
  );

  test(
    'RED SUM/MONTH-HM-13: one Core temporal coordinator publishes range-preview frames without source work',
    () async {
      final rows = <DashboardLedgerEntry>[
        _mindYearEntry(
          id: 'income-2024-jan',
          direction: 'income',
          categoryId: 'salary',
          partnerId: 'employer',
          amount: 100000,
          date: const LocalDate(year: 2024, month: 1, day: 2),
        ),
        _mindYearEntry(
          id: 'income-2025-may-low',
          direction: 'income',
          categoryId: 'salary',
          partnerId: 'employer',
          amount: 200000,
          date: const LocalDate(year: 2025, month: 5, day: 2),
        ),
        _mindYearEntry(
          id: 'income-2025-may-high',
          direction: 'income',
          categoryId: 'salary',
          partnerId: 'employer',
          amount: 500000,
          date: const LocalDate(year: 2025, month: 5, day: 3),
        ),
      ];
      final monthRepository = _FocusSeedRepository(rows: rows);
      final month = DashboardCoreController(
        dataRepository: monthRepository,
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(month.dispose);
      await month.bootstrap();
      _installMindAmountDomain(month, LedgerDirection.income);
      expect(await month.primeMindAmountPreviewDomain(), isTrue);
      expect(month.ensureMindTemporalVisualProjection(), isTrue);
      expect(month.mindTemporalHeatmap.value, isA<MindMonthHeatmapFrame>());
      final initialMonth =
          month.mindTemporalHeatmap.value! as MindMonthHeatmapFrame;
      expect(initialMonth.total, 700000);
      final initialMonthScore = month.mindBehavioralScore.value!;
      expect(
        initialMonthScore.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 3).epochDay,
        reason:
            'One ordinary Core admission publishes the selected Month body '
            'and Header score target together, before any later frame.',
      );
      expect(
        initialMonthScore.chartSeries!.startInclusiveEpochDay,
        const LocalDate(year: 2025, month: 5, day: 1).epochDay,
        reason:
            'The chart carries the complete selected Month calendar domain; '
            'its endpoint remains the latest meaningful daily score point.',
      );
      expect(
        initialMonthScore.chartSeries!.points.last,
        initialMonthScore.point,
      );
      final repositoryReadsBeforePreview = monthRepository.committedPageReads;
      final indexBuildsBeforePreview = monthRepository.prepareCalls;

      month.beginMindAmountRangeInteraction();
      expect(
        month.previewMindAmountRange(
          QueryAmountRangeValues(
            minimumScaled100: initialMonth.range.minimumScaled100,
            maximumScaled100: initialMonth.range.maximumScaled100,
            lowerScaled100: 500000,
            upperScaled100: initialMonth.range.upperScaled100,
          ),
        ),
        isTrue,
      );
      final previewMonth =
          month.mindTemporalHeatmap.value! as MindMonthHeatmapFrame;
      expect(previewMonth.total, 500000);
      expect(previewMonth.range.lowerScaled100, 500000);
      final previewMonthScore = month.mindBehavioralScore.value!;
      expect(previewMonthScore.range, previewMonth.range);
      expect(
        previewMonthScore.chartSeries!.points.last,
        previewMonthScore.point,
      );
      expect(monthRepository.committedPageReads, repositoryReadsBeforePreview);
      expect(monthRepository.prepareCalls, indexBuildsBeforePreview);
      month.endMindAmountRangeInteraction(committed: false);

      final sumRepository = _FocusSeedRepository(rows: rows);
      final sum = DashboardCoreController(
        dataRepository: sumRepository,
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(sum.dispose);
      await sum.bootstrap();
      _installMindAmountDomain(sum, LedgerDirection.income);
      expect(await sum.primeMindAmountPreviewDomain(), isTrue);
      expect(sum.ensureMindTemporalVisualProjection(), isTrue);
      final sumFrame = sum.mindTemporalHeatmap.value! as MindSumHeatmapFrame;
      expect(sumFrame.years, containsAllInOrder(<int>[2024, 2025]));
      expect(sumFrame.month(year: 2025, month: 5).total, 700000);
      final sumScore = sum.mindBehavioralScore.value!;
      expect(
        sumScore.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 3).epochDay,
        reason:
            'Sum uses the same accepted semantic target as its temporal '
            'heatmap rather than retaining a previous Year/Month score.',
      );
      expect(
        sumScore.chartSeries!.startInclusiveEpochDay,
        const LocalDate(year: 2024, month: 1, day: 2).epochDay,
      );
      expect(sumScore.chartSeries!.points.last, sumScore.point);
      final sumReadsBeforePreview = sumRepository.committedPageReads;
      final sumPreparesBeforePreview = sumRepository.prepareCalls;
      sum.beginMindAmountRangeInteraction();
      const sumPreviewRange = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 500000,
        lowerScaled100: 500000,
        upperScaled100: 500000,
      );
      expect(sum.previewMindAmountRange(sumPreviewRange), isTrue);
      final previewSum = sum.mindTemporalHeatmap.value! as MindSumHeatmapFrame;
      expect(previewSum.range, sumPreviewRange);
      expect(previewSum.month(year: 2025, month: 5).total, 500000);
      final previewSumScore = sum.mindBehavioralScore.value!;
      expect(previewSumScore.range, sumPreviewRange);
      expect(previewSumScore.chartSeries!.points.last, previewSumScore.point);
      expect(sumRepository.committedPageReads, sumReadsBeforePreview);
      expect(sumRepository.prepareCalls, sumPreparesBeforePreview);
      sum.endMindAmountRangeInteraction(committed: false);
    },
  );

  test(
    'SUM/MON-03/04: the resident temporal coordinator keeps Sum and Month heatmap, Header score and range preview on one focus/direction target',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-salary-2024',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 100000,
            date: const LocalDate(year: 2024, month: 1, day: 2),
          ),
          _mindYearEntry(
            id: 'income-food-2025',
            direction: 'income',
            categoryId: 'food',
            partnerId: 'shop',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 5, day: 2),
          ),
          _mindYearEntry(
            id: 'expense-food-low-2025',
            direction: 'expense',
            categoryId: 'food',
            partnerId: 'shop',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 5, day: 2),
          ),
          _mindYearEntry(
            id: 'expense-food-high-2025',
            direction: 'expense',
            categoryId: 'food',
            partnerId: 'shop',
            amount: 500000,
            date: const LocalDate(year: 2025, month: 5, day: 3),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);

      MindSumHeatmapFrame sumFrame() =>
          core.mindTemporalHeatmap.value! as MindSumHeatmapFrame;
      MindBehavioralScoreFrame scoreFrame() => core.mindBehavioralScore.value!;

      expect(sumFrame().month(year: 2025, month: 5).total, 200000);
      expect(scoreFrame().identity.direction, LedgerDirection.income);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'food', displayName: 'Food'),
        ),
        isTrue,
      );
      expect(sumFrame().month(year: 2025, month: 5).total, 200000);
      expect(
        scoreFrame().identity.upstreamScopeKey,
        contains('focus:category=food'),
      );
      expect(
        scoreFrame().range,
        sumFrame().range,
        reason:
            'A focus admission may not leave the Sum body and Header score '
            'on different amount identities.',
      );

      core.selectDirection(TransactionDirection.expense);
      await pumpEventQueue(times: 12);
      expect(sumFrame().month(year: 2025, month: 5).total, 700000);
      expect(scoreFrame().identity.direction, LedgerDirection.expense);
      expect(scoreFrame().range, sumFrame().range);

      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.month,
        isRailOpen: false,
      );
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      final month = core.mindTemporalHeatmap.value! as MindMonthHeatmapFrame;
      expect(month.year, 2025);
      expect(month.month, 5);
      expect(month.total, 700000);
      expect(scoreFrame().identity.direction, LedgerDirection.expense);
      expect(scoreFrame().range, month.range);

      final readsBeforePreview = repository.committedPageReads;
      final preparesBeforePreview = repository.prepareCalls;
      const onlyLowerExpense = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 200000,
        upperScaled100: 200000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(onlyLowerExpense), isTrue);
      final preview = core.mindTemporalHeatmap.value! as MindMonthHeatmapFrame;
      expect(preview.total, 200000);
      expect(preview.range, onlyLowerExpense);
      expect(scoreFrame().range, preview.range);
      expect(scoreFrame().chartSeries!.points.last, scoreFrame().point);
      expect(repository.committedPageReads, readsBeforePreview);
      expect(repository.prepareCalls, preparesBeforePreview);
      final scoreCounter = core.mindBehavioralScore.sourceWorkCounter!;
      expect(scoreCounter.sourceRowTouchesDuringPreview, 0);
      expect(scoreCounter.repositoryAccessesDuringPreview, 0);
      expect(scoreCounter.indexBuildsDuringPreview, 0);
      core.endMindAmountRangeInteraction(committed: false);
    },
  );

  testWidgets(
    'ATOM-03/04: mounted Sum and Month selector targets publish one matching heatmap and score frame before settle',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-2024',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 100000,
              date: const LocalDate(year: 2024, month: 1, day: 2),
            ),
            _mindYearEntry(
              id: 'income-2025-low',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 200000,
              date: const LocalDate(year: 2025, month: 5, day: 2),
            ),
            _mindYearEntry(
              id: 'income-2025-high',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 500000,
              date: const LocalDate(year: 2025, month: 5, day: 3),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.sum,
        isRailOpen: false,
      );
      // Intentionally no pumpAndSettle: this is the first mounted selector
      // frame which has accepted the new semantic target.
      await tester.pump();
      final sum = core.mindTemporalHeatmap.value;
      final sumScore = core.mindBehavioralScore.value;
      expect(core.navigation.state.plane, TimePlane.sum);
      expect(sum, isA<MindSumHeatmapFrame>());
      expect(sumScore, isNotNull);
      expect(
        sumScore!.chartSeries!.startInclusiveEpochDay,
        const LocalDate(year: 2024, month: 1, day: 2).epochDay,
      );
      expect(
        sumScore.chartSeries!.points.last,
        sumScore.point,
        reason:
            'The Header score and its chart endpoint are one Sum semantic '
            'publication, not a stale Month result.',
      );

      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.month,
        isRailOpen: false,
      );
      await tester.pump();
      final month = core.mindTemporalHeatmap.value;
      final monthScore = core.mindBehavioralScore.value;
      expect(core.navigation.state.plane, TimePlane.month);
      expect(month, isA<MindMonthHeatmapFrame>());
      expect(monthScore, isNotNull);
      expect(
        monthScore!.chartSeries!.startInclusiveEpochDay,
        const LocalDate(year: 2025, month: 5, day: 1).epochDay,
      );
      expect(monthScore.chartSeries!.points.last, monthScore.point);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'MONTH-LIVE-01 RED: a renderer-accepted Month target publishes body and score before canonical settle',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-june',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 200000,
            date: const LocalDate(year: 2026, month: 6, day: 2),
          ),
          _mindYearEntry(
            id: 'income-july-prior-year',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 350000,
            date: const LocalDate(year: 2025, month: 7, day: 2),
          ),
          _mindYearEntry(
            id: 'income-july',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 500000,
            date: const LocalDate(year: 2026, month: 7, day: 3),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 3),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      final origin = core.navigation.state;
      expect(origin.monthCursor, const YearMonth(year: 2026, month: 7));
      core.beginSegmentedSummaryMotion();
      final acceptedJune = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: false,
        component: DashboardTemporalAnchorComponent.month,
        offset: -1,
        base: origin,
      )!;
      expect(acceptedJune.monthCursor, const YearMonth(year: 2026, month: 6));
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: acceptedJune,
              component: DashboardTemporalAnchorComponent.month,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );

      // This is the exact renderer acknowledgement delivered by the mounted
      // segmented Summary.  No settle follows: this is the physical liveness
      // boundary that Year already owns and Month currently misses.
      core.noteSegmentedSummaryComponentVisualTargetPainted(
        candidate: acceptedJune,
        component: DashboardTemporalAnchorComponent.month,
      );
      await tester.pump();

      final frame = core.mindTemporalHeatmap.value;
      expect(frame, isA<MindMonthHeatmapFrame>());
      final monthFrame = frame! as MindMonthHeatmapFrame;
      expect(monthFrame.year, 2026);
      expect(monthFrame.month, 6);
      expect(find.text('június 2026'), findsOneWidget);
      expect(
        core.mindBehavioralScore.identity?.navigationEpoch,
        1,
        reason:
            'Month heatmap and Header score must share the accepted Summary generation before settle.',
      );
      expect(
        core.mindBehavioralScore.value?.chartSeries?.points.last,
        core.mindBehavioralScore.value?.point,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('mind-header-score-text')),
            )
            .data,
        '${core.mindBehavioralScore.value!.point.roundedScore}/100',
      );
      expect(
        find.byKey(const ValueKey<String>('mind-header-score-chart')),
        findsOneWidget,
      );
      expect(
        core.navigation.state.monthCursor,
        const YearMonth(year: 2026, month: 7),
        reason: 'Renderer admission must not force canonical Month settlement.',
      );
      expect(repository.prepareCalls, 1);

      // A parent-year crossing is the second Month target shape. The Month
      // component remains July, but its accepted calendar year changes before
      // canonical navigation is allowed to settle.
      core.beginSegmentedSummaryMotion();
      final acceptedPriorYear = core
          .experimentalTemporalComponentOffsetCandidate(
            plane: TimePlane.month,
            isRailOpen: false,
            component: DashboardTemporalAnchorComponent.year,
            offset: -1,
            base: origin,
          )!;
      expect(
        acceptedPriorYear.monthCursor,
        const YearMonth(year: 2025, month: 7),
      );
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: acceptedPriorYear,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );
      core.noteSegmentedSummaryComponentVisualTargetPainted(
        candidate: acceptedPriorYear,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();

      final parentYearFrame = core.mindTemporalHeatmap.value;
      expect(parentYearFrame, isA<MindMonthHeatmapFrame>());
      final parentYearMonthFrame = parentYearFrame! as MindMonthHeatmapFrame;
      expect(parentYearMonthFrame.year, 2025);
      expect(parentYearMonthFrame.month, 7);
      expect(find.text('július 2025'), findsOneWidget);
      expect(core.mindBehavioralScore.identity?.navigationEpoch, 2);
      expect(
        core.navigation.state.monthCursor,
        const YearMonth(year: 2026, month: 7),
        reason:
            'The renderer acknowledgement publishes the new Month target, '
            'not an early canonical parent-Year commit.',
      );
    },
  );

  testWidgets(
    'LIV-04: the mounted shared compact slider publishes Month, Sum and Year heatmap plus Header score in its first preview frame',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2024',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 100000,
            date: const LocalDate(year: 2024, month: 1, day: 2),
          ),
          _mindYearEntry(
            id: 'income-2025-low',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 5, day: 2),
          ),
          _mindYearEntry(
            id: 'income-2025-high',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 500000,
            date: const LocalDate(year: 2025, month: 5, day: 3),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      RangeSlider slider() => tester.widget<RangeSlider>(
        find.byKey(const ValueKey<String>('query-amount-range-slider')),
      );
      void expectFirstPreviewFrame(QueryAmountRangeValues expected) {
        final heatmap = core.mindTemporalHeatmap.value;
        final score = core.mindBehavioralScore.value;
        String rangeDigest(QueryAmountRangeValues values) =>
            '${values.minimumScaled100}/${values.maximumScaled100} '
            '${values.lowerScaled100}/${values.upperScaled100}';
        expect(heatmap, isNotNull);
        expect(score, isNotNull);
        expect(
          heatmap!.range,
          expected,
          reason:
              'heatmap=${rangeDigest(heatmap.range)} expected=${rangeDigest(expected)}',
        );
        expect(
          score!.range,
          expected,
          reason:
              'score=${rangeDigest(score.range)} expected=${rangeDigest(expected)}',
        );
        expect(score.chartSeries!.points.last, score.point);
      }

      final readsBefore = repository.committedPageReads;
      final preparesBefore = repository.prepareCalls;
      slider().onChangeStart!(const RangeValues(100000, 500000));
      slider().onChanged!(const RangeValues(500000, 500000));
      // No settle: the shared display-frame coalescer's first accepted
      // preview frame is the liveness deadline.
      await tester.pump();
      const onlyHigh = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 500000,
        upperScaled100: 500000,
      );
      expect(core.mindTemporalHeatmap.value, isA<MindMonthHeatmapFrame>());
      expectFirstPreviewFrame(onlyHigh);

      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.sum,
        isRailOpen: false,
      );
      await tester.pump();
      expect(core.mindTemporalHeatmap.value, isA<MindSumHeatmapFrame>());
      slider().onChanged!(const RangeValues(200000, 500000));
      await tester.pump();
      const middleAndHigh = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 500000,
        lowerScaled100: 200000,
        upperScaled100: 500000,
      );
      expectFirstPreviewFrame(middleAndHigh);

      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.year,
        isRailOpen: false,
      );
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();
      expect(core.mindTemporalHeatmap.value, isA<MindYearHeatmapFrame>());
      slider().onChanged!(const RangeValues(200000, 200000));
      await tester.pump();
      const onlyLow = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 500000,
        lowerScaled100: 200000,
        upperScaled100: 200000,
      );
      expectFirstPreviewFrame(onlyLow);
      expect(repository.committedPageReads, readsBefore);
      expect(repository.prepareCalls, preparesBefore);
      final counter = core.mindBehavioralScore.sourceWorkCounter!;
      expect(counter.sourceRowTouchesDuringPreview, 0);
      expect(counter.repositoryAccessesDuringPreview, 0);
      expect(counter.indexBuildsDuringPreview, 0);
      expect(counter.maxDayBucketsVisitedPerPreview, lessThanOrEqualTo(366));
      const measuresPreviewMicros = bool.fromEnvironment(
        'FLUVI_PHYSICAL_RAIL_DIAGNOSTICS',
      );
      final previewTiming = counter.previewDurationSummary();
      if (measuresPreviewMicros) {
        expect(previewTiming['sampleCount'], greaterThanOrEqualTo(3));
        expect(
          previewTiming['p95Micros'],
          greaterThanOrEqualTo(previewTiming['p50Micros']!),
        );
        expect(
          previewTiming['maxMicros'],
          greaterThanOrEqualTo(previewTiming['p95Micros']!),
        );
        // This is intentionally a bounded test-profile evidence line, not a
        // device-frame claim. The final report records its exact values.
        // ignore: avoid_print
        print('LIV-04 score preview micros: $previewTiming');
      }
      slider().onChangeEnd!(const RangeValues(200000, 200000));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RED AMD-06: a mounted Mind slider never paints the canonical all-time domain while its exact visible Year domain is pending',
    (tester) async {
      final rows = <DashboardLedgerEntry>[
        _mindYearEntry(
          id: 'rent-2026',
          direction: 'expense',
          categoryId: 'housing',
          partnerId: 'landlord',
          amount: 26000000,
          date: const LocalDate(year: 2026, month: 1, day: 5),
        ),
        _mindYearEntry(
          id: 'fastfood-min-2027',
          direction: 'expense',
          categoryId: 'fastfood',
          partnerId: 'kfc',
          amount: 180000,
          date: const LocalDate(year: 2027, month: 1, day: 5),
        ),
        _mindYearEntry(
          id: 'fastfood-max-2027',
          direction: 'expense',
          categoryId: 'fastfood',
          partnerId: 'mcdonalds',
          amount: 1350000,
          date: const LocalDate(year: 2027, month: 12, day: 5),
        ),
      ];
      final expectedVisibleMaximum = rows
          .where(
            (entry) =>
                entry.direction == 'expense' &&
                DateTime.fromMillisecondsSinceEpoch(
                      entry.bookedLocalEpochDay * Duration.millisecondsPerDay,
                      isUtc: true,
                    ).year ==
                    2027,
          )
          .map((entry) => entry.amountMinor)
          .reduce((maximum, amount) => amount > maximum ? amount : maximum);
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(rows: rows),
        initialDate: DateTime.utc(2027, 6, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      core.committedLogViewport.configureSurfaceWidth(378);

      // This deliberately models the narrow timing gap proven in source: the
      // generic Query-menu domain is resident but the exact visible Year
      // domain has not been published yet. A physical Mind slider must wait
      // for the latter instead of borrowing the unrelated 2026 rent maximum.
      final visibleScope = core.mindAmountDomainScopeFor(
        LedgerDirection.expense,
      );
      final canonicalScope = core.currentQuery.scopeFor(
        LedgerDirection.expense,
      );
      expect(
        QueryAmountRange.domainScope(visibleScope),
        isNot(QueryAmountRange.domainScope(canonicalScope)),
      );
      core.currentQuery.publishFacetPresentationForScope(
        canonicalScope,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 27530000,
          ),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 100000,
            maximumAmountScaled100: 26000000,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      expect(core.currentQuery.amountDomainForScope(visibleScope), isNull);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );

      // The pre-repair fallback renders a live RangeSlider with a 260,000 Ft
      // maximum at this exact first production-parent frame. That is the
      // forbidden visible lie; after repair the range remains unavailable
      // until its matching Year domain is admitted.
      expect(
        find.byKey(const ValueKey('query-amount-range-slider')),
        findsNothing,
      );

      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await tester.pump();
      final slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      expect(slider.max.round(), expectedVisibleMaximum);
      expect(find.text('Max.'), findsOneWidget);
      expect(find.text('13 500 Ft'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FOOT-04/DAY-01: the real Mind Day rail retains the one compact fixed range and legend without an hourly heatmap',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'day-income',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 250000,
              date: const LocalDate(year: 2025, month: 5, day: 3),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      // The mounted production host owns the normal LogBox surface layout.
      // Prime the compact Mind range only after that owner has admitted it;
      // otherwise this integration test asks the scene cache to prepare
      // before its required layout exists.
      await tester.pump();
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await tester.pump();

      expect(core.navigation.state.isRailOpen, isTrue);
      expect(core.navigation.state.plane, TimePlane.month);
      expect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
        findsNothing,
        reason: 'Day remains daily-score content, never an hourly heatmap.',
      );
      expect(
        find.byKey(const ValueKey<String>('mind-heatmap-palette-legend')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('query-amount-range-slider')),
        findsOneWidget,
      );
      expect(find.text('Összeg'), findsNothing);
      expect(find.text('Min.'), findsOneWidget);
      expect(find.text('Max.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'YEAR-6R-09: only the selected four-column Year layout expands the real Mind body',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'four-column-year',
              direction: 'expense',
              categoryId: 'food',
              partnerId: 'merchant',
              amount: 12000,
              date: const LocalDate(year: 2025, month: 5, day: 3),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 5, 3),
        initialPlane: TimePlane.year,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      await tester.pump();
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();

      final body = find.byKey(
        const ValueKey<String>('dashboard-core-mode-mind-body'),
      );
      final baselineBounds = tester.getRect(body);
      core.mindYearHeatmapPresentation.setMonthCardLayout(
        MindYearMonthCardLayout.fourColumns,
      );
      await tester.pump();

      expect(
        tester.getRect(body).height,
        baselineBounds.height +
            MindYearMonthCardLayout
                .fourColumns
                .requiredMindModeContentExtraHeight,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-year-heatmap-fit-scroll')),
        findsOneWidget,
      );

      core.mindYearHeatmapPresentation.setMonthCardLayout(
        MindYearMonthCardLayout.threeColumns,
      );
      await tester.pump();
      expect(tester.getRect(body).height, baselineBounds.height);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'MBS-01/04: production Core publishes the matching daily score on range preview, commit, direction and focus changes',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-100',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 100000,
            date: const LocalDate(year: 2025, month: 5, day: 1),
          ),
          _mindYearEntry(
            id: 'income-200',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 5, day: 10),
          ),
          _mindYearEntry(
            id: 'income-300',
            direction: 'income',
            categoryId: 'bonus',
            partnerId: 'employer',
            amount: 300000,
            date: const LocalDate(year: 2025, month: 5, day: 15),
          ),
          _mindYearEntry(
            id: 'expense-200',
            direction: 'expense',
            categoryId: 'food',
            partnerId: 'shop',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 5, day: 14),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 5, 15),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await pumpEventQueue(times: 12);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);

      final initial = core.mindBehavioralScore.value!;
      expect(initial.identity.direction, LedgerDirection.income);
      expect(
        initial.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 15).epochDay,
      );
      expect(initial.point.noSignal, isFalse);
      expect(initial.point.score, closeTo(76.25, .000001));
      expect(
        initial.chartSeries?.startInclusiveEpochDay,
        const LocalDate(year: 2025, month: 5, day: 1).epochDay,
        reason:
            'The expanded Header history starts at the actual current Month '
            'scope, while its endpoint remains the same canonical daily '
            'score point as the text.',
      );
      expect(initial.chartSeries?.points.last, initial.point);

      const middleOnly = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 200000,
        upperScaled100: 200000,
      );
      final sourceCounter = core.mindBehavioralScore.sourceWorkCounter!;
      final preparesBeforePreview = repository.prepareCalls;
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(middleOnly), isTrue);
      final preview = core.mindBehavioralScore.value!;
      expect(preview.range, middleOnly);
      expect(
        preview.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 10).epochDay,
      );
      expect(preview.point.score, 50);
      expect(preview.point.noSignal, isTrue);
      expect(
        preview.chartSeries?.startInclusiveEpochDay,
        const LocalDate(year: 2025, month: 5, day: 1).epochDay,
      );
      expect(preview.chartSeries?.points.last, preview.point);
      expect(repository.prepareCalls, preparesBeforePreview);
      expect(sourceCounter.sourceRowTouchesDuringPreview, 0);
      expect(sourceCounter.repositoryAccessesDuringPreview, 0);
      expect(sourceCounter.indexBuildsDuringPreview, 0);

      expect(await core.commitMindAmountRange(middleOnly), isTrue);
      await pumpEventQueue(times: 12);
      expect(
        core.currentQuery.scopeFor(LedgerDirection.income).refinements,
        <String, Object?>{
          QueryAmountRange.minimumRefinementKey: 200000,
          QueryAmountRange.maximumRefinementKey: 200000,
        },
      );
      expect(core.mindBehavioralScore.value?.range, middleOnly);

      core.selectDirection(TransactionDirection.expense);
      await pumpEventQueue(times: 12);
      expect(
        core.mindBehavioralScore.value?.identity.direction,
        LedgerDirection.expense,
      );
      expect(core.mindBehavioralScore.value?.point.score, 0);

      core.selectDirection(TransactionDirection.income);
      await pumpEventQueue(times: 12);
      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'salary', displayName: 'Salary'),
        ),
        isTrue,
      );
      expect(
        core.mindBehavioralScore.value?.identity.upstreamScopeKey,
        contains('focus:category=salary'),
      );
      expect(
        core.mindBehavioralScore.value?.range,
        const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 200000,
          lowerScaled100: 200000,
          upperScaled100: 200000,
        ),
        reason:
            'The canonical 2000-Ft filter stays selected, while the physical '
            'domain now follows the focused Salary population (1000–2000 Ft).',
      );
    },
  );

  test(
    'MSS-14 production score settings republish one coherent resident Header frame',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          for (var day = 1; day <= 14; day += 1)
            _mindYearEntry(
              id: 'expense-$day',
              direction: 'expense',
              categoryId: 'food',
              partnerId: 'shop',
              amount: 100000 + day * 1000,
              date: LocalDate(year: 2025, month: 1, day: day),
            ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 1, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await pumpEventQueue(times: 12);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);

      final initial = core.mindBehavioralScore.value!;
      final preparesBefore = repository.prepareCalls;
      expect(
        initial.identity.settings.expenseAlgorithm,
        MindExpenseScoreAlgorithm.causalTrailing,
      );
      expect(initial.point, initial.chartSeries!.points.last);

      const previewRange = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 114000,
        lowerScaled100: 111000,
        upperScaled100: 114000,
      );
      for (final algorithm in MindExpenseScoreAlgorithm.values) {
        core.mindBehavioralScoreSettings.setExpenseAlgorithm(algorithm);
        core.beginMindAmountRangeInteraction();
        // This pure Core parent has no installed visual LogBox surface, so
        // the outer transient-frame publication can fail closed. The semantic
        // resident score publication must still update synchronously; the
        // physical visible-preview contract is covered by the production
        // slider test above with a live render resource.
        core.previewMindAmountRange(previewRange);
        final preview = core.mindBehavioralScore.value!;
        expect(preview.range, previewRange, reason: algorithm.name);
        expect(preview.identity.settings.expenseAlgorithm, algorithm);
        expect(preview.point, preview.chartSeries!.points.last);
        core.endMindAmountRangeInteraction(committed: false);
      }

      core.mindBehavioralScoreSettings.setExpenseAlgorithm(
        MindExpenseScoreAlgorithm.causalTrailing,
      );
      core.mindBehavioralScoreSettings.setCausalHistoryOrigin(
        MindCausalHistoryOrigin.selectedScopeStart,
      );
      final causalScope = core.mindBehavioralScore.value!;
      expect(
        causalScope.identity.settings.causalHistoryOrigin,
        MindCausalHistoryOrigin.selectedScopeStart,
      );
      expect(causalScope.point, causalScope.chartSeries!.points.last);
      expect(
        repository.prepareCalls,
        preparesBefore,
        reason: 'settings are score provenance, not a Query/index mutation',
      );
    },
  );

  test(
    'MSS/HMP-29 score and heatmap setting combinations retain one latest coherent state',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          for (var day = 1; day <= 14; day += 1)
            _mindYearEntry(
              id: 'expense-$day',
              direction: 'expense',
              categoryId: 'food',
              partnerId: 'shop',
              amount: 100000 + day * 1000,
              date: LocalDate(year: 2025, month: 1, day: day),
            ),
          for (var day = 1; day <= 3; day += 1)
            _mindYearEntry(
              id: 'income-$day',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 200000 + day * 10000,
              date: LocalDate(year: 2025, month: 1, day: day),
            ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 1, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.expense);
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await pumpEventQueue(times: 12);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);

      void expectCoherentScore(MindExpenseScoreAlgorithm algorithm) {
        final frame = core.mindBehavioralScore.value!;
        expect(frame.identity.settings.expenseAlgorithm, algorithm);
        expect(frame.point, frame.chartSeries!.points.last);
      }

      // Matrix 1: HTML centered + Fluvi + 3x4 + no footers.
      core.mindBehavioralScoreSettings.setExpenseAlgorithm(
        MindExpenseScoreAlgorithm.htmlCentered,
      );
      core.mindYearHeatmapPresentation.setPaletteStyle(
        MindYearHeatmapPaletteStyle.fluvi,
      );
      core.mindYearHeatmapPresentation.setMonthCardLayout(
        MindYearMonthCardLayout.threeColumns,
      );
      core.mindYearHeatmapPresentation.setShowMonthlyNetClose(false);
      core.mindYearHeatmapPresentation.setShowMonthlyDirectionTotal(false);
      expectCoherentScore(MindExpenseScoreAlgorithm.htmlCentered);
      expect(
        core.mindYearHeatmapPresentation.value,
        const MindYearHeatmapPresentationSettings.defaults(),
      );

      // Matrix 2: HTML trailing + B3M + 3x4 + net.
      core.mindBehavioralScoreSettings.setExpenseAlgorithm(
        MindExpenseScoreAlgorithm.htmlTrailing,
      );
      core.mindYearHeatmapPresentation.setPaletteStyle(
        MindYearHeatmapPaletteStyle.b3mMy3,
      );
      core.mindYearHeatmapPresentation.setShowMonthlyNetClose(true);
      expectCoherentScore(MindExpenseScoreAlgorithm.htmlTrailing);
      expect(
        core.mindYearHeatmapPresentation.value.showMonthlyNetClose,
        isTrue,
      );

      // Matrix 3: causal/full history + B3M + 2x6 + both footers.
      core.mindBehavioralScoreSettings.setExpenseAlgorithm(
        MindExpenseScoreAlgorithm.causalTrailing,
      );
      core.mindBehavioralScoreSettings.setCausalHistoryOrigin(
        MindCausalHistoryOrigin.fullFilteredHistory,
      );
      core.mindYearHeatmapPresentation.setMonthCardLayout(
        MindYearMonthCardLayout.twoColumns,
      );
      core.mindYearHeatmapPresentation.setShowMonthlyDirectionTotal(true);
      expectCoherentScore(MindExpenseScoreAlgorithm.causalTrailing);
      expect(
        core.mindYearHeatmapPresentation.value,
        isA<MindYearHeatmapPresentationSettings>()
            .having(
              (settings) => settings.paletteStyle,
              'palette',
              MindYearHeatmapPaletteStyle.b3mMy3,
            )
            .having(
              (settings) => settings.monthCardLayout,
              'layout',
              MindYearMonthCardLayout.twoColumns,
            )
            .having((settings) => settings.showMonthlyNetClose, 'net', isTrue)
            .having(
              (settings) => settings.showMonthlyDirectionTotal,
              'direction total',
              isTrue,
            ),
      );

      // Matrix 4: causal/scope start + Fluvi + 2x6 + direction total.
      core.mindBehavioralScoreSettings.setCausalHistoryOrigin(
        MindCausalHistoryOrigin.selectedScopeStart,
      );
      core.mindYearHeatmapPresentation.setPaletteStyle(
        MindYearHeatmapPaletteStyle.fluvi,
      );
      core.mindYearHeatmapPresentation.setShowMonthlyNetClose(false);
      expectCoherentScore(MindExpenseScoreAlgorithm.causalTrailing);
      expect(
        core.mindYearHeatmapPresentation.value.showMonthlyDirectionTotal,
        isTrue,
      );

      // Rapid final state: algorithm -> live preview -> direction -> layout.
      core.mindBehavioralScoreSettings.setExpenseAlgorithm(
        MindExpenseScoreAlgorithm.htmlTrailing,
      );
      core.beginMindAmountRangeInteraction();
      core.previewMindAmountRange(
        const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 108000,
          upperScaled100: 114000,
        ),
      );
      core.selectDirection(TransactionDirection.income);
      core.mindYearHeatmapPresentation.setMonthCardLayout(
        MindYearMonthCardLayout.threeColumns,
      );
      await pumpEventQueue(times: 12);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);
      expect(core.transactionDirection.direction, TransactionDirection.income);
      final finalFrame = core.mindBehavioralScore.value!;
      expect(finalFrame.identity.direction, LedgerDirection.income);
      expect(
        finalFrame.identity.settings.expenseAlgorithm,
        MindExpenseScoreAlgorithm.htmlTrailing,
        reason: 'Income must not overwrite the selected Expense mathematics.',
      );
      expect(finalFrame.point, finalFrame.chartSeries!.points.last);
      expect(
        core.mindYearHeatmapPresentation.value.monthCardLayout,
        MindYearMonthCardLayout.threeColumns,
      );
      core.endMindAmountRangeInteraction(committed: false);
    },
  );

  testWidgets(
    'MBS-01: an actually visible rail child retargets its score before settle without resurrecting coalesced children',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-14',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 200000,
              date: const LocalDate(year: 2025, month: 5, day: 14),
            ),
            _mindYearEntry(
              id: 'income-15',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 300000,
              date: const LocalDate(year: 2025, month: 5, day: 15),
            ),
            _mindYearEntry(
              id: 'income-16',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 400000,
              date: const LocalDate(year: 2025, month: 5, day: 16),
            ),
          ],
          withPreparedYearRows: true,
        ),
        initialDate: DateTime.utc(2025, 5, 15),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      expect(
        core.mindBehavioralScore.value?.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 15).epochDay,
      );

      final catalog = core.presentation.motion.catalog;
      final day14 = catalog.logicalIndexForValue(14);
      final day16 = catalog.logicalIndexForValue(16);
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(day14);
      core.semanticCrossed(day16);
      await tester.pump();

      expect(
        core.visibleFrames.value?.scope.timeScope,
        const DayScope(LocalDate(year: 2025, month: 5, day: 16)),
      );
      expect(
        core.mindBehavioralScore.value?.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 16).epochDay,
      );
      expect(
        core.mindBehavioralScore.identity?.targetEpochDay,
        const LocalDate(year: 2025, month: 5, day: 16).epochDay,
      );
      final dayFrame = core.mindTemporalHeatmap.value;
      expect(dayFrame, isA<MindDayHeatmapFrame>());
      expect(
        (dayFrame! as MindDayHeatmapFrame).date,
        const LocalDate(year: 2025, month: 5, day: 16),
        reason:
            'The Day body must follow the actually visible rail child on the '
            'same frame as the pre-settle score publication.',
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
        findsOneWidget,
        reason: 'The mounted Mind body must paint the accepted Day target.',
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-date')),
        findsOneWidget,
      );
      final headerScore = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mind-header-score-text')),
      );
      expect(
        headerScore.data,
        '${core.mindBehavioralScore.value!.point.roundedScore}/100',
        reason:
            'The mounted Header text reads the same accepted Day score as '
            'the visible body and chart endpoint.',
      );
      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 100000,
            upperScaled100: 900000,
          ),
        ),
        isTrue,
      );
      await tester.pump();
      expect(
        (core.mindTemporalHeatmap.value! as MindDayHeatmapFrame).date,
        const LocalDate(year: 2025, month: 5, day: 16),
        reason:
            'A held range preview cannot restore the pre-crossing Day body.',
      );
      expect(
        core.mindBehavioralScore.value?.point.epochDay,
        const LocalDate(year: 2025, month: 5, day: 16).epochDay,
        reason:
            'A held range preview uses the same accepted Day target as the '
            '24-hour heatmap.',
      );
      core.endMindAmountRangeInteraction(committed: false);
      expect(
        core.mindBehavioralScore.publicationCount,
        greaterThanOrEqualTo(2),
        reason:
            'The final visible child receives a new score; coalesced day 14 '
            'never becomes a visible score authority.',
      );
    },
  );

  testWidgets(
    'DAY-HOST-01 RED: an open Month rail renders one DayScope Mind body',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-day-hour-00',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 200000,
              date: const LocalDate(year: 2026, month: 7, day: 14),
              localTimeMinutes: 0,
            ),
            _mindYearEntry(
              id: 'income-day-hour-23',
              direction: 'income',
              categoryId: 'salary',
              partnerId: 'employer',
              amount: 300000,
              date: const LocalDate(year: 2026, month: 7, day: 14),
              localTimeMinutes: 1439,
            ),
          ],
        ),
        initialDate: DateTime.utc(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      expect(
        core.navigation.state.effectiveScope,
        const DayScope(LocalDate(year: 2026, month: 7, day: 14)),
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
        findsOneWidget,
      );
      expect(find.text('Óránkénti aktivitás'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-cell-00')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-cell-23')),
        findsOneWidget,
      );
      final score = core.mindBehavioralScore.value!;
      expect(
        score.chartSeries!.startInclusiveEpochDay,
        const LocalDate(year: 2026, month: 6, day: 14).epochDay,
        reason: 'Day presents a rolling 31-day daily score context.',
      );
      expect(
        score.chartSeries!.endInclusiveEpochDay,
        const LocalDate(year: 2026, month: 7, day: 14).epochDay,
      );
      expect(score.chartSeries!.points.last, score.point);
    },
  );

  testWidgets(
    'LEVEL-MONTH-01/02/03/04 RED: closing DayScope to Month publishes one mounted Month body and Header target without acquisition',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-june-day',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 250000,
            date: const LocalDate(year: 2027, month: 6, day: 6),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2027, 6, 6),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      expect(
        core.navigation.state.effectiveScope,
        const DayScope(LocalDate(year: 2027, month: 6, day: 6)),
      );
      expect(core.mindTemporalHeatmap.value, isA<MindDayHeatmapFrame>());
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
        findsOneWidget,
      );
      final readsBeforeLevelClose = repository.prepareCalls;
      final indexBeforeLevelClose = core.preparedIndex;

      FluviDiagnosticLogger.clear();
      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.month,
        isRailOpen: false,
      );
      // This is the first accepted Flutter opportunity.  Do not use a later
      // Month-component crossing or an unrelated settle to repair the body.
      await tester.pump();

      expect(core.navigation.state.effectiveScope, isA<MonthScope>());
      final frame = core.mindTemporalHeatmap.value;
      expect(frame, isA<MindMonthHeatmapFrame>());
      final month = frame! as MindMonthHeatmapFrame;
      expect(month.year, 2027);
      expect(month.month, 6);
      expect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
        findsOneWidget,
      );
      final monthGridRect = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
      );
      expect(monthGridRect.width, greaterThan(0));
      expect(monthGridRect.height, greaterThan(0));
      expect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
        findsNothing,
      );

      final monthScore = core.mindBehavioralScore.value!;
      expect(
        core.mindBehavioralScore.identity?.navigationEpoch,
        month.identity.navigationEpoch,
      );
      expect(
        monthScore.seriesRequest?.chartStartInclusiveEpochDay,
        const LocalDate(year: 2027, month: 6, day: 1).epochDay,
      );
      expect(
        monthScore.seriesRequest?.targetEpochDay,
        const LocalDate(year: 2027, month: 6, day: 6).epochDay,
      );
      expect(
        monthScore.chartSeries!.endInclusiveEpochDay,
        monthScore.point.epochDay,
      );
      expect(monthScore.chartSeries!.points.last, monthScore.point);
      expect(repository.prepareCalls, readsBeforeLevelClose);
      expect(core.preparedIndex, same(indexBeforeLevelClose));
      final admission = FluviDiagnosticLogger.entries.lastWhere(
        (event) =>
            event.stage == 'MIND_TEMPORAL_HEATMAP|ACCEPTED_TARGET_ADMISSION' &&
            (event.scope?.contains('source=visibleFrameLevelAcceptance') ??
                false),
      );
      expect(admission.scope, contains('published=true'));
      expect(admission.scope, contains('repositoryRequests=0'));
      expect(admission.scope, contains('indexBuilds=0'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LEVEL-MONTH-05: repeated Month-Day-Month level returns never retain a stale Day frame',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-june-day-round-trip',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 250000,
            date: const LocalDate(year: 2027, month: 6, day: 6),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2027, 6, 6),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();
      expect(core.mindTemporalHeatmap.value, isA<MindDayHeatmapFrame>());
      final readsBefore = repository.prepareCalls;
      final indexBefore = core.preparedIndex;

      for (final railOpen in <bool>[false, true, false, true, false]) {
        core.beginSegmentedSummaryMotion();
        core.navigateExperimentalTemporalSelection(
          plane: TimePlane.month,
          isRailOpen: railOpen,
        );
        await tester.pump();
        if (railOpen) {
          expect(core.navigation.state.effectiveScope, isA<DayScope>());
          expect(core.mindTemporalHeatmap.value, isA<MindDayHeatmapFrame>());
          expect(
            find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
            findsOneWidget,
          );
        } else {
          final frame = core.mindTemporalHeatmap.value;
          expect(core.navigation.state.effectiveScope, isA<MonthScope>());
          expect(frame, isA<MindMonthHeatmapFrame>());
          final month = frame! as MindMonthHeatmapFrame;
          expect(month.year, 2027);
          expect(month.month, 6);
          expect(
            find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
            findsNothing,
          );
        }
      }

      expect(repository.prepareCalls, readsBefore);
      expect(core.preparedIndex, same(indexBefore));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LEVEL-MONTH-06: a Day child, level close and later Month target paint only the latest Month',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-june-day-latest-wins',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 250000,
            date: const LocalDate(year: 2027, month: 6, day: 6),
          ),
          _mindYearEntry(
            id: 'income-july-month-latest-wins',
            direction: 'income',
            categoryId: 'salary',
            partnerId: 'employer',
            amount: 300000,
            date: const LocalDate(year: 2027, month: 7, day: 1),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2027, 6, 6),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      final origin = core.navigation.state;
      final dayChild = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;
      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: dayChild,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      expect(core.mindTemporalHeatmap.value, isA<MindDayHeatmapFrame>());

      // Keep these two later semantic targets in one render opportunity.  A
      // close can publish its visible June Month target internally, but it
      // may not leave a Day frame mounted or overwrite the later July target.
      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.month,
        isRailOpen: false,
      );
      final closedMonth = core.navigation.state;
      final latestMonth = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: false,
        component: DashboardTemporalAnchorComponent.month,
        offset: 1,
        base: closedMonth,
      )!;
      expect(latestMonth.monthCursor, const YearMonth(year: 2027, month: 7));
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: latestMonth,
              component: DashboardTemporalAnchorComponent.month,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );
      core.noteSegmentedSummaryComponentVisualTargetPainted(
        candidate: latestMonth,
        component: DashboardTemporalAnchorComponent.month,
      );
      await tester.pump();

      final frame = core.mindTemporalHeatmap.value;
      expect(frame, isA<MindMonthHeatmapFrame>());
      final month = frame! as MindMonthHeatmapFrame;
      expect(month.year, 2027);
      expect(month.month, 7);
      expect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mind-day-heatmap-grid')),
        findsNothing,
      );
      expect(
        core.mindBehavioralScore.value?.seriesRequest?.targetEpochDay,
        const LocalDate(year: 2027, month: 7, day: 1).epochDay,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SCALE-05: changing 10 to 20 repaints presentation without Core, Query, source or score work',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'expense-june-scale-presentation-only',
            direction: 'expense',
            categoryId: 'home',
            partnerId: 'utility',
            amount: 150000,
            date: const LocalDate(year: 2027, month: 6, day: 6),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2027, 6, 6),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      final frame = core.mindTemporalHeatmap.value;
      final score = core.mindBehavioralScore.value;
      final scoreProjection = core.mindBehavioralScore.projection;
      final index = core.preparedIndex;
      final navigation = core.navigation.state;
      final scope = core.currentQuery.scopeFor(LedgerDirection.expense);
      final repositoryCalls = repository.prepareCalls;
      var heatmapPublications = 0;
      var scorePublications = 0;
      var navigationMutations = 0;
      var queryMutations = 0;
      core.mindTemporalHeatmap.addListener(() => heatmapPublications += 1);
      core.mindBehavioralScore.addListener(() => scorePublications += 1);
      core.navigation.addListener(() => navigationMutations += 1);
      core.currentQuery.addListener(() => queryMutations += 1);

      core.mindYearHeatmapPresentation.setScaleResolution(
        MindHeatmapScaleResolution.twenty,
      );
      await tester.pump();

      expect(
        core.mindYearHeatmapPresentation.value.scaleResolution,
        MindHeatmapScaleResolution.twenty,
      );
      expect(core.mindTemporalHeatmap.value, same(frame));
      expect(core.mindBehavioralScore.value, same(score));
      expect(core.mindBehavioralScore.projection, same(scoreProjection));
      expect(core.preparedIndex, same(index));
      expect(core.navigation.state, same(navigation));
      expect(core.currentQuery.scopeFor(LedgerDirection.expense), same(scope));
      expect(repository.prepareCalls, repositoryCalls);
      expect(heatmapPublications, 0);
      expect(scorePublications, 0);
      expect(navigationMutations, 0);
      expect(queryMutations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CHART-TAP-09: repeated real Header taps keep score, Core, Query, Time and source identities stable',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'expense-june-chart-tap-presentation-only',
            direction: 'expense',
            categoryId: 'home',
            partnerId: 'utility',
            amount: 150000,
            date: const LocalDate(year: 2027, month: 6, day: 6),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2027, 6, 6),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindTemporalVisualProjection(), isTrue);
      await tester.pump();

      final plot = find.byKey(
        const ValueKey<String>('mind-header-score-chart-paint'),
      );
      expect(plot, findsOneWidget);
      final frame = core.mindTemporalHeatmap.value;
      final score = core.mindBehavioralScore.value;
      final scoreProjection = core.mindBehavioralScore.projection;
      final index = core.preparedIndex;
      final navigation = core.navigation.state;
      final scope = core.currentQuery.scopeFor(LedgerDirection.expense);
      final repositoryCalls = repository.prepareCalls;
      var heatmapPublications = 0;
      var scorePublications = 0;
      var navigationMutations = 0;
      var queryMutations = 0;
      core.mindTemporalHeatmap.addListener(() => heatmapPublications += 1);
      core.mindBehavioralScore.addListener(() => scorePublications += 1);
      core.navigation.addListener(() => navigationMutations += 1);
      core.currentQuery.addListener(() => queryMutations += 1);

      final center = tester.getCenter(plot);
      await tester.tapAt(center);
      await tester.pump();
      await tester.tapAt(center);
      await tester.pump();
      await tester.tapAt(center);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('mind-header-score-chart-selected-score'),
        ),
        findsOneWidget,
      );
      expect(core.mindTemporalHeatmap.value, same(frame));
      expect(core.mindBehavioralScore.value, same(score));
      expect(core.mindBehavioralScore.projection, same(scoreProjection));
      expect(core.preparedIndex, same(index));
      expect(core.navigation.state, same(navigation));
      expect(core.currentQuery.scopeFor(LedgerDirection.expense), same(scope));
      expect(repository.prepareCalls, repositoryCalls);
      expect(heatmapPublications, 0);
      expect(scorePublications, 0);
      expect(navigationMutations, 0);
      expect(queryMutations, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'RED MYH-04/05/06/14: the production Mind Year projection shares direction, focus, year and range identity without drag reads',
    () async {
      final rows = <DashboardLedgerEntry>[
        _mindYearEntry(
          id: 'income-utility-jan',
          direction: 'income',
          categoryId: 'utilities',
          partnerId: 'partner-a',
          amount: 100000,
          date: const LocalDate(year: 2025, month: 1, day: 2),
        ),
        _mindYearEntry(
          id: 'income-food-sep',
          direction: 'income',
          categoryId: 'food',
          partnerId: 'partner-b',
          amount: 900000,
          date: const LocalDate(year: 2025, month: 9, day: 2),
        ),
        _mindYearEntry(
          id: 'income-future',
          direction: 'income',
          categoryId: 'utilities',
          partnerId: 'partner-a',
          amount: 500000,
          date: const LocalDate(year: 2026, month: 1, day: 2),
        ),
        _mindYearEntry(
          id: 'expense-utility-dec',
          direction: 'expense',
          categoryId: 'utilities',
          partnerId: 'partner-a',
          amount: 300000,
          date: const LocalDate(year: 2025, month: 12, day: 2),
        ),
      ];
      final repository = _MindFooterRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);

      final beforeFocus = core.mindYearHeatmap.value!;
      expect(beforeFocus.identity.year, 2025);
      expect(
        beforeFocus.dayFor(const LocalDate(year: 2025, month: 1, day: 2)).total,
        100000,
      );
      expect(
        beforeFocus.dayFor(const LocalDate(year: 2025, month: 9, day: 2)).total,
        900000,
      );
      expect(
        beforeFocus
            .dayFor(const LocalDate(year: 2025, month: 12, day: 2))
            .isEmpty,
        isTrue,
      );
      // Month footer aggregates are full calendar-month direction totals,
      // admitted beside the prepared base. They deliberately do not inherit
      // the active Income heatmap filter, focus or slider range.
      expect(beforeFocus.monthlyAggregates.incomeForMonth(1), 100000);
      expect(beforeFocus.monthlyAggregates.expenseForMonth(12), 300000);
      expect(beforeFocus.monthlyAggregates.netForMonth(1), 100000);
      expect(
        beforeFocus.scopedMonthlyAggregates.amountForMonth(1),
        100000,
        reason:
            'the optional inspection scope is derived from the admitted '
            'direction/focus membership, not the whole-month aggregate bank',
      );
      expect(beforeFocus.scopedMonthlyAggregates.amountForMonth(9), 900000);
      final sourceSeed = core.preparedIndex!
          .partitionFor(LedgerDirection.income)
          .focusMembershipSeed!;
      expect(
        sourceSeed
            .select(normalizedSearch: 'partner-b')
            .entryIndices
            .map(sourceSeed.entryAt)
            .map((entry) => entry.id),
        contains('income-food-sep'),
      );

      final sourceCounter = core.mindYearHeatmap.sourceWorkCounter!;
      final sourceTouchesAfterBuild = sourceCounter.sourceRowTouches;
      const highOnly = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 800000,
        upperScaled100: 900000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(highOnly), isTrue);
      final highFrame = core.mindYearHeatmap.value!;
      expect(
        highFrame.dayFor(const LocalDate(year: 2025, month: 1, day: 2)).isEmpty,
        isTrue,
      );
      expect(
        highFrame.dayFor(const LocalDate(year: 2025, month: 9, day: 2)).total,
        900000,
      );
      expect(
        highFrame.monthlyAggregates.incomeForMonth(1),
        beforeFocus.monthlyAggregates.incomeForMonth(1),
        reason: 'the amount preview only changes heatmap membership',
      );
      expect(
        highFrame.monthlyAggregates.expenseForMonth(12),
        beforeFocus.monthlyAggregates.expenseForMonth(12),
        reason: 'the amount preview must not rewrite full monthly closes',
      );
      expect(
        highFrame.scopedMonthlyAggregates.amountForMonth(1),
        100000,
        reason:
            'the scope inspection read model is pre-amount-range and cannot '
            'move with a held range thumb',
      );
      for (var tick = 0; tick < 20; tick += 1) {
        core.previewMindAmountRange(highOnly);
      }
      expect(sourceCounter.sourceRowTouches, sourceTouchesAfterBuild);
      expect(sourceCounter.sourceRowTouchesDuringPreview, 0);
      expect(sourceCounter.repositoryAccessesDuringPreview, 0);
      expect(sourceCounter.indexBuildsDuringPreview, 0);
      expect(sourceCounter.maxDayBucketsVisitedPerPreview, 365);
      expect(repository.prepareCalls, 1);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      final categoryFrame = core.mindYearHeatmap.value!;
      expect(
        categoryFrame.monthlyAggregates.incomeForMonth(9),
        900000,
        reason: 'category focus must recolor cells, never narrow footer sums',
      );
      expect(
        categoryFrame
            .dayFor(const LocalDate(year: 2025, month: 1, day: 2))
            .total,
        100000,
      );
      expect(
        categoryFrame
            .dayFor(const LocalDate(year: 2025, month: 9, day: 2))
            .isEmpty,
        isTrue,
      );
      expect(categoryFrame.scopedMonthlyAggregates.amountForMonth(1), 100000);
      expect(categoryFrame.scopedMonthlyAggregates.amountForMonth(9), 0);
      expect(categoryFrame.inspectionScope.facets, hasLength(1));
      expect(
        categoryFrame.inspectionScope.facets.single.displayName,
        'Utilities',
      );
      expect(
        categoryFrame.inspectionScope.facets.single.kind,
        MindYearHeatmapInspectionFacetKind.category,
      );
      expect(
        await core.requestPartnerFocus(
          const DashboardFocusFacet(id: 'partner-a', displayName: 'Partner A'),
        ),
        isTrue,
      );
      expect(
        core.mindYearHeatmap.value!
            .dayFor(const LocalDate(year: 2025, month: 1, day: 2))
            .total,
        100000,
      );
      expect(
        core.mindYearHeatmap.value!.monthlyAggregates.expenseForMonth(12),
        300000,
        reason: 'partner focus must not narrow the calendar-month close',
      );
      expect(
        core.mindYearHeatmap.value!.scopedMonthlyAggregates.amountForMonth(1),
        100000,
      );
      expect(
        core.mindYearHeatmap.value!.inspectionScope.facets.map(
          (facet) => facet.kind,
        ),
        orderedEquals(<MindYearHeatmapInspectionFacetKind>[
          MindYearHeatmapInspectionFacetKind.category,
          MindYearHeatmapInspectionFacetKind.partner,
        ]),
        reason:
            'The optional inspection row retains both active dimensions; its '
            'single amount is the selected category/partner intersection.',
      );
      expect(
        core.mindYearHeatmap.value!.scopedMonthlyAggregates.amountForMonth(1),
        100000,
        reason:
            'The combined scope remains the prepared intersection, not a sum '
            'of independent category and partner totals.',
      );
      expect(await core.clearAllEphemeralFocus(), isTrue);
      // Current prepared SearchPill semantics cover partner display and note
      // text (not the category facet, which has its own authority).
      expect(await core.updateLiveSearch('partner-b'), isTrue);
      expect(core.focus.state?.normalizedSearch, 'partner-b');
      expect(core.focus.state?.category, isNull);
      expect(core.focus.state?.partner, isNull);
      final searchFrame = core.mindYearHeatmap.value!;
      expect(
        searchFrame
            .dayFor(const LocalDate(year: 2025, month: 1, day: 2))
            .isEmpty,
        isTrue,
      );
      expect(
        searchFrame.dayFor(const LocalDate(year: 2025, month: 9, day: 2)).total,
        900000,
      );
      expect(searchFrame.scopedMonthlyAggregates.amountForMonth(1), 0);
      expect(searchFrame.scopedMonthlyAggregates.amountForMonth(9), 900000);
      expect(
        searchFrame.inspectionScope.facets,
        isEmpty,
        reason:
            'Search narrows heatmap membership but must not invent a '
            'category/vendor inspection identity or tint.',
      );
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RED MYH-04: the annual projection selects the active expense direction',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income',
            direction: 'income',
            categoryId: 'utilities',
            partnerId: 'partner-a',
            amount: 100000,
            date: const LocalDate(year: 2025, month: 1, day: 2),
          ),
          _mindYearEntry(
            id: 'expense',
            direction: 'expense',
            categoryId: 'utilities',
            partnerId: 'partner-a',
            amount: 300000,
            date: const LocalDate(year: 2025, month: 12, day: 2),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(
        core.mindYearHeatmap.value!
            .dayFor(const LocalDate(year: 2025, month: 12, day: 2))
            .total,
        300000,
      );
      expect(
        core.mindYearHeatmap.value!
            .dayFor(const LocalDate(year: 2025, month: 1, day: 2))
            .isEmpty,
        isTrue,
      );
    },
  );

  test(
    'RED MYHR-06: production Core preserves exact disjoint direction day sets and intersects range second',
    () async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-jan-1',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 100000,
            date: const LocalDate(year: 2025, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-jan-8',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 600000,
            date: const LocalDate(year: 2025, month: 1, day: 8),
          ),
          _mindYearEntry(
            id: 'income-mar-3',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 900000,
            date: const LocalDate(year: 2025, month: 3, day: 3),
          ),
          _mindYearEntry(
            id: 'expense-jan-2',
            direction: 'expense',
            categoryId: 'expense-a',
            partnerId: 'expense-partner',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 1, day: 2),
          ),
          _mindYearEntry(
            id: 'expense-feb-4',
            direction: 'expense',
            categoryId: 'expense-a',
            partnerId: 'expense-partner',
            amount: 700000,
            date: const LocalDate(year: 2025, month: 2, day: 4),
          ),
          _mindYearEntry(
            id: 'expense-mar-9',
            direction: 'expense',
            categoryId: 'expense-a',
            partnerId: 'expense-partner',
            amount: 850000,
            date: const LocalDate(year: 2025, month: 3, day: 9),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);

      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await pumpEventQueue(times: 4);
      expect(
        core.mindAmountPreparedBaseCount,
        2,
        reason:
            'Mind retains exactly the canonical Income and Expense immutable '
            'bases, not an unbounded direction/query cache.',
      );
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), <String>{
        '2025-01-01',
        '2025-01-08',
        '2025-03-03',
      });

      core.selectDirection(TransactionDirection.expense);
      await pumpEventQueue(times: 20);
      expect(
        core.presentation.navigation.state.parentQueryScope.direction,
        LedgerDirection.expense,
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), <String>{
        '2025-01-02',
        '2025-02-04',
        '2025-03-09',
      });

      const highExpenseOnly = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 800000,
        upperScaled100: 900000,
      );
      // This assertion belongs to this physical slider interaction only. A
      // preceding Core test may have retained a diagnostic summary in the
      // process-wide ring; clear it instead of accidentally counting it.
      FluviDiagnosticLogger.clear();
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(highExpenseOnly), isTrue);
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), <String>{
        '2025-03-09',
      });
      core.endMindAmountRangeInteraction(committed: false);
      final sliderSummaries = FluviDiagnosticLogger.entries
          .where(
            (event) => event.stage == 'MIND_HEATMAP|SLIDER_PREVIEW_SUMMARY',
          )
          .toList(growable: false);
      expect(sliderSummaries, hasLength(1));
      expect(
        sliderSummaries.single.scope,
        contains('sourceRowsDuringPreview=0'),
      );
      expect(
        sliderSummaries.single.scope,
        contains('repositoryAccessesDuringPreview=0'),
      );
      expect(sliderSummaries.single.scope, isNot(contains('income-partner')));
      expect(sliderSummaries.single.scope, isNot(contains('expense-partner')));
    },
  );

  test(
    'RED DRR-03c: two cold Mind direction bases serialize on the one native index lane',
    () async {
      final firstColdBuild = Completer<void>();
      final repository = _FocusSeedRepository(
        prepareAfterBootstrapGate: firstColdBuild,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      addTearDown(() {
        if (!firstColdBuild.isCompleted) firstColdBuild.complete();
      });
      await core.bootstrap();

      core.currentQuery.apply(
        core.currentQuery
            .scopeFor(LedgerDirection.income)
            .copyWith(
              categoryIds: const <String>{'income-cold'},
              refinements: const <String, Object?>{
                QueryAmountRange.minimumRefinementKey: 100000,
              },
            ),
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 1, amountScaled100: 100),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 100,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      core.currentQuery.apply(
        core.currentQuery
            .scopeFor(LedgerDirection.expense)
            .copyWith(
              categoryIds: const <String>{'expense-cold'},
              refinements: const <String, Object?>{
                QueryAmountRange.minimumRefinementKey: 200000,
              },
            ),
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 1, amountScaled100: 100),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 100,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );

      final activePrime = core.primeMindAmountPreviewDomain();
      await pumpEventQueue(times: 12);
      expect(
        repository.prepareCalls,
        2,
        reason:
            'Only Income may occupy the shared native index lane while its '
            'cold base is held. Starting Expense here cancels the active '
            'builder request.',
      );

      firstColdBuild.complete();
      expect(await activePrime, isTrue);
      await pumpEventQueue(times: 40);
      expect(repository.prepareCalls, 3);
      expect(core.mindAmountPreparedBaseCount, 2);
    },
  );

  test(
    'RED MIND-LIVE-RESOURCE-01: inactive Mind base is not enough for a direction tap',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-ready-row',
              direction: 'income',
              categoryId: 'income-a',
              partnerId: 'income-partner',
              amount: 100000,
              date: const LocalDate(year: 2025, month: 1, day: 1),
            ),
            _mindYearEntry(
              id: 'expense-ready-row',
              direction: 'expense',
              categoryId: 'expense-a',
              partnerId: 'expense-partner',
              amount: 200000,
              date: const LocalDate(year: 2025, month: 1, day: 2),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);

      final preparedDirectionResources =
          <LedgerDirection, DashboardLiveInteractionResourceLane>{};
      final retainedKeys = <String>{};
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              preparedDirectionResources[window.payloads.single.direction] =
                  lane;
              retainedKeys.add(retainedKey);
            },
        hasLiveInteractionResources:
            (_, {required lane, required candidateKey}) =>
                retainedKeys.contains(candidateKey),
      );

      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      await pumpEventQueue(times: 40);

      expect(core.mindAmountPreparedBaseCount, 2);
      expect(
        preparedDirectionResources,
        <LedgerDirection, DashboardLiveInteractionResourceLane>{
          LedgerDirection.income:
              DashboardLiveInteractionResourceLane.mindIncomeAmountPreview,
          LedgerDirection.expense:
              DashboardLiveInteractionResourceLane.mindExpenseAmountPreview,
        },
        reason:
            'A prepared inactive base without its Phase-A paragraph universe '
            'forces the first real direction tap to prepare every row.',
      );
    },
  );

  test(
    'RED MYHR-07: an immediate direction request never leaves an outgoing heatmap identity under new direction state',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-jan-1',
              direction: 'income',
              categoryId: 'income-a',
              partnerId: 'income-partner',
              amount: 100000,
              date: const LocalDate(year: 2025, month: 1, day: 1),
            ),
            _mindYearEntry(
              id: 'expense-jan-2',
              direction: 'expense',
              categoryId: 'expense-a',
              partnerId: 'expense-partner',
              amount: 200000,
              date: const LocalDate(year: 2025, month: 1, day: 2),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);

      expect(
        core.mindYearHeatmap.value!.identity.upstreamScopeKey,
        contains('income'),
      );

      final sceneGate = Completer<void>();
      addTearDown(() {
        if (!sceneGate.isCompleted) sceneGate.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => sceneGate.future,
        activate: (_) {},
      );

      FluviDiagnosticLogger.clear();
      core.selectDirection(TransactionDirection.expense);
      expect(core.transactionDirection.direction, TransactionDirection.expense);
      expect(
        core.mindYearHeatmap.value?.identity.upstreamScopeKey,
        contains('expense'),
        reason:
            'The direct direction owner changes in this interaction turn. The '
            'heatmap identity must change before an unrelated LogBox scene '
            'gate is allowed to resolve.',
      );
      final events = FluviDiagnosticLogger.entries;
      final request = events.singleWhere(
        (event) => event.stage == 'MIND_HEATMAP|DIRECTION_REQUEST',
      );
      final traceStages = events
          .where((event) => event.flowId == request.flowId)
          .map((event) => event.stage)
          .toList(growable: false);
      expect(
        traceStages,
        containsAllInOrder(<String>[
          'MIND_HEATMAP|DIRECTION_REQUEST',
          'MIND_HEATMAP|IDENTITY_RESOLVED',
          'MIND_HEATMAP|PROJECTION_BUILD_STARTED',
          'MIND_HEATMAP|PROJECTION_BUILD_COMPLETED',
          'MIND_HEATMAP|FRAME_SCHEDULED',
          'MIND_HEATMAP|FRAME_PUBLISHED',
        ]),
      );
    },
  );

  test(
    'RED DRR-03: Mind may receive an exact prepared index before optional candidate scene staging completes',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final optionalSceneGate = Completer<void>();
      addTearDown(() {
        if (!optionalSceneGate.isCompleted) optionalSceneGate.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => Future<void>.value(),
        activate: (_) {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) =>
                optionalSceneGate.future,
      );
      final target = core.currentQuery
          .scopeFor(LedgerDirection.income)
          .copyWith(categoryIds: const <String>{'cold-index-target'});
      final indexReady = Completer<PreparedDashboardIndex?>();
      var candidateCompleted = false;
      final candidateFuture = core
          .prepareQueryDraft(
            target,
            onIndexReady: (index) {
              if (!indexReady.isCompleted) indexReady.complete(index);
            },
          )
          .then((_) => candidateCompleted = true);

      await pumpEventQueue(times: 12);
      expect(indexReady.isCompleted, isTrue);
      final index = await indexReady.future;
      expect(index, isNotNull);
      expect(index!.key.matchesScope(target), isTrue);
      expect(
        candidateCompleted,
        isFalse,
        reason:
            'The optional LogBox scene is intentionally held. Its Phase-B '
            'completion must not delay compatible immutable-index readiness.',
      );

      optionalSceneGate.complete();
      await candidateFuture;
    },
  );

  testWidgets(
    'RED MYTP-01: a painted Summary Year must not retain the previous Mind heatmap year',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2026',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 100000,
            date: const LocalDate(year: 2026, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2025',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 2, day: 2),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();
      expect(core.mindYearHeatmap.value!.identity.year, 2026);

      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      final selector = find.byKey(
        const ValueKey<String>('summary-pill-segmented-year-selector'),
      );
      expect(selector, findsOneWidget);
      FluviDiagnosticLogger.clear();
      final gesture = await tester.startGesture(tester.getCenter(selector));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.descendant(of: selector, matching: find.text('2025')),
        findsOneWidget,
        reason: 'The real segmented Summary Year has reached its next paint.',
      );
      expect(
        core.mindYearHeatmap.value!.identity.year,
        2025,
        reason:
            'The accepted, visibly painted Summary year and Mind heatmap '
            'identity must share one visible generation.',
      );
      expect(
        core.mindYearHeatmap.value!.identity.navigationEpoch,
        1,
        reason:
            'The transient Mind frame must carry the accepted Summary flight '
            'generation, not only a matching calendar year.',
      );
      expect(
        repository.prepareCalls,
        1,
        reason: 'Transient Year publication must not query the repository.',
      );
      final transientPublication = FluviDiagnosticLogger.entries.singleWhere(
        (event) =>
            event.stage == 'MIND_HEATMAP|FRAME_PUBLISHED' &&
            (event.scope?.contains('cause=summaryVisualTransientYear') ??
                false),
      );
      expect(
        transientPublication.scope,
        contains('sourceRows=0'),
        reason:
            'The painted transient Year must consume the resident annual '
            'membership, not revisit DashboardLedgerEntry rows.',
      );
      expect(transientPublication.scope, contains('preparedContributions=1'));
      expect(transientPublication.scope, contains('temporalGeneration=1'));

      // The existing amount slider may start while Summary's exact visible
      // Year is still transient. Its held identity must remain that exact
      // Y/G frame rather than silently reconstructing canonical 2026/0.
      final transientIdentity = core.mindYearHeatmap.identity!;
      final heatmapPublicationsBeforeSlider =
          core.mindYearHeatmap.publicationCount;
      FluviDiagnosticLogger.clear();
      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 600000,
            upperScaled100: 900000,
          ),
        ),
        isTrue,
      );
      expect(
        core.mindYearHeatmap.identity,
        transientIdentity,
        reason:
            'A held slider cannot replace the exact visible Summary Y/G with '
            'the older canonical year.',
      );
      expect(
        core.mindYearHeatmap.publicationCount,
        heatmapPublicationsBeforeSlider + 1,
        reason: 'The slider preview must publish against its held Y/G frame.',
      );
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'MIND|PREVIEW_FRAME')
            .scope,
        allOf(
          contains('heatmapPublished=true'),
          contains('repositoryRequests=0 indexBuilds=0 canonicalCommits=0'),
        ),
      );
      expect(repository.prepareCalls, 1);
      expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
      expect(
        core.mindYearHeatmap.sourceWorkCounter!.preparedContributionTouches,
        1,
      );
      core.endMindAmountRangeInteraction(committed: false);

      // CoreDashboard invokes this exact method during an otherwise unrelated
      // Mind parent rebuild. Canonical navigation remains 2026 at this point;
      // it must not overwrite the visibly painted transient 2025/G frame.
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(
        core.mindYearHeatmap.identity,
        transientIdentity,
        reason:
            'A parent refresh cannot regress a Summary-painted heatmap back '
            'to the older canonical Year before settle.',
      );
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      await tester.pump();
      expect(
        core.mindYearHeatmap.identity,
        transientIdentity,
        reason:
            'The real rebuilt CoreDashboard parent must retain the same '
            'Summary-painted Y/G heatmap identity before canonical settle.',
      );
      await tester.pump();
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'MIND_HEATMAP|PAINTED')
            .map((event) => event.scope)
            .join('\n'),
        contains('year=2025'),
        reason:
            'The mounted annual viewport must paint the matching identity on '
            'the render frame immediately following Summary paint.',
      );

      // Coalesce two more unpainted ticks into the terminal Year. The
      // selector-local frame epoch must invalidate the intermediate 2024
      // acknowledgement, so only the actual visible 2023 target publishes.
      FluviDiagnosticLogger.clear();
      await gesture.moveBy(const Offset(0, 60));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.descendant(of: selector, matching: find.text('2023')),
        findsOneWidget,
        reason: 'The terminal rapid Summary Year is the only painted target.',
      );
      expect(core.mindYearHeatmap.value!.identity.year, 2023);
      expect(repository.prepareCalls, 1);
      await tester.pump();
      final rapidPaints = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'MIND_HEATMAP|PAINTED')
          .map((event) => event.scope)
          .join('\n');
      expect(rapidPaints, contains('year=2023'));
      expect(
        rapidPaints,
        isNot(contains('year=2024')),
        reason:
            'A coalesced target that never painted must not enqueue a stale '
            'heatmap frame behind the terminal Summary Year.',
      );
      await gesture.up();
      await tester.pumpAndSettle();

      final settledYear = core.navigation.state.yearCursor;
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(core.mindYearHeatmap.identity!.year, settledYear);
      expect(
        core.mindYearHeatmap.identity!.navigationEpoch,
        0,
        reason:
            'After canonical Summary settlement, its transient G must not '
            'remain a second temporal authority.',
      );

      await core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      final programmaticYear = core.navigation.state.yearCursor;
      expect(programmaticYear, isNot(settledYear));
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(
        core.mindYearHeatmap.identity!.year,
        programmaticYear,
        reason:
            'A later non-segmented Year producer must replace the settled '
            'Summary target rather than retaining its old Y/G heatmap.',
      );
    },
  );

  testWidgets(
    'RED MYRL-01: a final canonical Year settle cannot resurrect a retained older transient heatmap Year',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2025',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 100000,
            date: const LocalDate(year: 2025, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2026',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 200000,
            date: const LocalDate(year: 2026, month: 1, day: 1),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();
      expect(core.mindYearHeatmap.identity!.year, 2026);

      // Mount the actual segmented Summary owner. The following calls are the
      // exact Core callbacks that this mounted production parent invokes for
      // accepted components, painted LogBox frames, renderer acknowledgement
      // and terminal settle; no parallel temporal/heatmap implementation is
      // introduced by the test.
      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('summary-pill-segmented-year-selector'),
        ),
        findsOneWidget,
      );

      final origin = core.navigation.state;
      core.beginSegmentedSummaryMotion();
      final retained2027 = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.year,
        isRailOpen: origin.isRailOpen,
        component: DashboardTemporalAnchorComponent.year,
        offset: 1,
        base: origin,
      )!;
      expect(retained2027.yearCursor, 2027);
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: retained2027,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );
      core.noteSegmentedSummaryComponentVisualTargetPainted(
        candidate: retained2027,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();
      expect(core.mindYearHeatmap.identity!.year, 2027);
      expect(core.mindYearHeatmap.identity!.navigationEpoch, 1);

      // A new Summary interaction settles a distinct 2025 target. Its
      // canonical commit must revoke the old renderer-acknowledged 2027
      // authority even though the two target objects cannot be identical.
      core.beginSegmentedSummaryMotion();
      final final2025 = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.year,
        isRailOpen: origin.isRailOpen,
        component: DashboardTemporalAnchorComponent.year,
        offset: -1,
        base: origin,
      )!;
      expect(final2025.yearCursor, 2025);
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: final2025,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );
      core.settleExperimentalTemporalComponentCandidate(
        candidate: final2025,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();
      expect(core.navigation.state.yearCursor, 2025);

      // This is the Core refresh entry point used by the graph-verified
      // focus, direction and presentation callers. On the unmodified parent
      // it wrongly reselects retained 2027 under
      // summaryVisualTransientYearRetained after the final 2025 settle.
      FluviDiagnosticLogger.clear();
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      final actual = core.mindYearHeatmap.identity!;
      expect(
        actual.year,
        2025,
        reason:
            'A later refresh must retain final canonical/presented 2025, not '
            'resurrect the obsolete renderer-acknowledged 2027. Diagnostics: '
            '${FluviDiagnosticLogger.entries.map((event) => '${event.stage}:${event.scope}').join(' | ')}',
      );
      expect(actual.navigationEpoch, 0);
      expect(
        FluviDiagnosticLogger.entries
            .where(
              (event) =>
                  event.stage == 'MIND_HEATMAP|FRAME_PUBLISHED' &&
                  (event.scope?.contains(
                        'cause=summaryVisualTransientYearRetained',
                      ) ??
                      false),
            )
            .map((event) => event.scope)
            .join('\n'),
        isEmpty,
        reason: 'A settled canonical Year may not retain a prior transient.',
      );
    },
  );

  testWidgets(
    'RED SCA-01: a Summary-painted transient Year publishes the matching Mind score in the same semantic admission',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2026',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 100000,
            date: const LocalDate(year: 2026, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2025',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 2, day: 2),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(core.ensureMindBehavioralScoreProjection(), isTrue);
      await tester.pump();
      expect(
        core.mindBehavioralScore.identity?.targetEpochDay,
        const LocalDate(year: 2026, month: 1, day: 1).epochDay,
      );

      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      final selector = find.byKey(
        const ValueKey<String>('summary-pill-segmented-year-selector'),
      );
      expect(selector, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(selector));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.descendant(of: selector, matching: find.text('2025')),
        findsOneWidget,
        reason: 'The Summary target is a real painted transient Year.',
      );
      expect(core.mindYearHeatmap.identity?.year, 2025);
      expect(
        core.mindBehavioralScore.identity?.targetEpochDay,
        const LocalDate(year: 2025, month: 2, day: 2).epochDay,
        reason:
            'The same accepted transient target must publish score text/chart '
            'provenance before canonical Year settlement. Diagnostics: '
            '${FluviDiagnosticLogger.entries.map((event) => '${event.stage}:${event.scope}').join(' | ')}',
      );
      expect(
        core.mindBehavioralScore.identity?.navigationEpoch,
        core.mindYearHeatmap.identity?.navigationEpoch,
        reason: 'Heatmap and score must carry one accepted Summary generation.',
      );
      await gesture.up();
    },
  );

  testWidgets(
    'MYRT-01/LIV-03: each painted Summary Year reaches matching Mind heatmap and Header score by the next frame',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2026',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 100000,
            date: const LocalDate(year: 2026, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2025',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 200000,
            date: const LocalDate(year: 2025, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2024',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 300000,
            date: const LocalDate(year: 2024, month: 1, day: 1),
          ),
          _mindYearEntry(
            id: 'income-2023',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 400000,
            date: const LocalDate(year: 2023, month: 1, day: 1),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();

      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      final selector = find.byKey(
        const ValueKey<String>('summary-pill-segmented-year-selector'),
      );
      expect(selector, findsOneWidget);
      FluviDiagnosticLogger.clear();
      final observedPaintedYears = <int>[];

      Future<void> expectVisibleYearAndMindFrame(int year) async {
        expect(
          find.descendant(of: selector, matching: find.text('$year')),
          findsOneWidget,
          reason: 'Summary Year $year must be an actual mounted paint target.',
        );
        expect(
          FluviDiagnosticLogger.entries.any(
            (event) =>
                event.stage == 'SUMMARY_TARGET_PAINTED' &&
                (event.queryKey?.contains('year:$year') ?? false),
          ),
          isTrue,
          reason:
              'The contract applies only after Summary has actually painted $year.',
        );
        final identity = core.mindYearHeatmap.identity;
        expect(identity?.year, year);
        expect(identity?.navigationEpoch, 1);
        expect(
          core.mindBehavioralScore.identity?.targetEpochDay,
          LocalDate(year: year, month: 1, day: 1).epochDay,
          reason:
              'The renderer-accepted transient Year must not paint its '
              'heatmap while the Header still names an older score point.',
        );
        expect(
          core.mindBehavioralScore.identity?.navigationEpoch,
          identity?.navigationEpoch,
          reason:
              'The transient heatmap and Header score must retain the same '
              'accepted Summary generation.',
        );
        expect(
          core.mindBehavioralScore.value?.chartSeries?.points.last,
          core.mindBehavioralScore.value?.point,
          reason:
              'The visible Header text and chart endpoint share one score '
              'frame for every transient Year target.',
        );
        expect(
          core.navigation.state.yearCursor,
          2026,
          reason:
              'A transient Mind Year must not apply canonical navigation/query '
              'state before its terminal settle.',
        );
        final preparedPublication = FluviDiagnosticLogger.entries.lastWhere(
          (event) =>
              event.stage == 'SUMMARY_COMPONENT_PREPARED_PUBLICATION' &&
              (event.queryKey?.contains('year:$year') ?? false),
        );
        expect(
          preparedPublication.scope,
          contains('repositoryCalls=0 indexBuilds=0 scenePrepares=0'),
        );
        final heatmapPublication = FluviDiagnosticLogger.entries.lastWhere(
          (event) =>
              event.stage == 'MIND_HEATMAP|FRAME_PUBLISHED' &&
              (event.scope?.contains('year=$year ') ?? false) &&
              (event.scope?.contains('cause=summaryVisualTransientYear') ??
                  false),
        );
        expect(heatmapPublication.scope, contains('sourceRows=0'));
        expect(heatmapPublication.scope, contains('preparedContributions=1'));

        bool hasMatchingHeatmapPaint() => FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_HEATMAP|PAINTED' &&
              (event.scope?.contains('year=$year ') ?? false) &&
              (event.scope?.contains('temporalGeneration=1') ?? false),
        );

        // The viewport may have already painted in this same transition. If
        // not, exactly one subsequent render frame is the complete allowed
        // budget; pumping until idle would hide a lagging publication.
        if (!hasMatchingHeatmapPaint()) {
          await tester.pump();
        }
        expect(
          hasMatchingHeatmapPaint(),
          isTrue,
          reason:
              'Mind must paint Summary Year $year in the same or next frame.',
        );
        observedPaintedYears.add(year);
        expect(repository.prepareCalls, 1);
        expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
      }

      final gesture = await tester.startGesture(tester.getCenter(selector));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      await expectVisibleYearAndMindFrame(2025);

      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      await expectVisibleYearAndMindFrame(2024);

      await gesture.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      await expectVisibleYearAndMindFrame(2023);

      // The held slider is allowed to refine only the exact last visible
      // transient identity. It must not reconstruct canonical 2026 or defer
      // its own frame until Summary settles.
      final heldTransientIdentity = core.mindYearHeatmap.identity!;
      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 900000,
            lowerScaled100: 100000,
            upperScaled100: 900000,
          ),
        ),
        isTrue,
      );
      expect(core.mindYearHeatmap.identity, heldTransientIdentity);
      expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
      expect(repository.prepareCalls, 1);
      core.endMindAmountRangeInteraction(committed: false);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_HEATMAP|PAINTED' &&
              (event.scope?.contains('year=2023 ') ?? false) &&
              (event.scope?.contains('temporalGeneration=0') ?? false),
        ),
        isTrue,
        reason:
            'Terminal canonical 2023 must itself reach an actual annual paint.',
      );

      expect(
        observedPaintedYears,
        const <int>[2025, 2024, 2023],
        reason:
            'Every visible target must paint through the existing transient path.',
      );
      expect(repository.prepareCalls, 1);

      // A real terminal settle and a later Core refresh must retire only the
      // transient authority, never the visible final Year.
      expect(core.navigation.state.yearCursor, 2023);
      FluviDiagnosticLogger.clear();
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      expect(core.mindYearHeatmap.identity!.year, 2023);
      expect(core.mindYearHeatmap.identity!.navigationEpoch, 0);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_HEATMAP|FRAME_PUBLISHED' &&
              (event.scope?.contains(
                    'cause=summaryVisualTransientYearRetained',
                  ) ??
                  false),
        ),
        isFalse,
        reason: 'A later refresh may not restore obsolete transient authority.',
      );
    },
  );

  testWidgets(
    'MYRT-02/LIV-03: a real ballistic Year fling keeps every painted Mind Year and Header score current',
    (tester) async {
      final repository = _FocusSeedRepository(
        rows: <DashboardLedgerEntry>[
          for (final year in <int>[2020, 2021, 2022, 2023, 2024, 2025, 2026])
            _mindYearEntry(
              id: 'income-$year',
              direction: 'income',
              categoryId: 'income-a',
              partnerId: 'income-partner',
              amount: 100000,
              date: LocalDate(year: year, month: 1, day: 1),
            ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();
      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      final selector = find.byKey(
        const ValueKey<String>('summary-pill-segmented-year-selector'),
      );
      expect(selector, findsOneWidget);
      FluviDiagnosticLogger.clear();

      // Keep the pointer sequence itself frame-free. Only the subsequent
      // physical ballistic frames are visible, so this test can make the
      // same-frame/next-frame assertion without silently treating a target
      // painted during WidgetTester.fling's input synthesis as "eventually"
      // correct.
      await tester.fling(
        selector,
        const Offset(0, 180),
        1500,
        frameInterval: const Duration(days: 1),
      );
      final seenSummaryPaintSequences = <int>{};
      final seenHeatmapPaintSequences = <int>{};
      final summaryPaintedYears = <int>[];
      final summaryPaintedYearSet = <int>{};
      final pendingSummaryPaints = <int>[];
      final pendingSummaryScorePublications = <int>[];
      bool hasMatchingScorePublication(int year) {
        // The fixture contains Jan 1 contributions only for 2020..2026.
        // An actually painted empty Summary Year still owes one score frame;
        // the score contract resolves that no-activity target to the selected
        // Year end rather than fabricating a Jan 1 transaction point.
        final targetEpochDay = LocalDate(
          year: year,
          month: year >= 2020 && year <= 2026 ? 1 : 12,
          day: year >= 2020 && year <= 2026 ? 1 : 31,
        ).epochDay;
        return FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_SCORE|ACCEPTED_TEMPORAL_TARGET_PUBLISHED' &&
              (event.scope?.contains('targetEpochDay=$targetEpochDay ') ??
                  false) &&
              (event.scope?.contains('temporalGeneration=1') ?? false),
        );
      }

      for (var frame = 0; frame < 80; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final newlyPaintedSummary = FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SUMMARY_TARGET_PAINTED' &&
              event.sequence != null &&
              seenSummaryPaintSequences.add(event.sequence!),
        );
        final currentFrameSummaryYears = <int>[];
        for (final event in newlyPaintedSummary) {
          final year = int.tryParse(
            RegExp(r'year:(\d+)').firstMatch(event.queryKey ?? '')?.group(1) ??
                '',
          );
          expect(
            year,
            isNotNull,
            reason:
                'A Summary paint must carry a parseable Year identity. '
                'event=${event.queryKey}:${event.scope}',
          );
          currentFrameSummaryYears.add(year!);
          summaryPaintedYears.add(year);
          summaryPaintedYearSet.add(year);
        }
        final currentFrameHeatmapYears = <int>{};
        for (final event in FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'MIND_HEATMAP|PAINTED' &&
              event.sequence != null &&
              seenHeatmapPaintSequences.add(event.sequence!),
        )) {
          final year = int.tryParse(
            RegExp(r'year=(\d+)').firstMatch(event.scope ?? '')?.group(1) ?? '',
          );
          if (year != null &&
              (event.scope?.contains('temporalGeneration=1') ?? false)) {
            final expectedColoredDays = year >= 2020 && year <= 2026 ? 1 : 0;
            expect(
              event.scope,
              contains('coloredDays=$expectedColoredDays'),
              reason:
                  'A ballistic Summary Year must paint the exact populated '
                  'or empty annual payload, not merely a matching identity.',
            );
            expect(
              summaryPaintedYearSet,
              contains(year),
              reason:
                  'A ballistic Mind paint may not resurrect a coalesced or '
                  'otherwise unpainted Summary Year $year.',
            );
            currentFrameHeatmapYears.add(year);
          }
        }
        // A real Summary paint may wait for only this frame or the one after
        // it. Anything later is visible lag, rather than a coalesced target.
        for (final year in pendingSummaryPaints) {
          expect(
            currentFrameHeatmapYears,
            contains(year),
            reason:
                'Ballistic Summary Year $year must reach actual Mind paint '
                'by the immediately following frame.',
          );
        }
        for (final year in pendingSummaryScorePublications) {
          expect(
            hasMatchingScorePublication(year),
            isTrue,
            reason:
                'Ballistic Summary Year $year must publish its matching '
                'Header score by the immediately following frame.',
          );
        }
        pendingSummaryPaints
          ..clear()
          ..addAll(
            currentFrameSummaryYears.where(
              (year) => !currentFrameHeatmapYears.contains(year),
            ),
          );
        pendingSummaryScorePublications
          ..clear()
          ..addAll(
            currentFrameSummaryYears.where(
              (year) => !hasMatchingScorePublication(year),
            ),
          );
      }
      expect(summaryPaintedYears, isNotEmpty);
      expect(
        pendingSummaryPaints,
        isEmpty,
        reason:
            'The final ballistic Summary paint must not outlive Mind paint.',
      );
      expect(
        pendingSummaryScorePublications,
        isEmpty,
        reason:
            'The final ballistic Summary paint must not outlive its Header '
            'score publication.',
      );
      expect(repository.prepareCalls, 1);
      expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
    },
  );

  testWidgets(
    'RED MYPL-01: a populated Year cannot leave actual list rows ahead of gray Mind MonthCards',
    (tester) async {
      final repository = _FocusSeedRepository(
        withPreparedYearRows: true,
        rows: <DashboardLedgerEntry>[
          _mindYearEntry(
            id: 'income-2026-jan',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 101000,
            date: const LocalDate(year: 2026, month: 1, day: 4),
          ),
          _mindYearEntry(
            id: 'income-2026-feb',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 202000,
            date: const LocalDate(year: 2026, month: 2, day: 18),
          ),
          _mindYearEntry(
            id: 'income-2026-dec',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 303000,
            date: const LocalDate(year: 2026, month: 12, day: 29),
          ),
          _mindYearEntry(
            id: 'income-2025-jan',
            direction: 'income',
            categoryId: 'income-a',
            partnerId: 'income-partner',
            amount: 404000,
            date: const LocalDate(year: 2025, month: 1, day: 8),
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      _installMindAmountDomain(core, LedgerDirection.income);
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();

      tester
          .widget<DashboardHeaderVisualTuner>(
            find.byType(DashboardHeaderVisualTuner),
          )
          .summaryPillVariants!
          .select(SummaryPillVariant.segmented);
      await tester.pump();
      final selector = find.byKey(
        const ValueKey<String>('summary-pill-segmented-year-selector'),
      );
      expect(selector, findsOneWidget);

      // Establish the working empty path through the actual selector first.
      // It is setup only; the assertion below never waits for the populated
      // target to settle or for an asynchronous source to become ready.
      final toEmpty = await tester.startGesture(tester.getCenter(selector));
      await toEmpty.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
      await toEmpty.moveBy(const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        core.mindYearHeatmap.identity?.year,
        2027,
        reason:
            'The empty 2027 control target is already admitted by the same '
            'real selector path; the populated 2026 leg below is the '
            'liveness differential under test.',
      );
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), isEmpty);
      await tester.pump();
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_HEATMAP|PAINTED' &&
              (event.scope?.contains('year=2027 ') ?? false) &&
              (event.scope?.contains('coloredDays=0') ?? false),
        ),
        isTrue,
      );
      await toEmpty.up();
      await tester.pumpAndSettle();
      expect(core.navigation.state.yearCursor, 2027);
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), isEmpty);

      FluviDiagnosticLogger.clear();
      final toPopulated = await tester.startGesture(tester.getCenter(selector));
      await toPopulated.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
      await toPopulated.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));

      bool summaryAndListPainted2026() {
        final summaryPainted = FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'SUMMARY_TARGET_PAINTED' &&
              (event.queryKey?.contains('year:2026') ?? false) &&
              (event.scope?.contains('exactEmpty=false') ?? false),
        );
        final listRowsBound = FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'LOGBOX|VISIBLE_ROWS_BOUND' &&
              (event.scope?.contains('payloadDirection=income') ?? false) &&
              (event.scope?.contains('actualVisibleRowCount=') ?? false) &&
              !(event.scope?.contains('actualVisibleRowCount=0') ?? true),
        );
        return summaryPainted && listRowsBound;
      }

      // A Summary/list Year is a paint fact.  A single extra frame is the
      // complete allowed heatmap budget; pumping until idle would hide the
      // physical liveness defect.
      expect(
        summaryAndListPainted2026(),
        isTrue,
        reason: FluviDiagnosticLogger.entries
            .map((event) => '${event.stage} ${event.queryKey} ${event.scope}')
            .join('\n'),
      );
      expect(
        core.visibleFrames.countLane.value!.count.entryCount,
        42,
        reason:
            'The compact heatmap must follow the same accepted 2026 Phase-A '
            'package as the visible 42-row transaction surface, not an '
            'independent late data acquisition path.',
      );
      const expected2026 = <String>{'2026-01-04', '2026-02-18', '2026-12-29'};
      final heatmapYearAtSummaryPaint = core.mindYearHeatmap.identity?.year;
      final heatmapDaysAtSummaryPaint = _coloredHeatmapDates(
        core.mindYearHeatmap.value!,
      );
      await tester.pump();
      expect(
        core.mindYearHeatmap.identity?.year,
        2026,
        reason: FluviDiagnosticLogger.entries
            .map((event) => '${event.stage} ${event.queryKey} ${event.scope}')
            .join('\n'),
      );
      expect(
        _coloredHeatmapDates(core.mindYearHeatmap.value!),
        expected2026,
        reason:
            'A populated Summary/list target may consume at most the next '
            'render frame before its actual Mind MonthCards are data-bearing; '
            'it was $heatmapYearAtSummaryPaint with '
            '$heatmapDaysAtSummaryPaint at Summary/list paint.',
      );
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'MIND_HEATMAP|PAINTED' &&
              (event.scope?.contains('year=2026 ') ?? false) &&
              (event.scope?.contains('coloredDays=3') ?? false),
        ),
        isTrue,
      );
      expect(repository.prepareCalls, 1);
      expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
      await toPopulated.up();
      await tester.pumpAndSettle();

      // Exercise the physical recurrence shape without using settlement as a
      // correctness oracle: each empty and populated target is asserted
      // before its release.  Settlement below merely returns the real
      // selector to a deterministic origin for the next direct interaction.
      for (var cycle = 0; cycle < 3; cycle += 1) {
        FluviDiagnosticLogger.clear();
        final emptyAgain = await tester.startGesture(
          tester.getCenter(selector),
        );
        await emptyAgain.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
        await emptyAgain.moveBy(const Offset(0, -60));
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          core.mindYearHeatmap.identity?.year,
          2027,
          reason: 'cycle=$cycle: an empty direct target must be exact.',
        );
        expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), isEmpty);
        await emptyAgain.up();
        await tester.pumpAndSettle();

        FluviDiagnosticLogger.clear();
        final populatedAgain = await tester.startGesture(
          tester.getCenter(selector),
        );
        await populatedAgain.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
        await populatedAgain.moveBy(const Offset(0, 60));
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          summaryAndListPainted2026(),
          isTrue,
          reason:
              'cycle=$cycle: the exact 2026 list target must not outlive a '
              'gray or prior-Year heatmap frame.',
        );
        await tester.pump();
        expect(core.mindYearHeatmap.identity?.year, 2026);
        expect(
          _coloredHeatmapDates(core.mindYearHeatmap.value!),
          expected2026,
          reason:
              'cycle=$cycle: a populated Year must retain its exact colored '
              'days after repeated direct Year changes.',
        );
        expect(
          FluviDiagnosticLogger.entries.any(
            (event) =>
                event.stage == 'MIND_HEATMAP|PAINTED' &&
                (event.scope?.contains('year=2026 ') ?? false) &&
                (event.scope?.contains('coloredDays=3') ?? false),
          ),
          isTrue,
        );
        await populatedAgain.up();
        await tester.pumpAndSettle();
      }
      expect(repository.prepareCalls, 1);
      expect(core.mindYearHeatmap.sourceWorkCounter!.sourceRowTouches, 0);
    },
  );

  testWidgets(
    'RED MYHR-08: the mounted production parent exposes no blank or stale direction heatmap frame',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          rows: <DashboardLedgerEntry>[
            _mindYearEntry(
              id: 'income-jan-1',
              direction: 'income',
              categoryId: 'income-a',
              partnerId: 'income-partner',
              amount: 100000,
              date: const LocalDate(year: 2025, month: 1, day: 1),
            ),
            _mindYearEntry(
              id: 'income-jan-8',
              direction: 'income',
              categoryId: 'income-a',
              partnerId: 'income-partner',
              amount: 600000,
              date: const LocalDate(year: 2025, month: 1, day: 8),
            ),
            _mindYearEntry(
              id: 'expense-jan-2',
              direction: 'expense',
              categoryId: 'expense-a',
              partnerId: 'expense-partner',
              amount: 200000,
              date: const LocalDate(year: 2025, month: 1, day: 2),
            ),
            _mindYearEntry(
              id: 'expense-feb-4',
              direction: 'expense',
              categoryId: 'expense-a',
              partnerId: 'expense-partner',
              amount: 700000,
              date: const LocalDate(year: 2025, month: 2, day: 4),
            ),
          ],
        ),
        initialDate: DateTime.utc(2025, 7, 1),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final modes = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      addTearDown(core.dispose);
      addTearDown(modes.dispose);
      await core.bootstrap();

      await pumpDashboardSurface(
        tester,
        CoreDashboard(
          controller: core,
          modeController: modes,
          categoryCollection: emptyTestCategoryCollection,
        ),
      );
      // CoreDashboard first binds its real LogBox surface/cache. The production
      // Mind range ownership may then prime its resident data without asking a
      // scene cache to prepare before that normal layout exists.
      await tester.pump();
      _installMindAmountDomain(core, LedgerDirection.income);
      _installMindAmountDomain(core, LedgerDirection.expense);
      expect(core.ensureMindYearHeatmapProjection(), isTrue);
      await tester.pump();

      void expectFrameFor(TransactionDirection direction) {
        final expectedLabel = direction == TransactionDirection.income
            ? 'Bevétel'
            : 'Kiadás';
        expect(core.transactionDirection.direction, direction);
        expect(
          tester
              .widget<Semantics>(
                find.byKey(const ValueKey('dashboard-action-row')),
              )
              .properties
              .label,
          expectedLabel,
        );
        final frame = core.mindYearHeatmap.value;
        expect(
          frame,
          isNotNull,
          reason: 'A visible direction may not flash null.',
        );
        expect(
          frame!.identity.upstreamScopeKey,
          contains(direction.name),
          reason:
              'Visible direction chrome and the mounted heatmap must share '
              'the exact directional identity in every pumped frame.',
        );
      }

      expectFrameFor(TransactionDirection.income);
      await tester.tap(find.text('Kiadás').first);
      for (var frame = 0; frame < 3; frame += 1) {
        await tester.pump();
        expectFrameFor(TransactionDirection.expense);
      }
      expect(_coloredHeatmapDates(core.mindYearHeatmap.value!), <String>{
        '2025-01-02',
        '2025-02-04',
      });

      for (final direction in <TransactionDirection>[
        TransactionDirection.income,
        TransactionDirection.expense,
        TransactionDirection.income,
        TransactionDirection.expense,
      ]) {
        await tester.tap(
          find
              .text(
                direction == TransactionDirection.income ? 'Bevétel' : 'Kiadás',
              )
              .first,
        );
        await tester.pump();
        expectFrameFor(direction);
      }
      expectFrameFor(TransactionDirection.expense);
    },
  );

  test(
    'RED b166 Phase-A Mind preview publishes exact rows when the rich stager is unavailable',
    () async {
      final rows = <DashboardLedgerEntry>[
        for (final (index, amount) in <int>[100000, 200000, 300000].indexed)
          DashboardLedgerEntry(
            id: 'amount-$amount',
            partnerId: 'partner-$index',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: amount,
            bookedLocalEpochDay: 20636 - index,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Partner $index',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
      ];
      final repository = _FocusSeedRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 600000,
          ),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 100000,
            maximumAmountScaled100: 300000,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      // This test covers the Phase-A preview after its immutable base has
      // been admitted.  A drag tick deliberately fails closed before this
      // idle prewarm; see RED MYHP-15 for that cold-path contract.
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        stageLiveInteractionFromPreparedResources:
            (_, {required retainViewportId}) => false,
      );

      core.beginMindAmountRangeInteraction();

      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 300000,
            lowerScaled100: 150000,
            upperScaled100: 250000,
          ),
        ),
        isTrue,
        reason:
            'The resident exact amount frame is Phase A. A rich scene miss may '
            'be recorded, but it cannot suppress the held-drag list preview.',
      );
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
      );
      expect(core.visibleFrames.countLane.value!.count.entryCount, 1);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RED: Mind canonical apply keeps exact amount rows when optional candidate-scene retention is unavailable',
    () async {
      final rows = <DashboardLedgerEntry>[
        for (final (index, amount) in <int>[100000, 200000, 300000].indexed)
          DashboardLedgerEntry(
            id: 'amount-$amount',
            partnerId: 'partner-$index',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: amount,
            bookedLocalEpochDay: 20636 - index,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Partner $index',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
      ];
      final repository = _FocusSeedRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      const domain = QueryMenuAmountDomain(
        minimumAmountScaled100: 100000,
        maximumAmountScaled100: 300000,
      );
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 600000,
          ),
          amountDomain: domain,
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareCandidate:
            (_, {required candidateKey, required retainViewportId}) async {},
        hasCandidate: (_, {required candidateKey}) => false,
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      const values = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 300000,
        lowerScaled100: 150000,
        upperScaled100: 250000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(values), isTrue);
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
      );

      FluviDiagnosticLogger.clear();

      expect(
        await core.commitMindAmountRange(values),
        isTrue,
        reason:
            'An optional candidate-bank miss must not invalidate the exact '
            'already-published Phase-A Mind query.',
      );
      final committed = core.currentQuery.scopeFor(LedgerDirection.income);
      expect(committed.refinements, <String, Object?>{
        'minimumAmountScaled100': 150000,
        'maximumAmountScaled100': 250000,
      });
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
        reason:
            'The exact held preview remains visible while rich Phase-B is '
            'unavailable.',
      );
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('QUERY_CANDIDATE_SCENE_RETENTION_REJECTED'),
      );

      core.beginMindAmountRangeInteraction();
      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 300000,
            lowerScaled100: 100000,
            upperScaled100: 250000,
          ),
        ),
        isTrue,
        reason: 'The next physical Mind drag remains immediately reentrant.',
      );
    },
  );

  test(
    'RED b166 Phase-A Avatar focus publishes the selected rows when rich staging misses',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        stageLiveInteractionFromPreparedResources:
            (_, {required retainViewportId}) => false,
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);

      core.beginBudgetAvatarMotion();
      expect(
        await drilldown.previewBudgetTarget(
          state: _budgetAvatarPreviewState(
            categoryId: 'food',
            displayName: 'Food',
          ),
        ),
        isTrue,
        reason:
            'Avatar semantic selection/list publication must not wait for the '
            'optional rich LogBox scene.',
      );
      expect(core.focus.state?.category?.id, 'food');
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        const <String>['food-row'],
      );
      expect(core.visibleFrames.countLane.value!.count.entryCount, 1);
      expect(repository.prepareCalls, 1);
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RED AVATAR COLD REPLAY: a real painter-resource completion promotes the latest pending target before settle',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();
      final basePayload = core.visibleFrames.logBoxLane.value!.logBox;
      final baseWindow = DashboardLogBoxSceneWindow(
        identity: 'cold-avatar-production-parent-base',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
      cache.activateWindow(baseWindow);

      final resourcePreparationStarted = Completer<void>();
      final releaseResourcePreparation = Completer<void>();
      final resourcePreparationCompleted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              final isBudgetAvatarResource =
                  lane ==
                  DashboardLiveInteractionResourceLane.budgetAvatarPreview;
              if (isBudgetAvatarResource &&
                  !resourcePreparationStarted.isCompleted) {
                resourcePreparationStarted.complete();
              }
              await releaseResourcePreparation.future;
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
              );
              if (isBudgetAvatarResource &&
                  !resourcePreparationCompleted.isCompleted) {
                resourcePreparationCompleted.complete();
              }
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );

      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: _focusBudgetSnapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );
      expect(foodHandle, greaterThan(0));

      // This is the production resource lane, deliberately held before it
      // becomes cache-visible. The exact target itself is already derivable.
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      await resourcePreparationStarted.future;
      core.beginBudgetAvatarMotion();
      final preview = drilldown.previewBudgetTarget(targetHandle: foodHandle);
      var previewCompleted = false;
      preview.whenComplete(() => previewCompleted = true);
      await pumpEventQueue();

      expect(
        previewCompleted,
        isFalse,
        reason:
            'A cold exact target must remain as one latest pending candidate; '
            'the current 5ba gate instead rejects and permanently forgets it.',
      );
      expect(core.focus.state, isNull);
      expect(budget.value.selectedHandle, 0);

      releaseResourcePreparation.complete();
      await resourcePreparationCompleted.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw StateError(
          'The existing bounded resource preparation never completed.',
        ),
      );
      expect(
        await preview.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'The current pending Avatar candidate was not replayed after '
            'the existing resource-completion event. Recent diagnostics: '
            '${FluviDiagnosticLogger.entries.map((event) => '${event.stage}[${event.scope}]').join(' | ')}',
          ),
        ),
        isTrue,
      );

      final frame = core.visibleFrames.logBoxLane.value!;
      expect(core.focus.state?.category?.id, 'food');
      expect(budget.value.selectedHandle, foodHandle);
      expect(budget.value.liveSelection.target.handle, foodHandle);
      expect(budget.value.header.target.handle, foodHandle);
      expect(budget.value.header.title, 'Food');
      expect(budget.value.selectedLimitVisual.targetHandle, foodHandle);
      expect(frame.scope.categoryIds, <String>{'food'});
      expect(cache.hasCompleteReadablePhaseAFor(frame.logBox), isTrue);
      expect(cache.readablePhaseARowCountFor(frame.logBox), greaterThan(0));
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(frame));
      expect(core.budgetAvatarTargetPainted.value?.targetHandle, foodHandle);

      final utilitiesHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'utilities',
      );
      expect(utilitiesHandle, greaterThan(0));
      // A complete exact cache resource is sufficient. The aggregate hotset
      // status may still be false while unrelated neighbours prepare, but it
      // must not block this warm exact target.
      core.budgetAvatarLiveRootReady.value = false;
      expect(
        await drilldown.previewBudgetTarget(targetHandle: utilitiesHandle),
        isTrue,
      );
      expect(core.focus.state?.category?.id, 'utilities');
      expect(budget.value.selectedHandle, utilitiesHandle);
      expect(budget.value.header.target.handle, utilitiesHandle);
      expect(budget.value.header.title, 'Utilities');
      expect(budget.value.selectedLimitVisual.targetHandle, utilitiesHandle);
      expect(core.visibleFrames.logBoxLane.value!.scope.categoryIds, <String>{
        'utilities',
      });
      expect(await drilldown.previewBudgetTarget(targetHandle: 0), isTrue);
      expect(core.focus.state, isNull);
      expect(budget.value.selectedHandle, 0);
      expect(budget.value.header.target.handle, 0);
      expect(budget.value.selectedLimitVisual.targetHandle, 0);
      expect(core.visibleFrames.logBoxLane.value!.scope.categoryIds, isEmpty);
      expect(repository.prepareCalls, 1);
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RED AVATAR COLD REPLAY: a newer cold target coalesces the older candidate and preserves its own input order',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();
      final baseWindow = DashboardLogBoxSceneWindow(
        identity: 'cold-avatar-latest-wins-base',
        payloads: <DashboardLogViewportState>[
          core.visibleFrames.logBoxLane.value!.logBox,
        ],
      );
      await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
      cache.activateWindow(baseWindow);

      final budgetResourceStarted = Completer<void>();
      final releaseBudgetResource = Completer<void>();
      final budgetResourceCompleted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              final isBudgetAvatarResource =
                  lane ==
                  DashboardLiveInteractionResourceLane.budgetAvatarPreview;
              if (isBudgetAvatarResource &&
                  !budgetResourceStarted.isCompleted) {
                budgetResourceStarted.complete();
              }
              await releaseBudgetResource.future;
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
              );
              if (isBudgetAvatarResource &&
                  !budgetResourceCompleted.isCompleted) {
                budgetResourceCompleted.complete();
              }
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      await budgetResourceStarted.future;
      core.beginBudgetAvatarMotion();

      final older = core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        publishDuringMotion: true,
        targetHandle: 1,
      );
      await pumpEventQueue();
      final latest = core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'food', displayName: 'Food'),
        publishDuringMotion: true,
        targetHandle: 2,
      );
      expect(
        await older.timeout(const Duration(seconds: 3)),
        isFalse,
        reason:
            'A superseded cold candidate must terminate rather than later '
            'replaying over the newest intent.',
      );
      expect(core.focus.state, isNull);

      releaseBudgetResource.complete();
      await budgetResourceCompleted.future.timeout(const Duration(seconds: 3));
      expect(await latest.timeout(const Duration(seconds: 3)), isTrue);
      final frame = core.visibleFrames.logBoxLane.value!;
      expect(core.focus.state?.category?.id, 'food');
      expect(frame.scope.categoryIds, <String>{'food'});
      expect(cache.hasCompleteReadablePhaseAFor(frame.logBox), isTrue);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AVATAR_CANDIDATE_SUPERSEDED' &&
              event.scope?.contains('targetHandle=1') == true &&
              event.scope?.contains(
                    'terminalClassification=coalescedBeforeReadiness',
                  ) ==
                  true,
        ),
        isNotEmpty,
      );
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RED AVATAR COLD REPLAY: a newer shared Mind intent terminates a pending Avatar candidate instead of stranding it',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();
      final baseWindow = DashboardLogBoxSceneWindow(
        identity: 'cold-avatar-newer-mind-owner-base',
        payloads: <DashboardLogViewportState>[
          core.visibleFrames.logBoxLane.value!.logBox,
        ],
      );
      await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
      cache.activateWindow(baseWindow);

      final budgetResourceStarted = Completer<void>();
      final releaseBudgetResource = Completer<void>();
      final budgetResourceCompleted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              final isBudgetAvatarResource =
                  lane ==
                  DashboardLiveInteractionResourceLane.budgetAvatarPreview;
              if (isBudgetAvatarResource &&
                  !budgetResourceStarted.isCompleted) {
                budgetResourceStarted.complete();
              }
              await releaseBudgetResource.future;
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
              );
              if (isBudgetAvatarResource &&
                  !budgetResourceCompleted.isCompleted) {
                budgetResourceCompleted.complete();
              }
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      await budgetResourceStarted.future;
      core.beginBudgetAvatarMotion();

      final pendingAvatar = core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'food', displayName: 'Food'),
        publishDuringMotion: true,
        targetHandle: 2,
      );
      await pumpEventQueue();

      // This uses the same production visible-frame authority that an
      // accepted Mind drag claims before its own callback has a display frame.
      final newerMindOrder = core.visibleFrames.nextInteractionPreviewOrder(
        producer: DashboardInteractionPreviewProducer.mindAmount,
        localGeneration: 1,
      );
      expect(
        core.visibleFrames.claimInteractionPublicationIntent(newerMindOrder),
        isTrue,
      );
      expect(
        core.visibleFrames.interactionPreviewOrder?.hasSameIdentity(
          newerMindOrder,
        ),
        isTrue,
      );

      releaseBudgetResource.complete();
      await budgetResourceCompleted.future.timeout(const Duration(seconds: 3));
      expect(
        await pendingAvatar.timeout(const Duration(seconds: 3)),
        isFalse,
        reason:
            'A newer cross-producer interaction owner must terminally stale '
            'the cold Avatar candidate rather than leaving its original '
            'semantic future unresolved after resource completion.',
      );
      expect(core.focus.state, isNull);
      expect(
        core.visibleFrames.interactionPreviewOrder?.hasSameIdentity(
          newerMindOrder,
        ),
        isTrue,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AVATAR_CANDIDATE_SUPERSEDED' &&
              event.scope?.contains('targetHandle=2') == true &&
              event.scope?.contains('terminalClassification=staleRejected') ==
                  true,
        ),
        isNotEmpty,
      );
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RED AVATAR COLD REPLAY: a cold aggregate crossing supersedes an unaccepted category target',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();
      final baseWindow = DashboardLogBoxSceneWindow(
        identity: 'cold-avatar-aggregate-base',
        payloads: <DashboardLogViewportState>[
          core.visibleFrames.logBoxLane.value!.logBox,
        ],
      );
      await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
      cache.activateWindow(baseWindow);

      final budgetResourceStarted = Completer<void>();
      final releaseBudgetResource = Completer<void>();
      final budgetResourceCompleted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              final isBudgetAvatarResource =
                  lane ==
                  DashboardLiveInteractionResourceLane.budgetAvatarPreview;
              if (isBudgetAvatarResource &&
                  !budgetResourceStarted.isCompleted) {
                budgetResourceStarted.complete();
              }
              await releaseBudgetResource.future;
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
              );
              if (isBudgetAvatarResource &&
                  !budgetResourceCompleted.isCompleted) {
                budgetResourceCompleted.complete();
              }
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
      ]);
      await budgetResourceStarted.future;
      core.beginBudgetAvatarMotion();

      final category = core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        publishDuringMotion: true,
        targetHandle: 1,
      );
      await pumpEventQueue();
      final aggregate = core.clearBudgetCategoryFocus(
        publishDuringMotion: true,
        targetHandle: 0,
      );
      await pumpEventQueue();
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AVATAR_CANDIDATE_SUPERSEDED' &&
              event.scope?.contains('targetHandle=1') == true,
        ),
        isNotEmpty,
        reason:
            'A cold aggregate crossing must replace an unaccepted category '
            'candidate before the resource completion arrives.',
      );
      expect(await category.timeout(const Duration(seconds: 3)), isFalse);

      releaseBudgetResource.complete();
      await budgetResourceCompleted.future.timeout(const Duration(seconds: 3));
      expect(
        await aggregate.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'The cold aggregate candidate did not replay. Recent diagnostics: '
            '${FluviDiagnosticLogger.entries.where((event) => event.stage.startsWith('AV')).map((event) => '${event.stage}[${event.scope}]').join(' | ')}',
          ),
        ),
        isTrue,
      );
      final frame = core.visibleFrames.logBoxLane.value!;
      expect(core.focus.state, isNull);
      expect(frame.scope.categoryIds, isEmpty);
      expect(cache.hasCompleteReadablePhaseAFor(frame.logBox), isTrue);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AV|LOGBOX_TARGET_ALREADY_VISIBLE' &&
              event.scope?.contains('targetHandle=0') == true,
        ),
        isNotEmpty,
      );
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'Avatar exact-empty category is an accepted zero-row target rather than a Phase-A resource failure',
    () async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      FluviDiagnosticLogger.clear();
      core.beginBudgetAvatarMotion();

      expect(
        await core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'known-empty', displayName: 'Empty'),
          publishDuringMotion: true,
          targetHandle: 1,
        ),
        isTrue,
      );

      final frame = core.visibleFrames.logBoxLane.value!;
      expect(core.focus.state?.category?.id, 'known-empty');
      expect(frame.scope.categoryIds, <String>{'known-empty'});
      expect(frame.logBox.entryCount, 0);
      expect(frame.logBox.previewRowCount, 0);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|PHASE_A_PUBLICATION_DEFERRED',
        ),
        isEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'LIVE_INTERACTION_ACCEPTED',
        ),
        isNotEmpty,
      );
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RED: a later Avatar target owns the production Phase-A frame after 63 Mind-local previews',
    () async {
      final repository = _FocusSeedRepository(
        rows: const <DashboardLedgerEntry>[
          DashboardLedgerEntry(
            id: 'amount-100000',
            partnerId: 'partner-0',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: 100000,
            bookedLocalEpochDay: 20636,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Utility partner',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
          DashboardLedgerEntry(
            id: 'amount-200000',
            partnerId: 'partner-1',
            categoryId: 'food',
            direction: 'income',
            amountMinor: 200000,
            bookedLocalEpochDay: 20635,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Food partner',
            categoryDisplayName: 'Food',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
          DashboardLedgerEntry(
            id: 'amount-300000',
            partnerId: 'partner-2',
            categoryId: 'food',
            direction: 'income',
            amountMinor: 300000,
            bookedLocalEpochDay: 20634,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Food partner',
            categoryDisplayName: 'Food',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 600000,
          ),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 100000,
            maximumAmountScaled100: 300000,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      core.beginMindAmountRangeInteraction();
      const mindValues = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 300000,
        lowerScaled100: 150000,
        upperScaled100: 300000,
      );
      for (var tick = 0; tick < 63; tick += 1) {
        core.previewMindAmountRange(mindValues);
      }

      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: _focusBudgetSnapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );

      core.beginBudgetAvatarMotion();
      expect(
        await drilldown.previewBudgetTarget(targetHandle: foodHandle),
        isTrue,
        reason:
            'The Avatar producer has its own local generation. A later user '
            'intent must not be rejected only because the prior Mind drag ran '
            'through 63 preview ticks in the shared visible-frame store.',
      );
      expect(core.focus.state?.category?.id, 'food');
      expect(budget.value.selectedHandle, foodHandle);
      expect(
        core.visibleFrames.amountLane.value!.queryKey,
        core.visibleFrames.logBoxLane.value!.queryKey,
      );
      expect(
        core.visibleFrames.countLane.value!.queryKey,
        core.visibleFrames.logBoxLane.value!.queryKey,
      );
      expect(core.visibleFrames.logBoxLane.value!.scope.categoryIds, <String>{
        'food',
      });
      core.endBudgetAvatarMotion();
    },
  );

  testWidgets(
    'RED b166 Phase-A time crossing is accepted without an active rich scene',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
      );
      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: candidate,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
        reason:
            'A retained exact temporal frame is Phase A even when the rich '
            'scene cache has not admitted its optional rendering bank yet.',
      );
      await tester.pump();
      expect(
        core.visibleFrames.logBoxLane.value!.queryKey,
        candidate.temporalAnchor.sourceChildQueryKey,
      );
      expect(
        core.visibleFrames.countLane.value!.queryKey,
        candidate.temporalAnchor.sourceChildQueryKey,
      );
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RED REENTRANT-MIND: an older release cannot overwrite the next drag live rows',
    () async {
      final canonicalGate = Completer<void>();
      final rows = <DashboardLedgerEntry>[
        for (final (index, amount) in <int>[100000, 200000, 300000].indexed)
          DashboardLedgerEntry(
            id: 'amount-$amount',
            partnerId: 'partner-$index',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: amount,
            bookedLocalEpochDay: 20636 - index,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Partner $index',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
      ];
      final repository = _FocusSeedRepository(
        rows: rows,
        prepareAfterBootstrapGate: canonicalGate,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final applied = core.currentQuery.scopeFor(LedgerDirection.income);
      const domain = QueryMenuAmountDomain(
        minimumAmountScaled100: 100000,
        maximumAmountScaled100: 300000,
      );
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 3,
            amountScaled100: 600000,
          ),
          amountDomain: domain,
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      final binding = QueryAmountRangeBinding.ready(
        scope: applied,
        amountDomain: domain,
      )!;

      const firstValues = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 300000,
        lowerScaled100: 250000,
        upperScaled100: 250000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(firstValues), isTrue);
      final firstInteractionGeneration = core.mindAmountInteractionGeneration;
      final firstCommit = core.applyQuery(
        binding.apply(firstValues),
        facetPresentationSource: 'mindAmountRange',
        expectedMindAmountInteractionGeneration: firstInteractionGeneration,
      );
      expect(repository.prepareCalls, 2);

      const secondValues = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 300000,
        lowerScaled100: 150000,
        upperScaled100: 250000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(secondValues), isTrue);
      expect(
        core.visibleFrames.logBoxLane.value!.preparedFrame.stableRowIdentities,
        <String>['amount-200000'],
      );

      canonicalGate.complete();
      expect(await firstCommit, isFalse);
      expect(
        core.visibleFrames.logBoxLane.value!.preparedFrame.stableRowIdentities,
        <String>['amount-200000'],
        reason:
            'The first release belongs to an older interaction generation and '
            'must not replace the exact rows already published by drag two.',
      );
      expect(core.currentQuery.scopeFor(LedgerDirection.income), applied);
    },
  );

  test(
    'RED CROSS-PRODUCER: a delayed Mind canonical release cannot overwrite a later accepted Avatar target',
    () async {
      final canonicalGate = Completer<void>();
      final repository = _FocusSeedRepository(
        prepareAfterBootstrapGate: canonicalGate,
        rows: const <DashboardLedgerEntry>[
          DashboardLedgerEntry(
            id: 'amount-100000',
            partnerId: 'partner-utility',
            categoryId: 'utilities',
            direction: 'income',
            amountMinor: 100000,
            bookedLocalEpochDay: 20636,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Utility partner',
            categoryDisplayName: 'Utilities',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
          DashboardLedgerEntry(
            id: 'amount-200000',
            partnerId: 'partner-food',
            categoryId: 'food',
            direction: 'income',
            amountMinor: 200000,
            bookedLocalEpochDay: 20635,
            bookedLocalTimeMinutes: 600,
            partnerDisplayName: 'Food partner',
            categoryDisplayName: 'Food',
            categoryColorId: 'fallback',
            categoryIconId: 'fallback',
          ),
        ],
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final applied = core.currentQuery.scopeFor(LedgerDirection.income);
      const domain = QueryMenuAmountDomain(
        minimumAmountScaled100: 100000,
        maximumAmountScaled100: 200000,
      );
      _publishMindAmountFacetPresentation(
        core,
        LedgerDirection.income,
        const QueryMenuData(
          result: QueryMenuResultSummary(
            entryCount: 2,
            amountScaled100: 300000,
          ),
          amountDomain: domain,
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      const mindValues = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 200000,
        lowerScaled100: 100000,
        upperScaled100: 100000,
      );
      core.beginMindAmountRangeInteraction();
      expect(core.previewMindAmountRange(mindValues), isTrue);
      final mindCommit = core.commitMindAmountRange(mindValues);
      expect(repository.prepareCalls, 2);

      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: _focusBudgetSnapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );

      expect(
        await drilldown.previewBudgetTarget(targetHandle: foodHandle),
        isTrue,
      );
      expect(core.focus.state?.category?.id, 'food');
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
      );

      canonicalGate.complete();

      expect(
        await mindCommit,
        isFalse,
        reason:
            'The Mind release is older than the accepted Avatar intent even '
            'though its query candidate finishes later.',
      );
      expect(core.currentQuery.scopeFor(LedgerDirection.income), applied);
      expect(core.focus.state?.category?.id, 'food');
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
      );
    },
  );

  testWidgets(
    'RED LIVE-TIME: every component crossing publishes its exact visible data before settle',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final origin = core.navigation.state;
      final candidates = <DashboardNavigationState>[];
      for (var offset = 1; offset <= 8; offset += 1) {
        final candidate = core.experimentalTemporalComponentOffsetCandidate(
          plane: TimePlane.month,
          isRailOpen: true,
          component: DashboardTemporalAnchorComponent.day,
          offset: offset,
          base: origin,
        );
        if (candidate != null) candidates.add(candidate);
      }
      expect(candidates.length, greaterThan(1));
      core.beginSegmentedSummaryMotion();
      FluviDiagnosticLogger.clear();
      for (final candidate in candidates) {
        final publishesBefore = core.visibleFrames.visiblePublishCount;
        core.navigateExperimentalTemporalComponentCandidate(
          candidate: candidate,
          component: DashboardTemporalAnchorComponent.day,
        );
        await tester.pump();

        expect(
          core.navigation.state.dayCursor,
          origin.dayCursor,
          reason:
              'A live component target owns the visible frame first. Canonical '
              'navigation remains at the latest painted owner until the exact '
              'LogBox acknowledgement permits settlement.',
        );
        expect(
          core.visibleFrames.logBoxLane.value!.queryKey,
          candidate.temporalAnchor.sourceChildQueryKey,
          reason:
              'The production LogBox lane must own the semantic tick before '
              'the flight settles.',
        );
        expect(
          core.visibleFrames.countLane.value!.queryKey,
          candidate.temporalAnchor.sourceChildQueryKey,
        );
        expect(
          core.visibleFrames.visiblePublishCount,
          publishesBefore + 1,
          reason: 'Each distinct controlled-frame tick publishes live data.',
        );
      }

      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SCENE_WINDOW_PREPARE_STARTED' ||
              event.stage == 'QUERY_APPLY_STARTED',
        ),
        isEmpty,
      );

      // The stable viewport reports actual paint after the matching live
      // frame has been selected.  Settlement is forbidden before this exact
      // identity has drawable rows (or explicit exact-empty geometry).
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.value!),
      );
      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        candidates.last.dayCursor,
      );

      final visibleBeforeSettle = core.visibleFrames.value!;
      final publishesBeforeSettle = core.visibleFrames.visiblePublishCount;
      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidates.last,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      expect(core.navigation.state.dayCursor, candidates.last.dayCursor);
      final visibleAfterSettle = core.visibleFrames.value;
      expect(visibleAfterSettle?.queryKey, visibleBeforeSettle.queryKey);
      expect(
        visibleAfterSettle?.visualDigest,
        visibleBeforeSettle.visualDigest,
        reason:
            'Settlement promotes canonical ownership of the already-painted '
            'target without selecting new rows.',
      );
      expect(visibleAfterSettle?.logBox, same(visibleBeforeSettle.logBox));
      expect(visibleAfterSettle?.mode, DashboardVisibleMode.committed);
      expect(
        core.visibleFrames.visiblePublishCount,
        publishesBeforeSettle,
        reason:
            'Settle promotes ownership only; it cannot be the first data '
            'publication or produce a second visual frame.',
      );
      final summary = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'TM|FLIGHT_SUMMARY',
      );
      expect(summary.scope, contains('semanticTicks=${candidates.length}'));
      expect(summary.scope, contains('transientScenePrepares=0'));
      expect(
        summary.scope,
        contains('acceptedLiveSnapshots=${candidates.length}'),
      );
      expect(summary.scope, contains('liveRootMisses=0'));
      expect(summary.scope, contains('canonicalSettleCommits=1'));
      expect(summary.scope, contains('settleVisualDeltaCount=0'));
      expect(repository.prepareCalls, 1);
    },
  );

  testWidgets(
    'RED TIME SETTLE: an unpainted exact Time target remains preview-owned until its matching LogBox acknowledgement',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      await core.bootstrap();
      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: candidate,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final preview = core.visibleFrames.value!;
      expect(preview.mode, DashboardVisibleMode.preview);

      FluviDiagnosticLogger.clear();
      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      expect(
        core.navigation.state.dayCursor,
        origin.dayCursor,
        reason:
            'A semantic target may be accepted immediately, but canonical '
            'settlement is forbidden until the real LogBox owner has '
            'acknowledged its exact visible paint.',
      );
      expect(core.visibleFrames.value, same(preview));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_SETTLE_AWAITING_EXACT_PAINT',
        ),
        hasLength(1),
      );

      core.recordLogBoxRenderExtent(_exactPaintSnapshot(preview));
      await tester.pump();
      expect(core.navigation.state.dayCursor, candidate.dayCursor);
      expect(core.visibleFrames.value!.mode, DashboardVisibleMode.committed);
    },
  );

  testWidgets(
    'RED TIME DIAGNOSTICS: one settled flight emits one authoritative final summary',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      await core.bootstrap();
      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: candidate,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.value!),
      );

      FluviDiagnosticLogger.clear();
      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();
      expect(core.navigation.state.dayCursor, candidate.dayCursor);

      // A stale duplicate release must retain its rejection diagnostic, but
      // cannot manufacture a second, contradictory final flight summary.
      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      final summaries = FluviDiagnosticLogger.entries
          .where(
            (event) =>
                event.stage == 'TM|FLIGHT_SUMMARY' &&
                event.flowId == 'flight:1',
          )
          .toList(growable: false);
      expect(summaries, hasLength(1));
      expect(summaries.single.scope, contains('canonicalSettleCommits=1'));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SUMMARY_SETTLE_REJECTED_UNPAINTED_OR_SUPERSEDED',
        ),
        hasLength(1),
        reason:
            'The stale guard remains observable; only premature summary '
            'emission is repaired.',
      );
    },
  );

  testWidgets(
    'RED TIME VISUAL OUTCOME: a target superseded before a display frame is explicitly classified as coalesced',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      await core.bootstrap();
      final origin = core.navigation.state;
      final first = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;
      final second = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 2,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: first,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: second,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();

      final current = core.visibleFrames.value!;
      expect(current.queryKey, second.temporalAnchor.sourceChildQueryKey);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SUMMARY_TARGET_VISUAL_OUTCOME' &&
              (event.scope?.contains('outcome=coalescedBeforePaint') ??
                  false) &&
              event.queryKey == first.temporalAnchor.sourceChildQueryKey.value,
        ),
        hasLength(1),
        reason:
            'An accepted target replaced in the coalescer before it receives '
            'a render opportunity must be accounted for once, rather than '
            'silently inflating a missing-paint metric.',
      );

      core.recordLogBoxRenderExtent(_exactPaintSnapshot(current));
      core.settleExperimentalTemporalComponentCandidate(
        candidate: second,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();
      expect(core.navigation.state.dayCursor, second.dayCursor);
    },
  );

  testWidgets(
    'RED TIME PROMOTION: a matching committed-vertical acknowledgement accepts the already-visible preview target',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      await core.bootstrap();
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          initialYear: 2026,
          entryCountOverride: 154,
          previewRowCountForScope: (_) => 24,
        ),
        publicationState: core.navigation.state,
      );
      await tester.pump();
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: core.navigation.state,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: candidate,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final preview = core.visibleFrames.value!;
      expect(preview.mode, DashboardVisibleMode.preview);
      expect(preview.logBox.previewRowCount, 24);
      // The first authoritative acknowledgement belongs to the exact
      // readable preview. A later committed-vertical report may enrich the
      // same target's geometry, but it cannot be the first paint that
      // authorizes canonical settlement.
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(preview));

      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();
      final committed = core.visibleFrames.value!;
      expect(committed.mode, DashboardVisibleMode.committed);
      expect(committed.logBox, same(preview.logBox));
      final publishCount = core.visibleFrames.visiblePublishCount;
      FluviDiagnosticLogger.clear();

      // This is the physical seq 300/301 shape: the authoritative identity
      // remains the exact preview target, but committed vertical geometry
      // reports the full scope (not only its 24-row preview payload).
      core.recordLogBoxRenderExtent(
        _committedPromotionPaintSnapshot(
          committed,
          drawableRows: committed.logBox.previewRowCount + 130,
        ),
      );

      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        candidate.dayCursor,
        reason:
            'A committed-vertical report for the same exact target must not '
            'be rejected merely because its full drawable scope exceeds the '
            'preview payload count. diagnostics=${FluviDiagnosticLogger.entries.map((event) => '${event.stage}:${event.scope}').join(' || ')}',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_TARGET_PAINT_REJECTED',
        ),
        isEmpty,
      );
      expect(core.visibleFrames.visiblePublishCount, publishCount);
    },
  );

  testWidgets(
    'POST-DF1 RED: an old same-query render report cannot paint-accept a newer Segmented generation',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldOriginFrame = core.visibleFrames.logBoxLane.value!;
      final origin = core.navigation.state;
      final next = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: next,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: origin,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final currentOriginFrame = core.visibleFrames.logBoxLane.value!;
      expect(currentOriginFrame.queryKey, oldOriginFrame.queryKey);
      expect(
        currentOriginFrame.frameGeneration,
        greaterThan(oldOriginFrame.frameGeneration),
        reason:
            'A reverse crossing may return to the same Query key but still '
            'requires a new exact visible-frame identity.',
      );

      core.recordLogBoxRenderExtent(_exactPaintSnapshot(oldOriginFrame));
      expect(
        core.segmentedTargetPainted.value,
        isNull,
        reason:
            'A delayed old 2025 report cannot acknowledge the later 2025 '
            'crossing solely because query/revision/epoch happen to match.',
      );

      core.recordLogBoxRenderExtent(_exactPaintSnapshot(currentOriginFrame));
      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        origin.dayCursor,
      );
    },
  );

  testWidgets(
    'RED TIME PAINT IDENTITY: returning to an already-painted target requires its newer frame acknowledgement',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final origin = core.navigation.state;
      final next = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: next,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final firstNextFrame = core.visibleFrames.logBoxLane.value!;
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(firstNextFrame));

      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: origin,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(core.visibleFrames.logBoxLane.value!),
      );

      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: next,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final secondNextFrame = core.visibleFrames.logBoxLane.value!;
      expect(
        secondNextFrame.frameGeneration,
        greaterThan(firstNextFrame.frameGeneration),
      );

      core.recordLogBoxRenderExtent(_exactPaintSnapshot(secondNextFrame));
      core.settleExperimentalTemporalComponentCandidate(
        candidate: next,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      expect(
        core.navigation.state.dayCursor,
        next.dayCursor,
        reason:
            'The old fast-path compared only the temporal candidate and left '
            'this newer same-query frame forever unpainted for settlement.',
      );
    },
  );

  testWidgets(
    'b166 regression: a new Summary pointer cannot commit an unpainted semantic target and rejects its late acknowledgement',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: candidate,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      // The display-frame callback has already handed this preview to the
      // production visible store, so the coalescer no longer has a pending
      // slot to discard. Its LogBox paint acknowledgement is still absent.
      await tester.pump();
      final publishedUnpaintedFrame = core.visibleFrames.value!;
      expect(publishedUnpaintedFrame.mode, DashboardVisibleMode.preview);

      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      expect(core.navigation.state.dayCursor, origin.dayCursor);

      // A direct pointer interrupts the old ballistic/settling generation
      // before it crosses a replacement target. A late report for that old
      // frame must no longer acquire canonical settlement ownership.
      core.noteSummaryDirectPointerDown();
      core.recordLogBoxRenderExtent(
        _exactPaintSnapshot(publishedUnpaintedFrame),
      );
      await tester.pump();

      expect(core.segmentedTargetPainted.value, isNull);
      expect(
        core.navigation.state.dayCursor,
        origin.dayCursor,
        reason:
            'A late acknowledgement from an interrupted, unpainted preview '
            'may not become a first-time canonical settlement.',
      );
    },
  );

  testWidgets(
    'b166 regression: Summary pointer interruption never promotes a newer unpainted target over canonical state',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final origin = core.navigation.state;
      final painted = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;
      final unpainted = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 2,
        base: origin,
      )!;

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: painted,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final paintedFrame = core.visibleFrames.value!;
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(paintedFrame));
      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        painted.dayCursor,
      );

      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: unpainted,
              component: DashboardTemporalAnchorComponent.day,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      expect(
        core.visibleFrames.value!.queryKey,
        unpainted.temporalAnchor.sourceChildQueryKey,
      );

      // The new pointer becomes a cancelled/tap interaction: it never emits
      // a replacement crossing. The B preview may remain the live visible
      // target until the next interaction, but it cannot become canonical
      // before its own exact acknowledgement.
      core.noteSummaryDirectPointerDown();
      await tester.pump();

      final retained = core.visibleFrames.value!;
      expect(core.navigation.state.dayCursor, origin.dayCursor);
      expect(retained.mode, DashboardVisibleMode.preview);
      expect(retained.queryKey, unpainted.temporalAnchor.sourceChildQueryKey);
      expect(core.segmentedTargetPainted.value, isNull);
      expect(repository.prepareCalls, 1);
    },
  );

  testWidgets(
    'b166 regression: parent-changing Summary interruption leaves an unpainted live target non-canonical',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearWindowRadius: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      FluviDiagnosticLogger.clear();
      await core.bootstrap();

      var scenePreparationCalls = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          scenePreparationCalls += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        prepareRetained:
            (window, {required retainedKey, required retainViewportId}) =>
                cache.prepareRetainedWindow(
                  retainedKey: retainedKey,
                  window: window,
                  retainViewportId: retainViewportId,
                  surfaceWidth: 378,
                ),
        hasRetained: cache.hasRetainedWindow,
        retainSegmentedPaintedTarget: (window, {required retainedKey}) =>
            cache.retainActiveWindowForSegmentedPaintedTarget(
              retainedKey: retainedKey,
              window: window,
            ),
        discardRetainedSegmentedPaintedTarget:
            cache.discardRetainedSegmentedPaintedTargetWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          initialYear: 2026,
          yearWindowRadius: 1,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      await tester.pump();

      final origin = core.navigation.state;
      final painted = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -1,
        base: origin,
      )!;
      final unpainted = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: 1,
        base: origin,
      )!;
      expect(
        painted.parentQueryKey,
        isNot(origin.parentQueryKey),
        reason: 'The painted 2025 target uses its own prepared parent.',
      );
      expect(
        unpainted.parentQueryKey,
        isNot(painted.parentQueryKey),
        reason: 'The unpainted 2027 target uses another prepared parent.',
      );
      final paintedWindow = core.railInteractionSceneWindowFor(painted);
      final unpaintedWindow = core.railInteractionSceneWindowFor(unpainted);
      await cache.prepareRetainedWindow(
        retainedKey: 'post-df1-parent-changing-painted',
        window: paintedWindow,
        surfaceWidth: 378,
      );
      await cache.prepareRetainedWindow(
        retainedKey: 'post-df1-parent-changing-unpainted',
        window: unpaintedWindow,
        surfaceWidth: 378,
      );

      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: painted,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final paintedFrame = core.visibleFrames.value!;
      expect(cache.railCriticalSceneFor(paintedFrame.logBox), isNotNull);
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(paintedFrame));
      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        painted.dayCursor,
      );

      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: unpainted,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isExactLivePublication,
        isTrue,
      );
      await tester.pump();
      final newerPreview = core.visibleFrames.value!;
      expect(
        newerPreview.queryKey,
        unpainted.temporalAnchor.sourceChildQueryKey,
      );
      expect(cache.railCriticalSceneFor(newerPreview.logBox), isNotNull);

      final scenePreparationCallsBeforeInterrupt = scenePreparationCalls;
      core.noteSummaryDirectPointerDown();
      await tester.pump();

      final retained = core.visibleFrames.value!;
      expect(core.navigation.state.dayCursor, origin.dayCursor);
      expect(retained.mode, DashboardVisibleMode.preview);
      expect(retained.queryKey, unpainted.temporalAnchor.sourceChildQueryKey);
      expect(
        cache.railCriticalSceneFor(retained.logBox),
        isNotNull,
        reason:
            'The selected parent may retain continuity while its rich scene '
            'is prepared, but it must never restore the previous parent.',
      );
      expect(
        scenePreparationCalls,
        scenePreparationCallsBeforeInterrupt,
        reason:
            'Semantic preemption is RAM-only and may not prepare another scene.',
      );
    },
  );

  testWidgets(
    'RED LIVE-LEVEL: every segmented level crossing publishes exact visible data in one frame',
    (tester) async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.year,
        isRailOpen: false,
      );
      await tester.pump();
      expect(core.navigation.state.plane, TimePlane.year);
      expect(core.navigation.state.isRailOpen, isFalse);
      expect(
        core.visibleFrames.logBoxLane.value!.queryKey,
        core.navigation.state.parentQueryKey,
      );
      expect(
        core.visibleFrames.countLane.value!.queryKey,
        core.navigation.state.parentQueryKey,
      );

      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.sum,
        isRailOpen: false,
      );
      await tester.pump();
      expect(core.navigation.state.plane, TimePlane.sum);
      expect(
        core.visibleFrames.logBoxLane.value!.queryKey,
        core.navigation.state.parentQueryKey,
      );
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SCENE_WINDOW_PREPARE_STARTED' ||
              event.stage == 'QUERY_APPLY_STARTED',
        ),
        isEmpty,
      );
    },
  );

  test(
    'G2: Budget Header selection changes only with its matching visible Query frame',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final snapshot = _focusBudgetSnapshot();
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );
      expect(foodHandle, greaterThan(0));
      expect(budget.value.selectedHandle, 0);

      final visibleCategoriesAtHeaderCommit = <Set<String>>[];
      budget.addListener(() {
        if (budget.value.selectedHandle == foodHandle) {
          visibleCategoriesAtHeaderCommit.add(
            core.visibleFrames.value!.scope.categoryIds,
          );
        }
      });

      expect(
        await drilldown.commitBudgetTargetHandle(
          targetHandle: foodHandle,
          source: 'test',
        ),
        isTrue,
      );

      expect(core.focus.state?.category?.id, 'food');
      expect(core.liveInteractions.frame?.category?.id, 'food');
      expect(core.visibleFrames.value!.scope.categoryIds, <String>{'food'});
      expect(budget.value.selectedHandle, foodHandle);
      expect(visibleCategoriesAtHeaderCommit, <Set<String>>[
        <String>{'food'},
      ]);
    },
  );

  test(
    'RED AVATAR ATOMICITY: a live Avatar frame never exposes an old Budget target to dependent surfaces',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: _focusBudgetSnapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );
      expect(foodHandle, greaterThan(0));

      final observedAvatarFrames =
          <
            ({
              int selectedHandle,
              int analysisTargetHandle,
              int headerTargetHandle,
              int? liveTargetHandle,
              String? focusedCategoryId,
              Set<String> logBoxCategoryIds,
              Object? amountQueryKey,
              Object? countQueryKey,
              Object? logBoxQueryKey,
            })
          >[];
      budget.addListener(() {
        final live = core.liveInteractions.frame;
        if (live?.source != DashboardLiveInteractionSource.budgetAvatar) {
          return;
        }
        final logBox = core.visibleFrames.logBoxLane.value;
        observedAvatarFrames.add((
          selectedHandle: budget.value.selectedHandle,
          analysisTargetHandle: budget.value.liveAnalysis.targetHandle,
          headerTargetHandle: budget.value.liveSelection.target.handle,
          liveTargetHandle: live?.budgetTargetHandle,
          focusedCategoryId: core.focus.state?.category?.id,
          logBoxCategoryIds: logBox?.scope.categoryIds ?? const <String>{},
          amountQueryKey: core.visibleFrames.amountLane.value?.queryKey,
          countQueryKey: core.visibleFrames.countLane.value?.queryKey,
          logBoxQueryKey: logBox?.queryKey,
        ));
      });

      expect(
        await drilldown.previewBudgetTarget(targetHandle: foodHandle),
        isTrue,
      );

      expect(observedAvatarFrames, isNotEmpty);
      for (final frame in observedAvatarFrames) {
        expect(frame.selectedHandle, foodHandle);
        expect(frame.analysisTargetHandle, foodHandle);
        expect(frame.headerTargetHandle, foodHandle);
        expect(frame.liveTargetHandle, foodHandle);
        expect(frame.focusedCategoryId, 'food');
        expect(frame.logBoxCategoryIds, <String>{'food'});
        expect(frame.amountQueryKey, frame.logBoxQueryKey);
        expect(frame.countQueryKey, frame.logBoxQueryKey);
      }
    },
  );

  test(
    'RED LIVE-AVATAR: a real handle crossing publishes one complete focused frame before settle',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final categories =
          ValueNotifier<List<FluviCategory>>(const <FluviCategory>[
            FluviCategory(
              id: 'utilities',
              name: 'Utilities',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
            FluviCategory(
              id: 'food',
              name: 'Food',
              colorId: 'fallback',
              iconId: 'fallback',
              isSystemUncategorized: false,
              createdAtUtcMs: 1,
              updatedAtUtcMs: 1,
            ),
          ]);
      addTearDown(categories.dispose);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: _focusBudgetSnapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      addTearDown(budget.dispose);
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final foodHandle = budget.value.items.indexWhere(
        (item) => item.target.category?.id == 'food',
      );
      final visiblePublishes = core.visibleFrames.visiblePublishCount;
      final indexPublishes = core.dataRuntime.publishedIndexCount;
      FluviDiagnosticLogger.clear();

      expect(
        await drilldown.previewBudgetTarget(targetHandle: foodHandle),
        isTrue,
      );

      expect(budget.value.selectedHandle, foodHandle);
      expect(core.focus.state?.category?.id, 'food');
      expect(core.visibleFrames.value!.scope.categoryIds, <String>{'food'});
      expect(
        core.visibleFrames.amountLane.value!.queryKey,
        core.visibleFrames.logBoxLane.value!.queryKey,
      );
      expect(
        core.visibleFrames.countLane.value!.queryKey,
        core.visibleFrames.logBoxLane.value!.queryKey,
      );
      expect(core.visibleFrames.visiblePublishCount, visiblePublishes + 1);
      expect(
        core.dataRuntime.publishedIndexCount,
        indexPublishes,
        reason:
            'The live focus snapshot comes from the prepared Avatar hotset; '
            'it does not install a new repository-built canonical index.',
      );
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'FOCUS_PUBLICATION_COMPLETED',
        ),
        hasLength(1),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|TARGET_PREVIEW_BOUND',
        ),
        isEmpty,
      );

      final visibleBeforeSettle = core.visibleFrames.value;
      final publishesBeforeSettle = core.visibleFrames.visiblePublishCount;
      expect(
        await drilldown.commitBudgetTargetHandle(
          targetHandle: foodHandle,
          source: 'avatarSettled',
        ),
        isTrue,
      );
      expect(core.focus.state?.category?.id, 'food');
      expect(core.visibleFrames.value, same(visibleBeforeSettle));
      expect(core.visibleFrames.visiblePublishCount, publishesBeforeSettle);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'Budget avatar preview crossings publish the shared amount, count and Ledger lanes together',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final previewAmounts = <int>[];
      core.visibleFrames.amountLane.addListener(() {
        final frame = core.visibleFrames.amountLane.value;
        if (frame != null) previewAmounts.add(frame.amount.totalMinor);
      });

      Future<void> preview(
        DashboardFocusFacet facet,
        int expectedAmount,
      ) async {
        expect(await core.requestBudgetCategoryFocus(facet), isTrue);
        final amountFrame = core.visibleFrames.amountLane.value!;
        final countFrame = core.visibleFrames.countLane.value!;
        final logBoxFrame = core.visibleFrames.logBoxLane.value!;
        expect(amountFrame.amount.totalMinor, expectedAmount);
        expect(amountFrame.amount.queryKey, countFrame.count.queryKey);
        expect(amountFrame.amount.queryKey, logBoxFrame.logBox.queryKey);
        expect(core.focus.state?.category?.id, facet.id);
      }

      await preview(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        500,
      );
      await preview(
        const DashboardFocusFacet(id: 'food', displayName: 'Food'),
        700,
      );
      await preview(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        500,
      );

      final amountBeforeSettle = core.visibleFrames.amountLane.value!;
      final visiblePublishCountBeforeSettle =
          core.visibleFrames.visiblePublishCount;
      expect(
        await core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      expect(core.visibleFrames.amountLane.value, same(amountBeforeSettle));
      expect(
        core.visibleFrames.visiblePublishCount,
        visiblePublishCountBeforeSettle,
        reason:
            'Settling the already-current avatar target must reuse its preview '
            'rather than publishing an aggregate or starting a second amount lane.',
      );
      expect(previewAmounts, containsAllInOrder(<int>[500, 700, 500]));
      expect(
        repository.prepareCalls,
        1,
        reason:
            'Avatar crossings derive from the prepared membership; they do not '
            'start a repository query per visual tick.',
      );
    },
  );

  test(
    'Budget avatar preview publishes its newest prepared Ledger frame before a held scene settles',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final gates = <Completer<void>>[];
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {
          final gate = Completer<void>();
          gates.add(gate);
          if (gates.length == 1) {
            firstStarted.complete();
          } else if (gates.length == 2) {
            secondStarted.complete();
          }
          await gate.future;
        },
        activate: (_) {},
      );
      FluviDiagnosticLogger.clear();
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);

      final previewA = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      expect(
        firstStarted.isCompleted,
        isTrue,
        reason:
            'The discrete avatar crossing is foreground interaction: it '
            'starts the matching LogBox scene path immediately instead of '
            'waiting for the carousel to settle.',
      );
      await firstStarted.future;
      final previewB = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      final previewC = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'food',
          displayName: 'Food',
        ),
      );

      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        700,
        reason:
            'The discrete C avatar tick owns the SummaryPill amount as soon '
            'as FOCUS_DERIVED_SCOPE_READY has produced its prepared scalar, '
            'rather than waiting for the queued scene window.',
      );
      expect(
        core.visibleFrames.value!.amount.totalMinor,
        700,
        reason:
            'The bounded prepared LogBox frame is the live interaction '
            'authority; only rich scene decoration remains asynchronous.',
      );
      final focusedViewport = core.visibleFrames.value!;
      expect(
        core.focus.state?.category?.id,
        'food',
        reason:
            'The accepted avatar target must expose its Category facet before '
            'the held rich scene is allowed to finish.',
      );
      expect(focusedViewport.count.entryCount, 1);
      expect(focusedViewport.logBox.entryCount, 1);
      expect(
        focusedViewport.logBox.stableRowIdentities,
        const <String>['food-row'],
        reason:
            'The first prepared viewport is already exact and ordered; rich '
            'row decoration is only a later render resource.',
      );
      expect(
        core.visibleFrames.amountPreviewPublishCount,
        0,
        reason:
            'Avatar crossings publish one complete visible generation; they '
            'must not expose a scalar amount-only notifier first.',
      );

      gates.first.complete();
      await secondStarted.future;
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        700,
        reason: 'A late A scene preparation must not overwrite C\'s amount.',
      );
      gates[1].complete();

      expect(await previewA, isTrue);
      expect(await previewB, isTrue);
      expect(await previewC, isTrue);
      expect(core.focus.state?.category?.id, 'food');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 700);
      expect(core.visibleFrames.value!.amount.totalMinor, 700);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RED POST-df1: Avatar raw re-entry supersedes a queued Core install before the next crossing',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final originalFrame = core.visibleFrames.value!;
      FluviDiagnosticLogger.clear();

      final oldPublication = core.requestBudgetCategoryFocus(
        const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        // This is the existing coalesced Avatar focus installation used when
        // a prior semantic command has not yet reached its foreground turn.
        // Its actual install is deferred one event turn, leaving a precise
        // pointer-down-to-next-crossing supersession window.
        publishDuringMotion: false,
        targetHandle: 1,
      );

      // This is the physical boundary under review: the new pointer exists
      // before it has emitted its first semantic target. A completing old
      // installation may not publish into that gap.
      core.noteBudgetAvatarDirectPointerDown();
      await pumpEventQueue();

      expect(await oldPublication, isFalse);
      expect(
        core.visibleFrames.value,
        same(originalFrame),
        reason:
            'An old ballistic target must not replace Budget/LogBox while the '
            'replacement pointer has not yet crossed a new Avatar target.',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'FOCUS_PUBLICATION_COMPLETED',
        ),
        isEmpty,
      );
    },
  );

  test(
    'b166 regression: an active Avatar semantic target remains accepted after raw re-entry without rich paint',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
      );
      FluviDiagnosticLogger.clear();
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);
      final first = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      await pumpEventQueue();
      expect(await first, isTrue);

      core.noteBudgetAvatarDirectPointerDown();
      expect(
        await drilldown.previewBudgetTarget(
          state: _budgetAvatarPreviewState(
            categoryId: 'utilities',
            displayName: 'Utilities',
          ),
        ),
        isTrue,
        reason:
            'A cyclic crossing that returns to the current Phase-A Avatar '
            'projection must be accepted immediately; rich paint may still '
            'arrive later.',
      );
    },
  );

  test(
    'b166 regression: same Avatar crossing after raw re-entry accepts its Phase-A frame before rich paint',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);
      FluviDiagnosticLogger.clear();
      final state = _budgetAvatarPreviewState(
        categoryId: 'utilities',
        displayName: 'Utilities',
      );

      // The first crossing atomically selects its exact Budget/LogBox frame.
      // Rich render acknowledgement is intentionally not an admission gate.
      final first = drilldown.previewBudgetTarget(state: state);
      await pumpEventQueue();
      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.visibleFrames.value!.scope.categoryIds, <String>{
        'utilities',
      });

      core.noteBudgetAvatarDirectPointerDown();
      expect(await first, isTrue);

      final reentered = drilldown.previewBudgetTarget(state: state);
      await pumpEventQueue();
      expect(
        await reentered,
        isTrue,
        reason:
            'The same semantic Avatar target may not wait for a prior rich '
            'paint acknowledgement after raw pointer re-entry.',
      );
    },
  );

  test(
    'RED: same Avatar crossing after raw re-entry rearms its exact paint acknowledgement',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);
      final state = _budgetAvatarPreviewState(
        categoryId: 'utilities',
        displayName: 'Utilities',
      );

      core.beginBudgetAvatarMotion();
      expect(await drilldown.previewBudgetTarget(state: state), isTrue);
      expect(core.budgetAvatarTargetPainted.value, isNull);

      // Raw contact cancels the unpainted former acknowledgement. Returning
      // to the same already accepted Phase-A target must arm the next actual
      // LogBox extent report instead of accepting semantic state only.
      core.noteBudgetAvatarDirectPointerDown();
      expect(await drilldown.previewBudgetTarget(state: state), isTrue);
      final reenteredFrame = core.visibleFrames.logBoxLane.value!;
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(reenteredFrame));

      expect(core.budgetAvatarTargetPainted.value?.targetHandle, 1);
      expect(await core.awaitBudgetAvatarTargetPaint(targetHandle: 1), isTrue);
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RG-G2: Avatar crossings publish prepared semantic frames without starting rich scene work during motion',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var scenePrepareCalls = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {
          scenePrepareCalls += 1;
        },
        activate: (_) {},
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);

      core.beginBudgetAvatarMotion();
      final previewA = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      final previewB = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'food',
          displayName: 'Food',
        ),
      );
      final previewC = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      await pumpEventQueue();

      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 500);
      expect(
        scenePrepareCalls,
        0,
        reason:
            'The crossing path may derive and atomically publish a retained '
            'prepared semantic frame, but it must not occupy the UI isolate '
            'with rich scene preparation while the Avatar rail is ballistic.',
      );

      core.endBudgetAvatarMotion();
      await pumpEventQueue();

      await Future.wait(<Future<bool>>[previewA, previewB, previewC]);
      expect(
        scenePrepareCalls,
        1,
        reason:
            'Motion end admits only the latest bounded scene augmentation, '
            'rather than one UI-isolate prepare per Avatar crossing.',
      );
      expect(core.focus.state?.category?.id, 'utilities');
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RG-G2: an eight-crossing Avatar hotset promotes immutable focus roots without UI-isolate derivation',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      await pumpEventQueue();
      expect(core.budgetAvatarFocusHotsetDiagnostics['cached'], 2);
      FluviDiagnosticLogger.clear();

      core.beginBudgetAvatarMotion();
      final visiblePublishes = core.visibleFrames.visiblePublishCount;
      final liveInteractionPublishes =
          core.visibleFrames.interactionPreviewPublishCount;
      for (var index = 0; index < 8; index += 1) {
        final utilities = index.isEven;
        expect(
          await core.requestBudgetCategoryFocus(
            DashboardFocusFacet(
              id: utilities ? 'utilities' : 'food',
              displayName: utilities ? 'Utilities' : 'Food',
            ),
            publishDuringMotion: true,
            targetHandle: index,
          ),
          isTrue,
        );
        expect(
          core.visibleFrames.amountLane.value!.queryKey,
          core.visibleFrames.logBoxLane.value!.queryKey,
        );
        expect(
          core.visibleFrames.countLane.value!.queryKey,
          core.visibleFrames.logBoxLane.value!.queryKey,
        );
      }
      core.endBudgetAvatarMotion();

      expect(
        core.visibleFrames.visiblePublishCount,
        visiblePublishes,
        reason:
            'Each ballistic crossing must update the atomic Phase-A lanes, '
            'not replace the committed complete frame before settle.',
      );
      expect(
        core.visibleFrames.interactionPreviewPublishCount,
        liveInteractionPublishes + 8,
      );
      expect(
        core.budgetAvatarFocusHotsetDiagnostics['promotions'],
        8,
        reason:
            'hotset=${core.budgetAvatarFocusHotsetDiagnostics} '
            'derived=${FluviDiagnosticLogger.entries.where((event) => event.stage == 'FOCUS_DERIVED_SCOPE_READY').map((event) => event.scope).join(' || ')}',
      );
      expect(core.budgetAvatarFocusHotsetDiagnostics['misses'], 0);
      final derived = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'FOCUS_DERIVED_SCOPE_READY')
          .toList(growable: false);
      expect(derived, hasLength(8));
      for (final event in derived) {
        expect(event.scope, contains('avatarFocusHotsetHit=true'));
        expect(event.scope, contains('uiIsolateMicros=0'));
      }
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'RED G2: an Avatar hotset requested before bootstrap is prepared when the initial index installs',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);

      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);

      expect(core.budgetAvatarFocusHotsetDiagnostics['cached'], 0);
      await core.bootstrap();
      await pumpEventQueue();

      expect(
        core.budgetAvatarFocusHotsetDiagnostics['cached'],
        2,
        reason:
            'The rail mounts before the Core installs its first immutable '
            'index. Its bounded neighbour request must survive that ordering, '
            'otherwise every first fling takes the expensive derivation path.',
      );
    },
  );

  test(
    'RED G2: the first Avatar fling cannot fall through a pending idle hotset to UI-isolate derivation',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      // Deliberately do not yield to an event-loop turn. The fixed local
      // horizon must already be available before the first real rail fling
      // can start from the newly-ready Dashboard frame.
      expect(core.budgetAvatarFocusHotsetDiagnostics['cached'], 2);
      FluviDiagnosticLogger.clear();

      core.beginBudgetAvatarMotion();
      for (var index = 0; index < 8; index += 1) {
        final utilities = index.isEven;
        expect(
          await core.requestBudgetCategoryFocus(
            DashboardFocusFacet(
              id: utilities ? 'utilities' : 'food',
              displayName: utilities ? 'Utilities' : 'Food',
            ),
            publishDuringMotion: true,
            targetHandle: index,
          ),
          isTrue,
        );
      }
      core.endBudgetAvatarMotion();

      expect(
        core.budgetAvatarFocusHotsetDiagnostics['misses'],
        0,
        reason:
            'A bounded preparation request may not leave the first user fling '
            'on the direct deriveFast path just because the idle task has not '
            'received a turn yet.',
      );
      final derived = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'FOCUS_DERIVED_SCOPE_READY')
          .toList(growable: false);
      expect(derived, hasLength(8));
      for (final event in derived) {
        expect(event.scope, contains('avatarFocusHotsetHit=true'));
        expect(event.scope, contains('uiIsolateMicros=0'));
      }
    },
  );

  test(
    'RED E8M: the first Avatar resource bank contains only exact local hotset roots',
    () async {
      const categoryIds = <String>['utilities', 'food', 'travel', 'home'];
      final rows = List<DashboardLedgerEntry>.generate(240, (index) {
        final categoryId = categoryIds[index % categoryIds.length];
        return DashboardLedgerEntry(
          id: 'avatar-cold-$index',
          partnerId: 'partner-$index',
          categoryId: categoryId,
          direction: 'income',
          amountMinor: 100 + index,
          bookedLocalEpochDay: 20636 - index,
          bookedLocalTimeMinutes: 600,
          partnerDisplayName: 'Partner $index',
          categoryDisplayName: categoryId,
          categoryColorId: 'fallback',
          categoryIconId: 'fallback',
        );
      });
      final repository = _FocusSeedRepository(rows: rows);
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initialWindow = DashboardLogBoxSceneWindow(
        identity: 'e8m-avatar-cold-local-resource-base',
        payloads: <DashboardLogViewportState>[
          core.visibleFrames.logBoxLane.value!.logBox,
        ],
      );
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);

      DashboardLogBoxSceneWindow? avatarResourceWindow;
      final avatarResourcePrepared = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              if (lane ==
                  DashboardLiveInteractionResourceLane.budgetAvatarPreview) {
                avatarResourceWindow = window;
              }
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
              );
              if (lane ==
                      DashboardLiveInteractionResourceLane
                          .budgetAvatarPreview &&
                  !avatarResourcePrepared.isCompleted) {
                avatarResourcePrepared.complete();
              }
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );

      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[
        DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        DashboardFocusFacet(id: 'food', displayName: 'Food'),
      ]);
      await avatarResourcePrepared.future.timeout(const Duration(seconds: 3));
      for (
        var turn = 0;
        turn < 40 && !core.budgetAvatarLiveRootReady.value;
        turn += 1
      ) {
        await pumpEventQueue();
      }

      final window = avatarResourceWindow;
      final baseMembership = core.preparedIndex!
          .partitionFor(LedgerDirection.income)
          .focusMembershipSeed!;
      expect(window, isNotNull);
      expect(baseMembership.entryCount, 240);
      expect(
        window!.payloads,
        hasLength(3),
        reason:
            'The aggregate/current root plus the two immediately reachable '
            'Avatar targets are the only normal-path Phase-A inputs.',
      );
      expect(
        window.previewRowCount,
        lessThan(baseMembership.entryCount),
        reason:
            'The first Avatar gesture may not wait for a broad reusable '
            'focus-membership universe.',
      );
      expect(
        window.payloads.every(
          (payload) => payload.previewRowCount <= core.preparedIndex!.pageSize,
        ),
        isTrue,
        reason:
            'Every Avatar resource payload must remain a compact exact '
            'preview root rather than the complete source membership.',
      );
      expect(
        cache.hasLiveInteractionResourceWindow(
          window,
          lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
          resourceKey: window.identity,
        ),
        isTrue,
      );
      expect(
        core.budgetAvatarLiveRootReady.value,
        isTrue,
        reason: 'hotset=${core.budgetAvatarFocusHotsetDiagnostics}',
      );

      core.beginBudgetAvatarMotion();
      expect(
        await core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
          publishDuringMotion: true,
          targetHandle: 1,
        ),
        isTrue,
      );
      final visible = core.visibleFrames.logBoxLane.value!;
      expect(visible.scope.categoryIds, <String>{'utilities'});
      expect(cache.hasCompleteReadablePhaseAFor(visible.logBox), isTrue);
      core.endBudgetAvatarMotion();
    },
  );

  test(
    'RG-G3: Summary raw input cancels a retained time-neighbour preparation before arena resolution',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final retainedStarted = Completer<void>();
      final retainedGate = Completer<void>();
      var cancels = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareRetained:
            (_, {required retainedKey, required retainViewportId}) {
              if (!retainedStarted.isCompleted) retainedStarted.complete();
              return retainedGate.future;
            },
        cancel: () => cancels += 1,
      );

      core.beginVerticalInteraction();
      core.resumeSceneWindowMaintenanceAfterVerticalInput();
      await pumpEventQueue();
      expect(retainedStarted.isCompleted, isTrue);
      FluviDiagnosticLogger.clear();

      core.noteSummaryDirectPointerDown();
      expect(cancels, greaterThanOrEqualTo(1));
      final preemption = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'SUMMARY_DIRECT_POINTER_PREEMPTED',
      );
      expect(preemption.scope, contains('cancelledSummaryParentHotset=true'));
      retainedGate.complete();
      await pumpEventQueue();
    },
  );

  testWidgets(
    'RED FPA baseline control: a Summary pointer starts Time resource preparation while Avatar motion is still active',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          initialYear: 2026,
          entryCountOverride: 4,
          previewRowCountForScope: (_) => 4,
          deferredLogBoxes: true,
        ),
        publicationState: core.navigation.state,
      );

      final timeResourceStarted = Completer<void>();
      core.beginBudgetAvatarMotion();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: (_) {},
        prepareLiveInteractionResources:
            (
              _, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              if (lane == DashboardLiveInteractionResourceLane.timePreview &&
                  !timeResourceStarted.isCompleted) {
                timeResourceStarted.complete();
              }
            },
      );

      // Coordinator attachment during active Avatar motion is intentionally
      // not the trigger. The new physical Summary pointer is the required
      // handoff boundary, before its gesture arena has resolved.
      await tester.pump();
      expect(timeResourceStarted.isCompleted, isFalse);

      core.noteSummaryDirectPointerDown();
      await tester.pump();

      expect(
        timeResourceStarted.isCompleted,
        isTrue,
        reason:
            'Time resource preparation must start on the foreground pointer, '
            'not after the old Avatar ScrollEnd.',
      );
    },
  );

  testWidgets(
    'RED FPA: an Avatar-active Summary pointer acquires the cold Time Phase-A resource before Avatar lifecycle end',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      // This production-parent index provides a real non-empty prepared
      // Time payload. The test intentionally does not preinstall the
      // `timePreview` resource bank: that remains cold until the Summary
      // pointer takes foreground ownership below.
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          initialYear: 2026,
          entryCountOverride: 4,
          previewRowCountForScope: (_) => 4,
          deferredLogBoxes: true,
        ),
        publicationState: core.navigation.state,
      );

      final initialWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      final timeResourceStarted = Completer<void>();
      final releaseTimeResource = Completer<void>();
      final cancelledResourceLanes = <DashboardLiveInteractionResourceLane>[];
      core.beginBudgetAvatarMotion();
      final visibleBeforeTakeover = core.visibleFrames.value!;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        activate: cache.activateWindow,
        prepareLiveInteractionResources:
            (
              window, {
              required lane,
              required retainedKey,
              required retainViewportId,
            }) async {
              if (lane == DashboardLiveInteractionResourceLane.timePreview) {
                if (!timeResourceStarted.isCompleted) {
                  timeResourceStarted.complete();
                }
                await releaseTimeResource.future;
              }
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                retainViewportId: retainViewportId,
                surfaceWidth: 378,
              );
            },
        hasLiveInteractionResources:
            (window, {required lane, required candidateKey}) =>
                cache.hasLiveInteractionResourceWindow(
                  window,
                  lane: lane,
                  resourceKey: candidateKey,
                ),
        cancelLiveInteractionResourcePreparation: ({required lane}) {
          cancelledResourceLanes.add(lane);
          return cache.cancelLiveInteractionResourcePreparation(lane: lane);
        },
        bindLiveInteractionReadablePhaseA:
            (payload, {required lane, required resourceKey}) =>
                cache.bindLiveInteractionReadablePhaseA(
                  payload,
                  lane: lane,
                  resourceKey: resourceKey,
                ),
      );

      // Attaching during Avatar motion must not be enough to start Time work:
      // the tested boundary is the newer Summary pointer, before its pan wins.
      await tester.pump();
      expect(timeResourceStarted.isCompleted, isFalse);

      FluviDiagnosticLogger.clear();
      core.noteSummaryDirectPointerDown();
      await tester.pump();

      expect(
        timeResourceStarted.isCompleted,
        isTrue,
        reason:
            'The new foreground Time producer must request its bounded '
            'timePreview resource now, not after the old Avatar ScrollEnd.',
      );
      expect(
        core.isMotionLaneActive(DashboardMotionLane.budgetAvatar),
        isFalse,
        reason:
            'The physical Avatar controller may finish later, but its old '
            'foreground scheduling lane cannot survive the Time pointer.',
      );
      expect(
        cancelledResourceLanes,
        contains(DashboardLiveInteractionResourceLane.budgetAvatarPreview),
        reason:
            'The controller must explicitly release the old producer\'s '
            'resource lease before it starts Time work; the cache remains the '
            'only owner that decides whether an active lane can be cancelled.',
      );
      // The old physical Avatar ScrollEnd may arrive after the Time pointer.
      // It must remain cleanup-only: no Avatar Phase-B drain or resource
      // re-prime may regain foreground scheduling from that stale lifecycle.
      core.endBudgetAvatarMotion();
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'FOREGROUND_PRODUCER_STALE_MOTION_END' &&
              event.scope?.contains('producer=budgetAvatar') == true,
        ),
        isTrue,
      );

      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;
      final latestCandidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 2,
        base: origin,
      )!;
      core.beginSegmentedSummaryMotion();
      final firstAcceptance = core
          .navigateExperimentalTemporalComponentCandidate(
            candidate: candidate,
            component: DashboardTemporalAnchorComponent.day,
          );
      final latestAcceptance = core
          .navigateExperimentalTemporalComponentCandidate(
            candidate: latestCandidate,
            component: DashboardTemporalAnchorComponent.day,
          );
      await tester.pump();

      expect(firstAcceptance.isAcceptedSemanticIntent, isTrue);
      expect(latestAcceptance.isAcceptedSemanticIntent, isTrue);

      expect(
        core.visibleFrames.value,
        same(visibleBeforeTakeover),
        reason:
            'A cold non-empty Time target retains the last valid visual; it '
            'may not publish an unreadable preview before the exact binder.',
      );

      releaseTimeResource.complete();
      await tester.pump();
      await tester.pump();

      final promoted = core.visibleFrames.logBoxLane.value!;
      expect(
        promoted.queryKey,
        latestCandidate.temporalAnchor.sourceChildQueryKey,
        reason:
            'Two Time semantic targets in one render opportunity coalesce to '
            'the latest exact painter-ready candidate; the earlier target '
            'never becomes a 13 px visible frame.',
      );
      expect(cache.hasCompleteReadablePhaseAFor(promoted.logBox), isTrue);

      // Release/settle is allowed to arrive before the render surface reports
      // paint, but it cannot be the first moment Time becomes visible or the
      // authority for canonical navigation.  This exact Phase-A paint report
      // is intentionally independent from every Header expansion transition.
      core.settleExperimentalTemporalComponentCandidate(
        candidate: latestCandidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      expect(core.navigation.state, same(origin));
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(promoted));
      await tester.pump();

      expect(
        core.segmentedTargetPainted.value?.target.dayCursor,
        latestCandidate.dayCursor,
      );
      expect(core.navigation.state.dayCursor, latestCandidate.dayCursor);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'TIME_PHASE_A_CANDIDATE_TERMINAL' &&
              event.scope?.contains(
                    'terminalOutcome=coalescedBeforeReadiness',
                  ) ==
                  true,
        ),
        isTrue,
      );
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'TIME_PHASE_A_CANDIDATE_TERMINAL' &&
              event.scope?.contains('terminalOutcome=exactPhaseAPainted') ==
                  true,
        ),
        isTrue,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_LIVE_ROOT_MISS',
        ),
        isEmpty,
        reason:
            'A cold target is pending rather than entering visible authority '
            'as a painter-resource miss.',
      );

      // Header collapse/expand is an unrelated geometry owner. It cannot
      // promote a deferred target, transfer the timePreview lease, or emit a
      // second exact-paint acknowledgement after the resource completion has
      // already made the target visible.
      final paintedBeforeCollapse = core.segmentedTargetPainted.value;
      final terminalCountBeforeCollapse = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'TIME_PHASE_A_CANDIDATE_TERMINAL')
          .length;
      final resourceReadyCountBeforeCollapse = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'TM|LIVE_ROOT_RESOURCES_READY')
          .length;
      core.expansion.setProgress(core.metrics.collapseTravel);
      core.expansion.setProgress(0);
      await tester.pump();

      expect(core.visibleFrames.logBoxLane.value!.queryKey, promoted.queryKey);
      expect(core.segmentedTargetPainted.value, same(paintedBeforeCollapse));
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'TIME_PHASE_A_CANDIDATE_TERMINAL')
            .length,
        terminalCountBeforeCollapse,
      );
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'TM|LIVE_ROOT_RESOURCES_READY')
            .length,
        resourceReadyCountBeforeCollapse,
      );
    },
  );

  testWidgets(
    'RED FPA: an Avatar pointer supersedes Time foreground settlement while retaining the last Time visual until Avatar Phase A publishes',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _FocusSeedRepository(
          // The Time candidate remains a real prepared component crossing;
          // this bounded membership seed gives every nearby date one Avatar
          // category row so the post-takeover Header/amount/LogBox assertion
          // verifies a non-empty Avatar semantic transaction as well.
          rows: List<DashboardLedgerEntry>.generate(
            90,
            (index) => DashboardLedgerEntry(
              id: 'reverse-handoff-utility-$index',
              partnerId: 'reverse-handoff-partner',
              categoryId: 'utilities',
              direction: 'income',
              amountMinor: 500,
              bookedLocalEpochDay: 20600 + index,
              bookedLocalTimeMinutes: 600,
              partnerDisplayName: 'Utility partner',
              categoryDisplayName: 'Utilities',
              categoryColorId: 'fallback',
              categoryIconId: 'fallback',
            ),
            growable: false,
          ),
        ),
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final origin = core.navigation.state;
      final timeCandidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;
      core.beginSegmentedSummaryMotion();
      final timeAcceptance = core
          .navigateExperimentalTemporalComponentCandidate(
            candidate: timeCandidate,
            component: DashboardTemporalAnchorComponent.day,
          );
      expect(timeAcceptance.isExactLivePublication, isTrue);
      await tester.pump();
      final visibleTimeFrame = core.visibleFrames.value!;

      core.noteBudgetAvatarDirectPointerDown();

      expect(
        core.isMotionLaneActive(DashboardMotionLane.summaryShell),
        isFalse,
        reason:
            'A newer Avatar pointer releases the obsolete Time foreground '
            'lane before Avatar gesture recognition settles.',
      );
      expect(
        core.visibleFrames.value,
        same(visibleTimeFrame),
        reason:
            'Takeover never blanks the prior valid Time visual while Avatar '
            'waits to bind its own exact Phase-A target.',
      );

      // This is the obsolete Time lifecycle callback. It may not canonically
      // settle or overwrite the newer Avatar intent.
      core.settleExperimentalTemporalComponentCandidate(
        candidate: timeCandidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();
      expect(core.navigation.state, same(origin));

      core.beginBudgetAvatarMotion();
      expect(
        await core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
          publishDuringMotion: true,
          targetHandle: 17,
        ),
        isTrue,
      );
      await tester.pump();

      expect(core.focus.state?.category?.id, 'utilities');
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 500);
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        isNotEmpty,
      );
      expect(core.navigation.state, same(origin));
    },
  );

  test(
    'Budget avatar active-resource scene hit publishes the focused LogBox in the crossing epoch',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var genericPrepareCalls = 0;
      var activeResourceHits = 0;
      var activated = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {
          genericPrepareCalls += 1;
        },
        stageFromActiveResources: (_, {required retainViewportId}) {
          activeResourceHits += 1;
          return true;
        },
        activate: (_) => activated += 1,
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);
      final committedAmountBefore = core.visibleFrames.value!.amount.totalMinor;

      core.beginBudgetAvatarMotion();
      final published = await drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );

      expect(published, isTrue);
      expect(activeResourceHits, 1);
      expect(genericPrepareCalls, 0);
      expect(activated, 1);
      expect(core.focus.state?.category?.id, 'utilities');
      expect(
        core.visibleFrames.value!.amount.totalMinor,
        committedAmountBefore,
        reason:
            'The committed frame remains structurally stable through the '
            'ballistic crossing; the exact Phase-A lanes carry the new '
            'Avatar target atomically.',
      );
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        500,
        reason:
            'The LogBox/amount live lanes share the accepted focused target '
            'before the Avatar motion ends.',
      );
      core.endBudgetAvatarMotion();
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'a stale live generation is rejected before any scene stage starts',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var stages = 0;
      var discards = 0;
      var activations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {},
        stageFromActiveResources: (_, {required retainViewportId}) {
          stages += 1;
          return true;
        },
        discardStagedActiveResources: (_) => discards += 1,
        activate: (_) => activations += 1,
      );
      var publicationChecks = 0;

      final published = await core.installPreparedIndex(
        core.preparedIndex!,
        isEphemeralFocusPublication: true,
        shouldPublish: () => publicationChecks++ == 0,
      );

      expect(published, isFalse);
      expect(stages, 0);
      expect(discards, 0);
      expect(activations, 0);
    },
  );

  test(
    'an aggregate avatar tick cancels a provisional category amount before its scene commits',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final aggregateAmount =
          core.visibleFrames.amountLane.value!.amount.totalMinor;
      final sceneStarted = Completer<void>();
      final sceneGate = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) async {
          sceneStarted.complete();
          await sceneGate.future;
        },
        activate: (_) {},
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);

      final categoryPreview = drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      );
      await sceneStarted.future;
      expect(core.visibleFrames.amountLane.value!.amount.totalMinor, 500);

      expect(
        await drilldown.previewBudgetTarget(
          state: _budgetAggregatePreviewState(),
        ),
        isTrue,
      );
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        aggregateAmount,
        reason:
            'Aggregate owns the next discrete avatar tick even before the '
            'older category scene can complete.',
      );

      sceneGate.complete();
      expect(
        await categoryPreview,
        isTrue,
        reason:
            'The accepted category facet published its prepared first frame '
            'before the held rich scene; the later stale augmentation has no '
            'authority to overwrite the aggregate interaction.',
      );
      expect(core.focus.state, isNull);
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        aggregateAmount,
      );
    },
  );

  test('RED: an aggregate avatar crossing restores the prepared base LogBox in '
      'the same active-motion turn', () async {
    final repository = _FocusSeedRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
      initialDate: DateTime.utc(2026, 7, 1),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.income,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    final baseIndex = core.preparedIndex!;
    final drilldown = DashboardBudgetLogboxDrilldownCoordinator(core: core);

    expect(
      await drilldown.previewBudgetTarget(
        state: _budgetAvatarPreviewState(
          categoryId: 'utilities',
          displayName: 'Utilities',
        ),
      ),
      isTrue,
    );
    expect(core.preparedIndex, isNot(same(baseIndex)));

    core.setMotionLaneActive(DashboardMotionLane.budgetAvatar, true);
    final aggregate = drilldown.previewBudgetTarget(
      state: _budgetAggregatePreviewState(),
    );
    await Future<void>.microtask(() {});

    expect(core.focus.state, isNull);
    final aggregateLiveFrame = core.visibleFrames.logBoxLane.value!;
    expect(
      aggregateLiveFrame.preparedFrame.stableRowIdentities,
      baseIndex.frameFor(aggregateLiveFrame.scope).stableRowIdentities,
      reason:
          'The active Avatar producer may defer its one canonical index '
          'install, but the user-visible Phase-A LogBox must immediately '
          'switch away from the old category rows to the retained base rows.',
    );
    expect(
      core.visibleFrames.amountLane.value!.queryKey,
      aggregateLiveFrame.queryKey,
    );
    expect(
      core.visibleFrames.countLane.value!.queryKey,
      aggregateLiveFrame.queryKey,
    );

    core.setMotionLaneActive(DashboardMotionLane.budgetAvatar, false);
    expect(await aggregate, isTrue);
  });

  test(
    'clearing focus publishes its retained base frame before one noncritical scene augmentation',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final baseIndex = core.preparedIndex!;
      final baseWindow = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
      cache.activateWindow(baseWindow);
      core.recordInitialSceneWindowActivation(baseWindow);

      var genericPrepareCalls = 0;
      DashboardLogBoxSceneWindow? expectedBaseRestoreWindow;
      var baseRestorePrepareCalls = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          genericPrepareCalls += 1;
          final expected = expectedBaseRestoreWindow;
          if (expected != null &&
              window.identity == expected.identity &&
              window.payloads.length == expected.payloads.length &&
              window.payloads.every(
                (payload) => expected.payloads.any(
                  (required) => required.queryKey == payload.queryKey,
                ),
              )) {
            baseRestorePrepareCalls += 1;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        hasRetained: cache.hasRetainedWindow,
        retainActive: (window, {required retainedKey}) =>
            cache.retainActiveWindow(retainedKey: retainedKey, window: window),
        discardRetainedFocus: cache.discardRetainedFocusBaseWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      FluviDiagnosticLogger.clear();
      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );
      expect(genericPrepareCalls, 1);
      expect(cache.hasRetainedFocusBaseWindow, isTrue);
      final retained = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'FOCUS_BASE_SCENE_RETAINED',
      );
      expect(retained.scope, contains('retainedKeyDigest='));
      expect(
        retained.scope!.length,
        lessThan(180),
        reason:
            'The diagnostic must name the one ownership lease, not serialize '
            'the full retained scene-window payload list.',
      );
      final restoreState = core.navigation.appliedQueryCandidate(
        core.currentQuery.scopeFor(LedgerDirection.income),
        availability: DashboardTemporalAvailability.fromTemporalFilter(
          core.currentQuery.scopeFor(LedgerDirection.income).temporalFilter,
        ),
        coreRevision: core.preparedIndex!.coreRevision,
      );
      final restoreWindow = core.structuralPublicationSceneWindowFor(
        restoreState,
        indexOverride: baseIndex,
      );
      expect(cache.hasRetainedWindow(restoreWindow), isTrue);
      expectedBaseRestoreWindow = restoreWindow;

      FluviDiagnosticLogger.clear();
      expect(await core.clearAllEphemeralFocus(), isTrue);

      expect(
        baseRestorePrepareCalls,
        1,
        reason:
            'The direct clear publishes its prepared base frame immediately; '
            'one later rich-scene augmentation may rebuild after the old '
            'focused scene is no longer retained.',
      );
      expect(cache.hasRetainedFocusBaseWindow, isFalse);
      expect(cache.activeWindowIdentity, baseWindow.identity);
      expect(repository.prepareCalls, 1);
    },
  );

  test(
    'a newer committed base Query clears the temporary overlay before its new base publishes',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 1),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final oldBase = core.currentQuery.scopeFor(LedgerDirection.income);

      expect(
        await core.requestCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
        ),
        isTrue,
      );

      final newerBase = oldBase.copyWith(categoryIds: const <String>{'food'});
      expect(await core.applyQuery(newerBase), isTrue);

      expect(core.focus.state, isNull);
      expect(core.currentQuery.scopeFor(LedgerDirection.income), newerBase);
      expect(await core.clearAllEphemeralFocus(), isFalse);
      expect(core.currentQuery.scopeFor(LedgerDirection.income), newerBase);
    },
  );
  test(
    'RED E8M: an out-of-window direct Time year remains pending instead of canonically splitting authority',
    () async {
      final preparedWindowGate = Completer<void>();
      final repository = _FocusSeedRepository(
        prepareAfterBootstrapGate: preparedWindowGate,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(() {
        if (!preparedWindowGate.isCompleted) preparedWindowGate.complete();
        core.dispose();
      });
      await core.bootstrap();

      final origin = core.navigation.state;
      final originVisible = core.visibleFrames.value!;
      final originIndex = core.preparedIndex!;
      expect(originIndex.key.yearWindowStart, 2014);
      expect(originIndex.key.yearWindowEndInclusive, 2038);

      final target = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -16,
        base: origin,
      );
      expect(target, isNotNull);
      expect(target!.yearCursor, 2010);

      FluviDiagnosticLogger.clear();
      core.beginSegmentedSummaryMotion();
      DashboardSegmentedTargetAcceptance? acceptance;
      Object? thrown;
      try {
        acceptance = core.navigateExperimentalTemporalComponentCandidate(
          candidate: target,
          component: DashboardTemporalAnchorComponent.year,
        );
      } on Object catch (error) {
        thrown = error;
      }
      await pumpEventQueue();

      expect(
        thrown,
        isNull,
        reason:
            'A missing target frame must enter the bounded prepared-window '
            'transaction before any scene-window/frame materialization.',
      );
      if (thrown != null) return;
      expect(
        acceptance!.isAcceptedSemanticIntent,
        isTrue,
        reason:
            'An unavailable frame is a bounded prepared-window transition, '
            'not a rejected direct user intent.',
      );
      expect(
        core.navigation.state,
        same(origin),
        reason:
            'Until the gated exact target window exists, canonical navigation '
            'must retain the last coherent temporal authority.',
      );
      expect(core.visibleFrames.value, same(originVisible));
      expect(core.preparedIndex, same(originIndex));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SUMMARY_COMPONENT_LIVE_ROOT_MISS' &&
              event.scope?.contains('fallback=canonicalNavigation') == true,
        ),
        isEmpty,
      );

      preparedWindowGate.complete();
      await pumpEventQueue();
      await pumpEventQueue();
      core.frameCoalescer.flush();

      final rebased = core.preparedIndex!;
      expect(rebased.key.yearWindowStart, 1998);
      expect(rebased.key.yearWindowEndInclusive, 2022);
      final rebasedVisible = core.visibleFrames.value!;
      expect(
        rebasedVisible.queryKey,
        target.temporalAnchor.sourceChildQueryKey,
        reason:
            'The exact rebased target, not the old prepared window, must be '
            'the next visible Phase-A authority.',
      );
      expect(
        core.liveInteractions.frame?.temporalCandidate.effectiveScope,
        target.effectiveScope,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'TIME_PREPARED_WINDOW_REBASED',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'RED E8M: Avatar category and aggregate admission use the rebased Time base',
    () async {
      final preparedWindowGate = Completer<void>();
      final repository = _FocusSeedRepository(
        prepareAfterBootstrapGate: preparedWindowGate,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(() {
        if (!preparedWindowGate.isCompleted) preparedWindowGate.complete();
        core.dispose();
      });
      await core.bootstrap();

      final origin = core.navigation.state;
      final timeTarget = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -16,
        base: origin,
      )!;
      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: timeTarget,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isAcceptedSemanticIntent,
        isTrue,
      );
      preparedWindowGate.complete();
      await pumpEventQueue();
      await pumpEventQueue();
      core.frameCoalescer.flush();
      final timeFrame = core.visibleFrames.value!;
      core.settleExperimentalTemporalComponentCandidate(
        candidate: timeTarget,
        component: DashboardTemporalAnchorComponent.year,
      );
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(timeFrame));
      await pumpEventQueue();

      expect(
        core.navigation.state.yearCursor,
        2010,
        reason: FluviDiagnosticLogger.entries
            .map((event) => '${event.stage}:${event.scope}')
            .join('\n'),
      );
      expect(core.preparedIndex!.key.yearWindowStart, 1998);
      expect(core.preparedIndex!.key.yearWindowEndInclusive, 2022);

      core.beginBudgetAvatarMotion();
      expect(
        await core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
          targetHandle: 1,
          publishDuringMotion: true,
        ),
        isTrue,
        reason:
            'A category target after a Time window transition must derive '
            'against the exact rebased base rather than throw or silently '
            'reject its Phase-A admission.',
      );
      expect(core.focus.state?.category?.id, 'utilities');

      expect(
        await core.clearBudgetCategoryFocus(
          targetHandle: 0,
          publishDuringMotion: true,
        ),
        isTrue,
        reason:
            'The aggregate target follows the same exact rebased base and '
            'must not retain a stale Budget progress identity.',
      );
      expect(core.focus.state?.category, isNull);
      core.endBudgetAvatarMotion();
    },
  );
  test(
    'E8M: latest out-of-window Time target coalesces an older pending window rebase',
    () async {
      final preparedWindowGate = Completer<void>();
      final repository = _FocusSeedRepository(
        prepareAfterBootstrapGate: preparedWindowGate,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(() {
        if (!preparedWindowGate.isCompleted) preparedWindowGate.complete();
        core.dispose();
      });
      await core.bootstrap();

      final origin = core.navigation.state;
      final first = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -16,
        base: origin,
      )!;
      final latest = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -17,
        base: origin,
      )!;
      expect(first.yearCursor, 2010);
      expect(latest.yearCursor, 2009);

      FluviDiagnosticLogger.clear();
      core.beginSegmentedSummaryMotion();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: first,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isAcceptedSemanticIntent,
        isTrue,
      );
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: latest,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isAcceptedSemanticIntent,
        isTrue,
      );
      await pumpEventQueue();

      expect(core.navigation.state, same(origin));
      expect(
        core.visibleFrames.value!.queryKey,
        isNot(first.temporalAnchor.sourceChildQueryKey),
      );

      preparedWindowGate.complete();
      for (var index = 0; index < 4; index += 1) {
        await pumpEventQueue();
      }
      core.frameCoalescer.flush();

      final visible = core.visibleFrames.value!;
      expect(core.navigation.state.yearCursor, latest.yearCursor);
      expect(core.preparedIndex!.key.yearWindowStart, 1997);
      expect(core.preparedIndex!.key.yearWindowEndInclusive, 2021);
      expect(visible.queryKey, latest.temporalAnchor.sourceChildQueryKey);
      expect(
        core.liveInteractions.frame?.temporalCandidate.effectiveScope,
        latest.effectiveScope,
      );
      expect(
        core.liveInteractions.frame?.interactionPublicationEpoch,
        greaterThan(0),
      );
      expect(
        core.liveInteractions.frame?.producerLocalGeneration,
        greaterThan(0),
      );
      expect(
        core.liveInteractions.frame?.source,
        DashboardLiveInteractionSource.temporalSelector,
        reason:
            'A direct Time rebase retains its physical producer instead of '
            'being accepted later as a producer-less canonical fallback.',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'TIME_PREPARED_WINDOW_REBASED',
        ),
        hasLength(1),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'TIME_PREPARED_WINDOW_CANDIDATE_TERMINAL' &&
              event.queryKey ==
                  first.temporalAnchor.sourceChildQueryKey.value &&
              event.scope?.contains(
                    'terminalOutcome=coalescedBeforeWindowReady',
                  ) ==
                  true,
        ),
        hasLength(1),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SUMMARY_COMPONENT_LIVE_ROOT_MISS' &&
              event.scope?.contains('fallback=canonicalNavigation') == true,
        ),
        isEmpty,
      );
    },
  );

  test(
    'E8M: a rejected direct Time target cannot invoke canonical fallback or split authority',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.beginSegmentedSummaryMotion();
      final origin = core.navigation.state;
      final originVisible = core.visibleFrames.value!;
      final preparedTarget = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -1,
        base: origin,
      );
      expect(preparedTarget, isNotNull);
      final invalidRevisionTarget = preparedTarget!.copyWith(
        temporalAnchor: preparedTarget.temporalAnchor.copyWith(revision: 2),
      );

      FluviDiagnosticLogger.clear();
      final acceptance = core.navigateExperimentalTemporalComponentCandidate(
        candidate: invalidRevisionTarget,
        component: DashboardTemporalAnchorComponent.year,
      );
      await pumpEventQueue();

      expect(
        acceptance,
        DashboardSegmentedTargetAcceptance.rejectedNotPrepared,
      );
      expect(core.navigation.state, same(origin));
      expect(core.visibleFrames.value, same(originVisible));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_COMPONENT_LIVE_ROOT_MISS',
        ),
        isEmpty,
      );
      final rejection = FluviDiagnosticLogger.entries.lastWhere(
        (event) => event.stage == 'TIME_PHASE_A_DIRECT_REJECTED',
      );
      expect(rejection.scope, contains('canonicalFallback=false'));
      expect(
        rejection.scope,
        contains('visibleAuthority=retainedPreviousExact'),
      );
    },
  );

  test(
    'E8M: month targets remain exact after a bounded prepared-year-window rebase',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.beginSegmentedSummaryMotion();
      final targetYear = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.sum,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -13,
        base: core.navigation.state,
      );
      expect(targetYear, isNotNull);
      expect(targetYear!.yearCursor, 2013);

      FluviDiagnosticLogger.clear();
      expect(
        core
            .navigateExperimentalTemporalComponentCandidate(
              candidate: targetYear,
              component: DashboardTemporalAnchorComponent.year,
            )
            .isAcceptedSemanticIntent,
        isTrue,
      );
      await pumpEventQueue();
      core.frameCoalescer.flush();
      final yearFrame = core.visibleFrames.value!;
      core.recordLogBoxRenderExtent(_exactPaintSnapshot(yearFrame));
      core.settleExperimentalTemporalComponentCandidate(
        candidate: targetYear,
        component: DashboardTemporalAnchorComponent.year,
      );
      expect(core.navigation.state.yearCursor, 2013);
      expect(core.preparedIndex!.key.yearWindowStart, 2001);
      expect(core.preparedIndex!.key.yearWindowEndInclusive, 2025);

      var base = core.navigation.state;
      for (final month in <int>[2, 3, 4, 5, 6, 7, 8]) {
        final candidate = core.experimentalTemporalComponentOffsetCandidate(
          plane: TimePlane.sum,
          isRailOpen: true,
          component: DashboardTemporalAnchorComponent.month,
          offset: 1,
          base: base,
        );
        expect(candidate, isNotNull);
        expect(candidate!.yearCursor, 2013);
        expect(candidate.monthCursor.month, month);
        expect(
          core
              .navigateExperimentalTemporalComponentCandidate(
                candidate: candidate,
                component: DashboardTemporalAnchorComponent.month,
              )
              .isExactLivePublication,
          isTrue,
        );
        core.frameCoalescer.flush();
        final frame = core.visibleFrames.value!;
        expect(frame.queryKey, candidate.temporalAnchor.sourceChildQueryKey);
        core.recordLogBoxRenderExtent(_exactPaintSnapshot(frame));
        core.settleExperimentalTemporalComponentCandidate(
          candidate: candidate,
          component: DashboardTemporalAnchorComponent.month,
        );
        expect(core.navigation.state.yearCursor, 2013);
        expect(core.navigation.state.monthCursor.month, month);
        expect(core.visibleFrames.value!.queryKey, frame.queryKey);
        base = core.navigation.state;
      }

      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'TIME_PHASE_A_PREPARED_REJECTED' &&
              event.scope?.contains('preparedFrameUnavailable') == true,
        ),
        isEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SUMMARY_COMPONENT_LIVE_ROOT_MISS',
        ),
        isEmpty,
      );
    },
  );

  test(
    'E8M: Core preserves bounded temporal-base evidence when Avatar admission throws',
    () async {
      final repository = _FocusSeedRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 1, 29),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
        initialPlane: TimePlane.sum,
        initialRailOpen: true,
      );
      addTearDown(core.dispose);
      addTearDown(FluviDiagnosticLogger.clear);
      await core.bootstrap();
      core.beginBudgetAvatarMotion();
      FluviDiagnosticLogger.clear();

      await expectLater(
        core.requestBudgetCategoryFocus(
          const DashboardFocusFacet(id: 'utilities', displayName: 'Utilities'),
          targetHandle: 1,
          publishDuringMotion: true,
          onVisibleSemanticCommit: () {
            throw StateError('forced admission metadata failure');
          },
        ),
        throwsA(isA<StateError>()),
      );

      final evidence = FluviDiagnosticLogger.entries.lastWhere(
        (event) => event.stage == 'AVATAR_PHASE_A_ADMISSION_EXCEPTION_CORE',
      );
      expect(evidence.scope, contains('boundary=requestBudgetCategoryFocus'));
      expect(evidence.scope, contains('errorType=StateError'));
      expect(evidence.scope, contains('errorDigest='));
      expect(evidence.scope, contains('stackFingerprint='));
      expect(evidence.scope, contains('targetHandle=1'));
      expect(evidence.scope, contains('baseWindow=window:2014-2038'));
      expect(evidence.scope, contains('temporalScopeDigest='));
      expect(evidence.scope, contains('navigationScopeDigest='));
      expect(evidence.scope, contains('visibleQueryDigest='));
      expect(evidence.scope, contains('interactionEpoch='));
      expect(evidence.scope, contains('foregroundProducer=budgetAvatar'));
    },
  );
}

DashboardBudgetPresentationState _budgetAvatarPreviewState({
  required String categoryId,
  required String displayName,
}) {
  final target = DashboardBudgetTargetCatalog.fromCategories(
    <DashboardBudgetCategoryVisual>[
      DashboardBudgetCategoryVisual(
        id: categoryId,
        displayName: displayName,
        colorId: 'fallback',
        iconId: 'fallback',
      ),
    ],
  ).targetAtHandle(1);
  return DashboardBudgetPresentationState(
    items: const <DashboardBudgetTargetPresentationItem>[],
    selectedHandle: target.handle,
    liveSelection: DashboardBudgetLiveSelectionState.unavailable(
      direction: LedgerDirection.income,
      target: target,
      title: displayName,
    ),
    partition: const DashboardBudgetPartitionPresentation.unavailable(
      direction: LedgerDirection.income,
    ),
  );
}

DashboardBudgetPresentationState _budgetAggregatePreviewState() =>
    DashboardBudgetPresentationState(
      items: const <DashboardBudgetTargetPresentationItem>[],
      selectedHandle: 0,
      liveSelection: DashboardBudgetLiveSelectionState.unavailable(
        direction: LedgerDirection.income,
        target: const DashboardBudgetTarget.aggregate(),
        title: 'Összbevételi cél',
      ),
      partition: const DashboardBudgetPartitionPresentation.unavailable(
        direction: LedgerDirection.income,
      ),
    );

PreparedBudgetLimitSnapshot _focusBudgetSnapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    42,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['utilities', 'food'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 1,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

DashboardLogBoxRenderExtentSnapshot _exactPaintSnapshot(
  DashboardVisibleFrame frame,
) {
  final rows = frame.logBox.previewRowCount;
  return DashboardLogBoxRenderExtentSnapshot(
    presentation: DashboardLogBoxPresentationBinding.fromFrame(frame),
    payloadLaneMode: frame.mode,
    payloadViewportId: frame.logBox.viewportId,
    renderDomain: DashboardLogBoxRenderDomain.railPreview,
    renderedRowCount: rows,
    payloadRowCount: rows,
    drawableRowCount: rows,
    paintedRowCount: rows == 0 ? 0 : 1,
    renderedContentExtent: 120,
    previewPayloadRows: rows,
    previewSurfaceHeight: 120,
    committedCacheQueryKey: null,
    committedCacheGeneration: null,
    committedCacheReadyRows: 0,
    committedCacheDrawableExtent: 0,
    renderSurfaceHeight: 120,
    sliverScrollExtent: 120,
    viewportDimension: 120,
    minScrollExtent: 0,
    maxScrollExtent: 0,
    pixels: 0,
    isMismatch: false,
  );
}

DashboardLogBoxRenderExtentSnapshot _committedPromotionPaintSnapshot(
  DashboardVisibleFrame frame, {
  required int drawableRows,
}) {
  final previewRows = frame.logBox.previewRowCount;
  return DashboardLogBoxRenderExtentSnapshot(
    presentation: DashboardLogBoxPresentationBinding.fromFrame(frame),
    payloadLaneMode: DashboardVisibleMode.preview,
    payloadViewportId: frame.logBox.viewportId,
    renderDomain: DashboardLogBoxRenderDomain.committedVertical,
    renderedRowCount: drawableRows,
    payloadRowCount: previewRows,
    drawableRowCount: drawableRows,
    paintedRowCount: previewRows == 0 ? 0 : 8,
    renderedContentExtent: 9480,
    previewPayloadRows: previewRows,
    previewSurfaceHeight: 1490,
    committedCacheQueryKey: frame.queryKey.value,
    committedCacheGeneration: 3,
    committedCacheGeometryGeneration: 7,
    committedCacheReadyRows: previewRows,
    committedCacheDrawableExtent: 9480,
    renderSurfaceHeight: 9480,
    sliverScrollExtent: 9612,
    viewportDimension: 458,
    minScrollExtent: 0,
    maxScrollExtent: 9153,
    pixels: 0,
    isMismatch: false,
  );
}

void _installMindAmountDomain(
  DashboardCoreController core,
  LedgerDirection direction,
) {
  _publishMindAmountFacetPresentation(
    core,
    direction,
    const QueryMenuData(
      result: QueryMenuResultSummary(entryCount: 4, amountScaled100: 1800000),
      amountDomain: QueryMenuAmountDomain(
        minimumAmountScaled100: 100000,
        maximumAmountScaled100: 900000,
      ),
      availableMonths: <QueryMenuAvailableMonth>[],
      categories: <QueryMenuCategoryFacet>[],
      partners: <QueryMenuPartnerFacet>[],
    ),
  );
}

void _publishMindAmountFacetPresentation(
  DashboardCoreController core,
  LedgerDirection direction,
  QueryMenuData data,
) {
  core.currentQuery.publishFacetPresentationForScope(
    core.mindAmountDomainScopeFor(direction),
    data,
  );
}

DashboardLedgerEntry _mindYearEntry({
  required String id,
  required String direction,
  required String categoryId,
  required String partnerId,
  required int amount,
  required LocalDate date,
  int localTimeMinutes = 600,
}) => DashboardLedgerEntry(
  id: id,
  partnerId: partnerId,
  categoryId: categoryId,
  direction: direction,
  amountMinor: amount,
  bookedLocalEpochDay: date.epochDay,
  bookedLocalTimeMinutes: localTimeMinutes,
  partnerDisplayName: partnerId,
  categoryDisplayName: categoryId,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
);

Set<String> _coloredHeatmapDates(MindYearHeatmapFrame frame) => frame.days
    .where((day) => !day.isEmpty)
    .map(
      (day) =>
          '${day.date.year.toString().padLeft(4, '0')}-'
          '${day.date.month.toString().padLeft(2, '0')}-'
          '${day.date.day.toString().padLeft(2, '0')}',
    )
    .toSet();

class _FocusSeedRepository implements DashboardDataRuntimeRepository {
  _FocusSeedRepository({
    List<DashboardLedgerEntry>? rows,
    Completer<void>? prepareAfterBootstrapGate,
    this.withPreparedYearRows = false,
  }) : _rows = rows,
       _prepareAfterBootstrapGate = prepareAfterBootstrapGate;

  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final List<DashboardLedgerEntry>? _rows;
  final Completer<void>? _prepareAfterBootstrapGate;
  final bool withPreparedYearRows;
  var prepareCalls = 0;
  var committedPageReads = 0;

  List<DashboardLedgerEntry> get allRows => _rows ?? _defaultRows;

  static const List<DashboardLedgerEntry> _defaultRows = <DashboardLedgerEntry>[
    DashboardLedgerEntry(
      id: 'utility-row',
      partnerId: 'partner-utility',
      categoryId: 'utilities',
      direction: 'income',
      amountMinor: 500,
      bookedLocalEpochDay: 20636,
      bookedLocalTimeMinutes: 600,
      partnerDisplayName: 'Utility partner',
      categoryDisplayName: 'Utilities',
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
    ),
    DashboardLedgerEntry(
      id: 'food-row',
      partnerId: 'partner-food',
      categoryId: 'food',
      direction: 'income',
      amountMinor: 700,
      bookedLocalEpochDay: 20635,
      bookedLocalTimeMinutes: 600,
      partnerDisplayName: 'Food partner',
      categoryDisplayName: 'Food',
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
    ),
  ];

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    prepareCalls += 1;
    if (prepareCalls > 1 && _prepareAfterBootstrapGate != null) {
      await _prepareAfterBootstrapGate.future;
    }
    final base = withPreparedYearRows
        ? buildRuntimeTestIndex(
            revision: request.key.coreRevision,
            generation: token.generation,
            directionalQueries: request.directionalQueries,
            initialYear: request.initialYear,
            yearWindowRadius:
                request.key.yearWindowEndInclusive - request.initialYear,
            entryCountForScope: _preparedYearEntryCount,
            previewRowCountForScope: _preparedYearPreviewRowCount,
            deferredLogBoxes: true,
          )
        : await _empty.prepareIndex(request, token);
    final rows = allRows;
    return PreparedDashboardIndex.complete(
      key: base.key,
      frames: base.frames,
      catalogs: base.catalogs,
      scopes: <LedgerQueryKey, CurrentLedgerQueryScope>{
        for (final zero in base.compactZeroFrames.values)
          zero.queryKey: zero.scope,
        for (final frame in base.frames.values) frame.queryKey: frame.scope,
      },
      origins: base.origins,
      geometrySeedsByDirection:
          <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{
            for (final direction in LedgerDirection.values)
              direction: base.partitionFor(direction).verticalGeometrySeed,
          },
      focusMembershipSeedsByDirection:
          <LedgerDirection, DashboardFocusMembershipSeed>{
            for (final direction in LedgerDirection.values)
              direction: DashboardFocusMembershipSeed(
                _rowsFor(direction, rows),
              ),
          },
      generation: base.generation,
      contentDigest: base.contentDigest,
      preparedAt: base.preparedAt,
      buildMetrics: base.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    committedPageReads += 1;
    return _empty.readCommittedPage(request);
  }

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();

  static List<DashboardLedgerEntry> _rowsFor(
    LedgerDirection direction,
    List<DashboardLedgerEntry> rows,
  ) {
    final ordered = rows
        .where((entry) => entry.direction == direction.name)
        .toList(growable: false);
    ordered.sort((left, right) {
      final date = right.bookedLocalEpochDay.compareTo(
        left.bookedLocalEpochDay,
      );
      if (date != 0) return date;
      final time = right.bookedLocalTimeMinutes.compareTo(
        left.bookedLocalTimeMinutes,
      );
      if (time != 0) return time;
      return right.id.compareTo(left.id);
    });
    return ordered;
  }

  static int _preparedYearEntryCount(CurrentLedgerQueryScope scope) {
    if (scope.direction != LedgerDirection.income) return 0;
    return switch (scope.timeScope) {
      YearScope(year: 2026) => 42,
      YearScope(year: 2025) => 1,
      _ => 0,
    };
  }

  static int _preparedYearPreviewRowCount(CurrentLedgerQueryScope scope) =>
      _preparedYearEntryCount(scope).clamp(0, 24).toInt();
}

/// Test-only native snapshot capability: unlike the focus seed, it always
/// exposes the full ledger aggregate at handle zero. This proves that a Mind
/// MonthCard footer keeps the complete monthly close while its cells narrow.
final class _MindFooterRepository extends _FocusSeedRepository
    implements PreparedBudgetLimitSnapshotRepository {
  _MindFooterRepository({super.rows});

  @override
  Future<PreparedBudgetLimitSnapshot> prepareBudgetLimitSnapshot({
    required int coreRevision,
    required int yearWindowStart,
    required int yearWindowEndInclusive,
  }) async {
    final yearCount = yearWindowEndInclusive - yearWindowStart + 1;
    final sliceCount = 1 + yearCount + yearCount * 12;

    PreparedBudgetLimitDirectionBank bankFor(LedgerDirection direction) {
      int totalFor({int? year, int? month}) => allRows
          .where((entry) {
            if (entry.direction != direction.name) return false;
            final date = DateTime.utc(
              1970,
            ).add(Duration(days: entry.bookedLocalEpochDay));
            if (date.year < yearWindowStart ||
                date.year > yearWindowEndInclusive) {
              return false;
            }
            return (year == null || date.year == year) &&
                (month == null || date.month == month);
          })
          .fold<int>(0, (sum, entry) => sum + entry.amountMinor);

      return PreparedBudgetLimitDirectionBank(
        orderedCategoryIds: const <String>[],
        cells: List<PreparedBudgetLimitCell>.generate(sliceCount, (slice) {
          final actual = switch (slice) {
            0 => totalFor(),
            _ when slice <= yearCount => totalFor(
              year: yearWindowStart + slice - 1,
            ),
            _ => () {
              final monthOffset = slice - 1 - yearCount;
              return totalFor(
                year: yearWindowStart + monthOffset ~/ 12,
                month: monthOffset % 12 + 1,
              );
            }(),
          };
          return PreparedBudgetLimitCell(
            actualScaled100: actual,
            limitScaled100: null,
          );
        }, growable: false),
      );
    }

    return PreparedBudgetLimitSnapshot(
      coreRevision: coreRevision,
      yearWindowStart: yearWindowStart,
      yearWindowEndInclusive: yearWindowEndInclusive,
      incomeBank: bankFor(LedgerDirection.income),
      expenseBank: bankFor(LedgerDirection.expense),
    );
  }
}
