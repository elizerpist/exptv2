import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/category_limit_methods');
  late NativeBridge bridge;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/category_limit_events'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'expenseListCategoryLimits') {
            return [
              categoryLimitMap(
                id: 3,
                targetType: 'category',
                targetId: 6,
                transactionType: 'expense',
                window: 'monthly',
                periodKey: '2026-05',
                hasLimit: true,
                limitAmount: 50000,
                alertActive: true,
              ),
            ];
          }
          if (call.method == 'expenseUpsertCategoryLimit') {
            final args = call.arguments as Map<Object?, Object?>;
            return categoryLimitMap(
              id: 4,
              targetType: args['targetType'].toString(),
              targetId: args['targetId'] as int,
              transactionType: args['transactionType'].toString(),
              window: args['window'].toString(),
              periodKey: args['periodKey'].toString(),
              hasLimit: args['hasLimit'] == true,
              limitAmount: args['limitAmount'] as int,
              alertActive: args['alertActive'] == true,
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('lists category limits through native bridge', () async {
    final limits = await bridge.expenseListCategoryLimits(
      transactionType: 'expense',
      window: 'monthly',
      periodKey: '2026-05',
    );

    expect(limits, hasLength(1));
    expect(limits.single, isA<CategoryLimit>());
    expect(limits.single.targetType, LimitTargetType.category);
    expect(limits.single.targetId, 6);
    expect(limits.single.window, LimitWindow.monthly);
    expect(limits.single.periodKey, '2026-05');
    expect(calls.single.method, 'expenseListCategoryLimits');
  });

  test('upserts category limit through native bridge', () async {
    final limit = await bridge.expenseUpsertCategoryLimit({
      'targetType': 'category',
      'targetId': 6,
      'transactionType': 'expense',
      'window': 'yearly',
      'periodKey': '2026',
      'hasLimit': true,
      'limitAmount': 600000,
      'alertActive': false,
    });

    expect(limit.id, 4);
    expect(limit.window, LimitWindow.yearly);
    expect(limit.limitAmount, 600000);
    expect(calls.single.method, 'expenseUpsertCategoryLimit');
  });
}

Map<String, Object?> categoryLimitMap({
  required int id,
  required String targetType,
  required int targetId,
  required String transactionType,
  required String window,
  required String periodKey,
  required bool hasLimit,
  required num limitAmount,
  required bool alertActive,
}) {
  return {
    'id': id,
    'targetType': targetType,
    'targetId': targetId,
    'transactionType': transactionType,
    'window': window,
    'periodKey': periodKey,
    'hasLimit': hasLimit,
    'limitAmount': limitAmount,
    'alertActive': alertActive,
    'createdAt': 10,
    'updatedAt': 20,
  };
}
