import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_data_runtime.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_presentation_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import 'dashboard_runtime_test_fixtures.dart';

void main() {
  test('combined visual motion remains active until every lane is idle', () {
    final core = DashboardCoreController(initialDate: DateTime(2026, 7, 14));
    addTearDown(core.dispose);

    core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
    core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
    expect(core.diagnostics.isMotionActive, isTrue);

    core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
    expect(core.diagnostics.isMotionActive, isTrue);

    core.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
    expect(core.diagnostics.isMotionActive, isFalse);
  });

  test(
    'database revision stays pending until every visual lane reaches idle',
    () async {
      final repository = _CountingRuntimeRepository();
      final scheduler = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        dataRepository: repository,
        displayFrameScheduler: scheduler,
        stableFrameScheduler: scheduler,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 7,
        yearWindowRadius: 1,
      );
      addTearDown(() async {
        core.dispose();
        await repository.dispose();
      });
      await core.bootstrap();

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.setMotionLaneActive(DashboardMotionLane.amount, true);
      repository.emitRevision(8);
      await pumpEventQueue();

      expect(core.preparedIndex?.coreRevision, 7);
      expect(core.dataRuntime.pendingIndex?.coreRevision, 8);

      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      scheduler.fireFrame();
      expect(core.preparedIndex?.coreRevision, 7);

      core.setMotionLaneActive(DashboardMotionLane.amount, false);
      expect(core.preparedIndex?.coreRevision, 7);
      scheduler.fireFrame();
      expect(core.preparedIndex?.coreRevision, 8);
      expect(core.visibleFrames.value?.coreRevision, 8);
    },
  );

  test(
    'all dashboard navigation remains RAM-only after one bootstrap',
    () async {
      final repository = _CountingRuntimeRepository();
      final scheduler = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        dataRepository: repository,
        displayFrameScheduler: scheduler,
        stableFrameScheduler: scheduler,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 7,
        yearWindowRadius: 1,
      );
      addTearDown(() async {
        core.dispose();
        await repository.dispose();
      });
      await core.bootstrap();
      expect(repository.globalRevisionSubscribeCount, 1);
      expect(repository.indexBuildCount, 1);
      repository.resetInteractionCounters();

      core.setRailOpen(true);
      scheduler.fireFrame();
      for (var fling = 0; fling < 50; fling += 1) {
        final target = 1 + (fling % 27);
        core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
        core.semanticCrossed(target);
        scheduler.fireFrame();
        core.settleRail(target);
      }

      core.navigatePlane(finer: false);
      scheduler.fireFrame();
      for (var fling = 0; fling < 50; fling += 1) {
        final target = fling % 12;
        core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
        core.semanticCrossed(target);
        scheduler.fireFrame();
        core.settleRail(target);
      }

      for (var switchIndex = 0; switchIndex < 30; switchIndex += 1) {
        core.navigateParent(
          switchIndex.isEven
              ? DashboardTimeNavigationChangeDirection.forward
              : DashboardTimeNavigationChangeDirection.backward,
        );
        scheduler.fireFrame();
      }
      for (var switchIndex = 0; switchIndex < 20; switchIndex += 1) {
        core.navigatePlane(finer: switchIndex.isOdd);
        scheduler.fireFrame();
      }
      for (var switchIndex = 0; switchIndex < 20; switchIndex += 1) {
        core.selectDirection(
          switchIndex.isEven
              ? TransactionDirection.expense
              : TransactionDirection.income,
        );
        scheduler.fireFrame();
      }
      for (var cycle = 0; cycle < 20; cycle += 1) {
        core.setRailOpen(cycle.isEven);
        scheduler.fireFrame();
      }

      expect(repository.repositoryReadCount, 0);
      expect(repository.nativeSubscribeCount, 0);
      expect(repository.nativeCancelCount, 0);
      expect(repository.sqlCount, 0);
      expect(repository.indexBuildCount, 0);
      expect(repository.bridgePayloadCount, 0);
      expect(repository.pageReadCount, 0);
      expect(repository.globalRevisionSubscribeCount, 1);
      final visible = core.visibleFrames.value!;
      expect(visible.queryKey, core.presentation.expectedVisibleQueryKey);
      expect(visible.coreRevision, core.preparedIndex!.coreRevision);
      expect(visible.amount.queryKey, visible.count.queryKey);
      expect(visible.count.queryKey, visible.logBox.queryKey);
    },
  );

  test(
    'multiple crossings in one display frame publish only the last target',
    () {
      final scheduler = _DisplayFrameScheduler();
      final presentation = _presentation(scheduler);
      addTearDown(presentation.dispose);
      presentation.setRailOpen(true);
      scheduler.fireFrame();
      final before = presentation.visibleFrames.visiblePublishCount;

      presentation.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      presentation.semanticCrossed(14);
      presentation.semanticCrossed(15);
      presentation.semanticCrossed(16);
      scheduler.fireFrame();

      expect(presentation.visibleFrames.visiblePublishCount, before + 1);
      expect(
        presentation.visibleFrames.value?.queryKey.value,
        contains('day:2026-07-17'),
      );
      expect(
        presentation.frameCoalescer.coalescedTargetCount,
        greaterThanOrEqualTo(2),
      );
      expect(presentation.frameCoalescer.maximumPublishesInOneDisplayFrame, 1);
    },
  );
}

