import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/dashboard_performance_counters.dart';
import '../data/dashboard_ledger_repository.dart';
import 'dashboard_live_query_lease_coordinator.dart';
import 'dashboard_presentation_diagnostics.dart';
import 'dashboard_query_debug.dart';
import 'dashboard_presentation_store.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

typedef DashboardCoreRevisionRefreshHandler =
    Future<bool> Function(int minimumRevision);

@immutable
class DashboardQueryState {
  const DashboardQueryState({
    required this.scope,
    required this.isLoading,
    required this.result,
    required this.error,
  });

  final CurrentLedgerQueryScope scope;
  final bool isLoading;
  final DashboardLedgerResult? result;
  final Object? error;
}

/// Owns the current query scope and coordinates latest-wins reads.
class CurrentQueryController extends ChangeNotifier {
  CurrentQueryController({
    required DashboardLedgerRepository repository,
    required CurrentLedgerQueryScope initialScope,
    DashboardPresentationStore? presentationStore,
    Duration liveLeaseQuiescence = Duration.zero,
    DashboardPerformanceCounters? performanceCounters,
  }) : _repository = repository,
       _presentationStore = presentationStore,
       performanceCounters =
           performanceCounters ?? DashboardPerformanceCounters(),
       _liveLease = DashboardLiveQueryLeaseCoordinator(
         quiescence: liveLeaseQuiescence,
       ),
       _state = DashboardQueryState(
         scope: initialScope,
         isLoading: false,
         result: null,
         error: null,
       );

  final DashboardLedgerRepository _repository;
  final DashboardPresentationStore? _presentationStore;
  final DashboardPerformanceCounters performanceCounters;
  final _cache = <LedgerQueryKey, DashboardLedgerResult>{};
  static const _cacheCapacity = 36;
  int? _knownCoreRevision;
  int? _pendingCoreRevision;
  DashboardQueryState _state;
  int _requestGeneration = 0;
  int _prewarmGeneration = 0;
  final DashboardLiveQueryLeaseCoordinator _liveLease;
  StreamSubscription<DashboardLedgerResult>? _watchSubscription;
  StreamSubscription<int>? _coreRevisionSubscription;
  bool _motionActive = false;
  int? _activeMotionEpoch;
  bool _revisionRefreshPending = false;
  bool _revisionRefreshInFlight = false;
  bool _revisionRefreshInterruptedByMotion = false;
  int _revisionRefreshGeneration = 0;
  DashboardCoreRevisionRefreshHandler? _coreRevisionRefreshHandler;
  bool _disposed = false;

  DashboardQueryState get state => _state;

  DashboardPresentationStore? get presentationStore => _presentationStore;

  int get pendingLeaseCancellationCount =>
      _liveLease.pendingLeaseCancellationCount;
  int get liveLeaseRequestCount =>
      performanceCounters.value(DashboardPerformanceMetric.liveLeaseRequest);
  int get liveLeaseActivationCount =>
      performanceCounters.value(DashboardPerformanceMetric.liveLeaseActivation);
  int get exactWatchStartCount =>
      performanceCounters.value(DashboardPerformanceMetric.exactWatchStart);
  int get oneShotReadCount =>
      performanceCounters.value(DashboardPerformanceMetric.oneShotRead);
  int get coreRevisionSubscriptionCount => performanceCounters.value(
    DashboardPerformanceMetric.coreRevisionSubscription,
  );
  int? get pendingCoreRevision => _pendingCoreRevision;

  /// Installs the application-level atomic parent+child refresh boundary.
  ///
  /// The query controller owns revision invalidation and interaction gating,
  /// while the dashboard core owns rebuilding the complete visible bundle.
  /// A null handler keeps the standalone one-shot exact-query fallback used
  /// by isolated tests and non-bundle hosts.
  void setCoreRevisionRefreshHandler(
    DashboardCoreRevisionRefreshHandler? handler,
  ) {
    if (_disposed) return;
    _coreRevisionRefreshHandler = handler;
    if (handler != null &&
        !_motionActive &&
        _revisionRefreshPending &&
        !_revisionRefreshInFlight) {
      _scheduleRevisionRefresh();
    }
  }

