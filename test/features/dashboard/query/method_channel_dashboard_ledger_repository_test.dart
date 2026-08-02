import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluvi/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart';

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

  test(
    'decodes a grouped child summary index with canonical child keys',
    () async {
      MethodCall? received;
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      final dayScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 15)),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return <String, Object?>{
          'parentQueryKey': parentScope.key.value,
          'direction': 'expense',
          'childPeriod': 'day',
          'coreRevision': 12,
          'isComplete': false,
          'values': <Object?>[
            <String, Object?>{
              'childPeriodValue': '2026-03-15',
              'childQueryKey': dayScope.key.value,
              'totalMinor': 1075384,
              'entryCount': 4,
            },
          ],
        };
      });

      final repository = MethodChannelDashboardLedgerRepository(
        channel: channel,
      );
      final index = await repository.readChildSummaries(
        DashboardChildSummaryRequest(
          parentScope: parentScope,
          childPeriod: TimeChildPeriod.day,
        ),
      );

      expect(received?.method, 'readDashboardChildSummaries');
      final arguments = received!.arguments! as Map<Object?, Object?>;
      expect(arguments['scopeKey'], parentScope.key.value);
      expect(arguments['childPeriod'], 'day');
      expect(index.coreRevision, 12);
      expect(index.isComplete, isFalse);
      expect(index.direction, LedgerDirection.expense);
      expect(index.values['2026-03-15']?.childQueryKey, dayScope.key.value);
      expect(index.values['2026-03-15']?.totalMinor, 1075384);
    },
  );

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
              'flowId': 'Q-expense-month-2026-07',
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
      expect(
        (receivedArguments! as Map<Object?, Object?>)['debugFlowId'],
        'Q-${scope.key.value}',
      );
      expect(result.totalMinor, 68900000);
      expect(result.entryCount, 100);
      expect(result.scopeKey, scope.key.value);
      expect(result.timeScopeKey, 'month:2026-07');
      expect(result.flowId, 'Q-expense-month-2026-07');
      expect(result.entries.single.categoryColorId, 'color_15');
      expect(result.entries.single.categoryIconId, 'icon_13');
      expect(result.entries.single.partnerDisplayName, 'Lidl');
    },
  );

  test(
    'native bridge result reaches CurrentQueryController and SummaryPill amount',
    () async {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final resultReady = Completer<DashboardQueryState>();
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            events.success(<String, Object?>{
              'scopeKey': scope.key.value,
              'flowId': 'Q-${scope.key.value}',
              'timeScopeKey': 'month:2026-07',
              'direction': 'expense',
              'totalMinor': 68900000,
              'entryCount': 94,
              'coreRevision': 12,
              'entries': const <Object?>[],
            });
          },
        ),
      );

      final controller = CurrentQueryController(
        repository: MethodChannelDashboardLedgerRepository(
          eventChannel: eventChannel,
        ),
        initialScope: scope,
      );
      addTearDown(controller.dispose);
      controller.addListener(() {
        if (controller.state.result != null && !resultReady.isCompleted) {
          resultReady.complete(controller.state);
        }
      });
      controller.refresh();

      final state = await resultReady.future;
      final presentation = SummaryPillPresenter.presentMetrics(query: state);

      expect(presentation.formattedAmount, '689000,00 Ft');
      expect(presentation.scopeKey, scope.key.value);
      expect(presentation.totalMinor, 68900000);
      expect(presentation.entryCount, 94);
      expect(presentation.coreRevision, 12);
      expect(state.result?.flowId, 'Q-${scope.key.value}');
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
