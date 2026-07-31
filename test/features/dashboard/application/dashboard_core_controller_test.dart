import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';

void main() {
  test('forwards every owned child state notification to core listeners', () {
    final core = DashboardCoreController();
    var notifications = 0;
    core.addListener(() => notifications += 1);

    core.expansion.setProgress(1);
    core.rail.setExpanded(true);
    core.transactionDirection.select(TransactionDirection.expense);

    expect(notifications, 3);
    core.dispose();
  });
}
