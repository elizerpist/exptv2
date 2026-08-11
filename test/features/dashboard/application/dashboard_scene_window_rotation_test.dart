import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_prepared_revision_bundle.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rail-critical window covers every prepared query exactly once',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final window = core.railCriticalSceneWindowForIndex(index);

      expect(window.sceneCount, index.frames.length);
      expect(
        window.payloads.map((payload) => payload.queryKey.value).toSet(),
        hasLength(index.frames.length),
      );
    },
  );

  test(
    'query publication window contains the visible parent and its immediate rail domain only',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final publicationBundle = DashboardPreparedRevisionBundle.forIndex(
        core.preparedIndex!,
        publicationState: core.navigation.state,
      );

      expect(
        publicationBundle.railCriticalSceneWindow.sceneCount,
        lessThan(core.preparedIndex!.frames.length),
      );
      expect(
        publicationBundle.railCriticalSceneWindow.payloads.map(
          (payload) => payload.queryKey,
        ),
        contains(core.navigation.state.parentQueryKey),
      );
    },
  );

  test(
    'demanded navigation window stays canonical when a full bank is active',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final fullWindow = core.railCriticalSceneWindowForIndex(index);
      core.recordInitialSceneWindowActivation(fullWindow);

      final demanded = core.renderCriticalLogBoxSceneWindowFor(
        core.navigation.state,
      );

      expect(demanded.sceneCount, lessThan(index.frames.length));
      expect(
        demanded.payloads.map((payload) => payload.queryKey.value).toSet(),
        hasLength(demanded.sceneCount),
      );
    },
  );

  test(
    'input cancels speculative preparation without rejecting navigation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final preparation = Completer<void>();
      var cancellations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => preparation.future,
        activate: (_) {},
        cancel: () {
          cancellations += 1;
          if (!preparation.isCompleted) preparation.complete();
        },
      );

      final parentMove = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      await pumpEventQueue();
      expect(core.sceneWindowPreparing.value, isTrue);

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.navigatePlane(finer: false);
      core.setRailOpen(true);

      await parentMove;
      expect(cancellations, greaterThanOrEqualTo(1));
      expect(core.navigation.state.plane, TimePlane.year);
      expect(core.navigation.state.isRailOpen, isTrue);
    },
  );

  test(
    'a revision publishes its index and complete rail bank together',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initialWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      final allowNextBank = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          await allowNextBank.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final publication = core.installPreparedIndex(
        buildRuntimeTestIndex(revision: 2, generation: 2),
      );
      await Future<void>.microtask(() {});
      expect(core.activePreparedRevisionBundle!.coreRevision, 1);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:1|'));

      allowNextBank.complete();
      await publication;
      expect(core.activePreparedRevisionBundle!.coreRevision, 2);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:2|'));
      expect(cache.activeWindowManifest!.isComplete, isTrue);
    },
  );

  test('a complete active rail bank eliminates sibling rebase work', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    addTearDown(core.dispose);
    addTearDown(cache.dispose);
    await core.bootstrap();
    final window = core.railCriticalSceneWindow();
    await cache.prepareWindow(window: window, surfaceWidth: 378);
    cache.activateWindow(window);
    core.recordInitialSceneWindowActivation(window);
    var prepares = 0;
    core.attachLogBoxSceneWindowCoordinator(
      prepare: (_, {required retainViewportId}) async => prepares += 1,
      activate: (_) {},
      report: cache.report,
    );

    core.setRailOpen(true);
    final sibling = core.motion.catalog.logicalIndexForValue(6);
    core.semanticCrossed(sibling);
    core.settleRail(sibling);
    await pumpEventQueue();

    expect(prepares, 0);
    expect(cache.railCriticalLookupMissCount, 0);
  });

  test(
    'minimal publication bank keeps the direction twin paint-ready synchronously',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      expect(
        core.activePreparedRevisionBundle!.railCriticalSceneWindow.sceneCount,
        lessThan(core.preparedIndex!.frames.length),
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );

      expect(
        core.activePreparedRevisionBundle!.railCriticalSceneWindow.payloads.map(
          (payload) => payload.queryKey.value,
        ),
        contains('expense|month:2026-07|categories:|partners:|refinements:'),
        reason:
            'The interaction-critical publication bank must contain the exact '
            'opposite-direction parent before the user can tap it.',
      );
      expect(
        core.activePreparedRevisionBundle!.railCriticalSceneWindow.payloads.map(
          (payload) => payload.queryKey.value,
        ),
        contains('expense|day:2026-07-14|categories:|partners:|refinements:'),
        reason:
            'The opposite-direction immediate rail domain must be prepared '
            'once as well, so a direction switch remains paint-ready during '
            'rail movement.',
      );

      final preparesBeforeDirectionChange = prepares;
      core.selectDirection(TransactionDirection.expense);
      expect(core.navigation.state.parentQueryScope.direction.name, 'expense');
      displayFrames.flush();

      expect(
        prepares,
        preparesBeforeDirectionChange,
        reason:
            'Direction twins share one canonical critical bank; changing only '
            'direction must not schedule asynchronous scene preparation.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
        reason:
            'The visible expense payload must be drawable before any event-loop '
            'or rebase work is allowed to run.',
      );
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'minimal publication bank rebases exact scenes across plane transitions',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );

      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );

      core.navigatePlane(finer: true);
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.month);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      expect(prepares, 3);
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'input cancellation retains an in-flight required scene demand until idle',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var blockNextPreparation = false;
      var prepares = 0;
      var cancellations = 0;
      Completer<void>? blockedPreparation;
      final blockedPreparationStarted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          if (blockNextPreparation &&
              window.sceneCount < core.preparedIndex!.frames.length) {
            blockedPreparation = Completer<void>();
            if (!blockedPreparationStarted.isCompleted) {
              blockedPreparationStarted.complete();
            }
            await blockedPreparation!.future;
            return;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          cancellations += 1;
          final pending = blockedPreparation;
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeDemand = prepares;

      blockNextPreparation = true;
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();
      expect(prepares, preparesBeforeDemand);

      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await blockedPreparationStarted.future;
      expect(prepares, preparesBeforeDemand + 1);

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      await pumpEventQueue();
      expect(cancellations, greaterThanOrEqualTo(1));

      blockNextPreparation = false;
      core.settleRail(0);
      displayFrames.flush();
      await pumpEventQueue();

      expect(
        prepares,
        preparesBeforeDemand + 2,
        reason:
            'Cancelling work for input must not erase the still-required '
            'coverage demand; the next idle boundary retries it automatically.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
    },
  );

  test(
    'a newer deferred coverage target supersedes a cancelled in-flight target',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var blockNextPreparation = false;
      var prepares = 0;
      Completer<void>? blockedPreparation;
      final blockedPreparationStarted = Completer<void>();
      final preparedWindows = <Set<String>>[];
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          preparedWindows.add(
            window.payloads.map((payload) => payload.queryKey.value).toSet(),
          );
          if (blockNextPreparation &&
              window.sceneCount < core.preparedIndex!.frames.length) {
            blockedPreparation = Completer<void>();
            if (!blockedPreparationStarted.isCompleted) {
              blockedPreparationStarted.complete();
            }
            await blockedPreparation!.future;
            return;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          final pending = blockedPreparation;
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeDemand = prepares;

      blockNextPreparation = true;
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.navigatePlane(finer: false); // B = 2026 year plane.
      displayFrames.flush();
      await pumpEventQueue();
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await blockedPreparationStarted.future;

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      await pumpEventQueue();
      unawaited(
        core.navigateParent(DashboardTimeNavigationChangeDirection.backward),
      );
      displayFrames.flush();
      await pumpEventQueue();

      blockNextPreparation = false;
      core.settleRail(0);
      await pumpEventQueue();

      expect(
        prepares,
        preparesBeforeDemand + 2,
        reason: 'Only B once and its newer C replacement may be prepared.',
      );
      expect(
        preparedWindows.last,
        contains('income|year:2025|categories:|partners:|refinements:'),
        reason: 'The retry must prepare the newer C target, never restart B.',
      );
    },
  );

  test(
    'motion retains the latest direction and plane scene demand until idle',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeMotion = prepares;

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.selectDirection(TransactionDirection.expense);
      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.navigation.state.parentQueryScope.direction.name, 'expense');
      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        prepares,
        preparesBeforeMotion,
        reason: 'motion defers expensive scene preparation',
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await pumpEventQueue();

      expect(
        prepares,
        preparesBeforeMotion + 1,
        reason: 'idle must drain only the latest demanded coverage',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
    },
  );
}

final class _DisplayFrameScheduler implements DashboardDisplayFrameScheduler {
  final List<VoidCallback> _callbacks = <VoidCallback>[];
  int _frame = 0;

  @override
  int get currentFrameNumber => _frame;

  @override
  void scheduleFrame(VoidCallback callback) => _callbacks.add(callback);

  void flush() {
    _frame += 1;
    final callbacks = List<VoidCallback>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}
