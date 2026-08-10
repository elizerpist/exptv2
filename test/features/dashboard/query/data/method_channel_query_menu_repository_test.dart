import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/method_channel_query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('facet bridge carries real bounded months and canonical time filter', () async {
    const channel = MethodChannel('test/query-menu');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return <String, Object?>{
        'result': <String, Object?>{
          'entryCount': 26,
          'amountScaled100': 123_000,
        },
        'amountDomain': <String, Object?>{
          'minimumAmountScaled100': 0,
          'maximumAmountScaled100': 250_000,
        },
        'availableMonths': <Object?>[
          <String, Object?>{'year': 2025, 'month': 6},
          <String, Object?>{'year': 2026, 'month': 2},
        ],
        'categories': const <Object?>[],
        'partners': const <Object?>[],
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 2),
      }),
    );

    final result = await MethodChannelQueryMenuRepository(
      channel: channel,
    ).readFacets(scope);

    expect(request?.method, 'readQueryMenuFacets');
    expect(
      (request!.arguments! as Map<Object?, Object?>)['periodGroups'],
      <Object?>[
        <String, Object?>{
          'key': 'time',
          'selections': <Object?>[
            <String, Object?>{'kind': 'month', 'value': '2026-02'},
          ],
        },
      ],
    );
    expect(result.result.entryCount, 26);
    expect(result.availableMonths.map((month) => (month.year, month.month)), <(int, int)>[
      (2025, 6),
      (2026, 2),
    ]);
  });
}
