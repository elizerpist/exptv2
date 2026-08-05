import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import '../motion/dashboard_display_frame_coalescer.dart';
import '../motion/dashboard_motion_kernel.dart';
import '../motion/dashboard_motion_state.dart';
import '../motion/dashboard_semantic_catalog.dart';
import '../prepared/application/dashboard_prepared_deck_cache.dart';
import '../prepared/application/dashboard_prepared_deck_pipeline.dart';
import '../prepared/data/dashboard_prepared_deck_repository.dart';
import '../prepared/data/empty_dashboard_prepared_deck_repository.dart';
import '../prepared/domain/dashboard_prepared_deck.dart';
import '../query/application/dashboard_committed_query_controller.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/time_plane.dart';
import '../visible/application/dashboard_visible_frame_store.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_interaction_diagnostics.dart';
import 'dashboard_performance_counters.dart';
import 'transaction_direction_controller.dart';

abstract interface class DashboardBackgroundPrewarmScheduler {
  void schedule(FutureOr<void> Function() task);
}

final class FlutterDashboardBackgroundPrewarmScheduler
    implements DashboardBackgroundPrewarmScheduler {
  const FlutterDashboardBackgroundPrewarmScheduler();

  @override
  void schedule(FutureOr<void> Function() task) {
    SchedulerBinding.instance.scheduleTask<void>(
      task,
      Priority.idle,
      debugLabel: 'dashboard-prepared-deck-prewarm',
    );
  }
}

/// Small composition façade for the dashboard's independent state owners.
///
/// It routes structural intents and exact immutable deck activation. It does
/// not own query results, row projection, scroll physics or a catch-all
/// presentation notifier.
final class DashboardCoreController {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardPreparedDeckRepository? preparedRepository,
    DashboardPreparedLiveRepository? liveRepository,
    DashboardCoreRevisionRepository? revisionRepository,
    DashboardDisplayFrameScheduler? displayFrameScheduler,
    DateTime? initialDate,
    bool seedReady = true,
    int? initialCoreRevision,
    this.pageSize = 24,
    DashboardPerformanceCounters? performanceCounters,
    DashboardInteractionDiagnostics? interactionDiagnostics,
    this.enableBackgroundPrewarm = false,
    DashboardBackgroundPrewarmScheduler? backgroundPrewarmScheduler,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       navigation = DashboardNavigationController(initialDate: initialDate),
       transactionDirection = TransactionDirectionController(),
       _seedReady = seedReady,
       _revisionRepository = revisionRepository {
    this.performanceCounters =
        interactionDiagnostics?.counters ??
        performanceCounters ??
        DashboardPerformanceCounters();
    diagnostics =
        interactionDiagnostics ??
        DashboardInteractionDiagnostics(counters: this.performanceCounters);
    _backgroundPrewarmScheduler =
        backgroundPrewarmScheduler ??
        const FlutterDashboardBackgroundPrewarmScheduler();
    final repository =
        preparedRepository ?? const EmptyDashboardPreparedDeckRepository();
    _usesNativePreparedRepository =
        repository is DashboardNativePreparedRepository;
    final initialCatalog = _catalogFor(navigation.state);
    motion = DashboardMotionKernel(
      catalog: initialCatalog,
      initialLogicalIndex: navigation.selectedChildLogicalIndex,
    );
    prepared = DashboardPreparedDeckPipeline(
      repository: repository,
      cache: DashboardPreparedDeckCache(capacity: 8),
    );
    visibleFrames = DashboardVisibleFrameStore();
    frameCoalescer = DashboardDisplayFrameCoalescer(
      scheduler:
          displayFrameScheduler ?? FlutterDashboardDisplayFrameScheduler(),
      publish: _publishCoalescedFrame,
    );
    committed = DashboardCommittedQueryController(
      visibleFrames: visibleFrames,
      repository:
          liveRepository ??
          (repository is DashboardPreparedLiveRepository
              ? repository as DashboardPreparedLiveRepository
              : null),
      pageSize: pageSize,
      onLiveLeaseStarted: _onLiveLeaseStarted,
      onPageReadStarted: _onPageReadStarted,
      onLiveFrameAccepted: _onLiveFrameAccepted,
      onStaleCallbackRejected: _onStaleLiveCallbackRejected,
    );
    motion.setCallbacks(
      onSemanticCrossed: (entry, context) => diagnostics.runMotionHotPath(
        () => _onSemanticCrossed(entry, context),
      ),
      onSettled: _onSettled,
      onBallisticStarted: _onBallisticStarted,
    );
    _pendingInitialRevision = initialCoreRevision;
    if (initialCoreRevision != null && seedReady) {
      _acceptInitialRevision(initialCoreRevision);
    }
  }

