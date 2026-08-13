import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_directional_query_set.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_committed_page_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/method_channel_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_dashboard_index_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

import 'dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('test/fluvi-dashboard-runtime');
  const revisions = EventChannel('test/fluvi-dashboard-revisions');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(revisions, null);
  });

  test('bootstrap makes one global index call and decodes in worker', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(method, (call) async {
      received = call;
      return Uint8List.fromList(const [1, 2, 3]);
    });
    final request = _indexRequest();
    final expected = buildRuntimeTestIndex(revision: 3, generation: 4);
    final worker = _IndexWorker(expected);
    final repository = MethodChannelDashboardDataRuntimeRepository(
      channel: method,
      revisionEventChannel: revisions,
      indexDecodeWorker: worker,
    );

    final result = await repository.prepareIndex(
      request,
      DashboardIndexPreparationToken(generation: 4),
    );

    expect(result.key, expected.key);
    expect(result.frames, same(expected.frames));
    expect(result.catalogs, same(expected.catalogs));
    expect(
      result.buildMetrics.bridgeTransferDurationMicros,
      greaterThanOrEqualTo(0),
    );
    expect(worker.calls, 1);
    expect(received?.method, 'readDashboardPreparedIndex');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['requestGeneration'], 4);
    expect(arguments['coreRevision'], 3);
    expect(arguments['yearWindowStart'], 2014);
    expect(arguments['yearWindowEndInclusive'], 2038);
    expect(arguments['acquisitionReason'], 'bootstrap');
    expect(repository.performanceReport()['index_build_calls'], 1);
  });

  test('global revision stream is the only long-lived subscription', () async {
    var listenCount = 0;
    messenger.setMockStreamHandler(
      revisions,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          listenCount += 1;
          sink.success(<String, Object?>{'coreRevision': 3});
          sink.success(<String, Object?>{'coreRevision': 3});
          sink.success(<String, Object?>{'coreRevision': 4});
          sink.endOfStream();
        },
      ),
    );
    final repository = MethodChannelDashboardDataRuntimeRepository(
      channel: method,
      revisionEventChannel: revisions,
      indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
    );

    expect(await repository.watchCoreRevision().toList(), <int>[3, 4]);
    expect(listenCount, 1);
  });

  test(
    'prepared-index transport preserves the restrictive query period',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(method, (call) async {
        received = call;
        return Uint8List.fromList(const [1, 2, 3]);
      });
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>[
          QueryPeriodSelection.month(2026, 2),
          QueryPeriodSelection.month(2026, 8),
        ]),
      );
      final request = PreparedDashboardIndexRequest(
        key: PreparedDashboardIndexKey.fromScope(
          scope: scope,
          coreRevision: 3,
          pageSize: 24,
          yearWindowStart: 2014,
          yearWindowEndInclusive: 2038,
        ),
        filterScope: scope,
        initialYear: 2026,
        reason: DataAcquisitionReason.bootstrap,
      );
      final repository = MethodChannelDashboardDataRuntimeRepository(
        channel: method,
        revisionEventChannel: revisions,
        indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      );

      await repository.prepareIndex(
        request,
        DashboardIndexPreparationToken(generation: 1),
      );

      final arguments = received!.arguments! as Map<Object?, Object?>;
      expect(
        (arguments['expenseFilter']! as Map<Object?, Object?>)['periodGroups'],
        <Object?>[
          <String, Object?>{
            'key': 'time',
            'selections': <Object?>[
              <String, Object?>{'kind': 'month', 'value': '2026-02'},
              <String, Object?>{'kind': 'month', 'value': '2026-08'},
            ],
          },
        ],
      );
      expect(arguments.containsKey('periodGroups'), isFalse);
    },
  );

  test(
    'prepared-index transport carries independent directional filters',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(method, (call) async {
        received = call;
        return Uint8List.fromList(const [1, 2, 3]);
      });
      final income = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
      );
      final expense = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2026, 6),
          QueryPeriodSelection.month(2026, 8),
        }),
        categoryIds: const <String>{'food'},
      );
      final filters = DashboardDirectionalQuerySet(
        income: income,
        expense: expense,
      );
      final request = PreparedDashboardIndexRequest(
        key: PreparedDashboardIndexKey.fromDirectionalQuerySet(
          queries: filters,
          coreRevision: 3,
          pageSize: 24,
          yearWindowStart: 2014,
          yearWindowEndInclusive: 2038,
        ),
        directionalQueries: filters,
        initialYear: 2026,
        reason: DataAcquisitionReason.query,
      );
      final repository = MethodChannelDashboardDataRuntimeRepository(
        channel: method,
        revisionEventChannel: revisions,
        indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      );

      await repository.prepareIndex(
        request,
        DashboardIndexPreparationToken(generation: 1),
      );

      final arguments = received!.arguments! as Map<Object?, Object?>;
      final incomeFilter = arguments['incomeFilter']! as Map<Object?, Object?>;
      final expenseFilter =
          arguments['expenseFilter']! as Map<Object?, Object?>;
      expect(incomeFilter['direction'], 'income');
      expect(incomeFilter['categoryIds'], isEmpty);
      expect(expenseFilter['direction'], 'expense');
      expect(expenseFilter['categoryIds'], <Object?>['food']);
      expect(expenseFilter['periodGroups'], isNotEmpty);
      expect(arguments.containsKey('periodGroups'), isFalse);
    },
  );

  test(
    'directional partition transport requests only the changed lane',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(method, (call) async {
        received = call;
        return Uint8List.fromList(const [1, 2, 3]);
      });
      final request = _indexRequest();
      final repository = MethodChannelDashboardDataRuntimeRepository(
        channel: method,
        revisionEventChannel: revisions,
        indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      );

      await repository.prepareIndexPartition(
        PreparedDashboardIndexPartitionRequest(
          request: request,
          direction: LedgerDirection.expense,
        ),
        DashboardIndexPreparationToken(generation: 9),
      );

      expect(received?.method, 'readDashboardPreparedIndexPartition');
      final arguments = received!.arguments! as Map<Object?, Object?>;
      expect(arguments['direction'], 'expense');
      expect(arguments['requestGeneration'], 9);
      expect(arguments['incomeFilter'], isNotNull);
      expect(arguments['expenseFilter'], isNotNull);
    },
  );

  test(
    'prepared index diagnostic identity covers both directional filters',
    () {
      final income = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
      );
      final expense = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      final initial = PreparedDashboardIndexKey.fromDirectionalQuerySet(
        queries: DashboardDirectionalQuerySet(income: income, expense: expense),
        coreRevision: 3,
        pageSize: 24,
        yearWindowStart: 2014,
        yearWindowEndInclusive: 2038,
      );
      final changed = PreparedDashboardIndexKey.fromDirectionalQuerySet(
        queries: DashboardDirectionalQuerySet(
          income: income.copyWith(categoryIds: const <String>{'salary'}),
          expense: expense,
        ),
        coreRevision: 3,
        pageSize: 24,
        yearWindowStart: 2014,
        yearWindowEndInclusive: 2038,
      );

      expect(initial.diagnosticIdentity, contains('income:income|'));
      expect(initial.diagnosticIdentity, contains('expense:expense|'));
      expect(changed.diagnosticIdentity, isNot(initial.diagnosticIdentity));
    },
  );

  test(
    'prepared-index transport forwards the explicit Query acquisition reason',
    () async {
      MethodCall? received;
      messenger.setMockMethodCallHandler(method, (call) async {
        received = call;
        return Uint8List.fromList(const [1, 2, 3]);
      });
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.year(2025),
        }),
      );
      final request = PreparedDashboardIndexRequest(
        key: PreparedDashboardIndexKey.fromScope(
          scope: scope,
          coreRevision: 3,
          pageSize: 24,
          yearWindowStart: 2013,
          yearWindowEndInclusive: 2037,
        ),
        filterScope: scope,
        initialYear: 2025,
        reason: DataAcquisitionReason.query,
      );
      final repository = MethodChannelDashboardDataRuntimeRepository(
        channel: method,
        revisionEventChannel: revisions,
        indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      );

      await repository.prepareIndex(
        request,
        DashboardIndexPreparationToken(generation: 2),
      );

      expect(received?.method, 'readDashboardPreparedIndex');
      expect(
        (received!.arguments! as Map<Object?, Object?>)['acquisitionReason'],
        'query',
      );
    },
  );

  test(
    'Query preparation cancellation forwards the exact generation',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(method, (call) async {
        calls.add(call);
        return null;
      });
      final repository = MethodChannelDashboardDataRuntimeRepository(
        channel: method,
        revisionEventChannel: revisions,
        indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      );

      await repository.cancelPreparedIndex(
        DashboardIndexPreparationToken(
          generation: 17,
          reason: DataAcquisitionReason.query,
        ),
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'cancelDashboardPreparedIndex');
      expect(calls.single.arguments, <String, Object?>{
        'requestGeneration': 17,
      });
    },
  );

  test('only explicit committed paging invokes the page method', () async {
    FluviDiagnosticLogger.clear();
    MethodCall? received;
    messenger.setMockMethodCallHandler(method, (call) async {
      received = call;
      return Uint8List.fromList(const [4, 5, 6]);
    });
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 14)),
    );
    final current = runtimeTestFrame(scope, revision: 3);
    final page = CommittedLogPage(
      queryKey: scope.key,
      coreRevision: 3,
      generation: 7,
      ordinal: 1,
      startCursor: const <String, Object?>{
        'bookedLocalEpochDay': 20000,
        'bookedLocalTimeMinutes': 600,
        'entryId': 'row-1',
      },
      previousStartCursor: null,
      payload: current.logBox,
    );
    final worker = _PageWorker(page);
    final repository = MethodChannelDashboardDataRuntimeRepository(
      channel: method,
      revisionEventChannel: revisions,
      indexDecodeWorker: _IndexWorker(buildRuntimeTestIndex(revision: 3)),
      pageDecodeWorker: worker,
    );
    final request = DashboardCommittedPageRequest(
      scope: scope,
      parentQueryKey: scope.key,
      coreRevision: 3,
      presentationEpoch: 9,
      commitGeneration: 7,
      authoritativeTotalMinor: current.amount.totalMinor,
      authoritativeEntryCount: current.count.entryCount,
      pageSize: 24,
      pageOrdinal: 1,
      startCursor: const <String, Object?>{
        'bookedLocalEpochDay': 20000,
        'bookedLocalTimeMinutes': 600,
        'entryId': 'row-1',
      },
      previousStartCursor: null,
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );

    final result = await repository.readCommittedPage(request);

    expect(result, same(page));
    expect(received?.method, 'readDashboardCommittedPage');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['acquisitionReason'], 'explicitCommittedVerticalPaging');
    expect(arguments['commitGeneration'], 7);
    expect(arguments['authoritativeTotalMinor'], current.amount.totalMinor);
    expect(arguments['authoritativeEntryCount'], current.count.entryCount);
    expect(worker.calls, 1);
    final transport = FluviDiagnosticLogger.entries.lastWhere(
      (event) => event.stage == 'VERTICAL_PAGE_TRANSPORT_READY',
    );
    expect(transport.message, contains('dartPlatformCallMicros='));
    expect(transport.message, contains('platformResponseDeliveryGapMicros='));
    expect(transport.message, contains('dartResultCallbackTimestamp='));
    expect(transport.message, contains('decodeStartedAt='));
    expect(transport.message, isNot(contains('bridgeMicros=')));
  });
}

PreparedDashboardIndexRequest _indexRequest() {
  final filterScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const AllTimeScope(),
  );
  return PreparedDashboardIndexRequest(
    key: PreparedDashboardIndexKey.fromScope(
      scope: filterScope,
      coreRevision: 3,
      pageSize: 24,
      yearWindowStart: 2014,
      yearWindowEndInclusive: 2038,
    ),
    filterScope: filterScope,
    initialYear: 2026,
    reason: DataAcquisitionReason.bootstrap,
  );
}

final class _IndexWorker implements DashboardPreparedIndexDecodeWorker {
  _IndexWorker(this.index);

  final PreparedDashboardIndex index;
  int calls = 0;

  @override
  Future<PreparedDashboardIndex> decode(
    Uint8List bytes, {
    required PreparedDashboardIndexRequest request,
    required int expectedGeneration,
    LedgerDirection? expectedPartitionDirection,
  }) async {
    calls += 1;
    return index;
  }
}

final class _PageWorker implements DashboardCommittedPageDecodeWorker {
  _PageWorker(this.page);

  final CommittedLogPage page;
  int calls = 0;

  @override
  Future<CommittedLogPage> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
  }) async {
    calls += 1;
    return page;
  }
}
