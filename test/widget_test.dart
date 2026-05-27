import 'package:exptv2/main.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pushparser/methods'), (
          call,
        ) async {
          if (call.method == 'loadEvents') return <Map<String, Object?>>[];
          if (call.method == 'listInstalledApps') {
            return <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'com.mand.notitest',
                'label': 'Notification Test',
                'iconBase64':
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
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
        .setMockMethodCallHandler(
          const MethodChannel('pushparser/methods'),
          null,
        );
  });

  Widget buildApp() {
    return Exptv2App(store: EventStore(NativeBridge(), realtimeEnabled: false));
  }

  testWidgets('renders blank shell with bottom nav and FAB', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byKey(const ValueKey('blank-page-home')), findsOneWidget);
    expect(find.text('Főoldal'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Értesítések'), findsOneWidget);
    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
  });

  testWidgets('bottom nav taps switch blank pages', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blank-page-groceries')), findsOneWidget);

    await tester.tap(find.text('Értesítések'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('blank-page-notifications')),
      findsOneWidget,
    );

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('blank-page-home')), findsOneWidget);
  });

  testWidgets('settings contains push parser app filter input and app picker', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('App regex'), findsOneWidget);
    expect(find.byTooltip('Pick installed app'), findsOneWidget);

    await tester.tap(find.byTooltip('Pick installed app'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('Notification Test'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsOneWidget);
  });
}
