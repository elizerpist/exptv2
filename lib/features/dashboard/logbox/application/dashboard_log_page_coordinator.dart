import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../application/dashboard_summary_metrics_source.dart';
import '../../application/dashboard_parent_display_bundle.dart';
import '../../application/dashboard_parent_display_bundle_controller.dart';
import '../../query/application/current_query_controller.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/scope_summary_metrics.dart';
import '../../query/domain/time_child_summary.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel_spec.dart';
import '../../time_navigation/domain/local_date.dart';
import '../data/dashboard_log_repository.dart';
import '../domain/dashboard_log_models.dart';
import 'dashboard_committed_query_snapshot.dart';
import 'dashboard_log_area_state.dart';
import 'dashboard_log_view_models.dart';

/// Owns only LogBox paging, page cache and data-only prefetch lifecycle.
///
/// [CurrentQueryController] remains the sole committed query-scope owner. The
/// coordinator observes that scope, binds its canonical first page, and can
/// additionally project a read-only rail preview from the existing first-page
/// cache. Preview never mutates the query, opens a watch or performs I/O.
class DashboardLogPageCoordinator extends ChangeNotifier {
  DashboardLogPageCoordinator({
    required CurrentQueryController query,
    DashboardLogPageRepository? repository,
    DashboardSummaryMetricsSource? previewMetrics,
    DashboardTimeNavigationController? navigation,
    DashboardParentDisplayBundleController? previewBundles,
  }) : _query = query,
       _repository = repository,
       _previewMetrics = previewMetrics,
       _navigation = navigation,
       _previewBundles = previewBundles,
       _committedState = DashboardLogInitialLoading(
         queryKey: query.state.scope.key.value,
       ),
       _state = DashboardLogInitialLoading(
         queryKey: query.state.scope.key.value,
       ) {
    _query.addListener(_synchronizeCommittedQuery);
    _previewMetrics?.addListener(_synchronizePreview);
    _navigation?.addListener(_synchronizePreview);
    _previewBundles?.addListener(_synchronizePreview);
    _synchronizeCommittedQuery();
    _synchronizePreview();
  }

  static const _maxCachedPages = 30;
  static const _maxCachedRows = 1000;

  final CurrentQueryController _query;
  final DashboardLogPageRepository? _repository;
  final DashboardSummaryMetricsSource? _previewMetrics;
  final DashboardTimeNavigationController? _navigation;
  final DashboardParentDisplayBundleController? _previewBundles;
  final LinkedHashMap<_LogPageCacheKey, DashboardDayGroupPage> _cache =
      LinkedHashMap<_LogPageCacheKey, DashboardDayGroupPage>();
  final LinkedHashMap<_LogPreviewStateCacheKey, DashboardLogAreaState>
  _previewStateCache =
      LinkedHashMap<_LogPreviewStateCacheKey, DashboardLogAreaState>();
  final Set<_LogPageCacheKey> _loadingPageKeys = <_LogPageCacheKey>{};
  final Set<String> _warmedChildDomains = <String>{};
  DashboardLogAreaState _committedState;
  DashboardLogAreaState _state;
  String? _lastFirstPageBindKey;
  String? _activePreviewQueryKey;
  String? _lastPreviewDiagnosticKey;
  bool _disposed = false;

  DashboardLogAreaState get state => _state;

  /// Invoked after a tap target is accepted or shared rail physics resolves a
  /// final target. It warms the existing result cache and leaves visible state
  /// unchanged; this is supplementary to bounded child-domain warming.
  Future<void> prefetchForMotionTarget(
    CurrentLedgerQueryScope target, {
    required String reason,
  }) async {
    await _query.prefetchFirstDayGroupPage(target, reason: reason);
  }

