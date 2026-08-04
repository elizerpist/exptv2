import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'dashboard_parent_bundle_registry.dart';
import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_parent_display_bundle.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/application/dashboard_presentation_diagnostics.dart';
import '../query/application/dashboard_presentation_store.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../query/data/dashboard_child_preview_bundle.dart';
import '../query/data/dashboard_child_preview_repository.dart';
import '../query/data/dashboard_ledger_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/scope_summary_metrics.dart';
import '../query/domain/time_child_summary.dart';
import '../query/domain/dashboard_visible_presentation_target.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/summary_metrics_presentation.dart';

/// The single presentation owner for the SummaryPill amount and LogBox count.
///
/// A displayed child uses a bounded grouped summary index. The detailed query
/// remains owned by [CurrentQueryController] and is never started by a preview
/// lookup. No value from a retained detailed result may be relabelled as a
/// different displayed scope.
class DashboardSummaryMetricsController extends ChangeNotifier {
  DashboardSummaryMetricsController({
    required DashboardTimeNavigationController navigation,
    required CurrentQueryController query,
    DashboardChildSummaryRepository? childSummaryRepository,
    DashboardChildPreviewRepository? childPreviewRepository,
    DashboardPresentationStore? presentationStore,
    DashboardPresentationDiagnostics? diagnostics,
    DashboardParentBundleRegistry? parentBundleRegistry,
    bool seedReady = true,
  }) : _navigation = navigation,
       _query = query,
       _childSummaryRepository = childSummaryRepository,
       _childPreviewRepository = childPreviewRepository,
       _presentationStore = presentationStore,
       _diagnostics = diagnostics,
       _parentBundleRegistry =
           parentBundleRegistry ?? DashboardParentBundleRegistry(),
       _seedReady = seedReady,
       _presentation = SummaryMetricsPresentation.fromMetrics(
         _loadingMetricsForScope(
           query.state.scope,
           isStale: false,
           hasError: false,
         ),
       ) {
    _navigation.addListener(_handleNavigationChanged);
    _query.addListener(_handleQueryChanged);
    _synchronize();
  }

  static const _cacheCapacity = 30;

  final DashboardTimeNavigationController _navigation;
  final CurrentQueryController _query;
  final DashboardChildSummaryRepository? _childSummaryRepository;
  final DashboardChildPreviewRepository? _childPreviewRepository;
  final DashboardPresentationStore? _presentationStore;
  final DashboardPresentationDiagnostics? _diagnostics;
  final DashboardParentBundleRegistry _parentBundleRegistry;
  final LinkedHashMap<String, DashboardTimeChildSummaryIndex> _cache =
      LinkedHashMap<String, DashboardTimeChildSummaryIndex>();

  DashboardTimeChildSummaryIndex? _index;
  String? _activeParentQueryKey;
  String? _inFlightCacheKey;
  final Set<String> _inFlightBundleKeys = <String>{};
  final Map<String, Future<DashboardParentBundleEntry?>> _bundleLoads =
      <String, Future<DashboardParentBundleEntry?>>{};
  final Map<String, DashboardChildPreviewBundle> _pendingBundleAssembly =
      <String, DashboardChildPreviewBundle>{};
  int _requestGeneration = 0;
  int _presentationGeneration = 0;
  int _presentationEpoch = 0;
  String? _lastVisibleTargetSignature;
  bool _disposed = false;
  bool _seedReady;
  DashboardChildPreviewBundle? _activeBundle;
  int _childPreviewCacheHitCount = 0;
  int _childPreviewCacheMissCount = 0;
  int _childPreviewRepositoryReadCount = 0;
  int _childPreviewVisiblePublishCount = 0;
  int _firstOpenCacheHitCount = 0;
  int _firstOpenCacheMissCount = 0;
  int _lastCountedRailOpenRevision = -1;
  Completer<void>? _bundleReadinessCompleter;
  String? _bundleReadinessKey;
  ScopeSummaryMetrics? _metrics;
  SummaryMetricsPresentation _presentation;

  SummaryMetricsPresentation get presentation => _presentation;
  ScopeSummaryMetrics? get metrics => _metrics;
  DashboardTimeChildSummaryIndex? get index => _index;
  String? get activeParentQueryKey => _activeParentQueryKey;

  DashboardPresentationStore? get presentationStore => _presentationStore;
  int get childPreviewCacheHitCount => _childPreviewCacheHitCount;
  int get childPreviewCacheMissCount => _childPreviewCacheMissCount;
  int get childPreviewRepositoryReadCount => _childPreviewRepositoryReadCount;
  int get childPreviewVisiblePublishCount => _childPreviewVisiblePublishCount;
  int get firstOpenCacheHitCount => _firstOpenCacheHitCount;
  int get firstOpenCacheMissCount => _firstOpenCacheMissCount;
  DashboardPresentationDiagnostics? get diagnostics => _diagnostics;
  DashboardParentBundleRegistry get parentBundleRegistry =>
      _parentBundleRegistry;
  int get childPreviewCacheEstimatedRows =>
      _parentBundleRegistry.estimatedWeight;
  int get childPreviewCacheEstimatedBytes =>
      _parentBundleRegistry.estimatedBytes;
  int get childPreviewCacheEvictionCount => _parentBundleRegistry.evictionCount;
  bool get isSeedReady => _seedReady;

  /// Releases the seed gate after the native seed transaction has committed.
  /// Any accidental pre-seed projection is discarded before the first
  /// authoritative bundle can be registered.
  void markSeedCommitted() {
    if (_disposed || _seedReady) return;
    _seedReady = true;
    _cache.clear();
    _parentBundleRegistry.clear();
    _pendingBundleAssembly.clear();
    _index = null;
    _activeBundle = null;
    _activeParentQueryKey = null;
  }

