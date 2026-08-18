import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );

  testWidgets(
    'RED: exact committed resources arm before O(1) vertical domain activation',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      cache.configureSurfaceWidth(378);
      expect(
        cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null)),
        isTrue,
      );
      await tester.pump();

      expect(cache.isVerticalRenderingActive, isFalse);
      expect(await cache.armVerticalInteractionResources(), isTrue);
      expect(cache.isVerticalInteractionArmed, isTrue);
      final preparedRowsBeforeActivation = cache.preparedTextRowCount;
      final preparedHeadersBeforeActivation = cache.preparedDayHeaderCount;

      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      expect(cache.preparedTextRowCount, preparedRowsBeforeActivation);
      expect(cache.preparedDayHeaderCount, preparedHeadersBeforeActivation);
      final activation = FluviDiagnosticLogger.entries.lastWhere(
        (event) => event.stage == 'VERTICAL_RENDER_ACTIVATION_COMPLETED',
      );
      expect(
        activation.message,
        allOf(contains('wasArmed=true'), contains('newPreparedPageCount=0')),
      );
    },
  );

  testWidgets(
    'rail preview root stages before takeover and transfers without pointer work',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      final root = _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0));
      cache.configureSurfaceWidth(378);

      expect(await cache.armPreviewRootResources(root.payload), isTrue);
      cache.seed(
        root,
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      expect(cache.hasDrawableRootFallback, isTrue);
      expect(await cache.armVerticalInteractionResources(), isTrue);
      final preparedRowsBeforePointer = cache.preparedTextRowCount;

      cache.noteVerticalPointerIntent(active: true);
      expect(cache.activateVerticalRendering(), isTrue);
      expect(cache.preparedTextRowCount, preparedRowsBeforePointer);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) => event.stage == 'VERTICAL_PREVIEW_ROOT_ARMED',
        ),
        isTrue,
      );
      expect(
        FluviDiagnosticLogger.entries
            .lastWhere(
              (event) => event.stage == 'VERTICAL_RENDER_ACTIVATION_COMPLETED',
            )
            .message,
        contains('newPreparedPageCount=0'),
      );
      await tester.pump();
    },
  );

  testWidgets(
    'a complete page advances only resource state, never immutable geometry',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      final rootExtent = cache.drawableExtent;
      final rootGeometryGeneration = cache.geometryGeneration;
      final rootRenderGeneration = cache.renderGeneration;

      expect(
        cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null)),
        isTrue,
      );

      expect(cache.highestReadyPageOrdinal, 1);
      expect(cache.drawableExtent, rootExtent);
      expect(cache.geometryGeneration, rootGeometryGeneration);
      expect(cache.renderGeneration, greaterThan(rootRenderGeneration));
    },
  );

  testWidgets(
    'idle ready-ahead commit has complete text resources before publication',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      cache.configureSurfaceWidth(378);

      expect(
        cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null)),
        isTrue,
      );

      expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
      expect(cache.preparedPageForOrdinal(1)?.dayHeaderCount, 1);
      expect(cache.layoutAt(24), isNotNull);
      expect(cache.textLayoutMissCount, 0);
      expect(cache.drawableExtent, greaterThan(0));
    },
  );

  testWidgets(
    'RED: ready drawable frontier and visible resource gap stay distinct from immutable virtual geometry',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      final manifest = _manifest(scope, total: 67);
      cache.seed(
        _page(scope, ordinal: 0, total: 67, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: manifest,
      );
      cache.configureSurfaceWidth(378);

      final rootBottom = manifest.pageForOrdinal(0)!.bottom;
      expect(cache.readyDrawableExtent, rootBottom);
      expect(cache.readyDrawableExtent, lessThan(cache.drawableExtent));

      final missing = cache.visibleResourceReadiness(
        firstVisibleOrdinal: 1,
        lastVisibleOrdinal: 1,
      );
      expect(missing.visibleMissingPageCount, 1);
      expect(missing.firstVisibleMissingOrdinal, 1);
      expect(missing.missingVisibleOrdinals, <int>[1]);
      expect(missing.resourceReadyStartOrdinal, isNull);
      expect(missing.resourceReadyEndOrdinal, isNull);

      cache.recordVirtualPageMiss(
        ordinal: 1,
        scrollOffset: manifest.pageForOrdinal(1)!.top,
        direction: 'forward',
      );
      cache.recordVirtualPageMiss(
        ordinal: 1,
        scrollOffset: manifest.pageForOrdinal(1)!.top,
        direction: 'forward',
      );
      expect(cache.virtualPageMissCount, 1);
      expect(
        cache
            .visibleResourceReadiness(
              firstVisibleOrdinal: 1,
              lastVisibleOrdinal: 1,
            )
            .visibleMissingPageCount,
        1,
        reason: 'Current state must remain visible after event deduplication.',
      );

      cache.updateVisibleRowWindow(start: 24, end: 48);
      final window = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_DRAWABLE_WINDOW_CHANGED')
          .single;
      expect(
        window.message,
        allOf(
          contains('logicalVisibleStart=24'),
          contains('logicalVisibleEnd=48'),
          contains('resourceReadyStartOrdinal=-1'),
          contains('resourceReadyEndOrdinal=-1'),
          contains('missingVisibleOrdinals=[1]'),
          contains('missingVisiblePageCount=1'),
          contains('firstVisibleMissingOrdinal=1'),
        ),
      );
    },
  );

  test(
    'a bounded rail preview never activates the virtual surface as a partial root page',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(
          scope,
          ordinal: 0,
          total: 48,
          nextCursor: _cursor(0),
          rowCount: 1,
        ),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      cache.configureSurfaceWidth(378);

      expect(cache.activateVerticalRendering(hasExactRailScene: true), isFalse);
      expect(cache.isVerticalRenderingActive, isFalse);
      expect(cache.virtualGeometryMismatchCount, 1);
    },
  );

  testWidgets(
    'resumable page preparation publishes only after complete bounded slices',
    (tester) async {
      var clock = 0;
      final yields = <Completer<void>>[];
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        pagePreparationPolicy: CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 2,
          nowMicros: () => ++clock,
          yieldToEventTurn: () {
            final completer = Completer<void>();
            yields.add(completer);
            return completer.future;
          },
        ),
      );
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      cache.configureSurfaceWidth(378);

      var completed = false;
      final result = cache
          .prepareAndCommit(
            _page(scope, ordinal: 1, total: 48, nextCursor: null),
            canPublish: () => true,
          )
          .then((value) {
            completed = true;
            return value;
          });
      await tester.pump();
      while (!completed) {
        expect(cache.pageForOrdinal(1), isNull);
        expect(cache.preparedPageForOrdinal(1), isNull);
        expect(yields, isNotEmpty);
        yields.removeAt(0).complete();
        await tester.pump();
      }

      expect(await result, isTrue);
      expect(cache.pageForOrdinal(1), isNotNull);
      expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
      expect(cache.pagePreparationYieldCount, greaterThan(0));
      expect(
        cache.largestPagePreparationUiSliceMicros,
        lessThanOrEqualTo(3),
        reason: 'one atomic row/header step may cross the injected boundary',
      );
      expect(yields, isEmpty, reason: 'completion must not yield once more');
    },
  );

  testWidgets('superseding a private preparation publishes no partial page', (
    tester,
  ) async {
    var clock = 0;
    final yieldGate = Completer<void>();
    final cache = CommittedLogViewportCache(
      pageSize: 24,
      pagePreparationPolicy: CommittedPagePreparationPolicy(
        contiguousUiBudgetMicros: 1,
        nowMicros: () => ++clock,
        yieldToEventTurn: () => yieldGate.future,
      ),
    );
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 48),
    );
    cache.configureSurfaceWidth(378);
    var current = true;
    final result = cache.prepareAndCommit(
      _page(scope, ordinal: 1, total: 48, nextCursor: null),
      canPublish: () => current,
    );
    await tester.pump();
    current = false;
    yieldGate.complete();

    expect(await result, isFalse);
    expect(cache.pageForOrdinal(1), isNull);
    expect(cache.preparedPageForOrdinal(1), isNull);
    expect(cache.isPagePreparationActive, isFalse);
  });

  test('a stale or noncontiguous page cannot partially publish geometry', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 72, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 72),
    );
    final rootExtent = cache.drawableExtent;

    expect(
      cache.commit(_page(scope, ordinal: 2, total: 72, nextCursor: null)),
      isFalse,
    );
    expect(
      cache.lastCommitRejection,
      CommittedLogPageCommitRejection.nonContiguousOrdinal,
    );
    expect(cache.highestReadyPageOrdinal, 0);
    expect(cache.drawableExtent, rootExtent);
    expect(cache.pageForOrdinal(2), isNull);
  });

  test(
    'a payload whose local day grouping disagrees with the manifest fails closed',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      final manifest = CommittedVerticalGeometryManifest.compile(
        queryKey: scope.key,
        coreRevision: 3,
        pageSize: 24,
        totalEntryCount: 80,
        dayBuckets: const <CommittedVerticalGeometryDayBucket>[
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 20_000,
            entryCount: 30,
          ),
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 19_999,
            entryCount: 10,
          ),
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 19_998,
            entryCount: 40,
          ),
        ],
      );
      cache.seed(
        _page(scope, ordinal: 0, total: 80, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: manifest,
      );
      final extent = cache.contentHeight;

      expect(
        cache.commit(_page(scope, ordinal: 1, total: 80, nextCursor: null)),
        isFalse,
      );
      expect(
        cache.lastCommitRejection,
        CommittedLogPageCommitRejection.geometryMismatch,
      );
      expect(cache.virtualGeometryMismatchCount, 1);
      expect(cache.contentHeight, extent);
      expect(cache.pageForOrdinal(1), isNull);
    },
  );

  testWidgets('root remains pinned while the five movable slots rotate', (
    tester,
  ) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 264, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 264),
    );
    cache.configureSurfaceWidth(378);
    expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
    cache.updateForwardDemand(10, trigger: 'testReadyTarget');

    for (var ordinal = 1; ordinal <= 10; ordinal += 1) {
      cache.updateVisibleRowWindow(
        start: (ordinal - 1) * 24,
        end: ordinal * 24,
      );
      expect(
        cache.commit(
          _page(
            scope,
            ordinal: ordinal,
            total: 264,
            nextCursor: ordinal == 10 ? null : _cursor(ordinal),
          ),
        ),
        isTrue,
      );
      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
    }

    expect(cache.pageForOrdinal(0), isNotNull);
    expect(cache.rootPagePresent, isTrue);
    expect(cache.highestReadyPageOrdinal, 10);
    expect(cache.retainedPageCount, lessThanOrEqualTo(5));
    expect(cache.contentHeight, _manifest(scope, total: 264).totalExtent);
  });

  testWidgets(
    'a visible ordinal beyond the ready frontier cannot invert retention clamp bounds',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 264, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 264),
      );
      cache.configureSurfaceWidth(378);
      cache.updateForwardDemand(10, trigger: 'fastBallisticDemand');

      for (var ordinal = 1; ordinal <= 8; ordinal += 1) {
        cache.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 264,
              nextCursor: _cursor(ordinal),
            ),
          ),
          isTrue,
        );
      }

      // This is the physical ordinal-9 / visible-10 sequence. Before the
      // fix, `_retentionTargetOrdinals` evaluated `10.clamp(10, 9)` while
      // committing this prepared page and threw `Invalid argument(s): 10`.
      cache.updateVisibleRowWindow(start: 240, end: 264);
      expect(
        () => cache.commit(
          _page(scope, ordinal: 9, total: 264, nextCursor: _cursor(9)),
        ),
        returnsNormally,
      );
      expect(cache.pageForOrdinal(9), isNotNull);
      expect(cache.virtualGeometryMismatchCount, 0);
    },
  );

  testWidgets(
    'ephemeral focus transfers and restores the exact bounded base hotset',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      final baseManifest = _manifest(scope, total: 120);
      cache.seed(
        _page(scope, ordinal: 0, total: 120, nextCursor: _cursor(0)),
        generation: 7,
        geometryManifest: baseManifest,
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      for (var ordinal = 1; ordinal <= 3; ordinal += 1) {
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 120,
              nextCursor: _cursor(ordinal),
              generation: 7,
            ),
          ),
          isTrue,
        );
      }
      await tester.pump();
      final retainedPage = cache.pageForOrdinal(2);
      final retainedPrepared = cache.preparedPageForOrdinal(2);
      final snapshot = cache.retainForEphemeralFocus();

      expect(snapshot, isNotNull);
      expect(cache.hasExactCommittedScope, isFalse);
      expect(cache.rootPagePresent, isFalse);

      final focusScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
      );
      cache.seed(
        _page(focusScope, ordinal: 0, total: 24, nextCursor: null),
        generation: 8,
        geometryManifest: _manifest(focusScope, total: 24),
      );

      expect(
        cache.restoreEphemeralFocusSnapshot(
          snapshot!,
          queryKey: scope.key,
          coreRevision: 3,
          geometryManifest: baseManifest,
        ),
        isTrue,
      );
      expect(cache.queryKey, scope.key);
      expect(cache.highestReadyPageOrdinal, 3);
      expect(identical(cache.pageForOrdinal(2), retainedPage), isTrue);
      expect(
        identical(cache.preparedPageForOrdinal(2), retainedPrepared),
        isTrue,
      );
      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
      expect(cache.contentHeight, baseManifest.totalExtent);
    },
  );

  test(
    'a changed base identity rejects and disposes an ephemeral focus hotset',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 1,
        geometryManifest: _manifest(scope, total: 48),
      );
      final snapshot = cache.retainForEphemeralFocus();
      expect(snapshot, isNotNull);
      final changedScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
      );

      expect(
        cache.restoreEphemeralFocusSnapshot(
          snapshot!,
          queryKey: changedScope.key,
          coreRevision: 3,
          geometryManifest: _manifest(changedScope, total: 48),
        ),
        isFalse,
      );
      snapshot.dispose();
      expect(snapshot.isAvailable, isFalse);
    },
  );

  testWidgets('backward retention keeps the immediate reverse safety page', (
    tester,
  ) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 192, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 192),
    );
    cache.configureSurfaceWidth(378);
    expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
    cache.updateForwardDemand(7, trigger: 'forward');
    for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
      cache.updateVisibleRowWindow(start: 72, end: 96);
      cache.commit(
        _page(
          scope,
          ordinal: ordinal,
          total: 192,
          nextCursor: _cursor(ordinal),
        ),
      );
    }

    cache.updateVisibleRowWindow(start: 48, end: 72);
    expect(
      cache.commit(
        _page(scope, ordinal: 2, total: 192, nextCursor: _cursor(2)),
      ),
      isTrue,
    );
    expect(cache.pageForOrdinal(2), isNotNull);

    cache.updateVisibleRowWindow(start: 24, end: 48);
    expect(
      cache.commit(
        _page(scope, ordinal: 1, total: 192, nextCursor: _cursor(1)),
      ),
      isTrue,
    );

    expect(cache.pageForOrdinal(1), isNotNull);
    expect(cache.pageForOrdinal(2), isNotNull);
    expect(cache.retainedPageCount, lessThanOrEqualTo(5));
  });

  testWidgets('a width change rebuilds complete pages atomically', (
    tester,
  ) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 48),
    );
    cache.configureSurfaceWidth(378);
    expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
    cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null));
    expect(cache.preparedPageForOrdinal(1)?.surfaceWidth, 378);

    cache.configureSurfaceWidth(520);

    expect(cache.preparedPageForOrdinal(1)?.surfaceWidth, 520);
    expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
    expect(cache.textLayoutMissCount, 0);
  });

  testWidgets('a root fallback is prepared before vertical activation', (
    tester,
  ) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 24, nextCursor: null),
      generation: 1,
      geometryManifest: _manifest(scope, total: 24),
    );
    cache.configureSurfaceWidth(378);

    expect(cache.hasDrawableRootFallback, isFalse);
    await tester.pump();
    expect(cache.hasDrawableRootFallback, isTrue);
    expect(cache.activateVerticalRendering(hasExactRailScene: false), isTrue);
    expect(cache.textLayoutMissCount, 0);
  });

  test('a superseded scope rejects old page identity without stale rows', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 1,
      geometryManifest: _manifest(scope, total: 48),
    );
    final nextScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
    );
    cache.seed(
      _page(nextScope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 2,
      geometryManifest: _manifest(nextScope, total: 48),
    );

    expect(
      cache.commit(
        _page(scope, ordinal: 1, total: 48, nextCursor: null, generation: 1),
      ),
      isFalse,
    );
    expect(cache.queryKey, nextScope.key);
    expect(cache.pageForOrdinal(1), isNull);
  });
}

