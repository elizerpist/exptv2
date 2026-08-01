import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluvi/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.fluvi/dashboard_query');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('encodes a canonical day scope and decodes the core result', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{
        'scopeKey': 'expense|day:2026-02-14|categories:|partners:|refinements:',
        'totalMinor': 12500,
        'entryCount': 2,
        'coreRevision': 7,
        'entries': const <Object?>[],
      };
    });

    final repository = MethodChannelDashboardLedgerRepository(channel: channel);
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const DayScope(LocalDate(year: 2026, month: 2, day: 14)),
    );

    final result = await repository.read(scope);

    expect(received?.method, 'readDashboard');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['direction'], 'expense');
    expect(arguments['scopeKey'], scope.key.value);
    expect(arguments['periodGroups'], <Object?>[
      <Object?, Object?>{
        'key': 'time',
        'selections': <Object?>[
          <Object?, Object?>{'kind': 'day', 'value': '2026-02-14'},
        ],
      },
    ]);
    expect(result.totalMinor, 12500);
    expect(result.entryCount, 2);
    expect(result.coreRevision, 7);
  });

  test('encodes all-time without a time predicate', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{
        'scopeKey': 'income|all|categories:|partners:|refinements:',
        'totalMinor': 0,
        'entryCount': 0,
        'entries': const <Object?>[],
      };
    });

    final repository = MethodChannelDashboardLedgerRepository(channel: channel);
    await repository.read(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
      ),
    );

    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['periodGroups'], isEmpty);
  });

  test('encodes a month scope with future facets intact', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{
        'scopeKey':
            'income|month:2026-05|categories:food|partners:partner-1|refinements:note=coffee',
        'totalMinor': 800,
        'entryCount': 1,
        'entries': const <Object?>[],
      };
    });

    final repository = MethodChannelDashboardLedgerRepository(channel: channel);
    await repository.read(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
        categoryIds: const {'food'},
        partnerIds: const {'partner-1'},
        refinements: const {'note': 'coffee'},
      ),
    );

    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['categoryIds'], <Object?>['food']);
    expect(arguments['partnerIds'], <Object?>['partner-1']);
    expect(arguments['refinements'], <String, Object?>{'note': 'coffee'});
  });
}
