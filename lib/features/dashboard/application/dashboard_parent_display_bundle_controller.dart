import 'dart:async';

import 'package:flutter/foundation.dart';

import '../performance/dashboard_performance_trace.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../time_navigation/domain/time_plane.dart';
import 'dashboard_parent_display_bundle.dart';

/// Boundary for a single native/read-model batch that supplies a finite parent
/// preview deck. Implementations must return only after their payload is ready
/// for one atomic publication; callers never receive child-by-child updates.
abstract interface class DashboardParentDisplayBundleRepository {
  Future<DashboardParentDisplayBundlePayload> readParentDisplayBundle(
    DashboardParentDisplayBundleRequest request,
  );
}

@immutable
class DashboardParentDisplayBundleRequest {
  DashboardParentDisplayBundleRequest({
    required this.parentScope,
    required this.plane,
    required Iterable<CurrentLedgerQueryScope> expectedChildren,
  }) : expectedChildren = List<CurrentLedgerQueryScope>.unmodifiable(
         expectedChildren,
       );

  final CurrentLedgerQueryScope parentScope;
  final TimePlane plane;
  final List<CurrentLedgerQueryScope> expectedChildren;
}

/// Fully read but not yet normalized bundle content. The controller fills every
/// SQL-absent finite child with an explicit empty snapshot before publication.
@immutable
class DashboardParentDisplayBundlePayload {
  DashboardParentDisplayBundlePayload({
    required this.parentScope,
    required this.plane,
    required this.coreRevision,
    required Iterable<DashboardLogPreviewSnapshot> snapshots,
  }) : snapshots = List<DashboardLogPreviewSnapshot>.unmodifiable(snapshots);

  final CurrentLedgerQueryScope parentScope;
  final TimePlane plane;
  final int coreRevision;
  final List<DashboardLogPreviewSnapshot> snapshots;
}

/// Owns the complete active parent deck used by the rail preview hot path.
///
/// This controller is intentionally separate from [CurrentQueryController]: it
/// owns display-ready finite bundles, while the query controller continues to
/// own committed watches and paging. A current bundle is pinned as one LRU
/// unit, therefore no active child can be evicted independently.
class DashboardParentDisplayBundleController extends ChangeNotifier {
  DashboardParentDisplayBundleController({
    required DashboardParentDisplayBundleRepository repository,
    int cacheCapacity = 4,
  }) : _repository = repository,
       _cache = DashboardParentDisplayBundleCache(capacity: cacheCapacity);

  final DashboardParentDisplayBundleRepository _repository;
  final DashboardParentDisplayBundleCache _cache;
  final Map<String, Future<DashboardParentDisplayBundle>> _loads =
      <String, Future<DashboardParentDisplayBundle>>{};
  final Map<String, DashboardParentDisplayBundle> _preparedByIdentity =
      <String, DashboardParentDisplayBundle>{};

  DashboardParentDisplayBundle? _currentBundle;

  DashboardParentDisplayBundle? get currentBundle => _currentBundle;

  /// Loads, validates, completes and publishes one finite deck atomically.
  /// Concurrent requests for the same parent/plane share the in-flight work.
  Future<DashboardParentDisplayBundle> ensureFiniteBundle({
    required CurrentLedgerQueryScope parentScope,
    required TimePlane plane,
    required Iterable<CurrentLedgerQueryScope> expectedChildren,
  }) {
    final frozenChildren = List<CurrentLedgerQueryScope>.unmodifiable(
      expectedChildren,
    );
    final childCoverageKey = DashboardParentDisplayBundle.coverageKeyFor(
      frozenChildren,
    );
    final current = _currentBundle;
    if (current != null &&
        current.key.parentQueryKey == parentScope.key.value &&
        current.key.plane == plane &&
        current.key.childCoverageKey == childCoverageKey &&
        current.isComplete) {
      return SynchronousFuture<DashboardParentDisplayBundle>(current);
    }
    return prewarmFiniteBundle(
      parentScope: parentScope,
      plane: plane,
      expectedChildren: frozenChildren,
    ).then((bundle) {
      activatePreparedBundle(bundle);
      return bundle;
    });
  }