  void _synchronizeCommittedQuery() {
    if (_disposed) return;
    final queryState = _query.state;
    final scope = queryState.scope;
    final result = queryState.result;
    final exactResult = result != null && result.scopeKey == scope.key.value;

    if (queryState.error != null) {
      _lastFirstPageBindKey = null;
      _publishCommitted(
        DashboardLogError(
          queryKey: scope.key.value,
          coreRevision: result?.coreRevision,
          error: queryState.error!,
          previousData:
              _committedState is DashboardLogData &&
                  _committedState.queryKey == scope.key.value
              ? _committedState as DashboardLogData
              : null,
        ),
      );
      return;
    }
    if (queryState.isLoading || !exactResult) {
      _lastFirstPageBindKey = null;
      // The newly committed scope may still be behind the finite rail deck.
      // Keep the prior immutable LogBox mounted until either that deck or the
      // exact committed first page is ready. Replacing concrete content with
      // an InitialLoading delegate causes the visible empty-frame flash that
      // this coordinator boundary is responsible for preventing.
      if (_hasConcreteVisibleState(_state)) return;
      _publishCommitted(
        DashboardLogInitialLoading(
          queryKey: scope.key.value,
          coreRevision: result?.coreRevision,
        ),
      );
      return;
    }

    final snapshot = DashboardCommittedQuerySnapshot.fromResult(
      scope: scope,
      result: result,
    );
    final firstPage = _pageFromCommittedResult(scope, result);
    final bindKey = _firstPageBindKey(firstPage);
    if (_lastFirstPageBindKey == bindKey &&
        (_committedState is DashboardLogData ||
            _committedState is DashboardLogEmpty)) {
      return;
    }
    // A rail preview already owns the mounted rows. When the committed query
    // selects the exact same immutable content, retain that visible identity
    // and promote only the coordinator's paging/watch ownership. Creating a
    // new LogBox state here would replace the delegate after every settle.
    if (_canPromotePreviewWithoutVisualChange(
      preview: _state,
      committedSnapshot: snapshot,
      page: firstPage,
    )) {
      _committedState = _committedStateForPromotion(
        preview: _state,
        snapshot: snapshot,
        page: firstPage,
        cacheHit: queryState.isCacheHit,
      );
      _activePreviewQueryKey = null;
      _lastFirstPageBindKey = bindKey;
      DashboardQueryDebug.mark(
        'PREVIEW_PROMOTED_TO_COMMITTED',
        scope: scope,
        queryKey: snapshot.summaryMetrics.canonicalQueryKey,
        coreRevision: snapshot.summaryMetrics.coreRevision,
        totalMinor: snapshot.summaryMetrics.totalMinor,
        entryCount: snapshot.summaryMetrics.entryCount,
        detail:
            'visualChange=false listRebound=false amountAnimationStarted=false',
      );
      return;
    }
    // A matching settled child can keep a deck projection visible while its
    // committed read resolves. If the immutable rows differ despite the same
    // key/revision, that projection is not promotable and the exact committed
    // content must replace it once, rather than remain hidden behind an
    // active preview marker.
    if (_activePreviewQueryKey == snapshot.summaryMetrics.canonicalQueryKey) {
      _activePreviewQueryKey = null;
    }
    final cacheKey = _LogPageCacheKey.forPage(firstPage, cursor: null);
    // CurrentQueryController can select a data-only prefetch from its own
    // canonical cache before this coordinator has seen the first page. Keep
    // that cache-hit identity in the presentation state and diagnostics.
    final cacheHit = queryState.isCacheHit || _cache.containsKey(cacheKey);
    _cachePage(cacheKey, firstPage);
    assert(
      snapshot.summaryMetrics.canonicalQueryKey == firstPage.canonicalQueryKey,
    );
    assert(
      snapshot.summaryMetrics.coreRevision == null ||
          snapshot.summaryMetrics.coreRevision == firstPage.coreRevision,
    );
    _publishPage(
      snapshot: snapshot,
      groups: firstPage.groups,
      nextCursor: firstPage.nextCursor,
      cacheHit: cacheHit,
      durationMs: null,
    );
    _lastFirstPageBindKey = bindKey;
  }

