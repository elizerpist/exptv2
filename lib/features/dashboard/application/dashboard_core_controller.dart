import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';
import '../query/application/current_query_controller.dart';
import '../query/data/dashboard_ledger_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/time_plane.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
  })  : expansion = DashboardExpansionController(metrics: metrics),
        rail = DashboardRailController(
          initialDate: initialDate,
          initialPlane: TimePlane.month,
        ),
        transactionDirection = TransactionDirectionController() {
    query = CurrentQueryController(
      repository: queryRepository ?? const EmptyDashboardLedgerRepository(),
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: rail.state.effectiveScope,
      ),
    );
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_handleRailChanged);
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

  void _forwardChildNotification() => notifyListeners();

  void _handleRailChanged() {
    final previousScope = query.state.scope.timeScope;
    query.setTimeScope(rail.state.effectiveScope);
    if (previousScope != rail.state.effectiveScope) return;
    notifyListeners();
  }

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
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    query.dispose();
    super.dispose();
  }
}
