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
              ];
            }
            return true;
          });

      final cards = await bridge.expenseListNotificationCards();
      final read = await bridge.expenseMarkNotificationCardRead(1);
      final deleted = await bridge.expenseDeleteNotificationCard(1);

      expect(cards.single.title, 'Ismétlődő tranzakció');
      expect(read, isTrue);
      expect(deleted, isTrue);
      expect(invoked, [
        'expenseListNotificationCards',
        'expenseMarkNotificationCardRead',
        'expenseDeleteNotificationCard',
      ]);
    },
  );
}
