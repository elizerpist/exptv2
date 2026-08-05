import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'bootstrap installs one complete nonzero deck and parent frame',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);

      final frame = await core.bootstrap();

      expect(repository.requestCount, 1);
      expect(core.activeDeck?.isComplete, isTrue);
      expect(frame.queryKey, core.navigation.state.parentQueryKey);
      expect(frame.coreRevision, 1);
      expect(frame.railOpen, isFalse);
      expect(core.visibleFrames.value, same(frame));
    },
  );

  test('one hundred semantic crossings only select memory frames', () async {
    final repository = _PreparedRepository(autoComplete: true);
    final scheduler = _FrameScheduler();
    final core = _core(repository, scheduler: scheduler);
    addTearDown(core.dispose);
    await core.bootstrap();
    core.setRailOpen(true);
    scheduler.fireFrame();
    final requestsBefore = repository.requestCount;

    for (var index = 0; index < 100; index += 1) {
      core.semanticCrossed(index);
    }
    scheduler.fireFrame();

    expect(repository.requestCount, requestsBefore);
    expect(core.frameCoalescer.requestCount, 101);
    expect(core.frameCoalescer.maximumPublishesInOneDisplayFrame, 1);
    expect(core.visibleFrames.value?.semanticChildIndex, 6);
  });

  test('cold parent target keeps the complete outgoing frame', () async {
    final repository = _PreparedRepository(autoComplete: true);
    final scheduler = _FrameScheduler();
    final core = _core(repository, scheduler: scheduler);
    addTearDown(core.dispose);
    await core.bootstrap();
    final outgoing = core.visibleFrames.value!;
    repository.autoComplete = false;

    final navigation = core.navigateParent(
      DashboardTimeNavigationChangeDirection.forward,
    );
    await pumpEventQueue();

    expect(core.visibleFrames.value, same(outgoing));
    expect(
      core.navigation.state.parentQueryKey,
      isNot(outgoing.parentQueryKey),
    );
    repository.completeLast();
    await navigation;
    expect(core.visibleFrames.value, same(outgoing));

    scheduler.fireFrame();
    expect(
      core.visibleFrames.value?.parentQueryKey,
      core.navigation.state.parentQueryKey,
    );
    expect(
      core.visibleFrames.value?.queryKey,
      core.navigation.state.parentQueryKey,
    );
  });

  test(
    'cold parent completion selects the child settled while data was pending',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      core.setRailOpen(true);
      scheduler.fireFrame();
      repository.autoComplete = false;

      final navigation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.forward,
      );
      await pumpEventQueue();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(19);
      core.settleRail(19);

      repository.completeLast();
      await navigation;
      scheduler.fireFrame();
      await pumpEventQueue();

      expect(
        core.visibleFrames.value?.queryKey.value,
        contains('day:2026-08-20'),
      );
      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.committed);
      expect(
        core.committed.state.committedQueryKey,
        core.visibleFrames.value?.queryKey,
      );
    },
  );

  test(
    'cold parent completion selects the current child while motion continues',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      core.setRailOpen(true);
      scheduler.fireFrame();
      repository.autoComplete = false;

      final navigation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.forward,
      );
      await pumpEventQueue();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(19);

      repository.completeLast();
      await navigation;
      scheduler.fireFrame();

      expect(
        core.visibleFrames.value?.queryKey.value,
        contains('day:2026-08-20'),
      );
      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.preview);
      final publishesBeforeSettle = core.visibleFrames.visiblePublishCount;

      core.settleRail(19);
      await pumpEventQueue();

      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.committed);
      expect(core.visibleFrames.visiblePublishCount, publishesBeforeSettle);
    },
  );

  test(
    'warm parent target is selected without another repository call',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      final initialKey = core.navigation.state.parentQueryKey;

      await core.navigateParent(DashboardTimeNavigationChangeDirection.forward);
      scheduler.fireFrame();
      expect(repository.requestCount, 2);

      await core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(repository.requestCount, 2);
      scheduler.fireFrame();
      expect(core.visibleFrames.value?.parentQueryKey, initialKey);
    },
  );

  test(
    'structural navigation returns before cold deck dispatch starts',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      expect(repository.requestCount, 1);
      final initialPlane = core.navigation.state.plane;

      final navigation = core.navigatePlane(finer: true);

      expect(core.navigation.state.plane, isNot(initialPlane));
      expect(repository.requestCount, 1);

      await navigation;
      expect(repository.requestCount, 2);
    },
  );

  test(
    'idle prewarm prepares previous next and opposite decks without publishing',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final frameScheduler = _FrameScheduler();
      final prewarmScheduler = _PrewarmScheduler();
      final core = DashboardCoreController(
        preparedRepository: repository,
        displayFrameScheduler: frameScheduler,
        backgroundPrewarmScheduler: prewarmScheduler,
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        enableBackgroundPrewarm: true,
      );
      addTearDown(core.dispose);

      await core.bootstrap();
      final visible = core.visibleFrames.value;
      final publishes = core.visibleFrames.visiblePublishCount;
      expect(repository.requestCount, 1);
      expect(prewarmScheduler.pendingCount, 1);

      await prewarmScheduler.flush();

      expect(repository.requestCount, 4);
      expect(core.prepared.cache.length, 4);
      expect(core.visibleFrames.value, same(visible));
      expect(core.visibleFrames.visiblePublishCount, publishes);
    },
  );

  test('rapid A to B to C rejects both older deck completions', () async {
    final repository = _PreparedRepository(autoComplete: true);
    final scheduler = _FrameScheduler();
    final core = _core(repository, scheduler: scheduler);
    addTearDown(core.dispose);
    await core.bootstrap();
    final initial = core.visibleFrames.value;
    repository.autoComplete = false;

    final a = core.navigateParent(
      DashboardTimeNavigationChangeDirection.forward,
    );
    final b = core.navigateParent(
      DashboardTimeNavigationChangeDirection.forward,
    );
    final c = core.navigateParent(
      DashboardTimeNavigationChangeDirection.forward,
    );
    await pumpEventQueue(times: 1);
    expect(repository.pendingCount, 3);

    repository.completeAt(0);
    repository.completeAt(0);
    await pumpEventQueue();
    expect(core.visibleFrames.value, same(initial));

    repository.completeAt(0);
    await Future.wait([a, b, c]);
    scheduler.fireFrame();
    expect(core.staleDeckCompletionCount, 2);
    expect(
      core.visibleFrames.value?.parentQueryKey,
      core.navigation.state.parentQueryKey,
    );
  });

  test(
    'open and closed direction changes publish one exact atomic frame',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();

      await core.selectDirection(TransactionDirection.expense);
      scheduler.fireFrame();
      var visible = core.visibleFrames.value!;
      expect(visible.queryKey.value, startsWith('expense|'));
      expect(visible.queryKey, visible.amount.queryKey);
      expect(visible.queryKey, visible.count.queryKey);
      expect(visible.queryKey, visible.logBox.queryKey);

      core.setRailOpen(true);
      scheduler.fireFrame();
      final completeOutgoing = core.visibleFrames.value!;
      await core.selectDirection(TransactionDirection.income);
      expect(core.visibleFrames.value, same(completeOutgoing));

      scheduler.fireFrame();
      visible = core.visibleFrames.value!;
      expect(visible.railOpen, isTrue);
      expect(visible.queryKey.value, startsWith('income|day:'));
      expect(visible.queryKey, visible.amount.queryKey);
      expect(visible.queryKey, visible.count.queryKey);
      expect(visible.queryKey, visible.logBox.queryKey);
      expect(visible.coreRevision, visible.amount.coreRevision);
      expect(visible.coreRevision, visible.count.coreRevision);
      expect(visible.coreRevision, visible.logBox.revision);
    },
  );

  test('open rail parent navigation maps July 31 to June and back', () async {
    final repository = _PreparedRepository(autoComplete: true);
    final scheduler = _FrameScheduler();
    final core = DashboardCoreController(
      preparedRepository: repository,
      displayFrameScheduler: scheduler,
      initialDate: DateTime(2026, 7, 31),
      initialCoreRevision: 1,
      enableBackgroundPrewarm: false,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    core.setRailOpen(true);
    scheduler.fireFrame();
    expect(
      core.visibleFrames.value?.queryKey.value,
      contains('day:2026-07-31'),
    );

    await core.navigateParent(DashboardTimeNavigationChangeDirection.backward);
    scheduler.fireFrame();
    expect(
      core.visibleFrames.value?.queryKey.value,
      contains('day:2026-06-30'),
    );

    await core.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    scheduler.fireFrame();
    expect(
      core.visibleFrames.value?.queryKey.value,
      contains('day:2026-07-30'),
    );
  });

  test('seed gate starts no preparation before commit', () async {
    final repository = _PreparedRepository(autoComplete: true);
    final scheduler = _FrameScheduler();
    final core = DashboardCoreController(
      preparedRepository: repository,
      displayFrameScheduler: scheduler,
      initialDate: DateTime(2026, 7, 14),
      seedReady: false,
      initialCoreRevision: 1,
      enableBackgroundPrewarm: false,
    );
    addTearDown(core.dispose);

    final bootstrap = core.bootstrap();
    await pumpEventQueue();
    expect(repository.requestCount, 0);

    core.markSeedCommitted();
    await bootstrap;
    expect(repository.requestCount, 1);
  });

  test(
    'settle promotes the visible preview without a visual publish',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      await pumpEventQueue();
      core.setRailOpen(true);
      scheduler.fireFrame();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(18);
      scheduler.fireFrame();
      final publishesBefore = core.visibleFrames.visiblePublishCount;
      final leaseStartsBefore = repository.liveStarts;

      core.settleRail(18);
      await pumpEventQueue();

      expect(core.visibleFrames.visiblePublishCount, publishesBefore);
      expect(core.visibleFrames.committedPromotionCount, 1);
      expect(core.visibleFrames.logRebindCount, 0);
      expect(core.visibleFrames.amountRestartCount, 0);
      expect(repository.liveStarts, leaseStartsBefore + 1);
    },
  );

  test(
    'settle waits for an already scheduled final crossing without republishing',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      await pumpEventQueue();
      core.setRailOpen(true);
      scheduler.fireFrame();
      await pumpEventQueue();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      final publishesBeforeCrossing = core.visibleFrames.visiblePublishCount;
      final promotionsBefore = core.visibleFrames.committedPromotionCount;
      final leaseStartsBefore = repository.liveStarts;

      core.semanticCrossed(18);
      core.settleRail(18);

      expect(core.visibleFrames.visiblePublishCount, publishesBeforeCrossing);
      scheduler.fireFrame();
      await pumpEventQueue();

      expect(
        core.visibleFrames.value?.queryKey.value,
        contains('day:2026-07-19'),
      );
      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.committed);
      expect(
        core.visibleFrames.visiblePublishCount,
        publishesBeforeCrossing + 1,
      );
      expect(core.visibleFrames.committedPromotionCount, promotionsBefore + 1);
      expect(repository.liveStarts, leaseStartsBefore + 1);
      expect(core.visibleFrames.logRebindCount, 0);
      expect(core.visibleFrames.amountRestartCount, 0);
    },
  );

  test(
    'same-index settle restores live ownership without a visual publish',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      await pumpEventQueue();
      core.setRailOpen(true);
      scheduler.fireFrame();
      await pumpEventQueue();
      final visible = core.visibleFrames.value!;
      final publishesBefore = core.visibleFrames.visiblePublishCount;
      final leaseStartsBefore = repository.liveStarts;

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.settleRail(visible.semanticChildIndex);
      await pumpEventQueue();

      expect(core.visibleFrames.value, same(visible));
      expect(core.visibleFrames.visiblePublishCount, publishesBefore);
      expect(repository.liveStarts, leaseStartsBefore + 1);
      expect(core.committed.state.committedQueryKey, visible.queryKey);
    },
  );

  test(
    'opening the rail selects a committed child and transfers live ownership',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      await pumpEventQueue();
      final liveStartsBefore = repository.liveStarts;

      core.setRailOpen(true);
      scheduler.fireFrame();
      await pumpEventQueue();

      expect(core.visibleFrames.value?.railOpen, isTrue);
      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.committed);
      expect(repository.liveStarts, liveStartsBefore + 1);
      expect(
        core.committed.state.committedQueryKey,
        core.visibleFrames.value?.queryKey,
      );
    },
  );

  test(
    'revision invalidation cannot select a frame from the outgoing deck',
    () async {
      final repository = _PreparedRepository(autoComplete: true);
      final scheduler = _FrameScheduler();
      final core = _core(repository, scheduler: scheduler);
      addTearDown(core.dispose);
      await core.bootstrap();
      core.setRailOpen(true);
      scheduler.fireFrame();
      final outgoing = core.visibleFrames.value!;
      repository.autoComplete = false;

      final revision = core.acceptCoreRevision(2);
      await pumpEventQueue();
      final publishesBefore = core.visibleFrames.visiblePublishCount;
      core.motion.semanticCrossed(20);
      scheduler.fireFrame();

      expect(core.visibleFrames.value, same(outgoing));
      expect(core.visibleFrames.visiblePublishCount, publishesBefore);

      repository.completeLast();
      await revision;
      scheduler.fireFrame();
      expect(core.visibleFrames.value?.coreRevision, 2);
    },
  );
}

