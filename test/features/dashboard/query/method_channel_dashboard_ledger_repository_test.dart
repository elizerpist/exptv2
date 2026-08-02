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
  const eventChannel = EventChannel('com.fluvi/dashboard_query_stream');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockStreamHandler(eventChannel, null);
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

  test(
    'observes the native Room-backed dashboard stream with the same scope',
    () async {
      Object? receivedArguments;
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            receivedArguments = arguments;
            events.success(<String, Object?>{
              'scopeKey':
                  'expense|month:2026-07|categories:|partners:|refinements:',
              'timeScopeKey': 'month:2026-07',
              'direction': 'expense',
              'totalMinor': 68900000,
              'entryCount': 100,
              'coreRevision': 12,
              'entries': <Object?>[
                <String, Object?>{
                  'id': '01JDEMOENTRY00000000000000',
                  'partnerId': '01JDEMOPARTNER000000000000',
                  'partnerDisplayName': 'Lidl',
                  'categoryId': '01JDEMOCATEGORY000000000000',
                  'categoryDisplayName': 'Élelmiszer',
                  'categoryColorId': 'color_15',
                  'categoryIconId': 'icon_13',
                  'assignmentMode': 'partnerDefault',
                  'originKind': 'manual',
                  'direction': 'expense',
                  'amountMinor': 129900,
                  'bookedLocalEpochDay': 20655,
                  'bookedLocalTimeMinutes': 720,
                  'note': 'Bevásárlás',
                  'occurredAtUtcMs': 1782900000000,
                },
              ],
            });
          },
        ),
      );

      final repository = MethodChannelDashboardLedgerRepository(
        eventChannel: eventChannel,
      );
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );

      final result = await repository.watch(scope).first;

      expect(receivedArguments, isA<Map<Object?, Object?>>());
      expect(
        (receivedArguments! as Map<Object?, Object?>)['scopeKey'],
        scope.key.value,
      );
      expect(result.totalMinor, 68900000);
      expect(result.entryCount, 100);
      expect(result.scopeKey, scope.key.value);
      expect(result.timeScopeKey, 'month:2026-07');
      expect(result.entries.single.categoryColorId, 'color_15');
      expect(result.entries.single.categoryIconId, 'icon_13');
      expect(result.entries.single.partnerDisplayName, 'Lidl');
    },
  );

  test('encodes a cursor for the next bounded ledger page', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{
        'scopeKey': 'expense|month:2026-07|categories:|partners:|refinements:',
        'totalMinor': 68900000,
        'entryCount': 100,
        'coreRevision': 12,
        'entries': const <Object?>[],
        'nextCursor': <String, Object?>{
          'bookedLocalEpochDay': 20655,
          'bookedLocalTimeMinutes': 720,
          'entryId': '01JDEMOENTRY00000000000000',
        },
      };
    });

    final repository = MethodChannelDashboardLedgerRepository(channel: channel);
    final result = await repository.read(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      ),
      pageSize: 25,
      after: const <String, Object?>{
        'bookedLocalEpochDay': 20656,
        'bookedLocalTimeMinutes': 700,
        'entryId': '01JDEMOENTRY00000000000001',
      },
    );

    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['pageSize'], 25);
    expect(arguments['after'], <String, Object?>{
      'bookedLocalEpochDay': 20656,
      'bookedLocalTimeMinutes': 700,
      'entryId': '01JDEMOENTRY00000000000001',
    });
    expect(result.nextCursor?['entryId'], '01JDEMOENTRY00000000000000');
  });
}