  /// Loads and validates a complete deck but deliberately keeps the visible
  /// parent unchanged. The core uses it for previous/next prewarm so an
  /// unfinished horizontal target cannot relabel the old amount or LogBox.
  Future<DashboardParentDisplayBundle> prewarmFiniteBundle({
    required CurrentLedgerQueryScope parentScope,
    required TimePlane plane,
    required Iterable<CurrentLedgerQueryScope> expectedChildren,
  }) {
    final frozenChildren = List<CurrentLedgerQueryScope>.unmodifiable(
      expectedChildren,
    );
    final childCoverageKey = DashboardParentDisplayBundle.coverageKeyFor(
      frozenChildren,
    );
    final identity = _loadIdentity(parentScope, plane, childCoverageKey);
    _traceDeckLookup(
      parentScope: parentScope,
      plane: plane,
      expectedChildCount: frozenChildren.length,
      event: plane == TimePlane.sum
          ? 'YEAR_COVERAGE_LOOKUP'
          : 'DISPLAY_DECK_LOOKUP',
      cache: 'begin',
    );
    final current = _currentBundle;
    if (current != null &&
        current.key.parentQueryKey == parentScope.key.value &&
        current.key.plane == plane &&
        current.key.childCoverageKey == childCoverageKey &&
        current.isComplete) {
      _traceDeckLookup(
        parentScope: parentScope,
        plane: plane,
        expectedChildCount: frozenChildren.length,
        event: 'DISPLAY_DECK_LOOKUP',
        cache: 'active',
      );
      return SynchronousFuture<DashboardParentDisplayBundle>(current);
    }
    final prepared = _preparedByIdentity[identity];
    if (prepared != null && _cache.contains(prepared.key)) {
      _cache.lookup(prepared.key);
      _traceDeckLookup(
        parentScope: parentScope,
        plane: plane,
        expectedChildCount: frozenChildren.length,
        event: 'DISPLAY_DECK_LOOKUP',
        cache: 'prepared',
      );
      return SynchronousFuture<DashboardParentDisplayBundle>(prepared);
    }
    _preparedByIdentity.remove(identity);
    final pending = _loads[identity];
    if (pending != null) {
      _traceDeckLookup(
        parentScope: parentScope,
        plane: plane,
        expectedChildCount: frozenChildren.length,
        event: 'DISPLAY_DECK_LOOKUP',
        cache: 'loading',
      );
      return pending;
    }

    _traceDeckLookup(
      parentScope: parentScope,
      plane: plane,
      expectedChildCount: frozenChildren.length,
      event: 'DISPLAY_DECK_PREWARM_REQUESTED',
      cache: 'miss',
    );
    final stopwatch = DashboardQueryDebug.isEnabled
        ? (Stopwatch()..start())
        : null;

    final load = _readCompleteAndCache(
      DashboardParentDisplayBundleRequest(
        parentScope: parentScope,
        plane: plane,
        expectedChildren: frozenChildren,
      ),
    );
    final tracedLoad = load.then((bundle) {
      if (DashboardQueryDebug.isEnabled) {
        DashboardQueryDebug.mark(
          'DISPLAY_DECK_PREWARM_READY',
          scope: parentScope,
          coreRevision: bundle.key.coreRevision,
          detail:
              'plane=${plane.name} cache=miss children=${frozenChildren.length} '
              'durationMs=${stopwatch?.elapsedMilliseconds ?? 0}',
        );
      }
      return bundle;
    });
    _loads[identity] = tracedLoad;
    return tracedLoad.whenComplete(() => _loads.remove(identity));
  }

  void _traceDeckLookup({
    required CurrentLedgerQueryScope parentScope,
    required TimePlane plane,
    required int expectedChildCount,
    required String event,
    required String cache,
  }) {
    if (!DashboardQueryDebug.isEnabled) return;
    DashboardQueryDebug.mark(
      event,
      scope: parentScope,
      detail: 'plane=${plane.name} cache=$cache children=$expectedChildCount',
    );
  }

