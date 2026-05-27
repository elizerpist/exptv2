import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushparserv2/main.dart';
import 'package:pushparserv2/services/native_bridge.dart';
import 'package:pushparserv2/state/event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pushparser/methods'), (call) async {
      if (call.method == 'loadEvents') return <Map<String, Object?>>[];
      if (call.method == 'listInstalledApps') {
        return <Map<String, Object?>>[
          <String, Object?>{
            'packageName': 'com.mand.notitest',
            'label': 'Notification Test',
            'iconBase64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
          },
        ];
      }
      if (call.method == 'getStatus') {
        return <String, Object?>{
          'captureMode': 'both',
          'notificationListenerEnabled': false,
          'accessibilityEnabled': false,
          'notificationListenerActive': false,
          'accessibilityActive': false,
          'lastNotificationListenerEvent': 0,
          'lastAccessibilityEvent': 0,
          'totalEvents': 0,
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pushparser/methods'), null);
  });



  testWidgets('app picker shows icons and selects app label for filtering', (tester) async {
    await tester.pumpWidget(PushParserApp(
      store: EventStore(NativeBridge(), realtimeEnabled: false),
    ));
    await tester.pump();

    await tester.tap(find.byTooltip('Pick installed app'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('Notification Test'));
    await tester.pumpAndSettle();

    expect(find.text('Notification Test'), findsOneWidget);
    expect(find.text(r'^com\.mand\.notitest$'), findsNothing);
    final filterSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(filterSwitch.value, isTrue);
  });

  testWidgets('app renders main title and permission setup', (tester) async {
    await tester.pumpWidget(PushParserApp(
      store: EventStore(NativeBridge(), realtimeEnabled: false),
    ));
    await tester.pump();
    expect(find.text('PushParserV2'), findsOneWidget);
    expect(find.text('Permission setup'), findsOneWidget);
    expect(find.textContaining('Restricted settings'), findsOneWidget);
    expect(find.text('Open app info'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
