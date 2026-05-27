import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/category_methods');
  late NativeBridge bridge;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/events'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'expenseAddCategory') {
            return categoryMap(id: 14, name: 'Travel', type: 'kiadás');
          }
          if (call.method == 'expenseUpdateCategory') {
            return categoryMap(id: 14, name: 'Travel Edit', type: 'kiadás');
          }
          if (call.method == 'expenseDeleteCategory') return true;
          if (call.method == 'expenseCategoryCounts') {
            return <Object?, Object?>{5: 1, '6': 3};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('adds category through native bridge', () async {
    final category = await bridge.expenseAddCategory({
      'name': 'Travel',
      'type': 'expense',
      'colorSlot': 7,
      'iconSlot': 4,
    });

    expect(category, isA<TransactionCategory>());
    expect(category.transactionCategoryID, 14);
    expect(category.normalizedType, TransactionType.expense);
    expect(calls.single.method, 'expenseAddCategory');
  });

  test('updates and deletes category through native bridge', () async {
    final updated = await bridge.expenseUpdateCategory(14, {
      'name': 'Travel Edit',
      'colorSlot': 8,
      'iconSlot': 5,
    });
    final deleted = await bridge.expenseDeleteCategory(14);

    expect(updated.name, 'Travel Edit');
    expect(deleted, isTrue);
    expect(calls.map((call) => call.method), [
      'expenseUpdateCategory',
      'expenseDeleteCategory',
    ]);
    expect((calls.first.arguments as Map<Object?, Object?>)['id'], 14);
  });

  test('loads category counts as typed integer map', () async {
    final counts = await bridge.expenseCategoryCounts();

    expect(counts, {5: 1, 6: 3});
  });
}

Map<String, Object?> categoryMap({
  required int id,
  required String name,
  required String type,
}) {
  return <String, Object?>{
    'transactionCategoryID': id,
    'name': name,
    'type': type,
    'colorSlot': 7,
    'iconSlot': 4,
    'backgroundColor': '#0ea5e9',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  };
}
