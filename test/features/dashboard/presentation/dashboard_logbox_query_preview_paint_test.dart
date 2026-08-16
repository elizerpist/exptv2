import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_render_surface.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
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
    activate: cache.activateWindow,
    cancel: cache.cancelInFlightPreparation,
    report: cache.report,
  );
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
