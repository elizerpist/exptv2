import 'dart:async';

import 'package:exptv2/features/transactions/native/native_ime_sheet_app.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/add_transaction_sheet.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nativeSheetChannel = MethodChannel('exptv2/native_ime_sheet');
  const dataChannel = MethodChannel('pushparser/methods');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, null);
  });

  testWidgets(
    'native sheet startup does not expose a blank white loading sheet',
    (tester) async {
      final pendingInitialState = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, (call) async {
            if (call.method == 'getInitialState') {
              return pendingInitialState.future;
            }
            return null;
          });

      await tester.pumpWidget(const NativeImeSheetApp());
      await tester.pump();

      final loadingMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(NativeImeSheetApp),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(loadingMaterial.color, Colors.transparent);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('native add transaction content does not load full bootstrap', (
    tester,
  ) async {
    var bootstrapCalls = 0;
    var listCategoryCalls = 0;
    final nativeCalls = <String>[];
    final dataCalls = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async {
          nativeCalls.add(call.method);
          if (call.method == 'getInitialState') {
            return <String, Object?>{
              'mode': 'addTransaction',
              'type': 'expense',
            };
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, (call) async {
          dataCalls.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              return _settingsPayload();
            case 'expenseListCategories':
              listCategoryCalls += 1;
              return _categoryPayload();
            case 'expenseLoadBootstrap':
              bootstrapCalls += 1;
              return <String, Object?>{
                'categories': _categoryPayload(),
                'transactions': <Map<String, Object?>>[],
                'limits': <Map<String, Object?>>[],
                'recurringGhostTransactions': <Map<String, Object?>>[],
              };
            case 'expenseListRecurringRules':
              return <Map<String, Object?>>[];
          }
          return null;
        });

    await tester.pumpWidget(const NativeImeSheetApp());
    await tester.pumpAndSettle();

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(bootstrapCalls, 0, reason: 'calls: $dataCalls');
    expect(listCategoryCalls, 1, reason: 'calls: $dataCalls');
    expect(nativeCalls, contains('getInitialState'));
  });

  testWidgets('native add transaction sends contentReady after first frame', (
    tester,
  ) async {
    final nativeCalls = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async {
          nativeCalls.add(call.method);
          if (call.method == 'getInitialState') {
            return <String, Object?>{
              'mode': 'addTransaction',
              'type': 'expense',
            };
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, (call) async {
          switch (call.method) {
            case 'expenseLoadSettings':
              return _settingsPayload();
            case 'expenseListCategories':
              return _categoryPayload();
          }
          return null;
        });

    await tester.pumpWidget(const NativeImeSheetApp());
    await tester.pumpAndSettle();

    expect(find.text('Új kiadási tranzakció'), findsOneWidget);
    expect(nativeCalls, contains('contentReady'));
  });

  testWidgets('native add transaction sends contentReady for error surface', (
    tester,
  ) async {
    final nativeCalls = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async {
          nativeCalls.add(call.method);
          if (call.method == 'getInitialState') {
            return <String, Object?>{
              'mode': 'addTransaction',
              'type': 'expense',
            };
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, (call) async {
          if (call.method == 'expenseLoadSettings') {
            throw PlatformException(code: 'settings_failed');
          }
          return null;
        });

    await tester.pumpWidget(const NativeImeSheetApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Native sheet hiba'), findsOneWidget);
    expect(nativeCalls, contains('contentReady'));
  });

  testWidgets(
    'native add transaction handles host type changes without restart',
    (tester) async {
      final nativeCalls = <String>[];
      var listCategoryCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeSheetChannel, (call) async {
            nativeCalls.add(call.method);
            if (call.method == 'getInitialState') {
              return <String, Object?>{
                'mode': 'addTransaction',
                'type': 'expense',
              };
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(dataChannel, (call) async {
            switch (call.method) {
              case 'expenseLoadSettings':
                return _settingsPayload();
              case 'expenseListCategories':
                listCategoryCalls += 1;
                return _categoryPayload();
            }
            return null;
          });

      await tester.pumpWidget(const NativeImeSheetApp());
      await tester.pumpAndSettle();
      expect(find.text('Új kiadási tranzakció'), findsOneWidget);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            nativeSheetChannel.name,
            nativeSheetChannel.codec.encodeMethodCall(
              const MethodCall('sheetStateChanged', <String, Object?>{
                'mode': 'addTransaction',
                'type': 'income',
              }),
            ),
            (_) {},
          );
      await tester.pumpAndSettle();

      expect(find.text('Új bevételi tranzakció'), findsOneWidget);
      expect(listCategoryCalls, 1);
      expect(
        nativeCalls.where((method) => method == 'contentReady'),
        hasLength(2),
      );
    },
  );

  testWidgets('native add transaction save avoids sheet-side full reload', (
    tester,
  ) async {
    var bootstrapCalls = 0;
    final savedTransactions = <Map<dynamic, dynamic>>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeSheetChannel, (call) async {
          if (call.method == 'getInitialState') {
            return <String, Object?>{
              'mode': 'addTransaction',
              'type': 'expense',
            };
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dataChannel, (call) async {
          switch (call.method) {
            case 'expenseLoadSettings':
              return _settingsPayload();
            case 'expenseListCategories':
              return _categoryPayload();
            case 'expenseAddTransaction':
              final payload = Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              );
              savedTransactions.add(payload);
              final amount = payload['amount'] as num;
              return <String, Object?>{
                'id': 991,
                'date': payload['date'],
                'time': payload['time'],
                'merchant': payload['merchant'],
                'amount': -amount.abs(),
                'userAssignedName': null,
                'transactionCategoryID': payload['transactionCategoryID'],
              };
            case 'expenseLoadBootstrap':
              bootstrapCalls += 1;
              return <String, Object?>{
                'categories': _categoryPayload(),
                'transactions': <Map<String, Object?>>[],
                'limits': <Map<String, Object?>>[],
                'recurringGhostTransactions': <Map<String, Object?>>[],
              };
          }
          return null;
        });

    await tester.pumpWidget(const NativeImeSheetApp());
    await tester.pumpAndSettle();
    bootstrapCalls = 0;

    await tester.enterText(
      find.widgetWithText(TextField, 'Tranzakció neve'),
      'Native save',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '1200');
    await tester.tap(find.byKey(const ValueKey('transaction-save-button')));
    await tester.pumpAndSettle();

    expect(savedTransactions, hasLength(1));
    expect(savedTransactions.single['merchant'], 'Native save');
    expect(bootstrapCalls, 0);
  });

  testWidgets('native hosted add transaction avoids keyboard overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(460, 1024);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    tester.view.viewInsets = const FakeViewPadding(bottom: 252);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewPadding();
      tester.view.resetViewInsets();
    });

    final store = TransactionStore(TransactionRepository(NativeBridge()));
    store.startAddTransactionForm(
      categories: _categoryPayload().map(TransactionCategory.fromMap).toList(),
      type: TransactionType.expense,
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 460,
            height: 401,
            child: AddTransactionSheet(
              store: store,
              nativeHostMode: true,
              reloadAfterSave: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isNull);
    final dateRect = tester.getRect(
      find.byKey(const ValueKey('transaction-date-picker-button')),
    );
    final timeRect = tester.getRect(
      find.byKey(const ValueKey('transaction-time-picker-button')),
    );
    final saveRect = tester.getRect(
      find.byKey(const ValueKey('transaction-save-footer')),
    );
    final dateTimeBottom = dateRect.bottom > timeRect.bottom
        ? dateRect.bottom
        : timeRect.bottom;
    expect(saveRect.top - dateTimeBottom, greaterThanOrEqualTo(0));
    expect(
      find.byKey(const ValueKey('transaction-save-button')),
      findsOneWidget,
    );
  });
}

Map<String, Object?> _settingsPayload() {
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

List<Map<String, Object?>> _categoryPayload() {
  return <Map<String, Object?>>[
    <String, Object?>{
      'transactionCategoryID': 1,
      'name': 'Bolt',
      'type': 'kiadás',
      'colorSlot': 0,
      'iconSlot': 0,
      'backgroundColor': '#FF06B6D4',
      'icon': 'shopping-bag',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': false,
      'originalIcon': null,
    },
    <String, Object?>{
      'transactionCategoryID': 2,
      'name': 'Fizetés',
      'type': 'bevétel',
      'colorSlot': 1,
      'iconSlot': 1,
      'backgroundColor': '#FF22C55E',
      'icon': 'wallet',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': false,
      'originalIcon': null,
    },
  ];
}
