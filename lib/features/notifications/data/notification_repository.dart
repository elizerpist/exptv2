import '../../../services/native_bridge.dart';
import '../models/expense_notification_card.dart';

abstract class NotificationRepositoryContract {
  Future<List<ExpenseNotificationCard>> listCards();
  Future<bool> markRead(int id);
  Future<bool> deleteCard(int id);
  Future<int> clearCards({String? monthKey});
}

class NotificationRepository implements NotificationRepositoryContract {
  const NotificationRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<List<ExpenseNotificationCard>> listCards() {
    return _bridge.expenseListNotificationCards();
  }

  @override
  Future<bool> markRead(int id) {
    return _bridge.expenseMarkNotificationCardRead(id);
  }

  @override
  Future<bool> deleteCard(int id) {
    return _bridge.expenseDeleteNotificationCard(id);
  }

  @override
  Future<int> clearCards({String? monthKey}) {
    return _bridge.expenseClearNotificationCards(monthKey: monthKey);
  }
}
