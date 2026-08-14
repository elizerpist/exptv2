import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
