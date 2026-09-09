import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_avatar_resource_window.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../../../support/avatar_target_liveness_fixture.dart';

void main() {
  test(
    'current nonempty target prepares exact resources with no broad hotset',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      final initialFrame = fixture.core.visibleFrames.logBoxLane.value!;
      final repositoryReads = fixture.repository.indexRequests;
      fixture.core.beginBudgetAvatarMotion();

      final result = fixture.preview(8);
      await _eventually(() => fixture.avatarPreparations.length == 1);
      final preparation = fixture.avatarPreparations.single;
      expect(fixture.core.budgetAvatarFocusHotsetDiagnostics['cached'], 0);
      expect(fixture.core.budgetAvatarFocusHotsetDiagnostics['pending'], 0);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        1,
      );
      expect(preparation.window.sceneCount, 1);
      expect(preparation.window.previewRowCount, 1);
      expect(
        preparation.window.payloads.single.queryKey.value,
        contains('categories:avatar-category-8'),
      );
      expect(fixture.core.visibleFrames.logBoxLane.value, same(initialFrame));
      expect(
        fixture.cache.hasCompleteReadablePhaseAFor(initialFrame.logBox),
        isTrue,
      );

      preparation.release();
      expect(await result.timeout(_deadline), isTrue);
      fixture.expectExactTarget(8);
      expect(fixture.repository.indexRequests, repositoryReads);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        0,
      );
      expect(fixture.terminals[8], isEmpty);
      expect(
        _events('AV|LIVE_ROOT_RESOURCES_READY').single.scope,
        contains('resourceMode=exactCurrentTarget'),
      );
    },
  );

  test(
    'target 8 coalesces held target 1 and replays its original order once',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      fixture.core.beginBudgetAvatarMotion();
      final older = fixture.preview(1);
      await _eventually(() => fixture.avatarPreparations.length == 1);
      final original = fixture.avatarPreparations.single;
      final latest = fixture.preview(8);
      await _eventually(() => fixture.avatarPreparations.length == 2);
      final newest = fixture.avatarPreparations.last;
      final pending = _events('AVATAR_CANDIDATE_PENDING_RESOURCE').last;
      final requestedOrder = _order(pending.scope!);

      expect(await older.timeout(_deadline), isFalse);
      expect(fixture.terminals[1], [
        AvatarPreviewTerminal.coalescedBeforeResourceReady,
      ]);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        1,
      );
      expect(fixture.core.focus.state, isNull);
      var latestCompleted = false;
      latest.then((_) => latestCompleted = true);
      newest.release();
      await pumpEventQueue(times: 100);
      expect(
        latestCompleted,
        isTrue,
        reason:
            'The latest exact target must receive foreground priority without waiting for the superseded target preparation to finish.',
      );
      expect(await latest.timeout(_deadline), isTrue);
      fixture.expectExactTarget(8);
      original.release();
      await original.completed.future.timeout(_deadline);
      await pumpEventQueue();
      fixture.expectExactTarget(8);
      expect(
        _order(_events('AVATAR_PENDING_CANDIDATE_PROMOTED').single.scope!),
        requestedOrder,
      );
      final visibleOrder = fixture.core.visibleFrames.interactionPreviewOrder!;
      expect([
        visibleOrder.interactionEpoch,
        visibleOrder.localGeneration,
      ], requestedOrder);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        0,
      );
      expect(fixture.terminals[1], hasLength(1));
      expect(fixture.terminals[8], isEmpty);
      expect(fixture.avatarPreparations, hasLength(2));
    },
  );

  test(
    'returning to current target 1 coalesces held target 8 in the same pointer',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      fixture.core.beginBudgetAvatarMotion();
      final first = fixture.preview(1);
      await _eventually(() => fixture.avatarPreparations.length == 1);
      fixture.avatarPreparations.single.release();
      expect(await first.timeout(_deadline), isTrue);
      fixture.expectExactTarget(1);

      final older = fixture.preview(8);
      await _eventually(() => fixture.avatarPreparations.length == 2);
      final held = fixture.avatarPreparations.last;
      await held.reachedCheckpoint.future.timeout(_deadline);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        1,
      );
      var olderCompleted = false;
      older.then((_) => olderCompleted = true);

      // The current exact frame may be reused or prepared again. Either path
      // must retire the older candidate while its real cache work is held.
      var latestCompleted = false;
      final latest = fixture.preview(1);
      latest.then((_) => latestCompleted = true);
      await _eventually(
        () => latestCompleted || fixture.avatarPreparations.length == 3,
      );
      fixture.expectExactTarget(1);
      await pumpEventQueue();
      expect(
        olderCompleted,
        isTrue,
        reason:
            'Returning to the exact current target must coalesce target 8 before its held preparation completes.',
      );
      expect(await older.timeout(_deadline), isFalse);
      expect(fixture.terminals[8], [
        AvatarPreviewTerminal.coalescedBeforeResourceReady,
      ]);
      if (!latestCompleted) {
        fixture.avatarPreparations.last.release();
      }
      expect(await latest.timeout(_deadline), isTrue);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        0,
      );
      fixture.expectExactTarget(1);

      held.release();
      await held.completed.future.timeout(_deadline);
      await pumpEventQueue();
      fixture.expectExactTarget(1);
      expect(fixture.terminals[8], hasLength(1));
      fixture.core.endBudgetAvatarMotion();
      await _eventually(
        () => fixture.core.navigation.state.parentQueryScope.categoryIds
            .contains('avatar-category-1'),
      );
      expect(fixture.core.navigation.state.parentQueryScope.categoryIds, {
        'avatar-category-1',
      });
    },
  );

  test(
    'new pointer terminally cancels pending work before stale cache completion',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      final initialFrame = fixture.core.visibleFrames.logBoxLane.value;
      fixture.core.beginBudgetAvatarMotion();
      final result = fixture.preview(7);
      await _eventually(() => fixture.avatarPreparations.length == 1);

      fixture.core.noteBudgetAvatarDirectPointerDown();
      final pointerOrder = fixture.core.visibleFrames.interactionPreviewOrder!;
      expect(await result.timeout(_deadline), isFalse);
      expect(fixture.terminals[7], [
        AvatarPreviewTerminal.cancelledByNewPointer,
      ]);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        0,
      );
      fixture.avatarPreparations.single.release();
      await fixture.avatarPreparations.single.completed.future.timeout(
        _deadline,
      );
      await pumpEventQueue();

      expect(fixture.core.visibleFrames.logBoxLane.value, same(initialFrame));
      expect(fixture.core.focus.state, isNull);
      expect(
        fixture.core.visibleFrames.interactionPreviewOrder!.hasSameIdentity(
          pointerOrder,
        ),
        isTrue,
      );
      expect(fixture.terminals[7], hasLength(1));
      expect(_events('AVATAR_PENDING_CANDIDATE_PROMOTED'), isEmpty);
    },
  );

  test(
    'disposal resolves the pending request exactly once and drops its owner',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      fixture.core.beginBudgetAvatarMotion();
      final result = fixture.preview(8);
      await _eventually(() => fixture.avatarPreparations.length == 1);

      fixture.disposeCore();
      expect(await result.timeout(_deadline), isFalse);
      expect(fixture.terminals[8], [AvatarPreviewTerminal.disposed]);
      expect(
        fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
        0,
      );
      expect(fixture.core.budgetAvatarFocusHotsetDiagnostics['disposed'], 1);
      fixture.avatarPreparations.single.release();
      await fixture.avatarPreparations.single.completed.future.timeout(
        _deadline,
      );
      await pumpEventQueue();
      expect(fixture.terminals[8], hasLength(1));
      expect(_events('AVATAR_PENDING_CANDIDATE_PROMOTED'), isEmpty);
    },
  );

  for (final disposedBeforeRequest in [false, true]) {
    test(
      'Avatar category and aggregate requests ${disposedBeforeRequest ? 'after disposal terminate as disposed' : 'behind Time foreground terminate as staleRejected'}',
      () async {
        final fixture = await _LifecycleFixture.create();
        addTearDown(fixture.dispose);
        if (disposedBeforeRequest) {
          fixture.disposeCore();
        } else {
          fixture.core.beginSegmentedSummaryMotion();
        }
        final aggregateTerminals = <AvatarPreviewTerminal>[];

        final categoryResult = await fixture.preview(8).timeout(_deadline);
        final aggregateResult = await fixture.core
            .clearBudgetCategoryFocus(
              targetHandle: 0,
              publishDuringMotion: true,
              onPreviewTerminated: aggregateTerminals.add,
            )
            .timeout(_deadline);
        await pumpEventQueue();

        expect([categoryResult, aggregateResult], [false, false]);
        final terminal = disposedBeforeRequest
            ? AvatarPreviewTerminal.disposed
            : AvatarPreviewTerminal.staleRejected;
        expect(
          {8: fixture.terminals[8], 0: aggregateTerminals},
          {
            8: [terminal],
            0: [terminal],
          },
        );
        expect(
          fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
          0,
        );
        expect(fixture.avatarPreparations, isEmpty);
      },
    );
  }

  for (final cancelled in [false, true]) {
    test(
      'exact preparation ${cancelled ? 'cancellation' : 'failure'} terminates explicitly',
      () async {
        final fixture = await _LifecycleFixture.create();
        addTearDown(fixture.dispose);
        final initialFrame = fixture.core.visibleFrames.logBoxLane.value;
        fixture.core.beginBudgetAvatarMotion();
        final result = fixture.preview(8);
        await _eventually(() => fixture.avatarPreparations.length == 1);
        final preparation = fixture.avatarPreparations.single;
        await preparation.reachedCheckpoint.future.timeout(_deadline);
        if (cancelled) {
          fixture.cache.cancelLiveInteractionResourcePreparation(
            lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
          );
          preparation.release();
        } else {
          preparation.fail(
            StateError('controlled exact resource layout failure'),
          );
        }

        expect(await result.timeout(_deadline), isFalse);
        expect(fixture.terminals[8], [
          AvatarPreviewTerminal.explicitInvariantFailure,
        ]);
        expect(
          fixture.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
          0,
        );
        expect(fixture.core.visibleFrames.logBoxLane.value, same(initialFrame));
        expect(fixture.core.focus.state, isNull);
        expect(
          fixture.cache.hasCompleteReadablePhaseAFor(initialFrame!.logBox),
          isTrue,
        );
        await pumpEventQueue();
        expect(fixture.terminals[8], hasLength(1));
      },
    );
  }

  test(
    'new accepted target replaces the older deferred canonical installation',
    () async {
      final fixture = await _LifecycleFixture.create();
      addTearDown(fixture.dispose);
      fixture.core.beginBudgetAvatarMotion();
      final older = fixture.preview(1);
      await _eventually(() => fixture.avatarPreparations.length == 1);
      fixture.avatarPreparations.single.release();
      expect(await older.timeout(_deadline), isTrue);
      fixture.expectExactTarget(1);
      expect(
        fixture.core.navigation.state.parentQueryScope.categoryIds,
        isEmpty,
        reason: 'Motion holds the accepted target 1 canonical installation.',
      );

      final latest = fixture.preview(8);
      await _eventually(() => fixture.avatarPreparations.length == 2);
      fixture.avatarPreparations.last.release();
      expect(await latest.timeout(_deadline), isTrue);
      fixture.expectExactTarget(8);
      expect(
        fixture.core.navigation.state.parentQueryScope.categoryIds,
        isEmpty,
      );

      fixture.core.endBudgetAvatarMotion();
      await _eventually(
        () => fixture.core.navigation.state.parentQueryScope.categoryIds
            .contains('avatar-category-8'),
      );
      await pumpEventQueue();
      expect(fixture.core.focus.state?.category?.id, 'avatar-category-8');
      expect(fixture.core.visibleFrames.logBoxLane.value!.scope.categoryIds, {
        'avatar-category-8',
      });
      expect(fixture.core.navigation.state.parentQueryScope.categoryIds, {
        'avatar-category-8',
      });
      final installs = _events('AV|CANONICAL_PUBLICATION_RECONCILED');
      expect(installs, hasLength(1));
      expect(installs.single.scope, contains('targetHandle=8'));
      expect(
        _events('FOCUS_PUBLICATION_COMPLETED').single.queryKey,
        contains('categories:avatar-category-8'),
      );
    },
  );
}