  /// Appends exactly one old-enough complete-day page. It is guarded by the
  /// canonical query key, revision and cursor so late results cannot append to
  /// a newer scope.
  Future<void> loadNextPage() async {
    final current = _committedState;
    final repository = _repository;
    if (_activePreviewQueryKey != null ||
        current is! DashboardLogData ||
        repository == null ||
        !current.hasNextPage ||
        current.isLoadingNextPage) {
      return;
    }
    final cursor = current.nextCursor!;
    final key = _LogPageCacheKey(
      queryKey: current.queryKey,
      coreRevision: current.coreRevision,
      beforeEpochDayExclusive: _epochDay(cursor.beforeLocalDateExclusive),
    );
    if (!_loadingPageKeys.add(key)) return;
    _publishCommitted(current.copyWith(isLoadingNextPage: true));
    final stopwatch = Stopwatch()..start();
    try {
      final page =
          _cache[key] ??
          await repository.readLogPage(
            current.snapshot.queryContext,
            before: cursor,
          );
      if (_disposed ||
          _committedState.queryKey != current.queryKey ||
          _committedState.coreRevision != current.coreRevision ||
          page.canonicalQueryKey != current.queryKey ||
          page.coreRevision != current.coreRevision) {
        DashboardQueryDebug.mark(
          'LOG_QUERY_DROPPED_STALE',
          queryKey: page.canonicalQueryKey,
          coreRevision: page.coreRevision,
          isStale: true,
          detail: 'nextPageCursor=${key.beforeEpochDayExclusive}',
        );
        return;
      }
      _cachePage(key, page);
      stopwatch.stop();
      final merged = _mergeDayGroups(current.groups, page.groups);
      final mergedViewGroups = _mergeViewGroups(
        current: current,
        merged: merged,
      );
      _publishCommitted(
        current.copyWith(
          groups: merged,
          viewGroups: mergedViewGroups,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingNextPage: false,
        ),
      );
      DashboardQueryDebug.mark(
        'LOG_NEXT_PAGE_LOADED',
        scope: current.snapshot.queryContext,
        queryKey: current.queryKey,
        coreRevision: current.coreRevision,
        durationMs: stopwatch.elapsedMilliseconds,
        detail:
            'cursor=${key.beforeEpochDayExclusive} groupCount=${page.groups.length} '
            'rowCount=${page.rowCount}',
      );
    } on Object catch (error) {
      if (!_disposed && _committedState.queryKey == current.queryKey) {
        _publishCommitted(
          DashboardLogError(
            queryKey: current.queryKey,
            coreRevision: current.coreRevision,
            error: error,
            previousData: current.copyWith(isLoadingNextPage: false),
          ),
        );
      }
    } finally {
      _loadingPageKeys.remove(key);
    }
  }

  void retry() {
    final current = _committedState;
    if (current is DashboardLogError && current.previousData != null) {
      _publishCommitted(current.previousData!);
      loadNextPage();
      return;
    }
    _synchronizeCommittedQuery();
  }

  DashboardDayGroupPage _pageFromCommittedResult(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result,
  ) {
    final rawGroups = result.dayGroups.isNotEmpty
        ? result.dayGroups
        : _groupLegacyEntries(result.entries);
    return DashboardDayGroupPage(
      canonicalQueryKey: scope.key.value,
      coreRevision: result.coreRevision ?? 0,
      groups: rawGroups
          .map(
            (group) => DashboardDayLogGroup(
              localDate: _localDateFromEpochDay(group.bookedLocalEpochDay),
              rows: group.entries,
            ),
          )
          .toList(growable: false),
      nextCursor: _cursorFromResult(result),
    );
  }

  List<DashboardLedgerDayGroup> _groupLegacyEntries(
    List<DashboardLedgerEntry> entries,
  ) {
    final byDate = <int, List<DashboardLedgerEntry>>{};
    for (final entry in entries) {
      (byDate[entry.bookedLocalEpochDay] ??= <DashboardLedgerEntry>[]).add(
        entry,
      );
    }
    final dates = byDate.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return dates
        .map(
          (date) => DashboardLedgerDayGroup(
            bookedLocalEpochDay: date,
            entries: List<DashboardLedgerEntry>.unmodifiable(byDate[date]!),
          ),
        )
        .toList(growable: false);
  }

  DashboardDayGroupPageCursor? _cursorFromResult(DashboardLedgerResult result) {
    final raw = result.nextDayCursor;
    if (raw == null) return null;
    final epochDay = raw['beforeLocalEpochDayExclusive'];
    if (epochDay is! num) return null;
    return DashboardDayGroupPageCursor(
      beforeLocalDateExclusive: _localDateFromEpochDay(epochDay.toInt()),
    );
  }

