import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
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
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
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
      repository.complete(0, _page('2026-07', generation: 1));

      expect(await page, isTrue);
      expect(visibleFrames.value?.preparedFrame.presentationDigest, 1);
      expect(committedViewport.pageForOrdinal(1), isNotNull);
      expect(controller.pageReadCount, 1);
    },
  );

  test(
    'a forward demand drains each page ordinal once through its ready frontier',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final demand = controller.requestForwardDemand(3);
      await pumpEventQueue();
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
      ]);

      repository.complete(
        0,
        _page('2026-07', generation: 1, ordinal: 1, hasNext: true),
      );
      await pumpEventQueue();
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
      ]);

      repository.complete(
        0,
        _page('2026-07', generation: 1, ordinal: 2, hasNext: true),
      );
      await pumpEventQueue();
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
        3,
      ]);

      repository.complete(
        0,
        _page('2026-07', generation: 1, ordinal: 3, hasNext: false),
      );
      expect(await demand, isTrue);
      expect(controller.nextPageOrdinal, 4);
      expect(controller.duplicatePageSuppressCount, 0);
    },
  );

  test(
    'an evicted prior page reloads through its bounded keyset cursor chain',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(
        pageSize: 24,
        maximumRetainedPages: 5,
      );
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      for (var ordinal = 1; ordinal <= 6; ordinal += 1) {
        final request = controller.loadNextPage();
        await pumpEventQueue();
        repository.complete(
          0,
          _page(
            '2026-07',
            generation: 1,
            ordinal: ordinal,
            hasNext: ordinal != 6,
          ),
        );
        expect(await request, isTrue);
        committedViewport.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }

      // Match the production trigger: backwards acquisition begins only once
      // the viewport has approached the lowest retained drawable page.
      committedViewport.updateVisibleRowWindow(start: 2 * 24, end: 3 * 24);
      final prior = controller.loadPreviousPage();
      await pumpEventQueue();
      expect(repository.requests.last.pageOrdinal, 2);
      expect(repository.requests.last.startCursor?['entryId'], 'cursor-1');
      repository.complete(
        0,
        _page('2026-07', generation: 1, ordinal: 2, hasNext: true),
      );
      expect(await prior, isTrue);
      expect(committedViewport.pageForOrdinal(2), isNotNull);
    },
  );

  test('the pinned root page never starts a reverse repository read', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    final committedViewport = CommittedLogViewportCache(pageSize: 24);
    addTearDown(visibleFrames.dispose);
    addTearDown(committedViewport.dispose);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      committedViewport: committedViewport,
      pageSize: 24,
    );
    addTearDown(controller.dispose);
    final committed = _visible('2026-07', epoch: 3, digest: 1);
    visibleFrames.publish(committed);
    controller.commitMetadata(committed);

    final forward = controller.loadNextPage();
    await pumpEventQueue();
    repository.complete(0, _page('2026-07', generation: 1));
    expect(await forward, isTrue);
    expect(committedViewport.rootPagePresent, isTrue);
    expect(committedViewport.pageForOrdinal(0), isNotNull);

    expect(await controller.loadPreviousPage(), isFalse);
    expect(repository.requests, hasLength(1));
  });

  test('a page response for an older committed target is rejected', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    final committedViewport = CommittedLogViewportCache(pageSize: 24);
    addTearDown(visibleFrames.dispose);
    addTearDown(committedViewport.dispose);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      committedViewport: committedViewport,
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
    repository.complete(0, _page('2026-07', generation: 1));

    expect(await stalePage, isFalse);
    expect(visibleFrames.value?.queryKey, august.queryKey);
    expect(controller.stalePageRejectCount, 1);
  });

  test('a committed frame without a cursor cannot request a page', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    final committedViewport = CommittedLogViewportCache(pageSize: 24);
    addTearDown(visibleFrames.dispose);
    addTearDown(committedViewport.dispose);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      committedViewport: committedViewport,
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
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var motionActive = true;
      final requested = <DashboardCommittedPageRequest>[];
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
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
      repository.complete(0, _page('2026-07', generation: 1));
      expect(await page, isTrue);
    },
  );

  test(
    'a page completing after rail motion starts is discarded before layout',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var motionActive = false;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        isMotionActive: () => motionActive,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final request = controller.loadNextPage();
      await pumpEventQueue();
      motionActive = true;
      repository.complete(0, _page('2026-07', generation: 1));

      expect(await request, isFalse);
      expect(committedViewport.pageForOrdinal(1), isNull);
      expect(controller.motionPageSuppressCount, 1);
    },
  );

  test(
    'a vertical page failure leaves the last complete page retryable',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final request = controller.loadNextPage();
      await pumpEventQueue();
      repository.fail(0, StateError('synthetic page failure'));

      expect(await request, isFalse);
      expect(committedViewport.pageForOrdinal(0), isNotNull);
      expect(committedViewport.pageForOrdinal(1), isNull);
      expect(committedViewport.pageFailureCount, 1);
      expect(committedViewport.lastError, contains('synthetic page failure'));
    },
  );

  test(
    'a failed cursor retries only after an explicit new demand epoch',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final failed = controller.requestForwardDemand(1);
      await pumpEventQueue();
      repository.fail(0, StateError('retry on an explicit epoch only'));
      expect(await failed, isFalse);
      await pumpEventQueue();
      unawaited(controller.requestForwardDemand(1));
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));

      controller.beginForwardDemandEpoch();
      final retry = controller.requestForwardDemand(1);
      await pumpEventQueue();
      expect(repository.requests, hasLength(2));
      repository.complete(0, _page('2026-07', generation: 1));
      expect(await retry, isTrue);
      expect(
        controller.forwardRequestStates.values,
        contains(CommittedVerticalPageRequestState.committed.name),
      );
    },
  );

  test(
    'one keyset cursor permits at most one in-flight page request',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final committed = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final first = controller.loadNextPage();
      await pumpEventQueue();
      expect(await controller.loadNextPage(), isFalse);
      expect(repository.requests, hasLength(1));
      expect(controller.duplicatePageSuppressCount, 1);

      repository.complete(0, _page('2026-07', generation: 1));
      expect(await first, isTrue);
    },
  );

  test(
    'a stale page error cannot mark the new structural scope failed',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
      );
      addTearDown(controller.dispose);
      final july = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(july);
      controller.commitMetadata(july);
      final stale = controller.loadNextPage();
      await pumpEventQueue();

      final august = _visible('2026-08', epoch: 4, digest: 2);
      visibleFrames.publish(august);
      controller.commitMetadata(august);
      repository.fail(0, StateError('stale failure'));

      expect(await stale, isFalse);
      expect(committedViewport.queryKey, august.queryKey);
      expect(committedViewport.pageFailureCount, 0);
      expect(committedViewport.lastError, isNull);
    },
  );
}

