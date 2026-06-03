import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses recurring notification card from native map', () {
    final card = ExpenseNotificationCard.fromMap({
      'id': 7,
      'type': 'recurring_transaction_alert',
      'title': 'Ismétlődő tranzakció',
      'message': 'Rent automatikusan hozzáadva',
      'timestamp': 1778803200000,
      'isRead': false,
      'isActive': true,
      'priority': 'medium',
      'categoryId': 6,
      'categoryName': 'Lakhatás',
      'categoryColor': '#dc2626',
      'categoryIconSlot': 2,
      'recurringTransactionId': 9,
      'transactionId': 26051501,
      'amount': 120000,
      'triggerDate': '2026-05-15T00:00:00.000',
      'nextDueDate': '2026-06-15T00:00:00.000',
      'createdAt': 1778803200000,
      'updatedAt': 1778803200000,
    });

    expect(card.type, ExpenseNotificationType.recurringTransactionAlert);
    expect(card.monthKey, '2026-05');
    expect(card.categoryName, 'Lakhatás');
    expect(card.amount, 120000);
  });

  test('parses transaction and limit notification card types', () {
    final transaction = ExpenseNotificationCard.fromMap({
      'id': 8,
      'type': 'transaction_created',
      'title': 'Új tranzakció',
      'message': 'Tesco - 4200 Ft',
      'timestamp': 1778803200000,
      'isRead': false,
      'isActive': true,
      'priority': 'normal',
    });
    final limit75 = ExpenseNotificationCard.fromMap({
      'id': 9,
      'type': 'limit_75',
      'title': 'Limit 75%',
      'message': '12000 Ft maradt a limitből',
      'timestamp': 1778803200000,
      'isRead': false,
      'isActive': true,
      'priority': 'warning',
    });
    final limit100 = ExpenseNotificationCard.fromMap({
      'id': 10,
      'type': 'limit_100',
      'title': 'Limit elérve',
      'message': '3000 Ft-tal túllépted a limitet',
      'timestamp': 1778803200000,
      'isRead': false,
      'isActive': true,
      'priority': 'critical',
    });

    expect(transaction.type, ExpenseNotificationType.transactionCreated);
    expect(limit75.type, ExpenseNotificationType.limit75);
    expect(limit100.type, ExpenseNotificationType.limit100);
  });
}
