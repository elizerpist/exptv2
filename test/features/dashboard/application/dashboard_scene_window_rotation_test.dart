import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'parent commit waits for the complete target scene window and gates input',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final events = <String>[];
      final prepared = Completer<void>();
      DashboardLogBoxSceneWindow? target;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          events.add('prepare:${window.identity}');
          target = window;
          expect(retainViewportId, core.visibleFrames.value!.logBox.viewportId);
          await prepared.future;
        },
        activate: (window) => events.add('activate:${window.identity}'),
      );

      final rotation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(core.sceneWindowPreparing.value, isTrue);
      expect(core.navigation.state.monthCursor.month, 7);
      core.setRailOpen(true);
      expect(core.navigation.state.isRailOpen, isFalse);

      prepared.complete();
      await rotation;

      expect(core.navigation.state.monthCursor.month, 6);
      expect(core.sceneWindowPreparing.value, isFalse);
      expect(target, isNotNull);
      expect(target!.payloads, isNotEmpty);
      expect(events, <String>[
        'prepare:${target!.identity}',
        'activate:${target!.identity}',
      ]);
    },
  );

  test('the active bank already covers plane and direction targets', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    addTearDown(core.dispose);
    addTearDown(cache.dispose);
    await core.bootstrap();
    final initial = core.renderCriticalLogBoxSceneWindow();
    await cache.prepareWindow(window: initial, surfaceWidth: 378);
    cache.activateWindow(initial);

    core.navigatePlane(finer: false);
    final yearWindow = core.renderCriticalLogBoxSceneWindow();
    expect(yearWindow.payloads, isNotEmpty);
    expect(yearWindow.coverageIdentity, initial.coverageIdentity);
    expect(
      yearWindow.payloads.every((payload) => cache.sceneFor(payload) != null),
      isTrue,
    );

    core.selectDirection(TransactionDirection.expense);
    final expenseWindow = core.renderCriticalLogBoxSceneWindow();
    expect(expenseWindow.coverageIdentity, initial.coverageIdentity);
    expect(
      expenseWindow.payloads.every(
        (payload) => cache.sceneFor(payload) != null,
      ),
      isTrue,
    );
    expect(cache.textLayoutMissCount, 0);
  });

  test(
    'a settled distant month rebases the complete next-finer day scene bank',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final julyWindow = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: julyWindow, surfaceWidth: 378);
      cache.activateWindow(julyWindow);
      var postSettlePrepareCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          postSettlePrepareCount += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
          );
        },
        activate: cache.activateWindow,
        report: cache.report,
      );

      core.setRailOpen(true);
      final aprilLogicalIndex = core.motion.catalog.logicalIndexForValue(4);
      core.semanticCrossed(aprilLogicalIndex);
      core.settleRail(aprilLogicalIndex);

      expect(postSettlePrepareCount, 0);
      core.navigatePlane(finer: true);
      expect(core.navigation.state.plane, TimePlane.year);
      await pumpEventQueue();
      expect(postSettlePrepareCount, 1);

      core.navigatePlane(finer: true);
      final aprilDays = core.motion.catalog.entries;
      expect(aprilDays, isNotEmpty);
      for (final day in aprilDays) {
        final payload = core.preparedIndex!.frameForKey(day.queryKey).logBox;
        expect(
          cache.sceneFor(payload),
          isNotNull,
          reason: 'April day ${day.value} must be lookup-ready after settle.',
        );
      }
      expect(cache.textLayoutMissCount, 0);
      final sceneReport =
          core.exportPhysicalRailReport()['sceneWindow']!
              as Map<String, Object?>;
      expect(sceneReport['activeCoverageIdentity'], contains('month:2026-04'));
      expect(sceneReport['desiredCoverageIdentity'], contains('month:2026-04'));
      expect(sceneReport['rebaseInFlight'], isFalse);
      expect(sceneReport['queuedRebase'], isFalse);
      expect(
        sceneReport['lastRebaseReason'],
        'railSettledTemporalAnchorChanged',
      );
      expect(sceneReport['criticalCacheMisses'], 0);
    },
  );

  test(
    'post-settle coverage includes both empty and populated April day scenes',
    () async {
      int entryCountForScope(CurrentLedgerQueryScope scope) =>
          switch (scope.timeScope) {
            DayScope(:final date)
                when date.year == 2026 && date.month == 4 && date.day == 12 =>
              8,
            DayScope(:final date)
                when date.year == 2026 && date.month == 4 && date.day == 8 =>
              0,
            _ => 1,
          };
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          entryCountForScope: entryCountForScope,
          previewRowCountForScope: entryCountForScope,
        ),
      );

      final julyWindow = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: julyWindow, surfaceWidth: 378);
      cache.activateWindow(julyWindow);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
        ),
        activate: cache.activateWindow,
      );

      core.setRailOpen(true);
      final aprilLogicalIndex = core.motion.catalog.logicalIndexForValue(4);
      core.semanticCrossed(aprilLogicalIndex);
      core.settleRail(aprilLogicalIndex);
      await pumpEventQueue();
      expect(core.navigation.state.monthCursor.month, 4);
      core.navigatePlane(finer: true);

      DashboardLogViewportState payloadForDay(int day) => core
          .presentation
          .index!
          .frameForKey(
            core.motion.catalog.entries
                .singleWhere((entry) => entry.value == day)
                .queryKey,
          )
          .logBox;
      final emptyApril8 = payloadForDay(8);
      final populatedApril12 = payloadForDay(12);
      expect(emptyApril8.entryCount, 0);
      expect(populatedApril12.entryCount, 8);
      expect(cache.sceneFor(emptyApril8), isNotNull);
      expect(cache.sceneFor(populatedApril12), isNotNull);
      final populatedScene = cache.sceneFor(populatedApril12)!;
      expect(
        populatedApril12.flatItems.every(
          (item) => populatedScene.rowFor(item.row) != null,
        ),
        isTrue,
      );
      expect(cache.textLayoutMissCount, 0);
    },
  );

  test(
    'rapid settles serialize preparation and activate only latest coverage',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final firstPreparation = Completer<void>();
      final activated = <DashboardLogBoxSceneWindow>[];
      var concurrentPrepares = 0;
      var maximumConcurrentPrepares = 0;
      var prepareCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepareCount += 1;
          concurrentPrepares += 1;
          maximumConcurrentPrepares =
              maximumConcurrentPrepares > concurrentPrepares
              ? maximumConcurrentPrepares
              : concurrentPrepares;
          try {
            if (prepareCount == 1) await firstPreparation.future;
          } finally {
            concurrentPrepares -= 1;
          }
        },
        activate: activated.add,
      );
      core.setRailOpen(true);

      void settleMonth(int value) {
        final index = core.motion.catalog.logicalIndexForValue(value);
        core.semanticCrossed(index);
        core.settleRail(index);
      }

      settleMonth(6);
      await Future<void>.microtask(() {});
      expect(prepareCount, 1);
      settleMonth(5);
      settleMonth(4);
      firstPreparation.complete();
      await pumpEventQueue();

      expect(maximumConcurrentPrepares, 1);
      expect(prepareCount, 2);
      expect(activated, hasLength(1));
      expect(activated.single.coverageIdentity!.visibleMonth, 4);
    },
  );

  test(
    'a day settle within active month coverage skips scene preparation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 4, 12),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.recordInitialSceneWindowActivation(
        core.renderCriticalLogBoxSceneWindow(),
      );
      var prepareCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepareCount += 1;
        },
        activate: (_) {},
      );

      core.setRailOpen(true);
      final day11 = core.motion.catalog.logicalIndexForValue(11);
      core.semanticCrossed(day11);
      core.settleRail(day11);
      await pumpEventQueue();

      expect(prepareCount, 0);
    },
  );

  test(
    'a settled SUM year provides every next-finer month preview scene',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initial = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
        ),
        activate: cache.activateWindow,
      );

      core.setRailOpen(true);
      final year2024 = core.motion.catalog.logicalIndexForValue(2024);
      core.semanticCrossed(year2024);
      core.settleRail(year2024);
      await pumpEventQueue();
      core.navigatePlane(finer: true);

      expect(core.navigation.state.plane, TimePlane.year);
      for (final month in core.motion.catalog.entries) {
        final payload = core.preparedIndex!.frameForKey(month.queryKey).logBox;
        expect(cache.sceneFor(payload), isNotNull);
      }
    },
  );

  test(
    'a distant February settle supplies its complete month day catalog',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initial = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
        ),
        activate: cache.activateWindow,
      );

      core.setRailOpen(true);
      final february = core.motion.catalog.logicalIndexForValue(2);
      core.semanticCrossed(february);
      core.settleRail(february);
      await pumpEventQueue();
      core.navigatePlane(finer: true);

      expect(core.navigation.state.monthCursor.month, 2);
      for (final day in core.motion.catalog.entries) {
        final payload = core.preparedIndex!.frameForKey(day.queryKey).logBox;
        expect(cache.sceneFor(payload), isNotNull);
      }
      expect(cache.textLayoutMissCount, 0);
    },
  );

  test(
    'December-to-January parent rotation supplies January day scenes',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 12, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final december = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: december, surfaceWidth: 378);
      cache.activateWindow(december);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
        ),
        activate: cache.activateWindow,
      );

      await core.navigateParent(DashboardTimeNavigationChangeDirection.forward);

      expect(core.navigation.state.monthCursor.year, 2027);
      expect(core.navigation.state.monthCursor.month, 1);
      for (final day in core.motion.catalog.entries) {
        final payload = core.preparedIndex!.frameForKey(day.queryKey).logBox;
        expect(cache.sceneFor(payload), isNotNull);
      }
      expect(cache.textLayoutMissCount, 0);
    },
  );

  test(
    'direction changes retain the same coverage without a scene rebase',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 4, 12),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      core.recordInitialSceneWindowActivation(
        core.renderCriticalLogBoxSceneWindow(),
      );
      var prepareCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepareCount += 1;
        },
        activate: (_) {},
      );

      core.selectDirection(TransactionDirection.expense);
      await pumpEventQueue();

      expect(prepareCount, 0);
    },
  );

  test(
    'an index publication queues behind a structural scene rotation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final firstPrepare = Completer<void>();
      final indexActivated = Completer<void>();
      var prepareCount = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepareCount += 1;
          if (prepareCount == 1) await firstPrepare.future;
        },
        activate: (window) {
          if (window.identity.startsWith('rev:2|')) indexActivated.complete();
        },
      );

      final rotation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      await Future<void>.microtask(() {});
      expect(core.sceneWindowPreparing.value, isTrue);

      await core.installPreparedIndex(buildRuntimeTestIndex(revision: 2));
      expect(core.preparedIndex!.coreRevision, 1);

      firstPrepare.complete();
      await rotation;
      await indexActivated.future;

      expect(core.presentation.index!.coreRevision, 2);
      expect(prepareCount, 2);
      expect(core.sceneWindowPreparing.value, isFalse);
    },
  );
}
