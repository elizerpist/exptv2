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
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_logbox_presentation_binding.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

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
      final applied = core.currentQuery.scopeFor(LedgerDirection.income);
      const domain = QueryMenuAmountDomain(
        minimumAmountScaled100: 100000,
        maximumAmountScaled100: 300000,
      );
      core.currentQuery.apply(
        applied,
        facetPresentation: const QueryMenuData(
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
      core.currentQuery.apply(
        applied,
        facetPresentation: const QueryMenuData(
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
      core.currentQuery.apply(
        applied,
        facetPresentation: const QueryMenuData(
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
    'b166 regression: a new Summary pointer retains an accepted unpainted semantic target while rejecting its stale rich acknowledgement',
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
      expect(core.navigation.state.dayCursor, candidate.dayCursor);

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
        candidate.dayCursor,
        reason:
            'A richer late paint acknowledgement may not move a semantically '
            'accepted release target back to the old month.',
      );
    },
  );

  testWidgets(
    'b166 regression: Summary pointer interruption keeps the latest accepted target over an older rich-painted preview',
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
      // a replacement crossing. The latest accepted B target remains the
      // semantic origin; a richer old A paint is diagnostic only.
      core.noteSummaryDirectPointerDown();
      await tester.pump();

      final retained = core.visibleFrames.value!;
      expect(core.navigation.state.dayCursor, unpainted.dayCursor);
      expect(retained.mode, DashboardVisibleMode.committed);
      expect(retained.queryKey, unpainted.temporalAnchor.sourceChildQueryKey);
      expect(core.segmentedTargetPainted.value, isNull);
      expect(repository.prepareCalls, 1);
    },
  );

  testWidgets(
    'b166 regression: parent-changing Summary interruption retains the latest accepted parent rather than restoring an older rich scene',
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
      expect(core.navigation.state.dayCursor, unpainted.dayCursor);
      expect(retained.mode, DashboardVisibleMode.committed);
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

final class _FocusSeedRepository implements DashboardDataRuntimeRepository {
  _FocusSeedRepository({
    List<DashboardLedgerEntry>? rows,
    Completer<void>? prepareAfterBootstrapGate,
  }) : _rows = rows,
       _prepareAfterBootstrapGate = prepareAfterBootstrapGate;

  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final List<DashboardLedgerEntry>? _rows;
  final Completer<void>? _prepareAfterBootstrapGate;
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
    if (prepareCalls > 1 && _prepareAfterBootstrapGate != null) {
      await _prepareAfterBootstrapGate.future;
    }
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
