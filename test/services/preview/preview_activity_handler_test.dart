import 'package:exptv2/services/preview/preview_activity_handler.dart';
import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PreviewNativeState state;
  late PreviewActivityHandler handler;

  setUp(() {
    state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    handler = PreviewActivityHandler(state);
  });

  tearDown(() => state.dispose());

  test('pages raw events and marks a push event as system', () async {
    final events = await handler.invoke('loadEvents', null) as List;
    expect(events, hasLength(3));
    final after =
        await handler.invoke('loadEventsAfterId', <String, Object?>{
              'afterId': 1,
            })
            as List;
    expect(after, hasLength(2));

    final page =
        await handler.invoke('loadNotificationEventPage', <String, Object?>{
              'limit': 1,
              'offset': 0,
              'query': 'BKK',
              'status': 'all',
            })
            as Map<String, Object?>;
    expect(page['totalCount'], 1);
    expect(page['events'], hasLength(1));

    expect(
      await handler.invoke('markNotificationEventSystem', <String, Object?>{
        'id': 2,
      }),
      isTrue,
    );
    final marked =
        await handler.invoke('loadNotificationEvent', <String, Object?>{
              'id': 2,
            })
            as Map<String, Object?>;
    expect(marked['status'], 'system');
    expect(marked['manualStatus'], 'system');
  });

  test('notification cards support read, delete, and month clear', () async {
    final cards =
        await handler.invoke('expenseListNotificationCards', null) as List;
    expect(cards, hasLength(3));

    expect(
      await handler.invoke('expenseMarkNotificationCardRead', <String, Object?>{
        'id': 1,
      }),
      isTrue,
    );
    expect(
      state.notificationCards.singleWhere((row) => row['id'] == 1)['isRead'],
      isTrue,
    );
    expect(
      await handler.invoke('expenseDeleteNotificationCard', <String, Object?>{
        'id': 2,
      }),
      isTrue,
    );
    expect(
      await handler.invoke('expenseClearNotificationCards', <String, Object?>{
        'monthKey': '2026-07',
      }),
      2,
    );
    expect(state.notificationCards, isEmpty);
  });

  test('recurring transaction CRUD enriches category snapshots', () async {
    final added =
        await handler
                .invoke('expenseAddRecurringTransaction', <String, Object?>{
                  'name': 'Bérlet',
                  'amount': 9500,
                  'transactionType': 'expense',
                  'dayOfMonth': 5,
                  'categoryId': 2,
                  'isActive': true,
                })
            as Map<String, Object?>;
    final id = added['id']! as int;
    expect(added['categoryName'], 'Közlekedés');

    final updated =
        await handler
                .invoke('expenseUpdateRecurringTransaction', <String, Object?>{
                  'id': id,
                  'name': 'Havi bérlet',
                  'amount': 10000,
                  'transactionType': 'expense',
                  'dayOfMonth': 6,
                  'categoryId': 2,
                  'isActive': true,
                })
            as Map<String, Object?>;
    expect(updated['name'], 'Havi bérlet');

    final toggled =
        await handler.invoke(
              'expenseToggleRecurringTransaction',
              <String, Object?>{'id': id, 'isActive': false},
            )
            as Map<String, Object?>;
    expect(toggled['isActive'], isFalse);
    expect(
      await handler.invoke(
        'expenseDeleteRecurringTransaction',
        <String, Object?>{'id': id},
      ),
      isTrue,
    );
  });

  test('recurring rule CRUD and processing are period-idempotent', () async {
    final added =
        await handler.invoke('expenseAddRecurringRule', <String, Object?>{
              'triggerType': 'date',
              'transactionType': 'expense',
              'name': 'Design tool',
              'estimatedAmount': 4200,
              'expectedDayOfMonth': 10,
              'expectedTime': '09:00',
              'categoryId': 3,
              'isActive': true,
            })
            as Map<String, Object?>;
    final id = added['id']! as int;
    expect(added['categoryName'], 'Előfizetések');

    final updated =
        await handler.invoke('expenseUpdateRecurringRule', <String, Object?>{
              ...added,
              'id': id,
              'name': 'Design suite',
            })
            as Map<String, Object?>;
    expect(updated['name'], 'Design suite');

    final first =
        await handler.invoke(
              'expenseProcessRecurringTransactions',
              <String, Object?>{
                'targetMillis': DateTime(2026, 7, 18).millisecondsSinceEpoch,
              },
            )
            as List;
    final second =
        await handler.invoke(
              'expenseProcessRecurringTransactions',
              <String, Object?>{
                'targetMillis': DateTime(2026, 7, 18).millisecondsSinceEpoch,
              },
            )
            as List;
    expect(first, isNotEmpty);
    expect(second, isEmpty);
    expect(
      first.where((row) => (row as Map)['recurringRuleId'] == id),
      hasLength(1),
    );

    final toggled =
        await handler.invoke('expenseToggleRecurringRule', <String, Object?>{
              'id': id,
              'isActive': false,
            })
            as Map<String, Object?>;
    expect(toggled['isActive'], isFalse);
    expect(
      await handler.invoke('expenseDeleteRecurringRule', <String, Object?>{
        'id': id,
      }),
      isTrue,
    );
  });

  test(
    'status is disabled, platform actions are no-ops, reset reseeds',
    () async {
      final status =
          await handler.invoke('getStatus', null) as Map<String, Object?>;
      expect(status['notificationListenerEnabled'], isFalse);
      expect(status['accessibilityEnabled'], isFalse);
      expect(status['totalEvents'], 3);

      for (final method in <String>[
        'setCaptureMode',
        'openNotificationAccessSettings',
        'openAccessibilitySettings',
        'openAppInfoSettings',
        'openAppNotificationSettings',
        'requestPostNotifications',
        'sendTestNotification',
      ]) {
        expect(await handler.invoke(method, null), isNull);
      }
      expect(
        await handler.invoke('requestPostNotificationsOnFirstLaunch', null),
        isFalse,
      );

      state.transactions.clear();
      await handler.invoke('clearDatabase', null);
      expect(state.transactions, hasLength(20));
    },
  );
}
