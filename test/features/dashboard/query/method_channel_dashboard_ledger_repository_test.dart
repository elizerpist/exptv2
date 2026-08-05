import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';

import 'package:fluvi/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_binary_codec.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart';

import '../prepared/dashboard_prepared_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.fluvi/dashboard_query');
  const eventChannel = EventChannel('com.fluvi/dashboard_query_stream');
  const revisionEventChannel = EventChannel(
    'com.fluvi/dashboard_core_revision_stream',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockStreamHandler(eventChannel, null);
    messenger.setMockStreamHandler(revisionEventChannel, null);
  });

  test('prepared response is delegated once to a non-UI worker', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return Uint8List.fromList(const <int>[1, 2, 3]);
    });
    final expected = preparedDeckFixture();
    final request = DashboardPreparedDeckRequest.fromDeck(expected);
    final worker = _RecordingPreparedWorker(expected);
    final repository = MethodChannelDashboardLedgerRepository(
      channel: channel,
      preparedDecodeWorker: worker,
    );

    final result = await repository.prepareDeck(
      request,
      DashboardPreparationToken(generation: 17, required: true),
    );

    expect(result, same(expected));
    expect(worker.invocations, 1);
    expect(worker.workerIsolateName, 'test-dashboard-prepared-worker');
    expect(worker.workerIsolateName, isNot(Isolate.current.debugName));
    expect(received?.method, 'readDashboardPreparedDeck');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['childPeriod'], 'day');
    expect(arguments['requestGeneration'], 17);
    expect(arguments['pageSize'], 24);
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

  test('decodes one stable core revision invalidation stream', () async {
    var listenCount = 0;
    messenger.setMockStreamHandler(
      revisionEventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          listenCount += 1;
          expect(arguments, isNull);
          events.success(<String, Object?>{'coreRevision': 12});
        },
      ),
    );
    final repository = MethodChannelDashboardLedgerRepository(
      revisionEventChannel: revisionEventChannel,
    );

    final revision = await repository.watchCoreRevision().first;

    expect(revision, 12);
    expect(listenCount, 1);
  });

  test(
    'decodes a complete child preview bundle without per-child query state',
    () async {
      FluviDiagnosticLogger.clear();
      MethodCall? received;
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      final childScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return <String, Object?>{
          'parentQueryKey': parentScope.key.value,
          'direction': 'expense',
          'childPeriod': 'day',
          'coreRevision': 12,
          'previewPageSize': 1,
          'requestGeneration': 17,
          'requestId':
              '${parentScope.key.value}|child:day|page:1|generation:17',
          'children': <Object?>[
            <String, Object?>{
              'childPeriodValue': '2026-03-21',
              'scopeKey': childScope.key.value,
              'timeScopeKey': 'day:2026-03-21',
              'direction': 'expense',
              'totalMinor': 68900000,
              'entryCount': 2,
              'coreRevision': 12,
              'entries': <Object?>[
                <String, Object?>{
                  'id': 'preview-row',
                  'partnerId': 'partner',
                  'partnerDisplayName': 'Lidl',
                  'categoryId': 'category',
                  'categoryDisplayName': 'Food',
                  'categoryColorId': 'color_02',
                  'categoryIconId': 'icon_02',
                  'assignmentMode': 'partnerDefault',
                  'originKind': 'manual',
                  'direction': 'expense',
                  'amountMinor': 1234,
                  'bookedLocalEpochDay': 20533,
                  'bookedLocalTimeMinutes': 720,
                  'note': 'preview',
                  'occurredAtUtcMs': 1782900000000,
                },
              ],
              'nextCursor': <String, Object?>{
                'bookedLocalEpochDay': 20533,
                'bookedLocalTimeMinutes': 720,
                'entryId': 'preview-row',
              },
            },
          ],
        };
      });

      final repository = MethodChannelDashboardLedgerRepository(
        channel: channel,
      );
      final bundle = await repository.readChildPreviewBundle(
        DashboardChildPreviewBundleRequest(
          parentScope: parentScope,
          childPeriod: TimeChildPeriod.day,
          previewPageSize: 1,
          requestGeneration: 17,
        ),
      );

      expect(received?.method, 'readDashboardChildPreviewBundle');
      final arguments = received!.arguments! as Map<Object?, Object?>;
      expect(arguments['scopeKey'], parentScope.key.value);
      expect(arguments['childPeriod'], 'day');
      expect(arguments['pageSize'], 1);
      expect(arguments['requestGeneration'], 17);
      expect(
        arguments['requestId'],
        '${parentScope.key.value}|child:day|page:1|generation:17',
      );
      final child = bundle.childrenByQueryKey[childScope.key];
      expect(child?.result.totalMinor, 68900000);
      expect(child?.result.entryCount, 2);
      expect(child?.result.entries.single.id, 'preview-row');
      expect(child?.result.nextCursor?['entryId'], 'preview-row');
      final aggregateEvents = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'CHILD_PREVIEW_BUNDLE_PARSED')
          .toList();
      expect(aggregateEvents, hasLength(1));
      expect(aggregateEvents.single.entryCount, 2);
      expect(
        FluviDiagnosticLogger.entries.where((event) => event.stage == 'D7'),
        isEmpty,
      );
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
      var exactWatchListenCount = 0;
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            exactWatchListenCount += 1;
          },
        ),
      );
      messenger.setMockStreamHandler(
        revisionEventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            events.success(<String, Object?>{'coreRevision': 12});
          },
        ),
      );
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'readDashboard');
        return <String, Object?>{
          'scopeKey': scope.key.value,
          'flowId': 'Q-${scope.key.value}',
          'timeScopeKey': 'month:2026-07',
          'direction': 'expense',
          'totalMinor': 68900000,
          'entryCount': 94,
          'coreRevision': 12,
          'entries': const <Object?>[],
        };
      });

      final controller = CurrentQueryController(
        repository: MethodChannelDashboardLedgerRepository(
          channel: channel,
          eventChannel: eventChannel,
          revisionEventChannel: revisionEventChannel,
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
      expect(exactWatchListenCount, 0);
      expect(controller.exactWatchStartCount, 0);
      expect(controller.oneShotReadCount, 1);
      expect(controller.coreRevisionSubscriptionCount, 1);
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

final class _RecordingPreparedWorker
    implements DashboardPreparedDeckDecodeWorker {
  _RecordingPreparedWorker(this.result);

  final DashboardPreparedDeck result;
  int invocations = 0;
  String? workerIsolateName;

  @override
  Future<DashboardPreparedDeck> decode(
    Uint8List bytes, {
    required DashboardPreparedDeckRequest request,
    required int expectedGeneration,
  }) async {
    invocations += 1;
    workerIsolateName = await Isolate.run(
      () => Isolate.current.debugName,
      debugName: 'test-dashboard-prepared-worker',
    );
    return result;
  }
}
