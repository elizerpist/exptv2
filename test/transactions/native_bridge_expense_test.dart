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
}
