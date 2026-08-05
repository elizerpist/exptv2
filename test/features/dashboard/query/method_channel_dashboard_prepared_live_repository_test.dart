import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_binary_codec.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/data/method_channel_dashboard_prepared_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

import '../prepared/dashboard_prepared_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('test/fluvi-prepared-live-method');
  const events = EventChannel('test/fluvi-prepared-live-events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockStreamHandler(events, null);
  });

  test('live lease sends exact epochs and decodes binary in worker', () async {
    Object? listenArguments;
    messenger.setMockStreamHandler(
      events,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          listenArguments = arguments;
          sink.success(Uint8List.fromList(const [1, 2, 3]));
        },
      ),
    );
    final request = _request();
    final expected = preparedFrameFixture(
      scope: request.scope,
      parentQueryKey: request.parentQueryKey,
      revision: request.coreRevision,
      digest: 82,
    );
    final worker = _FrameWorker(expected);
    final repository = MethodChannelDashboardPreparedRepository(
      channel: method,
      eventChannel: events,
      preparedFrameDecodeWorker: worker,
    );

    final frame = await repository.watchCommittedFrame(request).first;

    expect(frame, same(expected));
    expect(worker.calls, 1);
    final arguments = listenArguments! as Map<Object?, Object?>;
    expect(arguments['scopeKey'], request.scope.key.value);
    expect(arguments['parentQueryKey'], request.parentQueryKey.value);
    expect(arguments['coreRevision'], 3);
    expect(arguments['presentationEpoch'], 9);
    expect(arguments['leaseGeneration'], 4);
    expect(arguments['pageSize'], 24);
  });

  test('prepared paging uses one bounded binary method call', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(method, (call) async {
      received = call;
      return Uint8List.fromList(const [4, 5, 6]);
    });
    final request = _request();
    final expected = preparedFrameFixture(
      scope: request.scope,
      parentQueryKey: request.parentQueryKey,
      revision: request.coreRevision,
      digest: 83,
    );
    final worker = _FrameWorker(expected);
    final repository = MethodChannelDashboardPreparedRepository(
      channel: method,
      preparedFrameDecodeWorker: worker,
    );

    final frame = await repository.readCommittedNextPage(
      request,
      after: const {
        'bookedLocalEpochDay': 20000,
        'bookedLocalTimeMinutes': 600,
        'entryId': 'row-1',
      },
      currentFrame: expected,
    );

    expect(frame, same(expected));
    expect(received?.method, 'readDashboardPreparedFrame');
    final arguments = received!.arguments! as Map<Object?, Object?>;
    expect(arguments['after'], isA<Map<Object?, Object?>>());
    expect(arguments['leaseGeneration'], 4);
    expect(worker.calls, 1);
  });
}

DashboardCommittedFrameRequest _request() {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );
  return DashboardCommittedFrameRequest(
    scope: parent.copyWith(
      timeScope: DayScope(const YearMonth(year: 2026, month: 7).clampDay(14)),
    ),
    parentQueryKey: parent.key,
    coreRevision: 3,
    presentationEpoch: 9,
    leaseGeneration: 4,
    pageSize: 24,
  );
}

final class _FrameWorker implements DashboardPreparedFrameDecodeWorker {
  _FrameWorker(this.frame);

  final DashboardPreparedFrame frame;
  int calls = 0;

  @override
  Future<DashboardPreparedFrame> decodeFrame(
    Uint8List bytes, {
    required DashboardCommittedFrameRequest request,
  }) async {
    calls += 1;
    return frame;
  }

  @override
  Future<DashboardPreparedFrame> decodePage(
    Uint8List bytes, {
    required DashboardCommittedFrameRequest request,
    required DashboardPreparedFrame currentFrame,
  }) async {
    calls += 1;
    return frame;
  }
}