  final DashboardLayoutMetrics metrics;
  final int pageSize;
  final bool enableBackgroundPrewarm;
  final DashboardExpansionController expansion;
  final DashboardNavigationController navigation;
  final TransactionDirectionController transactionDirection;
  late final DashboardPerformanceCounters performanceCounters;
  late final DashboardInteractionDiagnostics diagnostics;
  late final DashboardMotionKernel motion;
  late final DashboardPreparedDeckPipeline prepared;
  late final DashboardVisibleFrameStore visibleFrames;
  late final DashboardDisplayFrameCoalescer frameCoalescer;
  late final DashboardCommittedQueryController committed;

  final DashboardCoreRevisionRepository? _revisionRepository;
  late final DashboardBackgroundPrewarmScheduler _backgroundPrewarmScheduler;
  late final bool _usesNativePreparedRepository;
  late bool _seedReady;
  Completer<void>? _seedReadyCompleter;
  StreamSubscription<int>? _revisionSubscription;
  Completer<int>? _firstRevisionCompleter;
  DashboardPreparedDeck? _activeDeck;
  int? _coreRevision;
  int? _pendingInitialRevision;
  int _navigationRequestGeneration = 0;
  int _presentationEpoch = 0;
  int _frameGeneration = 0;
  int _staleDeckCompletionCount = 0;
  _DashboardSettledCommit? _pendingSettledCommit;
  bool _bootstrapped = false;
  bool _disposed = false;

  DashboardPreparedDeck? get activeDeck => _activeDeck;
  int? get coreRevision => _coreRevision;
  int get staleDeckCompletionCount => _staleDeckCompletionCount;
  bool get isBootstrapped => _bootstrapped;

  Future<DashboardVisibleFrame> bootstrap({int? coreRevision}) async {
    if (_disposed) throw StateError('Dashboard core has been disposed.');
    if (!_seedReady) {
      _seedReadyCompleter ??= Completer<void>();
      await _seedReadyCompleter!.future;
    }
    final revision =
        coreRevision ?? _coreRevision ?? await _waitForFirstPositiveRevision();
    _acceptInitialRevision(revision);
    final frame = await _activateTarget(
      navigation.state,
      source: 'bootstrap',
      publishImmediately: true,
    );
    if (frame == null) {
      throw StateError('Dashboard bootstrap target was superseded.');
    }
    _bootstrapped = true;
    return frame;
  }

  void markSeedCommitted({int? coreRevision}) {
    if (_disposed) return;
    _seedReady = true;
    _seedReadyCompleter?.complete();
    _seedReadyCompleter = null;
    final revision = coreRevision ?? _pendingInitialRevision;
    if (revision != null) _acceptInitialRevision(revision);
  }

  Future<void> acceptCoreRevision(int revision) async {
    if (revision <= 0 || _disposed || revision == _coreRevision) return;
    _coreRevision = revision;
    prepared.acceptCoreRevision(revision);
    prepared.openSeedGate();
    committed.invalidate();
    _pendingSettledCommit = null;
    _activeDeck = null;
    if (_bootstrapped) {
      await _activateTarget(navigation.state, source: 'revision');
    }
  }

  void beginRailMotion(CenteredCarouselMotionOrigin origin) {
    _pendingSettledCommit = null;
    diagnostics.setMotionActive(true);
    prepared.setInteractionActive(true);
    committed.invalidate();
    if (origin == CenteredCarouselMotionOrigin.userDrag) {
      motion.beginGesture();
      diagnostics.record(
        DashboardInteractionEvent.motionGestureStarted,
        context: _diagnosticContext(),
        source: 'railGesture',
      );
    }
  }

