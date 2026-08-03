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
    this.isCacheHit = false,
  });

  final CurrentLedgerQueryScope scope;
  final bool isLoading;
  final DashboardLedgerResult? result;
  final Object? error;
  final bool isCacheHit;
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
         isCacheHit: false,
       );

  final DashboardLedgerRepository _repository;
  final Map<LedgerQueryKey, DashboardLedgerResult> _cache =
      <LedgerQueryKey, DashboardLedgerResult>{};
  static const _cacheCapacity = 36;
  static const _cacheRowCapacity = 1000;
  int? _knownCoreRevision;
  DashboardQueryState _state;
  int _requestGeneration = 0;
  int _prefetchCacheGeneration = 0;
  int _warmGeneration = 0;
  final Map<LedgerQueryKey, Future<DashboardLedgerResult?>>
  _inFlightFirstDayPrefetches =
      <LedgerQueryKey, Future<DashboardLedgerResult?>>{};
  StreamSubscription<DashboardLedgerResult>? _watchSubscription;
  bool _disposed = false;

  DashboardQueryState get state => _state;

  /// Reads an exact, revision-compatible first page from the existing bounded
  /// query cache without changing the committed query or starting I/O.
  ///
  /// This is the only data-cache access used by presentation-only rail
  /// previews. A cache miss is deliberately indistinguishable from absent
  /// data: callers must render scoped loading, never relabel old rows.
  DashboardLedgerResult? cachedFirstDayGroupPage(
    CurrentLedgerQueryScope scope,
  ) {
    final cached = _cache[scope.key];
    if (cached == null) return null;
    if (!_matchesKnownRevision(cached)) {
      _cache.remove(scope.key);
      return null;
    }
    _cache
      ..remove(scope.key)
      ..[scope.key] = cached;
    return cached;
  }

  void refresh({String reason = 'initial'}) {
    _cache.clear();
    _knownCoreRevision = null;
    _prefetchCacheGeneration += 1;
    _warmGeneration += 1;
    _inFlightFirstDayPrefetches.clear();
    _state = DashboardQueryState(
      scope: _state.scope,
      isLoading: true,
      result: _state.result,
      error: null,
      isCacheHit: false,
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

  /// Warm exactly one complete, data-only LogBox first page for a known final
  /// target. Preview ticks must never call this method: it is reserved for a
  /// tap target or the shared rail physics' resolved final target.
  ///
  /// The visible query state is intentionally untouched. When that target is
  /// later committed, [_setScope] selects this same canonical result from the
  /// existing query cache instead of starting a second first-page read.
  Future<DashboardLedgerResult?> prefetchFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    String reason = 'motionTargetResolved',
  }) {
    final repository = _repository;
    if (repository is! DashboardLedgerFirstPagePrefetchRepository) {
      return Future<DashboardLedgerResult?>.value();
    }
    final prefetchRepository =
        repository as DashboardLedgerFirstPagePrefetchRepository;
    final cached = cachedFirstDayGroupPage(scope);
    if (cached != null) {
      return Future<DashboardLedgerResult?>.value(cached);
    }
    final existing = _inFlightFirstDayPrefetches[scope.key];
    if (existing != null) return existing;

    final cacheGeneration = _prefetchCacheGeneration;
    late final Future<DashboardLedgerResult?> future;
    future = _performFirstDayGroupPrefetch(
      scope: scope,
      prefetchRepository: prefetchRepository,
      cacheGeneration: cacheGeneration,
      reason: reason,
    );
    _inFlightFirstDayPrefetches[scope.key] = future;
    future.whenComplete(() {
      if (identical(_inFlightFirstDayPrefetches[scope.key], future)) {
        _inFlightFirstDayPrefetches.remove(scope.key);
      }
    });
    return future;
  }

  /// Warms a bounded collection of first pages before rail preview begins.
  ///
  /// This is intentionally data-only: it neither changes [state] nor creates
  /// a repository watch. Callers supply a finite child domain (or a bounded
  /// SUM window); each preview tick subsequently uses [cachedFirstDayGroupPage]
  /// for an O(1) lookup. Sequential dispatch keeps the Room/channel lane
  /// bounded and yields between pages instead of competing with rail physics.
  Future<void> warmFirstDayGroupPages(
    Iterable<CurrentLedgerQueryScope> scopes, {
    required String reason,
  }) async {
    final repository = _repository;
    if (repository is! DashboardLedgerFirstPagePrefetchRepository) return;
    final unique = <LedgerQueryKey, CurrentLedgerQueryScope>{};
    for (final scope in scopes) {
      unique.putIfAbsent(scope.key, () => scope);
    }
    if (unique.isEmpty) return;

    final generation = ++_warmGeneration;
    DashboardQueryDebug.mark(
      'LOG_PREVIEW_CACHE_WARM_STARTED',
      detail: 'reason=$reason scopeCount=${unique.length}',
    );
    var warmedCount = 0;
    for (final scope in unique.values) {
      if (_disposed || generation != _warmGeneration) return;
      if (cachedFirstDayGroupPage(scope) != null) continue;
      final result = await prefetchFirstDayGroupPage(
        scope,
        reason: 'previewCacheWarm:$reason',
      );
      if (result != null) warmedCount += 1;
    }
    if (_disposed || generation != _warmGeneration) return;
    DashboardQueryDebug.mark(
      'LOG_PREVIEW_CACHE_WARM_COMPLETED',
      detail:
          'reason=$reason warmedCount=$warmedCount scopeCount=${unique.length}',
    );
  }

  Future<DashboardLedgerResult?> _performFirstDayGroupPrefetch({
    required CurrentLedgerQueryScope scope,
    required DashboardLedgerFirstPagePrefetchRepository prefetchRepository,
    required int cacheGeneration,
    required String reason,
  }) async {
    final stopwatch = Stopwatch()..start();
    DashboardQueryDebug.mark(
      'LOG_PREFETCH_STARTED',
      scope: scope,
      detail: 'reason=$reason target=${scope.timeScope.canonicalKey}',
    );
    try {
      final result = await prefetchRepository.readFirstDayGroupPage(scope);
      final canonicalResult = _canonicalizeResult(scope, result);
      if (_disposed || cacheGeneration != _prefetchCacheGeneration) {
        DashboardQueryDebug.mark(
          'LOG_QUERY_DROPPED_STALE',
          scope: scope,
          result: canonicalResult,
          isStale: true,
          detail:
              'prefetchCacheGeneration=$cacheGeneration '
              'current=$_prefetchCacheGeneration',
        );
        return null;
      }
      if (canonicalResult.scopeKey != scope.key.value) {
        DashboardQueryDebug.mark(
          'LOG_QUERY_DROPPED_STALE',
          scope: scope,
          result: canonicalResult,
          isStale: true,
          detail:
              'scopeMismatch expected=${scope.key.value} actual=${canonicalResult.scopeKey}',
        );
        return null;
      }
      if (canonicalResult.coreRevision != null &&
          _knownCoreRevision != null &&
          canonicalResult.coreRevision != _knownCoreRevision) {
        _cache.clear();
      }
      _knownCoreRevision = canonicalResult.coreRevision ?? _knownCoreRevision;
      _cacheResult(scope, canonicalResult);
      stopwatch.stop();
      DashboardQueryDebug.mark(
        'LOG_PREFETCH_COMPLETED',
        scope: scope,
        result: canonicalResult,
        durationMs: stopwatch.elapsedMilliseconds,
        detail:
            'groupCount=${canonicalResult.dayGroups.length} '
            'rowCount=${canonicalResult.dayGroups.fold<int>(0, (count, group) => count + group.entries.length)}',
      );
      return canonicalResult;
    } on Object catch (error) {
      DashboardQueryDebug.mark(
        'LOG_QUERY_DROPPED_STALE',
        scope: scope,
        isStale: true,
        detail: 'prefetchError=$error',
      );
      return null;
    }
  }

  void _setScope(CurrentLedgerQueryScope nextScope, {required String reason}) {
    if (nextScope == _state.scope) return;
    final cached = _cache[nextScope.key];
    DashboardQueryDebug.mark(
      'LOG_QUERY_COMMITTED',
      scope: nextScope,
      result: cached,
      detail:
          'reason=$reason cacheHit=${cached != null && _matchesKnownRevision(cached)}',
    );
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
        isCacheHit: true,
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
      isCacheHit: false,
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
    final identityMatches =
        (result.scopeKey == null || result.scopeKey == scope.key.value) &&
        (result.timeScopeKey == null ||
            result.timeScopeKey == scope.timeScope.canonicalKey) &&
        (result.direction == null || result.direction == scope.direction.name);
    if (!identityMatches) {
      DashboardQueryDebug.mark(
        'D8 queryResultDroppedStale',
        scope: scope,
        result: result,
        flowId: result.flowId ?? DashboardQueryDebug.flowIdFor(scope),
        isStale: true,
        detail:
            'identityMismatch expectedKey=${scope.key.value} '
            'actualKey=${result.scopeKey} '
            'expectedTime=${scope.timeScope.canonicalKey} '
            'actualTime=${result.timeScopeKey} '
            'expectedDirection=${scope.direction.name} '
            'actualDirection=${result.direction}',
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
    _knownCoreRevision = canonicalResult.coreRevision ?? _knownCoreRevision;
    _cacheResult(scope, canonicalResult);
    _state = DashboardQueryState(
      scope: scope,
      isLoading: false,
      result: canonicalResult,
      error: null,
      isCacheHit: false,
    );
    DashboardQueryDebug.mark(
      'D8 currentQuerySliceAccepted',
      scope: scope,
      result: canonicalResult,
      flowId: canonicalResult.flowId ?? DashboardQueryDebug.flowIdFor(scope),
      detail: 'generation=$generation',
    );
    notifyListeners();
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
      dayGroups: result.dayGroups,
      nextCursor: result.nextCursor,
      nextDayCursor: result.nextDayCursor,
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
      isCacheHit: false,
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

  void _cacheResult(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result,
  ) {
    _cache.remove(scope.key);
    _cache[scope.key] = result;
    while (_cache.isNotEmpty &&
        (_cache.length > _cacheCapacity ||
            _cachedRowCount() > _cacheRowCapacity)) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Bounds the data cache by both scope count and decoded rows. A complete
  /// day can legitimately be dense, so the visible state may outlive this
  /// cache; only speculative/reusable data is evicted.
  int _cachedRowCount() {
    return _cache.values.fold<int>(0, (count, result) {
      if (result.dayGroups.isNotEmpty) {
        return count +
            result.dayGroups.fold<int>(
              0,
              (rowCount, group) => rowCount + group.entries.length,
            );
      }
      return count + result.entries.length;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration += 1;
    _prefetchCacheGeneration += 1;
    _warmGeneration += 1;
    _inFlightFirstDayPrefetches.clear();
    _watchSubscription?.cancel();
    _watchSubscription = null;
    super.dispose();
  }
}
