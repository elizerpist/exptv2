import 'package:flutter/foundation.dart';

import '../query/domain/scope_summary_metrics.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/time_child_summary.dart';

/// Narrow read-only boundary between summary preview ownership and consumers
/// that can project the same immutable metrics into another presentation.
///
/// The source never transfers query ownership: consumers may observe a
/// displayed scope but cannot commit it, start a watch, or mutate the rail.
abstract interface class DashboardSummaryMetricsSource implements Listenable {
  ScopeSummaryMetrics? get metrics;
  DashboardTimeChildSummaryIndex? get index;

  /// A compatible child index remains available for data warming even while
  /// the rail is closed and the rendered metrics correctly show the parent.
  DashboardTimeChildSummaryIndex? get readyIndex;
  CurrentLedgerQueryScope? get readyParentScope;
}