  void _onBallisticStarted(double velocity, DashboardMotionContext _) {
    diagnostics.record(
      DashboardInteractionEvent.motionBallisticStarted,
      context: _diagnosticContext(),
      source: 'railPhysics',
    );
  }

  void semanticCrossed(int logicalIndex) =>
      motion.semanticCrossed(logicalIndex);

  void settleRail(int logicalIndex) => motion.settled(logicalIndex);

  void toggleRail() => setRailOpen(!navigation.state.isRailOpen);

  void setRailOpen(bool open) {
    if (open == navigation.state.isRailOpen) return;
    navigation.setRailOpen(open);
    _presentationEpoch += 1;
    _pendingSettledCommit = null;
    committed.invalidate();
    final deck = _activeDeck;
    if (deck == null ||
        deck.parentScope.key != navigation.state.parentQueryKey) {
      return;
    }
    _requestVisibleFromDeck(deck, navigation.state);
  }

  Future<void> navigateParent(
    DashboardTimeNavigationChangeDirection direction,
  ) async {
    final target = navigation.commitParent(direction);
    if (target == null) return;
    await _yieldToStartedMotion();
    await _activateTarget(target, source: 'parent');
  }

  Future<void> commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) => navigateParent(direction);

  DashboardNavigationState? previewParent(
    DashboardTimeNavigationChangeDirection direction,
  ) => navigation.parentCandidate(direction);

  Future<void> navigatePlane({required bool finer}) async {
    final target = navigation.commitPlane(finer: finer);
    await _yieldToStartedMotion();
    await _activateTarget(target, source: 'plane');
  }

  Future<void> selectDirection(TransactionDirection direction) async {
    transactionDirection.select(direction);
    final ledgerDirection = direction == TransactionDirection.income
        ? LedgerDirection.income
        : LedgerDirection.expense;
    final target = navigation.selectDirection(ledgerDirection);
    await _yieldToStartedMotion();
    await _activateTarget(target, source: 'direction');
  }

  /// Ends the synchronous navigation-intent stack before data preparation is
  /// dispatched. Motion owners observe the structural state and start their
  /// controllers synchronously; preparation then proceeds independently.
  Future<void> _yieldToStartedMotion() => Future<void>.value();

  Future<bool> loadNextPage() => committed.loadNextPage();

  Future<DashboardVisibleFrame?> _activateTarget(
    DashboardNavigationState target, {
    required String source,
    bool publishImmediately = false,
  }) async {
    final revision = _coreRevision;
    if (revision == null || revision <= 0) {
      throw StateError('A nonzero core revision is required.');
    }
    final requestGeneration = ++_navigationRequestGeneration;
    final targetPresentationEpoch = ++_presentationEpoch;
    _pendingSettledCommit = null;
    committed.invalidate();
    prepared.cancelPrewarm();
    final request = _requestFor(target, revision);
    motion.installCatalog(
      request.semanticCatalog,
      selectedLogicalIndex: _selectedIndex(target, request.semanticCatalog),
    );
    final access = prepared.resolveRequired(request);
    diagnostics.record(
      access.isCacheHit
          ? DashboardInteractionEvent.preparedDeckCacheHit
          : DashboardInteractionEvent.preparedDeckCacheMiss,
      context: _diagnosticContext(
        queryKey: request.parentScope.key,
        parentQueryKey: request.parentScope.key,
      ),
      source: source,
    );
    late final DashboardPreparedDeck deck;
    if (access.isCacheHit) {
      deck = await access.future;
    } else {
      final preparationTimer = Stopwatch()..start();
      if (access.kind == DashboardRequiredDeckAccessKind.started) {
        _recordRepositoryOperation();
        diagnostics.record(
          DashboardInteractionEvent.preparedDeckStarted,
          context: _diagnosticContext(
            queryKey: request.parentScope.key,
            parentQueryKey: request.parentScope.key,
          ),
          source: source,
        );
      }
      try {
        deck = await access.future;
      } on Object {
        preparationTimer.stop();
        diagnostics.record(
          DashboardInteractionEvent.preparedDeckDiscarded,
          context: _diagnosticContext(
            queryKey: request.parentScope.key,
            parentQueryKey: request.parentScope.key,
          ),
          source: source,
          duration: preparationTimer.elapsed,
        );
        rethrow;
      }
      preparationTimer.stop();
      diagnostics.record(
        DashboardInteractionEvent.preparedDeckReady,
        context: _diagnosticContext(
          queryKey: request.parentScope.key,
          parentQueryKey: request.parentScope.key,
        ),
        source: source,
        duration: preparationTimer.elapsed,
      );
    }
    if (_disposed ||
        requestGeneration != _navigationRequestGeneration ||
        revision != _coreRevision ||
        target.navigationEpoch != navigation.state.navigationEpoch ||
        target.parentQueryKey != navigation.state.parentQueryKey ||
        deck.key != request.key ||
        deck.generation <= 0) {
      _staleDeckCompletionCount += 1;
      diagnostics.record(
        DashboardInteractionEvent.staleCallbackRejected,
        context: _diagnosticContext(
          queryKey: deck.parentScope.key,
          parentQueryKey: deck.parentScope.key,
        ),
        source: '$source:deckCompletion',
      );
      return null;
    }
    final currentTarget = navigation.state;
    _activeDeck = deck;
    _presentationEpoch = targetPresentationEpoch;
    final prewarmRequests = _prewarmRequests(currentTarget, revision);
    prepared.cache.updateResidency(
      active: deck.key,
      previous: prewarmRequests.previous?.key,
      next: prewarmRequests.next?.key,
      oppositeDirection: prewarmRequests.oppositeDirection.key,
    );
    final frame = _visibleFromDeck(
      deck,
      currentTarget,
      presentationEpoch: targetPresentationEpoch,
      mode: prepared.state.interactionActive
          ? DashboardVisibleMode.preview
          : DashboardVisibleMode.committed,
    );
    if (publishImmediately) {
      _publishCoalescedFrame(frame);
    } else {
      frameCoalescer.request(frame);
    }
    _schedulePrewarm(
      prewarmRequests.all,
      expectedRequestGeneration: requestGeneration,
      expectedNavigationEpoch: target.navigationEpoch,
      expectedRevision: revision,
    );
    return frame;
  }

  _DashboardPrewarmRequests _prewarmRequests(
    DashboardNavigationState state,
    int revision,
  ) {
    final previousState = navigation.parentCandidate(
      DashboardTimeNavigationChangeDirection.backward,
    );
    final nextState = navigation.parentCandidate(
      DashboardTimeNavigationChangeDirection.forward,
    );
    final oppositeDirection =
        state.parentQueryScope.direction == LedgerDirection.income
        ? LedgerDirection.expense
        : LedgerDirection.income;
    final oppositeState = state.copyWith(
      parentQueryScope: state.parentQueryScope.copyWith(
        direction: oppositeDirection,
      ),
    );
    return _DashboardPrewarmRequests(
      previous: previousState == null
          ? null
          : _requestFor(previousState, revision),
      next: nextState == null ? null : _requestFor(nextState, revision),
      oppositeDirection: _requestFor(oppositeState, revision),
    );
  }

  void _schedulePrewarm(
    Iterable<DashboardPreparedDeckRequest> requests, {
    required int expectedRequestGeneration,
    required int expectedNavigationEpoch,
    required int expectedRevision,
  }) {
    if (!enableBackgroundPrewarm || _disposed) return;
    final unique = <DashboardPreparedDeckKey, DashboardPreparedDeckRequest>{
      for (final request in requests) request.key: request,
    }.values.toList(growable: false);
    _backgroundPrewarmScheduler.schedule(
      () => _runPrewarm(
        unique,
        expectedRequestGeneration: expectedRequestGeneration,
        expectedNavigationEpoch: expectedNavigationEpoch,
        expectedRevision: expectedRevision,
      ),
    );
  }

  Future<void> _runPrewarm(
    Iterable<DashboardPreparedDeckRequest> requests, {
    required int expectedRequestGeneration,
    required int expectedNavigationEpoch,
    required int expectedRevision,
  }) async {
    for (final request in requests) {
      if (_disposed ||
          prepared.state.interactionActive ||
          expectedRequestGeneration != _navigationRequestGeneration ||
          expectedNavigationEpoch != navigation.state.navigationEpoch ||
          expectedRevision != _coreRevision) {
        return;
      }
      final access = prepared.beginPrewarm(request);
      if (access.kind == DashboardPrewarmAccessKind.suppressed) return;
      final context = _diagnosticContext(
        queryKey: request.parentScope.key,
        parentQueryKey: request.parentScope.key,
      );
      if (access.kind == DashboardPrewarmAccessKind.cacheHit) {
        diagnostics.record(
          DashboardInteractionEvent.preparedDeckCacheHit,
          context: context,
          source: 'prewarm',
        );
        continue;
      }
      diagnostics.record(
        DashboardInteractionEvent.preparedDeckCacheMiss,
        context: context,
        source: 'prewarm:${access.kind.name}',
      );
      final timer = Stopwatch()..start();
      if (access.kind == DashboardPrewarmAccessKind.started) {
        _recordRepositoryOperation();
        diagnostics.record(
          DashboardInteractionEvent.preparedDeckStarted,
          context: context,
          source: 'prewarm',
        );
      }
      await access.completion;
      timer.stop();
      final ready = prepared.cache.peek(request.key) != null;
      diagnostics.record(
        ready
            ? DashboardInteractionEvent.preparedDeckReady
            : DashboardInteractionEvent.preparedDeckDiscarded,
        context: context,
        source: 'prewarm',
        duration: timer.elapsed,
      );
      if (!ready) return;
    }
  }

  void _onSemanticCrossed(
    DashboardSemanticEntry entry,
    DashboardMotionContext _,
  ) {
    diagnostics.record(
      DashboardInteractionEvent.motionSemanticCrossed,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: entry.logicalIndex,
      ),
      source: 'semanticCatalog',
    );
    final deck = _activeDeck;
    final state = navigation.state;
    if (deck == null ||
        deck.parentScope.key != state.parentQueryKey ||
        entry.queryKey !=
            deck.semanticCatalog
                .entryAtLogicalIndex(entry.logicalIndex)
                .queryKey) {
      return;
    }
    final preparedFrame = deck.frames[entry.queryKey];
    if (preparedFrame == null) return;
    diagnostics.record(
      DashboardInteractionEvent.motionFrameTargetSelected,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        parentQueryKey: deck.parentScope.key,
        semanticIndex: entry.logicalIndex,
      ),
      source: 'preparedDeck',
    );
    frameCoalescer.request(
      DashboardVisibleFrame.fromPrepared(
        preparedFrame,
        parentQueryKey: deck.parentScope.key,
        plane: state.plane,
        railOpen: state.isRailOpen,
        semanticIndex: entry.logicalIndex,
        childLabel: entry.label,
        navigationEpoch: state.navigationEpoch,
        presentationEpoch: _presentationEpoch,
        frameGeneration: ++_frameGeneration,
        mode: DashboardVisibleMode.preview,
      ),
    );
  }

  void _onSettled(DashboardSemanticEntry entry, DashboardMotionContext _) {
    diagnostics.setMotionActive(false);
    prepared.setInteractionActive(false);
    diagnostics.record(
      DashboardInteractionEvent.motionSettled,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: entry.logicalIndex,
      ),
      source: 'railPhysics',
    );
    final state = navigation.state;
    if (!state.isRailOpen ||
        motion.catalog.entryForQueryKey(entry.queryKey) == null) {
      return;
    }
    navigation.retainSettledChild(
      value: entry.value,
      expectedNavigationEpoch: state.navigationEpoch,
    );
    final deck = _activeDeck;
    if (deck == null ||
        deck.parentScope.key != state.parentQueryKey ||
        deck.frames[entry.queryKey] == null) {
      return;
    }
    _pendingSettledCommit = _DashboardSettledCommit(
      queryKey: entry.queryKey,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: _presentationEpoch,
    );
    _promoteSettledFrameIfVisible();
  }

  void _promoteSettledFrameIfVisible() {
    final pending = _pendingSettledCommit;
    final visible = visibleFrames.value;
    if (pending == null ||
        visible == null ||
        visible.queryKey != pending.queryKey ||
        visible.navigationEpoch != pending.navigationEpoch ||
        visible.presentationEpoch != pending.presentationEpoch) {
      return;
    }
    _pendingSettledCommit = null;
    final promoted = visibleFrames.promoteCommitted(
      expectedKey: pending.queryKey,
      epoch: pending.presentationEpoch,
    );
    final committedFrame = visibleFrames.value;
    if (promoted && committedFrame != null) {
      diagnostics.record(
        DashboardInteractionEvent.committedFramePromoted,
        context: _diagnosticContext(frame: committedFrame),
        source: 'settle',
      );
    }
    if (committedFrame?.mode == DashboardVisibleMode.committed) {
      unawaited(committed.commit(committedFrame!));
    }
  }

  void _requestVisibleFromDeck(
    DashboardPreparedDeck deck,
    DashboardNavigationState state,
  ) {
    frameCoalescer.request(
      _visibleFromDeck(
        deck,
        state,
        presentationEpoch: _presentationEpoch,
        mode: DashboardVisibleMode.committed,
      ),
    );
  }

  void _publishCoalescedFrame(DashboardVisibleFrame frame) {
    final published = visibleFrames.publish(frame);
    if (published) {
      diagnostics.record(
        DashboardInteractionEvent.visibleFramePublished,
        context: _diagnosticContext(frame: frame),
        source: frame.mode.name,
      );
    }
    _promoteSettledFrameIfVisible();
    final current = visibleFrames.value;
    if (frame.mode == DashboardVisibleMode.committed &&
        identical(current, frame)) {
      unawaited(committed.commit(current!));
    }
  }

  void _onLiveLeaseStarted(DashboardCommittedFrameRequest request) {
    diagnostics.recordDataOperation(DashboardDataOperation.liveLeaseStart);
    _recordRepositoryOperation();
    diagnostics.record(
      DashboardInteractionEvent.liveLeaseStarted,
      context: _diagnosticContext(
        queryKey: request.scope.key,
        parentQueryKey: request.parentQueryKey,
      ),
      source: 'committedQuery',
    );
  }

  void _onPageReadStarted(DashboardCommittedFrameRequest _) {
    _recordRepositoryOperation();
  }

  void _recordRepositoryOperation() {
    diagnostics.recordDataOperation(DashboardDataOperation.repositoryRead);
    if (!_usesNativePreparedRepository) return;
    diagnostics
      ..recordDataOperation(DashboardDataOperation.platformChannel)
      ..recordDataOperation(DashboardDataOperation.sql);
  }

  void _onLiveFrameAccepted(
    DashboardPreparedFrame frame,
    DashboardCommittedFrameRequest request,
  ) {
    diagnostics.record(
      DashboardInteractionEvent.liveFrameAccepted,
      context: _diagnosticContext(
        queryKey: frame.queryKey,
        parentQueryKey: request.parentQueryKey,
      ),
      source: 'committedLive',
    );
  }

  void _onStaleLiveCallbackRejected(
    DashboardPreparedFrame frame,
    DashboardCommittedFrameRequest request,
  ) {
    diagnostics.record(
      DashboardInteractionEvent.staleCallbackRejected,
      context: _diagnosticContext(
        queryKey: frame.queryKey,
        parentQueryKey: request.parentQueryKey,
      ),
      source: 'committedLive',
    );
  }

  DashboardDiagnosticContext _diagnosticContext({
    DashboardVisibleFrame? frame,
    LedgerQueryKey? queryKey,
    LedgerQueryKey? parentQueryKey,
    int? semanticIndex,
  }) {
    final motionState = motion.state;
    final navigationState = navigation.state;
    final visible = frame ?? visibleFrames.value;
    return DashboardDiagnosticContext(
      gestureId: motionState.gestureId,
      motionEpoch: motionState.motionEpoch,
      navigationEpoch:
          visible?.navigationEpoch ?? navigationState.navigationEpoch,
      presentationEpoch: visible?.presentationEpoch ?? _presentationEpoch,
      queryKey: queryKey ?? visible?.queryKey,
      parentQueryKey:
          parentQueryKey ??
          visible?.parentQueryKey ??
          navigationState.parentQueryKey,
      coreRevision: visible?.coreRevision ?? _coreRevision ?? 0,
      semanticIndex:
          semanticIndex ??
          visible?.semanticChildIndex ??
          motionState.semanticIndex,
      frameNumber: frameCoalescer.currentFrameNumber,
    );
  }

  DashboardVisibleFrame _visibleFromDeck(
    DashboardPreparedDeck deck,
    DashboardNavigationState state, {
    required int presentationEpoch,
    required DashboardVisibleMode mode,
  }) {
    final selectedIndex =
        state.isRailOpen &&
            prepared.state.interactionActive &&
            motion.catalog.parentScope.key == deck.parentScope.key &&
            motion.catalog.windowIdentity == deck.semanticCatalog.windowIdentity
        ? motion.state.semanticIndex
        : _selectedIndex(state, deck.semanticCatalog);
    final selectedEntry = deck.semanticCatalog.entryAtLogicalIndex(
      selectedIndex,
    );
    final preparedFrame = state.isRailOpen
        ? deck.frameFor(selectedEntry.queryKey)
        : deck.parentFrame;
    return DashboardVisibleFrame.fromPrepared(
      preparedFrame,
      parentQueryKey: deck.parentScope.key,
      plane: state.plane,
      railOpen: state.isRailOpen,
      semanticIndex: selectedIndex,
      childLabel: selectedEntry.label,
      navigationEpoch: state.navigationEpoch,
      presentationEpoch: presentationEpoch,
      frameGeneration: ++_frameGeneration,
      mode: mode,
    );
  }

  DashboardPreparedDeckRequest _requestFor(
    DashboardNavigationState state,
    int revision,
  ) {
    final catalog = _catalogFor(state);
    return DashboardPreparedDeckRequest(
      key: DashboardPreparedDeckKey.fromScope(
        parentScope: state.parentQueryScope,
        childKind: catalog.childKind,
        coreRevision: revision,
        pageSize: pageSize,
        semanticWindowIdentity: catalog.windowIdentity,
      ),
      parentScope: state.parentQueryScope,
      semanticCatalog: catalog,
    );
  }

  int _selectedIndex(
    DashboardNavigationState state,
    DashboardSemanticCatalog catalog,
  ) => catalog.logicalIndexForValue(state.retainedSemanticChild);

  static DashboardSemanticCatalog _catalogFor(DashboardNavigationState state) =>
      DashboardSemanticCatalog.forParent(
        parentScope: state.parentQueryScope,
        childKind: switch (state.plane) {
          TimePlane.sum => DashboardChildKind.year,
          TimePlane.year => DashboardChildKind.month,
          TimePlane.month => DashboardChildKind.day,
        },
        retainedYear: state.retainedChildYear,
      );

  void _acceptInitialRevision(int revision) {
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    if (_coreRevision == revision && prepared.state.seedGateOpen) return;
    _coreRevision = revision;
    prepared.acceptCoreRevision(revision);
    prepared.openSeedGate();
  }

  Future<int> _waitForFirstPositiveRevision() {
    final existing = _firstRevisionCompleter;
    if (existing != null) return existing.future;
    final repository = _revisionRepository;
    if (repository == null) {
      throw StateError('No dashboard core revision source is configured.');
    }
    final completer = Completer<int>();
    _firstRevisionCompleter = completer;
    _revisionSubscription = repository.watchCoreRevision().listen(
      (revision) {
        if (revision <= 0) return;
        if (!completer.isCompleted) {
          completer.complete(revision);
          return;
        }
        unawaited(acceptCoreRevision(revision));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );
    return completer.future;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _navigationRequestGeneration += 1;
    unawaited(_revisionSubscription?.cancel());
    committed.dispose();
    visibleFrames.dispose();
    motion.dispose();
    navigation.dispose();
    transactionDirection.dispose();
    expansion.dispose();
  }
}

final class _DashboardPrewarmRequests {
  const _DashboardPrewarmRequests({
    required this.previous,
    required this.next,
    required this.oppositeDirection,
  });

  final DashboardPreparedDeckRequest? previous;
  final DashboardPreparedDeckRequest? next;
  final DashboardPreparedDeckRequest oppositeDirection;

  Iterable<DashboardPreparedDeckRequest> get all =>
      <DashboardPreparedDeckRequest>[?previous, ?next, oppositeDirection];
}

final class _DashboardSettledCommit {
  const _DashboardSettledCommit({
    required this.queryKey,
    required this.navigationEpoch,
    required this.presentationEpoch,
  });

  final LedgerQueryKey queryKey;
  final int navigationEpoch;
  final int presentationEpoch;
}
