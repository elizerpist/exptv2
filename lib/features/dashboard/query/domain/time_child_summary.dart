import 'package:flutter/foundation.dart';

import 'current_ledger_query_scope.dart';
import 'ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/year_month.dart';

/// The local calendar bucket represented by one child of the time rail.
///
/// This is deliberately distinct from a detailed ledger query: the value is
/// a bounded aggregate used while a parent rail is open.
enum TimeChildPeriod { year, month, day }

@immutable
class DashboardChildSummaryRequest {
  const DashboardChildSummaryRequest({
    required this.parentScope,
    required this.childPeriod,
  });

  final CurrentLedgerQueryScope parentScope;
  final TimeChildPeriod childPeriod;

  String get cacheKey => '${parentScope.key.value}|child:${childPeriod.name}';
}

@immutable
class DashboardTimeChildSummary {
  const DashboardTimeChildSummary({
    required this.childPeriodValue,
    required this.childQueryKey,
    required this.totalMinor,
    required this.entryCount,
  });

  /// Canonical local child value: `2026`, `2026-03`, or `2026-03-14`.
  final String childPeriodValue;

  /// The canonical query key for the detailed child scope.
  final String childQueryKey;
  final int totalMinor;
  final int entryCount;
}

@immutable
class DashboardTimeChildSummaryIndex {
  DashboardTimeChildSummaryIndex({
    required this.parentQueryKey,
    required this.direction,
    required this.childPeriod,
    required this.coreRevision,
    required this.isComplete,
    required Map<String, DashboardTimeChildSummary> values,
  }) : values = Map.unmodifiable(values);

  final String parentQueryKey;
  final LedgerDirection direction;
  final TimeChildPeriod childPeriod;
  final int coreRevision;

  /// True only when the grouped query covers every valid child bucket for the
  /// canonical parent predicate. A missing key is then a real zero.
  final bool isComplete;

  /// Sparse by design. An absent key represents zero only when [isComplete].
  final Map<String, DashboardTimeChildSummary> values;

  /// Materializes calendar children omitted by a sparse grouped SQL result.
  ///
  /// Only a complete, compatible index can declare those values as true zero.
  /// All-time/year children intentionally remain sparse because their domain is
  /// logically unbounded; a requested absent year is resolved as zero by the
  /// same complete-index contract.
  DashboardTimeChildSummaryIndex withExplicitZeroBuckets(
    DashboardChildSummaryRequest request,
  ) {
    if (!isComplete ||
        parentQueryKey != request.parentScope.key.value ||
        direction != request.parentScope.direction ||
        childPeriod != request.childPeriod) {
      return this;
    }
    final semanticScopes = _semanticChildScopes(request);
    if (semanticScopes.isEmpty) return this;

    final completed = <String, DashboardTimeChildSummary>{...values};
    for (final timeScope in semanticScopes) {
      final childScope = request.parentScope.copyWith(timeScope: timeScope);
      final childPeriodValue = _periodValue(timeScope);
      completed.putIfAbsent(
        childPeriodValue,
        () => DashboardTimeChildSummary(
          childPeriodValue: childPeriodValue,
          childQueryKey: childScope.key.value,
          totalMinor: 0,
          entryCount: 0,
        ),
      );
    }
    if (completed.length == values.length) return this;
    return DashboardTimeChildSummaryIndex(
      parentQueryKey: parentQueryKey,
      direction: direction,
      childPeriod: childPeriod,
      coreRevision: coreRevision,
      isComplete: true,
      values: completed,
    );
  }

  static List<LedgerTimeScope> _semanticChildScopes(
    DashboardChildSummaryRequest request,
  ) => switch ((request.childPeriod, request.parentScope.timeScope)) {
    (TimeChildPeriod.month, YearScope(:final year)) => List.generate(
      12,
      (index) => MonthScope(YearMonth(year: year, month: index + 1)),
    ),
    (TimeChildPeriod.day, MonthScope(:final value)) => List.generate(
      value.daysInMonth,
      (index) => DayScope(value.clampDay(index + 1)),
    ),
    _ => const <LedgerTimeScope>[],
  };

  static String _periodValue(LedgerTimeScope scope) => switch (scope) {
    AllTimeScope() => throw ArgumentError.value(scope, 'scope'),
    YearScope(:final year) => year.toString().padLeft(4, '0'),
    MonthScope(:final value) => value.isoString,
    DayScope(:final date) => date.isoString,
  };
}