  /// Called by the dashboard motion lane when a new drag/ballistic epoch
  /// starts. This invalidates only deferred lease activation; it does not
  /// discard the committed query cache or interrupt an already active watch.
  void invalidatePendingLiveLease({required int motionEpoch}) {
    _motionActive = true;
    _activeMotionEpoch = motionEpoch;
    if (_revisionRefreshInFlight) {
      _revisionRefreshInterruptedByMotion = true;
    }
    _liveLease.invalidatePendingForMotion(motionEpoch: motionEpoch);
  }

  /// Releases background refresh work only for the currently active motion
  /// epoch. Presentation settle remains independent and may already be
  /// visible from the canonical bundle when this handoff occurs.
  void resumeBackgroundAfterMotion({required int motionEpoch}) {
    if (_disposed || !_motionActive || _activeMotionEpoch != motionEpoch) {
      return;
    }
    _motionActive = false;
    _activeMotionEpoch = null;
    if (_revisionRefreshPending) _scheduleRevisionRefresh();
  }

  /// Completes after the active scope has a canonical non-placeholder result.
  /// It is a bootstrap/readiness helper; it does not start a second read or
  /// alter the current query owner.
  Future<DashboardQueryState> waitForCurrentSnapshot() async {
    if (_hasCanonicalResult) return _state;
    final completer = Completer<DashboardQueryState>();
    void listener() {
      if (_hasCanonicalResult && !completer.isCompleted) {
        completer.complete(_state);
      } else if (_state.error != null && !completer.isCompleted) {
        completer.completeError(_state.error!);
      }
    }

    addListener(listener);
    listener();
    try {
      return await completer.future;
    } finally {
      removeListener(listener);
    }
  }

  bool get _hasCanonicalResult =>
      !_state.isLoading &&
      _state.error == null &&
      _state.result != null &&
      (_state.result!.scopeKey == null ||
          _state.result!.scopeKey == _state.scope.key.value);

  /// Reads a future direction/scope into the same bounded cache without
  /// changing the active query or notifying the dashboard. This is the only
  /// startup/direction prewarm lane; it never runs from rail preview.
  Future<DashboardLedgerResult?> prewarm(
    CurrentLedgerQueryScope scope, {
    String reason = 'prewarm',
    bool forceRefresh = false,
    int? minimumRevision,
  }) async {
    final cached = _cache[scope.key];
    if (!forceRefresh &&
        cached != null &&
        _matchesKnownRevision(cached) &&
        _meetsMinimumRevision(cached, minimumRevision)) {
      return cached;
    }
    final prewarmGeneration = ++_prewarmGeneration;
    DashboardQueryDebug.mark(
      'PREFETCH_REQUESTED',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$prewarmGeneration reason=$reason',
    );
    try {
      final result = await _repository.read(scope);
      if (_disposed || prewarmGeneration != _prewarmGeneration) return null;
      if (result.scopeKey != null && result.scopeKey != scope.key.value) {
        DashboardQueryDebug.mark(
          'PREFETCH_DROPPED_SCOPE_MISMATCH',
          scope: scope,
          result: result,
          flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
          isStale: true,
        );
        return null;
      }
      final canonical = _canonicalizeResult(scope, result);
      if (!_matchesKnownRevision(canonical) ||
          !_meetsMinimumRevision(canonical, minimumRevision)) {
        DashboardQueryDebug.mark(
          'PREFETCH_DROPPED_REVISION_MISMATCH',
          scope: scope,
          result: canonical,
          flowId: canonical.flowId ?? DashboardQueryDebug.flowIdFor(scope),
          isStale: true,
          detail:
              'minimumRevision=$minimumRevision '
              'knownRevision=$_knownCoreRevision',
        );
        return null;
      }
      _cacheResult(scope.key, canonical);
      _presentationStore?.publish(
        DashboardPresentationSnapshot.fromResult(
          scope: scope,
          generation: prewarmGeneration,
          result: canonical,
        ),
        activate: false,
      );
      DashboardQueryDebug.mark(
        'PREFETCH_COMPLETED',
        scope: scope,
        result: canonical,
        flowId: canonical.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        detail: 'generation=$prewarmGeneration reason=$reason',
      );
      return canonical;
    } on Object catch (error) {
      DashboardQueryDebug.mark(
        'PREFETCH_FAILED',
        scope: scope,
        flowId: DashboardQueryDebug.flowIdFor(scope),
        detail: 'generation=$prewarmGeneration error=$error',
      );
      return null;
    }
  }