  /// Prepares the current parent summary and its child preview payload as one
  /// readiness boundary for dashboard bootstrap.
  Future<DashboardParentDisplayBundle>
  prepareCurrentParentDisplayBundle() async {
    final navigation = _navigation.state;
    final parentScope = _query.state.scope.copyWith(
      timeScope: navigation.parentScope,
    );
    final bundle = await prepareParentDisplayBundle(
      parentScope: parentScope,
      childPeriod: _childPeriodFor(navigation),
      source: 'bootstrap',
      pinCurrent: true,
    );
    if (bundle == null || !bundle.isComplete) {
      throw StateError('Current parent display bundle is incomplete.');
    }
    return bundle;
  }

  /// Prepares a parent without changing the visible navigation or current
  /// query. The caller commits the scope only after this future completes.
  Future<DashboardParentDisplayBundle?> prepareParentDisplayBundle({
    required CurrentLedgerQueryScope parentScope,
    required TimeChildPeriod childPeriod,
    String source = 'parentPrewarm',
    bool pinCurrent = false,
  }) async {
    if (!_seedReady) return null;
    final request = DashboardChildSummaryRequest(
      parentScope: parentScope,
      childPeriod: childPeriod,
    );
    final cached = _lookupParentBundle(request, emitDiagnostic: true);
    if (cached != null) {
      if (pinCurrent) _parentBundleRegistry.pinCurrent(cached.key);
      return cached.displayBundle;
    }
    final result = await _query.prewarm(parentScope, reason: source);
    if (_disposed || result == null) return null;
    final parentSnapshot = DashboardPresentationSnapshot.fromResult(
      scope: parentScope,
      generation: _presentationGeneration,
      result: result,
    );
    DashboardChildPreviewBundle? childPreviewBundle;
    if (_childPreviewRepository != null) {
      final entry = await _loadBundleForRequest(
        request,
        source: source,
        parentSnapshot: parentSnapshot,
        pinCurrent: pinCurrent,
      );
      if (_disposed || entry == null) return null;
      final displayBundle = entry.displayBundle;
      DashboardQueryDebug.mark(
        'DASHBOARD_BUNDLE_READY',
        scope: parentScope,
        result: result,
        detail:
            'childCount=${displayBundle.childPreviewBundle?.childrenByQueryKey.length ?? 0} '
            'startup=${source == "bootstrap"} complete=${displayBundle.isComplete}',
      );
      return displayBundle;
    }
    final displayBundle = DashboardParentDisplayBundle(
      parentSnapshot: parentSnapshot,
      childPreviewBundle: childPreviewBundle,
    );
    DashboardQueryDebug.mark(
      'DASHBOARD_BUNDLE_READY',
      scope: parentScope,
      result: result,
      detail:
          'childCount=${childPreviewBundle?.childrenByQueryKey.length ?? 0} '
          'startup=${source == "bootstrap"} complete=${displayBundle.isComplete}',
    );
    return displayBundle;
  }

  /// Returns whether the exact parent and its complete child deck are already
  /// resident. This is a read-only gate for the atomic open-rail transition;
  /// it never starts a repository request.
  bool hasCompleteParentDisplayBundle({
    required CurrentLedgerQueryScope parentScope,
    required TimeChildPeriod childPeriod,
  }) {
    if (!_seedReady) return false;
    final request = DashboardChildSummaryRequest(
      parentScope: parentScope,
      childPeriod: childPeriod,
    );
    if (_childPreviewRepository != null) {
      return _lookupParentBundle(request, emitDiagnostic: true) != null;
    }
    final parentSnapshot = _presentationStore?.peekSnapshot(parentScope.key);
    return parentSnapshot != null &&
        parentSnapshot.hasValue &&
        !parentSnapshot.isLoading &&
        !parentSnapshot.isStale &&
        !parentSnapshot.hasError &&
        parentSnapshot.scope?.key == parentScope.key;
  }

  /// Waits for the current parent child-preview bundle when the repository
  /// supports one. Empty/web repositories have no bundle lane and are already
  /// ready after the critical parent snapshot.
  Future<void> waitForCurrentParentPreview() {
    if (_childPreviewRepository == null) return Future<void>.value();
    final request = _requestFor(_navigation.state);
    if (_lookupParentBundle(request) != null) return Future<void>.value();
    if (_bundleReadinessKey != request.cacheKey ||
        _bundleReadinessCompleter == null ||
        _bundleReadinessCompleter!.isCompleted) {
      _bundleReadinessKey = request.cacheKey;
      _bundleReadinessCompleter = Completer<void>();
    }
    _synchronize();
    return _bundleReadinessCompleter!.future;
  }

