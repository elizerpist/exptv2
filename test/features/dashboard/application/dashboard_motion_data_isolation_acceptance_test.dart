import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_diagnostics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

void main() {
  test('100 semantic crossings perform zero data or projection work', () async {
    final harness = await _Harness.start(density: 658);
    addTearDown(harness.dispose);
    harness.core.setRailOpen(true);
    harness.scheduler.fireFrame();
    final preparations = harness.repository.prepareCount;
    final leases = harness.repository.liveLeaseCount;
    final publishes = harness.core.frameCoalescer.publishCount;

    harness.core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
    for (var index = 0; index < 100; index += 1) {
      harness.core.semanticCrossed(index);
    }
    harness.scheduler.fireFrame();

    expect(harness.repository.prepareCount, preparations);
    expect(harness.repository.liveLeaseCount, leases);
    for (final metric in <DashboardPerformanceMetric>[
      DashboardPerformanceMetric.sqlCallsDuringMotion,
      DashboardPerformanceMetric.platformCallsDuringMotion,
      DashboardPerformanceMetric.repositoryReadsDuringMotion,
      DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
      DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
      DashboardPerformanceMetric.formattingDuringMotion,
    ]) {
      expect(
        harness.counters.value(metric),
        0,
        reason: '${metric.name} must remain outside the semantic hot path',
      );
    }
    expect(harness.core.frameCoalescer.publishCount, publishes + 1);
    expect(harness.core.frameCoalescer.maximumPublishesInOneDisplayFrame, 1);
  });

  test(
    'physical target and duration are invariant across data densities',
    () async {
      final traces = <_FlingTrace>[];
      for (final density in <int>[0, 1, 94, 658]) {
        final harness = await _Harness.start(density: density);
        traces.add(_trace(harness.core));
        harness.dispose();
      }

      expect(traces.map((trace) => trace.targetIndex).toSet(), hasLength(1));
      expect(traces.map((trace) => trace.durationTicks).toSet(), hasLength(1));
      expect(
        traces.first.targetIndex - _physicalStartIndex,
        greaterThan(1),
        reason: 'a long fling may not collapse to a one-item move',
      );
    },
  );

  test('first, tenth and 100 repeated flings are deterministic', () async {
    final harness = await _Harness.start(density: 94);
    addTearDown(harness.dispose);

    final traces = List<_FlingTrace>.generate(100, (_) => _trace(harness.core));

    expect(traces[9], traces.first);
    expect(traces.toSet(), hasLength(1));
  });

  test(
    '100 structural changes retain controller and physics identity',
    () async {
      final harness = await _Harness.start(density: 94);
      addTearDown(harness.dispose);
      final motion = harness.core.motion;
      final carousel = motion.carouselController;
      final scrollController = carousel.scrollController;
      final physics = motion.dashboardPhysics;

      for (var index = 0; index < 100; index += 1) {
        switch (index % 4) {
          case 0:
            harness.core.setRailOpen(!harness.core.navigation.state.isRailOpen);
          case 1:
            await harness.core.navigatePlane(finer: index.isEven);
          case 2:
            await harness.core.selectDirection(
              index.isEven
                  ? TransactionDirection.income
                  : TransactionDirection.expense,
            );
          case 3:
            if (harness.core.navigation.state.plane != TimePlane.sum) {
              await harness.core.navigateParent(
                index.isEven
                    ? DashboardTimeNavigationChangeDirection.forward
                    : DashboardTimeNavigationChangeDirection.backward,
              );
            }
        }
        harness.scheduler.fireFrame();
      }

      expect(identical(harness.core.motion, motion), isTrue);
      expect(identical(motion.carouselController, carousel), isTrue);
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(motion.dashboardPhysics, physics), isTrue);
      expect(carousel.physicsCreationCount, 1);
    },
  );

  test(
    'seeded random navigation preserves every visible-frame invariant',
    () async {
      final harness = await _Harness.start(density: 94);
      addTearDown(harness.dispose);
      final random = math.Random(0xF1_0A_1);
      var revision = 1;

      for (var step = 0; step < 250; step += 1) {
        switch (random.nextInt(7)) {
          case 0:
            harness.core.setRailOpen(!harness.core.navigation.state.isRailOpen);
          case 1:
            await harness.core.navigatePlane(finer: random.nextBool());
          case 2:
            if (harness.core.navigation.state.plane != TimePlane.sum) {
              await harness.core.navigateParent(
                random.nextBool()
                    ? DashboardTimeNavigationChangeDirection.forward
                    : DashboardTimeNavigationChangeDirection.backward,
              );
            }
          case 3:
            await harness.core.selectDirection(
              random.nextBool()
                  ? TransactionDirection.income
                  : TransactionDirection.expense,
            );
          case 4:
            if (harness.core.navigation.state.isRailOpen) {
              final length = harness.core.motion.catalog.length;
              harness.core.semanticCrossed(random.nextInt(length));
            }
          case 5:
            if (harness.core.navigation.state.isRailOpen) {
              final visible = harness.core.visibleFrames.value;
              if (visible != null && visible.railOpen) {
                harness.core.settleRail(visible.semanticChildIndex);
              }
            }
          case 6:
            revision += 1;
            await harness.core.acceptCoreRevision(revision);
        }
        harness.scheduler.fireFrame();
        await pumpEventQueue();
        _expectAtomicVisibleFrame(harness.core);
      }

      expect(
        harness.counters.value(
          DashboardPerformanceMetric.repositoryReadsDuringMotion,
        ),
        0,
      );
      expect(
        harness.counters.value(
          DashboardPerformanceMetric.platformCallsDuringMotion,
        ),
        0,
      );
    },
  );
}

