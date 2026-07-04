import 'package:exptv2/features/notifications/notifications_page.dart';
import 'package:exptv2/features/notifications/data/notification_repository.dart';
import 'package:exptv2/features/notifications/state/notification_store.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/notifications_page_methods');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('reloads cards when the notifications tab becomes active', (
    tester,
  ) async {
    var listCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'expenseListNotificationCards') {
            listCalls += 1;
            if (listCalls == 1) return <Map<String, Object?>>[];
            return <Map<String, Object?>>[
              <String, Object?>{
                'id': 5,
                'type': 'limit_100',
                'title': 'Limit elérve',
                'message': 'Kiadási budget: 10 000 Ft-tal túllépted a limitet.',
                'timestamp': DateTime(2026, 6, 3, 17).millisecondsSinceEpoch,
                'isRead': false,
                'isActive': true,
                'priority': 'critical',
              },
            ];
          }
          return null;
        });

    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/notifications_page_events'),
    );
    final store = NotificationStore(
      NotificationRepository(bridge),
      clock: () => DateTime(2026, 6, 3),
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          nativeBridge: bridge,
          store: store,
          active: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(listCalls, 1);
    expect(find.text('Nincsenek értesítések'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          nativeBridge: bridge,
          store: store,
          active: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          nativeBridge: bridge,
          store: store,
          active: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(listCalls, 3);
    expect(find.text('Limit elérve'), findsOneWidget);
  });

  testWidgets('marks unread cards read when notifications tab becomes active', (
    tester,
  ) async {
    final readIds = <int>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'expenseListNotificationCards') {
            return <Map<String, Object?>>[
              <String, Object?>{
                'id': 7,
                'type': 'limit_75',
                'title': 'Limit 75%',
                'message': 'A limit 75%-át elérted.',
                'timestamp': DateTime(2026, 6, 3, 17).millisecondsSinceEpoch,
                'isRead': readIds.contains(7),
                'isActive': true,
                'priority': 'high',
              },
            ];
          }
          if (call.method == 'expenseMarkNotificationCardRead') {
            final args = call.arguments as Map<dynamic, dynamic>;
            readIds.add(args['id'] as int);
            return true;
          }
          return null;
        });

    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/notifications_page_events'),
    );
    final store = NotificationStore(
      NotificationRepository(bridge),
      clock: () => DateTime(2026, 6, 3),
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          nativeBridge: bridge,
          store: store,
          active: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(readIds, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsPage(
          nativeBridge: bridge,
          store: store,
          active: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(readIds, [7]);
    expect(find.text('Limit 75%'), findsOneWidget);
  });
}
