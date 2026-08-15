import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/runtime/application/explicit_committed_paging_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets('the LogBox scroll viewport owns a hard physical paint clip', (
    tester,
  ) async {
    final fixture = await _readyFixture(tester, totalRows: 94);
    addTearDown(fixture.dispose);

    final scrollView = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
    );

    expect(scrollView.clipBehavior, Clip.hardEdge);

    final viewportFinder = find.descendant(
      of: find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
      matching: find.byType(Viewport),
    );
    expect(viewportFinder, findsOneWidget);
    expect(
      tester.renderObject<RenderViewport>(viewportFinder).clipBehavior,
      Clip.hardEdge,
    );
  });

  testWidgets(
    'RED: the LogBox scroll viewport begins below its structural count header',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);

      final header = find.byKey(const ValueKey('dashboard-logbox-header'));
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      expect(header, findsOneWidget);
      expect(scrollView, findsOneWidget);
      expect(
        tester.getRect(scrollView).top,
        greaterThanOrEqualTo(tester.getRect(header).bottom),
        reason:
            'The scrollable must begin after the count header, not behind an '
            'overlay compensated by an in-scroll spacer.',
      );
    },
  );

  testWidgets(
    'RED: the LogBox scroll viewport begins below active Query facet chips',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      final query = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: MonthScope(YearMonth(year: 2026, month: 7)),
          categoryIds: const <String>{'food'},
        ),
      );
      addTearDown(fixture.dispose);
      addTearDown(query.dispose);
      query.apply(
        query.scope,
        facetPresentation: const QueryMenuData(
          result: QueryMenuResultSummary(entryCount: 94, amountScaled100: 1),
          amountDomain: QueryMenuAmountDomain(
            minimumAmountScaled100: 0,
            maximumAmountScaled100: 1,
          ),
          availableMonths: <QueryMenuAvailableMonth>[],
          categories: <QueryMenuCategoryFacet>[
            QueryMenuCategoryFacet(
              id: 'food',
              displayName: 'Étel',
              colorId: 'color_15',
              iconId: 'icon_02',
              entryCount: 94,
            ),
          ],
          partners: <QueryMenuPartnerFacet>[],
        ),
      );

      await tester.pumpWidget(
        _viewport(
          store: fixture.store,
          cache: fixture.cache,
          railScenes: fixture.railScenes,
          onLoadNextPage: (_) {},
          currentQuery: query,
        ),
      );
      await tester.pump();

      final chips = find.byKey(const ValueKey('dashboard-query-facet-chips'));
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      expect(chips, findsOneWidget);
      expect(
        tester.getRect(scrollView).top,
        greaterThanOrEqualTo(tester.getRect(chips).bottom + 6),
        reason:
            'Active facets need a small dedicated breathing gap before the '
            'structural scroll viewport.',
      );
    },
  );

  testWidgets(
    'RED: an exact virtual extent is authoritative before the first vertical drag',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final maxAtRest = position.maxScrollExtent;
      final minAtRest = position.minScrollExtent;
      final physicsAtRest = position.physics;
      expect(minAtRest, 0);

      expect(fixture.cache.isVerticalRenderingActive, isFalse);
      expect(
        maxAtRest,
        closeTo(
          fixture.cache.contentHeight -
              position.viewportDimension +
              DashboardLogBoxTokens.terminalBottomBreathingRoom,
          0.1,
        ),
        reason:
            'The full immutable virtual geometry is already known while '
            'railPreview paints the prepared root. Its only extra scroll '
            'extent is the terminal navigation/shadow tail, so a first drag '
            'may switch paint domain but cannot install dimensions.',
      );

      await tester.drag(scrollView, const Offset(0, -80));
      await tester.pump();

      expect(position.maxScrollExtent, maxAtRest);
      final scrollableAfterDrag = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(identical(scrollableAfterDrag.position, position), isTrue);
      expect(
        identical(scrollableAfterDrag.position.physics, physicsAtRest),
        isTrue,
      );
      expect(position.minScrollExtent, minAtRest);
    },
  );

  testWidgets(
    'a common fling adopts the idle-ready bank without foreground reads or identity replacement',
    (tester) async {
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      final physics = position.physics;
      final readsBeforeInteraction =
          fixture.repository.requestedOrdinals.length;

      await tester.fling(scrollView, const Offset(0, -180), 5000);
      await tester.pump();

      expect(fixture.cache.isVerticalRenderingActive, isTrue);
      expect(fixture.cache.contiguousReadyRowCount, 94);
      expect(
        fixture.repository.requestedOrdinals,
        hasLength(readsBeforeInteraction),
        reason: 'a visible page inside the exact ready bank needs no read',
      );
      expect(identical(scrollable.position, position), isTrue);
      expect(identical(position.physics, physics), isTrue);
      expect(
        fixture.counters.value(DashboardPerformanceMetric.verticalCacheMiss),
        0,
      );
      expect(
        fixture.counters.value(DashboardPerformanceMetric.textLayoutMiss),
        0,
      );
    },
  );

  testWidgets(
    'one interaction emits one aggregate ready-ahead summary without per-frame logs',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(tester, totalRows: 94);
      addTearDown(fixture.dispose);

      await tester.drag(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -120),
      );
      await tester.pump();

      final summaries = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .toList(growable: false);
      expect(summaries, hasLength(1));
      expect(
        summaries.single.message,
        allOf(
          contains('repositoryReadsStartedDuringInteraction=0'),
          contains('preparedAheadPagesAtStart='),
          contains('preparedAheadPagesMinimum='),
          contains('contentDimensionChangeCount='),
          contains('verticalCacheMissCount=0'),
          contains('verticalRootNotDrawableCount=0'),
        ),
      );
      expect(summaries.single.message, contains('virtualPageMissCount=0'));
      expect(
        summaries.single.message,
        contains('virtualGeometryMismatchCount=0'),
      );
    },
  );

  testWidgets(
    'RED: interaction diagnostics keep preparation, pointer, and ballistic scopes explicit',
    (tester) async {
      FluviDiagnosticLogger.clear();
      var clock = 0;
      final fixture = await _readyFixture(
        tester,
        totalRows: 94,
        cache: CommittedLogViewportCache(
          pageSize: 24,
          pagePreparationPolicy: CommittedPagePreparationPolicy(
            contiguousUiBudgetMicros: 1000000,
            nowMicros: () => ++clock,
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      await tester.fling(scrollView, const Offset(0, -120), 5000);
      await tester.pumpAndSettle();

      final summary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      final input = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INPUT_SAMPLE_SUMMARY')
          .single;
      final release = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_DRAG_RELEASED')
          .single;

      expect(summary.message, contains('pagePreparationUiMicros=0'));
      expect(
        summary.message,
        contains('largestPagePreparationUiSliceMicrosDuringInteraction=0'),
      );
      expect(
        summary.message,
        contains('largestPagePreparationUiSliceMicrosForCommittedScope='),
      );
      expect(input.message, contains('pointerInputDurationMs='));
      expect(input.message, contains('interactionDurationMs='));
      expect(input.message, isNot(contains('eventDurationMs=')));
      expect(input.message, contains('rawReleaseVelocity='));
      expect(input.message, contains('appliedBallisticVelocity='));
      expect(release.message, contains('appliedBallisticVelocity='));
    },
  );

  testWidgets(
    'page resource commits do not change full virtual extent or restart ballistic metrics',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final fixture = await _readyFixture(
        tester,
        totalRows: 192,
        cache: CommittedLogViewportCache(
          pageSize: 24,
          pagePreparationPolicy: const CommittedPagePreparationPolicy(
            // This test isolates geometry notifications. The separate cache
            // test exercises resumable yielding with an injected clock.
            contiguousUiBudgetMicros: 1000000,
          ),
        ),
      );
      addTearDown(fixture.dispose);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      await tester.fling(scrollView, const Offset(0, -180), 5000);
      await tester.pump(const Duration(milliseconds: 16));
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final extentBefore = fixture.cache.contentHeight;
      final maxBefore = position.maxScrollExtent;
      final geometryGeneration = fixture.cache.geometryGeneration;

      expect(
        await fixture.cache.prepareAndCommit(
          _page(fixture.store.value!, ordinal: 6, totalRows: 192),
          canPublish: () => true,
        ),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(fixture.cache.contentHeight, extentBefore);
      expect(fixture.cache.geometryGeneration, geometryGeneration);
      expect(position.maxScrollExtent, maxBefore);

      await tester.pumpAndSettle();
      final summary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      expect(summary.message, contains('contentDimensionChangeCount=0'));
      expect(summary.message, contains('goBallisticInvocationCount=1'));
    },
  );

  testWidgets(
    'only a signed backward update asks for an immediate reverse page',
    (tester) async {
      const totalRows = 240;
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _frame(totalRows: totalRows);
      store.publish(frame);
      cache.seed(
        _rootPage(frame),
        generation: 1,
        geometryManifest: _manifest(frame),
      );
      cache.configureSurfaceWidth(378);
      cache.updateForwardDemand(7, trigger: 'test');
      for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
        cache.updateVisibleRowWindow(
          start: ordinal * cache.pageSize,
          end: (ordinal + 1) * cache.pageSize,
        );
        expect(
          cache.commit(_page(frame, ordinal: ordinal, totalRows: totalRows)),
          isTrue,
        );
      }
      expect(cache.lowestRetainedOrdinal, greaterThan(0));
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      await _prepareRailScene(railScenes, frame);

      final reverseRequests = <int>[];
      await tester.pumpWidget(
        _viewport(
          store: store,
          cache: cache,
          railScenes: railScenes,
          onLoadNextPage: (_) {},
          onLoadPreviousPage: () => reverseRequests.add(1),
        ),
      );
      await tester.pump();
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final context = tester.element(scrollView);
      final boundary = cache.lowestRetainedOrdinal;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: cache.drawableExtent,
        pixels: cache.pageTopForOrdinal(boundary),
        viewportDimension: 420,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      ScrollStartNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragStartDetails(globalPosition: Offset.zero),
      ).dispatch(context);
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: 48,
      ).dispatch(context);
      await tester.pump();
      expect(reverseRequests, isEmpty);
      expect(
        cache.report()['visibleStart'],
        boundary * cache.pageSize,
        reason:
            'The header is structural chrome, so a page top is already a '
            'content-local ScrollMetrics offset.',
      );

      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: -48,
      ).dispatch(context);
      await tester.pump();
      expect(reverseRequests, <int>[1]);
    },
  );
}

