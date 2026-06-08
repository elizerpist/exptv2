import 'package:exptv2/features/settings/widgets/push_log/push_notification_log_page.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_panel_metrics.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/push_log_page_methods');
  const eventChannel = EventChannel('test/push_log_page_events');
  final pageQueries = <Map<dynamic, dynamic>>[];

  setUp(() {
    pageQueries.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          switch (call.method) {
            case 'loadEvents':
              return <Map<String, Object?>>[];
            case 'getStatus':
              return <String, Object?>{
                'captureMode': 'both',
                'notificationListenerEnabled': true,
                'accessibilityEnabled': false,
                'notificationListenerActive': true,
                'accessibilityActive': false,
                'lastNotificationListenerEvent': 0,
                'lastAccessibilityEvent': 0,
                'totalEvents': 2,
              };
            case 'loadNotificationParserProfiles':
              return profilePayload();
            case 'listInstalledApps':
              return <Map<String, Object?>>[
                <String, Object?>{
                  'packageName': 'hu.bank.app',
                  'label': 'Bank',
                  'iconBase64':
                      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
                },
              ];
            case 'loadNotificationEventPage':
              final args = Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              );
              pageQueries.add(args);
              final offset = args['offset'] as int? ?? 0;
              if (offset == 0) {
                return <String, Object?>{
                  'events': List<Object?>.generate(8, (index) {
                    return pushLogEventRow(
                      id: 77 + index,
                      appLabel: index == 0 ? 'Bank' : 'Bank $index',
                      text: index == 0
                          ? 'Kártyás vásárlás: Tesco - 12 345 HUF. '
                                'Ez egy hosszabb értesítés, ami nem növelheti '
                                'meg a logbox magasságát.'
                          : 'Kártyás vásárlás: Bolt $index - 1 000 HUF',
                      status: 'missing',
                      statusText: 'Nincs hozzárendelt log',
                    );
                  }),
                  'totalCount': 9,
                  'limit': args['limit'],
                  'offset': offset,
                };
              }
              return <String, Object?>{
                'events': <Object?>[
                  pushLogEventRow(
                    id: 90,
                    appLabel: 'Wallet',
                    text: 'Kártyás vásárlás: Spar - 4 500 HUF',
                    status: 'linked',
                    statusText: 'Van tranzakció',
                    linkedTransactionId: 26060702,
                  ),
                ],
                'totalCount': 9,
                'limit': args['limit'],
                'offset': offset,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  Widget buildSubject({
    Future<void> Function(int transactionId)? onOpenTransaction,
  }) {
    final bridge = NativeBridge(
      methodChannel: methodChannel,
      eventChannel: eventChannel,
    );
    return MaterialApp(
      home: Scaffold(
        body: PushNotificationLogPage(
          nativeBridge: bridge,
          parserStore: EventStore(bridge, realtimeEnabled: false),
          onOpenTransaction: onOpenTransaction,
        ),
      ),
    );
  }

  testWidgets('renders captured push events and status filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('push-notification-log-list')),
      findsOneWidget,
    );
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Nincs hozzárendelt log'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('push-logbox-77')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    final firstBox = tester.getRect(
      find.byKey(const ValueKey('push-logbox-77')),
    );
    expect(firstBox.height, 102);
    expect(find.text('Összes'), findsOneWidget);
    expect(find.text('Van tranzakció'), findsOneWidget);
    expect(find.text('Rendszer'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('push-log-search')),
      'tesco',
    );
    await tester.pumpAndSettle();

    expect(pageQueries.last['query'], 'tesco');
    expect(pageQueries.last['offset'], 0);
  });

  testWidgets('loads more push events near the bottom of the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('push-notification-log-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(pageQueries.map((query) => query['offset']).toList(), <int>[0, 8]);
  });

  testWidgets('linked event sheet opens the linked transaction', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? openedTransactionId;

    await tester.pumpWidget(
      buildSubject(
        onOpenTransaction: (transactionId) async {
          openedTransactionId = transactionId;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('push-notification-log-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('push-logbox-90')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('push-logbox-90')));
    await tester.pumpAndSettle();

    expect(find.text('Ugrás a tranzakcióhoz'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('push-event-open-transaction')));
    await tester.pumpAndSettle();

    expect(openedTransactionId, 26060702);
    expect(find.byKey(const ValueKey('push-event-sheet')), findsNothing);
  });

  testWidgets('event sheet shows final training actions without separate create button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('push-logbox-77')));
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('push-event-sheet')),
    );
    expect(
      sheetRect.height,
      moreOrLessEquals(
        SlideUpPanelMetrics.fullHeightForScreen(1200),
        epsilon: 1,
      ),
    );
    expect(
      find.byKey(const ValueKey('push-event-sheet-drag-handle')),
      findsOneWidget,
    );
    expect(find.text('Tanítás és log létrehozása'), findsOneWidget);
    expect(find.text('Rendszerüzenetként jelölés'), findsOneWidget);
    expect(find.text('Bezárás'), findsOneWidget);
    expect(find.text('Log létrehozása'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('push-event-sheet-drag-handle')),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-event-sheet')), findsNothing);
  });
}

Map<String, Object?> profilePayload() {
  return <String, Object?>{
    'profiles': <Object?>[
      <String, Object?>{
        'id': 'bank-a',
        'name': 'Bank A',
        'enabled': true,
        'appFilterText': r'^Bank A$',
        'packageName': 'hu.bank.app',
        'appLabel': 'Bank',
        'sampleText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
        'includeKeyword': '',
        'amountPattern': r'(?<amount>\d[\d\s]*)\s*HUF',
        'merchantPattern': r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
      },
    ],
  };
}

Map<String, Object?> pushLogEventRow({
  required int id,
  required String appLabel,
  required String text,
  required String status,
  required String statusText,
  int? linkedTransactionId,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': DateTime(2026, 6, 7, 21, 10).millisecondsSinceEpoch,
    'source': 'notification_listener',
    'packageName': 'hu.bank.app',
    'appLabel': appLabel,
    'title': 'Vásárlás',
    'text': text,
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': 'n-$id',
    'accessibilityEventType': '',
    'hash': 'h-$id',
    'isDuplicate': false,
    'manualStatus': '',
    'displayText': text,
    'status': status,
    'statusText': statusText,
    'linkedTransactionId': linkedTransactionId,
  };
}
