import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_logbox_drilldown_coordinator.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_live_interaction_coordinator.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
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
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
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
      core.currentQuery.apply(
        applied,
        facetPresentation: const QueryMenuData(
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

  testWidgets(
    'time component crossings perform zero semantic work and commit only the latest settle candidate',
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
      final visiblePublishes = core.visibleFrames.visiblePublishCount;
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
        core.navigateExperimentalTemporalComponentCandidate(
          candidate: candidate,
          component: DashboardTemporalAnchorComponent.day,
        );
      }

      expect(core.navigation.state, same(origin));
      expect(core.visibleFrames.visiblePublishCount, visiblePublishes);
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'SCENE_WINDOW_PREPARE_STARTED' ||
              event.stage == 'QUERY_APPLY_STARTED',
        ),
        isEmpty,
      );

      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidates.last,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      expect(core.navigation.state.dayCursor, candidates.last.dayCursor);
      final summary = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'TM|FLIGHT_SUMMARY',
      );
      expect(summary.scope, contains('semanticTicks=${candidates.length}'));
      expect(summary.scope, contains('transientScenePrepares=0'));
      expect(summary.scope, contains('canonicalSettleCommits=1'));
      expect(repository.prepareCalls, 1);
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
    'Avatar transient crossings update only the prepared visual target and defer one focus/index publication to settle',
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
      final committedFrame = core.visibleFrames.value;
      final visiblePublishes = core.visibleFrames.visiblePublishCount;
      final indexPublishes = core.dataRuntime.publishedIndexCount;
      FluviDiagnosticLogger.clear();

      expect(
        await drilldown.previewBudgetTarget(targetHandle: foodHandle),
        isTrue,
      );

      expect(budget.value.selectedHandle, foodHandle);
      expect(budget.value.isTransientTargetPreview, isTrue);
      expect(core.focus.state, isNull);
      expect(core.visibleFrames.value, same(committedFrame));
      expect(core.visibleFrames.visiblePublishCount, visiblePublishes);
      expect(core.dataRuntime.publishedIndexCount, indexPublishes);
      expect(repository.prepareCalls, 1);
      expect(
        FluviDiagnosticLogger.entries
            .singleWhere((event) => event.stage == 'AV|TARGET_PREVIEW_BOUND')
            .scope,
        contains('indexPublished=false'),
      );

      expect(
        await drilldown.commitBudgetTargetHandle(
          targetHandle: foodHandle,
          source: 'avatarSettled',
        ),
        isTrue,
      );
      expect(budget.value.isTransientTargetPreview, isFalse);
      expect(core.focus.state?.category?.id, 'food');
      expect(core.visibleFrames.visiblePublishCount, visiblePublishes + 1);
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
        greaterThanOrEqualTo(2),
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

      expect(core.budgetAvatarFocusHotsetDiagnostics['promotions'], 8);
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
      expect(core.visibleFrames.value!.amount.totalMinor, 500);
      expect(
        core.visibleFrames.amountLane.value!.amount.totalMinor,
        500,
        reason:
            'The complete Ledger and the Summary amount have the same '
            'accepted focused target before the avatar motion ends.',
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
    expect(
      core.preparedIndex,
      same(baseIndex),
      reason:
          'The active avatar producer may defer rich scene augmentation, '
          'but it may never keep old category rows authoritative while '
          'the aggregate target is already selected.',
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

final class _FocusSeedRepository implements DashboardDataRuntimeRepository {
  _FocusSeedRepository({List<DashboardLedgerEntry>? rows}) : _rows = rows;

  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final List<DashboardLedgerEntry>? _rows;
  var prepareCalls = 0;
  var committedPageReads = 0;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    prepareCalls += 1;
    final base = await _empty.prepareIndex(request, token);
    final rows =
        _rows ??
        <DashboardLedgerEntry>[
          const DashboardLedgerEntry(
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
          const DashboardLedgerEntry(
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
            LedgerDirection.income: DashboardFocusMembershipSeed(rows),
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
}
