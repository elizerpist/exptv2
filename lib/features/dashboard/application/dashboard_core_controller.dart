import 'package:flutter/foundation.dart';

import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController()
      : expansion = DashboardExpansionController(),
        rail = DashboardRailController(),
        transactionDirection = TransactionDirectionController();

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;

  @override
  void dispose() {
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    super.dispose();
  }
}
