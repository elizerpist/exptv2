import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_logbox_drilldown_coordinator.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../../support/dashboard_render_resources.dart';
import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  test(
    'RED: a new non-empty rail-preview presentation epoch is structural paint identity',
    () {
      final previous = DashboardLogBoxPaintIdentity(
        payloadViewportId: 77,
        presentationEpoch: 4,
        sceneGeneration: 12,
        committedGeneration: 9,
        renderDomain: DashboardLogBoxRenderDomain.railPreview,
        rasterIdentity: Object(),
      );
      final next = DashboardLogBoxPaintIdentity(
        payloadViewportId: 77,
        presentationEpoch: 5,
        sceneGeneration: 12,
        committedGeneration: 9,
        renderDomain: DashboardLogBoxRenderDomain.railPreview,
        rasterIdentity: previous.rasterIdentity,
      );

      expect(next.requiresRepaintFrom(previous), isTrue);
    },
  );

  test('roundness changes repaint only the LogBox paint identity', () {
    final rasterIdentity = Object();
    final previous = DashboardLogBoxPaintIdentity(
      payloadViewportId: 77,
      presentationEpoch: 4,
      sceneGeneration: 12,
      committedGeneration: 9,
      renderDomain: DashboardLogBoxRenderDomain.railPreview,
      rasterIdentity: rasterIdentity,
      groupRadius: BorderRadius.circular(18),
    );
    final next = DashboardLogBoxPaintIdentity(
      payloadViewportId: 77,
      presentationEpoch: 4,
      sceneGeneration: 12,
      committedGeneration: 9,
      renderDomain: DashboardLogBoxRenderDomain.railPreview,
      rasterIdentity: rasterIdentity,
      groupRadius: BorderRadius.circular(25),
    );

    expect(next.requiresRepaintFrom(previous), isTrue);
  });

  test('row-height geometry changes repaint the LogBox paint identity', () {
    final rasterIdentity = Object();
    final previous = DashboardLogBoxPaintIdentity(
      payloadViewportId: 77,
      presentationEpoch: 4,
      sceneGeneration: 12,
      committedGeneration: 9,
      renderDomain: DashboardLogBoxRenderDomain.railPreview,
      rasterIdentity: rasterIdentity,
      rowHeight: 55,
    );
    final next = DashboardLogBoxPaintIdentity(
      payloadViewportId: 77,
      presentationEpoch: 4,
      sceneGeneration: 12,
      committedGeneration: 9,
      renderDomain: DashboardLogBoxRenderDomain.railPreview,
      rasterIdentity: rasterIdentity,
      rowHeight: 82.5,
    );

    expect(next.requiresRepaintFrom(previous), isTrue);
  });

  test('amount palette changes are paint-only LogBox identity inputs', () {
    final rasterIdentity = Object();
    final previous = DashboardLogBoxPaintIdentity(
      payloadViewportId: 77,
      presentationEpoch: 4,
      sceneGeneration: 12,
      committedGeneration: 9,
      renderDomain: DashboardLogBoxRenderDomain.railPreview,
      rasterIdentity: rasterIdentity,
      rowHeight: 55,
      incomeAmountColor: const Color(0xFF0F766E),
      expenseAmountColor: const Color(0xFFB42318),
    );
    final next = DashboardLogBoxPaintIdentity(
      payloadViewportId: previous.payloadViewportId,
      presentationEpoch: previous.presentationEpoch,
      sceneGeneration: previous.sceneGeneration,
      committedGeneration: previous.committedGeneration,
      renderDomain: previous.renderDomain,
      rasterIdentity: rasterIdentity,
      rowHeight: previous.rowHeight,
      incomeAmountColor: const Color(0xFF22C55E),
      expenseAmountColor: const Color(0xFFFF3E73),
    );

    expect(next.requiresRepaintFrom(previous), isTrue);
    expect(next.rowHeight, previous.rowHeight);
    expect(next.payloadViewportId, previous.payloadViewportId);
    expect(next.sceneGeneration, previous.sceneGeneration);
    expect(next.committedGeneration, previous.committedGeneration);
  });

  testWidgets(
    'roundness repaints the stable LogBox surface without replacing scroll or data state',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final scrollController = ScrollController();
      final roundness = DashboardCornerRoundnessController();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(sceneCache.dispose);
      addTearDown(scrollController.dispose);
      addTearDown(roundness.dispose);

      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final prepared = runtimeTestFrame(
        scope,
        revision: 1,
        entryCountOverride: 24,
        previewRowCount: 24,
      );
      final frame = _previewFrame(prepared, presentationEpoch: 1);
      await _prepareAndActivatePreviewScene(sceneCache, prepared.logBox);
      store.publish(frame);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardCornerRoundnessScope(
            controller: roundness,
            child: SizedBox(
              width: 378,
              height: 320,
              child: Stack(
                children: <Widget>[
                  CustomScrollView(
                    controller: scrollController,
                    slivers: const <Widget>[
                      SliverToBoxAdapter(child: SizedBox(height: 2400)),
                    ],
                  ),
                  Positioned.fill(
                    child: DashboardLogBoxRenderSurface(
                      visibleFrames: store,
                      scrollController: scrollController,
                      minimumHeight: 320,
                      preparedRasters: PreparedVectorAssetAtlas.instance
                          .logBoxRastersFor(3),
                      committedViewport: cache,
                      preparedSceneCache: sceneCache,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final position = scrollController.position;
      final frameBefore = store.value;
      final cacheGeneration = cache.renderGeneration;
      final extent = position.maxScrollExtent;

      roundness.setPosition(DashboardCornerSurfaceFamily.logBoxGroup, 1);
      await tester.pump();

      expect(identical(scrollController.position, position), isTrue);
      expect(store.value, same(frameBefore));
      expect(cache.renderGeneration, cacheGeneration);
      expect(position.maxScrollExtent, extent);
    },
  );

  testWidgets(
    'RED: prepared rail previews ignore old committed pixels across successive Query publications',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final scrollController = ScrollController();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(sceneCache.dispose);
      addTearDown(scrollController.dispose);

      final queryA = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final queryB = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      final queryC = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        partnerIds: const <String>{'merchant'},
      );
      final first = _previewFrame(
        runtimeTestFrame(
          queryA,
          revision: 1,
          entryCountOverride: 96,
          previewRowCount: 24,
        ),
        presentationEpoch: 1,
      );
      final second = _previewFrame(
        runtimeTestFrame(
          queryB,
          revision: 2,
          entryCountOverride: 4,
          previewRowCount: 4,
        ),
        presentationEpoch: 2,
      );
      final third = _previewFrame(
        runtimeTestFrame(
          queryC,
          revision: 3,
          entryCountOverride: 4,
          previewRowCount: 4,
        ),
        presentationEpoch: 3,
      );
      await _prepareAndActivatePreviewScene(sceneCache, first.logBox);
      store.publish(first);

      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 320,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: scrollController,
                  slivers: const <Widget>[
                    SliverToBoxAdapter(child: SizedBox(height: 2400)),
                  ],
                ),
                Positioned.fill(
                  child: DashboardLogBoxRenderSurface(
                    visibleFrames: store,
                    scrollController: scrollController,
                    minimumHeight: 320,
                    preparedRasters: PreparedVectorAssetAtlas.instance
                        .logBoxRastersFor(3),
                    committedViewport: cache,
                    preparedSceneCache: sceneCache,
                    onExtentPublished: snapshots.add,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      scrollController.jumpTo(1000);
      await tester.pump();

      await _prepareAndActivatePreviewScene(sceneCache, second.logBox);
      store.publish(second);
      await tester.pump();
      await tester.pump();

      final bSnapshot = snapshots.lastWhere(
        (snapshot) =>
            snapshot.presentation?.queryKey == second.queryKey &&
            snapshot.presentation?.presentationEpoch == 2,
      );
      expect(bSnapshot.renderDomain, DashboardLogBoxRenderDomain.railPreview);
      expect(bSnapshot.payloadRowCount, 4);
      expect(bSnapshot.drawableRowCount, 4);
      expect(
        bSnapshot.paintedRowCount,
        greaterThan(0),
        reason:
            'A rail preview is top-anchored; old committed pixels cannot '
            'cull its complete first page.',
      );
      expect(
        find.semantics.byLabel(second.logBox.flatItems.first.row.semanticLabel),
        findsOne,
        reason:
            'Paint and semantics must share the same top-anchored preview '
            'window.',
      );

      // Query chip removals can publish several exact prepared siblings in
      // succession. Every replacement has to be independently top-anchored,
      // even when the stable vertical position still contains stale pixels.
      scrollController.jumpTo(1280);
      await tester.pump();
      await _prepareAndActivatePreviewScene(sceneCache, third.logBox);
      store.publish(third);
      await tester.pump();
      await tester.pump();

      final cSnapshot = snapshots.lastWhere(
        (snapshot) =>
            snapshot.presentation?.queryKey == third.queryKey &&
            snapshot.presentation?.presentationEpoch == 3,
      );
      expect(cSnapshot.renderDomain, DashboardLogBoxRenderDomain.railPreview);
      expect(cSnapshot.payloadRowCount, 4);
      expect(cSnapshot.drawableRowCount, 4);
      expect(
        cSnapshot.paintedRowCount,
        greaterThan(0),
        reason:
            'A second prepared Query/chip publication must not need a '
            'gesture to repaint its exact preview.',
      );
      expect(
        find.semantics.byLabel(third.logBox.flatItems.first.row.semanticLabel),
        findsOne,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'RED: evicting a creator candidate cannot blank a prepared chip borrower before input',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final scrollController = ScrollController();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(store.dispose);
      addTearDown(committedViewport.dispose);
      addTearDown(sceneCache.dispose);
      addTearDown(scrollController.dispose);

      final beforeRemoval = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food', 'utilities'},
      );
      final afterRemoval = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'utilities'},
      );
      final creatorPayload = runtimeTestFrame(
        beforeRemoval,
        revision: 1,
        entryCountOverride: 4,
        previewRowCount: 4,
      ).logBox;
      // Query identity changes, but the prepared transaction presentation is
      // intentionally shared by identity across the creator and borrower.
      final borrowerPayload = creatorPayload.copyWith(
        queryKey: afterRemoval.key,
      );
      final borrowerPrepared = DashboardPreparedFrame.complete(
        scope: afterRemoval,
        parentQueryKey: dashboardPreparedParentQueryKey(afterRemoval),
        coreRevision: 1,
        totalMinor: 4,
        formattedAmount: '-4 Ft',
        entryCount: 4,
        formattedEntryCount: '4',
        logBox: borrowerPayload,
        presentationDigest: 41,
      );
      final borrowerFrame = _previewFrame(
        borrowerPrepared,
        presentationEpoch: 2,
      );
      final creatorWindow = DashboardLogBoxSceneWindow(
        identity: 'chip-creator-food-and-utilities',
        payloads: <DashboardLogViewportState>[creatorPayload],
      );
      final borrowerWindow = DashboardLogBoxSceneWindow(
        identity: 'chip-borrower-utilities',
        payloads: <DashboardLogViewportState>[borrowerPayload],
      );

      await sceneCache.prepareCandidateWindow(
        candidateKey: 'creator',
        window: creatorWindow,
        surfaceWidth: 378,
      );
      await sceneCache.prepareCandidateWindow(
        candidateKey: 'borrower',
        window: borrowerWindow,
        surfaceWidth: 378,
      );
      sceneCache.activateWindow(borrowerWindow);
      final borrowedScene = sceneCache.railCriticalSceneFor(borrowerPayload)!;
      final borrowedLayout = borrowedScene.rowFor(
        borrowerPayload.flatItems.first.row,
      )!;
      final borrowedHeader = borrowedScene.dayHeaderFor(
        borrowerPayload.flatItems.first.dayLabel!,
      )!;

      // This is the post-Apply hotset-eviction ordering from the device trace:
      // B is already the active exact scene while the original A creator loses
      // its retained slot. B must retain physical paragraph leases.
      sceneCache.discardCandidateWindow('creator');
      expect(borrowedLayout.title.debugDisposed, isFalse);
      expect(borrowedHeader.debugDisposed, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 320,
            child: Stack(
              children: <Widget>[
                CustomScrollView(
                  controller: scrollController,
                  slivers: const <Widget>[
                    SliverToBoxAdapter(child: SizedBox(height: 2400)),
                  ],
                ),
                Positioned.fill(
                  child: DashboardLogBoxRenderSurface(
                    visibleFrames: store,
                    scrollController: scrollController,
                    minimumHeight: 320,
                    preparedRasters: PreparedVectorAssetAtlas.instance
                        .logBoxRastersFor(3),
                    committedViewport: committedViewport,
                    preparedSceneCache: sceneCache,
                    onExtentPublished: snapshots.add,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      store.publish(borrowerFrame);
      // Deliberately no pointer, drag, scroll update, or ballistic event.
      await tester.pump();
      await tester.pump();

      final snapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == afterRemoval.key,
      );
      expect(snapshot.renderDomain, DashboardLogBoxRenderDomain.railPreview);
      expect(snapshot.payloadRowCount, 4);
      expect(snapshot.drawableRowCount, 4);
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(sceneCache.visiblePayloadWithoutPaintCount, 0);
      expect(sceneCache.textLayoutMissCount, 0);
    },
  );

  testWidgets(
    'RED: a complete filtered rail-preview scene paints in the first Query Apply frame without input',
    (tester) async {
      final repository = _NonEmptyQueryRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (target) {
                unawaited(core.requestForwardPageDemand(target));
              },
              onLoadPreviousPage: () {
                unawaited(core.loadPreviousPage());
              },
              onVerticalPointerDown: core.noteVerticalPointerDown,
              onVerticalScrollStarted: core.beginVerticalInteraction,
              onVerticalScrollEnded:
                  core.resumeSceneWindowMaintenanceAfterVerticalInput,
              currentQuery: core.currentQuery,
              onRemoveQueryCategory: core.removeAppliedQueryCategory,
              onRemoveQueryPartner: core.removeAppliedQueryPartner,
              onClearQuery: core.clearAppliedQuery,
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: snapshots.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Match the human sequence: the old dashboard has already exercised
      // committed vertical ownership before an exact filtered candidate is
      // applied. The new scope must still return to an immediately paintable
      // rail preview without requiring another gesture.
      await tester.fling(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -180),
        5000,
      );
      await tester.pumpAndSettle();
      expect(core.committedLogViewport.isVerticalRenderingActive, isTrue);

      final queryB = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 24, amountScaled100: 2400),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 2400,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[
          QueryMenuCategoryFacet(
            id: 'food',
            displayName: 'Food',
            colorId: 'fallback',
            iconId: 'fallback',
            entryCount: 24,
          ),
        ],
        partners: <QueryMenuPartnerFacet>[],
      );
      core.queryComposer.open(LedgerDirection.expense);
      core.queryComposer.updateDraft(scope: queryB);
      final applyIdentity = core.queryComposer.applyIdentity;
      final candidate = await core.prepareQueryDraft(
        queryB,
        composerIdentity: applyIdentity,
        facetPresentation: facets,
      );
      expect(candidate, isNotNull);
      expect(
        sceneCache.hasCandidateWindow(
          candidate!.currentParentInteractionWindow,
          candidateKey: candidate.cacheKey,
        ),
        isTrue,
      );
      expect(
        await core.applyQuery(
          queryB,
          facetPresentation: facets,
          composerApplyIdentity: applyIdentity,
        ),
        isTrue,
      );

      // Only the regular publication/render lifecycle is pumped. This test
      // intentionally sends no pointer, drag, scroll update or ballistic.
      for (var frame = 0; frame < 5; frame += 1) {
        await tester.pump();
      }

      final payload = core.visibleFrames.logBoxLane.value?.logBox;
      final presentation = core.visibleFrames.logBoxPresentationLane.value;
      final expectedPublishedKey = core.visibleFrames.value?.queryKey;
      final queryBSnapshots = snapshots
          .where(
            (value) => value.presentation?.queryKey == expectedPublishedKey,
          )
          .toList(growable: false);
      final scene = payload == null
          ? null
          : sceneCache.railCriticalSceneFor(payload);

      expect(expectedPublishedKey?.value, contains('categories:food'));
      expect(presentation?.queryKey, expectedPublishedKey);
      expect(payload?.queryKey, expectedPublishedKey);
      expect(queryBSnapshots, isNotEmpty);
      final snapshot = queryBSnapshots.last;
      expect(snapshot.renderDomain, DashboardLogBoxRenderDomain.railPreview);
      expect(payload?.previewRowCount, greaterThan(0));
      expect(snapshot.drawableRowCount, greaterThan(0));
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(scene, isNotNull);
      expect(scene!.rowFor(payload!.flatItems.first.row), isNotNull);
      expect(sceneCache.visiblePayloadWithoutPaintCount, 0);
    },
  );

  testWidgets(
    'RED LIVE-MIND: a warm amount drag paints exact production LogBox rows in one frame',
    (tester) async {
      final repository = _MindLivePreviewRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);
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
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: (snapshot) {
                // Match the production Dashboard parent: the visible viewport
                // both retains its test evidence and acknowledges the exact
                // post-layout root to the interaction coordinator.
                core.recordLogBoxRenderExtent(snapshot);
                snapshots.add(snapshot);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(await core.primeMindAmountPreviewDomain(), isTrue);
      expect(sceneCache.hasLiveInteractionResourceBank, isTrue);

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
        reason: sceneCache.report().toString(),
      );
      await tester.pump();

      final payload = core.visibleFrames.logBoxLane.value!.logBox;
      final scene = sceneCache.railCriticalSceneFor(payload);
      final snapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == payload.queryKey,
      );
      expect(payload.previewRowCount, 1);
      expect(payload.stableRowIdentities, <String>['amount-200000']);
      expect(scene, isNotNull);
      expect(scene!.rowFor(payload.flatItems.single.row), isNotNull);
      expect(snapshot.payloadRowCount, 1);
      expect(snapshot.drawableRowCount, 1);
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(sceneCache.textLayoutMissCount, 0);
      expect(sceneCache.visiblePayloadWithoutDrawableCount, 0);

      expect(
        core.previewMindAmountRange(
          const QueryAmountRangeValues(
            minimumScaled100: 100000,
            maximumScaled100: 300000,
            lowerScaled100: 250000,
            upperScaled100: 250000,
          ),
        ),
        isTrue,
      );
      await tester.pump();
      final emptyPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final emptySnapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == emptyPayload.queryKey,
      );
      expect(emptyPayload.previewRowCount, 0);
      expect(emptySnapshot.payloadRowCount, 0);
      expect(emptySnapshot.drawableRowCount, 0);
      expect(emptySnapshot.paintedRowCount, 0);
      expect(sceneCache.visiblePayloadWithoutDrawableCount, 0);

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
      await tester.pump();
      final restoredPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final restoredSnapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == restoredPayload.queryKey,
      );
      expect(restoredPayload.stableRowIdentities, <String>['amount-200000']);
      expect(restoredSnapshot.drawableRowCount, 1);
      expect(restoredSnapshot.paintedRowCount, greaterThan(0));
    },
  );

  testWidgets(
    'POST-DF1 RED LIVE-MIND: a held production RangeSlider drag paints exact LogBox rows before pointer-up',
    (tester) async {
      final canonicalIndexGate = Completer<void>();
      final repository = _MindLivePreviewRepository(
        canonicalIndexGate: canonicalIndexGate,
      );
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);
      final applied = core.currentQuery.scopeFor(LedgerDirection.income);
      const range = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 300000,
        lowerScaled100: 100000,
        upperScaled100: 300000,
      );
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
      var pointerUp = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: DashboardLogBoxViewport(
                    bounds: const DashboardBounds(
                      left: 0,
                      top: 28,
                      width: 378,
                      height: 28,
                    ),
                    visibleFrames: core.visibleFrames,
                    committedViewport: core.committedLogViewport,
                    preparedSceneCache: sceneCache,
                    preparedRasters: PreparedVectorAssetAtlas.instance
                        .logBoxRastersFor(3),
                    onLoadNextPage: (_) {},
                    performanceCounters: core.performanceCounters,
                    renderDiagnostics: core.renderReadinessDiagnostics,
                    renderDiagnosticContextProvider: () =>
                        core.renderDiagnosticContext,
                    onExtentPublished: (snapshot) {
                      core.recordLogBoxRenderExtent(snapshot);
                      snapshots.add(snapshot);
                    },
                  ),
                ),
                QueryAmountRangeControl(
                  values: range,
                  onInteractionStarted: core.beginMindAmountRangeInteraction,
                  onRangePreviewChanged: core.previewMindAmountRange,
                  onRangeCommitted: (values) {
                    pointerUp = true;
                    unawaited(core.commitMindAmountRange(values));
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(await core.primeMindAmountPreviewDomain(), isTrue);

      var slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      slider.onChangeStart!(slider.values);
      slider.onChanged!(const RangeValues(150000, 250000));
      await tester.pump();

      final firstPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final firstPaint = snapshots.lastWhere(
        (snapshot) => snapshot.presentation?.queryKey == firstPayload.queryKey,
      );
      expect(pointerUp, isFalse);
      expect(firstPayload.stableRowIdentities, <String>['amount-200000']);
      expect(firstPaint.drawableRowCount, 1);
      expect(firstPaint.paintedRowCount, greaterThan(0));
      expect(
        repository.prepareIndexCalls,
        1,
        reason:
            'A held Mind drag derives from the resident prepared base; it may '
            'not start a canonical index build for a move.',
      );

      // The physical pointer remains down while the next two semantic values
      // prove an exact empty result and a reverse crossing before release.
      slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      slider.onChanged!(const RangeValues(250000, 250000));
      await tester.pump();
      final emptyPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final emptyPaint = snapshots.lastWhere(
        (snapshot) => snapshot.presentation?.queryKey == emptyPayload.queryKey,
      );
      expect(pointerUp, isFalse);
      expect(emptyPayload.previewRowCount, 0);
      expect(emptyPaint.drawableRowCount, 0);
      expect(emptyPaint.paintedRowCount, 0);

      slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      slider.onChanged!(const RangeValues(150000, 250000));
      await tester.pump();
      final reversePayload = core.visibleFrames.logBoxLane.value!.logBox;
      final reversePaint = snapshots.lastWhere(
        (snapshot) =>
            snapshot.presentation?.queryKey == reversePayload.queryKey,
      );
      expect(pointerUp, isFalse);
      expect(reversePayload.stableRowIdentities, <String>['amount-200000']);
      expect(reversePaint.paintedRowCount, greaterThan(0));

      // Submit two raw values in one display frame. The shared one-slot
      // scheduler must discard the intermediate all-row value and paint the
      // newest exact one before the physical release.
      slider.onChanged!(const RangeValues(100000, 300000));
      slider.onChanged!(const RangeValues(100000, 100000));
      FluviDiagnosticLogger.clear();
      slider.onChangeEnd!(const RangeValues(100000, 100000));
      expect(pointerUp, isTrue);
      expect(
        FluviDiagnosticLogger.entries.map((event) => event.stage),
        contains('MIND|CANONICAL_COMMIT_AWAITING_PAINT'),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'QUERY_APPLY_STARTED',
        ),
        isEmpty,
        reason:
            'The last value was flushed at pointer-up and has not painted yet; '
            'canonical work may not race it before the next LogBox paint.',
      );

      await tester.pump();
      final finalPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final finalPaint = snapshots.lastWhere(
        (snapshot) => snapshot.presentation?.queryKey == finalPayload.queryKey,
      );
      expect(finalPayload.stableRowIdentities, <String>['amount-100000']);
      expect(finalPaint.paintedRowCount, greaterThan(0));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'MIND|LIVE_TARGET_PAINTED',
        ),
        hasLength(1),
      );
      await tester.pump();
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'QUERY_APPLY_STARTED',
        ),
        hasLength(1),
        reason:
            'Exactly one canonical commit begins only after the final exact '
            'range has a matching production LogBox paint acknowledgement.',
      );

      // Keep canonical Query/index persistence unavailable for the equivalent
      // of two physical seconds. The exact released preview is already
      // painted, so neither the visible rows nor the next pointer may wait for
      // this background gate.
      expect(repository.prepareIndexCalls, 2);
      await tester.pump(const Duration(seconds: 2));
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-100000'],
      );
      expect(
        find.byKey(const ValueKey('query-amount-range-slider')),
        findsOneWidget,
        reason:
            'Canonical amount-only reconciliation may not unmount the physical '
            'Mind control while its range domain is retained.',
      );

      final reentrantSlider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      reentrantSlider.onChangeStart!(reentrantSlider.values);
      reentrantSlider.onChanged!(const RangeValues(150000, 250000));
      await tester.pump();
      expect(
        core.visibleFrames.logBoxLane.value!.logBox.stableRowIdentities,
        <String>['amount-200000'],
        reason:
            'The next drag must immediately replace the retained live preview '
            'while the first canonical index build remains blocked.',
      );
      expect(repository.prepareIndexCalls, 2);
      canonicalIndexGate.complete();
      await tester.pump();
      await tester.pump();
    },
  );

  test(
    'POST-DF1 RED: a newer frame generation repaints even when query and epoch return to the same target',
    () {
      final previous = DashboardLogBoxPaintIdentity(
        payloadViewportId: 77,
        presentationEpoch: 4,
        presentationFrameGeneration: 10,
        sceneGeneration: 12,
        committedGeneration: 9,
        renderDomain: DashboardLogBoxRenderDomain.railPreview,
        rasterIdentity: Object(),
      );
      final next = DashboardLogBoxPaintIdentity(
        payloadViewportId: 77,
        presentationEpoch: 4,
        presentationFrameGeneration: 12,
        sceneGeneration: 12,
        committedGeneration: 9,
        renderDomain: DashboardLogBoxRenderDomain.railPreview,
        rasterIdentity: previous.rasterIdentity,
      );

      expect(next.requiresRepaintFrom(previous), isTrue);
    },
  );

  testWidgets(
    'RED LIVE-AVATAR: a prepared target crossing paints its exact production LogBox root in one frame',
    (tester) async {
      final repository = _MindLivePreviewRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: (snapshot) {
                // Match the production Dashboard parent: the visible viewport
                // both retains its test evidence and acknowledges the exact
                // post-layout root to the interaction coordinator.
                core.recordLogBoxRenderExtent(snapshot);
                snapshots.add(snapshot);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final aggregateQueryKey = core.visibleFrames.logBoxLane.value!.queryKey;
      const utilities = DashboardFocusFacet(
        id: 'utilities',
        displayName: 'Utilities',
      );
      core.primeBudgetAvatarFocusHotset(const <DashboardFocusFacet>[utilities]);
      for (
        var frame = 0;
        frame < 20 && !core.budgetAvatarLiveRootReady.value;
        frame += 1
      ) {
        await tester.pump();
      }
      expect(sceneCache.hasLiveInteractionResourceBank, isTrue);
      expect(core.budgetAvatarLiveRootReady.value, isTrue);
      FluviDiagnosticLogger.clear();

      core.beginBudgetAvatarMotion();
      expect(
        await core.requestBudgetCategoryFocus(
          utilities,
          publishDuringMotion: true,
          targetHandle: 1,
        ),
        isTrue,
        reason: sceneCache.report().toString(),
      );
      await tester.pump();

      final payload = core.visibleFrames.logBoxLane.value!.logBox;
      final scene = sceneCache.railCriticalSceneFor(payload);
      final snapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == payload.queryKey,
      );
      expect(payload.queryKey.value, contains('categories:utilities'));
      expect(payload.previewRowCount, greaterThan(0));
      expect(scene, isNotNull);
      for (final item in payload.flatItems) {
        expect(scene!.rowFor(item.row), isNotNull);
      }
      expect(snapshot.payloadRowCount, payload.previewRowCount);
      expect(snapshot.drawableRowCount, payload.previewRowCount);
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(sceneCache.textLayoutMissCount, 0);
      expect(sceneCache.visiblePayloadWithoutDrawableCount, 0);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|VISIBLE_PUBLICATION_ACCEPTED',
        ),
        hasLength(1),
        reason:
            'The production focus lane must record the exact accepted Avatar '
            'identity before its final settle callback.',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED',
        ),
        hasLength(1),
        reason:
            'The extent report must distinguish a selected Avatar from its '
            'matching production LogBox root actually painting.',
      );

      expect(
        await core.clearBudgetCategoryFocus(
          targetHandle: 0,
          publishDuringMotion: true,
        ),
        isTrue,
        reason: sceneCache.report().toString(),
      );
      await tester.pump();
      final aggregatePayload = core.visibleFrames.logBoxLane.value!.logBox;
      final aggregateScene = sceneCache.railCriticalSceneFor(aggregatePayload);
      final aggregateSnapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == aggregatePayload.queryKey,
      );
      expect(aggregatePayload.queryKey, aggregateQueryKey);
      expect(aggregatePayload.previewRowCount, 0);
      expect(aggregateScene, isNotNull);
      for (final item in aggregatePayload.flatItems) {
        expect(aggregateScene!.rowFor(item.row), isNotNull);
      }
      expect(
        aggregateSnapshot.drawableRowCount,
        aggregatePayload.previewRowCount,
      );
      expect(aggregateSnapshot.paintedRowCount, 0);
      expect(sceneCache.textLayoutMissCount, 0);
      expect(sceneCache.visiblePayloadWithoutDrawableCount, 0);
      core.endBudgetAvatarMotion();
    },
  );

  testWidgets(
    'POST-DF1 RED LIVE-AVATAR: a ballistic production rail crossing paints matching Budget and LogBox state before settle',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _MindLivePreviewRepository(),
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
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
      final snapshot = _budgetSnapshotFor(categories.value);
      final budget = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: core.visibleFrames,
        liveInteractions: core.liveInteractions,
        transactionDirection: core.transactionDirection,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: core.logicalAsOfDate,
      );
      final drilldown = DashboardBudgetLogboxDrilldownCoordinator(
        core: core,
        presentation: budget,
      );
      final renderSnapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      final settled = <int>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      addTearDown(categories.dispose);
      addTearDown(budget.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: DashboardLogBoxViewport(
                    bounds: const DashboardBounds(
                      left: 0,
                      top: 28,
                      width: 378,
                      height: 28,
                    ),
                    visibleFrames: core.visibleFrames,
                    committedViewport: core.committedLogViewport,
                    preparedSceneCache: sceneCache,
                    preparedRasters: PreparedVectorAssetAtlas.instance
                        .logBoxRastersFor(3),
                    onLoadNextPage: (_) {},
                    performanceCounters: core.performanceCounters,
                    renderDiagnostics: core.renderReadinessDiagnostics,
                    renderDiagnosticContextProvider: () =>
                        core.renderDiagnosticContext,
                    onExtentPublished: (extent) {
                      core.recordLogBoxRenderExtent(extent);
                      renderSnapshots.add(extent);
                    },
                  ),
                ),
                SizedBox(
                  height: BudgetTargetAvatarRail.selectedInputSurfaceHeight,
                  child: BudgetTargetAvatarRail(
                    presentation: budget,
                    onTargetPreviewAccepted: (targetHandle) => drilldown
                        .previewBudgetTarget(targetHandle: targetHandle),
                    onTargetSettled: (targetHandle) {
                      settled.add(targetHandle);
                      unawaited(
                        drilldown.commitBudgetTargetHandle(
                          targetHandle: targetHandle,
                          source: 'avatarSettled',
                        ),
                      );
                    },
                    onPreparedTargetHotsetRequested:
                        drilldown.primeBudgetTargetHotset,
                    liveTargetReadiness: drilldown.liveTargetReadiness,
                    onMotionActiveChanged: (active) {
                      if (active) {
                        core.beginBudgetAvatarMotion();
                      } else {
                        core.endBudgetAvatarMotion();
                      }
                    },
                    onDirectInputStarted:
                        core.noteBudgetAvatarDirectPointerDown,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      for (
        var frame = 0;
        frame < 32 && !core.budgetAvatarLiveRootReady.value;
        frame += 1
      ) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        core.budgetAvatarLiveRootReady.value,
        isTrue,
        reason: sceneCache.report().toString(),
      );
      FluviDiagnosticLogger.clear();

      await tester.fling(
        find.byKey(const ValueKey('budget-target-avatar-carousel')),
        const Offset(-240, 0),
        2600,
      );
      for (var frame = 0; frame < 24; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final ballisticAccepted = FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'AV|PREVIEW_ACCEPTED' &&
              (event.scope?.contains('phase=ballistic') ?? false),
        );
        final matchingLogBoxPaint = FluviDiagnosticLogger.entries.any(
          (event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED',
        );
        if (ballisticAccepted && matchingLogBoxPaint) break;
      }

      expect(settled, isEmpty);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|BALLISTIC_STARTED',
        ),
        isNotEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'AV|PREVIEW_ACCEPTED' &&
              (event.scope?.contains('phase=ballistic') ?? false),
        ),
        isNotEmpty,
        reason:
            'A semantic crossing must enter the exact production focus lane '
            'while the Avatar carousel is still ballistic.',
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED',
        ),
        isNotEmpty,
        reason:
            'The accepted ballistic target must select, lay out and paint its '
            'own LogBox root before the final settle callback.',
      );
      expect(renderSnapshots, isNotEmpty);
      expect(budget.value.selectedHandle, isNot(0));
      expect(
        core.visibleFrames.logBoxLane.value!.scope.categoryIds,
        isNotEmpty,
        reason:
            'Budget Header selection and the LogBox query must share the '
            'same focused Avatar target before settle.',
      );

      // Let the remaining ballistic frames finish one at a time. New matching
      // roots are legitimate while physics is still moving; the assertion is
      // about the terminal callback and the frames immediately after it.
      for (var frame = 0; frame < 120 && settled.isEmpty; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(settled, hasLength(1));
      final paintCountAtSettle = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED')
          .length;
      await tester.pump();
      await tester.pump();
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED')
            .length,
        paintCountAtSettle,
        reason:
            'Avatar settle may promote ownership but cannot introduce the '
            'first matching LogBox paint.',
      );
    },
  );

  testWidgets(
    'RED LIVE-TIME: a segmented component crossing paints exact production LogBox rows in one frame',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _NonEmptyQueryRepository(),
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);
      final origin = core.navigation.state;
      final candidate = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: origin,
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: (snapshot) {
                // Match the production Dashboard parent: the visible viewport
                // both retains its test evidence and acknowledges the exact
                // post-layout root to the interaction coordinator.
                core.recordLogBoxRenderExtent(snapshot);
                snapshots.add(snapshot);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final liveHotset = core.railInteractionSceneWindowFor(origin);
      await sceneCache.prepareWindow(
        window: liveHotset,
        surfaceWidth: sceneCache.surfaceWidth,
      );
      sceneCache.activateWindow(liveHotset);
      core.recordInitialSceneWindowActivation(liveHotset);
      final prepareCountBeforeCrossing = sceneCache.scenePrepareNewCount;
      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      await tester.pump();

      final payload = core.visibleFrames.logBoxLane.value!.logBox;
      final scene = sceneCache.railCriticalSceneFor(payload);
      final snapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == payload.queryKey,
      );
      expect(payload.queryKey, candidate.temporalAnchor.sourceChildQueryKey);
      expect(payload.previewRowCount, greaterThan(0));
      expect(
        scene,
        isNotNull,
        reason:
            'payload=${payload.queryKey.value}/${payload.viewportId} '
            'cache=${sceneCache.report()}',
      );
      expect(snapshot.drawableRowCount, payload.previewRowCount);
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(sceneCache.textLayoutMissCount, 0);
      expect(sceneCache.scenePrepareNewCount, prepareCountBeforeCrossing);
    },
  );

  testWidgets(
    'RED REENTRANT-TIME: populated-empty-populated reversal repaints before settle',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _TimeReversalRepository(),
        initialDate: DateTime.utc(2025, 4, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);
      final origin = core.navigation.state;
      final empty2024 = core.experimentalTemporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.year,
        offset: -1,
        base: origin,
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: snapshots.add,
            ),
          ),
        ),
      );
      await tester.pump();
      final originHotset = core.railInteractionSceneWindowFor(origin);
      final liveHotset = originHotset.union(
        core.railInteractionSceneWindowFor(empty2024),
        coverageIdentity: originHotset.coverageIdentity,
      );
      await sceneCache.prepareWindow(
        window: liveHotset,
        surfaceWidth: sceneCache.surfaceWidth,
      );
      sceneCache.activateWindow(liveHotset);
      core.recordInitialSceneWindowActivation(liveHotset);

      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalComponentCandidate(
        candidate: empty2024,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();
      final emptyPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final emptySnapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == emptyPayload.queryKey,
      );
      expect(empty2024.yearCursor, 2024);
      expect(
        emptyPayload.queryKey,
        empty2024.temporalAnchor.sourceChildQueryKey,
      );
      expect(emptyPayload.previewRowCount, 0);
      expect(emptySnapshot.drawableRowCount, 0);
      expect(sceneCache.visiblePayloadWithoutDrawableCount, 0);

      core.navigateExperimentalTemporalComponentCandidate(
        candidate: origin,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();
      final restoredPayload = core.visibleFrames.logBoxLane.value!.logBox;
      final restoredSnapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == restoredPayload.queryKey,
      );
      expect(origin.yearCursor, 2025);
      expect(
        restoredPayload.queryKey,
        origin.temporalAnchor.sourceChildQueryKey,
      );
      expect(restoredPayload.previewRowCount, greaterThan(0));
      expect(
        restoredSnapshot.drawableRowCount,
        restoredPayload.previewRowCount,
      );
      expect(restoredSnapshot.paintedRowCount, greaterThan(0));

      final visibleBeforeSettle = core.visibleFrames.value;
      final publishesBeforeSettle = core.visibleFrames.visiblePublishCount;
      core.settleExperimentalTemporalComponentCandidate(
        candidate: origin,
        component: DashboardTemporalAnchorComponent.year,
      );
      await tester.pump();
      expect(core.visibleFrames.value, same(visibleBeforeSettle));
      expect(core.visibleFrames.visiblePublishCount, publishesBeforeSettle);
      expect(sceneCache.textLayoutMissCount, 0);
    },
  );

  testWidgets(
    'RED LIVE-LEVEL: a segmented level crossing paints an armed exact production root in one frame',
    (tester) async {
      final core = DashboardCoreController(
        dataRepository: _NonEmptyQueryRepository(),
        initialDate: DateTime.utc(2026, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.expense,
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(core.dispose);
      addTearDown(sceneCache.dispose);
      await core.bootstrap();
      await _attachAndActivateInitialScene(core, sceneCache);
      final target = core.presentation.temporalCandidate(
        plane: TimePlane.year,
        isRailOpen: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: core.visibleFrames,
              committedViewport: core.committedLogViewport,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: core.performanceCounters,
              renderDiagnostics: core.renderReadinessDiagnostics,
              renderDiagnosticContextProvider: () =>
                  core.renderDiagnosticContext,
              onExtentPublished: snapshots.add,
            ),
          ),
        ),
      );
      await tester.pump();
      var armedLevels = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      for (final level in <({TimePlane plane, bool isRailOpen})>[
        (plane: TimePlane.sum, isRailOpen: false),
        (plane: TimePlane.year, isRailOpen: false),
        (plane: TimePlane.month, isRailOpen: false),
        (plane: TimePlane.month, isRailOpen: true),
      ]) {
        final candidate = core.presentation.temporalCandidate(
          plane: level.plane,
          isRailOpen: level.isRailOpen,
        );
        armedLevels = armedLevels.union(
          core.structuralPublicationSceneWindowFor(candidate),
          coverageIdentity: armedLevels.coverageIdentity,
        );
      }
      await sceneCache.prepareWindow(
        window: armedLevels,
        surfaceWidth: sceneCache.surfaceWidth,
      );
      sceneCache.activateWindow(armedLevels);
      core.recordInitialSceneWindowActivation(armedLevels);
      final prepareCountBeforeCrossing = sceneCache.scenePrepareNewCount;

      core.beginSegmentedSummaryMotion();
      core.navigateExperimentalTemporalSelection(
        plane: TimePlane.year,
        isRailOpen: false,
      );
      await tester.pump();

      final payload = core.visibleFrames.logBoxLane.value!.logBox;
      final scene = sceneCache.railCriticalSceneFor(payload);
      final snapshot = snapshots.lastWhere(
        (value) => value.presentation?.queryKey == payload.queryKey,
      );
      expect(payload.queryKey, target.parentQueryKey);
      expect(payload.previewRowCount, greaterThan(0));
      expect(scene, isNotNull);
      expect(snapshot.drawableRowCount, payload.previewRowCount);
      expect(snapshot.paintedRowCount, greaterThan(0));
      expect(sceneCache.textLayoutMissCount, 0);
      expect(sceneCache.scenePrepareNewCount, prepareCountBeforeCrossing);
    },
  );

  testWidgets(
    'RED: a new non-empty rail-preview presentation epoch repaints without a scroll notification',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final sceneCache = DashboardLogBoxPreparedSceneCache();
      final counters = DashboardPerformanceCounters();
      final snapshots = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(sceneCache.dispose);

      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final prepared = runtimeTestFrame(
        scope,
        revision: 1,
        entryCountOverride: 24,
        previewRowCount: 24,
      );
      final first = _previewFrame(prepared, presentationEpoch: 1);
      final second = _previewFrame(prepared, presentationEpoch: 2);
      store.publish(first);
      final window = DashboardLogBoxSceneWindow(
        identity: 'presentation-epoch:${prepared.queryKey.value}',
        payloads: <DashboardLogViewportState>[prepared.logBox],
      );
      await sceneCache.prepareWindow(window: window, surfaceWidth: 378);
      sceneCache.activateWindow(window);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 700,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedSceneCache: sceneCache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: counters,
              onExtentPublished: snapshots.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paintedBefore = counters.value(
        DashboardPerformanceMetric.logVisibleSlotPaint,
      );
      expect(paintedBefore, greaterThan(0));

      // This is deliberately a presentation-only publish. The payload and
      // offset remain stable, so only an explicit paint identity can require
      // the new first presentation to paint.
      expect(store.publish(second), isFalse);
      await tester.pump();
      await tester.pump();

      final secondSnapshot = snapshots.lastWhere(
        (snapshot) => snapshot.presentation?.presentationEpoch == 2,
      );
      expect(
        counters.value(DashboardPerformanceMetric.logVisibleSlotPaint),
        greaterThan(paintedBefore),
      );
      expect(
        secondSnapshot.renderDomain,
        DashboardLogBoxRenderDomain.railPreview,
      );
      expect(secondSnapshot.drawableRowCount, 24);
      expect(secondSnapshot.paintedRowCount, greaterThan(0));
    },
  );
}