  void _publishPage({
    required DashboardCommittedQuerySnapshot snapshot,
    required List<DashboardDayLogGroup> groups,
    required DashboardDayGroupPageCursor? nextCursor,
    required bool cacheHit,
    required int? durationMs,
  }) {
    final next = groups.isEmpty
        ? DashboardLogEmpty(snapshot: snapshot, cacheHit: cacheHit)
        : DashboardLogData(
            snapshot: snapshot,
            groups: groups,
            nextCursor: nextCursor,
            isLoadingNextPage: false,
            isStale: false,
            cacheHit: cacheHit,
          );
    _publishCommitted(next);
    DashboardQueryDebug.mark(
      'LOG_FIRST_PAGE_BOUND',
      scope: snapshot.queryContext,
      queryKey: snapshot.summaryMetrics.canonicalQueryKey,
      coreRevision: snapshot.summaryMetrics.coreRevision,
      totalMinor: snapshot.summaryMetrics.totalMinor,
      entryCount: snapshot.summaryMetrics.entryCount,
      durationMs: durationMs,
      detail:
          'cacheHit=$cacheHit groupCount=${groups.length} '
          'rowCount=${groups.fold<int>(0, (count, group) => count + group.rows.length)}',
    );
  }

  void _cachePage(_LogPageCacheKey key, DashboardDayGroupPage page) {
    _cache
      ..remove(key)
      ..[key] = page;
    while (_cache.length > _maxCachedPages ||
        _cachedRowCount > _maxCachedRows) {
      _cache.remove(_cache.keys.first);
    }
  }

  int get _cachedRowCount =>
      _cache.values.fold<int>(0, (count, page) => count + page.rowCount);

  void _synchronizePreview() {
    if (_disposed) return;
    _warmPreviewChildDomainIfReady();
    final metrics = _previewMetrics?.metrics;
    if (metrics == null || !_isDeckProjection(metrics)) {
      if (_activePreviewQueryKey == null) return;
      _activePreviewQueryKey = null;
      if (_sameVisiblePage(_state, _committedState)) {
        _state = _committedState;
        return;
      }
      _publishVisible(_committedState);
      return;
    }

    _activePreviewQueryKey = metrics.canonicalQueryKey;
    final deckSnapshot = _previewBundles?.previewFor(metrics.scope);
    if (deckSnapshot != null &&
        deckSnapshot.coreRevision == metrics.coreRevision) {
      final page = DashboardDayGroupPage(
        canonicalQueryKey: deckSnapshot.queryKey,
        coreRevision: deckSnapshot.coreRevision,
        groups: deckSnapshot.groups,
        nextCursor: null,
      );
      final key = _LogPreviewStateCacheKey(
        queryKey: metrics.canonicalQueryKey,
        coreRevision: metrics.coreRevision,
      );
      final next = metrics.source == SummaryMetricsSource.childPreviewIndex
          ? _previewStateCache[key] ??
                _createDeckPreviewState(
                  metrics: metrics,
                  snapshot: deckSnapshot,
                )
          : _createDeckPreviewState(metrics: metrics, snapshot: deckSnapshot);
      _cachePreviewState(key, next);
      if (!_sameVisiblePage(_state, next)) _publishVisible(next);
      _logPreviewBound(metrics, page);
      return;
    }
    final cached = _query.cachedFirstDayGroupPage(metrics.scope);
    final exactCachedPage =
        cached != null &&
        cached.scopeKey == metrics.canonicalQueryKey &&
        cached.coreRevision == metrics.coreRevision;
    if (!exactCachedPage) {
      _publishPreviewCacheMiss(metrics);
      return;
    }

    final page = _pageFromCommittedResult(metrics.scope, cached);
    final key = _LogPreviewStateCacheKey(
      queryKey: metrics.canonicalQueryKey,
      coreRevision: metrics.coreRevision,
    );
    final next = metrics.source == SummaryMetricsSource.childPreviewIndex
        ? _previewStateCache[key] ??
              _createPreviewState(metrics: metrics, page: page)
        : _createPreviewState(metrics: metrics, page: page);
    _cachePreviewState(key, next);
    if (!_sameVisiblePage(_state, next)) _publishVisible(next);
    _logPreviewBound(metrics, page);
  }

