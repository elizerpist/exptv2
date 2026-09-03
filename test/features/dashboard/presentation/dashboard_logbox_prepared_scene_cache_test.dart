import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('default scene preparation budget reserves TextPainter headroom', () {
    expect(
      DashboardLogBoxPreparedSceneCache.defaultMaxContiguousUiSliceMicros,
      1000,
    );
  });

  test(
    'an empty retained window reuses the active canonical empty scene without construction',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final activePayload = _payload(month: 7, rowCount: 0);
      final adjacentPayload = _payload(month: 8, rowCount: 0);
      final active = DashboardLogBoxSceneWindow(
        identity: 'active-empty',
        payloads: <DashboardLogViewportState>[activePayload],
      );
      final adjacent = DashboardLogBoxSceneWindow(
        identity: 'adjacent-empty',
        payloads: <DashboardLogViewportState>[adjacentPayload],
      );

      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      FluviDiagnosticLogger.clear();

      await cache.prepareRetainedWindow(
        retainedKey: 'adjacent-empty',
        window: adjacent,
        surfaceWidth: 378,
      );

      expect(cache.hasRetainedWindow(adjacent), isTrue);
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'SCENE_WINDOW_PREPARE_STARTED')
            .isEmpty,
        isTrue,
      );
      final retained = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'SCENE_WINDOW_CANONICAL_EMPTY_RETAINED',
      );
      expect(retained.message, contains('retainedKeyDigest='));
      expect(retained.message, isNot(contains('adjacent-empty')));
    },
  );

  test(
    'render-critical readiness preparation cannot be superseded by Summary maintenance',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final readinessWindow = DashboardLogBoxSceneWindow(
        identity: 'readiness-30-rows',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 30)],
      );
      final summaryWindow = DashboardLogBoxSceneWindow(
        identity: 'summary-parent-130-rows',
        payloads: <DashboardLogViewportState>[
          _payload(month: 8, rowCount: 130),
        ],
      );
      final readinessYielded = Completer<void>();
      final releaseReadiness = Completer<void>();

      final readiness = cache.prepareWindow(
        window: readinessWindow,
        surfaceWidth: 378,
        intent: DashboardLogBoxScenePreparationIntent.renderCriticalReadiness,
        yieldEveryRows: 1,
        yieldToBackground: () {
          if (!readinessYielded.isCompleted) readinessYielded.complete();
          return releaseReadiness.future;
        },
      );
      await readinessYielded.future;

      var summaryCompleted = false;
      final summary = cache
          .prepareRetainedWindow(
            retainedKey: 'summary-parent',
            window: summaryWindow,
            surfaceWidth: 378,
            intent:
                DashboardLogBoxScenePreparationIntent.speculativeMaintenance,
          )
          .whenComplete(() => summaryCompleted = true);
      await Future<void>.microtask(() {});

      expect(
        cache.activePreparationIntent,
        DashboardLogBoxScenePreparationIntent.renderCriticalReadiness,
      );
      expect(summaryCompleted, isFalse);

      releaseReadiness.complete();
      await readiness;
      await summary;

      expect(cache.hasRetainedWindow(summaryWindow), isTrue);
      expect(
        FluviDiagnosticLogger.entries.where(
          (entry) =>
              entry.stage == 'SCENE_WINDOW_PREPARE_CANCELLED' &&
              entry.queryKey == readinessWindow.identity,
        ),
        isEmpty,
      );
    },
  );

  test(
    'generic maintenance cancellation cannot terminate render-critical readiness',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final readinessWindow = DashboardLogBoxSceneWindow(
        identity: 'readiness-generic-cancel-guard',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 2)],
      );
      final yielded = Completer<void>();
      final release = Completer<void>();
      final readiness = cache.prepareWindow(
        window: readinessWindow,
        surfaceWidth: 378,
        intent: DashboardLogBoxScenePreparationIntent.renderCriticalReadiness,
        yieldEveryRows: 1,
        yieldToBackground: () {
          if (!yielded.isCompleted) yielded.complete();
          return release.future;
        },
      );
      await yielded.future;

      // This models the controller's existing generic maintenance-cancel
      // capability. It must not invalidate the mandatory readiness owner.
      cache.cancelInFlightPreparation();
      release.complete();

      await expectLater(readiness, completes);
      expect(cache.activeWindowIdentity, isNull);
      expect(
        cache.preparedSceneCount,
        0,
        reason: 'Preparation is complete but intentionally not activated.',
      );
    },
  );

  test(
    'RED: retained Summary preparation is denied before layout when every candidate bank is protected',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 1,
      );
      addTearDown(cache.dispose);
      final protected = DashboardLogBoxSceneWindow(
        identity: 'protected-summary-parent',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 1)],
      );
      final adjacent = DashboardLogBoxSceneWindow(
        identity: 'adjacent-summary-parent',
        payloads: <DashboardLogViewportState>[_payload(month: 6, rowCount: 1)],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'protected-candidate',
        window: protected,
        surfaceWidth: 378,
      );
      cache.setProtectedCandidateKeys(<String>{'protected-candidate'});
      FluviDiagnosticLogger.clear();

      final admission = cache.admitRetainedWindow(
        retainedKey: 'summary-adjacent',
        window: adjacent,
      );

      expect(admission.isAdmitted, isFalse);
      expect(admission.reason, 'allCandidateBanksProtected');
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'SCENE_WINDOW_PREPARE_STARTED',
        ),
        isEmpty,
      );
    },
  );

  test(
    'RED: rejected retained-candidate diagnostics use a bounded identity digest',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 1,
      );
      addTearDown(cache.dispose);
      final protected = DashboardLogBoxSceneWindow(
        identity: 'protected-diagnostic-parent',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 1)],
      );
      final rejected = DashboardLogBoxSceneWindow(
        identity: 'rejected-diagnostic-parent',
        payloads: <DashboardLogViewportState>[_payload(month: 6, rowCount: 1)],
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'protected-diagnostic-candidate',
        window: protected,
        surfaceWidth: 378,
      );
      cache.setProtectedCandidateKeys(<String>{
        'protected-diagnostic-candidate',
      });
      final enormousKey = List<String>.generate(
        31,
        (day) => 'expense|2026-07-${(day + 1).toString().padLeft(2, '0')}',
      ).join('|');
      FluviDiagnosticLogger.clear();

      await expectLater(
        cache.prepareCandidateWindow(
          candidateKey: enormousKey,
          window: rejected,
          surfaceWidth: 378,
        ),
        throwsStateError,
      );

      final event = FluviDiagnosticLogger.entries.singleWhere(
        (entry) => entry.stage == 'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED',
      );
      expect(event.scope, isNot(contains(enormousKey)));
      expect(event.scope, contains('candidateDigest='));
      expect(event.scope!.length, lessThan(280));
    },
  );

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
    'RED: a retained focus base restores exact payloads across a new presentation identity',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final base = DashboardLogBoxSceneWindow(
        identity: 'base-presentation-epoch-1',
        payloads: <DashboardLogViewportState>[payload],
      );
      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);

      expect(
        cache.retainActiveWindow(retainedKey: 'focus-base', window: base),
        isTrue,
      );

      // Focus clear has an independent presentation epoch, but it returns to
      // the same immutable base payload. It must reactivate the retained
      // exact scene instead of treating window identity as a data mismatch.
      final restore = DashboardLogBoxSceneWindow(
        identity: 'base-presentation-epoch-2',
        payloads: <DashboardLogViewportState>[payload],
      );
      expect(cache.hasRetainedWindow(restore), isTrue);

      cache.activateWindow(restore);

      expect(cache.activeWindowIdentity, restore.identity);
      expect(cache.sceneFor(payload), isNotNull);
      expect(cache.hasRetainedFocusBaseWindow, isFalse);
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

      final disposedRowsBeforeCancellation =
          cache.report()['preparedResourceLeaseDisposedRows'] as int;
      final disposedPaintersBeforeCancellation =
          cache.report()['preparedResourceLeaseDisposedPainters'] as int;

      cache.cancelInFlightPreparation();

      expect(cache.activeWindowIdentity, julyWindow.identity);
      expect(cache.activeWindowDigest, activeDigestBeforeCancellation);
      expect(cache.stagedWindowIdentity, isNull);
      expect(cache.sceneFor(july), isNotNull);
      expect(cache.sceneFor(june), isNull);
      expect(
        cache.report()['preparedResourceLeaseDisposedRows'],
        disposedRowsBeforeCancellation + 3,
      );
      expect(
        cache.report()['preparedResourceLeaseDisposedPainters'],
        disposedPaintersBeforeCancellation + 1,
      );
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
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
      final scenePreparesBefore = cache.scenePrepareNewCount;
      final rowLayoutsBefore = cache.rowLayoutNewCount;

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
        cache.scenePrepareNewCount,
        scenePreparesBefore,
        reason:
            'a bank-count impossibility is known before any TextPainter work',
      );
      expect(cache.rowLayoutNewCount, rowLayoutsBefore);
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
    'candidate hotset admission preserves deterministic protected priority before work',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 32,
      );
      addTearDown(cache.dispose);
      final priority = <String>[
        for (var index = 0; index < 7; index += 1) 'candidate-$index',
      ];

      final admission = cache.admitCandidateHotset(priority);

      expect(admission.admittedCandidateKeys, <String>[
        'candidate-0',
        'candidate-1',
        'candidate-2',
        'candidate-3',
        'candidate-4',
        'candidate-5',
      ]);
      expect(admission.deferredCandidateKeys, <String>['candidate-6']);
      expect(admission.capacityReason, 'candidateBankCapacity');
      expect(cache.protectedCandidateBankCount, 6);
      expect(cache.scenePrepareNewCount, 0);
      expect(cache.rowLayoutNewCount, 0);

      final windows = <String, DashboardLogBoxSceneWindow>{
        for (var index = 0; index < 7; index += 1)
          'candidate-$index': DashboardLogBoxSceneWindow(
            identity: 'candidate-window-$index',
            payloads: <DashboardLogViewportState>[
              _payload(month: index + 1, rowCount: 1),
            ],
          ),
      };
      for (final candidateKey in admission.admittedCandidateKeys) {
        await cache.prepareCandidateWindow(
          candidateKey: candidateKey,
          window: windows[candidateKey]!,
          surfaceWidth: 378,
        );
      }

      // The seventh key is deferred by its planner result; this test never
      // asks it to prepare until an actual cache-owned slot is made available.
      expect(
        cache.hasCandidateWindow(
          windows['candidate-6']!,
          candidateKey: 'candidate-6',
        ),
        isFalse,
      );
      expect(cache.retainedCandidateBankCount, 6);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);

      final promoted = cache.admitCandidateHotset(<String>[
        'candidate-6',
        'candidate-0',
        'candidate-1',
        'candidate-2',
        'candidate-3',
        'candidate-4',
        'candidate-5',
      ]);
      expect(promoted.admittedCandidateKeys.first, 'candidate-6');
      expect(promoted.deferredCandidateKeys, <String>['candidate-5']);

      await cache.prepareCandidateWindow(
        candidateKey: 'candidate-6',
        window: windows['candidate-6']!,
        surfaceWidth: 378,
      );

      for (var index = 0; index < 5; index += 1) {
        expect(
          cache.hasCandidateWindow(
            windows['candidate-$index']!,
            candidateKey: 'candidate-$index',
          ),
          isTrue,
        );
      }
      expect(
        cache.hasCandidateWindow(
          windows['candidate-5']!,
          candidateKey: 'candidate-5',
        ),
        isFalse,
      );
      expect(
        cache.hasCandidateWindow(
          windows['candidate-6']!,
          candidateKey: 'candidate-6',
        ),
        isTrue,
      );
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
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

  test(
    'RED: evicting a creator candidate preserves the active borrower resource',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final creator = DashboardLogBoxSceneWindow(
        identity: 'creator-candidate',
        payloads: <DashboardLogViewportState>[payload],
      );
      final borrower = DashboardLogBoxSceneWindow(
        identity: 'active-borrower',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'creator',
        window: creator,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'borrower',
        window: borrower,
        surfaceWidth: 378,
      );
      cache.activateWindow(borrower);

      final activeScene = cache.railCriticalSceneFor(payload)!;
      final activeLayout = activeScene.rowFor(payload.flatItems.first.row)!;
      final activeHeader = activeScene.dayHeaderFor(
        payload.flatItems.first.dayLabel!,
      )!;
      expect(activeLayout.title.debugDisposed, isFalse);
      expect(activeHeader.debugDisposed, isFalse);

      // The borrower is active and holds the exact same physical layouts
      // created by the retained creator. Evicting the creator must release
      // only its bank lease, never destroy these still-renderable paragraphs.
      cache.discardCandidateWindow('creator');

      expect(activeLayout.title.debugDisposed, isFalse);
      expect(activeLayout.secondary.debugDisposed, isFalse);
      expect(activeLayout.amount.debugDisposed, isFalse);
      expect(activeLayout.time.debugDisposed, isFalse);
      expect(activeHeader.debugDisposed, isFalse);
      expect(
        identical(
          cache
              .railCriticalSceneFor(payload)!
              .rowFor(payload.flatItems.first.row),
          activeLayout,
        ),
        isTrue,
      );
    },
  );

  test(
    'RED: final candidate lease releases shared resources exactly once',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final sharedPayload = _payload(month: 7, rowCount: 3);
      final replacementPayload = _payload(month: 8, rowCount: 1);
      final creator = DashboardLogBoxSceneWindow(
        identity: 'creator-for-final-release',
        payloads: <DashboardLogViewportState>[sharedPayload],
      );
      final borrower = DashboardLogBoxSceneWindow(
        identity: 'borrower-for-final-release',
        payloads: <DashboardLogViewportState>[sharedPayload],
      );
      final replacement = DashboardLogBoxSceneWindow(
        identity: 'replacement-after-final-release',
        payloads: <DashboardLogViewportState>[replacementPayload],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'creator',
        window: creator,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'borrower',
        window: borrower,
        surfaceWidth: 378,
      );
      cache.activateWindow(borrower);
      final sharedScene = cache.railCriticalSceneFor(sharedPayload)!;
      final sharedLayout = sharedScene.rowFor(
        sharedPayload.flatItems.first.row,
      )!;
      final sharedHeader = sharedScene.dayHeaderFor(
        sharedPayload.flatItems.first.dayLabel!,
      )!;

      cache.discardCandidateWindow('creator');
      await cache.prepareWindow(window: replacement, surfaceWidth: 378);
      cache.activateWindow(replacement);

      expect(sharedLayout.title.debugDisposed, isTrue);
      expect(sharedHeader.debugDisposed, isTrue);
      expect(
        cache.report()['preparedResourceLeaseDisposedRows'],
        3,
        reason: 'The three shared layouts have just lost their final lease.',
      );
      expect(
        cache.report()['preparedResourceLeaseDisposedPainters'],
        2,
        reason:
            'Only the creator empty painter and shared day header are final.',
      );

      cache.dispose();

      final report = cache.report();
      expect(report['preparedResourceLeaseLiveRows'], 0);
      expect(report['preparedResourceLeaseLivePainters'], 0);
      expect(report['preparedResourceLeaseDisposedRows'], 4);
      expect(report['preparedResourceLeaseDisposedPainters'], 4);
      expect(report['preparedResourceLeaseUnderflows'], 0);
      expect(report['preparedResourceLeaseDuplicateReleases'], 0);
      expect(report['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'creator eviction waits for active and retained sibling leases',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final sharedPayload = _payload(month: 7, rowCount: 3);
      final replacementPayload = _payload(month: 8, rowCount: 1);
      final creator = DashboardLogBoxSceneWindow(
        identity: 'creator-with-two-borrowers',
        payloads: <DashboardLogViewportState>[sharedPayload],
      );
      final activeBorrower = DashboardLogBoxSceneWindow(
        identity: 'active-borrower-with-sibling',
        payloads: <DashboardLogViewportState>[sharedPayload],
      );
      final retainedSibling = DashboardLogBoxSceneWindow(
        identity: 'retained-sibling-borrower',
        payloads: <DashboardLogViewportState>[sharedPayload],
      );
      final replacement = DashboardLogBoxSceneWindow(
        identity: 'replacement-after-sibling-lease',
        payloads: <DashboardLogViewportState>[replacementPayload],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'creator',
        window: creator,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'active-borrower',
        window: activeBorrower,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'retained-sibling',
        window: retainedSibling,
        surfaceWidth: 378,
      );
      cache.activateWindow(activeBorrower);

      final sharedScene = cache.railCriticalSceneFor(sharedPayload)!;
      final sharedLayout = sharedScene.rowFor(
        sharedPayload.flatItems.first.row,
      )!;
      final sharedHeader = sharedScene.dayHeaderFor(
        sharedPayload.flatItems.first.dayLabel!,
      )!;

      cache.discardCandidateWindow('creator');
      expect(sharedLayout.title.debugDisposed, isFalse);
      expect(sharedHeader.debugDisposed, isFalse);

      await cache.prepareWindow(window: replacement, surfaceWidth: 378);
      cache.activateWindow(replacement);
      expect(
        sharedLayout.title.debugDisposed,
        isFalse,
        reason: 'The retained sibling still leases the shared layout.',
      );
      expect(sharedHeader.debugDisposed, isFalse);

      cache.discardCandidateWindow('retained-sibling');
      expect(sharedLayout.title.debugDisposed, isTrue);
      expect(sharedHeader.debugDisposed, isTrue);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'same-key candidate replacement retains shared resources before old release',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final payload = _payload(month: 7, rowCount: 3);
      final creator = DashboardLogBoxSceneWindow(
        identity: 'same-key-creator',
        payloads: <DashboardLogViewportState>[payload],
      );
      final first = DashboardLogBoxSceneWindow(
        identity: 'same-key-first',
        payloads: <DashboardLogViewportState>[payload],
      );
      final replacement = DashboardLogBoxSceneWindow(
        identity: 'same-key-replacement',
        payloads: <DashboardLogViewportState>[payload],
      );

      await cache.prepareCandidateWindow(
        candidateKey: 'creator',
        window: creator,
        surfaceWidth: 378,
      );
      final createdRows = cache.rowLayoutNewCount;
      await cache.prepareCandidateWindow(
        candidateKey: 'same-key',
        window: first,
        surfaceWidth: 378,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'same-key',
        window: replacement,
        surfaceWidth: 378,
      );

      expect(cache.rowLayoutNewCount, createdRows);
      expect(
        cache.hasCandidateWindow(replacement, candidateKey: 'same-key'),
        isTrue,
      );
      cache.activateWindow(replacement);
      final activeLayout = cache
          .railCriticalSceneFor(payload)!
          .rowFor(payload.flatItems.first.row)!;

      cache.discardCandidateWindow('creator');
      expect(
        activeLayout.title.debugDisposed,
        isFalse,
        reason:
            'The active replacement took its lease before old-key eviction.',
      );
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'cache disposal releases active staged retained and focus-base leases once',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      final basePayload = _payload(month: 7, rowCount: 2);
      final candidatePayload = _payload(month: 7, rowCount: 2);
      final stagedPayload = _payload(month: 8, rowCount: 1);
      final base = DashboardLogBoxSceneWindow(
        identity: 'dispose-base',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final candidate = DashboardLogBoxSceneWindow(
        identity: 'dispose-retained-candidate',
        payloads: <DashboardLogViewportState>[candidatePayload],
      );
      final staged = DashboardLogBoxSceneWindow(
        identity: 'dispose-staged',
        payloads: <DashboardLogViewportState>[stagedPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      final baseLayout = cache
          .railCriticalSceneFor(basePayload)!
          .rowFor(basePayload.flatItems.first.row)!;
      expect(
        cache.retainActiveWindow(retainedKey: 'focus-base', window: base),
        isTrue,
      );
      await cache.prepareCandidateWindow(
        candidateKey: 'candidate',
        window: candidate,
        surfaceWidth: 378,
      );
      await cache.prepareWindow(window: staged, surfaceWidth: 378);

      expect(cache.report()['preparedResourceLeaseLiveRows'], greaterThan(0));
      expect(
        cache.report()['preparedResourceLeaseLivePainters'],
        greaterThan(0),
      );
      cache.dispose();

      final report = cache.report();
      expect(baseLayout.title.debugDisposed, isTrue);
      expect(report['preparedResourceLeaseLiveRows'], 0);
      expect(report['preparedResourceLeaseLivePainters'], 0);
      expect(report['preparedResourceLeaseUnderflows'], 0);
      expect(report['preparedResourceLeaseDuplicateReleases'], 0);
      expect(report['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'discarding a focus-base lease preserves an active candidate borrower',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final basePayload = _payload(month: 7, rowCount: 3);
      final focusedPayload = _payload(month: 8, rowCount: 1);
      final base = DashboardLogBoxSceneWindow(
        identity: 'focus-base-source',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final focused = DashboardLogBoxSceneWindow(
        identity: 'focus-temporary-active',
        payloads: <DashboardLogViewportState>[focusedPayload],
      );
      final borrowerScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'base-restored'},
      );
      final borrowerPayload = basePayload.copyWith(queryKey: borrowerScope.key);
      final borrower = DashboardLogBoxSceneWindow(
        identity: 'focus-base-borrower',
        payloads: <DashboardLogViewportState>[borrowerPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      expect(
        cache.retainActiveWindow(retainedKey: 'focus-base', window: base),
        isTrue,
      );
      await cache.prepareWindow(window: focused, surfaceWidth: 378);
      cache.activateWindow(focused);
      await cache.prepareCandidateWindow(
        candidateKey: 'focus-base-borrower',
        window: borrower,
        surfaceWidth: 378,
      );
      cache.activateWindow(borrower);
      final activeLayout = cache
          .railCriticalSceneFor(borrowerPayload)!
          .rowFor(borrowerPayload.flatItems.first.row)!;
      final activeHeader = cache
          .railCriticalSceneFor(borrowerPayload)!
          .dayHeaderFor(borrowerPayload.flatItems.first.dayLabel!)!;

      cache.discardRetainedFocusBaseWindow('focus-base');

      expect(activeLayout.title.debugDisposed, isFalse);
      expect(activeHeader.debugDisposed, isFalse);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'six prepared chip removals keep every active borrower drawable before input',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);

      for (var categoryCount = 6; categoryCount >= 1; categoryCount -= 1) {
        final rowCount = categoryCount == 1 ? 4 : categoryCount;
        final creatorPayload = _payload(
          month: categoryCount,
          rowCount: rowCount,
        );
        final borrowerScope = CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
          categoryIds: <String>{'remaining-$categoryCount'},
        );
        final borrowerPayload = creatorPayload.copyWith(
          queryKey: borrowerScope.key,
        );
        final creator = DashboardLogBoxSceneWindow(
          identity: 'chip-$categoryCount-creator',
          payloads: <DashboardLogViewportState>[creatorPayload],
        );
        final borrower = DashboardLogBoxSceneWindow(
          identity: 'chip-$categoryCount-borrower',
          payloads: <DashboardLogViewportState>[borrowerPayload],
        );

        await cache.prepareCandidateWindow(
          candidateKey: 'chip-$categoryCount-creator',
          window: creator,
          surfaceWidth: 378,
        );
        await cache.prepareCandidateWindow(
          candidateKey: 'chip-$categoryCount-borrower',
          window: borrower,
          surfaceWidth: 378,
        );
        cache.activateWindow(borrower);
        cache.discardCandidateWindow('chip-$categoryCount-creator');

        final scene = cache.railCriticalSceneFor(borrowerPayload)!;
        expect(scene.isCompletelyPrepared, isTrue);
        for (final item in borrowerPayload.flatItems) {
          final layout = scene.rowFor(item.row)!;
          expect(layout.title.debugDisposed, isFalse);
          expect(layout.secondary.debugDisposed, isFalse);
          expect(layout.amount.debugDisposed, isFalse);
          expect(layout.time.debugDisposed, isFalse);
        }
        final header = scene.dayHeaderFor(
          borrowerPayload.flatItems.first.dayLabel!,
        )!;
        expect(header.debugDisposed, isFalse);
      }

      expect(cache.textLayoutMissCount, 0);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
      expect(cache.report()['preparedResourceLeaseDoubleDisposes'], 0);
    },
  );

  test(
    'an active base window can be retained and restored without rebuilding its scene',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final basePayload = _payload(month: 7, rowCount: 3);
      final focusedPayload = _payload(month: 7, rowCount: 1);
      final base = DashboardLogBoxSceneWindow(
        identity: 'base-income-july',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final focused = DashboardLogBoxSceneWindow(
        identity: 'focused-income-july',
        payloads: <DashboardLogViewportState>[focusedPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      final scenePreparationsBeforeFocus = cache.completedPreparationEpoch;
      final rowLayoutsBeforeFocus = cache.rowLayoutNewCount;

      expect(
        cache.retainActiveWindow(
          retainedKey: 'ephemeral-focus-base',
          window: base,
        ),
        isTrue,
      );
      expect(cache.hasRetainedWindow(base), isTrue);

      await cache.prepareWindow(window: focused, surfaceWidth: 378);
      cache.activateWindow(focused);
      expect(cache.activeWindowIdentity, focused.identity);

      cache.activateWindow(base);

      expect(cache.activeWindowIdentity, base.identity);
      expect(cache.sceneFor(basePayload), isNotNull);
      expect(
        cache.completedPreparationEpoch,
        scenePreparationsBeforeFocus + 1,
        reason:
            'Only the focused scene was prepared. Restoring the retained '
            'base must not construct another scene bank.',
      );
      expect(
        cache.rowLayoutNewCount,
        rowLayoutsBeforeFocus,
        reason:
            'The narrower focus scene reuses the base row layout; restoring '
            'the base must not allocate a second copy.',
      );
      expect(cache.retainedCandidateBankCount, 0);
    },
  );

  test(
    'a focused subset can stage from active prepared resources without TextPainter work',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final basePayload = _payload(month: 7, rowCount: 3);
      final focusedPayload = _payload(month: 7, rowCount: 1);
      final base = DashboardLogBoxSceneWindow(
        identity: 'active-base-income-july',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final focused = DashboardLogBoxSceneWindow(
        identity: 'active-resource-focused-income-july',
        payloads: <DashboardLogViewportState>[focusedPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      final preparationEpoch = cache.completedPreparationEpoch;
      final newLayouts = cache.rowLayoutNewCount;

      expect(cache.stageWindowFromActiveResources(focused), isTrue);
      expect(cache.stagedWindowIdentity, focused.identity);
      expect(cache.completedPreparationEpoch, preparationEpoch);
      expect(cache.rowLayoutNewCount, newLayouts);
      cache.activateWindow(focused);

      expect(cache.activeWindowIdentity, focused.identity);
      expect(cache.sceneFor(focusedPayload), isNotNull);
      expect(cache.textLayoutMissCount, 0);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
    },
  );

  test(
    'RED LIVE-ROOT: a compact focused payload stages from prepared row resources',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final basePayload = _deferredPayload(month: 7, rowCount: 3);
      final focusedPayload = _deferredPayload(month: 7, rowCount: 3);
      final base = DashboardLogBoxSceneWindow(
        identity: 'active-compact-base-income-july',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final focused = DashboardLogBoxSceneWindow(
        identity: 'active-compact-focused-income-july',
        payloads: <DashboardLogViewportState>[focusedPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      final newLayouts = cache.rowLayoutNewCount;
      expect(focusedPayload.isRichProjected, isFalse);

      expect(
        cache.stageLivePreviewWindowFromPreparedResources(focused),
        isTrue,
      );
      expect(focusedPayload.isRichProjected, isTrue);
      cache.activateWindow(focused);
      expect(cache.sceneFor(focusedPayload), isNotNull);
      expect(cache.rowLayoutNewCount, newLayouts);
      expect(cache.textLayoutMissCount, 0);
      expect(cache.activeWindowIdentity, focused.identity);
    },
  );

  test(
    'RED REENTRANT-MIND: a borrowing release candidate coexists with an oversized bounded live resource bank',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 3,
        maximumRetainedCandidateRows: 2,
      );
      addTearDown(cache.dispose);
      final activePayload = _deferredPayload(month: 6, rowCount: 1);
      final resourcePayload = _deferredPayload(month: 7, rowCount: 3);
      final releasePayload = _deferredPayload(month: 7, rowCount: 1);
      final active = DashboardLogBoxSceneWindow(
        identity: 'mind-active-before-drag',
        payloads: <DashboardLogViewportState>[activePayload],
      );
      final resources = DashboardLogBoxSceneWindow(
        identity: 'mind-live-resource-universe',
        payloads: <DashboardLogViewportState>[resourcePayload],
      );
      final release = DashboardLogBoxSceneWindow(
        identity: 'mind-canonical-release',
        payloads: <DashboardLogViewportState>[releasePayload],
      );

      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
        resourceKey: 'mind-live-resource',
        window: resources,
        surfaceWidth: 378,
      );
      expect(cache.hasLiveInteractionResourceBank, isTrue);
      expect(cache.retainedCandidatePreparedRowCount, 3);

      await cache.prepareCandidateWindow(
        candidateKey: 'mind-release',
        window: release,
        surfaceWidth: 378,
      );

      expect(
        cache.hasCandidateWindow(release, candidateKey: 'mind-release'),
        isTrue,
      );
      expect(cache.hasLiveInteractionResourceBank, isTrue);
      expect(
        cache.retainedCandidatePreparedRowCount,
        3,
        reason:
            'The canonical subset borrows immutable live row resources and '
            'must not consume a second copy or evict next-drag readiness.',
      );
    },
  );

  test(
    'b166 regression: Avatar preparation retains a Mind resource and Mind replacement is lane-local',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 32,
      );
      addTearDown(cache.dispose);
      final active = DashboardLogBoxSceneWindow(
        identity: 'active-before-lane-resources',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 6, rowCount: 1),
        ],
      );
      final mindFirst = DashboardLogBoxSceneWindow(
        identity: 'mind-base-first',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 7, rowCount: 3),
        ],
      );
      final avatar = DashboardLogBoxSceneWindow(
        identity: 'avatar-base',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 8, rowCount: 4),
        ],
      );
      final mindSecond = DashboardLogBoxSceneWindow(
        identity: 'mind-base-second',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 9, rowCount: 5),
        ],
      );

      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);

      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
        resourceKey: 'mind-first',
        window: mindFirst,
        surfaceWidth: 378,
      );
      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
        resourceKey: 'avatar',
        window: avatar,
        surfaceWidth: 378,
      );

      expect(
        cache.hasLiveInteractionResourceWindow(
          mindFirst,
          lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
          resourceKey: 'mind-first',
        ),
        isTrue,
      );
      expect(
        cache.hasLiveInteractionResourceWindow(
          avatar,
          lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
          resourceKey: 'avatar',
        ),
        isTrue,
      );

      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
        resourceKey: 'mind-second',
        window: mindSecond,
        surfaceWidth: 378,
      );

      expect(
        cache.hasLiveInteractionResourceWindow(
          mindSecond,
          lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
          resourceKey: 'mind-second',
        ),
        isTrue,
      );
      expect(
        cache.hasLiveInteractionResourceWindow(
          avatar,
          lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
          resourceKey: 'avatar',
        ),
        isTrue,
      );
      expect(
        cache.hasCandidateWindow(mindFirst, candidateKey: 'mind-first'),
        isFalse,
      );
      expect(cache.report()['liveInteractionResourceLanes'], 2);
      expect(cache.report()['liveInteractionResourcePreparingLanes'], 0);
    },
  );

  test(
    'b166 regression: a superseded Avatar preparation releases only its stale lane candidate',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 6,
        maximumRetainedCandidateRows: 32,
      );
      addTearDown(cache.dispose);
      final active = DashboardLogBoxSceneWindow(
        identity: 'active-before-superseded-avatar-resource',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 6, rowCount: 1),
        ],
      );
      final mind = DashboardLogBoxSceneWindow(
        identity: 'mind-universe-survives-avatar-supersession',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 7, rowCount: 3),
        ],
      );
      final staleAvatar = DashboardLogBoxSceneWindow(
        identity: 'stale-avatar-target',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 8, rowCount: 4),
        ],
      );
      final newestAvatar = DashboardLogBoxSceneWindow(
        identity: 'newest-avatar-target',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 9, rowCount: 5),
        ],
      );
      final staleYielded = Completer<void>();
      final releaseStale = Completer<void>();
      var firstYield = true;

      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
        resourceKey: 'mind-resource',
        window: mind,
        surfaceWidth: 378,
      );

      final stalePreparation = cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
        resourceKey: 'avatar-stale',
        window: staleAvatar,
        surfaceWidth: 378,
        yieldEveryRows: 1,
        yieldToBackground: () {
          if (firstYield) {
            firstYield = false;
            staleYielded.complete();
            return releaseStale.future;
          }
          return Future<void>.value();
        },
      );
      await staleYielded.future;
      final newestPreparation = cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
        resourceKey: 'avatar-newest',
        window: newestAvatar,
        surfaceWidth: 378,
      );

      releaseStale.complete();
      await Future.wait<void>(<Future<void>>[
        stalePreparation,
        newestPreparation,
      ]);

      expect(
        cache.hasLiveInteractionResourceWindow(
          mind,
          lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
          resourceKey: 'mind-resource',
        ),
        isTrue,
      );
      expect(
        cache.hasCandidateWindow(staleAvatar, candidateKey: 'avatar-stale'),
        isFalse,
      );
      expect(
        cache.hasLiveInteractionResourceWindow(
          newestAvatar,
          lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
          resourceKey: 'avatar-newest',
        ),
        isTrue,
      );
      expect(cache.report()['liveInteractionResourceLanes'], 2);
      expect(cache.report()['liveInteractionResourcePreparingLanes'], 0);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'RESOURCE|REJECT' &&
              (event.scope?.contains('supersededBeforeRetention') ?? false),
        ),
        isTrue,
      );
    },
  );

  test(
    'live resource baseline does not admit additional unique rows beyond its bounded footprint',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache(
        maximumRetainedCandidateBanks: 3,
        maximumRetainedCandidateRows: 2,
      );
      addTearDown(cache.dispose);
      final resources = DashboardLogBoxSceneWindow(
        identity: 'bounded-live-resource-universe',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 7, rowCount: 3),
        ],
      );
      final unrelated = DashboardLogBoxSceneWindow(
        identity: 'unrelated-canonical-candidate',
        payloads: <DashboardLogViewportState>[
          _deferredPayload(month: 8, rowCount: 1),
        ],
      );

      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.mindAmountPreview,
        resourceKey: 'bounded-live-resource',
        window: resources,
        surfaceWidth: 378,
      );

      await expectLater(
        cache.prepareCandidateWindow(
          candidateKey: 'unrelated-candidate',
          window: unrelated,
          surfaceWidth: 378,
        ),
        throwsStateError,
      );
      expect(cache.retainedCandidatePreparedRowCount, 3);
      expect(cache.hasLiveInteractionResourceBank, isTrue);
    },
  );

  test(
    'discarding a stale active-resource stage releases only its exact bank',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final basePayload = _payload(month: 7, rowCount: 3);
      final focusedPayload = _payload(month: 7, rowCount: 1);
      final base = DashboardLogBoxSceneWindow(
        identity: 'active-base-for-stale-stage',
        payloads: <DashboardLogViewportState>[basePayload],
      );
      final focused = DashboardLogBoxSceneWindow(
        identity: 'stale-active-resource-focused',
        payloads: <DashboardLogViewportState>[focusedPayload],
      );

      await cache.prepareWindow(window: base, surfaceWidth: 378);
      cache.activateWindow(base);
      expect(cache.stageWindowFromActiveResources(focused), isTrue);
      expect(cache.stagedWindowIdentity, focused.identity);

      cache.discardStagedActiveResourceWindow(focused);

      expect(cache.stagedWindowIdentity, isNull);
      expect(cache.stageWindowFromActiveResources(focused), isTrue);
      expect(cache.report()['preparedResourceLeaseUnderflows'], 0);
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
    'disposing during a cooperative private lease releases its resources before teardown',
    () async {
      var nowMicros = 0;
      final cache = DashboardLogBoxPreparedSceneCache(
        nowMicros: () => nowMicros += 3000,
      );
      final leaseCheckpoint = Completer<void>();
      final releaseLeaseCheckpoint = Completer<void>();
      var checkpoints = 0;
      final window = DashboardLogBoxSceneWindow(
        identity: 'dispose-private-lease',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 1)],
      );

      final preparing = cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        yieldEveryRows: 1,
        yieldToBackground: () {
          checkpoints += 1;
          if (checkpoints == 8) {
            leaseCheckpoint.complete();
            return releaseLeaseCheckpoint.future;
          }
          return Future<void>.microtask(() {});
        },
      );

      await leaseCheckpoint.future;
      cache.dispose();
      expect(cache.report()['preparedResourceLeaseLiveRows'], 0);
      expect(cache.report()['preparedResourceLeaseLivePainters'], 0);

      releaseLeaseCheckpoint.complete();
      await expectLater(preparing, throwsA(isA<StateError>()));
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
    'RED: deferred rich projection checkpoints inside one payload before it becomes visible',
    () async {
      var nowMicros = 0;
      final cache = DashboardLogBoxPreparedSceneCache(
        nowMicros: () => nowMicros += 1000,
      );
      addTearDown(cache.dispose);
      final payload = _deferredPayload(month: 7, rowCount: 48);
      final window = DashboardLogBoxSceneWindow(
        identity: 'rich-projection-checkpoint',
        payloads: <DashboardLogViewportState>[payload],
      );
      final projectionCheckpoint = Completer<void>();
      final releaseProjection = Completer<void>();
      var yields = 0;

      final preparing = cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        yieldEveryRows: 64,
        maxContiguousUiSliceMicros: 3000,
        yieldToBackground: () {
          yields += 1;
          if (yields == 2) {
            projectionCheckpoint.complete();
            return releaseProjection.future;
          }
          return Future<void>.value();
        },
      );
      await projectionCheckpoint.future;

      expect(payload.isRichProjected, isFalse);
      expect(payload.richProjectedRowCount, inInclusiveRange(1, 47));
      expect(cache.preparedSceneCount, 0);

      releaseProjection.complete();
      await preparing;
      expect(payload.isRichProjected, isTrue);
      expect(payload.richProjectedRowCount, 48);
      expect(
        cache.lastPrepareLargestContiguousUiSliceMicros,
        lessThanOrEqualTo(4000),
      );
    },
  );

  test(
    'completed preparation epoch advances only for a fully prepared bank',
    () async {
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      final window = DashboardLogBoxSceneWindow(
        identity: 'completed-preparation-epoch',
        payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 3)],
      );

      expect(cache.completedPreparationEpoch, 0);

      await expectLater(
        cache.prepareWindow(
          window: window,
          surfaceWidth: 378,
          yieldToBackground: () async => cache.cancelInFlightPreparation(),
        ),
        throwsA(isA<DashboardLogBoxScenePreparationCancelled>()),
      );

      expect(cache.completedPreparationEpoch, 0);

      await cache.prepareWindow(window: window, surfaceWidth: 378);

      expect(cache.completedPreparationEpoch, 1);
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
      var nowMicros = 0;
      var forceFinalHandOffBudget = false;
      final cache = DashboardLogBoxPreparedSceneCache(
        nowMicros: () => forceFinalHandOffBudget ? (nowMicros += 3000) : 0,
      );
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
          if (checkpoints == 29) {
            forceFinalHandOffBudget = true;
          } else if (checkpoints == 30) {
            forceFinalHandOffBudget = false;
          }
        },
      );

      // One initial checkpoint, then nine bounded chunks for scanning and
      // text layouts, one header chunk, nine scene-assembly chunks, and a
      // final budget-exhausted hand-off before completion proof / immutable-
      // bank ownership.
      // Counting only scenes would collapse the final term to one 64-row
      // synchronous slice despite the eight-row contract; leaving the
      // completion hand-off synchronous would let lease accounting inherit
      // that same final UI slice.
      expect(checkpoints, 30);
      expect(cache.lastPrepareYieldCount, checkpoints);
      expect(cache.stagedWindowManifest!.isComplete, isTrue);
      expect(cache.stagedWindowManifest!.completeSceneCount, 9);
    },
  );

  test('one large scene assembles its row map in bounded work units', () async {
    final cache = DashboardLogBoxPreparedSceneCache(nowMicros: () => 0);
    addTearDown(cache.dispose);
    final window = DashboardLogBoxSceneWindow(
      identity: 'large-scene-row-map',
      payloads: <DashboardLogViewportState>[_payload(month: 7, rowCount: 24)],
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

    // Initial scheduling, row discovery and TextPainter preparation each
    // need their own bounded work units. The 24-row scene map itself must
    // add three more hand-offs, rather than materialising all 24 entries
    // before its first budget check.
    expect(checkpoints, 10);
    expect(cache.stagedWindowManifest!.isComplete, isTrue);
  });

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

DashboardLogViewportState _deferredPayload({
  required int month,
  required int rowCount,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  final rows = List<DashboardLedgerEntry>.generate(
    rowCount,
    (index) => DashboardLedgerEntry(
      id: 'deferred-$month-$index',
      partnerId: 'partner-$index',
      categoryId: 'category-$index',
      direction: LedgerDirection.income.name,
      amountMinor: index + 1,
      bookedLocalEpochDay: 20_000 - index ~/ 4,
      bookedLocalTimeMinutes: 600 - index,
      partnerDisplayName: 'Partner $index',
      categoryDisplayName: 'Category',
      categoryColorId: 'cyan',
      categoryIconId: 'wallet',
    ),
  );
  return DashboardLogViewportState.deferredPreparedOrdered(
    scope: scope,
    revision: 1,
    entries: rows,
    entryCount: rowCount,
    nextCursor: null,
  );
}
