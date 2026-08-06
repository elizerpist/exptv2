import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
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

  test('only explicit committed paging invokes the page method', () async {
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
    final worker = _PageWorker(current);
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
      pageSize: 24,
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );

    final result = await repository.readCommittedPage(
      request,
      after: const <String, Object?>{
        'bookedLocalEpochDay': 20000,
        'bookedLocalTimeMinutes': 600,
        'entryId': 'row-1',
      },
      currentFrame: current,
    );

    expect(result, same(current));
    expect(received?.method, 'readDashboardCommittedPage');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['acquisitionReason'], 'explicitCommittedVerticalPaging');
    expect(arguments['commitGeneration'], 7);
    expect(worker.calls, 1);
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
  }) async {
    calls += 1;
    return index;
  }
}

final class _PageWorker implements DashboardCommittedPageDecodeWorker {
  _PageWorker(this.frame);

  final DashboardPreparedFrame frame;
  int calls = 0;

  @override
  Future<DashboardPreparedFrame> decodePage(
    Uint8List bytes, {
    required DashboardCommittedPageRequest request,
    required DashboardPreparedFrame currentFrame,
  }) async {
    calls += 1;
    return frame;
  }
}
