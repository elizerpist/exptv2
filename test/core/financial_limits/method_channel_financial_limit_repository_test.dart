import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/financial_limits/data/method_channel_financial_limit_repository.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/financial-limits');
  final repository = MethodChannelFinancialLimitRepository(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'encodes aggregate and category keys without fake category IDs',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return _limitPayload(call.arguments as Map<Object?, Object?>);
          });

      final aggregate = await repository.upsert(
        const FinancialLimitKey(
          direction: FinancialLimitDirection.expense,
          target: FinancialLimitAggregateTarget(),
          period: FinancialLimitMonthOverridePeriod(2026, 7),
        ),
        12000000,
      );

      expect(received?.method, 'upsertFinancialLimit');
      expect(received?.arguments, <String, Object?>{
        'direction': 'expense',
        'targetKind': 'aggregate',
        'periodKind': 'month',
        'year': 2026,
        'month': 7,
        'amountScaled100': 12000000,
      });
      expect(aggregate.key.target, isA<FinancialLimitAggregateTarget>());
      expect(aggregate.amountScaled100, 12000000);
    },
  );

  test(
    'decodes category zero-limit distinctly from a missing response',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getFinancialLimit') {
              return _limitPayload(<Object?, Object?>{
                'direction': 'income',
                'targetKind': 'category',
                'categoryId': 'salary',
                'periodKind': 'base',
                'amountScaled100': 0,
              });
            }
            return null;
          });

      final found = await repository.get(
        const FinancialLimitKey(
          direction: FinancialLimitDirection.income,
          target: FinancialLimitCategoryTarget('salary'),
          period: FinancialLimitBaseMonthlyPeriod(),
        ),
      );

      expect(found, isNotNull);
      expect(found!.amountScaled100, 0);
      expect(found.key.target, isA<FinancialLimitCategoryTarget>());
    },
  );

  test('encodes one atomic monthly override batch', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return <Object?>[
            _limitPayload(
              ((call.arguments as Map<Object?, Object?>)['values']
                      as List<Object?>)[0]
                  as Map<Object?, Object?>,
            ),
          ];
        });

    final values = await repository.upsertBatch(const <FinancialLimitMutation>[
      FinancialLimitMutation(
        key: FinancialLimitKey(
          direction: FinancialLimitDirection.expense,
          target: FinancialLimitAggregateTarget(),
          period: FinancialLimitMonthOverridePeriod(2026, 1),
        ),
        amountScaled100: 100,
      ),
    ]);

    expect(received?.method, 'upsertFinancialLimitsBatch');
    expect(values.single.amountScaled100, 100);
  });
}

Map<Object?, Object?> _limitPayload(Map<Object?, Object?> source) =>
    <Object?, Object?>{...source, 'createdAtUtcMs': 1, 'updatedAtUtcMs': 2};
