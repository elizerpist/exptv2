import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'the active rail-critical bank exposes complete exact scenes and lookup metrics',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final window = DashboardLogBoxSceneWindow(
        identity: 'rail-critical-rev-1',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareWindow(window: window, surfaceWidth: 378);
      cache.activateWindow(window);

      final bank = cache.railCriticalSceneBank;
      expect(bank.isComplete, isTrue);
      expect(bank.sceneCount, 1);
      expect(bank.uniqueRowLayoutCount, 3);
      expect(cache.railCriticalSceneFor(payload), isNotNull);
      expect(cache.railCriticalLookupHitCount, 1);
      expect(cache.railCriticalLookupMissCount, 0);
      expect(cache.report()['railCriticalSceneCount'], 1);
    },
  );

  test(
    'a prepared scene window makes each populated row and header atomically available',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final window = DashboardLogBoxSceneWindow(
        identity: 'income|month:2026-07',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareWindow(window: window, surfaceWidth: 378);
      cache.activateWindow(window);

      final scene = cache.sceneFor(payload);
      expect(scene, isNotNull);
      for (final item in payload.flatItems) {
        expect(scene!.rowFor(item.row), isNotNull);
        if (item.dayLabel case final String label) {
          expect(scene.dayHeaderFor(label), isNotNull);
        }
      }
      expect(cache.preparedRowCount, 3);
      expect(cache.textLayoutMissCount, 0);
    },
  );

  test(
    'rotation keeps a completed later parent scene private until activation',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final july = _payload(month: 7, rowCount: 2);
      final february = _payload(month: 2, rowCount: 4);
      final julyWindow = DashboardLogBoxSceneWindow(
        identity: 'income|month:2026-07',
        payloads: <DashboardLogViewportState>[july],
      );
      final februaryWindow = DashboardLogBoxSceneWindow(
        identity: 'income|month:2026-02',
        payloads: <DashboardLogViewportState>[february],
      );

      await cache.prepareWindow(window: julyWindow, surfaceWidth: 378);
      cache.activateWindow(julyWindow);
      await cache.prepareWindow(
        window: februaryWindow,
        surfaceWidth: 378,
        retainViewportId: july.viewportId,
      );

      expect(cache.sceneFor(july), isNotNull);
      expect(cache.stagedWindowIdentity, februaryWindow.identity);
      expect(cache.sceneFor(february), isNull);

      cache.activateWindow(februaryWindow);
      expect(cache.activeWindowIdentity, februaryWindow.identity);
      expect(cache.sceneFor(february), isNotNull);
      expect(
        cache.preparedRowCount,
        lessThanOrEqualTo(cache.maximumPinnedRows),
      );
    },
  );

  test(
    'a completed staging bank is invisible and discardable until activation',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final july = _payload(month: 7, rowCount: 2);
      final june = _payload(month: 6, rowCount: 3);
      final julyWindow = DashboardLogBoxSceneWindow(
        identity: 'income|month:2026-07',
        payloads: <DashboardLogViewportState>[july],
      );
      final juneWindow = DashboardLogBoxSceneWindow(
        identity: 'income|month:2026-06',
        payloads: <DashboardLogViewportState>[june],
      );

      await cache.prepareWindow(window: julyWindow, surfaceWidth: 378);
      cache.activateWindow(julyWindow);
      final activeDigestBeforeCancellation = cache.activeWindowDigest;

      await cache.prepareWindow(
        window: juneWindow,
        surfaceWidth: 378,
        retainViewportId: july.viewportId,
      );

      expect(cache.activeWindowIdentity, julyWindow.identity);
      expect(cache.stagedWindowIdentity, juneWindow.identity);
      expect(cache.sceneFor(july), isNotNull);
      expect(cache.sceneFor(june), isNull);

      cache.cancelInFlightPreparation();

      expect(cache.activeWindowIdentity, julyWindow.identity);
      expect(cache.activeWindowDigest, activeDigestBeforeCancellation);
      expect(cache.stagedWindowIdentity, isNull);
      expect(cache.sceneFor(july), isNotNull);
      expect(cache.sceneFor(june), isNull);
    },
  );

  test(
    'bounded Query candidate banks stay invisible and activate independently',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 2,
        maximumRetainedCandidateRows: 16,
      );
      addTearDown(cache.dispose);
      final july = _payload(month: 7, rowCount: 2);
      final june = _payload(month: 6, rowCount: 3);
      final may = _payload(month: 5, rowCount: 4);
      final julyWindow = DashboardLogBoxSceneWindow(
        identity: 'active-july',
        payloads: <DashboardLogViewportState>[july],
      );
      final juneWindow = DashboardLogBoxSceneWindow(
        identity: 'candidate-june',
        payloads: <DashboardLogViewportState>[june],
      );
      final mayWindow = DashboardLogBoxSceneWindow(
        identity: 'candidate-may',
        payloads: <DashboardLogViewportState>[may],
      );

      await cache.prepareWindow(window: julyWindow, surfaceWidth: 378);
      cache.activateWindow(julyWindow);
      await cache.prepareCandidateWindow(
        candidateKey: 'june',
        window: juneWindow,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'may',
        window: mayWindow,
        surfaceWidth: 378,
      );

      expect(cache.activeWindowIdentity, julyWindow.identity);
      expect(cache.sceneFor(july), isNotNull);
      expect(cache.sceneFor(june), isNull);
      expect(cache.sceneFor(may), isNull);
      expect(cache.retainedCandidateBankCount, 2);
      expect(cache.retainedCandidatePreparedRowCount, 7);

      cache.activateWindow(juneWindow);
      expect(cache.sceneFor(june), isNotNull);
      expect(cache.retainedCandidateBankCount, 1);
      cache.activateWindow(mayWindow);
      expect(cache.sceneFor(may), isNotNull);
      expect(cache.retainedCandidateBankCount, 0);
    },
  );

  test(
    'retained candidate lookup promotes the exact bank before bounded LRU eviction',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 2,
        maximumRetainedCandidateRows: 16,
      );
      addTearDown(cache.dispose);
      final june = DashboardLogBoxSceneWindow(
        identity: 'candidate-june',
        payloads: <DashboardLogViewportState>[_payload(month: 6, rowCount: 2)],
      );
      final may = DashboardLogBoxSceneWindow(
        identity: 'candidate-may',
        payloads: <DashboardLogViewportState>[_payload(month: 5, rowCount: 2)],
      );
      final april = DashboardLogBoxSceneWindow(
        identity: 'candidate-april',
        payloads: <DashboardLogViewportState>[_payload(month: 4, rowCount: 2)],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'june',
        window: june,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'may',
        window: may,
        surfaceWidth: 378,
      );

      expect(cache.hasCandidateWindow(june, candidateKey: 'june'), isTrue);

      await cache.prepareCandidateWindow(
        candidateKey: 'april',
        window: april,
        surfaceWidth: 378,
      );

      expect(cache.hasCandidateWindow(june, candidateKey: 'june'), isTrue);
      expect(cache.hasCandidateWindow(may, candidateKey: 'may'), isFalse);
      expect(cache.hasCandidateWindow(april, candidateKey: 'april'), isTrue);
    },
  );

  test(
    'protected chip-neighbour banks survive LRU pressure before unrelated banks',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 2,
        maximumRetainedCandidateRows: 16,
      );
      addTearDown(cache.dispose);
      final protected = DashboardLogBoxSceneWindow(
        identity: 'protected-neighbour',
        payloads: <DashboardLogViewportState>[_payload(month: 6, rowCount: 2)],
      );
      final unrelated = DashboardLogBoxSceneWindow(
        identity: 'unrelated-candidate',
        payloads: <DashboardLogViewportState>[_payload(month: 5, rowCount: 2)],
      );
      final newest = DashboardLogBoxSceneWindow(
        identity: 'newest-candidate',
        payloads: <DashboardLogViewportState>[_payload(month: 4, rowCount: 2)],
      );

      cache.setProtectedCandidateKeys(const <String>{'protected'});
      await cache.prepareCandidateWindow(
        candidateKey: 'protected',
        window: protected,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'unrelated',
        window: unrelated,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'newest',
        window: newest,
        surfaceWidth: 378,
      );

      expect(
        cache.hasCandidateWindow(protected, candidateKey: 'protected'),
        isTrue,
      );
      expect(
        cache.hasCandidateWindow(unrelated, candidateKey: 'unrelated'),
        isFalse,
      );
      expect(cache.hasCandidateWindow(newest, candidateKey: 'newest'), isTrue);
    },
  );

  test(
    'candidate preparation rejects self-eviction behind a full protected hotset',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 32,
      );
      addTearDown(cache.dispose);
      final protectedKeys = <String>{
        for (var index = 0; index < 6; index += 1) 'expense-neighbour-$index',
      };
      cache.setProtectedCandidateKeys(protectedKeys);
      for (var index = 0; index < 6; index += 1) {
        await cache.prepareCandidateWindow(
          candidateKey: 'expense-neighbour-$index',
          window: DashboardLogBoxSceneWindow(
            identity: 'expense-neighbour-window-$index',
            payloads: <DashboardLogViewportState>[
              _payload(month: index + 1, rowCount: 1),
            ],
          ),
          surfaceWidth: 378,
        );
      }

      final foregroundWindow = DashboardLogBoxSceneWindow(
        identity: 'income-editor-window',
        payloads: <DashboardLogViewportState>[_payload(month: 8, rowCount: 1)],
      );

      await expectLater(
        cache.prepareCandidateWindow(
          candidateKey: 'income-editor',
          window: foregroundWindow,
          surfaceWidth: 378,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('QUERY_CANDIDATE_SCENE_RETENTION_REJECTED'),
          ),
        ),
      );
      expect(cache.retainedCandidateBankCount, 6);
      expect(cache.protectedCandidateBankCount, 6);
      expect(
        cache.hasCandidateWindow(
          foregroundWindow,
          candidateKey: 'income-editor',
        ),
        isFalse,
      );
    },
  );

  test(
    'a retained candidate shares exact active layouts without owning their disposal',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final active = DashboardLogBoxSceneWindow(
        identity: 'active-july',
        payloads: <DashboardLogViewportState>[payload],
      );
      final candidate = DashboardLogBoxSceneWindow(
        identity: 'candidate-same-july',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      final createdBeforeCandidate = cache.rowLayoutNewCount;

      await cache.prepareCandidateWindow(
        candidateKey: 'same-july',
        window: candidate,
        surfaceWidth: 378,
      );

      expect(cache.rowLayoutNewCount, createdBeforeCandidate);
      expect(cache.rowLayoutReuseCount, greaterThanOrEqualTo(3));
      expect(cache.sharedPreparedRowLayoutCount, greaterThanOrEqualTo(3));

      cache.discardCandidateWindow('same-july');

      final activeScene = cache.railCriticalSceneFor(payload);
      expect(activeScene, isNotNull);
      for (final item in payload.flatItems) {
        expect(activeScene!.rowFor(item.row), isNotNull);
      }
    },
  );

  test('retained candidate memory counts shared layouts once', () async {
    final cache = DashboardLogBoxPreparedSceneCache(
      maximumRetainedCandidateBanks: 3,
      maximumRetainedCandidateRows: 8,
    );
    addTearDown(cache.dispose);
    final shared = _payload(month: 7, rowCount: 3);
    final first = DashboardLogBoxSceneWindow(
      identity: 'candidate-first',
      payloads: <DashboardLogViewportState>[shared],
    );
    final second = DashboardLogBoxSceneWindow(
      identity: 'candidate-second',
      payloads: <DashboardLogViewportState>[
        shared,
        _payload(month: 8, rowCount: 0),
      ],
    );

    await cache.prepareCandidateWindow(
      candidateKey: 'first',
      window: first,
      surfaceWidth: 378,
    );
    await cache.prepareCandidateWindow(
      candidateKey: 'second',
      window: second,
      surfaceWidth: 378,
    );

    expect(cache.retainedCandidateBankCount, 2);
    expect(cache.retainedCandidatePreparedRowCount, 3);
    expect(
      cache.retainedCandidateEstimatedBytes,
      lessThan(2 * 6 * 2048),
      reason:
          'Two retained banks may reference the same immutable row layouts, '
          'which must be budgeted once rather than once per bank.',
    );
  });

  test(
    'mid-preparation cancellation leaves every active populated and empty scene drawable',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final july = _payload(month: 7, rowCount: 2);
      final junePopulated = _payload(month: 6, rowCount: 3);
      final juneEmpty = _payload(month: 5, rowCount: 0);
      final activeWindow = DashboardLogBoxSceneWindow(
        identity: 'active-july-and-june',
        payloads: <DashboardLogViewportState>[july, junePopulated, juneEmpty],
      );
      final replacement = DashboardLogBoxSceneWindow(
        identity: 'replacement-april',
        payloads: <DashboardLogViewportState>[_payload(month: 4, rowCount: 4)],
      );
      await cache.prepareWindow(window: activeWindow, surfaceWidth: 378);
      cache.activateWindow(activeWindow);
      final digestBeforeCancellation = cache.activeWindowDigest;

      final enteredPreparation = Completer<void>();
      final releasePreparation = Completer<void>();
      final preparing = cache.prepareWindow(
        window: replacement,
        surfaceWidth: 378,
        yieldEveryRows: 1,
        yieldToBackground: () {
          if (!enteredPreparation.isCompleted) enteredPreparation.complete();
          return releasePreparation.future;
        },
      );
      await enteredPreparation.future;
      cache.cancelInFlightPreparation();
      releasePreparation.complete();
      await expectLater(
        preparing,
        throwsA(isA<DashboardLogBoxScenePreparationCancelled>()),
      );

      expect(cache.activeWindowDigest, digestBeforeCancellation);
      for (final payload in <DashboardLogViewportState>[
        july,
        junePopulated,
        juneEmpty,
      ]) {
        final scene = cache.sceneFor(payload);
        expect(scene, isNotNull);
        expect(scene!.isCompletelyPrepared, isTrue);
        for (final item in payload.flatItems) {
          expect(scene.rowFor(item.row), isNotNull);
        }
      }
      expect(cache.textLayoutMissCount, 0);
      expect(cache.readySceneIncompleteCount, 0);
      expect(cache.activeWindowPartialPublishCount, 0);
      expect(cache.stagingObjectRenderedCount, 0);
    },
  );

  test(
    'time-budgeted preparation does not yield once per eight rows when a slice has budget',
    () async {
      var yields = 0;
      final cache = DashboardLogBoxPreparedSceneCache(nowMicros: () => 0);
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 77);
      final window = DashboardLogBoxSceneWindow(
        identity: 'time-budgeted-window',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        yieldEveryRows: 64,
        maxContiguousUiSliceMicros: 3000,
        yieldToBackground: () {
          yields += 1;
          return Future<void>.microtask(() {});
        },
      );

      expect(
        yields,
        lessThanOrEqualTo(4),
        reason:
            'The row count is only a secondary safety limit. A 77-row '
            'window with available UI budget must not incur a full scheduler '
            'yield every small fixed batch.',
      );
      expect(
        cache.lastPrepareLargestContiguousUiSliceMicros,
        lessThanOrEqualTo(3000),
      );
    },
  );

  test(
    '100 deterministic cancellation boundaries preserve the active bank',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final sibling = _payload(month: 6, rowCount: 3);
      final emptySibling = _payload(month: 5, rowCount: 0);
      final activeWindow = DashboardLogBoxSceneWindow(
        identity: 'active-siblings',
        payloads: <DashboardLogViewportState>[sibling, emptySibling],
      );
      await cache.prepareWindow(window: activeWindow, surfaceWidth: 378);
      cache.activateWindow(activeWindow);
      final digest = cache.activeWindowDigest;

      for (var run = 0; run < 100; run += 1) {
        var checkpoint = 0;
        final cancellationBoundary = 1 + (run % 7);
        final replacement = DashboardLogBoxSceneWindow(
          identity: 'replacement-$run',
          payloads: <DashboardLogViewportState>[
            _payload(month: 1 + (run % 4), rowCount: 8),
          ],
        );
        await expectLater(
          cache.prepareWindow(
            window: replacement,
            surfaceWidth: 378,
            yieldEveryRows: 1,
            yieldToBackground: () async {
              checkpoint += 1;
              if (checkpoint == cancellationBoundary) {
                cache.cancelInFlightPreparation();
              }
            },
          ),
          throwsA(isA<DashboardLogBoxScenePreparationCancelled>()),
        );
        expect(cache.activeWindowDigest, digest);
        expect(cache.sceneFor(sibling), isNotNull);
        expect(cache.sceneFor(emptySibling), isNotNull);
        expect(cache.stagedWindowIdentity, isNull);
      }
      expect(cache.textLayoutMissCount, 0);
      expect(cache.readySceneIncompleteCount, 0);
      expect(cache.activeWindowPartialPublishCount, 0);
      expect(cache.stagingObjectRenderedCount, 0);
    },
  );

  test(
    'a scene-window cap fails before it can become partially active',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumPinnedRows: 2,
        maximumRetainedScenes: 4,
      );
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final window = DashboardLogBoxSceneWindow(
        identity: 'too-large',
        payloads: <DashboardLogViewportState>[payload],
      );

      await expectLater(
        cache.prepareWindow(window: window, surfaceWidth: 378),
        throwsA(isA<StateError>()),
      );
      expect(cache.activeWindowIdentity, isNull);
      expect(cache.sceneFor(payload), isNull);
    },
  );

  test(
    'runtime scene lookup requires the exact prepared content and width',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 2);
      final window = DashboardLogBoxSceneWindow(
        identity: 'exact-key',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        devicePixelRatio: 2,
      );
      cache.activateWindow(window);

      final scene = cache.sceneFor(payload);
      expect(scene, isNotNull);
      expect(scene!.matches(payload, 378), isTrue);
      expect(scene.matches(payload, 379), isFalse);
      expect(scene.matches(payload.copyWith(revision: 2), 378), isFalse);
      expect(cache.sceneFor(payload, devicePixelRatio: 2), isNotNull);
      expect(cache.sceneFor(payload, devicePixelRatio: 3), isNull);
    },
  );

  test(
    'one complete active bank serves 100 child selections without layout work',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payloads = List<DashboardLogViewportState>.generate(
        12,
        (month) => _payload(month: month + 1, rowCount: 3),
      );
      final window = DashboardLogBoxSceneWindow(
        identity: '100-crossings',
        payloads: payloads,
      );

      await cache.prepareWindow(window: window, surfaceWidth: 378);
      cache.activateWindow(window);
      final generationBeforeCrossings = cache.generation;
      final rowsBeforeCrossings = cache.preparedRowCount;
      for (var crossing = 0; crossing < 100; crossing += 1) {
        final payload = payloads[crossing % payloads.length];
        final scene = cache.sceneFor(payload);
        expect(scene, isNotNull);
        expect(
          payload.flatItems.every((item) => scene!.rowFor(item.row) != null),
          isTrue,
        );
      }

      expect(cache.generation, generationBeforeCrossings);
      expect(cache.preparedRowCount, rowsBeforeCrossings);
      expect(cache.textLayoutMissCount, 0);
    },
  );

  test(
    'scene assembly yields by bounded row work rather than by scene count',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payloads = List<DashboardLogViewportState>.generate(
        9,
        (month) => _payload(month: month + 1, rowCount: 8),
      );
      final window = DashboardLogBoxSceneWindow(
        identity: 'bounded-scene-assembly',
        payloads: payloads,
      );
      var checkpoints = 0;

      await cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        yieldEveryRows: 8,
        yieldToBackground: () async {
          checkpoints += 1;
        },
      );

      // One initial checkpoint, then nine bounded chunks for scanning and
      // text layouts, one header chunk, and nine scene-assembly chunks.
      // Counting only scenes would collapse the final term to one 64-row
      // synchronous slice despite the eight-row contract.
      expect(checkpoints, greaterThanOrEqualTo(29));
      expect(cache.lastPrepareYieldCount, checkpoints);
      expect(cache.stagedWindowManifest!.isComplete, isTrue);
      expect(cache.stagedWindowManifest!.completeSceneCount, 9);
    },
  );

  test(
    'cooperative preparation yields before a slow row batch reaches its time budget',
    () async {
      var nowMicros = 0;
      final cache = DashboardLogBoxPreparedSceneCache(
        nowMicros: () => nowMicros += 3000,
      );
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 8);
      final window = DashboardLogBoxSceneWindow(
        identity: 'time-budgeted-preparation',
        payloads: <DashboardLogViewportState>[payload],
      );
      var checkpoints = 0;

      await cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        yieldEveryRows: 8,
        yieldToBackground: () async {
          checkpoints += 1;
        },
      );

      // With the eight-row cap alone this needs four checkpoints. The fake
      // clock makes one row cross the 3 ms budget, so the scheduler
      // must yield before the nominal row-count cap is reached.
      expect(checkpoints, greaterThan(4));
      expect(
        cache.lastPrepareLargestContiguousUiSliceMicros,
        lessThanOrEqualTo(6000),
      );
    },
  );
}

DashboardLogViewportState _payload({
  required int month,
  required int rowCount,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  return DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    entryCount: rowCount,
    nextCursor: null,
    direction: scope.direction,
    groups: <DashboardDayLogGroupViewModel>[
      DashboardDayLogGroupViewModel(
        dateKey: '2026-${month.toString().padLeft(2, '0')}-07',
        dayLabel: '2026. ${month.toString().padLeft(2, '0')}. 07.',
        rows: List<DashboardLogRowViewModel>.generate(
          rowCount,
          (index) => DashboardLogRowViewModel(
            entryId: 'income-$month-$index',
            displayName: 'Transaction $month/$index',
            categoryDisplayName: 'Category',
            formattedAmount: '${index + 1} 000 Ft',
            displayTime: '12:${index.toString().padLeft(2, '0')}',
            amountStyle: LogAmountStyle.income,
            categoryColorId: 'cyan',
            categoryIconId: 'wallet',
            semanticLabel: 'Transaction $month/$index',
          ),
        ),
      ),
    ],
  );
}