Future<void> _prepareAndActivatePreviewScene(
  DashboardLogBoxPreparedSceneCache cache,
  DashboardLogViewportState payload,
) async {
  final window = DashboardLogBoxSceneWindow(
    identity: 'preview:${payload.queryKey.value}:${payload.viewportId}',
    payloads: <DashboardLogViewportState>[payload],
  );
  await cache.prepareWindow(window: window, surfaceWidth: 378);
  cache.activateWindow(window);
}

DashboardVisibleFrame _previewFrame(
  DashboardPreparedFrame prepared, {
  required int presentationEpoch,
}) => DashboardVisibleFrame.fromPrepared(
  prepared,
  parentQueryKey: prepared.parentQueryKey,
  plane: TimePlane.month,
  railOpen: false,
  semanticIndex: 0,
  childLabel: '2026. július',
  navigationEpoch: presentationEpoch,
  presentationEpoch: presentationEpoch,
  frameGeneration: presentationEpoch,
  mode: DashboardVisibleMode.preview,
);

Future<void> _attachAndActivateInitialScene(
  DashboardCoreController core,
  DashboardLogBoxPreparedSceneCache cache,
) async {
  final initial = core.railCriticalSceneWindow();
  await cache.prepareWindow(window: initial, surfaceWidth: 378);
  cache.activateWindow(initial);
  core.recordInitialSceneWindowActivation(initial);
  core.attachLogBoxSceneWindowCoordinator(
    prepare: (window, {required retainViewportId}) => cache.prepareWindow(
      window: window,
      retainViewportId: retainViewportId,
      surfaceWidth: 378,
    ),
    prepareCandidate:
        (window, {required candidateKey, required retainViewportId}) =>
            cache.prepareCandidateWindow(
              candidateKey: candidateKey,
              window: window,
              retainViewportId: retainViewportId,
              surfaceWidth: 378,
            ),
    discardCandidate: cache.discardCandidateWindow,
    hasCandidate: cache.hasCandidateWindow,
    setCandidateHotset: cache.setProtectedCandidateKeys,
    planCandidateHotset: cache.admitCandidateHotset,
    prepareLiveInteractionResources:
        (window, {required retainedKey, required retainViewportId}) =>
            cache.prepareLiveInteractionResourceWindow(
              resourceKey: retainedKey,
              window: window,
              retainViewportId: retainViewportId,
              surfaceWidth: cache.surfaceWidth,
              devicePixelRatio: cache.devicePixelRatio ?? 1,
            ),
    hasLiveInteractionResources: (window, {required candidateKey}) => cache
        .hasLiveInteractionResourceWindow(window, resourceKey: candidateKey),
    stageLiveInteractionFromPreparedResources:
        (window, {required retainViewportId}) =>
            cache.stageLivePreviewWindowFromPreparedResources(window),
    stageFromActiveResources: (window, {required retainViewportId}) =>
        cache.stageWindowFromActiveResources(window),
    discardStagedActiveResources: cache.discardStagedActiveResourceWindow,
    activate: cache.activateWindow,
    cancel: cache.cancelInFlightPreparation,
    report: cache.report,
  );
}