  void refresh({String reason = 'initial'}) {
    _ensureCoreRevisionSubscription();
    _liveLease.cancel();
    _cache.clear();
    _knownCoreRevision = null;
    _pendingCoreRevision = null;
    _revisionRefreshPending = false;
    _revisionRefreshInFlight = false;
    _revisionRefreshInterruptedByMotion = false;
    _revisionRefreshGeneration += 1;
    _state = DashboardQueryState(
      scope: _state.scope,
      isLoading: true,
      result: _state.result,
      error: null,
    );
    notifyListeners();
    final generation = ++_requestGeneration;
    _startDataAcquisition(_state.scope, generation, reason: reason);
  }

  /// Clears query state and starts an immediate read for an explicitly chosen
  /// scope. This is used at a startup boundary where navigation has already
  /// been moved (for example after a native seed commit), so a deferred
  /// setTimeScope lease cannot briefly target the pre-seed scope.
  void refreshAtScope(
    CurrentLedgerQueryScope scope, {
    String reason = 'initialAtScope',
  }) {
    _ensureCoreRevisionSubscription();
    _liveLease.cancel();
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _cache.clear();
    _knownCoreRevision = null;
    _pendingCoreRevision = null;
    _revisionRefreshPending = false;
    _revisionRefreshInFlight = false;
    _revisionRefreshInterruptedByMotion = false;
    _revisionRefreshGeneration += 1;
    _state = DashboardQueryState(
      scope: scope,
      isLoading: true,
      result: null,
      error: null,
    );
    notifyListeners();
    final generation = ++_requestGeneration;
    _startDataAcquisition(scope, generation, reason: reason);
  }

  void setTimeScope(
    LedgerTimeScope timeScope, {
    String reason = 'timeScopeChanged',
  }) {
    _setScope(_state.scope.copyWith(timeScope: timeScope), reason: reason);
  }

  void setDirection(LedgerDirection direction) {
    _setScope(
      _state.scope.copyWith(direction: direction),
      reason: 'directionChanged',
    );
  }

  void setFacets({
    Set<String>? categoryIds,
    Set<String>? partnerIds,
    Map<String, Object?>? refinements,
  }) {
    _setScope(
      _state.scope.copyWith(
        categoryIds: categoryIds,
        partnerIds: partnerIds,
        refinements: refinements,
      ),
      reason: 'facetsChanged',
    );
  }

  /// Commits an exact immutable result that was already prepared by the
  /// canonical parent bundle lane.
  ///
  /// This is the presentation-to-query ownership handoff for child settle,
  /// rail open/close and cached parent navigation. It deliberately performs
  /// no repository read, watch cancellation/subscription or deferred lease
  /// activation. The existing active observer may remain alive until the
  /// background synchronization policy replaces it independently.
  bool commitPreparedResult(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result, {
    required String reason,
  }) {
    if (_disposed ||
        (result.scopeKey != null && result.scopeKey != scope.key.value) ||
        (result.direction != null &&
            result.direction != scope.direction.name)) {
      DashboardQueryDebug.mark(
        'PREPARED_QUERY_RESULT_REJECTED',
        scope: scope,
        result: result,
        flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'reason=$reason expected=${scope.key.value} '
            'actual=${result.scopeKey}',
      );
      return false;
    }
    final canonical = _canonicalizeResult(scope, result);
    if (!_matchesKnownRevision(canonical)) {
      DashboardQueryDebug.mark(
        'PREPARED_QUERY_RESULT_REJECTED',
        scope: scope,
        result: canonical,
        flowId: canonical.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'reason=$reason expectedRevision=$_knownCoreRevision '
            'actualRevision=${canonical.coreRevision}',
      );
      return false;
    }

    _liveLease.cancel();
    final generation = ++_requestGeneration;
    final stateChanged =
        _state.scope != scope ||
        _state.isLoading ||
        _state.error != null ||
        _state.result == null ||
        !_sameVisualResult(_state.result!, canonical);
    _adoptCommittedRevision(canonical.coreRevision);
    _cacheResult(scope.key, canonical);
    _state = DashboardQueryState(
      scope: scope,
      isLoading: false,
      result: canonical,
      error: null,
    );

    final store = _presentationStore;
    if (store != null) {
      final existing = store.peekSnapshot(scope.key);
      store.promote(
        DashboardPresentationSnapshot.fromResult(
          scope: scope,
          generation: generation,
          result: canonical,
        ).copyWith(
          dataOrigin: existing?.dataOrigin ?? DashboardDataOrigin.memoryCache,
        ),
      );
    }
    DashboardQueryDebug.mark(
      'PREPARED_QUERY_SCOPE_COMMITTED',
      scope: scope,
      result: canonical,
      flowId: canonical.flowId ?? DashboardQueryDebug.flowIdFor(scope),
      detail:
          'generation=$generation reason=$reason '
          'repositoryReadStarted=false watchRestarted=false',
    );
    if (stateChanged) notifyListeners();
    return true;
  }

