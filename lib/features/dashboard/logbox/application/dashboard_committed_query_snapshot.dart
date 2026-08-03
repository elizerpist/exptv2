import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/scope_summary_metrics.dart';

/// The immutable committed identity shared by LogBox rows and their aggregate.
///
/// SummaryPill may separately show a rail-preview metrics projection. This
/// snapshot is deliberately committed-only: a LogBox never changes during a
/// child preview and therefore cannot be relabelled under an uncommitted scope.
@immutable
class DashboardCommittedQuerySnapshot {
  DashboardCommittedQuerySnapshot({
    required this.queryContext,
    required this.summaryMetrics,
  }) : assert(summaryMetrics.scope == queryContext),
       assert(summaryMetrics.canonicalQueryKey == queryContext.key.value);

  factory DashboardCommittedQuerySnapshot.fromResult({
    required CurrentLedgerQueryScope scope,
    required DashboardLedgerResult result,
  }) {
    assert(result.scopeKey == scope.key.value);
    assert(
      result.timeScopeKey == null ||
          result.timeScopeKey == scope.timeScope.canonicalKey,
    );
    assert(result.direction == null || result.direction == scope.direction.name);
    return DashboardCommittedQuerySnapshot(
      queryContext: scope,
      summaryMetrics: ScopeSummaryMetrics(
        scope: scope,
        canonicalQueryKey: scope.key.value,
        coreRevision: result.coreRevision,
        totalMinor: result.totalMinor,
        entryCount: result.entryCount,
        source: SummaryMetricsSource.freshQuery,
        isLoading: false,
        isStale: false,
        hasError: false,
      ),
    );
  }

  final CurrentLedgerQueryScope queryContext;
  final ScopeSummaryMetrics summaryMetrics;
}
