import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/dashboard_ledger_repository.dart';
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
  bool _disposed = false;

  DashboardQueryState get state => _state;

  void refresh() {
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
    unawaited(_read(_state.scope, generation));
  }

  void setTimeScope(LedgerTimeScope timeScope) {
    _setScope(_state.scope.copyWith(timeScope: timeScope));
  }

  void setDirection(LedgerDirection direction) {
    _setScope(_state.scope.copyWith(direction: direction));
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
    );
  }

  void _setScope(CurrentLedgerQueryScope nextScope) {
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
    unawaited(_read(nextScope, generation));
  }

  Future<void> _read(CurrentLedgerQueryScope scope, int generation) async {
    try {
      final result = await _repository.read(scope);
      if (_disposed || generation != _requestGeneration) return;
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
      notifyListeners();
    } on Object catch (error) {
      if (_disposed || generation != _requestGeneration) return;
      _state = DashboardQueryState(
        scope: scope,
        isLoading: false,
        result: _state.result,
        error: error,
      );
      notifyListeners();
    }
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
    super.dispose();
  }
}