  void _setScope(CurrentLedgerQueryScope nextScope, {required String reason}) {
    if (nextScope == _state.scope) return;
    final cached = _cache[nextScope.key];
    if (cached != null && _matchesKnownRevision(cached)) {
      // A canonical cache hit is already the exact visible result. Any
      // deferred activation belongs to the scope we are leaving and must not
      // turn this synchronous promotion into a later watch/read restart.
      _liveLease.cancel();
      ++_requestGeneration;
      _adoptCommittedRevision(cached.coreRevision);
      _cache.remove(nextScope.key);
      _cache[nextScope.key] = cached;
      _state = DashboardQueryState(
        scope: nextScope,
        isLoading: false,
        result: cached,
        error: null,
      );
      _presentationStore?.publish(
        DashboardPresentationSnapshot.fromResult(
          scope: nextScope,
          generation: _requestGeneration,
          result: cached,
        ),
      );
      notifyListeners();
      return;
    }
    if (cached != null) _cache.remove(nextScope.key);
    _state = DashboardQueryState(
      scope: nextScope,
      isLoading: true,
      result: _state.result,
      error: null,
    );
    notifyListeners();
    final generation = ++_requestGeneration;
    _requestLiveLease(nextScope, generation, reason: reason);
  }

  void _requestLiveLease(
    CurrentLedgerQueryScope scope,
    int generation, {
    required String reason,
  }) {
    performanceCounters.increment(DashboardPerformanceMetric.liveLeaseRequest);
    DashboardQueryDebug.mark(
      'LIVE_LEASE_REQUESTED',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation reason=$reason',
    );
    _liveLease.request(
      scope: scope,
      generation: generation,
      activate: () {
        if (_disposed ||
            generation != _requestGeneration ||
            scope != _state.scope) {
          DashboardQueryDebug.mark(
            'LIVE_LEASE_DROPPED_STALE',
            scope: scope,
            flowId: DashboardQueryDebug.flowIdFor(scope),
            isStale: true,
            detail: 'generation=$generation current=$_requestGeneration',
          );
          return;
        }
        DashboardQueryDebug.mark(
          'LIVE_LEASE_ACTIVATED',
          scope: scope,
          flowId: DashboardQueryDebug.flowIdFor(scope),
          detail: 'generation=$generation reason=$reason',
        );
        performanceCounters.increment(
          DashboardPerformanceMetric.liveLeaseActivation,
        );
        _startDataAcquisition(scope, generation, reason: reason);
      },
    );
  }

  void _startDataAcquisition(
    CurrentLedgerQueryScope scope,
    int generation, {
    required String reason,
  }) {
    if (_repository is DashboardCoreRevisionRepository) {
      _startOneShotRead(scope, generation, reason: reason);
      return;
    }
    _startWatching(scope, generation, reason: reason);
  }

