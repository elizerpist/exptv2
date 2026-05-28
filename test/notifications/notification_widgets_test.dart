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
    int? deleteId;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationLogBox(
          card: card(),
          onMarkRead: (id) => readId = id,
          onDelete: (id) => deleteId = id,
        ),
      ),
    );

    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('notification-logbox-1')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('notification-logbox-1')),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    expect(readId, 1);
    expect(deleteId, 1);
  });
}

ExpenseNotificationCard card() => ExpenseNotificationCard.fromMap({
  'id': 1,
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