const int _physicalStartIndex = CenteredCarouselController.virtualAnchorIndex;

_FlingTrace _trace(DashboardCoreController core) {
  final physics = core.motion.dashboardPhysics;
  final itemExtent = physics.itemExtent;
  final position = FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: (physics.itemCount - 1) * itemExtent,
    pixels: _physicalStartIndex * itemExtent,
    viewportDimension: itemExtent * 7,
    axisDirection: AxisDirection.right,
    devicePixelRatio: 1,
  );
  final simulation = physics.createBallisticSimulation(position, 2200)!;
  var ticks = 0;
  var time = 0.0;
  while (ticks < 2000 && !simulation.isDone(time)) {
    ticks += 1;
    time += 1 / 120;
  }
  return _FlingTrace(
    targetIndex: (simulation.x(time) / itemExtent).round(),
    durationTicks: ticks,
  );
}

void _expectAtomicVisibleFrame(DashboardCoreController core) {
  final visible = core.visibleFrames.value!;
  expect(visible.amount.queryKey, visible.queryKey);
  expect(visible.count.queryKey, visible.queryKey);
  expect(visible.logBox.queryKey, visible.queryKey);
  expect(visible.amount.coreRevision, visible.coreRevision);
  expect(visible.count.coreRevision, visible.coreRevision);
  expect(visible.logBox.revision, visible.coreRevision);
  expect(visible.coreRevision, core.coreRevision);
  final deck = core.activeDeck!;
  expect(visible.parentQueryKey, deck.parentScope.key);
  final expected = visible.railOpen
      ? deck.semanticCatalog
            .entryAtLogicalIndex(visible.semanticChildIndex)
            .queryKey
      : deck.parentScope.key;
  expect(visible.queryKey, expected);
}

final class _FlingTrace {
  const _FlingTrace({required this.targetIndex, required this.durationTicks});

  final int targetIndex;
  final int durationTicks;

  @override
  bool operator ==(Object other) =>
      other is _FlingTrace &&
      other.targetIndex == targetIndex &&
      other.durationTicks == durationTicks;

  @override
  int get hashCode => Object.hash(targetIndex, durationTicks);
}

final class _Harness {
  _Harness._({
    required this.core,
    required this.repository,
    required this.scheduler,
    required this.counters,
  });

  final DashboardCoreController core;
  final _InstrumentedPreparedRepository repository;
  final _FrameScheduler scheduler;
  final DashboardPerformanceCounters counters;