  /// Selects a cached parent presentation without changing the committed
  /// navigation or query scope. This is the parent equivalent of the child
  /// preview lane: the target must already be present in the central store,
  /// otherwise the outgoing snapshot remains visible and no placeholder is
  /// published.
  bool previewParent(
    DashboardTimeNavigationState candidate, {
    required int presentationEpoch,
  }) {
    if (_disposed || !_seedReady) return false;
    final store = _presentationStore;
    if (store == null) return false;
    final displayedScope = _displayedScopeFor(candidate);
    final target = _visibleTargetFor(
      candidate,
      presentationEpoch: presentationEpoch,
    );
    final cached = store.peekSnapshot(target.expectedVisibleQueryKey);
    if (cached == null ||
        !cached.hasValue ||
        cached.isLoading ||
        cached.isStale ||
        cached.hasError ||
        cached.scope?.key != displayedScope.key) {
      // Keep the old target and active snapshot together on a cold parent
      // miss. The caller can prepare the target asynchronously and publish it
      // atomically later; the SummaryPill never gets a new label plus a dash.
      final outgoing = store.activeSnapshot;
      if (outgoing != null &&
          outgoing.hasValue &&
          !outgoing.isLoading &&
          !outgoing.isStale &&
          !outgoing.hasError &&
          (_presentation.totalMinor == null ||
              _presentation.entryCount == null)) {
        final outgoingScope = outgoing.scope;
        if (outgoingScope != null) {
          final stableMetrics = ScopeSummaryMetrics(
            scope: outgoingScope,
            canonicalQueryKey: outgoing.queryKey.value,
            coreRevision: outgoing.coreRevision,
            totalMinor: outgoing.totalMinor,
            entryCount: outgoing.entryCount,
            source: SummaryMetricsSource.parentSummary,
            isLoading: false,
            isStale: false,
            hasError: false,
          );
          _metrics = stableMetrics;
          _presentation = SummaryMetricsPresentation.fromMetrics(
            stableMetrics,
            presentationEpoch: presentationEpoch,
          );
        }
      }
      return false;
    }

    _presentationEpoch = presentationEpoch;
    store.setVisibleTarget(target);
    final previous = _metrics;
    final next = ScopeSummaryMetrics(
      scope: displayedScope,
      canonicalQueryKey: displayedScope.key.value,
      coreRevision: cached.coreRevision,
      totalMinor: cached.totalMinor,
      entryCount: cached.entryCount,
      source: SummaryMetricsSource.parentPreview,
      isLoading: false,
      isStale: false,
      hasError: false,
    );
    _metrics = next;
    _presentation = SummaryMetricsPresentation.fromMetrics(
      next,
      presentationEpoch: presentationEpoch,
    );
    _presentationGeneration += 1;
    _publishToPresentationStore(next, previous: previous);
    final diagnostics = _diagnostics;
    if (diagnostics != null) {
      final previewAmount = cached.totalMinor == null ? 0 : cached.totalMinor!;
      final previewEntryCount = cached.entryCount == null
          ? 0
          : cached.entryCount!;
      diagnostics.recordParentPreviewSnapshotSelected(
        interactionEpoch: presentationEpoch,
        presentationGeneration: _presentationGeneration,
        queryKey: cached.queryKey,
        amount: previewAmount,
        entryCount: previewEntryCount,
        logGroupCount: cached.logGroupCount,
        logRowCount: cached.entries.length,
        contentDigest: cached.contentDigest,
        dataOrigin: cached.dataOrigin,
        cacheHit: true,
      );
      diagnostics.recordParentPreviewPresentationPublished(
        interactionEpoch: presentationEpoch,
        presentationGeneration: _presentationGeneration,
        queryKey: cached.queryKey,
        amount: previewAmount,
        entryCount: previewEntryCount,
        logDigest: cached.contentDigest,
      );
    }
    notifyListeners();
    return store.activeSnapshot?.queryKey == target.expectedVisibleQueryKey;
  }

  void _handleNavigationChanged() => _synchronize();

  void _handleQueryChanged() => _synchronize();

  void _synchronize() {
    if (_disposed || !_seedReady) return;
    final navigation = _navigation.state;
    _synchronizeVisibleTarget(navigation);
    final displayedScope = _displayedScopeFor(navigation);
    if (!navigation.isRailOpen ||
        (_childSummaryRepository == null && _childPreviewRepository == null)) {
      _index = null;
      _activeParentQueryKey = null;
      _activeBundle = null;
      _publish(_parentMetricsFor(displayedScope));
      _prewarmChildPreviewIfReady(navigation);
      return;
    }

    final request = _requestFor(navigation);
    final cacheKey = request.cacheKey;
    _activeParentQueryKey = request.parentScope.key.value;
    final parentBundle = _lookupParentBundle(request);
    final bundle = parentBundle?.displayBundle.childPreviewBundle;
    if (navigation.lastChange.kind == DashboardTimeNavigationChangeKind.rail &&
        navigation.lastChange.direction ==
            DashboardTimeNavigationChangeDirection.forward &&
        navigation.navigationRevision != _lastCountedRailOpenRevision) {
      _lastCountedRailOpenRevision = navigation.navigationRevision;
      if (_isCompatibleBundle(bundle, request)) {
        _firstOpenCacheHitCount += 1;
      } else {
        _firstOpenCacheMissCount += 1;
      }
    }
    if (_isCompatibleBundle(bundle, request)) {
      _activeBundle = bundle;
      _childPreviewCacheHitCount += 1;
    } else {
      _activeBundle = null;
      _childPreviewCacheMissCount += 1;
    }
    final cached = parentBundle?.childSummaryIndex ?? _cache[cacheKey];
    if (_isCompatible(cached, request)) {
      if (parentBundle == null) {
        _cache
          ..remove(cacheKey)
          ..[cacheKey] = cached!;
      }
      _index = cached;
      _publish(_childMetricsFor(navigation, cached!));
      return;
    }

    // A prepared bundle is the first-open presentation lane. While its
    // parent read is completing, keep the complete outgoing snapshot visible
    // instead of publishing a child loading/dash placeholder.
    if (_childPreviewRepository != null &&
        _inFlightBundleKeys.contains(request.cacheKey)) {
      return;
    }

    _index = null;
    _publish(
      _loadingMetricsForScope(
        displayedScope,
        isStale: _query.state.result != null,
        hasError: false,
      ),
    );
    if (_inFlightCacheKey == cacheKey) return;
    if (_childPreviewRepository == null) {
      _load(request, source: 'rail');
    }
  }

  /// Establishes the semantic visible owner before any metrics source is
  /// allowed to publish. This is deliberately synchronous: a cached parent
  /// or child snapshot must win the same navigation turn, while query/watch
  /// activation remains a background concern owned by CurrentQueryController.
  void _synchronizeVisibleTarget(DashboardTimeNavigationState navigation) {
    _synchronizeVisibleTargetAtEpoch(
      navigation,
      presentationEpoch: _presentationEpoch,
    );
  }

