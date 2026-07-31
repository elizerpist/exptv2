import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';

void main() {
  test('starts on income and pulses exactly once for a changed direction', () {
    final controller = TransactionDirectionController();

    expect(controller.direction, TransactionDirection.income);
    expect(controller.pulseRevision, 0);

    controller.select(TransactionDirection.expense);
    expect(controller.direction, TransactionDirection.expense);
    expect(controller.pulseRevision, 1);

    controller.select(TransactionDirection.expense);
    expect(controller.pulseRevision, 1);
  });
}
