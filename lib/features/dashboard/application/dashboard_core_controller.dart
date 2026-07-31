import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
  })  : expansion = DashboardExpansionController(metrics: metrics),
        rail = DashboardRailController(),
        transactionDirection = TransactionDirectionController() {
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_forwardChildNotification);
    transactionDirection.addListener(_forwardChildNotification);
  }

  /// The single metric source shared by dashboard geometry and expansion state.
  final DashboardLayoutMetrics metrics;

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;

  void _forwardChildNotification() => notifyListeners();

  @override
  void dispose() {
    expansion.removeListener(_forwardChildNotification);
    rail.removeListener(_forwardChildNotification);
    transactionDirection.removeListener(_forwardChildNotification);
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    super.dispose();
  }
}
