import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:exptv2/features/notifications/widgets/notification_log_box.dart';
import 'package:exptv2/features/notifications/widgets/notification_month_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('month header swipes between months', (tester) async {
    final shifts = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationMonthHeader(
          selectedMonth: DateTime(2026, 5),
          hasCards: true,
          onMonthShift: shifts.add,
          onClear: () {},
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('notification-month-header')),
      const Offset(-90, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026. Május'), findsOneWidget);
    expect(shifts, [1]);
  });

  testWidgets('notification logbox renders recurring card and swipe actions', (
    tester,
  ) async {
    int? readId;
    final deletedIds = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationLogBox(
          card: card(),
          onMarkRead: (id) => readId = id,
          onDelete: deletedIds.add,
        ),
      ),
    );

    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('2026.05.15 08:00'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('notification-logbox-1'))),
    );
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('notification-logbox-opacity-1')),
    );
    expect(opacity.opacity, lessThan(1));

    await gesture.moveBy(const Offset(-80, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationLogBox(
          card: card(id: 2),
          onMarkRead: (id) => readId = id,
          onDelete: deletedIds.add,
        ),
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('notification-logbox-2')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    expect(readId, isNull);
    expect(deletedIds, [1, 2]);
  });

  testWidgets('notification logbox collapses after swipe delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationLogBox(
          card: card(),
          onMarkRead: (_) {},
          onDelete: (_) {},
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('notification-logbox-1')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    final slotSize = tester.getSize(
      find.byKey(const ValueKey('notification-logbox-slot-1')),
    );
    expect(slotSize.height, 0);
  });

  testWidgets('notification logbox renders transaction and limit labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            NotificationLogBox(
              card: notificationCard(id: 20, type: 'transaction_created'),
              onMarkRead: (_) {},
              onDelete: (_) {},
            ),
            NotificationLogBox(
              card: notificationCard(id: 21, type: 'limit_75'),
              onMarkRead: (_) {},
              onDelete: (_) {},
            ),
            NotificationLogBox(
              card: notificationCard(id: 22, type: 'limit_100'),
              onMarkRead: (_) {},
              onDelete: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Új tranzakció'), findsOneWidget);
    expect(find.text('Limit 75%'), findsOneWidget);
    expect(find.text('Limit elérve'), findsOneWidget);
  });
}

ExpenseNotificationCard card({int id = 1}) => ExpenseNotificationCard.fromMap({
  'id': id,
  'type': 'recurring_transaction_alert',
  'title': 'Ismétlődő tranzakció',
  'message': 'Rent',
  'timestamp': DateTime(2026, 5, 15, 8).millisecondsSinceEpoch,
  'isRead': false,
  'isActive': true,
  'priority': 'medium',
  'categoryName': 'Lakhatás',
  'categoryColor': '#dc2626',
  'amount': 120000,
});

ExpenseNotificationCard notificationCard({
  required int id,
  required String type,
}) => ExpenseNotificationCard.fromMap({
  'id': id,
  'type': type,
  'title': 'Teszt',
  'message': 'Teszt üzenet',
  'timestamp': DateTime(2026, 5, 15, 8).millisecondsSinceEpoch,
  'isRead': false,
  'isActive': true,
  'priority': 'normal',
});
