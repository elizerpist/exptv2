import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/dashboard_ledger_repository.dart';
import 'dashboard_query_debug.dart';
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
  }) : _repository = repository,
       _state = DashboardQueryState(
         scope: initialScope,
         isLoading: false,
         result: null,
         error: null,
       );

  final DashboardLedgerRepository _repository;
  final _cache = <LedgerQueryKey, DashboardLedgerResult>{};
  static const _cacheCapacity = 36;
  int? _knownCoreRevision;
  DashboardQueryState _state;
  int _requestGeneration = 0;
  StreamSubscription<DashboardLedgerResult>? _watchSubscription;
  bool _disposed = false;

  DashboardQueryState get state => _state;

  void refresh({String reason = 'initial'}) {
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
      _watchSubscription?.cancel();
      _watchSubscription = null;
      ++_requestGeneration;
      _cache.remove(nextScope.key);
      _cache[nextScope.key] = cached;
      _state = DashboardQueryState(
        scope: nextScope,
        isLoading: false,
        result: cached,
        error: null,
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
    _startWatching(nextScope, generation, reason: reason);
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
    if (_disposed || generation != _requestGeneration) {
      DashboardQueryDebug.mark(
        'D8 queryResultDroppedStale',
        scope: scope,
        result: result,
        flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail: 'generation=$generation current=$_requestGeneration',
      );
      return;
    }
    if (result.coreRevision != null &&
        _knownCoreRevision != null &&
        result.coreRevision != _knownCoreRevision) {
      _cache.clear();
    }
    _knownCoreRevision = result.coreRevision ?? _knownCoreRevision;
    _cache[scope.key] = result;
    while (_cache.length > _cacheCapacity) {
      _cache.remove(_cache.keys.first);
    }
    _state = DashboardQueryState(
      scope: scope,
      isLoading: false,
      result: result,
      error: null,
    );
    DashboardQueryDebug.mark(
      'D8 currentQuerySliceAccepted',
      scope: scope,
      result: result,
      flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation',
    );
    notifyListeners();
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

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration += 1;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    super.dispose();
  }
}