DashboardCoreController _core(
  _PreparedRepository repository, {
  required _FrameScheduler scheduler,
}) => DashboardCoreController(
  preparedRepository: repository,
  displayFrameScheduler: scheduler,
  initialDate: DateTime(2026, 7, 14),
  initialCoreRevision: 1,
  enableBackgroundPrewarm: false,
);

final class _FrameScheduler implements DashboardDisplayFrameScheduler {
  final List<void Function()> _callbacks = [];

  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(void Function() callback) => _callbacks.add(callback);

  void fireFrame() {
    currentFrameNumber += 1;
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

final class _PrewarmScheduler implements DashboardBackgroundPrewarmScheduler {
  final List<FutureOr<void> Function()> _tasks = [];

  int get pendingCount => _tasks.length;

  @override
  void schedule(FutureOr<void> Function() task) => _tasks.add(task);

  Future<void> flush() async {
    final tasks = List<FutureOr<void> Function()>.of(_tasks);
    _tasks.clear();
    for (final task in tasks) {
      await task();
    }
  }
}

final class _PendingPreparation {
  const _PendingPreparation({
    required this.request,
    required this.token,
    required this.completer,
  });

  final DashboardPreparedDeckRequest request;
  final DashboardPreparationToken token;
  final Completer<DashboardPreparedDeck> completer;
}

final class _PreparedRepository
    implements
        DashboardPreparedDeckRepository,
        DashboardPreparedLiveRepository {
  _PreparedRepository({required this.autoComplete});

  bool autoComplete;
  int requestCount = 0;
  final List<_PendingPreparation> _pending = [];
  final List<StreamController<DashboardPreparedFrame>> _liveControllers = [];
  int liveStarts = 0;

  int get pendingCount => _pending.length;

  @override
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  ) {
    requestCount += 1;
    if (autoComplete) return Future.value(_deck(request, token.generation));
    final completer = Completer<DashboardPreparedDeck>();
    _pending.add(
      _PendingPreparation(request: request, token: token, completer: completer),
    );
    return completer.future;
  }

  void completeLast() => completeAt(_pending.length - 1);

  void completeAt(int index) {
    final pending = _pending.removeAt(index);
    pending.completer.complete(
      _deck(pending.request, pending.token.generation),
    );
  }

  DashboardPreparedDeck _deck(
    DashboardPreparedDeckRequest request,
    int generation,
  ) {
    DashboardPreparedFrame frame(scope, int digest) =>
        DashboardPreparedFrame.complete(
          scope: scope,
          parentQueryKey: request.parentScope.key,
          coreRevision: request.key.coreRevision,
          totalMinor: digest,
          formattedAmount: '$digest,00 Ft',
          entryCount: 0,
          formattedEntryCount: '0',
          logBox: DashboardLogViewportState(
            queryKey: scope.key,
            revision: request.key.coreRevision,
            groups: const [],
            entryCount: 0,
            nextCursor: null,
            direction: scope.direction,
          ),
          presentationDigest: digest,
        );
    final frames = {
      for (final entry in request.semanticCatalog.entries)
        entry.queryKey: frame(entry.scope, entry.logicalIndex + 1),
    };
    return DashboardPreparedDeck.complete(
      key: request.key,
      parentScope: request.parentScope,
      parentFrame: frame(request.parentScope, 1000),
      semanticCatalog: request.semanticCatalog,
      frames: frames,
      contentDigest: Object.hash(request.key, generation),
      generation: generation,
      preparedAt: DateTime.utc(2026, 8, 5),
      buildMetrics: const DashboardPreparedDeckBuildMetrics.synthetic(),
    );
  }

  @override
  Stream<DashboardPreparedFrame> watchCommittedFrame(
    DashboardCommittedFrameRequest request,
  ) {
    liveStarts += 1;
    final controller = StreamController<DashboardPreparedFrame>();
    _liveControllers.add(controller);
    return controller.stream;
  }

  @override
  Future<DashboardPreparedFrame> readCommittedNextPage(
    DashboardCommittedFrameRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) => throw UnimplementedError();
}