const _deadline = Duration(seconds: 5);

Iterable<FluviDiagnosticEvent> _events(String stage) =>
    FluviDiagnosticLogger.entries.where((event) => event.stage == stage);

List<int> _order(String scope) => [
  for (final field in ['interactionEpoch', 'localGeneration'])
    int.parse(RegExp('$field=(\\d+)').firstMatch(scope)!.group(1)!),
];

Future<void> _eventually(bool Function() condition) async {
  final timer = Stopwatch()..start();
  while (!condition()) {
    if (timer.elapsed > _deadline) {
      fail(
        'Timed out waiting for lifecycle boundary.\n${FluviDiagnosticLogger.entries.map((event) => '${event.stage} ${event.scope}').join('\n')}',
      );
    }
    await Future<void>.delayed(Duration.zero);
  }
}

class _HeldPreparation {
  _HeldPreparation(this.window);

  final DashboardLogBoxSceneWindow window;
  final reachedCheckpoint = Completer<void>();
  final completed = Completer<void>();
  final _release = Completer<void>();

  Future<void> checkpoint() {
    if (!reachedCheckpoint.isCompleted) reachedCheckpoint.complete();
    return _release.future;
  }

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  void fail(Object error) => _release.completeError(error);
}

class _LifecycleFixture {
  _LifecycleFixture(this.repository, this.core, this.cache);