  void _startOneShotRead(
    CurrentLedgerQueryScope scope,
    int generation, {
    required String reason,
  }) {
    performanceCounters
      ..increment(DashboardPerformanceMetric.oneShotRead)
      ..increment(DashboardPerformanceMetric.repositoryRead);
    DashboardQueryDebug.mark(
      'D8 currentQueryScopeAccepted',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation reason=$reason acquisition=oneShotRead',
    );
    try {
      _repository
          .read(scope)
          .then(
            (result) => _applyResult(scope, generation, result),
            onError: (Object error, StackTrace stackTrace) {
              _applyError(scope, generation, error);
            },
          );
    } on Object catch (error) {
      _applyError(scope, generation, error);
    }
  }

  void _startWatching(
    CurrentLedgerQueryScope scope,
    int generation, {
    required String reason,
  }) {
    performanceCounters
      ..increment(DashboardPerformanceMetric.exactWatchStart)
      ..increment(DashboardPerformanceMetric.repositoryRead);
    DashboardQueryDebug.mark(
      'D8 currentQueryScopeAccepted',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation reason=$reason',
    );
    _watchSubscription?.cancel();
    _watchSubscription = null;
    var receivedSnapshot = false;
    try {
      _watchSubscription = _repository
          .watch(scope)
          .listen(
            (result) {
              receivedSnapshot = true;
              _applyResult(scope, generation, result);
            },
            onError: (Object error, StackTrace stackTrace) {
              _applyError(scope, generation, error);
            },
            onDone: () {
              if (!receivedSnapshot) {
                _applyError(
                  scope,
                  generation,
                  StateError(
                    'Dashboard observer closed before its initial snapshot.',
                  ),
                );
              }
            },
          );
    } on Object catch (error) {
      _applyError(scope, generation, error);
    }
  }

  void _ensureCoreRevisionSubscription() {
    if (_disposed || _coreRevisionSubscription != null) return;
    final repository = _repository;
    if (repository is! DashboardCoreRevisionRepository) return;
    final revisionRepository = repository as DashboardCoreRevisionRepository;
    performanceCounters.increment(
      DashboardPerformanceMetric.coreRevisionSubscription,
    );
    _coreRevisionSubscription = revisionRepository.watchCoreRevision().listen(
      _handleCoreRevision,
      onError: (Object error, StackTrace stackTrace) {
        DashboardQueryDebug.mark(
          'CORE_REVISION_WATCH_FAILED',
          scope: _state.scope,
          flowId: DashboardQueryDebug.flowIdFor(_state.scope),
          detail: error,
        );
      },
    );
  }

  void _handleCoreRevision(int revision) {
    if (_disposed || revision < 0) return;
    final previous = _knownCoreRevision;
    if (previous == null) {
      _knownCoreRevision = revision;
      return;
    }
    final pending = _pendingCoreRevision;
    final latestKnown = pending != null && pending > previous
        ? pending
        : previous;
    if (revision <= latestKnown) return;
    _pendingCoreRevision = revision;
    _revisionRefreshPending = true;
    _revisionRefreshInterruptedByMotion = false;
    DashboardQueryDebug.mark(
      'CORE_REVISION_INVALIDATED',
      scope: _state.scope,
      coreRevision: revision,
      flowId: DashboardQueryDebug.flowIdFor(_state.scope),
      detail:
          'previousRevision=$previous motionActive=$_motionActive '
          'refreshDeferred=$_motionActive',
    );
    if (!_motionActive) _scheduleRevisionRefresh();
  }

