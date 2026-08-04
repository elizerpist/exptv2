import 'dart:async';
import 'dart:math' as math;

import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

/// Deterministic profile-only source. It deliberately materializes the chosen
/// 0/94/1000-row parent fixture so the same gestures can isolate UI density.
class DashboardProfileFixtureRepository
    implements
        DashboardLedgerRepository,
        DashboardCoreRevisionRepository,
        DashboardChildSummaryRepository,
        DashboardChildPreviewRepository {
  DashboardProfileFixtureRepository({required this.entryCount});

  final int entryCount;
  static const int _coreRevision = 1;
  final Map<String, int> _epochDays = <String, int>{};

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    final distribution = _distributionForScope(scope.timeScope);
    return DashboardLedgerResult(
      totalMinor: _sumMinor(distribution.offset, distribution.count),
      entryCount: distribution.count,
      entries: _entries(
        scope,
        count: distribution.count,
        globalOffset: distribution.offset,
      ),
      coreRevision: _coreRevision,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    yield await read(scope, pageSize: pageSize, after: after);
  }

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(_coreRevision);

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) async {
    final values = <String, DashboardTimeChildSummary>{};
    for (final child in _children(request.parentScope, request.childPeriod)) {
      values[child.value] = DashboardTimeChildSummary(
        childPeriodValue: child.value,
        childQueryKey: child.scope.key.value,
        totalMinor: _sumMinor(child.offset, child.count),
        entryCount: child.count,
      );
    }
    return DashboardTimeChildSummaryIndex(
      parentQueryKey: request.parentScope.key.value,
      direction: request.parentScope.direction,
      childPeriod: request.childPeriod,
      coreRevision: _coreRevision,
      isComplete: true,
      values: values,
    );
  }

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) async {
    final values = <LedgerQueryKey, DashboardChildPreview>{};
    for (final child in _children(request.parentScope, request.childPeriod)) {
      final previewCount = math.min(child.count, request.previewPageSize);
      values[child.scope.key] = DashboardChildPreview(
        childPeriodValue: child.value,
        scope: child.scope,
        result: DashboardLedgerResult(
          totalMinor: _sumMinor(child.offset, child.count),
          entryCount: child.count,
          entries: _entries(
            child.scope,
            count: previewCount,
            globalOffset: child.offset,
          ),
          nextCursor: child.count > previewCount && previewCount > 0
              ? <String, Object?>{
                  'bookedLocalEpochDay': _epochDay(child.date),
                  'bookedLocalTimeMinutes': 720,
                  'entryId': _entryId(child.offset + previewCount - 1),
                }
              : null,
          coreRevision: _coreRevision,
          scopeKey: child.scope.key.value,
          timeScopeKey: child.scope.timeScope.canonicalKey,
          direction: child.scope.direction.name,
        ),
      );
    }
    return DashboardChildPreviewBundle(
      parentScope: request.parentScope,
      childPeriod: request.childPeriod,
      coreRevision: _coreRevision,
      previewPageSize: request.previewPageSize,
      childrenByQueryKey: values,
    );
  }

  List<_ProfileChild> _children(
    CurrentLedgerQueryScope parentScope,
    TimeChildPeriod childPeriod,
  ) {
    final parent = parentScope.timeScope;
    if (parent is MonthScope && childPeriod == TimeChildPeriod.day) {
      var offset = 0;
      return List<_ProfileChild>.generate(parent.value.daysInMonth, (index) {
        final day = index + 1;
        final count = _countForBucket(day, parent.value.daysInMonth);
        final date = parent.value.clampDay(day);
        final child = _ProfileChild(
          value: date.isoString,
          scope: parentScope.copyWith(timeScope: DayScope(date)),
          date: date,
          offset: offset,
          count: count,
        );
        offset += count;
        return child;
      });
    }
    if (parent is YearScope && childPeriod == TimeChildPeriod.month) {
      var offset = 0;
      return List<_ProfileChild>.generate(12, (index) {
        final month = YearMonth(year: parent.year, month: index + 1);
        final count = _countForBucket(index + 1, 12);
        final child = _ProfileChild(
          value: month.isoString,
          scope: parentScope.copyWith(timeScope: MonthScope(month)),
          date: month.clampDay(1),
          offset: offset,
          count: count,
        );
        offset += count;
        return child;
      });
    }
    throw StateError(
      'Unsupported profile child contract: ${parent.canonicalKey} '
      '${childPeriod.name}',
    );
  }

  _ProfileDistribution _distributionForScope(LedgerTimeScope scope) {
    if (scope is DayScope) {
      final month = YearMonth(year: scope.date.year, month: scope.date.month);
      var offset = 0;
      for (var day = 1; day < scope.date.day; day += 1) {
        offset += _countForBucket(day, month.daysInMonth);
      }
      return _ProfileDistribution(
        count: _countForBucket(scope.date.day, month.daysInMonth),
        offset: offset,
      );
    }
    return _ProfileDistribution(count: entryCount, offset: 0);
  }

  int _countForBucket(int oneBasedBucket, int bucketCount) {
    final base = entryCount ~/ bucketCount;
    final remainder = entryCount % bucketCount;
    return base + (oneBasedBucket <= remainder ? 1 : 0);
  }

  List<DashboardLedgerEntry> _entries(
    CurrentLedgerQueryScope scope, {
    required int count,
    required int globalOffset,
  }) {
    final fallbackDate = switch (scope.timeScope) {
      DayScope(:final date) => date,
      MonthScope(:final value) => value.clampDay(1),
      YearScope(:final year) => LocalDate(year: year, month: 1, day: 1),
      AllTimeScope() => const LocalDate(year: 2026, month: 1, day: 1),
    };
    return List<DashboardLedgerEntry>.generate(count, (index) {
      final globalIndex = globalOffset + index;
      final date = scope.timeScope is MonthScope
          ? _dateForMonthIndex(
              (scope.timeScope as MonthScope).value,
              globalIndex,
            )
          : fallbackDate;
      final epochDay = _epochDay(date);
      return DashboardLedgerEntry(
        id: _entryId(globalIndex),
        partnerId: 'profile-partner-${globalIndex % 8}',
        partnerDisplayName: 'Profile partner ${globalIndex % 8}',
        categoryId: 'profile-category-${globalIndex % 6}',
        categoryDisplayName: 'Profile category ${globalIndex % 6}',
        categoryColorId:
            'color_${((globalIndex % 20) + 1).toString().padLeft(2, '0')}',
        categoryIconId:
            'icon_${((globalIndex % 16) + 1).toString().padLeft(2, '0')}',
        assignmentMode: 'partnerDefault',
        originKind: 'manual',
        direction: scope.direction.name,
        amountMinor: (globalIndex + 1) * 100,
        bookedLocalEpochDay: epochDay,
        bookedLocalTimeMinutes: globalIndex % 1440,
        occurredAtUtcMs:
            epochDay * Duration.millisecondsPerDay +
            12 * Duration.millisecondsPerHour,
        note: 'Profile row $globalIndex',
      );
    }, growable: false);
  }

  static int _sumMinor(int offset, int count) =>
      count * (2 * offset + count + 1) * 50;

  int _epochDay(LocalDate date) => _epochDays.putIfAbsent(
    date.isoString,
    () =>
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay,
  );

  LocalDate _dateForMonthIndex(YearMonth month, int globalIndex) {
    final bucketCount = month.daysInMonth;
    final base = entryCount ~/ bucketCount;
    final remainder = entryCount % bucketCount;
    final largerBucketRows = (base + 1) * remainder;
    if (globalIndex < largerBucketRows) {
      return month.clampDay(globalIndex ~/ (base + 1) + 1);
    }
    return month.clampDay(
      remainder + (globalIndex - largerBucketRows) ~/ base + 1,
    );
  }

  static String _entryId(int index) => 'profile-entry-$index';
}

class _ProfileDistribution {
  const _ProfileDistribution({required this.count, required this.offset});

  final int count;
  final int offset;
}

class _ProfileChild {
  const _ProfileChild({
    required this.value,
    required this.scope,
    required this.date,
    required this.offset,
    required this.count,
  });

  final String value;
  final CurrentLedgerQueryScope scope;
  final LocalDate date;
  final int offset;
  final int count;
}