CommittedLogPage _page(
  CurrentLedgerQueryScope scope, {
  required int ordinal,
  required int total,
  required Map<String, Object?>? nextCursor,
  int generation = 1,
  int rowCount = 24,
}) {
  final start = ordinal * 24;
  final rows = List<DashboardLogRowViewModel>.generate(
    rowCount,
    (index) => DashboardLogRowViewModel(
      entryId: 'row-${start + index}',
      displayName: 'Név ${start + index}',
      categoryDisplayName: 'Kategória',
      formattedAmount: '-1 000 Ft',
      displayTime: '10:00',
      amountStyle: LogAmountStyle.expense,
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
      semanticLabel: 'Sor ${start + index}',
    ),
  );
  return CommittedLogPage(
    queryKey: scope.key,
    coreRevision: 3,
    generation: generation,
    ordinal: ordinal,
    startCursor: ordinal == 0 ? null : _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: <DashboardDayLogGroupViewModel>[
        DashboardDayLogGroupViewModel(
          dateKey: '2026-07-01',
          dayLabel: '2026. július 1.',
          rows: rows,
        ),
      ],
      entryCount: total,
      nextCursor: nextCursor,
      direction: scope.direction,
    ),
  );
}

Map<String, Object?> _cursor(int page) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - page,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'row-${page * 24 + 23}',
};

CommittedVerticalGeometryManifest _manifest(
  CurrentLedgerQueryScope scope, {
  required int total,
}) => CommittedVerticalGeometryManifest.compile(
  queryKey: scope.key,
  coreRevision: 3,
  pageSize: 24,
  totalEntryCount: total,
  dayBuckets: <CommittedVerticalGeometryDayBucket>[
    if (total > 0)
      CommittedVerticalGeometryDayBucket(
        bookedLocalEpochDay: 20_000,
        entryCount: total,
      ),
  ],
);
