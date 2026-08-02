import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_summary_amount_controller.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';
import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/data/dashboard_ledger_repository.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/time_plane.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       rail = DashboardRailController(
         initialDate: initialDate,
         initialPlane: TimePlane.month,
       ),
       transactionDirection = TransactionDirectionController() {
    final repository =
        queryRepository ?? const EmptyDashboardLedgerRepository();
    query = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: rail.state.effectiveScope,
      ),
    );
    summaryMetrics = DashboardSummaryMetricsController(
      navigation: rail,
      query: query,
      childSummaryRepository: repository is DashboardChildSummaryRepository
          ? repository as DashboardChildSummaryRepository
          : null,
    );
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_handleRailChanged);
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    transactionDirection.addListener(_handleDirectionChanged);
    query.addListener(_forwardChildNotification);
    query.refresh();
  }

  /// The single metric source shared by dashboard geometry and expansion state.
  final DashboardLayoutMetrics metrics;

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;
  late final CurrentQueryController query;
  late final DashboardSummaryMetricsController summaryMetrics;
  late int _lastHandledRailNavigationRevision;

  void _forwardChildNotification() => notifyListeners();

  void _handleRailChanged() {
    // Preview is presentation-only. Let the SummaryPill observe the rail
    // directly, but keep it out of the aggregate dashboard listener so a
    // fast child fling cannot rebuild the motion host, amount region or query
    // pipeline for every crossed index.
    if (rail.state.navigationRevision == _lastHandledRailNavigationRevision) {
      return;
    }
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    final previousScope = query.state.scope.timeScope;
    final nextScope = rail.state.effectiveScope;
    if (previousScope != nextScope) {
      DashboardSummaryTimingDebug.mark(
        'S4 effectiveScopeEmitted',
        value: nextScope,
      );
      DashboardQueryDebug.mark(
        'R4 QUERY_SCOPE_COMMITTED',
        scope: query.state.scope.copyWith(timeScope: nextScope),
        detail: 'reason=${_railQueryReason()}',
      );
      query.setTimeScope(nextScope, reason: _railQueryReason());
      DashboardSummaryTimingDebug.mark('S5 queryScopeSet', value: nextScope);
      return;
    }
    // A committed plane/data-source transition can leave the canonical scope
    // unchanged. It still needs one dashboard rebuild, unlike preview.
    notifyListeners();
  }

  String _railQueryReason() => switch (rail.state.lastChange.kind) {
    DashboardTimeNavigationChangeKind.rail =>
      rail.state.isRailOpen ? 'railOpened' : 'railClosed',
    DashboardTimeNavigationChangeKind.plane => 'planeCommitted',
    DashboardTimeNavigationChangeKind.parent => 'parentCommitted',
    DashboardTimeNavigationChangeKind.child => 'childSettled',
    DashboardTimeNavigationChangeKind.initial => 'initial',
  };

  void _handleDirectionChanged() {
    query.setDirection(
      transactionDirection.direction == TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense,
    );
  }

  @override
  void dispose() {
    expansion.removeListener(_forwardChildNotification);
    rail.removeListener(_handleRailChanged);
    transactionDirection.removeListener(_handleDirectionChanged);
    query.removeListener(_forwardChildNotification);
    summaryMetrics.dispose();
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    query.dispose();
    super.dispose();
  }
}
