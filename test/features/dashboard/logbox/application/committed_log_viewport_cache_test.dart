import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
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
    'keeps a page private until cooperative presentation preparation completes',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.configureSurfaceWidth(378);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      await tester.pump();
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      final yielded = Completer<void>();
      final release = Completer<void>();

      final pending = cache.prepareAndCommit(
        _page(scope, ordinal: 1, total: 48, nextCursor: null),
        yieldToScheduler: () async {
          if (!yielded.isCompleted) yielded.complete();
          await release.future;
        },
      );
      await yielded.future;

      expect(cache.pageForOrdinal(1), isNull);
      expect(cache.preparedPageForOrdinal(1), isNull);
      release.complete();
      expect(await pending, isTrue);
      expect(cache.pageForOrdinal(1), isNotNull);
      expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
    },
  );

  testWidgets(
    'ordinary scheduler yields are metrics, not pause-resume diagnostics',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.configureSurfaceWidth(378);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      await tester.pump();
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      expect(
        await cache.prepareAndCommit(
          _page(scope, ordinal: 1, total: 48, nextCursor: null),
          yieldToScheduler: () async {},
        ),
        isTrue,
      );

      final stages = FluviDiagnosticLogger.entries
          .map((event) => event.stage)
          .toList(growable: false);
      expect(stages, contains('VERTICAL_PAGE_PRESENTATION_PREPARE_READY'));
      expect(
        stages,
        isNot(contains('VERTICAL_PAGE_PRESENTATION_PREPARE_PAUSED')),
      );
      expect(
        stages,
        isNot(contains('VERTICAL_PAGE_PRESENTATION_PREPARE_RESUMED')),
      );
    },
  );

  testWidgets(
    'invalidates a private page preparation when the exact surface width changes',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.configureSurfaceWidth(378);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      await tester.pump();
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      final yielded = Completer<void>();
      final release = Completer<void>();
      final pending = cache.prepareAndCommit(
        _page(scope, ordinal: 1, total: 48, nextCursor: null),
        yieldToScheduler: () async {
          if (!yielded.isCompleted) yielded.complete();
          await release.future;
        },
      );

      await yielded.future;
      cache.configureSurfaceWidth(480);
      release.complete();

      expect(await pending, isFalse);
      expect(cache.pageForOrdinal(1), isNull);
      expect(cache.preparedPageForOrdinal(1), isNull);
    },
  );

  testWidgets('preempted private preparation never exposes a partial page', (
    tester,
  ) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.configureSurfaceWidth(378);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 11,
    );
    await tester.pump();
    expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
    var preempt = false;
    final yielded = Completer<void>();
    final pending = cache.prepareAndCommit(
      _page(scope, ordinal: 1, total: 48, nextCursor: null),
      shouldPreempt: () => preempt,
      yieldToScheduler: () async {
        preempt = true;
        if (!yielded.isCompleted) yielded.complete();
      },
    );

    await yielded.future;
    expect(await pending, isFalse);
    expect(cache.pageForOrdinal(1), isNull);
    expect(cache.preparedPageForOrdinal(1), isNull);
  });

  test('retains only the visible committed page window, never all pages', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);

    cache.seed(
      _page(scope, ordinal: 0, total: 1000, nextCursor: _cursor(0)),
      generation: 11,
    );
    for (var ordinal = 1; ordinal < 8; ordinal += 1) {
      cache.updateVisibleRowWindow(
        start: (ordinal - 1) * 24,
        end: ordinal * 24,
      );
      expect(
        cache.commit(
          _page(
            scope,
            ordinal: ordinal,
            total: 1000,
            nextCursor: _cursor(ordinal),
          ),
        ),
        isTrue,
      );
    }

    cache.updateVisibleRowWindow(start: 6 * 24, end: 6 * 24 + 5);

    expect(cache.totalEntryCount, 1000);
    expect(cache.loadedEntryCount, 8 * 24);
    expect(cache.estimatedBytes, lessThanOrEqualTo(cache.maximumRetainedBytes));
    expect(cache.pageForOrdinal(5), isNotNull);
    expect(cache.pageForOrdinal(0), isNotNull);
    expect(cache.rootPageRows, 24);
    expect(cache.rowAt(6 * 24)?.row.entryId, 'row-144');
  });

  test(
    'keeps at most five movable prepared pages for a small committed scope',
    () {
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        // The byte estimate remains a secondary cap. The movable prepared
        // working set itself is intentionally hard-bounded.
      );
      addTearDown(cache.dispose);

      cache.seed(
        _page(scope, ordinal: 0, total: 176, nextCursor: _cursor(0)),
        generation: 11,
      );
      for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 176,
              nextCursor: ordinal == 7 ? null : _cursor(ordinal),
            ),
          ),
          isTrue,
        );
        cache.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }

      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(cache.pageForOrdinal(0), isNotNull);
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
    },
  );

  testWidgets(
    'keeps the hard five-page working set despite a wider byte budget',
    (tester) async {
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        maximumRetainedBytes: 400 * 1024,
      );
      addTearDown(cache.dispose);
      cache.configureSurfaceWidth(378);
      cache.seed(
        _page(scope, ordinal: 0, total: 240, nextCursor: _cursor(0)),
        generation: 11,
      );
      await tester.pump();
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      cache.updateVisibleRowWindow(start: 6 * 24, end: 7 * 24);
      cache.updateForwardDemand(8);
      for (var ordinal = 1; ordinal <= 9; ordinal += 1) {
        expect(
          await cache.prepareAndCommit(
            _page(
              scope,
              ordinal: ordinal,
              total: 240,
              nextCursor: ordinal == 9 ? null : _cursor(ordinal),
            ),
            yieldToScheduler: () async {},
          ),
          isTrue,
        );
      }

      // The root is separately pinned and the movable bank is five pages.
      // Current drawable page and nearest forward/reverse safety win; byte
      // accounting may not broaden this hard local working set.
      expect(cache.pageForOrdinal(6), isNotNull);
      expect(cache.pageForOrdinal(5), isNotNull);
      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(cache.pageForOrdinal(1), isNull);
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
    },
  );

  test(
    'keeps an immediate prior page after a real backward visible-window move',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 240, nextCursor: _cursor(0)),
        generation: 11,
      );
      for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 240,
              nextCursor: ordinal == 7 ? null : _cursor(ordinal),
            ),
          ),
          isTrue,
        );
        cache.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }
      expect(cache.lowestRetainedOrdinal, 3);

      // This decreasing start is the cache-owned retention signal paired with
      // the viewport's negative ScrollUpdate demand.
      cache.updateVisibleRowWindow(start: 3 * 24, end: 4 * 24);
      expect(
        cache.commit(
          _page(scope, ordinal: 2, total: 240, nextCursor: _cursor(2)),
        ),
        isTrue,
      );

      expect(cache.pageForOrdinal(2), isNotNull);
      expect(cache.pageForOrdinal(3), isNotNull);
      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
    },
  );

  test(
    'retains the bounded forward-ready window while the viewport approaches it',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);

      cache.seed(
        _page(scope, ordinal: 0, total: 658, nextCursor: _cursor(0)),
        generation: 11,
      );
      // A three-page viewport at ordinals 2–4 needs the two-page forward
      // demand (5–6) to stay drawable until the user reaches it.
      cache.updateVisibleRowWindow(start: 2 * 24, end: 5 * 24);
      cache.updateForwardDemand(6);
      for (var ordinal = 1; ordinal <= 6; ordinal += 1) {
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 658,
              nextCursor: _cursor(ordinal),
            ),
          ),
          isTrue,
        );
      }

      expect(cache.pageForOrdinal(2), isNotNull);
      expect(cache.pageForOrdinal(4), isNotNull);
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
    },
  );

  test('pins committed page zero while local page retention moves deep', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);

    cache.seed(
      _page(scope, ordinal: 0, total: 658, nextCursor: _cursor(0)),
      generation: 11,
    );
    for (var ordinal = 1; ordinal <= 7; ordinal += 1) {
      expect(
        cache.commit(
          _page(
            scope,
            ordinal: ordinal,
            total: 658,
            nextCursor: ordinal == 7 ? null : _cursor(ordinal),
          ),
        ),
        isTrue,
      );
      cache.updateVisibleRowWindow(
        start: ordinal * 24,
        end: (ordinal + 1) * 24,
      );
    }

    cache.updateVisibleRowWindow(start: 0, end: 24);

    expect(
      cache.pageForOrdinal(0)?.payload.flatItems.first.row.entryId,
      'row-0',
    );
    expect(cache.pageTopForOrdinal(0), 0);
    expect(cache.rowAt(0)?.row.entryId, 'row-0');
    expect(cache.estimatedBytes, lessThanOrEqualTo(cache.maximumRetainedBytes));
    final report = cache.report();
    expect(report['rootPagePresent'], isTrue);
    expect(report['rootPageRows'], 24);
    expect(report['rootPageUsesRailScene'], isTrue);
  });

  test(
    'reports forward end once when an evicted local page reloads backward',
    () {
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        maximumRetainedBytes: 10 * 1024,
      );
      addTearDown(cache.dispose);
      FluviDiagnosticLogger.clear();

      cache.seed(
        _page(scope, ordinal: 0, total: 168, nextCursor: _cursor(0)),
        generation: 11,
      );
      for (var ordinal = 1; ordinal <= 6; ordinal += 1) {
        expect(
          cache.commit(
            _page(
              scope,
              ordinal: ordinal,
              total: 168,
              nextCursor: ordinal == 6 ? null : _cursor(ordinal),
            ),
          ),
          isTrue,
        );
        cache.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }

      expect(cache.endReachedCount, 1);
      expect(cache.pageForOrdinal(1), isNull);

      expect(
        cache.commit(
          _page(scope, ordinal: 1, total: 168, nextCursor: _cursor(1)),
        ),
        isTrue,
      );

      expect(cache.endReachedCount, 1);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'VERTICAL_END_REACHED',
        ),
        hasLength(1),
      );
    },
  );

  test('reports a near-frontier stall only once for one committed scope', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    FluviDiagnosticLogger.clear();
    cache.seed(
      _page(scope, ordinal: 0, total: 94, nextCursor: _cursor(0)),
      generation: 11,
    );

    cache.recordFrontierStall(
      firstVisibleOrdinal: 0,
      lastVisibleOrdinal: 2,
      distanceToDrawableEnd: 0,
    );
    cache.recordFrontierStall(
      firstVisibleOrdinal: 0,
      lastVisibleOrdinal: 2,
      distanceToDrawableEnd: 0,
    );

    expect(cache.frontierStallCount, 1);
    expect(
      FluviDiagnosticLogger.entries.where(
        (event) => event.stage == 'VERTICAL_FRONTIER_STALL',
      ),
      hasLength(1),
    );
  });

  test(
    'records lower-edge demand inputs in the bounded scroll diagnostics',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      FluviDiagnosticLogger.clear();
      cache.seed(
        _page(scope, ordinal: 0, total: 94, nextCursor: _cursor(0)),
        generation: 11,
      );

      expect(
        cache.updateForwardDemand(
          2,
          trigger: 'scrollUpdate',
          firstVisibleOrdinal: 0,
          lastVisibleOrdinal: 2,
          distanceToDrawableEnd: 0,
        ),
        isTrue,
      );
      cache.recordScrollSummary(
        scrollOffset: 947,
        firstVisibleOrdinal: 0,
        lastVisibleOrdinal: 2,
        lastPossibleOrdinal: 3,
        distanceToDrawableEnd: 0,
      );

      final demand = FluviDiagnosticLogger.entries.firstWhere(
        (event) => event.stage == 'VERTICAL_DEMAND_CHANGED',
      );
      final summary = FluviDiagnosticLogger.entries.firstWhere(
        (event) => event.stage == 'VERTICAL_SCROLL_SUMMARY',
      );
      expect(demand.message, contains('trigger=scrollUpdate'));
      expect(demand.message, contains('lastVisible=2'));
      expect(summary.message, contains('firstVisible=0'));
      expect(summary.message, contains('lastPossible=3'));
      expect(summary.message, contains('hasMorePages=true'));
    },
  );

  test(
    'rejects a page until it matches the active exact scope and generation',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 7,
      );

      expect(
        cache.commit(
          _page(scope, ordinal: 1, total: 48, nextCursor: null, generation: 6),
        ),
        isFalse,
      );
      expect(cache.stalePageDiscardCount, 1);
      expect(cache.loadedEntryCount, 24);
      expect(cache.pageForOrdinal(1), isNull);
    },
  );

  testWidgets(
    'publishes scroll extent only for the contiguous drawable page frontier',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 658, nextCursor: _cursor(0)),
        generation: 11,
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);

      final firstDrawableExtent = cache.pageHeightForOrdinal(0);
      expect(cache.contentHeight, firstDrawableExtent);
      expect(cache.pageOrdinalForOffset(firstDrawableExtent + 1), 0);

      expect(
        cache.commit(
          _page(scope, ordinal: 1, total: 658, nextCursor: _cursor(1)),
        ),
        isTrue,
      );
      expect(cache.contentHeight, greaterThan(firstDrawableExtent));
      expect(cache.pageOrdinalForOffset(firstDrawableExtent + 1), 1);
      expect(cache.preparedPageForOrdinal(1), isNotNull);
    },
  );

  test('rejects a noncontiguous page without publishing a phantom extent', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 658, nextCursor: _cursor(0)),
      generation: 11,
    );
    final firstExtent = cache.contentHeight;

    expect(
      cache.commit(
        _page(scope, ordinal: 2, total: 658, nextCursor: _cursor(2)),
      ),
      isFalse,
    );
    expect(
      cache.lastCommitRejection,
      CommittedLogPageCommitRejection.nonContiguousOrdinal,
    );
    expect(cache.pageForOrdinal(2), isNull);
    expect(cache.contentHeight, firstExtent);
  });

  testWidgets('publishes an atomically prepared vertical page', (tester) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 11,
    );
    cache.configureSurfaceWidth(378);

    expect(cache.isVerticalRenderingActive, isFalse);
    expect(cache.preparedPageForOrdinal(0), isNull);

    expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
    // The initial page normally paints from the rail preview scene. Its
    // independently prepared fallback may arrive after the layout turn.
    expect(cache.preparedPageForOrdinal(0), anyOf(isNull, isNotNull));
    expect(cache.textLayoutMissCount, 0);

    expect(
      cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null)),
      isTrue,
    );
    expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
    expect(cache.layoutAt(24), isNotNull);
    expect(cache.textLayoutMissCount, 0);
  });

  testWidgets(
    'a non-empty root cannot promote to a scrollable vertical surface without a paint source',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      cache.configureSurfaceWidth(378);

      expect(cache.hasDrawableRootFallback, isFalse);
      expect(
        cache.activateVerticalRendering(hasExactRailScene: false),
        isFalse,
        reason:
            'The promotion guard rejects the transient post-seed state until '
            'its bounded asynchronous fallback becomes drawable.',
      );
      expect(cache.isVerticalRenderingActive, isFalse);

      await tester.pump();

      expect(
        cache.hasDrawableRootFallback,
        isTrue,
        reason:
            'The root fallback is prepared after the root commit while the '
            'rail scene is still the normal first-gesture source. A first '
            'vertical gesture must never have to start its own safety layout.',
      );

      expect(
        cache.activateVerticalRendering(hasExactRailScene: false),
        isTrue,
        reason:
            'The exact committed root fallback makes vertical promotion safe '
            'even if the normally preferred rail scene is unavailable.',
      );
      expect(cache.isVerticalRenderingActive, isTrue);
      expect(cache.preparedPageForOrdinal(0), isNotNull);
      expect(cache.contentHeight, greaterThan(0));
    },
  );

  testWidgets(
    'root fallback is rebuilt for the newest exact surface width before promotion',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      cache.configureSurfaceWidth(378);
      await tester.pump();

      expect(cache.hasDrawableRootFallback, isTrue);
      expect(cache.preparedPageForOrdinal(0)?.surfaceWidth, 378);

      // Simulate two layout passes before the old fallback microtask can
      // complete. The only drawable root after the next turn must match the
      // final width, never one stale rotation in between.
      cache.configureSurfaceWidth(480);
      cache.configureSurfaceWidth(520);
      expect(cache.hasDrawableRootFallback, isFalse);
      await tester.pump();

      expect(cache.hasDrawableRootFallback, isTrue);
      expect(cache.preparedPageForOrdinal(0)?.surfaceWidth, 520);
      expect(cache.activateVerticalRendering(hasExactRailScene: false), isTrue);
    },
  );

  testWidgets(
    'a new committed rail frame resets vertical layouts until vertical scroll',
    (tester) async {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 11,
      );
      cache.configureSurfaceWidth(378);
      expect(cache.activateVerticalRendering(hasExactRailScene: true), isTrue);
      expect(cache.preparedTextRowCount, 0);

      // `DashboardPresentationController.onCommittedFrame` is a rail-settle
      // callback. It must never recreate vertical paragraphs just because the
      // surface width from the prior scope is still known.
      cache.seed(
        _page(
          scope,
          ordinal: 0,
          total: 48,
          nextCursor: _cursor(0),
          generation: 12,
        ),
        generation: 12,
      );

      expect(cache.isVerticalRenderingActive, isFalse);
      expect(cache.preparedTextRowCount, 0);
      expect(cache.preparedPageForOrdinal(0), isNull);
    },
  );

  for (final totalRows in <int>[24, 94, 658, 1000, 10000, 50000, 100000]) {
    test(
      '$totalRows committed rows retain bounded page/layout data at the end',
      () {
        final cache = CommittedLogViewportCache(pageSize: 24);
        addTearDown(cache.dispose);
        final lastOrdinal = (totalRows - 1) ~/ 24;
        cache.seed(
          _sizedPage(scope, ordinal: 0, total: totalRows, generation: 1),
          generation: 1,
        );
        for (var ordinal = 1; ordinal <= lastOrdinal; ordinal += 1) {
          expect(
            cache.commit(
              _sizedPage(
                scope,
                ordinal: ordinal,
                total: totalRows,
                generation: 1,
              ),
            ),
            isTrue,
          );
          cache.updateVisibleRowWindow(
            start: ordinal * 24,
            end: (ordinal + 1) * 24,
          );
        }

        cache.updateVisibleRowWindow(start: lastOrdinal * 24, end: totalRows);
        expect(cache.loadedEntryCount, totalRows);
        expect(
          cache.pageForOrdinal(lastOrdinal),
          isNotNull,
          reason: 'The active visible page must survive the five-page cap.',
        );
        expect(cache.rowAt(totalRows - 1)?.row.entryId, 'row-${totalRows - 1}');
        expect(
          cache.estimatedBytes,
          lessThanOrEqualTo(cache.maximumRetainedBytes),
        );
        expect(cache.rootPagePresent, isTrue);
        expect(cache.rootPageRows, lessThanOrEqualTo(24));
        expect(
          cache.retainedPageCount,
          lessThanOrEqualTo(5),
          reason:
              'The root is pinned separately; even a 100k-row traversal may '
              'not grow the movable prepared working set.',
        );
        expect(cache.preparedTextRowCount, 0);
        expect(
          (cache.report()['cursorAnchors'] as int),
          lessThanOrEqualTo(cache.maximumCursorAnchors),
        );
      },
    );
  }
}

CommittedLogPage _page(
  CurrentLedgerQueryScope scope, {
  required int ordinal,
  required int total,
  required Map<String, Object?>? nextCursor,
  int generation = 11,
}) {
  final start = ordinal * 24;
  final rows = List<DashboardLogRowViewModel>.generate(
    24,
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

CommittedLogPage _sizedPage(
  CurrentLedgerQueryScope scope, {
  required int ordinal,
  required int total,
  required int generation,
}) {
  final start = ordinal * 24;
  final count = (total - start).clamp(0, 24);
  final rows = List<DashboardLogRowViewModel>.generate(
    count,
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
      groups: rows.isEmpty
          ? const <DashboardDayLogGroupViewModel>[]
          : <DashboardDayLogGroupViewModel>[
              DashboardDayLogGroupViewModel(
                dateKey: '2026-07-01',
                dayLabel: '2026. július 1.',
                rows: rows,
              ),
            ],
      entryCount: total,
      nextCursor: start + count < total ? _cursor(ordinal) : null,
      direction: scope.direction,
    ),
  );
}
