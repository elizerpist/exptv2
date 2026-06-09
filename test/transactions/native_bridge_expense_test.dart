import 'package:exptv2/features/notifications/models/expense_notification_card.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/expense_methods');
  late NativeBridge bridge;

  setUp(() {
    bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/events'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'expenseLoadBootstrap') {
            return {
              'categories': [
                {
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
              ],
              'transactions': [
                {
                  'id': 250905,
                  'date': '2025.09.24',
                  'time': '21:56',
                  'merchant': 'Rrteeaawwq',
                  'amount': 5555,
                  'userAssignedName': 'Gguu',
                  'transactionCategoryID': 5,
                },
              ],
            };
          }
          if (call.method == 'expenseAddTransaction') {
            return {
              'id': 250914,
              'date': '2025.09.26',
              'time': '09:15',
              'merchant': 'Salary',
              'amount': 1000,
              'userAssignedName': null,
              'transactionCategoryID': 5,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads expense bootstrap payload', () async {
    final payload = await bridge.expenseLoadBootstrap();
    expect(payload.categories.single, isA<TransactionCategory>());
    expect(payload.transactions.single, isA<TransactionRecord>());
  });

  test('adds transaction through native bridge', () async {
    final record = await bridge.expenseAddTransaction({
      'merchant': 'Salary',
      'amount': 1000,
      'type': 'income',
      'transactionCategoryID': 5,
      'date': '2025-09-26',
      'time': '09:15',
    });
    expect(record.id, 250914);
    expect(record.amount, 1000);
  });

  test('updates transaction through native bridge', () async {
    String? invokedMethod;
    Map<dynamic, dynamic>? invokedPayload;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethod = call.method;
          invokedPayload = call.arguments as Map<dynamic, dynamic>;
          return {
            'id': 250905,
            'date': '2025.09.26',
            'time': '11:20',
            'merchant': 'Salary edit',
            'amount': -1234,
            'userAssignedName': 'Edited',
            'transactionCategoryID': 5,
          };
        });

    final record = await bridge.expenseUpdateTransaction(250905, {
      'merchant': 'Salary edit',
      'amount': 1234,
      'type': 'expense',
      'transactionCategoryID': 5,
      'date': '2025-09-26',
      'time': '11:20',
      'userAssignedName': 'Edited',
    });

    expect(invokedMethod, 'expenseUpdateTransaction');
    expect(invokedPayload?['id'], 250905);
    expect(record.id, 250905);
    expect(record.amount, -1234);
    expect(record.displayMerchant, 'Edited');
  });

  test('deletes transaction through native bridge', () async {
    String? invokedMethod;
    Map<dynamic, dynamic>? invokedPayload;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethod = call.method;
          invokedPayload = call.arguments as Map<dynamic, dynamic>;
          return true;
        });

    final deleted = await bridge.expenseDeleteTransaction(250905);

    expect(invokedMethod, 'expenseDeleteTransaction');
    expect(invokedPayload?['id'], 250905);
    expect(deleted, isTrue);
  });

  test(
    'loads, reads, and deletes notification cards through native bridge',
    () async {
      final invoked = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            invoked.add(call.method);
            if (call.method == 'expenseListNotificationCards') {
              return [
                {
                  'id': 1,
                  'type': 'recurring_transaction_alert',
                  'title': 'Ismétlődő tranzakció',
                  'message': 'Rent automatikusan hozzáadva',
                  'timestamp': 1778803200000,
                  'isRead': false,
                  'isActive': true,
                  'priority': 'medium',
                  'categoryId': 6,
                  'categoryName': 'Q',
                  'categoryColor': '#dc2626',
                  'categoryIconSlot': 2,
                  'recurringTransactionId': 9,
                  'transactionId': 26051501,
                  'amount': 500,
                  'triggerDate': '2026-05-15T00:00:00.000',
                  'nextDueDate': '2026-06-15T00:00:00.000',
                  'createdAt': 1778803200000,
                  'updatedAt': 1778803200000,
                },
                {
                  'id': 2,
                  'type': 'transaction_created',
                  'title': 'Új tranzakció',
                  'message': 'Tesco: 4200 Ft kiadás rögzítve.',
                  'timestamp': 1778803200000,
                  'isRead': false,
                  'isActive': true,
                  'priority': 'normal',
                  'categoryId': 6,
                  'categoryName': 'Q',
                  'categoryColor': '#dc2626',
                  'categoryIconSlot': 2,
                  'transactionId': 26051502,
                  'amount': 4200,
                  'triggerDate': '2026.05.15',
                  'createdAt': 1778803200000,
                  'updatedAt': 1778803200000,
                },
                {
                  'id': 3,
                  'type': 'limit_100',
                  'title': 'Limit elérve',
                  'message': 'Q: 1000 Ft-tal túllépted a limitet.',
                  'timestamp': 1778803200000,
                  'isRead': false,
                  'isActive': true,
                  'priority': 'critical',
                  'categoryId': 6,
                  'categoryName': 'Q',
                  'categoryColor': '#dc2626',
                  'categoryIconSlot': 2,
                  'transactionId': 26051502,
                  'amount': 4200,
                  'triggerDate': '2026.05.15',
                  'createdAt': 1778803200000,
                  'updatedAt': 1778803200000,
                },
              ];
            }
            return true;
          });

      final cards = await bridge.expenseListNotificationCards();
      final read = await bridge.expenseMarkNotificationCardRead(1);
      final deleted = await bridge.expenseDeleteNotificationCard(1);

      expect(cards, hasLength(3));
      expect(cards[0].title, 'Ismétlődő tranzakció');
      expect(cards[1].type, ExpenseNotificationType.transactionCreated);
      expect(cards[2].type, ExpenseNotificationType.limit100);
      expect(cards[2].priority, 'critical');
      expect(read, isTrue);
      expect(deleted, isTrue);
      expect(invoked, [
        'expenseListNotificationCards',
        'expenseMarkNotificationCardRead',
        'expenseDeleteNotificationCard',
      ]);
    },
  );

  test('renames and resets all transactions by original merchant', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 3;
        });

    final renamed = await bridge.expenseRenameTransactionsByMerchant(
      'Tesco',
      'Tesco Market',
    );
    final reset = await bridge.expenseResetTransactionNamesByMerchant('Tesco');

    expect(renamed, 3);
    expect(reset, 3);
    expect(calls[0].method, 'expenseRenameTransactionsByMerchant');
    expect((calls[0].arguments as Map)['originalMerchant'], 'Tesco');
    expect((calls[0].arguments as Map)['userAssignedName'], 'Tesco Market');
    expect(calls[1].method, 'expenseResetTransactionNamesByMerchant');
  });

  test('manages recurring rules through native bridge', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'expenseListRecurringRules':
              return <Map<String, Object?>>[
                recurringRuleRow(id: 7, triggerType: 'push'),
              ];
            case 'expenseAddRecurringRule':
              return recurringRuleRow(id: 8, triggerType: 'push');
            case 'expenseUpdateRecurringRule':
              return recurringRuleRow(id: 7, name: 'Hitel edit');
            case 'expenseToggleRecurringRule':
              return recurringRuleRow(id: 7, isActive: false);
            case 'expenseDeleteRecurringRule':
              return true;
          }
          return null;
        });

    final rows = await bridge.expenseListRecurringRules();
    expect(rows.single.triggerType, RecurringTriggerType.push);
    expect(rows.single.categoryId, 6);

    const draft = RecurringRuleDraft(
      triggerType: RecurringTriggerType.push,
      transactionType: TransactionType.expense,
      name: 'Hitel',
      estimatedAmount: 150000,
      expectedDayOfMonth: 5,
      expectedTime: '20:15',
      categoryId: 6,
      appFilterText: r'^Bank$',
      packageName: 'hu.bank.app',
      appLabel: 'Bank',
      sampleText: 'Levonás 150 000 Ft itt: Hitel',
      includeKeyword: 'Levonás',
      amountPattern: r'(?<amount>\d[\d\s]*)\s*Ft',
      amountSelection: '150 000 Ft',
      merchantPattern: r'itt:\s*(?<merchant>.+)',
      merchantSelection: 'Hitel',
      dateToleranceDays: 6,
      amountTolerancePercent: 15,
      amountToleranceMin: 10000,
    );

    final created = await bridge.expenseAddRecurringRule(draft);
    expect(created.id, 8);
    final addPayload = calls.last.arguments as Map<dynamic, dynamic>;
    expect(addPayload['triggerType'], 'push');
    expect(addPayload['transactionType'], 'expense');
    expect(addPayload['expectedTime'], '20:15');
    expect(addPayload['amountToleranceMin'], 10000);

    final updated = await bridge.expenseUpdateRecurringRule(7, draft);
    expect(updated.name, 'Hitel edit');
    expect((calls.last.arguments as Map<dynamic, dynamic>)['id'], 7);

    final toggled = await bridge.expenseToggleRecurringRule(7, false);
    expect(toggled.isActive, isFalse);

    final deleted = await bridge.expenseDeleteRecurringRule(7);
    expect(deleted, isTrue);
  });
}

Map<String, Object?> recurringRuleRow({
  required int id,
  String triggerType = 'date',
  String name = 'Hitel',
  bool isActive = true,
}) {
  return <String, Object?>{
    'id': id,
    'triggerType': triggerType,
    'transactionType': 'expense',
    'name': name,
    'estimatedAmount': 150000,
    'expectedDayOfMonth': 5,
    'expectedTime': '20:15',
    'categoryId': 6,
    'categoryName': 'Lakhatás',
    'categoryColor': '#dc2626',
    'categoryIconSlot': 2,
    'isActive': isActive,
    'appFilterText': r'^Bank$',
    'packageName': 'hu.bank.app',
    'appLabel': 'Bank',
    'sampleText': 'Levonás 150 000 Ft itt: Hitel',
    'includeKeyword': 'Levonás',
    'amountPattern': r'(?<amount>\d[\d\s]*)\s*Ft',
    'amountSelection': '150 000 Ft',
    'merchantPattern': r'itt:\s*(?<merchant>.+)',
    'merchantSelection': 'Hitel',
    'dateToleranceDays': 6,
    'amountTolerancePercent': 15,
    'amountToleranceMin': 10000,
    'createdAt': 1777593600000,
    'updatedAt': 1777593600000,
  };
}