  void _scheduleRevisionRefresh() {
    if (_disposed ||
        _motionActive ||
        !_revisionRefreshPending ||
        _revisionRefreshInFlight) {
      return;
    }
    final minimumRevision = _pendingCoreRevision;
    if (minimumRevision == null) {
      _revisionRefreshPending = false;
      return;
    }
    _revisionRefreshPending = false;
    final handler = _coreRevisionRefreshHandler;
    if (handler == null) {
      final generation = ++_requestGeneration;
      _startOneShotRead(
        _state.scope,
        generation,
        reason: 'coreRevisionChanged',
      );
      return;
    }

    final refreshGeneration = ++_revisionRefreshGeneration;
    _revisionRefreshInFlight = true;
    Future<bool>.sync(() => handler(minimumRevision)).then(
      (handled) {
        if (_disposed || refreshGeneration != _revisionRefreshGeneration) {
          return;
        }
        _revisionRefreshInFlight = false;
        final pendingRevision = _pendingCoreRevision;
        if (!handled) {
          _revisionRefreshPending = pendingRevision != null;
          final retryAfterInterruptedMotion =
              _revisionRefreshInterruptedByMotion && !_motionActive;
          _revisionRefreshInterruptedByMotion = false;
          DashboardQueryDebug.mark(
            'CORE_REVISION_BUNDLE_REFRESH_DEFERRED',
            scope: _state.scope,
            coreRevision: minimumRevision,
            flowId: DashboardQueryDebug.flowIdFor(_state.scope),
            detail: 'handled=false pendingRevision=$pendingRevision',
          );
          if (retryAfterInterruptedMotion) _scheduleRevisionRefresh();
          return;
        }
        _revisionRefreshInterruptedByMotion = false;
        if (pendingRevision != null && pendingRevision > minimumRevision) {
          _revisionRefreshPending = true;
          _scheduleRevisionRefresh();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed || refreshGeneration != _revisionRefreshGeneration) {
          return;
        }
        _revisionRefreshInFlight = false;
        _revisionRefreshPending = _pendingCoreRevision != null;
        final retryAfterInterruptedMotion =
            _revisionRefreshInterruptedByMotion && !_motionActive;
        _revisionRefreshInterruptedByMotion = false;
        DashboardQueryDebug.mark(
          'CORE_REVISION_BUNDLE_REFRESH_FAILED',
          scope: _state.scope,
          coreRevision: minimumRevision,
          flowId: DashboardQueryDebug.flowIdFor(_state.scope),
          detail: error,
        );
        if (retryAfterInterruptedMotion) _scheduleRevisionRefresh();
      },
    );
  }

  void _applyResult(
    CurrentLedgerQueryScope scope,
    int generation,
    DashboardLedgerResult result,
  ) {
    if (result.scopeKey != null && result.scopeKey != scope.key.value) {
      DashboardQueryDebug.mark(
        'D8 queryResultDroppedStale',
        scope: scope,
        result: result,
        flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'scopeMismatch expected=${scope.key.value} actual=${result.scopeKey}',
      );
      return;
    }
    final canonicalResult = _canonicalizeResult(scope, result);
    if (_disposed || generation != _requestGeneration) {
      DashboardQueryDebug.mark(
        'D8 queryResultDroppedStale',
        scope: scope,
        result: canonicalResult,
        flowId: canonicalResult.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail: 'generation=$generation current=$_requestGeneration',
      );
      return;
    }
    final minimumAcceptedRevision = _pendingCoreRevision ?? _knownCoreRevision;
    if (minimumAcceptedRevision != null &&
        (canonicalResult.coreRevision == null ||
            canonicalResult.coreRevision! < minimumAcceptedRevision)) {
      DashboardQueryDebug.mark(
        'D8 queryResultDroppedStale',
        scope: scope,
        result: canonicalResult,
        flowId: canonicalResult.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'revision=${canonicalResult.coreRevision} '
            'minimumAcceptedRevision=$minimumAcceptedRevision',
      );
      return;
    }
    if (canonicalResult.coreRevision != null &&
        _knownCoreRevision != null &&
        canonicalResult.coreRevision! > _knownCoreRevision!) {
      _cache.clear();
    }
    final visualUnchanged =
        _state.result != null &&
        _sameVisualResult(_state.result!, canonicalResult);
    final wasAlreadySettled =
        !_state.isLoading && _state.error == null && visualUnchanged;
    _adoptCommittedRevision(canonicalResult.coreRevision);
    _cacheResult(scope.key, canonicalResult);
    _state = DashboardQueryState(
      scope: scope,
      isLoading: false,
      result: canonicalResult,
      error: null,
    );
    final presentationSnapshot = DashboardPresentationSnapshot.fromResult(
      scope: scope,
      generation: generation,
      result: canonicalResult,
    );
    final store = _presentationStore;
    final visibleTarget = store?.visibleTarget;
    final visibleTargetExpectsThisResult =
        visibleTarget == null ||
        visibleTarget.expectedVisibleQueryKey == presentationSnapshot.queryKey;
    final visiblePresentationAccepted = store == null
        ? true
        : store.publishCommittedResult(
            presentationSnapshot,
            interactionEpoch: store.visibleTarget?.presentationEpoch ?? 0,
          );
    DashboardQueryDebug.mark(
      'D8 currentQuerySliceAccepted',
      scope: scope,
      result: canonicalResult,
      flowId: canonicalResult.flowId ?? DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation',
    );
    // A live result for the old committed scope can still be useful in the
    // query cache. During a different child preview it must not notify the
    // dashboard root, because the store has already rejected it visually and
    // the notification would only redo LogBox/presentation work.
    if (!wasAlreadySettled &&
        visibleTargetExpectsThisResult &&
        visiblePresentationAccepted) {
      notifyListeners();
    }
  }