final class _ReadyFixture {
  _ReadyFixture({
    required this.store,
    required this.cache,
    required this.railScenes,
    required this.paging,
    required this.repository,
    required this.counters,
  });

  final DashboardVisibleFrameStore store;
  final CommittedLogViewportCache cache;
  final DashboardLogBoxPreparedSceneCache railScenes;
  final ExplicitCommittedPagingController paging;
  final _ImmediateRepository repository;
  final DashboardPerformanceCounters counters;

  void dispose() {
    paging.dispose();
    railScenes.dispose();
    cache.dispose();
    store.dispose();
  }
}

Future<_ReadyFixture> _readyFixture(
  WidgetTester tester, {
  required int totalRows,
  CommittedLogViewportCache? cache,
}) async {
  final store = DashboardVisibleFrameStore();
  final committedCache =
      cache ??
      CommittedLogViewportCache(
        pageSize: 24,
        // Widget tests cover scroll metrics, not host stopwatch granularity.
        // The cache unit tests own deterministic yield/resume coverage with
        // their injected work probe.
        pagePreparationPolicy: const CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 1000000,
        ),
      );
  final railScenes = DashboardLogBoxPreparedSceneCache();
  final repository = _ImmediateRepository(totalRows: totalRows);
  final counters = DashboardPerformanceCounters();
  var verticalInteractionActive = false;
  final paging = ExplicitCommittedPagingController(
    repository: repository,
    visibleFrames: store,
    committedViewport: committedCache,
    pageSize: 24,
    isVerticalInteractionActive: () => verticalInteractionActive,
  );
  final frame = _frame(totalRows: totalRows);
  store.publish(frame);
  paging.commitMetadata(frame, geometryManifest: _manifest(frame));
  committedCache.configureSurfaceWidth(378);
  expect(
    await paging.prepareReadyAheadAtIdle(reason: 'viewportTestIdle'),
    isTrue,
  );
  expect(committedCache.contiguousReadyRowCount, totalRows.clamp(0, 144));
  await _prepareRailScene(railScenes, frame);
  await tester.pumpWidget(
    _viewport(
      store: store,
      cache: committedCache,
      railScenes: railScenes,
      performanceCounters: counters,
      onLoadNextPage: (_) {},
      onVerticalScrollStarted: () => verticalInteractionActive = true,
      onVerticalScrollEnded: () => verticalInteractionActive = false,
    ),
  );
  await tester.pump();
  return _ReadyFixture(
    store: store,
    cache: committedCache,
    railScenes: railScenes,
    paging: paging,
    repository: repository,
    counters: counters,
  );
}

