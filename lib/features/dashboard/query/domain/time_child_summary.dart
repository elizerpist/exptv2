import 'package:flutter/foundation.dart';

import 'current_ledger_query_scope.dart';
import 'ledger_direction.dart';

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
    required Map<String, DashboardTimeChildSummary> values,
  }) : values = Map.unmodifiable(values);

  final String parentQueryKey;
  final LedgerDirection direction;
  final TimeChildPeriod childPeriod;
  final int coreRevision;

  /// Sparse by design. A caller represents an absent compatible bucket as 0.
  final Map<String, DashboardTimeChildSummary> values;
}
