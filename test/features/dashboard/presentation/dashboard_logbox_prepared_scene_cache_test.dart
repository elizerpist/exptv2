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