  DashboardVisiblePresentationTarget _visibleTargetFor(
    DashboardTimeNavigationState navigation, {
    required int presentationEpoch,
  }) {
    final parentScope = _query.state.scope.copyWith(
      timeScope: navigation.parentScope,
    );
    final childScope = navigation.isRailOpen
        ? _displayedScopeFor(navigation)
        : null;
    return DashboardVisiblePresentationTarget(
      plane: navigation.plane,
      parentQueryKey: parentScope.key,
      childQueryKey: childScope?.key,
      railOpen: navigation.isRailOpen,
      direction: parentScope.direction,
      presentationEpoch: presentationEpoch,
    );
  }

  void _synchronizeVisibleTargetAtEpoch(
    DashboardTimeNavigationState navigation, {
    required int presentationEpoch,
  }) {
    final store = _presentationStore;
    if (store == null) return;
    final signature = <Object?>[
      navigation.plane,
      navigation.parentScope,
      navigation.isRailOpen ? _displayedScopeFor(navigation).key : null,
      navigation.isRailOpen,
      _query.state.scope.direction,
    ].join('|');
    if (signature != _lastVisibleTargetSignature) {
      _lastVisibleTargetSignature = signature;
      _presentationEpoch += 1;
    }
    store.setVisibleTarget(
      _visibleTargetFor(
        navigation,
        presentationEpoch: presentationEpoch == _presentationEpoch
            ? presentationEpoch
            : _presentationEpoch,
      ),
    );
  }

  /// Prewarms from the exact parent scope as early as possible. The batch
  /// payload may run alongside the parent detail read, which removes the
  /// first-open race without ever starting work from a preview crossing.
  void _prewarmChildPreviewIfReady(DashboardTimeNavigationState navigation) {
    final repository = _childSummaryRepository;
    final previewRepository = _childPreviewRepository;
    final queryState = _query.state;
    if ((repository == null && previewRepository == null) ||
        queryState.error != null) {
      return;
    }
    final request = _requestFor(navigation);
    if (queryState.scope != request.parentScope) {
      return;
    }
    if (previewRepository != null) {
      if (_lookupParentBundle(request) != null ||
          _inFlightBundleKeys.contains(request.cacheKey)) {
        return;
      }
      final result = queryState.result;
      final hasExactParent =
          !queryState.isLoading &&
          result != null &&
          result.scopeKey == request.parentScope.key.value;
      if (!hasExactParent &&
          _pendingBundleAssembly.containsKey(request.cacheKey)) {
        return;
      }
      final parentSnapshot = hasExactParent
          ? DashboardPresentationSnapshot.fromResult(
              scope: request.parentScope,
              generation: _presentationGeneration,
              result: result,
            )
          : null;
      _loadBundle(request, source: 'prewarm', parentSnapshot: parentSnapshot);
      return;
    }
    final result = queryState.result;
    if (queryState.isLoading || result == null) {
      return;
    }
    if (result.scopeKey != request.parentScope.key.value) {
      return;
    }
    final cached = _cache[request.cacheKey];
    if (_isCompatible(cached, request) ||
        _inFlightCacheKey == request.cacheKey) {
      return;
    }
    _load(request, source: 'prewarm');
  }

  DashboardChildSummaryRequest _requestFor(
    DashboardTimeNavigationState navigation,
  ) {
    final parentScope = _query.state.scope.copyWith(
      timeScope: navigation.parentScope,
    );
    return DashboardChildSummaryRequest(
      parentScope: parentScope,
      childPeriod: _childPeriodFor(navigation),
    );
  }

  TimeChildPeriod _childPeriodFor(DashboardTimeNavigationState navigation) =>
      switch (navigation.plane) {
        TimePlane.sum => TimeChildPeriod.year,
        TimePlane.year => TimeChildPeriod.month,
        TimePlane.month => TimeChildPeriod.day,
      };

  DashboardParentBundleKey _parentBundleKey(
    DashboardChildSummaryRequest request,
  ) => DashboardParentBundleKey(
    parentQueryKey: request.parentScope.key,
    childPeriod: request.childPeriod,
    previewPageSize: DashboardPreviewBudget.defaultRowBudget,
  );

  DashboardParentBundleEntry? _lookupParentBundle(
    DashboardChildSummaryRequest request, {
    bool emitDiagnostic = false,
  }) {
    final key = _parentBundleKey(request);
    final expectedRevision = _query.state.result?.coreRevision;
    final lookup = _parentBundleRegistry.lookup(
      key,
      expectedRevision: expectedRevision,
    );
    if (emitDiagnostic) {
      DashboardQueryDebug.mark(
        'BUNDLE_CACHE_LOOKUP',
        scope: request.parentScope,
        coreRevision: lookup.storedRevision,
        detail:
            'requestedBundleKey=$key normalizedBundleKey=$key '
            'found=${lookup.cacheHit} '
            'complete=${lookup.entry?.isComplete ?? false} '
            'storedRevision=${lookup.storedRevision} '
            'requestedRevision=$expectedRevision '
            'directionMatch=true filtersMatch=true childKindMatch=true '
            'missReason=${lookup.missReason.name}',
      );
    }
    return lookup.entry;
  }

  bool pinParentBundle({
    required CurrentLedgerQueryScope parentScope,
    required TimeChildPeriod childPeriod,
  }) => _parentBundleRegistry.pinCurrent(
    _parentBundleKey(
      DashboardChildSummaryRequest(
        parentScope: parentScope,
        childPeriod: childPeriod,
      ),
    ),
  );

  bool _isCompatible(
    DashboardTimeChildSummaryIndex? candidate,
    DashboardChildSummaryRequest request,
  ) {
    if (candidate == null ||
        !candidate.isComplete ||
        candidate.parentQueryKey != request.parentScope.key.value ||
        candidate.direction != request.parentScope.direction ||
        candidate.childPeriod != request.childPeriod) {
      return false;
    }
    final knownRevision = _query.state.result?.coreRevision;
    return knownRevision == null || candidate.coreRevision == knownRevision;
  }