  void _warmPreviewChildDomainIfReady() {
    final navigation = _navigation;
    final source = _previewMetrics;
    final index = source?.readyIndex;
    final parentScope = source?.readyParentScope;
    if (navigation == null ||
        source == null ||
        index == null ||
        parentScope == null ||
        !index.isComplete ||
        parentScope.direction != index.direction) {
      return;
    }
    final state = navigation.state;
    if (index.parentQueryKey != parentScope.key.value ||
        index.direction != parentScope.direction ||
        parentScope.timeScope != state.parentScope ||
        index.childPeriod != _childPeriodFor(state.plane)) {
      return;
    }
    if (_previewBundles?.isFiniteBundleActiveOrLoading(
          parentScope: parentScope,
          plane: state.plane,
        ) ??
        false) {
      return;
    }
    final domainKey = <Object?>[
      parentScope.key.value,
      index.coreRevision,
      state.plane.name,
    ].join('|');
    if (!_warmedChildDomains.add(domainKey)) return;
    final scopes = _warmScopesFor(state, navigation, parentScope);
    if (scopes.isEmpty) return;
    unawaited(
      _query.warmFirstDayGroupPages(
        scopes,
        reason: 'childDomain:${state.plane.name}',
      ),
    );
  }

  List<CurrentLedgerQueryScope> _warmScopesFor(
    DashboardTimeNavigationState state,
    DashboardTimeNavigationController navigation,
    CurrentLedgerQueryScope parentScope,
  ) {
    final logicalIndices = switch (state.plane) {
      TimePlane.year => List<int>.generate(12, (index) => index),
      TimePlane.month => List<int>.generate(
        state.monthCursor.daysInMonth,
        (index) => index,
      ),
      TimePlane.sum => List<int>.generate(
        CenteredCarouselPresets.timeRailMaxItemsPerFling * 2 + 3,
        (index) =>
            navigation.selectedChildLogicalIndex -
            CenteredCarouselPresets.timeRailMaxItemsPerFling -
            1 +
            index,
      ),
    };
    return logicalIndices
        .map(
          (logicalIndex) => parentScope.copyWith(
            timeScope: navigation.childScopeForLogicalIndex(logicalIndex),
          ),
        )
        .toList(growable: false);
  }

  TimeChildPeriod _childPeriodFor(TimePlane plane) => switch (plane) {
    TimePlane.sum => TimeChildPeriod.year,
    TimePlane.year => TimeChildPeriod.month,
    TimePlane.month => TimeChildPeriod.day,
  };

  DashboardLogAreaState _createPreviewState({
    required ScopeSummaryMetrics metrics,
    required DashboardDayGroupPage page,
  }) {
    final snapshot = DashboardPreviewQuerySnapshot(
      queryContext: metrics.scope,
      summaryMetrics: metrics,
    );
    assert(page.canonicalQueryKey == snapshot.summaryMetrics.canonicalQueryKey);
    assert(page.coreRevision == snapshot.summaryMetrics.coreRevision);
    return page.groups.isEmpty
        ? DashboardLogEmpty(snapshot: snapshot, cacheHit: true)
        : DashboardLogData(
            snapshot: snapshot,
            groups: page.groups,
            nextCursor: null,
            isLoadingNextPage: false,
            isStale: false,
            cacheHit: true,
          );
  }

  DashboardLogAreaState _createDeckPreviewState({
    required ScopeSummaryMetrics metrics,
    required DashboardLogPreviewSnapshot snapshot,
  }) {
    final querySnapshot = DashboardPreviewQuerySnapshot(
      queryContext: metrics.scope,
      summaryMetrics: metrics,
    );
    return snapshot.groups.isEmpty
        ? DashboardLogEmpty(snapshot: querySnapshot, cacheHit: true)
        : DashboardLogData(
            snapshot: querySnapshot,
            groups: snapshot.groups,
            viewGroups: snapshot.viewGroups,
            nextCursor: null,
            isLoadingNextPage: false,
            isStale: false,
            cacheHit: true,
          );
  }