Widget _viewport({
  required DashboardVisibleFrameStore store,
  required CommittedLogViewportCache cache,
  required DashboardLogBoxPreparedSceneCache railScenes,
  required ValueChanged<int> onLoadNextPage,
  VoidCallback? onLoadPreviousPage,
  VoidCallback? onVerticalScrollStarted,
  VoidCallback? onVerticalScrollEnded,
  DashboardPerformanceCounters? performanceCounters,
  CurrentQueryController? currentQuery,
}) => MaterialApp(
  home: SizedBox(
    width: 378,
    height: 420,
    child: DashboardLogBoxViewport(
      bounds: const DashboardBounds(left: 0, top: 28, width: 378, height: 28),
      visibleFrames: store,
      committedViewport: cache,
      preparedSceneCache: railScenes,
      preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(3),
      onLoadNextPage: onLoadNextPage,
      onLoadPreviousPage: onLoadPreviousPage,
      onVerticalScrollStarted: onVerticalScrollStarted,
      onVerticalScrollEnded: onVerticalScrollEnded,
      performanceCounters: performanceCounters,
      currentQuery: currentQuery,
      onRemoveQueryCategory: currentQuery == null ? null : (_) {},
      onRemoveQueryPartner: currentQuery == null ? null : (_) {},
      onClearQuery: currentQuery == null ? null : () {},
    ),
  ),
);