  bool _sameVisualResult(
    DashboardLedgerResult previous,
    DashboardLedgerResult next,
  ) {
    if (previous.totalMinor != next.totalMinor ||
        previous.entryCount != next.entryCount ||
        previous.coreRevision != next.coreRevision ||
        previous.entries.length != next.entries.length) {
      return false;
    }
    for (var index = 0; index < previous.entries.length; index += 1) {
      if (previous.entries[index].id != next.entries[index].id) return false;
    }
    return true;
  }

  /// A legacy/test repository may omit wire metadata. Normalize it at the
  /// repository boundary so presentation can require an exact canonical key
  /// instead of ever relabelling an old result under a new scope.
  DashboardLedgerResult _canonicalizeResult(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result,
  ) {
    if (result.scopeKey != null) return result;
    return DashboardLedgerResult(
      totalMinor: result.totalMinor,
      entryCount: result.entryCount,
      entries: result.entries,
      nextCursor: result.nextCursor,
      coreRevision: result.coreRevision,
      scopeKey: scope.key.value,
      timeScopeKey: result.timeScopeKey ?? scope.timeScope.canonicalKey,
      direction: result.direction ?? scope.direction.name,
      flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
    );
  }

  void _applyError(
    CurrentLedgerQueryScope scope,
    int generation,
    Object error,
  ) {
    if (_disposed || generation != _requestGeneration) {
      DashboardQueryDebug.mark(
        'D8 queryErrorDroppedStale',
        scope: scope,
        flowId: DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'generation=$generation current=$_requestGeneration error=$error',
      );
      return;
    }
    _state = DashboardQueryState(
      scope: scope,
      isLoading: false,
      result: _state.result,
      error: error,
    );
    DashboardQueryDebug.mark(
      'D8 currentQueryError',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: error,
    );
    notifyListeners();
  }

  bool _matchesKnownRevision(DashboardLedgerResult result) {
    return result.coreRevision == null ||
        _knownCoreRevision == null ||
        result.coreRevision! >= _knownCoreRevision!;
  }

  bool _meetsMinimumRevision(
    DashboardLedgerResult result,
    int? minimumRevision,
  ) {
    if (minimumRevision == null) return true;
    final revision = result.coreRevision;
    return revision != null && revision >= minimumRevision;
  }

  void _adoptCommittedRevision(int? revision) {
    if (revision == null) return;
    final knownRevision = _knownCoreRevision;
    if (knownRevision == null || revision > knownRevision) {
      if (knownRevision != null) _cache.clear();
      _knownCoreRevision = revision;
    }
    final pendingRevision = _pendingCoreRevision;
    if (pendingRevision != null && revision >= pendingRevision) {
      _pendingCoreRevision = null;
      _revisionRefreshPending = false;
    }
  }

  void _cacheResult(LedgerQueryKey key, DashboardLedgerResult result) {
    _cache
      ..remove(key)
      ..[key] = result;
    while (_cache.length > _cacheCapacity) {
      _cache.remove(_cache.keys.first);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration += 1;
    _revisionRefreshGeneration += 1;
    _coreRevisionRefreshHandler = null;
    _liveLease.cancel();
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _coreRevisionSubscription?.cancel();
    _coreRevisionSubscription = null;
    super.dispose();
  }
}
