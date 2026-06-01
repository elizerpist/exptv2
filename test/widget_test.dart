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
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

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

  testWidgets('FAB opens add transaction sheet from any bottom tab', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    await _tapFab(tester);

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(find.text('Tranzakció neve'), findsOneWidget);
    expect(find.text('Összeg'), findsOneWidget);
    expect(find.text('Kategória'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('transaction-date-picker-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-time-picker-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
  });

  testWidgets('FAB long press opens the new category editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Új kiadási kategória'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
  });

  testWidgets('FAB double tap opens the budget limit editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('budget-target-editor-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
  });

  testWidgets('transaction category field opens inline scroll picker', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    await tester.tap(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-menu-overlay')), findsNothing);
    expect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );

    final editorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
    );
    expect(pickerRect.height, greaterThanOrEqualTo(204));
    expect(pickerRect.bottom, lessThanOrEqualTo(editorRect.bottom - 8));

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
    );
    await tester.pumpAndSettle();

    final beforeDrag = _slideCardTranslationY(tester);
    await tester.drag(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      const Offset(0, 120),
    );
    await tester.pump();
    expect(
      _slideCardTranslationY(tester),
      moreOrLessEquals(beforeDrag, epsilon: 0.1),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-category-option-6')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-category-option-6')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
    );
    expect(find.text('Q'), findsWidgets);
  });

  testWidgets('category overlay keeps shell navigation controls visible', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('header-calendar-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-menu-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);

    expect(
      find.byKey(const ValueKey('category-menu-back-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-add-button')),
      findsNothing,
    );
  });

  testWidgets('transaction editor is focused and aligned to summary pill', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;
    final editorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final editorTop = editorRect.top;

    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(editorTop, greaterThan(summaryTop + 20));
    expect(
      editorRect.bottom,
      moreOrLessEquals(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
    );
    expect(editorRect.height, lessThan(600));
  });

  testWidgets('transaction editor drags down to close', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
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

  testWidgets('outside tap on type pills dismisses the focused transaction editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    expect(find.text('Új kiadási tranzakció'), findsOneWidget);

    await tester.tap(find.text('Bevétel'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsNothing,
    );
    await _tapFab(tester);
    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(find.text('Új bevételi tranzakció'), findsNothing);
  });

  testWidgets('logbox tap opens transaction editor in edit mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-logbox-250909')),
        matching: find.text('-505 Ft'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

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


  testWidgets('add transaction sheet opens date and time pickers', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-time-picker-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('transaction-time-picker-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('add transaction sheet saves through native bridge', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
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
      <String, Object?>{
        'transactionCategoryID': 7,
        'name': 'Food',
        'type': 'kiadás',
        'colorSlot': 1,
        'iconSlot': 3,
        'backgroundColor': '#10b981',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 8,
        'name': 'Travel',
        'type': 'kiadás',
        'colorSlot': 4,
        'iconSlot': 4,
        'backgroundColor': '#f59e0b',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
      <String, Object?>{
        'transactionCategoryID': 9,
        'name': 'Bills',
        'type': 'kiadás',
        'colorSlot': 5,
        'iconSlot': 5,
        'backgroundColor': '#8b5cf6',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      },
    ],
    'transactions': transactions,
  };
}

Future<void> _tapFab(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('expt-fab')));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

double _slideCardTranslationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('slide-up-menu-transform')),
  );
  return transform.transform.getTranslation().y;
}
