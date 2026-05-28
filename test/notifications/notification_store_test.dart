import 'package:exptv2/features/notifications/data/notification_repository.dart';
import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:exptv2/features/notifications/state/notification_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store filters active cards by selected month and groups by date',
    () async {
      final store = NotificationStore(
        FakeNotificationRepository(),
        clock: () => DateTime(2026, 5, 15),
      );

      await store.start();

      expect(store.selectedMonthKey, '2026-05');
      expect(store.visibleCards, hasLength(2));
      expect(store.groupedCards.keys, ['2026.05.15', '2026.05.10']);
    },
  );

  test('mark read and delete reload card state', () async {
    final repository = FakeNotificationRepository();
    final store = NotificationStore(
      repository,
      clock: () => DateTime(2026, 5, 15),
    );
    await store.start();

    await store.markRead(1);
    await store.deleteCard(2);

    expect(repository.readIds, [1]);
    expect(repository.deletedIds, [2]);
  });
}

class FakeNotificationRepository implements NotificationRepositoryContract {
  final readIds = <int>[];
  final deletedIds = <int>[];

  @override
  Future<List<ExpenseNotificationCard>> listCards() async => [
    card(1, 15),
    card(2, 10),
    card(3, 1, month: 4),
  ];

  @override
  Future<bool> markRead(int id) async {
    readIds.add(id);
    return true;
  }

  @override
  Future<bool> deleteCard(int id) async {
    deletedIds.add(id);
    return true;
  }

  @override
  Future<int> clearCards({String? monthKey}) async => 2;
}

ExpenseNotificationCard card(int id, int day, {int month = 5}) {
  return ExpenseNotificationCard.fromMap({
    'id': id,
    'type': 'recurring_transaction_alert',
    'title': 'Ismétlődő tranzakció',
    'message': 'Rent',
    'timestamp': DateTime(2026, month, day, 8).millisecondsSinceEpoch,
    'isRead': false,
    'isActive': true,
    'priority': 'medium',
  });
}
