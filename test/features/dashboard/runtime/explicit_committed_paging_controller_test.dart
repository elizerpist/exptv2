import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
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
      expect(repository.requests.single.authoritativeEntryCount, 2);
      expect(repository.requests.single.authoritativeTotalMinor, 100);
      repository.complete(0, _page('2026-07', generation: 1));

      expect(await page, isTrue);
      expect(visibleFrames.value?.preparedFrame.presentationDigest, 1);
      expect(committedViewport.pageForOrdinal(1), isNotNull);
      expect(controller.pageReadCount, 1);
    },
  );

  test(
    'idle root readiness prewarms only its immediate bounded forward hotset',
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      final hotset = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
      ]);
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 120,
        ),
      );
      await pumpEventQueue();
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
      ]);
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 2,
          hasNext: true,
          entryCount: 120,
        ),
      );

      expect(await hotset, isTrue);
      expect(controller.nextPageOrdinal, 3);
      expect(repository.requests, hasLength(2));
      expect(committedViewport.highestReadyPageOrdinal, 2);
      expect(
        committedViewport.exposedFrontierOrdinal,
        2,
        reason:
            'The completed bounded idle hotset is published as one exact '
            'initial runway before the first human gesture needs it.',
      );
    },
  );

  test(
    'a satisfied initial hotset cannot rearm from later post-layout retries',
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 240,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      final initial = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );
      await pumpEventQueue();
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 2,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(await initial, isTrue);
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
      ]);

      // A render extent may be reported many times after the same initial
      // runway becomes drawable. Those callbacks may retry a pending intent,
      // but must never create a new one after this scope is satisfied.
      for (var retry = 0; retry < 100; retry += 1) {
        unawaited(controller.prewarmBoundedReadyHotset());
      }
      await pumpEventQueue();

      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
      ]);
      expect(controller.nextPageOrdinal, 3);
      expect(committedViewport.highestReadyPageOrdinal, 2);
    },
  );

  test(
    'a gate-closed initial hotset retains one fixed target until it is satisfied',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var foregroundGateOpen = false;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        canRunBackgroundPrewarm: () => foregroundGateOpen,
      );
      addTearDown(controller.dispose);
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 240,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      for (var retry = 0; retry < 10; retry += 1) {
        expect(await controller.prewarmBoundedReadyHotset(), isFalse);
      }
      expect(repository.requests, isEmpty);

      foregroundGateOpen = true;
      final initial = controller.tryStartBoundedReadyHotset(
        reason: 'motionIdle',
      );
      await pumpEventQueue();
      expect(repository.requests.single.pageOrdinal, 1);
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );
      await pumpEventQueue();
      expect(repository.requests.last.pageOrdinal, 2);
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 2,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(await initial, isTrue);

      for (var retry = 0; retry < 10; retry += 1) {
        unawaited(
          controller.tryStartBoundedReadyHotset(reason: 'pagePipelineIdle'),
        );
        unawaited(controller.prewarmBoundedReadyHotset());
      }
      await pumpEventQueue();

      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        1,
        2,
      ]);
      expect(controller.nextPageOrdinal, 3);
    },
  );

  test(
    'foreground demand reuses an in-flight bounded hotset page without a second read',
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      final prewarm = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));

      final demand = controller.requestForwardDemand(1);
      expect(repository.requests, hasLength(1));
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 120,
        ),
      );

      expect(await demand, isTrue);
      expect(await prewarm, isTrue);
      expect(repository.requests, hasLength(1));
      expect(committedViewport.pageForOrdinal(1), isNotNull);
      expect(controller.nextPageOrdinal, 2);
    },
  );

  test(
    'foreground demand makes the same in-flight hotset response frontier critical',
    () async {
      FluviDiagnosticLogger.clear();
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(
        pageSize: 24,
        preparationSliceMicros: 1,
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      final hotset = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 120,
        ),
      );
      final demand = controller.requestForwardDemand(1);
      expect(await demand, isTrue);
      expect(await hotset, isTrue);
      expect(repository.requests, hasLength(1));
      expect(committedViewport.pageForOrdinal(1), isNotNull);
      expect(
        FluviDiagnosticLogger.entries.any(
          (event) =>
              event.stage == 'VERTICAL_PAGE_PREPARATION_STARTED' &&
              event.message?.contains('pageOrdinal=1') == true &&
              event.message?.contains('urgency=frontierCritical') == true,
        ),
        isTrue,
        reason:
            'The repository call stays single-owner while the resulting '
            'private page observes the newer human demand before it starts '
            'cooperative background presentation.',
      );
    },
  );

  test(
    'a superseding committed scope prevents a stale ready hotset from committing',
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
      final july = _visible('2026-07', epoch: 3, digest: 1, entryCount: 120);
      visibleFrames.publish(july);
      controller.commitMetadata(july);
      committedViewport.configureSurfaceWidth(378);
      final prewarm = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();

      final august = _visible('2026-08', epoch: 4, digest: 2, entryCount: 120);
      visibleFrames.publish(august);
      controller.commitMetadata(august);
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 120,
        ),
      );

      expect(await prewarm, isFalse);
      expect(committedViewport.queryKey, august.queryKey);
      expect(committedViewport.pageForOrdinal(1), isNull);
    },
  );

  test(
    'input preemption drops an unneeded hotset response before presentation',
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      final hotset = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      controller.cancelBoundedReadyHotset(reason: 'verticalInteraction');
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 120,
        ),
      );

      expect(await hotset, isFalse);
      expect(committedViewport.pageForOrdinal(1), isNull);
      expect(controller.committedPagePresentationActive, isFalse);
      expect(repository.requests, hasLength(1));
    },
  );

  test(
    'background hotset requires an idle foreground gate and an exact surface width',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var foregroundOwnsPriority = true;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        canRunBackgroundPrewarm: () => !foregroundOwnsPriority,
      );
      addTearDown(controller.dispose);
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      expect(await controller.prewarmBoundedReadyHotset(), isFalse);
      expect(repository.requests, isEmpty);

      foregroundOwnsPriority = false;
      committedViewport.configureSurfaceWidth(378);
      final hotset = controller.prewarmBoundedReadyHotset();
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));
      repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 120,
        ),
      );
      expect(await hotset, isTrue);
    },
  );

  test(
    'a gate-closed bounded hotset retries once when its lifecycle becomes idle',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var foregroundOwnsPriority = true;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        canRunBackgroundPrewarm: () => !foregroundOwnsPriority,
      );
      addTearDown(controller.dispose);
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 120,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);
      committedViewport.configureSurfaceWidth(378);

      expect(await controller.prewarmBoundedReadyHotset(), isFalse);
      expect(repository.requests, isEmpty);

      foregroundOwnsPriority = false;
      unawaited(controller.tryStartBoundedReadyHotset(reason: 'motionIdle'));
      unawaited(controller.tryStartBoundedReadyHotset(reason: 'motionIdle'));
      await pumpEventQueue();

      expect(
        repository.requests.map((request) => request.pageOrdinal),
        <int>[1],
        reason:
            'A closed foreground gate must retain this exact bounded hotset '
            'intent until an existing idle lifecycle boundary retries it.',
      );
    },
  );

  test(
    'a superseding scope replaces a deferred bounded hotset intent',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var foregroundOwnsPriority = true;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        canRunBackgroundPrewarm: () => !foregroundOwnsPriority,
      );
      addTearDown(controller.dispose);
      final july = _visible('2026-07', epoch: 3, digest: 1, entryCount: 120);
      visibleFrames.publish(july);
      controller.commitMetadata(july);
      committedViewport.configureSurfaceWidth(378);
      expect(await controller.prewarmBoundedReadyHotset(), isFalse);

      final august = _visible('2026-08', epoch: 4, digest: 2, entryCount: 120);
      visibleFrames.publish(august);
      controller.commitMetadata(august);
      foregroundOwnsPriority = false;
      unawaited(controller.tryStartBoundedReadyHotset(reason: 'motionIdle'));
      await pumpEventQueue();

      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.scope.key, august.queryKey);
      expect(repository.requests.single.pageOrdinal, 1);
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
    'a 156-entry month advances its committed ready frontier beyond page zero',
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
      final committed = _visible(
        '2025-04',
        epoch: 3,
        digest: 1,
        entryCount: 156,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      final demand = controller.requestForwardDemand(3);
      await pumpEventQueue();
      expect(repository.requests.single.pageOrdinal, 1);
      repository.complete(
        0,
        _page(
          '2025-04',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 156,
        ),
      );
      await pumpEventQueue();
      expect(repository.requests.last.pageOrdinal, 2);
      repository.complete(
        0,
        _page(
          '2025-04',
          generation: 1,
          ordinal: 2,
          hasNext: true,
          entryCount: 156,
        ),
      );
      await pumpEventQueue();
      expect(repository.requests.last.pageOrdinal, 3);
      repository.complete(
        0,
        _page(
          '2025-04',
          generation: 1,
          ordinal: 3,
          hasNext: false,
          entryCount: 156,
        ),
      );

      expect(await demand, isTrue);
      expect(committedViewport.pageForOrdinal(0), isNotNull);
      expect(committedViewport.pageForOrdinal(1), isNotNull);
      expect(committedViewport.pageForOrdinal(2), isNotNull);
      expect(controller.nextPageOrdinal, 4);
      expect(committed.logBox.entryCount, 156);
      expect(committedViewport.pageFailureCount, 0);
    },
  );

  test(
    'a local reverse traversal stays hot inside the movable working set',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(
        pageSize: 24,
        maximumRetainedBytes: 512 * 1024,
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

      for (var ordinal = 1; ordinal <= 5; ordinal += 1) {
        final request = controller.loadNextPage();
        await pumpEventQueue();
        repository.complete(
          0,
          _page(
            '2026-07',
            generation: 1,
            ordinal: ordinal,
            hasNext: ordinal != 5,
          ),
        );
        expect(await request, isTrue);
        committedViewport.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }

      // The current page plus immediate reversal history stay in the bounded
      // movable bank, so returning locally needs no native reload.
      committedViewport.updateVisibleRowWindow(start: 3 * 24, end: 4 * 24);
      expect(committedViewport.pageForOrdinal(3), isNotNull);
      expect(await controller.loadPreviousPage(), isFalse);
      expect(repository.requests, hasLength(5));
      expect(committedViewport.pageForOrdinal(3), isNotNull);
    },
  );

  test(
    'a backward traversal reloads consecutive evicted pages once each',
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
      final committed = _visible(
        '2026-07',
        epoch: 3,
        digest: 1,
        entryCount: 264,
      );
      visibleFrames.publish(committed);
      controller.commitMetadata(committed);

      for (var ordinal = 1; ordinal <= 10; ordinal += 1) {
        expect(
          committedViewport.commit(
            _page(
              '2026-07',
              generation: 1,
              ordinal: ordinal,
              hasNext: true,
              entryCount: 264,
            ),
          ),
          isTrue,
        );
        committedViewport.updateVisibleRowWindow(
          start: ordinal * 24,
          end: (ordinal + 1) * 24,
        );
      }
      expect(committedViewport.lowestRetainedOrdinal, 6);

      final reloadedOrdinals = <int>[];
      for (final target in <int>[5, 4, 3]) {
        committedViewport.updateVisibleRowWindow(
          start: (target + 1) * 24,
          end: (target + 2) * 24,
        );
        final reload = controller.loadPreviousPage();
        await pumpEventQueue();
        expect(repository.requests.last.pageOrdinal, target);
        reloadedOrdinals.add(repository.requests.last.pageOrdinal);
        repository.complete(
          0,
          _page(
            '2026-07',
            generation: 1,
            ordinal: target,
            hasNext: true,
            entryCount: 264,
          ),
        );
        expect(await reload, isTrue);
        expect(committedViewport.pageForOrdinal(target), isNotNull);
        expect(committedViewport.retainedPageCount, lessThanOrEqualTo(5));
      }

      expect(reloadedOrdinals, <int>[5, 4, 3]);
      expect(repository.requests.map((request) => request.pageOrdinal), <int>[
        5,
        4,
        3,
      ]);
      expect(committedViewport.pageForOrdinal(3), isNotNull);
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
    'a motion-deferred current forward demand resumes without another gesture',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var motionActive = true;
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

      expect(await controller.requestForwardDemand(2), isFalse);
      expect(repository.requests, isEmpty);
      expect(controller.desiredForwardOrdinal, 2);

      motionActive = false;
      controller.resumeDeferredForwardDemand();
      await pumpEventQueue();
      expect(repository.requests, hasLength(1));
      expect(repository.requests.single.pageOrdinal, 1);
      repository.complete(0, _page('2026-07', generation: 1, hasNext: true));
      await pumpEventQueue();
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.pageOrdinal, 2);
      repository.complete(0, _page('2026-07', generation: 1, ordinal: 2));
      await pumpEventQueue();

      expect(controller.nextPageOrdinal, 3);
      expect(controller.committedViewport.highestReadyPageOrdinal, 2);
    },
  );

  test('commits the exact next page without a vertical-idle release', () async {
    FluviDiagnosticLogger.clear();
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
    committedViewport.configureSurfaceWidth(378);
    expect(
      committedViewport.activateVerticalRendering(hasExactRailScene: true),
      isTrue,
    );

    final request = controller.loadNextPage();
    var completed = false;
    unawaited(request.then((_) => completed = true));
    await pumpEventQueue();
    repository.complete(0, _page('2026-07', generation: 1));
    await pumpEventQueue();
    await pumpEventQueue();

    expect(completed, isTrue);
    expect(committedViewport.pageForOrdinal(1), isNotNull);
    expect(controller.committedViewport.highestReadyPageOrdinal, 1);
    expect(repository.requests, hasLength(1));
    expect(
      FluviDiagnosticLogger.entries.where(
        (event) =>
            event.stage == 'VERTICAL_PAGE_PRESENTATION_DEFERRED_FOR_INPUT',
      ),
      isEmpty,
    );
    expect(
      FluviDiagnosticLogger.entries.where(
        (event) =>
            event.stage == 'VERTICAL_PAGE_PRESENTATION_RESUMED_AFTER_INPUT',
      ),
      isEmpty,
    );
    final ready = FluviDiagnosticLogger.entries.lastWhere(
      (event) => event.stage == 'VERTICAL_PAGE_PRESENTATION_PREPARE_READY',
    );
    expect(
      ready.message,
      contains('finalUrgency=frontierCritical'),
      reason:
          'The sequential cursor owner must classify its exact next page as '
          'the active drawable frontier, rather than background preparation.',
    );
  });

  test('forward demand preserves sequential frontier commits', () async {
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
    committedViewport.configureSurfaceWidth(378);
    expect(
      committedViewport.activateVerticalRendering(hasExactRailScene: true),
      isTrue,
    );

    final demand = controller.requestForwardDemand(3);
    await pumpEventQueue();
    expect(repository.requests.single.pageOrdinal, 1);
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
    expect(committedViewport.highestReadyPageOrdinal, 3);
    expect(repository.requests, hasLength(3));
  });

  test(
    'a stale deferred forward demand cannot resume after a new committed scope',
    () async {
      final repository = _PageRepository();
      final visibleFrames = DashboardVisibleFrameStore();
      final committedViewport = CommittedLogViewportCache(pageSize: 24);
      addTearDown(visibleFrames.dispose);
      addTearDown(committedViewport.dispose);
      var motionActive = true;
      final controller = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: visibleFrames,
        committedViewport: committedViewport,
        pageSize: 24,
        isMotionActive: () => motionActive,
      );
      addTearDown(controller.dispose);
      final oldScope = _visible('2026-07', epoch: 3, digest: 1);
      visibleFrames.publish(oldScope);
      controller.commitMetadata(oldScope);
      expect(await controller.requestForwardDemand(1), isFalse);

      final currentScope = _visible('2026-08', epoch: 4, digest: 2);
      visibleFrames.publish(currentScope);
      controller.commitMetadata(currentScope);
      motionActive = false;
      controller.resumeDeferredForwardDemand();
      await pumpEventQueue();

      expect(repository.requests, isEmpty);
      expect(controller.desiredForwardOrdinal, 0);
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
  int entryCount = 2,
}) {
  final scope = _scope(month);
  return DashboardVisibleFrame.fromPrepared(
    _prepared(month, digest: digest, hasCursor: true, entryCount: entryCount),
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
  int entryCount = 2,
}) {
  final scope = _scope(month);
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 7,
    totalMinor: 100,
    formattedAmount: '1,00 Ft',
    entryCount: entryCount,
    formattedEntryCount: '$entryCount',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const [],
      entryCount: entryCount,
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
  int entryCount = 2,
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
      entryCount: entryCount,
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