final class _PendingPage {
  const _PendingPage(this.request, this.completer);

  final DashboardCommittedPageRequest request;
  final Completer<CommittedLogPage> completer;
}

final class _PageRepository implements DashboardCommittedPageRepository {
  final List<DashboardCommittedPageRequest> requests = [];
  final List<_PendingPage> _pending = [];

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) {
    requests.add(request);
    final completer = Completer<CommittedLogPage>();
    _pending.add(_PendingPage(request, completer));
    return completer.future;
  }

  void complete(int index, CommittedLogPage page) {
    _pending.removeAt(index).completer.complete(page);
  }

  void fail(int index, Object error) {
    _pending.removeAt(index).completer.completeError(error);
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

CommittedLogPage _page(
  String month, {
  required int generation,
  int ordinal = 1,
  bool hasNext = false,
}) {
  final scope = _scope(month);
  return CommittedLogPage(
    queryKey: scope.key,
    coreRevision: 7,
    generation: generation,
    ordinal: ordinal,
    startCursor: ordinal == 0 ? null : _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const <DashboardDayLogGroupViewModel>[],
      entryCount: 2,
      nextCursor: hasNext ? _cursor(ordinal) : null,
      direction: LedgerDirection.income,
    ),
  );
}

Map<String, Object?> _cursor(int ordinal) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - ordinal,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'cursor-$ordinal',
};

CurrentLedgerQueryScope _scope(String month) {
  final parts = month.split('-');
  return CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: MonthScope(
      YearMonth(year: int.parse(parts[0]), month: int.parse(parts[1])),
    ),
  );
}
