import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_deck_repository.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_committed_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../prepared/dashboard_prepared_test_fixtures.dart';

void main() {
  test('preview ownership starts no lease', () async {
    final repository = _LiveRepository();
    final store = DashboardVisibleFrameStore();
    final controller = DashboardCommittedQueryController(
      visibleFrames: store,
      repository: repository,
    );
    addTearDown(controller.dispose);
    addTearDown(store.dispose);

    store.publish(_visible());
    await pumpEventQueue();

    expect(repository.liveStarts, 0);
    expect(controller.state.hasCommit, isFalse);
    expect(await controller.loadNextPage(), isFalse);
  });

  test('duplicate commit keeps the one exact live lease', () async {
    final repository = _LiveRepository();
    final store = DashboardVisibleFrameStore();
    final controller = DashboardCommittedQueryController(
      visibleFrames: store,
      repository: repository,
    );
    addTearDown(controller.dispose);
    addTearDown(store.dispose);
    final first = _visible();

    await controller.commit(first.asCommitted());
    await controller.commit(first.asCommitted());

    expect(repository.liveStarts, 1);
    expect(repository.cancelCount, 0);
    expect(controller.state.liveLeaseGeneration, 1);
    expect(repository.requests.last.leaseGeneration, 1);
    expect(repository.requests.last.scope.key, first.queryKey);
  });

  test(
    'invalidation requires one replacement lease for the same frame',
    () async {
      final repository = _LiveRepository();
      final store = DashboardVisibleFrameStore();
      final controller = DashboardCommittedQueryController(
        visibleFrames: store,
        repository: repository,
      );
      addTearDown(controller.dispose);
      addTearDown(store.dispose);
      final frame = _visible().asCommitted();

      await controller.commit(frame);
      controller.invalidate();
      await controller.commit(frame);

      expect(repository.liveStarts, 2);
      expect(repository.cancelCount, 1);
      expect(controller.state.liveLeaseGeneration, 3);
    },
  );

  test(
    'invalidation removes paging ownership before motion can read',
    () async {
      final repository = _LiveRepository();
      final store = DashboardVisibleFrameStore();
      final controller = DashboardCommittedQueryController(
        visibleFrames: store,
        repository: repository,
      );
      addTearDown(controller.dispose);
      addTearDown(store.dispose);
      final frame = _visible(withNextPage: true).asCommitted();

      await controller.commit(frame);
      controller.invalidate();

      expect(await controller.loadNextPage(), isFalse);
      expect(repository.pageReads, 0);
    },
  );

  test('wrong direction, revision and scope callbacks are rejected', () async {
    final repository = _LiveRepository();
    final store = DashboardVisibleFrameStore();
    final controller = DashboardCommittedQueryController(
      visibleFrames: store,
      repository: repository,
    );
    addTearDown(controller.dispose);
    addTearDown(store.dispose);
    final visible = _visible();
    store.publish(visible);
    await controller.commit(visible.asCommitted());

    repository.emit(
      preparedFrameFixture(
        scope: visible.scope.copyWith(direction: LedgerDirection.expense),
        parentQueryKey: visible.parentQueryKey,
        revision: visible.coreRevision,
        digest: 8,
      ),
    );
    repository.emit(
      preparedFrameFixture(
        scope: visible.scope,
        parentQueryKey: visible.parentQueryKey,
        revision: visible.coreRevision + 1,
        digest: 9,
      ),
    );
    await pumpEventQueue();

    expect(controller.staleCallbackRejectedCount, 2);
    expect(controller.liveFrameAcceptedCount, 0);
    expect(store.visiblePublishCount, 1);
  });

  test(
    'exact live frame is accepted without touching motion ownership',
    () async {
      final repository = _LiveRepository();
      final store = DashboardVisibleFrameStore();
      final controller = DashboardCommittedQueryController(
        visibleFrames: store,
        repository: repository,
      );
      addTearDown(controller.dispose);
      addTearDown(store.dispose);
      final visible = _visible();
      store.publish(visible);
      await controller.commit(visible.asCommitted());
      final prepared = preparedFrameFixture(
        scope: visible.scope,
        parentQueryKey: visible.parentQueryKey,
        revision: visible.coreRevision,
        digest: 912,
      );

      repository.emit(prepared);
      await pumpEventQueue();

      expect(controller.liveFrameAcceptedCount, 1);
      expect(store.value?.queryKey, visible.queryKey);
      expect(store.value?.coreRevision, visible.coreRevision);
      expect(store.value?.amount.totalMinor, 912);
      expect(store.value?.mode, DashboardVisibleMode.committed);
    },
  );

  test('same digest live response is a visual no-op', () async {
    final repository = _LiveRepository();
    final store = DashboardVisibleFrameStore();
    final controller = DashboardCommittedQueryController(
      visibleFrames: store,
      repository: repository,
    );
    addTearDown(controller.dispose);
    addTearDown(store.dispose);
    final visible = _visible();
    store.publish(visible.asCommitted());
    await controller.commit(visible.asCommitted());
    final publishes = store.visiblePublishCount;

    repository.emit(_prepared(digest: 71));
    await pumpEventQueue();

    expect(store.visiblePublishCount, publishes);
    expect(store.visualNoOpCount, 1);
  });
}

DashboardVisibleFrame _visible({bool withNextPage = false}) {
  final prepared = _prepared(digest: 71, withNextPage: withNextPage);
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: TimePlane.month,
    railOpen: true,
    semanticIndex: 13,
    childLabel: '14',
    navigationEpoch: 4,
    presentationEpoch: 8,
    frameGeneration: 12,
    mode: DashboardVisibleMode.preview,
  );
}

DashboardPreparedFrame _prepared({
  required int digest,
  bool withNextPage = false,
}) {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );
  return preparedFrameFixture(
    scope: parent.copyWith(
      timeScope: DayScope(const YearMonth(year: 2026, month: 7).clampDay(14)),
    ),
    parentQueryKey: parent.key,
    revision: 1,
    digest: digest,
    nextCursor: withNextPage
        ? const <String, Object?>{
            'bookedLocalEpochDay': 20648,
            'bookedLocalTimeMinutes': 720,
            'entryId': 'cursor-entry',
          }
        : null,
  );
}

final class _LiveRepository implements DashboardPreparedLiveRepository {
  final List<DashboardCommittedFrameRequest> requests = [];
  StreamController<DashboardPreparedFrame>? _controller;
  int liveStarts = 0;
  int cancelCount = 0;
  int pageReads = 0;

  @override
  Stream<DashboardPreparedFrame> watchCommittedFrame(
    DashboardCommittedFrameRequest request,
  ) {
    liveStarts += 1;
    requests.add(request);
    _controller = StreamController<DashboardPreparedFrame>(
      onCancel: () => cancelCount += 1,
    );
    return _controller!.stream;
  }

  void emit(DashboardPreparedFrame frame) => _controller!.add(frame);

  @override
  Future<DashboardPreparedFrame> readCommittedNextPage(
    DashboardCommittedFrameRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) {
    pageReads += 1;
    return Future<DashboardPreparedFrame>.value(currentFrame);
  }
}
