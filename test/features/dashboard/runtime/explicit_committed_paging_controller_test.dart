import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/application/explicit_committed_paging_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'metadata commit performs no acquisition and near-end paging is explicit',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(visibleFrames.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);

      controller.commitMetadata(committed);

      expect(repository.requests, isEmpty);
      expect(controller.committedQueryKey, committed.queryKey);

      final page = controller.loadNextPage();
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));
      expect(
        repository.requests.single.reason,
        DataAcquisitionReason.explicitCommittedVerticalPaging,
      );
      repository.complete(0, _prepared('2026-07', digest: 2, hasCursor: false));

      expect(await page, isTrue);
      expect(visibleFrames.value?.preparedFrame.presentationDigest, 2);
      expect(controller.pageReadCount, 1);
    },
  );

  test('a page response for an older committed target is rejected', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(visibleFrames.dispose);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      pageSize: 24,
    );
    addTearDown(controller.dispose);
    final july = _visible('2026-07', epoch: 3, digest: 1);
    visibleFrames.publish(july);
    controller.commitMetadata(july);
    final stalePage = controller.loadNextPage();
    await pumpEventQueue();

    final august = _visible('2026-08', epoch: 4, digest: 3);
    visibleFrames.publish(august);
    controller.commitMetadata(august);
    repository.complete(0, _prepared('2026-07', digest: 2, hasCursor: false));

    expect(await stalePage, isFalse);
    expect(visibleFrames.value?.queryKey, august.queryKey);
    expect(controller.stalePageRejectCount, 1);
  });

  test('a committed frame without a cursor cannot request a page', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    addTearDown(visibleFrames.dispose);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      pageSize: 24,
    );
    addTearDown(controller.dispose);
    final complete = DashboardVisibleFrame.fromPrepared(
      _prepared('2026-07', digest: 1, hasCursor: false),
      parentQueryKey: _scope('2026-07').key,
      plane: TimePlane.month,
      railOpen: false,
      semanticIndex: 13,
      childLabel: '14',
      navigationEpoch: 1,
      presentationEpoch: 3,
      frameGeneration: 1,
      mode: DashboardVisibleMode.committed,
    );
    visibleFrames.publish(complete);
    controller.commitMetadata(complete);

    expect(await controller.loadNextPage(), isFalse);
    expect(repository.requests, isEmpty);
  });

  test(
    'near-end paging is suppressed rather than queued during rail motion',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      addTearDown(visibleFrames.dispose);
      var motionActive = true;
      final requested = <DashboardCommittedPageRequest>[];
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        pageSize: 24,
        isMotionActive: () => motionActive,
        onPageRequested: requested.add,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      expect(await controller.loadNextPage(), isFalse);
      expect(repository.requests, isEmpty);
      expect(requested, isEmpty);
      expect(controller.motionPageSuppressCount, 1);

      motionActive = false;
      final page = controller.loadNextPage();
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));
      expect(requested, hasLength(1));
      repository.complete(0, _prepared('2026-07', digest: 2, hasCursor: false));
      expect(await page, isTrue);
    },
  );
}

final class _PendingPage {
  const _PendingPage(this.request, this.completer);

  final DashboardCommittedPageRequest request;
  final Completer<DashboardPreparedFrame> completer;
}

final class _PageRepository implements DashboardCommittedPageRepository {
  final List<DashboardCommittedPageRequest> requests = [];
  final List<_PendingPage> _pending = [];

  @override
  Future<DashboardPreparedFrame> readCommittedPage(
    DashboardCommittedPageRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  }) {
    requests.add(request);
    final completer = Completer<DashboardPreparedFrame>();
    _pending.add(_PendingPage(request, completer));
    return completer.future;
  }

  void complete(int index, DashboardPreparedFrame frame) {
    _pending.removeAt(index).completer.complete(frame);
  }
}

DashboardVisibleFrame _visible(
  String month, {
  required int epoch,
  required int digest,
}) {
  final scope = _scope(month);
  return DashboardVisibleFrame.fromPrepared(
    _prepared(month, digest: digest, hasCursor: true),
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 13,
    childLabel: '14',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: epoch,
    mode: DashboardVisibleMode.committed,
  );
}

DashboardPreparedFrame _prepared(
  String month, {
  required int digest,
  required bool hasCursor,
}) {
  final scope = _scope(month);
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 7,
    totalMinor: 100,
    formattedAmount: '1,00 Ft',
    entryCount: 2,
    formattedEntryCount: '2',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const [],
      entryCount: 2,
      nextCursor: hasCursor
          ? const {
              'bookedLocalEpochDay': 1,
              'bookedLocalTimeMinutes': 2,
              'entryId': 'cursor',
            }
          : null,
      direction: LedgerDirection.income,
    ),
    presentationDigest: digest,
  );
}

CurrentLedgerQueryScope _scope(String month) {
  final parts = month.split('-');
  return CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: MonthScope(
      YearMonth(year: int.parse(parts[0]), month: int.parse(parts[1])),
    ),
  );
}