  void _publishPreviewCacheMiss(ScopeSummaryMetrics metrics) {
    // A finite rail cannot replace a rendered immutable child snapshot with a
    // blank loading delegate. Keep the prior state under its own identity
    // until the complete target deck is activated. It is deliberately not
    // relabelled with [metrics]' target key.
    if (!_hasConcreteVisibleState(_state)) {
      _publishVisible(DashboardLogPreviewLoading(metrics: metrics));
    }
    final diagnosticKey =
        'miss|${metrics.canonicalQueryKey}|${metrics.coreRevision}';
    if (_lastPreviewDiagnosticKey == diagnosticKey) return;
    _lastPreviewDiagnosticKey = diagnosticKey;
    DashboardQueryDebug.mark(
      'LOG_PREVIEW_CACHE_MISS',
      scope: metrics.scope,
      queryKey: metrics.canonicalQueryKey,
      coreRevision: metrics.coreRevision,
      totalMinor: metrics.totalMinor,
      entryCount: metrics.entryCount,
      detail: 'source=${metrics.source.name}',
    );
  }

  void _logPreviewBound(
    ScopeSummaryMetrics metrics,
    DashboardDayGroupPage page,
  ) {
    final diagnosticKey =
        'bound|${metrics.canonicalQueryKey}|${metrics.coreRevision}';
    if (_lastPreviewDiagnosticKey == diagnosticKey) return;
    _lastPreviewDiagnosticKey = diagnosticKey;
    DashboardQueryDebug.mark(
      'LOG_PREVIEW_BOUND',
      scope: metrics.scope,
      queryKey: metrics.canonicalQueryKey,
      coreRevision: metrics.coreRevision,
      totalMinor: metrics.totalMinor,
      entryCount: metrics.entryCount,
      detail: 'groupCount=${page.groups.length} rowCount=${page.rowCount}',
    );
  }

  void _cachePreviewState(
    _LogPreviewStateCacheKey key,
    DashboardLogAreaState state,
  ) {
    _previewStateCache
      ..remove(key)
      ..[key] = state;
    while (_previewStateCache.length > _maxCachedPages ||
        _previewStateRowCount > _maxCachedRows) {
      _previewStateCache.remove(_previewStateCache.keys.first);
    }
  }

  int get _previewStateRowCount => _previewStateCache.values.fold<int>(
    0,
    (count, state) => switch (state) {
      DashboardLogData(:final groups) =>
        count + groups.fold<int>(0, (rows, group) => rows + group.rows.length),
      _ => count,
    },
  );

  bool _isDeckProjection(ScopeSummaryMetrics metrics) =>
      metrics.source == SummaryMetricsSource.childPreviewIndex ||
      metrics.source == SummaryMetricsSource.childSettledIndex;

  static bool _hasConcreteVisibleState(DashboardLogAreaState state) =>
      state is DashboardLogData || state is DashboardLogEmpty;

  bool _sameVisiblePage(
    DashboardLogAreaState left,
    DashboardLogAreaState right,
  ) {
    if (left.queryKey != right.queryKey ||
        left.coreRevision != right.coreRevision) {
      return false;
    }
    return switch ((left, right)) {
      (
        DashboardLogData(
          snapshot: final leftSnapshot,
          groups: final leftGroups,
        ),
        DashboardLogData(
          snapshot: final rightSnapshot,
          groups: final rightGroups,
        ),
      ) =>
        leftSnapshot.summaryMetrics.totalMinor ==
                rightSnapshot.summaryMetrics.totalMinor &&
            leftSnapshot.summaryMetrics.entryCount ==
                rightSnapshot.summaryMetrics.entryCount &&
            _sameRows(leftGroups, rightGroups),
      (
        DashboardLogEmpty(snapshot: final leftSnapshot),
        DashboardLogEmpty(snapshot: final rightSnapshot),
      ) =>
        leftSnapshot.summaryMetrics.totalMinor ==
                rightSnapshot.summaryMetrics.totalMinor &&
            leftSnapshot.summaryMetrics.entryCount ==
                rightSnapshot.summaryMetrics.entryCount,
      _ => false,
    };
  }

