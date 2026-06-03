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

  test(
    'unread count tracks active unread cards and can mark them all read',
    () async {
      final repository = FakeNotificationRepository(
        cards: [
          card(1, 15),
          card(2, 10, isRead: true),
          card(3, 1, month: 4),
          card(4, 15, isActive: false),
        ],
      );
      final store = NotificationStore(
        repository,
        clock: () => DateTime(2026, 5, 15),
      );

      await store.start();

      expect(store.unreadCount, 2);

      await store.markAllUnreadRead();

      expect(repository.readIds, [1, 3]);
      expect(store.unreadCount, 0);
    },
  );
}

class FakeNotificationRepository implements NotificationRepositoryContract {
  FakeNotificationRepository({List<ExpenseNotificationCard>? cards})
    : _cards = cards ?? [card(1, 15), card(2, 10), card(3, 1, month: 4)];

  final readIds = <int>[];
  final deletedIds = <int>[];
  final List<ExpenseNotificationCard> _cards;

  @override
  Future<List<ExpenseNotificationCard>> listCards() async => _cards
      .where((card) => !deletedIds.contains(card.id))
      .map(
        (card) =>
            readIds.contains(card.id) ? copyCard(card, isRead: true) : card,
      )
      .toList();

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

ExpenseNotificationCard card(
  int id,
  int day, {
  int month = 5,
  bool isRead = false,
  bool isActive = true,
}) {
  return ExpenseNotificationCard.fromMap({
    'id': id,
    'type': 'recurring_transaction_alert',
    'title': 'Ismétlődő tranzakció',
    'message': 'Rent',
    'timestamp': DateTime(2026, month, day, 8).millisecondsSinceEpoch,
    'isRead': isRead,
    'isActive': isActive,
    'priority': 'medium',
  });
}

ExpenseNotificationCard copyCard(
  ExpenseNotificationCard source, {
  bool? isRead,
}) {
  return ExpenseNotificationCard(
    id: source.id,
    type: source.type,
    title: source.title,
    message: source.message,
    timestamp: source.timestamp,
    isRead: isRead ?? source.isRead,
    isActive: source.isActive,
    priority: source.priority,
    categoryId: source.categoryId,
    categoryName: source.categoryName,
    categoryColor: source.categoryColor,
    categoryIconSlot: source.categoryIconSlot,
    recurringTransactionId: source.recurringTransactionId,
    transactionId: source.transactionId,
    amount: source.amount,
    triggerDate: source.triggerDate,
    nextDueDate: source.nextDueDate,
    createdAt: source.createdAt,
    updatedAt: source.updatedAt,
  );
}