Future<void> _prepareRailScene(
  DashboardLogBoxPreparedSceneCache railScenes,
  DashboardVisibleFrame frame,
) async {
  final window = DashboardLogBoxSceneWindow(
    identity: 'viewport-test-${frame.queryKey.value}',
    payloads: <DashboardLogViewportState>[frame.logBox],
  );
  await railScenes.prepareWindow(window: window, surfaceWidth: 378);
  railScenes.activateWindow(window);
}

DashboardVisibleFrame _frame({required int totalRows}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: MonthScope(YearMonth(year: 2026, month: 7)),
  );
  final rootRows = List<DashboardLogRowViewModel>.generate(
    totalRows.clamp(0, 24).toInt(),
    (index) => _row(index),
    growable: false,
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: <DashboardDayLogGroupViewModel>[
      DashboardDayLogGroupViewModel(
        dateKey: '2026-07-01',
        dayLabel: '2026. július 1.',
        rows: rootRows,
      ),
    ],
    entryCount: totalRows,
    nextCursor: totalRows > 24 ? _cursor(0) : null,
    direction: LedgerDirection.expense,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: 1,
    formattedAmount: '1 Ft',
    entryCount: totalRows,
    formattedEntryCount: '$totalRows',
    logBox: logBox,
    presentationDigest: totalRows,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. július',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}

CommittedLogPage _rootPage(DashboardVisibleFrame frame) => CommittedLogPage(
  queryKey: frame.queryKey,
  coreRevision: frame.coreRevision,
  generation: 1,
  ordinal: 0,
  startCursor: null,
  previousStartCursor: null,
  payload: frame.logBox,
);

CommittedLogPage _page(
  DashboardVisibleFrame frame, {
  required int ordinal,
  required int totalRows,
}) {
  final start = ordinal * 24;
  final count = (totalRows - start).clamp(0, 24);
  final rows = List<DashboardLogRowViewModel>.generate(
    count,
    (index) => _row(start + index),
    growable: false,
  );
  return CommittedLogPage(
    queryKey: frame.queryKey,
    coreRevision: frame.coreRevision,
    generation: 1,
    ordinal: ordinal,
    startCursor: _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: frame.queryKey,
      revision: frame.coreRevision,
      groups: <DashboardDayLogGroupViewModel>[
        DashboardDayLogGroupViewModel(
          dateKey: '2026-07-01',
          dayLabel: '2026. július 1.',
          rows: rows,
        ),
      ],
      entryCount: totalRows,
      nextCursor: start + count < totalRows ? _cursor(ordinal) : null,
      direction: frame.scope.direction,
    ),
  );
}

final class _ImmediateRepository implements DashboardCommittedPageRepository {
  _ImmediateRepository({required this.totalRows});

  final int totalRows;
  final List<int> requestedOrdinals = <int>[];

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async {
    requestedOrdinals.add(request.pageOrdinal);
    final start = request.pageOrdinal * request.pageSize;
    final count = (totalRows - start).clamp(0, request.pageSize);
    final rows = List<DashboardLogRowViewModel>.generate(
      count,
      (index) => _row(start + index),
      growable: false,
    );
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
            dateKey: '2026-07-01',
            dayLabel: '2026. július 1.',
            rows: rows,
          ),
        ],
        entryCount: totalRows,
        nextCursor: start + count < totalRows
            ? _cursor(request.pageOrdinal)
            : null,
        direction: request.scope.direction,
      ),
    );
  }
}

DashboardLogRowViewModel _row(int index) => DashboardLogRowViewModel(
  entryId: 'paged-$index',
  displayName: 'Partner $index',
  categoryDisplayName: 'Category',
  formattedAmount: '-1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Partner $index, -1,00 Ft, kiadás, Category',
);

Map<String, Object?> _cursor(int ordinal) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - ordinal,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'paged-${ordinal * 24 + 23}',
};

CommittedVerticalGeometryManifest _manifest(DashboardVisibleFrame frame) =>
    CommittedVerticalGeometryManifest.compile(
      queryKey: frame.queryKey,
      coreRevision: frame.coreRevision,
      pageSize: 24,
      totalEntryCount: frame.logBox.entryCount,
      dayBuckets: <CommittedVerticalGeometryDayBucket>[
        if (frame.logBox.entryCount > 0)
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 20_000,
            entryCount: frame.logBox.entryCount,
          ),
      ],
    );
