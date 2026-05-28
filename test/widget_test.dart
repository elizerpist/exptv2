import 'package:exptv2/main.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final savedTransactions = <Map<dynamic, dynamic>>[];
final updatedTransactions = <Map<dynamic, dynamic>>[];
final deletedTransactionIds = <int>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    savedTransactions.clear();
    updatedTransactions.clear();
    deletedTransactionIds.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pushparser/methods'), (
          call,
        ) async {
          if (call.method == 'loadEvents') return <Map<String, Object?>>[];
          if (call.method == 'expenseLoadBootstrap') {
            return expenseBootstrapPayload();
          }
          if (call.method == 'expenseLoadSettings') {
            return <String, Object?>{
              'themeSettings': <String, Object?>{
                'magnetType': 'fade',
                'cardColor': 'lightgray',
                'theme': 'Türkiz',
                'backgroundColor': 'gray',
                'boxColor': 'gray',
              },
              'fastInfoConfig': <String, Object?>{
                'pills': <Object?>[null, null, null],
                'boxes': <Object?>[null, null, null],
              },
            };
          }
          if (call.method == 'expenseListRecurringTransactions') {
            return <Map<String, Object?>>[];
          }
          if (call.method == 'expenseListCategories') {
            return (expenseBootstrapPayload()['categories']
                as List<Map<String, Object?>>);
          }
          if (call.method == 'expenseAddTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            savedTransactions.add(payload);
            final amount = payload['amount'] as num;
            final type = payload['type']?.toString();
            return <String, Object?>{
              'id': 250914,
              'date': payload['date'],
              'time': payload['time'],
              'merchant': payload['merchant'],
              'amount': type == 'income' ? amount : -amount.abs(),
              'userAssignedName': null,
              'transactionCategoryID': payload['transactionCategoryID'],
            };
          }
          if (call.method == 'expenseUpdateTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            updatedTransactions.add(payload);
            final amount = payload['amount'] as num;
            final type = payload['type']?.toString();
            return <String, Object?>{
              'id': payload['id'],
              'date': payload['date'],
              'time': payload['time'],
              'merchant': payload['merchant'],
              'amount': type == 'income' ? amount : -amount.abs(),
              'userAssignedName': null,
              'transactionCategoryID': payload['transactionCategoryID'],
            };
          }
          if (call.method == 'expenseDeleteTransaction') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            deletedTransactionIds.add(payload['id'] as int);
            return true;
          }
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
    final bridge = NativeBridge();
    return Exptv2App(
      store: EventStore(bridge, realtimeEnabled: false),
      nativeBridge: bridge,
    );
  }

  testWidgets('renders transaction home with bottom nav and FAB', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Kiadás'), findsOneWidget);
    expect(find.text('Bevétel'), findsOneWidget);
    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Főoldal'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Értesítések'), findsOneWidget);
    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
  });

  testWidgets('bottom nav taps switch secondary pages', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsNothing);

    await tester.tap(find.text('Értesítések'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-month-header')),
      findsOneWidget,
    );
    expect(find.text('Nincsenek értesítések'), findsOneWidget);

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();
    expect(find.text('Kiadás'), findsOneWidget);
  });

  testWidgets('FAB opens add transaction sheet on home tab', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(find.text('Tranzakció neve'), findsOneWidget);
    expect(find.text('Összeg'), findsOneWidget);
    expect(find.text('Kategória'), findsOneWidget);
  });

  testWidgets('category overlay hides shell navigation controls', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-calendar-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-menu-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsNothing);
    expect(find.byKey(const ValueKey('expt-fab')), findsNothing);
  });

  testWidgets('transaction editor is non modal and aligned to summary pill', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;
    final editorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final editorTop = editorRect.top;

    final visibleBarriers = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((barrier) => barrier.color != null);

    expect(visibleBarriers, isEmpty);
    expect(find.byType(BottomSheet), findsNothing);
    expect(editorTop, moreOrLessEquals(summaryTop, epsilon: 0.1));
    expect(
      editorRect.bottom,
      moreOrLessEquals(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
    );
  });

  testWidgets('transaction editor drags down to close', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );

    final cardTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final gesture = await tester.startGesture(
      cardTopLeft + const Offset(200, 24),
    );
    await gesture.moveBy(const Offset(0, 140));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-editor-card')), findsNothing);
  });

  testWidgets('type pills remain tappable while transaction editor is open', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bevétel'));
    await tester.pumpAndSettle();

    expect(find.text('Új bevételi tranzakció'), findsOneWidget);
  });

  testWidgets('logbox tap opens transaction editor in edit mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final logbox = tester.getRect(
      find.byKey(const ValueKey('transaction-logbox-card-250909')),
    );
    await tester.tapAt(logbox.centerRight - const Offset(24, 0));
    await tester.pumpAndSettle();

    expect(find.text('Kiadási tranzakció módosítása'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
  });

  testWidgets('right swipe asks before deleting a transaction', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-250909')),
      const Offset(160, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tranzakció törlése'), findsOneWidget);
    expect(find.text('Törlés'), findsOneWidget);

    await tester.tap(find.text('Törlés'));
    await tester.pumpAndSettle();

    expect(deletedTransactionIds, [250909]);
  });

  testWidgets('add transaction sheet saves through native bridge', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'New Shop',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '42');
    await tester.ensureVisible(find.text('Mentés'));
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    expect(savedTransactions, hasLength(1));
    expect(savedTransactions.single['merchant'], 'New Shop');
    expect(savedTransactions.single['amount'], 42.0);
    expect(savedTransactions.single['type'], 'expense');
    expect(savedTransactions.single['transactionCategoryID'], 6);
  });

  testWidgets('settings contains push parser app filter input and app picker', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    await tester.tap(find.text('Megfigyelni kívánt alkalmazás'));
    await tester.pumpAndSettle();

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

Map<String, Object?> expenseBootstrapPayload() {
  final transactions = <Map<String, Object?>>[
    if (!deletedTransactionIds.contains(250909))
      <String, Object?>{
        'id': 250909,
        'date': '2025.09.25',
        'time': '20:30:00',
        'merchant': 'Test Store',
        'amount': -505,
        'userAssignedName': null,
        'transactionCategoryID': 6,
      },
  ];
  if (savedTransactions.isNotEmpty) {
    final payload = savedTransactions.last;
    final amount = payload['amount'] as num;
    transactions.insert(0, <String, Object?>{
      'id': 250914,
      'date': payload['date'],
      'time': payload['time'],
      'merchant': payload['merchant'],
      'amount': -amount.abs(),
      'userAssignedName': null,
      'transactionCategoryID': payload['transactionCategoryID'],
    });
  }

  return <String, Object?>{
    'categories': <Map<String, Object?>>[
      <String, Object?>{
        'transactionCategoryID': 5,
        'name': 'Rr',
        'type': 'bevétel',
        'colorSlot': 2,
        'iconSlot': 0,
        'backgroundColor': '#3b82f6',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
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
    ],
    'transactions': transactions,
  };
}
