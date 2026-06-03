import 'package:exptv2/features/notifications/notifications_page.dart';
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

    await tester.pumpWidget(
      MaterialApp(home: NotificationsPage(nativeBridge: bridge, active: true)),
    );
    await tester.pumpAndSettle();

    expect(listCalls, 1);
    expect(find.text('Nincsenek értesítések'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: NotificationsPage(nativeBridge: bridge, active: false)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(home: NotificationsPage(nativeBridge: bridge, active: true)),
    );
    await tester.pumpAndSettle();

    expect(listCalls, 2);
    expect(find.text('Limit elérve'), findsOneWidget);
  });
}