  final AvatarTargetLivenessRepository repository;
  final DashboardCoreController core;
  final DashboardLogBoxPreparedSceneCache cache;
  final avatarPreparations = <_HeldPreparation>[];
  final terminals = <int, List<AvatarPreviewTerminal>>{};
  bool _coreDisposed = false;

  static Future<_LifecycleFixture> create() async {
    final repository = AvatarTargetLivenessRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
      initialDate: DateTime.utc(2026, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
      initialPlane: TimePlane.month,
      initialRailOpen: false,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    final fixture = _LifecycleFixture(repository, core, cache);
    await core.bootstrap();
    final baseWindow = DashboardLogBoxSceneWindow(
      identity: 'avatar-lifecycle-readable-base',
      payloads: [core.visibleFrames.logBoxLane.value!.logBox],
    );
    await cache.prepareWindow(window: baseWindow, surfaceWidth: 378);
    cache.activateWindow(baseWindow);
    core.attachLogBoxSceneWindowCoordinator(
      prepare: (window, {required retainViewportId}) => cache.prepareWindow(
        window: window,
        surfaceWidth: 378,
        retainViewportId: retainViewportId,
      ),
      activate: cache.activateWindow,
      cancel: cache.cancelInFlightPreparation,
      report: cache.report,
      prepareLiveInteractionResources:
          (
            window, {
            required lane,
            required retainedKey,
            required retainViewportId,
          }) async {
            final preparation =
                lane == DashboardLiveInteractionResourceLane.budgetAvatarPreview
                ? _HeldPreparation(window)
                : null;
            if (preparation != null) {
              fixture.avatarPreparations.add(preparation);
            }
            try {
              await cache.prepareLiveInteractionResourceWindow(
                lane: lane,
                resourceKey: retainedKey,
                window: window,
                surfaceWidth: 378,
                retainViewportId: retainViewportId,
                yieldToBackground: preparation?.checkpoint,
              );
            } finally {
              preparation?.completed.complete();
            }
          },
      hasLiveInteractionResources:
          (window, {required lane, required candidateKey}) =>
              cache.hasLiveInteractionResourceWindow(
                window,
                lane: lane,
                resourceKey: candidateKey,
              ),
      cancelLiveInteractionResourcePreparation: ({required lane}) =>
          cache.cancelLiveInteractionResourcePreparation(lane: lane),
      bindLiveInteractionReadablePhaseA:
          (payload, {required lane, required resourceKey}) =>
              cache.bindLiveInteractionReadablePhaseA(
                payload,
                lane: lane,
                resourceKey: resourceKey,
              ),
    );
    await pumpEventQueue();
    FluviDiagnosticLogger.clear();
    return fixture;
  }

  Future<bool> preview(int handle) => core.requestBudgetCategoryFocus(
    DashboardFocusFacet(
      id: 'avatar-category-$handle',
      displayName: 'Category $handle',
    ),
    publishDuringMotion: true,
    targetHandle: handle,
    onPreviewTerminated: (terminals[handle] = []).add,
  );

  void expectExactTarget(int handle) {
    final frame = core.visibleFrames.logBoxLane.value!;
    expect(core.focus.state?.category?.id, 'avatar-category-$handle');
    expect(frame.scope.categoryIds, {'avatar-category-$handle'});
    expect(frame.logBox.previewRowCount, 1);
    expect(cache.hasCompleteReadablePhaseAFor(frame.logBox), isTrue);
    expect(cache.readablePhaseARowCountFor(frame.logBox), 1);
  }

  void disposeCore() {
    if (_coreDisposed) return;
    _coreDisposed = true;
    core.dispose();
  }

  Future<void> dispose() async {
    disposeCore();
    for (final preparation in avatarPreparations) {
      preparation.release();
    }
    await Future.wait(
      avatarPreparations.map((preparation) => preparation.completed.future),
    ).timeout(_deadline);
    await pumpEventQueue();
    cache.dispose();
  }
}