  static Future<_Harness> start({required int density}) async {
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(counters: counters);
    final repository = _InstrumentedPreparedRepository(
      density: density,
      diagnostics: diagnostics,
    );
    final scheduler = _FrameScheduler();
    final core = DashboardCoreController(
      preparedRepository: repository,
      liveRepository: repository,
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 1,
      displayFrameScheduler: scheduler,
      interactionDiagnostics: diagnostics,
      enableBackgroundPrewarm: false,
    );
    await core.bootstrap();
    return _Harness._(
      core: core,
      repository: repository,
      scheduler: scheduler,
      counters: counters,
    );
  }

  void dispose() => core.dispose();
}

final class _FrameScheduler implements DashboardDisplayFrameScheduler {
  final List<VoidCallback> _callbacks = <VoidCallback>[];

  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(VoidCallback callback) => _callbacks.add(callback);

  void fireFrame() {
    if (_callbacks.isEmpty) return;
    currentFrameNumber += 1;
    final callbacks = List<VoidCallback>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

final class _InstrumentedPreparedRepository
    implements
        DashboardPreparedDeckRepository,
        DashboardPreparedLiveRepository {
  _InstrumentedPreparedRepository({
    required this.density,
    required this.diagnostics,
  });

  final int density;
  final DashboardInteractionDiagnostics diagnostics;
  int prepareCount = 0;
  int liveLeaseCount = 0;

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) async {
    prepareCount += 1;
    diagnostics
      ..recordDataOperation(DashboardDataOperation.repositoryRead)
      ..recordDataOperation(DashboardDataOperation.platformChannel)
      ..recordDataOperation(DashboardDataOperation.sql);
    return _deck(request, generation: token.generation);
  }

  DashboardPreparedDeck _deck(
    DashboardPreparedDeckRequest request, {
    required int generation,
  }) {
    final childBase = request.semanticCatalog.isEmpty
        ? 0
        : density ~/ request.semanticCatalog.length;
    final childRemainder = request.semanticCatalog.isEmpty
        ? 0
        : density % request.semanticCatalog.length;
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    for (final entry in request.semanticCatalog.entries) {
      final count = childBase + (entry.logicalIndex < childRemainder ? 1 : 0);
      frames[entry.queryKey] = _frame(
        request: request,
        scope: entry.scope,
        count: count,
        digest: Object.hash(request.key, entry.logicalIndex, density),
      );
    }
    return DashboardPreparedDeck.complete(
      key: request.key,
      parentScope: request.parentScope,
      parentFrame: _frame(
        request: request,
        scope: request.parentScope,
        count: density,
        digest: Object.hash(request.key, density),
      ),
      semanticCatalog: request.semanticCatalog,
      frames: frames,
      contentDigest: Object.hash(request.key, density, generation),
      generation: generation,
      preparedAt: DateTime.utc(2026, 8, 5),
      buildMetrics: const DashboardPreparedDeckBuildMetrics.synthetic(),
    );
  }

  DashboardPreparedFrame _frame({
    required DashboardPreparedDeckRequest request,
    required CurrentLedgerQueryScope scope,
    required int count,
    required int digest,
  }) {
    diagnostics
      ..recordDataOperation(DashboardDataOperation.formatting)
      ..recordDataOperation(DashboardDataOperation.logBoxProjection);
    return DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: request.parentScope.key,
      coreRevision: request.key.coreRevision,
      totalMinor: count * 100,
      formattedAmount: '$count,00 Ft',
      entryCount: count,
      formattedEntryCount: '$count',
      logBox: DashboardLogViewportState(
        queryKey: scope.key,
        revision: request.key.coreRevision,
        groups: const [],
        entryCount: count,
        nextCursor: null,
        direction: scope.direction,
      ),
      presentationDigest: digest,
    );
  }

  @override
  Stream<DashboardPreparedFrame> watchCommittedFrame(
    DashboardCommittedFrameRequest request,
  ) {
    liveLeaseCount += 1;
    diagnostics.recordDataOperation(DashboardDataOperation.liveLeaseStart);
    return const Stream<DashboardPreparedFrame>.empty();
  }

  @override
  Future<DashboardPreparedFrame> readCommittedNextPage(
    DashboardCommittedFrameRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) => Future<DashboardPreparedFrame>.value(currentFrame);
}
