import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_repository.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/scope_summary_metrics.dart';

/// The immutable identity shared by a LogBox page and its aggregate metrics.
///
/// The committed and presentation-only preview variants both obey this exact
/// query key/revision boundary. Preview cannot write the query; it can only
/// select an already warmed page which matches its immutable metrics.
abstract interface class DashboardLogQuerySnapshot {
  CurrentLedgerQueryScope get queryContext;
  ScopeSummaryMetrics get summaryMetrics;
}

/// The canonical identity emitted after a committed query/cache selection.
@immutable
class DashboardCommittedQuerySnapshot implements DashboardLogQuerySnapshot {
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
    assert(
      result.direction == null || result.direction == scope.direction.name,
    );
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

  @override
  final CurrentLedgerQueryScope queryContext;
  @override
  final ScopeSummaryMetrics summaryMetrics;
}

/// A read-only rail-preview identity. It is legal only when its page came
/// from the same canonical key and revision in the bounded first-page cache.
@immutable
class DashboardPreviewQuerySnapshot implements DashboardLogQuerySnapshot {
  DashboardPreviewQuerySnapshot({
    required this.queryContext,
    required this.summaryMetrics,
  }) : assert(summaryMetrics.scope == queryContext),
       assert(summaryMetrics.canonicalQueryKey == queryContext.key.value),
       assert(summaryMetrics.source == SummaryMetricsSource.childPreviewIndex);

  @override
  final CurrentLedgerQueryScope queryContext;
  @override
  final ScopeSummaryMetrics summaryMetrics;
}