  bool _isCompatibleBundle(
    DashboardChildPreviewBundle? candidate,
    DashboardChildSummaryRequest request,
  ) {
    if (candidate == null ||
        candidate.parentQueryKey != request.parentScope.key ||
        candidate.direction != request.parentScope.direction ||
        candidate.childPeriod != request.childPeriod) {
      return false;
    }
    final knownRevision = _query.state.result?.coreRevision;
    return knownRevision == null || candidate.coreRevision == knownRevision;
  }

  void _loadBundle(
    DashboardChildSummaryRequest request, {
    required String source,
    DashboardPresentationSnapshot? parentSnapshot,
  }) {
    final cacheKey = request.cacheKey;
    if (_childPreviewRepository == null) return;
    _inFlightBundleKeys.add(cacheKey);
    _loadBundleForRequest(
      request,
      source: source,
      parentSnapshot: parentSnapshot,
    ).then(
      (entry) {
        _inFlightBundleKeys.remove(cacheKey);
        if (_disposed || entry == null) return;
        final currentRequest = _requestFor(_navigation.state);
        if (currentRequest.cacheKey == cacheKey) {
          _activeBundle = entry.displayBundle.childPreviewBundle;
          _index = entry.childSummaryIndex;
          _synchronize();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _inFlightBundleKeys.remove(cacheKey);
        if (_disposed) return;
        if (_bundleReadinessKey == cacheKey &&
            !(_bundleReadinessCompleter?.isCompleted ?? true)) {
          _bundleReadinessCompleter!.completeError(error, stackTrace);
        }
        DashboardQueryDebug.mark(
          'I1 CHILD_PREVIEW_BUNDLE_FAILED',
          scope: request.parentScope,
          isStale: true,
          detail: 'source=$source error=$error',
        );
      },
    );
  }

  Future<DashboardParentBundleEntry?> _loadBundleForRequest(
    DashboardChildSummaryRequest request, {
    required String source,
    DashboardPresentationSnapshot? parentSnapshot,
    bool pinCurrent = false,
  }) {
    if (!_seedReady) return Future<DashboardParentBundleEntry?>.value();
    final cacheKey = request.cacheKey;
    final cached = _lookupParentBundle(request);
    if (cached != null) {
      if (pinCurrent) _parentBundleRegistry.pinCurrent(cached.key);
      return Future<DashboardParentBundleEntry?>.value(cached);
    }
    final pendingBundle = _pendingBundleAssembly.remove(cacheKey);
    if (pendingBundle != null) {
      if (parentSnapshot == null) {
        _pendingBundleAssembly[cacheKey] = pendingBundle;
        return Future<DashboardParentBundleEntry?>.value();
      }
      return Future<DashboardParentBundleEntry?>.value(
        _registerCompleteParentBundle(
          request: request,
          bundle: pendingBundle,
          parentSnapshot: parentSnapshot,
          generation: _requestGeneration,
          pinCurrent: pinCurrent,
        ),
      );
    }
    final existing = _bundleLoads[cacheKey];
    if (existing != null) return existing;
    final repository = _childPreviewRepository;
    if (repository == null) return Future<DashboardParentBundleEntry?>.value();
    final generation = ++_requestGeneration;
    final bundleRequest = DashboardChildPreviewBundleRequest(
      parentScope: request.parentScope,
      childPeriod: request.childPeriod,
    );
    _childPreviewRepositoryReadCount += 1;
    DashboardQueryDebug.mark(
      'I0 CHILD_PREVIEW_BUNDLE_REQUESTED',
      scope: request.parentScope,
      detail: 'source=$source generation=$generation cacheKey=$cacheKey',
    );
    final future = () async {
      final bundle = await repository.readChildPreviewBundle(bundleRequest);
      if (_disposed || !_isCompatibleBundle(bundle, request)) return null;
      DashboardQueryDebug.mark(
        'I1 CHILD_PREVIEW_BUNDLE_RECEIVED',
        scope: request.parentScope,
        coreRevision: bundle.coreRevision,
        detail:
            'source=$source generation=$generation '
            'childCount=${bundle.childrenByQueryKey.length}',
      );
      if (parentSnapshot == null) {
        _pendingBundleAssembly
          ..clear()
          ..[cacheKey] = bundle;
        return null;
      }
      return _registerCompleteParentBundle(
        request: request,
        bundle: bundle,
        parentSnapshot: parentSnapshot,
        generation: generation,
        pinCurrent: pinCurrent,
      );
    }();
    _bundleLoads[cacheKey] = future;
    void removeInFlightBundle() {
      if (identical(_bundleLoads[cacheKey], future)) {
        _bundleLoads.remove(cacheKey);
      }
    }

    // Attach cleanup to both completion paths without creating an ignored
    // error-producing future (as `whenComplete` would do for a failed read).
    future.then<void>(
      (_) => removeInFlightBundle(),
      onError: (Object error, StackTrace stackTrace) => removeInFlightBundle(),
    );
    return future;
  }

  DashboardParentBundleEntry? _registerCompleteParentBundle({
    required DashboardChildSummaryRequest request,
    required DashboardChildPreviewBundle bundle,
    required DashboardPresentationSnapshot parentSnapshot,
    required int generation,
    required bool pinCurrent,
  }) {
    final displayBundle = DashboardParentDisplayBundle(
      parentSnapshot: parentSnapshot,
      childPreviewBundle: bundle,
    );
    final entry = DashboardParentBundleEntry.fromDisplayBundle(displayBundle);
    if (!_parentBundleRegistry.put(entry, pinCurrent: pinCurrent)) return null;
    _registerBundleSnapshots(bundle, generation: generation);
    if (_bundleReadinessKey == request.cacheKey &&
        !(_bundleReadinessCompleter?.isCompleted ?? true)) {
      _bundleReadinessCompleter!.complete();
    }
    return entry;
  }

  void _registerBundleSnapshots(
    DashboardChildPreviewBundle bundle, {
    required int generation,
  }) {
    final store = _presentationStore;
    if (store == null) return;
    for (final child in bundle.childrenByQueryKey.values) {
      store.publish(
        DashboardPresentationSnapshot.fromResult(
          scope: child.scope,
          generation: generation,
          result: child.result,
        ).copyWith(isPreview: true),
        activate: false,
      );
    }
  }

  void _load(DashboardChildSummaryRequest request, {required String source}) {
    final repository = _childSummaryRepository;
    if (repository == null) return;
    final cacheKey = request.cacheKey;
    final generation = ++_requestGeneration;
    final stopwatch = Stopwatch()..start();
    _inFlightCacheKey = cacheKey;
    DashboardQueryDebug.mark(
      'I0 CHILD_SUMMARY_INDEX_REQUESTED',
      scope: request.parentScope,
      detail:
          'source=$source generation=$generation '
          'childPeriod=${request.childPeriod.name} '
          'cacheKey=$cacheKey',
    );
    repository
        .readChildSummaries(request)
        .then(
          (result) {
            if (_disposed || generation != _requestGeneration) return;
            _inFlightCacheKey = null;
            final completedIndex = result.withExplicitZeroBuckets(request);
            if (!_isCompatible(completedIndex, request)) return;
            stopwatch.stop();
            DashboardQueryDebug.mark(
              'I1 CHILD_SUMMARY_INDEX_RECEIVED',
              scope: request.parentScope,
              queryKey: completedIndex.parentQueryKey,
              coreRevision: completedIndex.coreRevision,
              durationMs: stopwatch.elapsedMilliseconds,
              detail:
                  'source=$source generation=$generation '
                  'childPeriod=${completedIndex.childPeriod.name} '
                  'bucketCount=${completedIndex.values.length} '
                  'isComplete=${completedIndex.isComplete}',
            );
            _cache[cacheKey] = completedIndex;
            while (_cache.length > _cacheCapacity) {
              _cache.remove(_cache.keys.first);
            }
            _index = completedIndex;
            _synchronize();
          },
          onError: (_, _) {
            if (_disposed || generation != _requestGeneration) return;
            _inFlightCacheKey = null;
            _publish(
              _loadingMetricsForScope(
                _displayedScopeFor(_navigation.state),
                isStale: _query.state.result != null,
                hasError: true,
              ),
            );
          },
        );
  }

  ScopeSummaryMetrics _parentMetricsFor(CurrentLedgerQueryScope scope) {
    final queryState = _query.state;
    final result = queryState.result;
    final isExactScope =
        queryState.scope == scope && result?.scopeKey == scope.key.value;
    if (!isExactScope) {
      final cached = _presentationStore?.peekSnapshot(scope.key);
      if (cached != null &&
          cached.hasValue &&
          !cached.isLoading &&
          !cached.isStale &&
          !cached.hasError) {
        return ScopeSummaryMetrics(
          scope: scope,
          canonicalQueryKey: scope.key.value,
          coreRevision: cached.coreRevision,
          totalMinor: cached.totalMinor,
          entryCount: cached.entryCount,
          source: SummaryMetricsSource.parentSummary,
          isLoading: false,
          isStale: false,
          hasError: false,
        );
      }
      return _loadingMetricsForScope(
        scope,
        isStale: result != null,
        hasError: queryState.error != null,
      );
    }
    return ScopeSummaryMetrics(
      scope: scope,
      canonicalQueryKey: scope.key.value,
      coreRevision: result?.coreRevision,
      totalMinor: result?.totalMinor,
      entryCount: result?.entryCount,
      source: SummaryMetricsSource.parentSummary,
      isLoading: queryState.isLoading,
      isStale: queryState.isLoading || queryState.error != null,
      hasError: queryState.error != null,
    );
  }

  ScopeSummaryMetrics _childMetricsFor(
    DashboardTimeNavigationState navigation,
    DashboardTimeChildSummaryIndex index,
  ) {
    final childScope = _displayedScopeFor(navigation);
    final childPeriodValue = _childPeriodValue(navigation);
    final expectedQueryKey = childScope.key.value;
    final summary = index.values[childPeriodValue];
    final hasCompatibleSummary =
        summary != null && summary.childQueryKey == expectedQueryKey;
    final isPreview = navigation.previewChild is int;
    return ScopeSummaryMetrics(
      scope: childScope,
      canonicalQueryKey: expectedQueryKey,
      coreRevision: index.coreRevision,
      totalMinor: hasCompatibleSummary ? summary.totalMinor : 0,
      entryCount: hasCompatibleSummary ? summary.entryCount : 0,
      source: isPreview
          ? SummaryMetricsSource.childPreviewIndex
          : SummaryMetricsSource.childSettledIndex,
      isLoading: false,
      isStale: false,
      hasError: false,
    );
  }

  CurrentLedgerQueryScope _displayedScopeFor(
    DashboardTimeNavigationState navigation,
  ) => navigation.isRailOpen
      ? _scopeForChildValue(navigation, navigation.displayedChild)
      : _query.state.scope.copyWith(timeScope: navigation.parentScope);

  CurrentLedgerQueryScope _scopeForChildValue(
    DashboardTimeNavigationState navigation,
    int childValue,
  ) => _query.state.scope.copyWith(
    timeScope: switch (navigation.plane) {
      TimePlane.sum => YearScope(childValue),
      TimePlane.year => MonthScope(
        YearMonth(year: navigation.yearCursor, month: childValue),
      ),
      TimePlane.month => DayScope(navigation.monthCursor.clampDay(childValue)),
    },
  );

  String _childPeriodValue(DashboardTimeNavigationState navigation) =>
      switch (navigation.plane) {
        TimePlane.sum => navigation.displayedChild.toString().padLeft(4, '0'),
        TimePlane.year =>
          '${navigation.yearCursor.toString().padLeft(4, '0')}-'
              '${navigation.displayedChild.toString().padLeft(2, '0')}',
        TimePlane.month =>
          '${navigation.monthCursor.isoString}-'
              '${navigation.displayedChild.toString().padLeft(2, '0')}',
      };

  static ScopeSummaryMetrics _loadingMetricsForScope(
    CurrentLedgerQueryScope scope, {
    required bool isStale,
    required bool hasError,
  }) => ScopeSummaryMetrics(
    scope: scope,
    canonicalQueryKey: scope.key.value,
    coreRevision: null,
    totalMinor: null,
    entryCount: null,
    source: SummaryMetricsSource.stalePreviousValue,
    isLoading: !hasError,
    isStale: isStale,
    hasError: hasError,
  );

  bool _publish(ScopeSummaryMetrics next) {
    // A cold parent navigation has not produced a target bundle yet. Keep the
    // complete outgoing visual state in place; a null loading metric is not a
    // valid visible parent presentation. Child misses retain their existing
    // behavior because a child preview still has to resolve its own scope.
    if (!_navigation.state.isRailOpen &&
        next.source == SummaryMetricsSource.stalePreviousValue &&
        _presentation.totalMinor != null &&
        _presentation.entryCount != null &&
        !_presentation.hasError) {
      return false;
    }
    final changed = !_sameMetrics(_metrics, next);
    if (!changed) {
      // A preview -> settled provenance change has no visual delta when its
      // scope/value pair is identical. Keep the canonical settled snapshot for
      // subsequent reads without scheduling a second paint or amount motion.
      final previous = _metrics;
      _metrics = next;
      _presentation = SummaryMetricsPresentation.fromMetrics(next);
      if (previous?.source == SummaryMetricsSource.childPreviewIndex &&
          next.source == SummaryMetricsSource.childSettledIndex) {
        _presentationGeneration += 1;
        _publishToPresentationStore(next, previous: previous);
      }
      return false;
    }
    final previous = _metrics;
    _metrics = next;
    _presentation = SummaryMetricsPresentation.fromMetrics(next);
    _presentationGeneration += 1;
    _publishToPresentationStore(next, previous: previous);
    assert(next.canonicalQueryKey == next.scope.key.value);
    assert(next.scope == _displayedScopeFor(_navigation.state));
    _logSelectedMetrics(next);
    notifyListeners();
    return true;
  }

  void _publishToPresentationStore(
    ScopeSummaryMetrics metrics, {
    required ScopeSummaryMetrics? previous,
  }) {
    final store = _presentationStore;
    if (store == null) return;
    final key = LedgerQueryKey(metrics.canonicalQueryKey);
    final existing = store.peekSnapshot(key);
    final navigation = _navigation.state;
    final target = store.visibleTarget;
    final interactionPreview =
        target?.railOpen == true &&
        target?.expectedVisibleQueryKey == key &&
        navigation.previewChild is int;
    final isPreview =
        metrics.source == SummaryMetricsSource.parentPreview ||
        metrics.source == SummaryMetricsSource.childPreviewIndex ||
        interactionPreview;
    final bundlePreview = isPreview ? (_activeBundle?[key]) : null;
    final bundleResult = bundlePreview?.result;
    final origin = _dataOriginFor(
      metrics,
      bundleResult: bundleResult,
      existing: existing,
    );
    final baseSnapshot = isPreview && existing != null && bundleResult != null
        ? existing
        : DashboardPresentationSnapshot(
            queryKey: key,
            generation: _presentationGeneration,
            scope: metrics.scope,
            coreRevision: metrics.coreRevision,
            totalMinor: metrics.totalMinor,
            entryCount: metrics.entryCount,
            entries:
                bundleResult?.entries ??
                existing?.entries ??
                const <DashboardLedgerEntry>[],
            nextCursor: bundleResult?.nextCursor ?? existing?.nextCursor,
            isLoading: metrics.isLoading,
            isStale: metrics.isStale,
            hasError: metrics.hasError,
          );
    final snapshot = baseSnapshot.copyWith(
      generation: _presentationGeneration,
      scope: metrics.scope,
      coreRevision: metrics.coreRevision,
      totalMinor: metrics.totalMinor,
      entryCount: metrics.entryCount,
      nextCursor: bundleResult?.nextCursor ?? baseSnapshot.nextCursor,
      isLoading: metrics.isLoading,
      isStale: metrics.isStale,
      hasError: metrics.hasError,
      presentationMode: isPreview
          ? DashboardPresentationMode.preview
          : DashboardPresentationMode.committed,
      dataOrigin: origin,
      isPreview: isPreview,
    );
    final isPreviewPromotion =
        previous?.source == SummaryMetricsSource.childPreviewIndex &&
        metrics.source == SummaryMetricsSource.childSettledIndex;
    if (metrics.source == SummaryMetricsSource.parentPreview ||
        metrics.source == SummaryMetricsSource.childPreviewIndex) {
      store.recordPreviewSelection();
    } else if (metrics.source == SummaryMetricsSource.childSettledIndex) {
      store.recordCommittedSelection();
    }
    final diagnostics = _diagnostics;
    if (metrics.source == SummaryMetricsSource.childPreviewIndex &&
        diagnostics != null) {
      diagnostics.recordRailChildCrossed(
        interactionEpoch: _presentationEpoch,
        semanticChild: _navigation.state.displayedChild,
        queryKey: snapshot.queryKey,
        activity: DashboardPreviewActivity.programmatic,
        frameNumber: diagnostics.currentFrameNumber,
      );
      diagnostics.recordPreviewSnapshotSelected(
        interactionEpoch: _presentationEpoch,
        presentationGeneration: _presentationGeneration,
        queryKey: snapshot.queryKey,
        amount: snapshot.totalMinor ?? 0,
        entryCount: snapshot.entryCount is int ? snapshot.entryCount! : 0,
        logGroupCount: snapshot.logGroupCount,
        logRowCount: snapshot.entries.length,
        contentDigest: snapshot.contentDigest,
        dataOrigin: snapshot.dataOrigin,
        cacheHit: bundlePreview != null,
      );
    }
    final didPublish = isPreviewPromotion
        ? store.promote(snapshot)
        : store.publish(snapshot);
    if (isPreviewPromotion && diagnostics != null) {
      diagnostics.recordSettlePromoted(
        interactionEpoch: _presentationEpoch,
        presentationGeneration: _presentationGeneration,
        queryKey: snapshot.queryKey,
        visualChange: didPublish,
        amountRebound: didPublish,
        countRebound: didPublish,
        logRebound: didPublish,
      );
    }
    final visiblePreview =
        metrics.source == SummaryMetricsSource.childPreviewIndex &&
        (didPublish ||
            store.activeSnapshot?.hasSameVisualValue(snapshot) == true);
    if (visiblePreview) {
      _childPreviewVisiblePublishCount += 1;
      if (diagnostics != null) {
        diagnostics.recordPreviewPresentationPublished(
          interactionEpoch: _presentationEpoch,
          presentationGeneration: _presentationGeneration,
          queryKey: snapshot.queryKey,
          amount: snapshot.totalMinor ?? 0,
          entryCount: snapshot.entryCount is int ? snapshot.entryCount! : 0,
          logDigest: snapshot.contentDigest,
          presentationMode: DashboardPresentationMode.preview,
        );
      }
      if (DashboardQueryDebug.tracePreviewMetrics) {
        DashboardQueryDebug.mark(
          'I2 VISIBLE_PREVIEW_PUBLISHED',
          scope: metrics.scope,
          queryKey: metrics.canonicalQueryKey,
          coreRevision: metrics.coreRevision,
          totalMinor: metrics.totalMinor,
          entryCount: metrics.entryCount,
          detail: 'presentationGeneration=$_presentationGeneration',
        );
      }
    }
  }

  DashboardDataOrigin _dataOriginFor(
    ScopeSummaryMetrics metrics, {
    required DashboardLedgerResult? bundleResult,
    required DashboardPresentationSnapshot? existing,
  }) {
    if (metrics.source == SummaryMetricsSource.childPreviewIndex) {
      return bundleResult == null
          ? DashboardDataOrigin.childPreviewIndex
          : DashboardDataOrigin.childPreviewBundle;
    }
    if (metrics.source == SummaryMetricsSource.freshQuery) {
      return DashboardDataOrigin.freshQuery;
    }
    if (metrics.source == SummaryMetricsSource.cache) {
      return DashboardDataOrigin.memoryCache;
    }
    final currentResult = _query.state.result;
    if (currentResult != null &&
        _query.state.scope.key == metrics.scope.key &&
        currentResult.coreRevision == metrics.coreRevision) {
      return DashboardDataOrigin.freshQuery;
    }
    return existing?.dataOrigin ?? DashboardDataOrigin.liveObserver;
  }

  void _logSelectedMetrics(ScopeSummaryMetrics metrics) {
    if (metrics.totalMinor == null || metrics.entryCount == null) return;
    if (metrics.source == SummaryMetricsSource.childPreviewIndex &&
        !DashboardQueryDebug.tracePreviewMetrics) {
      return;
    }
    final navigation = _navigation.state;
    final target = _presentationStore?.visibleTarget;
    final isPreview =
        metrics.source == SummaryMetricsSource.childPreviewIndex ||
        (target?.railOpen == true &&
            target?.expectedVisibleQueryKey ==
                LedgerQueryKey(metrics.canonicalQueryKey) &&
            navigation.previewChild is int);
    final existing = _presentationStore?.peekSnapshot(
      LedgerQueryKey(metrics.canonicalQueryKey),
    );
    final dataOrigin = _dataOriginFor(
      metrics,
      bundleResult: isPreview
          ? (_activeBundle?[LedgerQueryKey(metrics.canonicalQueryKey)])?.result
          : null,
      existing: existing,
    );
    DashboardQueryDebug.mark(
      'D12 SUMMARY_METRICS_SELECTED',
      scope: metrics.scope,
      queryKey: metrics.canonicalQueryKey,
      flowId: _presentation.flowId,
      coreRevision: metrics.coreRevision,
      totalMinor: metrics.totalMinor,
      entryCount: metrics.entryCount,
      formattedTotal: _presentation.formattedAmount,
      isStale: metrics.isStale,
      detail:
          'presentationGeneration=$_presentationGeneration '
          'source=${metrics.source.name} '
          'presentationMode=${isPreview ? DashboardPresentationMode.preview.name : DashboardPresentationMode.committed.name} '
          'dataOrigin=${dataOrigin.name} '
          'railOpen=${navigation.isRailOpen} '
          'plane=${navigation.plane.name} '
          'parentScope=${navigation.parentScope.canonicalKey} '
          'displayedChild=${navigation.isRailOpen ? navigation.displayedChild : '-'} '
          'displayedMetricsScope=${metrics.scope.timeScope.canonicalKey} '
          'loading=${metrics.isLoading} stale=${metrics.isStale} '
          'error=${metrics.hasError}',
    );
  }

  static bool _sameMetrics(
    ScopeSummaryMetrics? left,
    ScopeSummaryMetrics right,
  ) =>
      left != null &&
      left.scope == right.scope &&
      left.canonicalQueryKey == right.canonicalQueryKey &&
      left.coreRevision == right.coreRevision &&
      left.totalMinor == right.totalMinor &&
      left.entryCount == right.entryCount &&
      left.isLoading == right.isLoading &&
      left.isStale == right.isStale &&
      left.hasError == right.hasError;

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration += 1;
    _navigation.removeListener(_handleNavigationChanged);
    _query.removeListener(_handleQueryChanged);
    super.dispose();
  }
}
