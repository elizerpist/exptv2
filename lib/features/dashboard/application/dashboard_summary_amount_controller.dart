import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/application/dashboard_presentation_store.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/scope_summary_metrics.dart';
import '../query/domain/time_child_summary.dart';
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
    DashboardPresentationStore? presentationStore,
  }) : _navigation = navigation,
       _query = query,
       _childSummaryRepository = childSummaryRepository,
       _presentationStore = presentationStore,
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
  final DashboardPresentationStore? _presentationStore;
  final LinkedHashMap<String, DashboardTimeChildSummaryIndex> _cache =
      LinkedHashMap<String, DashboardTimeChildSummaryIndex>();

  DashboardTimeChildSummaryIndex? _index;
  String? _activeParentQueryKey;
  String? _inFlightCacheKey;
  int _requestGeneration = 0;
  int _presentationGeneration = 0;
  bool _disposed = false;
  ScopeSummaryMetrics? _metrics;
  SummaryMetricsPresentation _presentation;

  SummaryMetricsPresentation get presentation => _presentation;
  ScopeSummaryMetrics? get metrics => _metrics;
  DashboardTimeChildSummaryIndex? get index => _index;
  String? get activeParentQueryKey => _activeParentQueryKey;

  DashboardPresentationStore? get presentationStore => _presentationStore;

  void _handleNavigationChanged() => _synchronize();

  void _handleQueryChanged() => _synchronize();

  void _synchronize() {
    if (_disposed) return;
    final navigation = _navigation.state;
    final displayedScope = _displayedScopeFor(navigation);
    if (!navigation.isRailOpen || _childSummaryRepository == null) {
      _index = null;
      _activeParentQueryKey = null;
      _publish(_parentMetricsFor(displayedScope));
      _prewarmChildIndexIfReady(navigation);
      return;
    }

    final request = _requestFor(navigation);
    final cacheKey = request.cacheKey;
    _activeParentQueryKey = request.parentScope.key.value;
    final cached = _cache[cacheKey];
    if (_isCompatible(cached, request)) {
      _cache
        ..remove(cacheKey)
        ..[cacheKey] = cached!;
      _index = cached;
      _publish(_childMetricsFor(navigation, cached));
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
    _load(request, source: 'rail');
  }

  /// Prewarms only after the exact parent detailed scope is available. The
  /// request shares the regular bounded cache and never runs from a preview.
  void _prewarmChildIndexIfReady(DashboardTimeNavigationState navigation) {
    final repository = _childSummaryRepository;
    final queryState = _query.state;
    final result = queryState.result;
    if (repository == null ||
        queryState.isLoading ||
        result == null ||
        queryState.error != null) {
      return;
    }
    final request = _requestFor(navigation);
    if (queryState.scope != request.parentScope ||
        result.scopeKey != request.parentScope.key.value) {
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
      childPeriod: switch (navigation.plane) {
        TimePlane.sum => TimeChildPeriod.year,
        TimePlane.year => TimeChildPeriod.month,
        TimePlane.month => TimeChildPeriod.day,
      },
    );
  }

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
  ) => _query.state.scope.copyWith(
    timeScope: navigation.isRailOpen
        ? switch (navigation.plane) {
            TimePlane.sum => YearScope(navigation.displayedChild),
            TimePlane.year => MonthScope(
              YearMonth(
                year: navigation.yearCursor,
                month: navigation.displayedChild,
              ),
            ),
            TimePlane.month => DayScope(
              navigation.monthCursor.clampDay(navigation.displayedChild),
            ),
          }
        : navigation.parentScope,
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
    final snapshot = DashboardPresentationSnapshot(
      queryKey: LedgerQueryKey(metrics.canonicalQueryKey),
      generation: _presentationGeneration,
      scope: metrics.scope,
      coreRevision: metrics.coreRevision,
      totalMinor: metrics.totalMinor,
      entryCount: metrics.entryCount,
      isLoading: metrics.isLoading,
      isStale: metrics.isStale,
      hasError: metrics.hasError,
      isPreview: metrics.source == SummaryMetricsSource.childPreviewIndex,
    );
    final isPreviewPromotion =
        previous?.source == SummaryMetricsSource.childPreviewIndex &&
        metrics.source == SummaryMetricsSource.childSettledIndex;
    if (metrics.source == SummaryMetricsSource.childPreviewIndex) {
      store.recordPreviewSelection();
    } else if (metrics.source == SummaryMetricsSource.childSettledIndex) {
      store.recordCommittedSelection();
    }
    if (isPreviewPromotion) {
      store.promote(snapshot);
    } else {
      store.publish(snapshot);
    }
  }

  void _logSelectedMetrics(ScopeSummaryMetrics metrics) {
    if (metrics.source == SummaryMetricsSource.childPreviewIndex &&
        !DashboardQueryDebug.tracePreviewMetrics) {
      return;
    }
    final navigation = _navigation.state;
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
