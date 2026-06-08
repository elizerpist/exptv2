import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/main.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/features/shell/widgets/expt_fab.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_menu_card.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_panel_metrics.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final savedTransactions = <Map<dynamic, dynamic>>[];
final updatedTransactions = <Map<dynamic, dynamic>>[];
final updatedThemeSettings = <Map<dynamic, dynamic>>[];
final recurringRulesPayload = <Map<String, Object?>>[];
final deletedTransactionIds = <int>[];
var firstLaunchNotificationPromptEnabled = false;
var firstLaunchNotificationPromptCalls = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DebugConsole.clear();
    savedTransactions.clear();
    updatedTransactions.clear();
    updatedThemeSettings.clear();
    recurringRulesPayload.clear();
    deletedTransactionIds.clear();
    firstLaunchNotificationPromptEnabled = false;
    firstLaunchNotificationPromptCalls = 0;
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
                'backheaderStyle': 'classic',
              },
              'fastInfoConfig': <String, Object?>{
                'pills': <Object?>[null, null, null],
                'boxes': <Object?>[null, null, null],
              },
              'securitySettings': <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': false,
                'biometricLabel': 'Nem elerheto',
              },
            };
          }
          if (call.method == 'expenseUpdateThemeSettings') {
            final payload = Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
            updatedThemeSettings.add(payload);
            return payload;
          }
          if (call.method == 'expenseListRecurringTransactions') {
            return <Map<String, Object?>>[];
          }
          if (call.method == 'expenseListRecurringRules') {
            return recurringRulesPayload;
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
          if (call.method == 'loadNotificationParserProfiles') {
            return <String, Object?>{
              'profiles': <Object?>[notificationParserProfilePayload()],
            };
          }
          if (call.method == 'saveNotificationParserProfiles') {
            return Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
          }
          if (call.method == 'loadNotificationParserRule') {
            return notificationParserProfilePayload();
          }
          if (call.method == 'saveNotificationParserRule') {
            return Map<dynamic, dynamic>.from(
              call.arguments as Map<dynamic, dynamic>,
            );
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
          if (call.method == 'requestPostNotificationsOnFirstLaunch') {
            firstLaunchNotificationPromptCalls += 1;
            return firstLaunchNotificationPromptEnabled;
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

  testWidgets('shell keeps the body stable while the keyboard opens', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
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

  testWidgets('shell tab host avoids IndexedStack inactive page layout', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(IndexedStack), findsNothing);
  });

  testWidgets('bottom nav tab switch does not rebuild transaction home', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav tap from=home to=settings'));
    expect(logs, contains('[Perf] BottomNav frame from=home to=settings'));
    expect(logs, isNot(contains('[Perf] HomeBuild frame')));
  });

  testWidgets('bottom nav return to home reuses the existing home page', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await tester.tap(find.text('Főoldal'));
    await tester.pumpAndSettle();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] BottomNav tap from=settings to=home'));
    expect(logs, contains('[Perf] BottomNav frame from=settings to=home'));
    expect(
      logs,
      isNot(contains('[Perf] Store start skipped reason=completed')),
    );
    expect(logs, isNot(contains('[Perf] FastInfo metrics build')));
  });

  testWidgets('first launch requests Android notification permission once', (
    tester,
  ) async {
    firstLaunchNotificationPromptEnabled = true;

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(firstLaunchNotificationPromptCalls, 1);
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

  testWidgets('FAB long press opens the recurring manager', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(find.text('Ismétlődő kiadás'), findsOneWidget);
    expect(find.text('Kiadás a fő pill alapján'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recurring-manager-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recurring-trigger-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('recurring-trigger-push')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('transaction-editor-card')), findsNothing);
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
  });

  testWidgets('recurring push training taps stay inside the manager', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('recurring-rule-sample')),
      'Kartyas vasarlas: Tesco - 12 345 Ft',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-training-merchant')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-training-merchant')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-training-token-Tesco')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recurring-training-token-Tesco')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recurring-manager-card')), findsOneWidget);
    expect(find.text('Tesco'), findsWidgets);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsNothing);
  });

  testWidgets('recurring trigger pills use the same active primary color', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    Color triggerBorderColor(String key) {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      return (decoration.border! as Border).top.color;
    }

    expect(triggerBorderColor('recurring-trigger-date'), AppColors.primary);

    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();

    expect(triggerBorderColor('recurring-trigger-push'), AppColors.primary);
  });

  testWidgets('recurring manager body scroll never becomes sheet drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-trigger-push')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('recurring-push-advanced')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recurring-push-advanced')));
    await tester.pumpAndSettle();

    final scrollFinder = find.byKey(
      const ValueKey('recurring-manager-scroll'),
    );
    await tester.drag(scrollFinder, const Offset(0, -520));
    await tester.pumpAndSettle();

    final beforeDrag = _slideCardTranslationY(tester);
    final gesture = await tester.startGesture(tester.getCenter(scrollFinder));
    await gesture.moveBy(const Offset(0, 760));
    await tester.pump();

    expect(
      _slideCardTranslationY(tester),
      moreOrLessEquals(beforeDrag, epsilon: 0.1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('recurring-manager-drag-handle')),
      const Offset(0, 220),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recurring-manager-card')), findsNothing);
  });

  testWidgets('recurring rule cards use main logbox corner radius', (
    tester,
  ) async {
    recurringRulesPayload.add(
      <String, Object?>{
        'id': 7,
        'triggerType': 'date',
        'transactionType': 'expense',
        'name': 'Hitel',
        'estimatedAmount': 123456,
        'expectedDayOfMonth': 5,
        'categoryId': 1,
        'isActive': true,
        'appFilterText': '',
        'packageName': '',
        'appLabel': '',
        'sampleText': '',
        'includeKeyword': '',
        'amountPattern': '',
        'amountSelection': '',
        'merchantPattern': '',
        'merchantSelection': '',
        'dateToleranceDays': 5,
        'amountTolerancePercent': 20,
        'amountToleranceMin': 5000,
        'createdAt': '2026-06-01T10:00:00.000',
        'updatedAt': '2026-06-01T10:00:00.000',
      },
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('recurring-rule-card-7')),
    );
    final decoration = card.decoration! as BoxDecoration;
    final radius = decoration.borderRadius! as BorderRadius;

    expect(radius.topLeft.x, 25);
    expect(radius.topRight.x, 25);
    expect(radius.bottomLeft.x, 25);
    expect(radius.bottomRight.x, 25);
  });

  testWidgets('FAB repeated taps keep opening the transaction sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-editor-card')),
      findsOneWidget,
      reason: DebugConsole.allText,
    );
    expect(
      find.byKey(const ValueKey('budget-target-editor-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
  });

  testWidgets('FAB single tap dispatches immediately', (tester) async {
    var singleTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(onPressed: () => singleTaps += 1)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 1));

    expect(singleTaps, 1);
  });

  testWidgets('FAB quick second tap dispatches another single tap', (
    tester,
  ) async {
    var singleTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ExptFab(onPressed: () => singleTaps += 1)),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pump(const Duration(milliseconds: 1));

    expect(singleTaps, 2);
  });

  testWidgets('transaction editor closed height fits primary controls', (
    tester,
  ) async {
    var mobileClosedHeight = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              mobileClosedHeight = SlideUpPanelMetrics.transactionHeight(
                context,
                pickerOpen: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(mobileClosedHeight, lessThanOrEqualTo(430));
    expect(mobileClosedHeight, greaterThanOrEqualTo(400));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    expect(cardRect.height, lessThanOrEqualTo(456));

    for (final key in const [
      ValueKey('transaction-category-selector'),
      ValueKey('transaction-date-picker-button'),
      ValueKey('transaction-time-picker-button'),
      ValueKey('transaction-save-button'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.top, greaterThanOrEqualTo(cardRect.top));
      expect(rect.bottom, lessThanOrEqualTo(cardRect.bottom));
    }
  });

  testWidgets('transaction editor closed layout is not full-sheet scrollable', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final nameField = find.widgetWithText(TextField, 'Tranzakció neve');
    expect(nameField, findsOneWidget);
    expect(
      find.ancestor(
        of: nameField,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-category-scroll-list')),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
  });

  testWidgets('transaction editor keeps save button close to date row', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    final dateBottom = tester
        .getRect(find.byKey(const ValueKey('transaction-date-picker-button')))
        .bottom;
    final saveTop = tester
        .getRect(find.byKey(const ValueKey('transaction-save-button')))
        .top;
    final nameBottom = tester
        .getRect(find.widgetWithText(TextField, 'Tranzakció neve'))
        .bottom;
    final amountTop = tester
        .getRect(find.widgetWithText(TextField, 'Összeg'))
        .top;

    expect(saveTop - dateBottom, lessThanOrEqualTo(amountTop - nameBottom + 2));
  });

  testWidgets('transaction editor save button aligns with category editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);
    final transactionSaveBottom = tester
        .getRect(find.byKey(const ValueKey('transaction-save-button')))
        .bottom;

    await tester.tap(find.byKey(const ValueKey('slide-up-menu-veil')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('category-menu-add-button')));
    await tester.pumpAndSettle();

    final categorySaveBottom = tester
        .getRect(find.byKey(const ValueKey('category-save-button')))
        .bottom;

    expect(
      transactionSaveBottom,
      moreOrLessEquals(categorySaveBottom, epsilon: 4),
    );
  });

  testWidgets('transaction editor logs text focus performance', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    DebugConsole.clear();

    await _tapFab(tester);
    await tester.tap(find.widgetWithText(TextField, 'Tranzakció neve'));
    await tester.pump();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] AddTransaction focus field=name'));
    expect(logs, contains('[Perf] AddTransaction focus frame field=name'));
    expect(logs, contains('[Perf] TextInput focus label=AddTransaction.name'));
    expect(logs, contains('keyboard='));
  });

  testWidgets('transaction category field opens inline scroll picker', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final slideCard = tester.widget<SlideUpMenuCard>(
      find.ancestor(
        of: find.byKey(const ValueKey('transaction-editor-card')),
        matching: find.byType(SlideUpMenuCard),
      ),
    );
    expect(slideCard.entryDuration, const Duration(milliseconds: 192));
    expect(slideCard.deferEntryAnimation, isTrue);
    final cardBefore = tester.getRect(
      find.byKey(const ValueKey('transaction-editor-card')),
    );
    final saveBefore = tester.getRect(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    final dateBefore = tester.getRect(find.widgetWithText(TextField, 'Dátum'));

    await tester.tap(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-menu-overlay')), findsNothing);
    expect(
      find.byKey(const ValueKey('transaction-category-popup')),
      findsNothing,
    );
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
    final saveAfter = tester.getRect(
      find.byKey(const ValueKey('transaction-save-button')),
    );
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-scroll-list')),
    );
    final selectorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    final dateAfter = tester.getRect(find.widgetWithText(TextField, 'Dátum'));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(editorRect.top, lessThan(cardBefore.top));
    expect(
      editorRect.height,
      moreOrLessEquals(
        SlideUpPanelMetrics.transactionHeight(
          tester.element(find.byKey(const ValueKey('transaction-editor-card'))),
          pickerOpen: true,
        ),
        epsilon: 0.1,
      ),
    );
    expect(dateAfter.bottom, moreOrLessEquals(dateBefore.bottom, epsilon: 1));
    expect(saveAfter.bottom, moreOrLessEquals(saveBefore.bottom, epsilon: 1));
    expect(saveAfter.bottom, lessThanOrEqualTo(screenHeight));
    expect(
      pickerRect.top,
      moreOrLessEquals(selectorRect.bottom + 8, epsilon: 1),
    );
    expect(pickerRect.height, moreOrLessEquals(211, epsilon: 0.1));
    expect(pickerRect.bottom, lessThanOrEqualTo(saveAfter.top - 12));

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

  testWidgets('transaction editor keeps date row close to category selector', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await _tapFab(tester);

    final selectorRect = tester.getRect(
      find.byKey(const ValueKey('transaction-category-selector')),
    );
    final dateRect = tester.getRect(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );

    expect(dateRect.top - selectorRect.bottom, lessThanOrEqualTo(24));
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
    expect(find.byKey(const ValueKey('category-menu-add-button')), findsOneWidget);
  });

  testWidgets('add category sheet keeps the picker behind and covers nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    final overlayRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-overlay')),
    );
    final addButtonRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-add-button')),
    );
    expect(addButtonRect.right, greaterThan(overlayRect.right - 56));

    await tester.tap(find.byKey(const ValueKey('category-menu-add-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-menu-overlay')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );

    await tester.tap(find.text('Stats'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-page')), findsNothing);
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('category-menu-overlay')), findsOneWidget);
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

  testWidgets(
    'outside tap on type pills dismisses the focused transaction editor',
    (tester) async {
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
      expect(find.text('Új bevételi tranzakció'), findsOneWidget);
      expect(find.text('Új kiadási tranzakció'), findsNothing);
    },
  );

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

  testWidgets('settings contains Backheader style selector', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    final backheaderOption = find.ancestor(
      of: find.text('Backheader'),
      matching: find.byType(InkWell),
    );
    expect(backheaderOption, findsOneWidget);
    await tester.ensureVisible(backheaderOption);
    await tester.pumpAndSettle();
    await tester.tap(backheaderOption);
    await tester.pumpAndSettle();

    expect(find.text('Jelenlegi bar rendszer (jelenlegi)'), findsOneWidget);
    expect(find.text('C - Hero Token'), findsOneWidget);
    expect(find.text('D - Orbit Budget'), findsOneWidget);
    expect(find.text('A - Color Field Partition'), findsNothing);
    expect(find.text('B - Partition Dashboard'), findsNothing);
    expect(find.text('E - Mosaic Budget'), findsNothing);
    expect(find.text('F - Ledger Strip'), findsNothing);

    await tester.ensureVisible(find.text('D - Orbit Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D - Orbit Budget'));
    await tester.pumpAndSettle();

    expect(updatedThemeSettings.single['backheaderStyle'], 'orbitBudget');
  });

  testWidgets('settings contains push parser profiles and app picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beállítások'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-page')), findsOneWidget);
    await tester.tap(find.text('Megfigyelni kívánt alkalmazás'));
    await tester.pumpAndSettle();

    expect(find.text('Profilok'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-parser-profile-profile-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-parser-sample')),
      findsOneWidget,
    );
    expect(find.text('App regex'), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-parser-app-picker')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('notification-parser-app-picker')),
    );
    await tester.pumpAndSettle();
    final pickerRect = tester.getRect(
      find.byKey(const ValueKey('installed-app-picker-sheet')),
    );
    expect(
      pickerRect.height,
      moreOrLessEquals(
        SlideUpPanelMetrics.fullHeightForScreen(919),
        epsilon: 1,
      ),
    );
    expect(
      pickerRect.top,
      moreOrLessEquals(
        919 - SlideUpPanelMetrics.fullHeightForScreen(919),
        epsilon: 1,
      ),
    );
    expect(
      find.byKey(const ValueKey('installed-app-picker-search')),
      findsOneWidget,
    );
    final picker = find.byKey(const ValueKey('installed-app-picker-sheet'));
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('installed-app-picker-search')),
      'missing',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('installed-app-picker-search')),
      'notification',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: picker, matching: find.text('Notification Test')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: picker, matching: find.text('Notification Test')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification Test'), findsWidgets);
  });
}

Map<String, Object?> notificationParserProfilePayload() {
  return <String, Object?>{
    'id': 'profile-1',
    'name': 'Profil',
    'enabled': true,
    'appFilterText': '',
    'packageName': 'com.mand.notitest',
    'appLabel': 'Notification Test',
    'sampleText': 'Paid 999 Ft at Corner Shop',
    'includeKeyword': '',
    'amountPattern': r'(?<amount>\d+)\s*Ft',
    'merchantPattern': r'at\s+(?<merchant>.+)',
    'transactionType': 'expense',
  };
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
  tester.view.physicalSize = const Size(390, 919);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpAndSettle();
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
