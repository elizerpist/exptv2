import 'package:exptv2/features/settings/settings_page.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/settings_page_methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{
                  'magnetType': 'fade',
                  'cardColor': 'lightgray',
                  'theme': 'Türkiz',
                  'backgroundColor': 'gray',
                  'boxColor': 'gray',
                },
                'fastInfoConfig': <String, Object?>{
                  'pills': <Object?>[
                    <String, Object?>{
                      'id': 'megtakaritas',
                      'label': 'Megtakarítás',
                      'value': '156,780 Ft',
                      'type': 'pill',
                    },
                    null,
                    null,
                  ],
                  'boxes': <Object?>[
                    <String, Object?>{
                      'id': 'mai_nap',
                      'label': 'Mai nap',
                      'value': '2 db',
                      'extra': '-4,500 Ft',
                      'type': 'box',
                    },
                    null,
                    null,
                  ],
                },
              };
            case 'expenseListRecurringTransactions':
              return <Map<String, Object?>>[
                recurringRow(),
              ];
            case 'expenseListCategories':
              return <Map<String, Object?>>[
                <String, Object?>{
                  'transactionCategoryID': 6,
                  'name': 'Q',
                  'type': 'kiadás',
                  'colorSlot': 7,
                  'iconSlot': 2,
                  'backgroundColor': '#dc2626',
                  'hasLimit': false,
                  'limitAmount': 0,
                  'alertActive': false,
                  'isCustomIcon': true,
                },
              ];
            case 'listInstalledApps':
              return <Map<String, Object?>>[];
            case 'getStatus':
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
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildSubject() {
    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_page_events'),
    );
    return MaterialApp(
      home: SettingsPage(
        store: EventStore(bridge, realtimeEnabled: false),
        nativeBridge: bridge,
      ),
    );
  }

  testWidgets('renders original settings sections', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.text('Alkalmazás beállítások'), findsOneWidget);
    expect(find.text('Megjelenítési beállítások'), findsOneWidget);
    expect(find.text('Adatkezelés'), findsOneWidget);
    expect(find.text('Értesítési beállítások'), findsOneWidget);
    expect(find.text('Adatvédelem és biztonság'), findsOneWidget);
    expect(find.text('Visszajelzések'), findsOneWidget);
    expect(find.text('Információ és támogatás'), findsOneWidget);
  });

  testWidgets('opens theme, FastInfo, and recurring submenus', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Téma'));
    await tester.pumpAndSettle();
    expect(find.text('Téma Beállítások'), findsOneWidget);
    expect(find.text('Mágneskártya'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('FastInfo'));
    await tester.pumpAndSettle();
    expect(find.text('FastInfo'), findsOneWidget);
    expect(find.text('Pill slot 1'), findsOneWidget);
    expect(find.text('Box slot 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ismétlődő tranzakciók'));
    await tester.pumpAndSettle();
    expect(find.text('Ismétlődő tranzakciók'), findsOneWidget);
    expect(find.text('Új ismétlődő kiadás hozzáadása'), findsOneWidget);
    expect(find.text('Lakbér'), findsOneWidget);

    final colorDot = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('recurring-category-color-7')),
        matching: find.byType(Container),
      ),
    );
    final decoration = colorDot.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF0EA5E9));
  });
}

Map<String, Object?> recurringRow() {
  return <String, Object?>{
    'id': 7,
    'name': 'Lakbér',
    'amount': 165000,
    'transactionType': 'expense',
    'dayOfMonth': 1,
    'categoryId': 6,
    'categoryName': 'Q',
    'categoryColor': '#dc2626',
    'categoryIconSlot': 2,
    'isActive': true,
    'createdAt': 1777593600000,
    'updatedAt': 1777593600000,
  };
}