  bool _sameRows(
    List<DashboardDayLogGroup> left,
    List<DashboardDayLogGroup> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      final leftGroup = left[index];
      final rightGroup = right[index];
      if (leftGroup.localDate != rightGroup.localDate ||
          leftGroup.rows.length != rightGroup.rows.length) {
        return false;
      }
      for (var rowIndex = 0; rowIndex < leftGroup.rows.length; rowIndex += 1) {
        if (!_sameRow(leftGroup.rows[rowIndex], rightGroup.rows[rowIndex])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _sameRow(DashboardLedgerEntry left, DashboardLedgerEntry right) =>
      left.id == right.id &&
      left.partnerId == right.partnerId &&
      left.categoryId == right.categoryId &&
      left.direction == right.direction &&
      left.amountMinor == right.amountMinor &&
      left.bookedLocalEpochDay == right.bookedLocalEpochDay &&
      left.bookedLocalTimeMinutes == right.bookedLocalTimeMinutes &&
      left.note == right.note &&
      left.occurredAtUtcMs == right.occurredAtUtcMs &&
      left.partnerDisplayName == right.partnerDisplayName &&
      left.categoryDisplayName == right.categoryDisplayName &&
      left.categoryColorId == right.categoryColorId &&
      left.categoryIconId == right.categoryIconId &&
      left.assignmentMode == right.assignmentMode &&
      left.originKind == right.originKind;

  bool _canPromotePreviewWithoutVisualChange({
    required DashboardLogAreaState preview,
    required DashboardCommittedQuerySnapshot committedSnapshot,
    required DashboardDayGroupPage page,
  }) {
    if (!preview.isPreview ||
        preview.queryKey !=
            committedSnapshot.summaryMetrics.canonicalQueryKey ||
        preview.coreRevision != committedSnapshot.summaryMetrics.coreRevision) {
      return false;
    }
    return switch (preview) {
      DashboardLogData(
        snapshot: final DashboardPreviewQuerySnapshot previewSnapshot,
        :final groups,
      ) =>
        previewSnapshot.summaryMetrics.totalMinor ==
                committedSnapshot.summaryMetrics.totalMinor &&
            previewSnapshot.summaryMetrics.entryCount ==
                committedSnapshot.summaryMetrics.entryCount &&
            _sameRows(groups, page.groups),
      DashboardLogEmpty(
        snapshot: final DashboardPreviewQuerySnapshot previewSnapshot,
      ) =>
        page.groups.isEmpty &&
            previewSnapshot.summaryMetrics.totalMinor ==
                committedSnapshot.summaryMetrics.totalMinor &&
            previewSnapshot.summaryMetrics.entryCount ==
                committedSnapshot.summaryMetrics.entryCount,
      _ => false,
    };
  }

  DashboardLogAreaState _committedStateForPromotion({
    required DashboardLogAreaState preview,
    required DashboardCommittedQuerySnapshot snapshot,
    required DashboardDayGroupPage page,
    required bool cacheHit,
  }) => switch (preview) {
    DashboardLogData(:final viewGroups) => DashboardLogData(
      snapshot: snapshot,
      groups: page.groups,
      // Keep the already projected immutable VMs. The committed owner can
      // enable paging without formatting, grouping or list allocation again.
      viewGroups: viewGroups,
      nextCursor: page.nextCursor,
      isLoadingNextPage: false,
      isStale: false,
      cacheHit: cacheHit,
    ),
    DashboardLogEmpty() => DashboardLogEmpty(
      snapshot: snapshot,
      cacheHit: cacheHit,
    ),
    _ => throw StateError('Only preview data may be promoted.'),
  };

  List<DashboardDayLogGroup> _mergeDayGroups(
    List<DashboardDayLogGroup> current,
    List<DashboardDayLogGroup> incoming,
  ) {
    final byDate = <LocalDate, List<DashboardLedgerEntry>>{};
    for (final group in [...current, ...incoming]) {
      final rows = byDate.putIfAbsent(
        group.localDate,
        () => <DashboardLedgerEntry>[],
      );
      final knownIds = rows.map((row) => row.id).toSet();
      for (final row in group.rows) {
        if (knownIds.add(row.id)) rows.add(row);
      }
    }
    final dates = byDate.keys.toList()
      ..sort((left, right) => _epochDay(right).compareTo(_epochDay(left)));
    return List<DashboardDayLogGroup>.unmodifiable(
      dates.map(
        (date) => DashboardDayLogGroup(
          localDate: date,
          rows: List<DashboardLedgerEntry>.unmodifiable(byDate[date]!),
        ),
      ),
    );
  }

  /// Reuses immutable view models for day groups untouched by an append.
  /// Formatting names/money/date labels for hundreds of older rows during a
  /// scroll-triggered page load was the primary avoidable scroll-isolate cost.
  List<DashboardDayLogGroupViewModel> _mergeViewGroups({
    required DashboardLogData current,
    required List<DashboardDayLogGroup> merged,
  }) {
    final currentGroupsByDate = <LocalDate, DashboardDayLogGroup>{
      for (final group in current.groups) group.localDate: group,
    };
    final currentViewsByDate = <String, DashboardDayLogGroupViewModel>{
      for (final view in current.viewGroups) view.dateKey: view,
    };
    return List<DashboardDayLogGroupViewModel>.unmodifiable(
      merged.map((group) {
        final existingGroup = currentGroupsByDate[group.localDate];
        final existingView = currentViewsByDate[group.localDate.isoString];
        if (existingGroup != null &&
            existingView != null &&
            _sameDayGroupRows(existingGroup, group)) {
          return existingView;
        }
        return DashboardLogViewModelProjector.presentGroup(group);
      }),
    );
  }

  bool _sameDayGroupRows(
    DashboardDayLogGroup left,
    DashboardDayLogGroup right,
  ) {
    if (left.localDate != right.localDate ||
        left.rows.length != right.rows.length) {
      return false;
    }
    for (var index = 0; index < left.rows.length; index += 1) {
      if (left.rows[index].id != right.rows[index].id) return false;
    }
    return true;
  }

  void _publishCommitted(DashboardLogAreaState next) {
    if (_disposed || identical(_committedState, next)) return;
    _committedState = next;
    if (_activePreviewQueryKey == null) _publishVisible(next);
  }

  void _publishVisible(DashboardLogAreaState next) {
    if (_disposed || identical(_state, next)) return;
    _state = next;
    notifyListeners();
  }

  String _firstPageBindKey(DashboardDayGroupPage page) => <Object?>[
    page.canonicalQueryKey,
    page.coreRevision,
    page.nextCursor?.beforeLocalDateExclusive.isoString,
    for (final group in page.groups) group.localDate.isoString,
    for (final group in page.groups) ...group.rows.map((row) => row.id),
  ].join('|');

  @override
  void dispose() {
    _disposed = true;
    _query.removeListener(_synchronizeCommittedQuery);
    _previewMetrics?.removeListener(_synchronizePreview);
    _navigation?.removeListener(_synchronizePreview);
    _previewBundles?.removeListener(_synchronizePreview);
    super.dispose();
  }
}

@immutable
class _LogPageCacheKey {
  const _LogPageCacheKey({
    required this.queryKey,
    required this.coreRevision,
    required this.beforeEpochDayExclusive,
  });

  factory _LogPageCacheKey.forPage(
    DashboardDayGroupPage page, {
    required DashboardDayGroupPageCursor? cursor,
  }) => _LogPageCacheKey(
    queryKey: page.canonicalQueryKey,
    coreRevision: page.coreRevision,
    beforeEpochDayExclusive: cursor == null
        ? null
        : _epochDay(cursor.beforeLocalDateExclusive),
  );

  final String queryKey;
  final int? coreRevision;
  final int? beforeEpochDayExclusive;

  @override
  bool operator ==(Object other) =>
      other is _LogPageCacheKey &&
      other.queryKey == queryKey &&
      other.coreRevision == coreRevision &&
      other.beforeEpochDayExclusive == beforeEpochDayExclusive;

  @override
  int get hashCode =>
      Object.hash(queryKey, coreRevision, beforeEpochDayExclusive);
}

@immutable
class _LogPreviewStateCacheKey {
  const _LogPreviewStateCacheKey({
    required this.queryKey,
    required this.coreRevision,
  });

  final String queryKey;
  final int? coreRevision;

  @override
  bool operator ==(Object other) =>
      other is _LogPreviewStateCacheKey &&
      other.queryKey == queryKey &&
      other.coreRevision == coreRevision;

  @override
  int get hashCode => Object.hash(queryKey, coreRevision);
}

LocalDate _localDateFromEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return LocalDate(year: date.year, month: date.month, day: date.day);
}

int _epochDay(LocalDate date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(1970)).inDays;
