import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/time_child_summary.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/summary_amount_presentation.dart';
import '../time_navigation/presentation/summary_pill_presenter.dart';

/// Projects the SummaryPill amount independently of the detailed dashboard
/// slice while a time rail is open.
///
/// The existing [CurrentQueryController] remains the sole owner of selected
/// detailed scope watches. This controller has one bounded parent-index cache
/// and performs map lookups on rail preview changes.
class DashboardSummaryAmountController extends ChangeNotifier {
  DashboardSummaryAmountController({
    required DashboardTimeNavigationController navigation,
    required CurrentQueryController query,
    DashboardChildSummaryRepository? childSummaryRepository,
  }) : _navigation = navigation,
       _query = query,
       _childSummaryRepository = childSummaryRepository,
       _presentation = SummaryPillPresenter.presentAmount(query: query.state) {
    _navigation.addListener(_handleNavigationChanged);
    _query.addListener(_handleQueryChanged);
    _synchronize();
  }

  static const _cacheCapacity = 30;

  final DashboardTimeNavigationController _navigation;
  final CurrentQueryController _query;
  final DashboardChildSummaryRepository? _childSummaryRepository;
  final LinkedHashMap<String, DashboardTimeChildSummaryIndex> _cache =
      LinkedHashMap<String, DashboardTimeChildSummaryIndex>();

  DashboardTimeChildSummaryIndex? _index;
  String? _activeParentQueryKey;
  String? _inFlightCacheKey;
  int _requestGeneration = 0;
  bool _disposed = false;
  SummaryAmountPresentation _presentation;

  SummaryAmountPresentation get presentation => _presentation;
  DashboardTimeChildSummaryIndex? get index => _index;
  String? get activeParentQueryKey => _activeParentQueryKey;

  void _handleNavigationChanged() => _synchronize();

  void _handleQueryChanged() => _synchronize();

  void _synchronize() {
    if (_disposed) return;
    final navigation = _navigation.state;
    if (!navigation.isRailOpen || _childSummaryRepository == null) {
      _index = null;
      _activeParentQueryKey = null;
      _publish(SummaryPillPresenter.presentAmount(query: _query.state));
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
      _publishIndexedAmount(navigation, cached);
      return;
    }

    _index = null;
    _publish(SummaryPillPresenter.presentAmount(query: _query.state));
    if (_inFlightCacheKey == cacheKey) return;
    _load(request);
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
        candidate.parentQueryKey != request.parentScope.key.value ||
        candidate.direction != request.parentScope.direction ||
        candidate.childPeriod != request.childPeriod) {
      return false;
    }
    final knownRevision = _query.state.result?.coreRevision;
    return knownRevision == null || candidate.coreRevision == knownRevision;
  }

  void _load(DashboardChildSummaryRequest request) {
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
          'generation=$generation childPeriod=${request.childPeriod.name} '
          'cacheKey=$cacheKey',
    );
    repository
        .readChildSummaries(request)
        .then(
          (result) {
            if (_disposed || generation != _requestGeneration) return;
            _inFlightCacheKey = null;
            if (!_isCompatible(result, request)) return;
            stopwatch.stop();
            DashboardQueryDebug.mark(
              'I1 CHILD_SUMMARY_INDEX_RECEIVED',
              scope: request.parentScope,
              queryKey: result.parentQueryKey,
              coreRevision: result.coreRevision,
              durationMs: stopwatch.elapsedMilliseconds,
              entryCount: result.values.length,
              detail:
                  'generation=$generation childPeriod=${result.childPeriod.name} '
                  'bucketCount=${result.values.length}',
            );
            _cache[cacheKey] = result;
            while (_cache.length > _cacheCapacity) {
              _cache.remove(_cache.keys.first);
            }
            _index = result;
            _synchronize();
          },
          onError: (_, __) {
            if (_disposed || generation != _requestGeneration) return;
            _inFlightCacheKey = null;
          },
        );
  }

  void _publishIndexedAmount(
    DashboardTimeNavigationState navigation,
    DashboardTimeChildSummaryIndex index,
  ) {
    final childScope = _childScopeFor(navigation);
    final childPeriodValue = _childPeriodValue(navigation);
    final expectedQueryKey = childScope.key.value;
    final summary = index.values[childPeriodValue];
    final compatibleSummary =
        summary != null &&
        summary.childQueryKey == expectedQueryKey &&
        index.parentQueryKey == _activeParentQueryKey;
    final totalMinor = compatibleSummary ? summary!.totalMinor : 0;
    final entryCount = compatibleSummary ? summary!.entryCount : 0;
    final next = SummaryAmountPresentation(
      formattedAmount: SummaryPillPresenter.formatTotalMinor(totalMinor),
      scopeKey: expectedQueryKey,
      isLoading: false,
      isStale: false,
      hasError: false,
      entryCount: entryCount,
      coreRevision: index.coreRevision,
      totalMinor: totalMinor,
      flowId: DashboardQueryDebug.flowIdFor(childScope),
    );
    if (_publish(next)) {
      DashboardQueryDebug.mark(
        'D9 amountPresentationEmitted',
        scope: childScope,
        queryKey: expectedQueryKey,
        flowId: next.flowId,
        coreRevision: index.coreRevision,
        totalMinor: totalMinor,
        entryCount: entryCount,
        formattedTotal: next.formattedAmount,
        detail:
            'source=childSummaryIndex child=$childPeriodValue '
            'loading=false stale=false',
      );
    }
  }

  CurrentLedgerQueryScope _childScopeFor(
    DashboardTimeNavigationState navigation,
  ) => _query.state.scope.copyWith(
    timeScope: switch (navigation.plane) {
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

  bool _publish(SummaryAmountPresentation next) {
    final changed = !_samePresentation(_presentation, next);
    _presentation = next;
    if (!changed) return false;
    notifyListeners();
    return true;
  }

  static bool _samePresentation(
    SummaryAmountPresentation left,
    SummaryAmountPresentation right,
  ) =>
      left.formattedAmount == right.formattedAmount &&
      left.isLoading == right.isLoading &&
      left.isStale == right.isStale &&
      left.hasError == right.hasError &&
      left.entryCount == right.entryCount &&
      left.coreRevision == right.coreRevision &&
      left.totalMinor == right.totalMinor;

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration += 1;
    _navigation.removeListener(_handleNavigationChanged);
    _query.removeListener(_handleQueryChanged);
    super.dispose();
  }
}
