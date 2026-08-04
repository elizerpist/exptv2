import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/dashboard_ledger_repository.dart';
import 'dashboard_live_query_lease_coordinator.dart';
import 'dashboard_query_debug.dart';
import 'dashboard_presentation_store.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

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
  }) : _repository = repository,
       _presentationStore = presentationStore,
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
  final _cache = <LedgerQueryKey, DashboardLedgerResult>{};
  static const _cacheCapacity = 36;
  int? _knownCoreRevision;
  DashboardQueryState _state;
  int _requestGeneration = 0;
  int _prewarmGeneration = 0;
  final DashboardLiveQueryLeaseCoordinator _liveLease;
  StreamSubscription<DashboardLedgerResult>? _watchSubscription;
  bool _disposed = false;

  DashboardQueryState get state => _state;

  DashboardPresentationStore? get presentationStore => _presentationStore;

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
  Future<void> prewarm(
    CurrentLedgerQueryScope scope, {
    String reason = 'prewarm',
  }) async {
    final cached = _cache[scope.key];
    if (cached != null && _matchesKnownRevision(cached)) return;
    final prewarmGeneration = ++_prewarmGeneration;
    DashboardQueryDebug.mark(
      'PREFETCH_REQUESTED',
      scope: scope,
      flowId: DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$prewarmGeneration reason=$reason',
    );
    try {
      final result = await _repository.read(scope);
      if (_disposed || prewarmGeneration != _prewarmGeneration) return;
      if (result.scopeKey != null && result.scopeKey != scope.key.value) {
        DashboardQueryDebug.mark(
          'PREFETCH_DROPPED_SCOPE_MISMATCH',
          scope: scope,
          result: result,
          flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
          isStale: true,
        );
        return;
      }
      final canonical = _canonicalizeResult(scope, result);
      if (!_matchesKnownRevision(canonical)) return;
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
    } on Object catch (error) {
      DashboardQueryDebug.mark(
        'PREFETCH_FAILED',
        scope: scope,
        flowId: DashboardQueryDebug.flowIdFor(scope),
        detail: 'generation=$prewarmGeneration error=$error',
      );
    }
  }

  void refresh({String reason = 'initial'}) {
    _liveLease.cancel();
    _cache.clear();
    _knownCoreRevision = null;
    _state = DashboardQueryState(
      scope: _state.scope,
      isLoading: true,
      result: _state.result,
      error: null,
    );
    notifyListeners();
    final generation = ++_requestGeneration;
    _startWatching(_state.scope, generation, reason: reason);
  }

  /// Clears query state and starts an immediate read for an explicitly chosen
  /// scope. This is used at a startup boundary where navigation has already
  /// been moved (for example after a native seed commit), so a deferred
  /// setTimeScope lease cannot briefly target the pre-seed scope.
  void refreshAtScope(
    CurrentLedgerQueryScope scope, {
    String reason = 'initialAtScope',
  }) {
    _liveLease.cancel();
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _cache.clear();
    _knownCoreRevision = null;
    _state = DashboardQueryState(
      scope: scope,
      isLoading: true,
      result: null,
      error: null,
    );
    notifyListeners();
    final generation = ++_requestGeneration;
    _startWatching(scope, generation, reason: reason);
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

  void _setScope(CurrentLedgerQueryScope nextScope, {required String reason}) {
    if (nextScope == _state.scope) return;
    final cached = _cache[nextScope.key];
    if (cached != null && _matchesKnownRevision(cached)) {
      ++_requestGeneration;
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
      if (_liveLease.quiescence > Duration.zero) {
        _requestLiveLease(
          nextScope,
          _requestGeneration,
          reason: 'cacheHit:$reason',
        );
      }
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
        _startWatching(scope, generation, reason: reason);
      },
    );
  }

  void _startWatching(
    CurrentLedgerQueryScope scope,
    int generation, {
    required String reason,
  }) {
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
    if (canonicalResult.coreRevision != null &&
        _knownCoreRevision != null &&
        canonicalResult.coreRevision != _knownCoreRevision) {
      _cache.clear();
    }
    final visualUnchanged =
        _state.result != null &&
        _sameVisualResult(_state.result!, canonicalResult);
    final wasAlreadySettled =
        !_state.isLoading && _state.error == null && visualUnchanged;
    _knownCoreRevision = canonicalResult.coreRevision ?? _knownCoreRevision;
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
    if (store != null) {
      store.publishCommittedResult(
        presentationSnapshot,
        interactionEpoch: store.visibleTarget?.presentationEpoch ?? 0,
      );
    }
    DashboardQueryDebug.mark(
      'D8 currentQuerySliceAccepted',
      scope: scope,
      result: canonicalResult,
      flowId: canonicalResult.flowId ?? DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation',
    );
    if (!wasAlreadySettled) notifyListeners();
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
        result.coreRevision == _knownCoreRevision;
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
    _liveLease.cancel();
    _watchSubscription?.cancel();
    _watchSubscription = null;
    super.dispose();
  }
}