DashboardPresentationController _presentation(
  _DisplayFrameScheduler scheduler,
) {
  final presentation = DashboardPresentationController(
    initialDate: DateTime(2026, 7, 14),
    displayFrameScheduler: scheduler,
  );
  presentation.installIndex(
    buildRuntimeTestIndex(revision: 7),
    publishImmediately: true,
  );
  return presentation;
}

final class _DisplayFrameScheduler
    implements DashboardDisplayFrameScheduler, DashboardStableFrameScheduler {
  final List<void Function()> _callbacks = <void Function()>[];

  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(void Function() callback) => _callbacks.add(callback);

  @override
  void scheduleStableFrame(void Function() callback) =>
      _callbacks.add(callback);

  void fireFrame() {
    currentFrameNumber += 1;
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

final class _CountingRuntimeRepository
    implements DashboardDataRuntimeRepository {
  _CountingRuntimeRepository() {
    _revisions = StreamController<int>.broadcast(
      onListen: () => globalRevisionSubscribeCount += 1,
    );
  }

  late final StreamController<int> _revisions;
  int globalRevisionSubscribeCount = 0;
  int repositoryReadCount = 0;
  int nativeSubscribeCount = 0;
  int nativeCancelCount = 0;
  int sqlCount = 0;
  int indexBuildCount = 0;
  int bridgePayloadCount = 0;
  int pageReadCount = 0;

  void resetInteractionCounters() {
    repositoryReadCount = 0;
    nativeSubscribeCount = 0;
    nativeCancelCount = 0;
    sqlCount = 0;
    indexBuildCount = 0;
    bridgePayloadCount = 0;
    pageReadCount = 0;
  }

  @override
  Stream<int> watchCoreRevision() => _revisions.stream;

  void emitRevision(int revision) => _revisions.add(revision);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    request.reason.requireIndexBuild();
    repositoryReadCount += 1;
    sqlCount += 5;
    indexBuildCount += 1;
    bridgePayloadCount += 1;
    return buildRuntimeTestIndex(
      revision: request.key.coreRevision,
      generation: token.generation,
    );
  }

  @override
  Future<DashboardPreparedFrame> readCommittedPage(
    DashboardCommittedPageRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) async {
    request.reason.requirePageRead();
    pageReadCount += 1;
    repositoryReadCount += 1;
    bridgePayloadCount += 1;
    return currentFrame;
  }

  @override
  Map<String, Object?> performanceReport() => <String, Object?>{
    'repositoryReadCount': repositoryReadCount,
    'nativeSubscribeCount': nativeSubscribeCount,
    'nativeCancelCount': nativeCancelCount,
    'sqlCount': sqlCount,
    'indexBuildCount': indexBuildCount,
    'bridgePayloadCount': bridgePayloadCount,
    'pageReadCount': pageReadCount,
  };

  Future<void> dispose() => _revisions.close();
}