  /// Makes an already complete deck visible. Passing `notify: false` is used
  /// only by the core's parent commit: it first changes this selection, then
  /// publishes the matching navigation state in the same synchronous turn.
  /// Navigation listeners are therefore the single visible update boundary.
  void activatePreparedBundle(
    DashboardParentDisplayBundle bundle, {
    bool notify = true,
  }) {
    if (!bundle.isComplete) {
      throw ArgumentError.value(
        bundle,
        'bundle',
        'Only complete decks activate.',
      );
    }
    final previous = _currentBundle;
    if (previous?.key == bundle.key) return;
    // Pin before insertion so capacity-one caches cannot evict the new active
    // deck between prewarm and activation.
    _cache.pin(bundle.key);
    _cache.put(bundle);
    _currentBundle = bundle;
    if (previous != null) _cache.unpin(previous.key);
    if (notify) notifyListeners();
  }

  /// Strictly synchronous O(1) lookup for a rail index crossing.
  DashboardLogPreviewSnapshot? previewFor(CurrentLedgerQueryScope childScope) {
    final bundle = _currentBundle;
    if (bundle == null || !bundle.isComplete) return null;
    return bundle.childDeck.snapshotFor(childScope);
  }

  bool canServeFinitePreview(CurrentLedgerQueryScope childScope) =>
      previewFor(childScope) != null;

  /// True from dispatch until the requested complete deck is retired. This is
  /// used to keep the legacy item-level warmer from racing a parent batch.
  bool isFiniteBundleActiveOrLoading({
    required CurrentLedgerQueryScope parentScope,
    required TimePlane plane,
  }) {
    final current = _currentBundle;
    final prefix = '${parentScope.key.value}|plane:${plane.name}|coverage:';
    return _loads.keys.any((identity) => identity.startsWith(prefix)) ||
        _preparedByIdentity.keys.any(
          (identity) => identity.startsWith(prefix),
        ) ||
        (current != null &&
            current.isComplete &&
            current.key.parentQueryKey == parentScope.key.value &&
            current.key.plane == plane);
  }

  /// Finite active decks must never start a target-resolution prefetch.
  bool shouldFallbackToMotionTargetPrefetch(
    CurrentLedgerQueryScope childScope,
  ) => !canServeFinitePreview(childScope);

  Future<DashboardParentDisplayBundle> _readCompleteAndCache(
    DashboardParentDisplayBundleRequest request,
  ) async {
    final payload = await _repository.readParentDisplayBundle(request);
    if (payload.parentScope != request.parentScope ||
        payload.plane != request.plane) {
      throw StateError(
        'Parent display bundle response does not match request.',
      );
    }
    final bundle = DashboardParentDisplayBundle.completeFinite(
      parentScope: payload.parentScope,
      plane: payload.plane,
      coreRevision: payload.coreRevision,
      expectedChildren: request.expectedChildren,
      snapshots: payload.snapshots,
    );
    _cache.put(bundle);
    _preparedByIdentity[_loadIdentity(
          payload.parentScope,
          payload.plane,
          bundle.key.childCoverageKey,
        )] =
        bundle;
    _preparedByIdentity.removeWhere(
      (_, candidate) =>
          candidate.key != _currentBundle?.key &&
          !_cache.contains(candidate.key),
    );
    DashboardPerformanceTrace.record(
      DashboardPerformanceTraceKind.parentBundleReady,
      valueA: bundle.childDeck.snapshots.length,
      valueB: bundle.key.coreRevision,
    );
    return bundle;
  }

  String _loadIdentity(
    CurrentLedgerQueryScope parentScope,
    TimePlane plane,
    String childCoverageKey,
  ) =>
      '${parentScope.key.value}|plane:${plane.name}|coverage:$childCoverageKey';

  @override
  void dispose() {
    _loads.clear();
    _preparedByIdentity.clear();
    super.dispose();
  }
}