PreparedBudgetLimitSnapshot _budgetSnapshotFor(List<FluviCategory> categories) {
  final targetCount = categories.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * targetCount,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: categories.map((category) => category.id).toList(),
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

final class _MindLivePreviewRepository
    implements DashboardDataRuntimeRepository {
  _MindLivePreviewRepository({this.canonicalIndexGate});

  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  final Completer<void>? canonicalIndexGate;
  int prepareIndexCalls = 0;

  static const List<DashboardLedgerEntry> _rows = <DashboardLedgerEntry>[
    DashboardLedgerEntry(
      id: 'amount-100000',
      partnerId: 'partner-1',
      categoryId: 'utilities',
      direction: 'income',
      amountMinor: 100000,
      bookedLocalEpochDay: 20636,
      bookedLocalTimeMinutes: 600,
      partnerDisplayName: 'Partner 1',
      categoryDisplayName: 'Utilities',
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
    ),
    DashboardLedgerEntry(
      id: 'amount-200000',
      partnerId: 'partner-2',
      categoryId: 'utilities',
      direction: 'income',
      amountMinor: 200000,
      bookedLocalEpochDay: 20635,
      bookedLocalTimeMinutes: 600,
      partnerDisplayName: 'Partner 2',
      categoryDisplayName: 'Utilities',
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
    ),
    DashboardLedgerEntry(
      id: 'amount-300000',
      partnerId: 'partner-3',
      categoryId: 'utilities',
      direction: 'income',
      amountMinor: 300000,
      bookedLocalEpochDay: 20634,
      bookedLocalTimeMinutes: 600,
      partnerDisplayName: 'Partner 3',
      categoryDisplayName: 'Utilities',
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
    prepareIndexCalls += 1;
    final gate = canonicalIndexGate;
    if (prepareIndexCalls > 1 && gate != null) {
      await gate.future;
    }
    final base = await _empty.prepareIndex(request, token);
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
      geometrySeedsByDirection: {
        for (final direction in LedgerDirection.values)
          direction: base.partitionFor(direction).verticalGeometrySeed,
      },
      focusMembershipSeedsByDirection: {
        LedgerDirection.income: DashboardFocusMembershipSeed(_rows),
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
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _NonEmptyQueryRepository implements DashboardDataRuntimeRepository {
  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async => buildRuntimeTestIndex(
    revision: request.key.coreRevision,
    generation: token.generation,
    directionalQueries: request.directionalQueries,
    initialYear: request.initialYear,
    yearWindowRadius: request.key.yearWindowEndInclusive - request.initialYear,
    entryCountForScope: _entryCountFor,
    previewRowCountForScope: _previewRowCountFor,
    deferredLogBoxes: true,
  );

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async {
    final totalRows = _entryCountFor(request.scope);
    final start = request.pageOrdinal * request.pageSize;
    final count = (totalRows - start).clamp(0, request.pageSize).toInt();
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: request.coreRevision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: DashboardLogViewportState(
        queryKey: request.scope.key,
        revision: request.coreRevision,
        groups: <DashboardDayLogGroupViewModel>[
          DashboardDayLogGroupViewModel(
            dateKey: 'fixture-day',
            dayLabel: 'Fixture day',
            rows: List<DashboardLogRowViewModel>.generate(
              count,
              (index) => DashboardLogRowViewModel(
                entryId:
                    '${request.scope.key.value}:page:${request.pageOrdinal}:$index',
                displayName: 'Filtered row $index',
                categoryDisplayName: 'Food',
                formattedAmount: '-1 Ft',
                displayTime: '12:00',
                amountStyle: LogAmountStyle.expense,
                categoryColorId: 'fallback',
                categoryIconId: 'fallback',
                semanticLabel: 'Filtered row $index',
              ),
              growable: false,
            ),
          ),
        ],
        entryCount: totalRows,
        nextCursor: start + count < totalRows
            ? <String, Object?>{
                'bookedLocalEpochDay': 20000 - request.pageOrdinal,
                'bookedLocalTimeMinutes': 600,
                'entryId': '${request.scope.key.value}:$start',
              }
            : null,
        direction: request.scope.direction,
      ),
    );
  }

  @override
  Map<String, Object?> performanceReport() => const <String, Object?>{};

  static int _entryCountFor(CurrentLedgerQueryScope scope) =>
      scope.categoryIds.contains('food') ? 24 : 48;

  static int _previewRowCountFor(CurrentLedgerQueryScope scope) =>
      _entryCountFor(scope).clamp(0, 24).toInt();
}

final class _TimeReversalRepository implements DashboardDataRuntimeRepository {
  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async => buildRuntimeTestIndex(
    revision: request.key.coreRevision,
    generation: token.generation,
    directionalQueries: request.directionalQueries,
    initialYear: request.initialYear,
    yearWindowRadius: request.key.yearWindowEndInclusive - request.initialYear,
    entryCountForScope: _entryCountFor,
    previewRowCountForScope: _entryCountFor,
    deferredLogBoxes: true,
  );

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async =>
      throw StateError('Prepared reversal roots must not page natively.');

  @override
  Map<String, Object?> performanceReport() => const <String, Object?>{};

  static int _entryCountFor(CurrentLedgerQueryScope scope) {
    final time = scope.timeScope;
    if (time is MonthScope) return time.value.year == 2025 ? 3 : 0;
    if (time is YearScope) return time.year == 2025 ? 3 : 0;
    if (time is DayScope) return time.date.year == 2025 ? 3 : 0;
    return 3;
  }
}
