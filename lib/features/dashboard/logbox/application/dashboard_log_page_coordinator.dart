import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../query/application/current_query_controller.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../time_navigation/domain/local_date.dart';
import '../data/dashboard_log_repository.dart';
import '../domain/dashboard_log_models.dart';
import 'dashboard_committed_query_snapshot.dart';
import 'dashboard_log_area_state.dart';

/// Owns only LogBox paging, page cache and data-only prefetch lifecycle.
///
/// [CurrentQueryController] remains the sole committed query-scope owner. The
/// coordinator observes that scope, binds its already canonical first page,
/// and never listens to child rail preview state.
class DashboardLogPageCoordinator extends ChangeNotifier {
  DashboardLogPageCoordinator({
    required CurrentQueryController query,
    DashboardLogPageRepository? repository,
  }) : _query = query,
       _repository = repository,
       _state = DashboardLogInitialLoading(
         queryKey: query.state.scope.key.value,
       ) {
    _query.addListener(_synchronizeCommittedQuery);
    _synchronizeCommittedQuery();
  }

  static const _maxCachedPages = 30;
  static const _maxCachedRows = 1000;

  final CurrentQueryController _query;
  final DashboardLogPageRepository? _repository;
  final LinkedHashMap<_LogPageCacheKey, DashboardDayGroupPage> _cache =
      LinkedHashMap<_LogPageCacheKey, DashboardDayGroupPage>();
  final Set<_LogPageCacheKey> _loadingPageKeys = <_LogPageCacheKey>{};
  DashboardLogAreaState _state;
  String? _lastFirstPageBindKey;
  bool _disposed = false;

  DashboardLogAreaState get state => _state;

  /// Invoked only after a tap target is accepted or shared rail physics has a
  /// final target. It warms CurrentQueryController's existing result cache and
  /// leaves visible LogBox state exactly unchanged.
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
      _publish(
        DashboardLogError(
          queryKey: scope.key.value,
          coreRevision: result?.coreRevision,
          error: queryState.error!,
          previousData:
              _state is DashboardLogData && _state.queryKey == scope.key.value
              ? _state as DashboardLogData
              : null,
        ),
      );
      return;
    }
    if (queryState.isLoading || !exactResult) {
      _lastFirstPageBindKey = null;
      _publish(
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
        (_state is DashboardLogData || _state is DashboardLogEmpty)) {
      return;
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
    final current = _state;
    final repository = _repository;
    if (current is! DashboardLogData ||
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
    _publish(current.copyWith(isLoadingNextPage: true));
    final stopwatch = Stopwatch()..start();
    try {
      final page =
          _cache[key] ??
          await repository.readLogPage(
            current.snapshot.queryContext,
            before: cursor,
          );
      if (_disposed ||
          _state.queryKey != current.queryKey ||
          _state.coreRevision != current.coreRevision ||
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
      _publish(
        current.copyWith(
          groups: merged,
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
      if (!_disposed && _state.queryKey == current.queryKey) {
        _publish(
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
    final current = _state;
    if (current is DashboardLogError && current.previousData != null) {
      _publish(current.previousData!);
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
    _publish(next);
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

  void _publish(DashboardLogAreaState next) {
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

LocalDate _localDateFromEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return LocalDate(year: date.year, month: date.month, day: date.day);
}

int _epochDay(LocalDate date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(1970)).inDays;
