import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/application/explicit_committed_paging_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'a new scope prepares only its bounded five-page initial ready bank',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);

      final ready = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initialSurfaceReady',
      );
      await pumpEventQueue();
      for (var ordinal = 1; ordinal <= 5; ordinal += 1) {
        expect(
          harness.repository.requests.map((request) => request.pageOrdinal),
          <int>[for (var page = 1; page <= ordinal; page += 1) page],
        );
        harness.repository.complete(
          0,
          _page(
            '2026-07',
            generation: 1,
            ordinal: ordinal,
            hasNext: true,
            entryCount: 240,
          ),
        );
        if (ordinal < 5) await pumpEventQueue();
      }

      expect(await ready, isTrue);
      expect(harness.controller.desiredForwardOrdinal, 5);
      expect(harness.controller.nextPageOrdinal, 6);
      expect(harness.cache.highestReadyPageOrdinal, 5);
      expect(harness.cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(harness.repository.requests, hasLength(5));
    },
  );

  test('ready-ahead work waits until exact surface width is known', () async {
    final harness = _PagingHarness(
      entryCount: 240,
      configureSurfaceWidth: false,
    );
    addTearDown(harness.dispose);

    expect(
      await harness.controller.prepareReadyAheadAtIdle(
        reason: 'beforeSurfaceWidth',
      ),
      isFalse,
    );
    expect(harness.repository.requests, isEmpty);

    harness.cache.configureSurfaceWidth(378);
    await _fillInitialBank(harness);
    expect(harness.cache.highestReadyPageOrdinal, 5);
  });

  test(
    'a live forward demand records during active vertical input and runs at idle',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);

      harness.verticalInteractionActive = true;
      harness.cache.updateVisibleRowWindow(start: 72, end: 96);
      unawaited(harness.controller.requestForwardDemand(6));
      await pumpEventQueue();

      expect(
        harness.repository.requests,
        hasLength(5),
        reason:
            'Pointer-driven demand may update the bounded target, but it must '
            'not start a fresh repository acquisition during vertical input.',
      );
      expect(harness.controller.desiredForwardOrdinal, 6);
      expect(harness.controller.hasDeferredForwardDemand, isTrue);

      harness.verticalInteractionActive = false;
      final replenishment = harness.controller.prepareReadyAheadAtIdle(
        reason: 'verticalInputIdle',
      );
      await pumpEventQueue();

      expect(harness.repository.requests, hasLength(6));
      expect(harness.repository.requests.last.pageOrdinal, 6);
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 6,
          hasNext: true,
          entryCount: 240,
        ),
      );

      expect(await replenishment, isTrue);
      expect(harness.cache.highestReadyPageOrdinal, 6);
      expect(harness.cache.retainedPageCount, lessThanOrEqualTo(5));
    },
  );

  test(
    'route-gated ready-ahead records its target before it can execute',
    () async {
      final harness = _PagingHarness(entryCount: 48);
      addTearDown(harness.dispose);

      harness.gateOpen = false;
      expect(
        await harness.controller.prepareReadyAheadAtIdle(reason: 'routeActive'),
        isFalse,
      );
      expect(
        harness.controller.desiredForwardOrdinal,
        1,
        reason:
            'The post-layout opportunity may fall within the route gate. Its '
            'bounded target must survive until route completion re-admits it.',
      );
      expect(harness.controller.hasDeferredForwardDemand, isTrue);
      expect(harness.repository.requests, isEmpty);

      harness.gateOpen = true;
      final resumed = harness.controller.prepareReadyAheadAtIdle(
        reason: 'routeCompleted',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(1));
      expect(harness.repository.requests.single.pageOrdinal, 1);

      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 48,
        ),
      );
      expect(await resumed, isTrue);
      expect(harness.cache.highestReadyPageOrdinal, 1);
      expect(harness.repository.requests, hasLength(1));
    },
  );

  test(
    'page completion cannot recursively advance the rolling target',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);

      for (var callback = 0; callback < 100; callback += 1) {
        expect(
          await harness.controller.prepareReadyAheadAtIdle(
            reason: 'idleCallback',
          ),
          isFalse,
        );
      }

      expect(harness.controller.desiredForwardOrdinal, 5);
      expect(harness.repository.requests, hasLength(5));
      expect(harness.controller.nextPageOrdinal, 6);
    },
  );

  test(
    'a failed page waits for a new demand epoch instead of self-retrying',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);

      final initial = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initial',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(1));
      harness.repository.fail(0, StateError('transient page failure'));
      expect(await initial, isFalse);

      // Let a completed drain settle. It may not autonomously keep reopening
      // the same failed cursor identity in this demand epoch.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(harness.repository.requests, hasLength(1));
      expect(
        harness.pipelineIdleCount,
        0,
        reason:
            'The core must not be invited to reconcile a still-failed target, '
            'or it can recreate the same failed drain through its idle hook.',
      );

      harness.controller.beginForwardDemandEpoch();
      final retry = harness.controller.prepareReadyAheadAtIdle(
        reason: 'newInputEpoch',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(2));
      expect(harness.repository.requests.last.pageOrdinal, 1);
      harness.gateOpen = false;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(
        await retry,
        isTrue,
        reason:
            'A retry read that was already exact/current may complete its '
            'atomic commit; the closed background gate only prevents the '
            'next optional page from starting.',
      );
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(harness.repository.requests, hasLength(2));
    },
    timeout: const Timeout(Duration(seconds: 2)),
  );

  test(
    'repeated equal forward demand at a fixed visible page creates zero reads',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);

      for (var callback = 0; callback < 200; callback += 1) {
        harness.cache.updateVisibleRowWindow(start: 0, end: 24);
        expect(await harness.controller.requestForwardDemand(5), isFalse);
        expect(
          await harness.controller.prepareReadyAheadAtIdle(
            reason: 'postLayout',
          ),
          isFalse,
        );
      }

      expect(harness.controller.desiredForwardOrdinal, 5);
      expect(harness.repository.requests, hasLength(5));
    },
  );

  test(
    'a common fling consumes an already exact ready bank without duplicate reads',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);

      harness.verticalInteractionActive = true;
      for (var update = 0; update < 100; update += 1) {
        expect(await harness.controller.requestForwardDemand(5), isFalse);
      }

      expect(
        harness.repository.requests,
        hasLength(5),
        reason:
            'Visible ordinal changes inside a preprepared bank must not make '
            'repository I/O a normal active-fling dependency.',
      );
      expect(harness.controller.desiredForwardOrdinal, 5);
    },
  );

  test(
    'one serial cursor owns a rolling refill without duplicate reads',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);

      final first = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initial',
      );
      final duplicate = harness.controller.requestForwardDemand(5);
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(1));
      expect(harness.repository.requests.single.pageOrdinal, 1);
      expect(harness.controller.committedPageRequestInFlight, isTrue);

      harness.repository.complete(
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
      expect(harness.repository.requests, hasLength(2));
      expect(harness.repository.requests.last.pageOrdinal, 2);

      for (var ordinal = 2; ordinal <= 5; ordinal += 1) {
        harness.repository.complete(
          0,
          _page(
            '2026-07',
            generation: 1,
            ordinal: ordinal,
            hasNext: true,
            entryCount: 240,
          ),
        );
        if (ordinal < 5) await pumpEventQueue();
      }
      expect(await first, isTrue);
      expect(await duplicate, isTrue);
      expect(
        harness.repository.requests.map((request) => request.pageOrdinal),
        <int>[1, 2, 3, 4, 5],
      );
    },
  );

  test(
    'reverse reload stays pending through input and avoids immediate thrash',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);
      harness.cache.updateVisibleRowWindow(start: 72, end: 96);
      final forward = harness.controller.requestForwardDemand(6);
      await pumpEventQueue();
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 6,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(await forward, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNull);

      harness.verticalInteractionActive = true;
      harness.cache.updateVisibleRowWindow(start: 48, end: 72);
      expect(await harness.controller.loadPreviousPage(), isFalse);
      expect(harness.repository.requests, hasLength(6));

      harness.verticalInteractionActive = false;
      final reverse = harness.controller.prepareReadyAheadAtIdle(
        reason: 'reverseIdle',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(7));
      expect(harness.repository.requests.last.pageOrdinal, 1);
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(await reverse, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(await harness.controller.loadPreviousPage(), isFalse);
      expect(harness.repository.requests, hasLength(7));
    },
  );

  test(
    'a superseding committed scope cannot publish a stale private page',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      final oldScope = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initial',
      );
      await pumpEventQueue();
      expect(harness.repository.requests.single.pageOrdinal, 1);

      final august = _visible('2026-08', epoch: 4, digest: 2, entryCount: 240);
      harness.visibleFrames.publish(august);
      harness.controller.commitMetadata(
        august,
        geometryManifest: _manifestForFrame(august),
      );
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );

      expect(await oldScope, isFalse);
      expect(harness.cache.queryKey, august.queryKey);
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.controller.committedPageDataPendingPresentation, isFalse);
    },
  );

  test('a scope without a cursor never creates a ready-ahead read', () async {
    final repository = _PageRepository();
    final visibleFrames = DashboardVisibleFrameStore();
    final cache = CommittedLogViewportCache(pageSize: 24);
    final controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      committedViewport: cache,
    );
    addTearDown(visibleFrames.dispose);
    addTearDown(cache.dispose);
    addTearDown(controller.dispose);
    final frame = _visible(
      '2026-07',
      epoch: 3,
      digest: 1,
      entryCount: 24,
      hasCursor: false,
    );
    visibleFrames.publish(frame);
    controller.commitMetadata(
      frame,
      geometryManifest: _manifestForFrame(frame),
    );

    expect(
      await controller.prepareReadyAheadAtIdle(reason: 'noCursor'),
      isFalse,
    );
    expect(repository.requests, isEmpty);
  });

  test(
    'an exact response received during input defers publication without reread',
    () async {
      final harness = _PagingHarness(entryCount: 48);
      addTearDown(harness.dispose);

      final idleRead = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initial',
      );
      await pumpEventQueue();
      harness.verticalInteractionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 48,
        ),
      );
      expect(await idleRead, isFalse);
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);
      expect(harness.repository.requests, hasLength(1));

      harness.verticalInteractionActive = false;
      final resumed = harness.controller.prepareReadyAheadAtIdle(
        reason: 'verticalInputIdle',
      );

      expect(await resumed, isTrue);
      expect(harness.cache.highestReadyPageOrdinal, 1);
      expect(harness.controller.nextPageOrdinal, 2);
      expect(harness.controller.committedPageDataPendingPresentation, isFalse);
      expect(
        harness.repository.requests,
        hasLength(1),
        reason:
            'The exact decoded page must survive input and commit on idle, '
            'not be reread.',
      );
    },
  );

  test(
    'a decoded exact page resumes presentation after pointer release before ballistic ends',
    () async {
      final harness = _PagingHarness(entryCount: 67);
      addTearDown(harness.dispose);
      final virtualExtent = harness.cache.contentHeight;
      final geometryGeneration = harness.cache.geometryGeneration;

      final readyAhead = harness.controller.requestForwardDemand(2);
      await pumpEventQueue();
      expect(
        harness.repository.requests.map((request) => request.pageOrdinal),
        <int>[1],
      );

      harness.pointerIntentActive = true;
      harness.verticalInteractionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 67,
        ),
      );

      expect(await readyAhead, isFalse);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.repository.requests, hasLength(1));

      harness.pointerIntentActive = false;
      final presented = harness.controller.resumeDeferredPagePresentation(
        reason: 'pointerReleased',
      );

      expect(await presented, isTrue);
      expect(harness.verticalInteractionActive, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(harness.cache.highestReadyPageOrdinal, 1);
      expect(harness.controller.committedPageDataPendingPresentation, isFalse);
      expect(harness.cache.contentHeight, virtualExtent);
      expect(harness.cache.geometryGeneration, geometryGeneration);
      expect(
        harness.repository.requests,
        hasLength(1),
        reason:
            'Ballistic correctness presentation must reuse the one decoded '
            'ordinal-1 response rather than acquire it again or start ordinal 2.',
      );

      harness.verticalInteractionActive = false;
      final idleReadyAhead = harness.controller.prepareReadyAheadAtIdle(
        reason: 'verticalInputIdle',
      );
      await pumpEventQueue();
      expect(
        harness.repository.requests.map((request) => request.pageOrdinal),
        <int>[1, 2],
      );
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 2,
          hasNext: false,
          entryCount: 67,
        ),
      );
      expect(await idleReadyAhead, isTrue);
    },
  );

  test(
    'motion idle resumes a deferred exact page without reopening acquisition during ballistic',
    () async {
      final harness = _PagingHarness(entryCount: 67);
      addTearDown(harness.dispose);

      final readyAhead = harness.controller.requestForwardDemand(2);
      await pumpEventQueue();
      harness.pointerIntentActive = true;
      harness.verticalInteractionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 67,
        ),
      );
      expect(await readyAhead, isFalse);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);

      harness.pointerIntentActive = false;
      harness.structuralMotionActive = true;
      expect(
        await harness.controller.resumeDeferredPagePresentation(
          reason: 'pointerReleased',
        ),
        isFalse,
      );
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.repository.requests, hasLength(1));

      harness.structuralMotionActive = false;
      expect(
        await harness.controller.resumeDeferredPagePresentation(
          reason: 'motionIdle',
        ),
        isTrue,
      );
      expect(harness.verticalInteractionActive, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(
        harness.repository.requests,
        hasLength(1),
        reason:
            'Motion-idle may publish the retained exact page, but it must not '
            'turn the ballistic lane into a new acquisition drain.',
      );
    },
  );

  test(
    'a new raw pointer preempts deferred presentation and reuses the decoded page later',
    () async {
      var clock = 0;
      var yieldedOnce = false;
      final firstPreparationYield = Completer<void>();
      final releaseFirstPreparationYield = Completer<void>();
      final harness = _PagingHarness(
        entryCount: 67,
        committedViewport: CommittedLogViewportCache(
          pageSize: 24,
          pagePreparationPolicy: CommittedPagePreparationPolicy(
            contiguousUiBudgetMicros: 1,
            nowMicros: () => ++clock,
            yieldToEventTurn: () {
              if (!yieldedOnce) {
                yieldedOnce = true;
                firstPreparationYield.complete();
                return releaseFirstPreparationYield.future;
              }
              return Future<void>.value();
            },
          ),
        ),
      );
      addTearDown(harness.dispose);

      final readyAhead = harness.controller.requestForwardDemand(2);
      await pumpEventQueue();
      harness.pointerIntentActive = true;
      harness.verticalInteractionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 67,
        ),
      );
      expect(await readyAhead, isFalse);

      harness.pointerIntentActive = false;
      final presentation = harness.controller.resumeDeferredPagePresentation(
        reason: 'pointerReleased',
      );
      await firstPreparationYield.future;
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.cache.preparedPageForOrdinal(1), isNull);

      harness.pointerIntentActive = true;
      releaseFirstPreparationYield.complete();
      expect(await presentation, isFalse);
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.cache.preparedPageForOrdinal(1), isNull);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);
      expect(harness.repository.requests, hasLength(1));

      harness.pointerIntentActive = false;
      expect(
        await harness.controller.resumeDeferredPagePresentation(
          reason: 'secondPointerReleased',
        ),
        isTrue,
      );
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(harness.cache.preparedPageForOrdinal(1), isNotNull);
      expect(harness.repository.requests, hasLength(1));
      expect(
        harness.cache.largestPagePreparationUiSliceMicros,
        lessThanOrEqualTo(2),
      );
    },
  );

  test(
    'a superseding scope discards a deferred exact page before it can publish',
    () async {
      final harness = _PagingHarness(entryCount: 67);
      addTearDown(harness.dispose);

      final readyAhead = harness.controller.requestForwardDemand(2);
      await pumpEventQueue();
      harness.pointerIntentActive = true;
      harness.verticalInteractionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 67,
        ),
      );
      expect(await readyAhead, isFalse);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);

      final superseding = _visible(
        '2026-08',
        epoch: 4,
        digest: 2,
        entryCount: 24,
        hasCursor: false,
      );
      harness.visibleFrames.publish(superseding);
      harness.controller.commitMetadata(
        superseding,
        geometryManifest: _manifestForFrame(superseding),
      );
      harness.pointerIntentActive = false;

      expect(
        await harness.controller.resumeDeferredPagePresentation(
          reason: 'structuralSupersede',
        ),
        isFalse,
      );
      expect(harness.controller.committedPageDataPendingPresentation, isFalse);
      expect(harness.cache.queryKey, superseding.queryKey);
      expect(harness.cache.pageForOrdinal(1), isNull);
    },
  );

  test(
    'RED: end-of-data reverse updates never defer an impossible next ordinal',
    () async {
      FluviDiagnosticLogger.clear();
      final harness = _PagingHarness(entryCount: 48);
      addTearDown(harness.dispose);

      final initial = harness.controller.prepareReadyAheadAtIdle(
        reason: 'initial',
      );
      await pumpEventQueue();
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 48,
        ),
      );
      expect(await initial, isTrue);
      expect(harness.cache.hasMorePages, isFalse);
      expect(harness.controller.nextPageOrdinal, 2);
      expect(harness.controller.desiredForwardOrdinal, 1);

      harness.verticalInteractionActive = true;
      for (var update = 0; update < 20; update += 1) {
        expect(await harness.controller.loadPreviousPage(), isFalse);
      }

      expect(harness.repository.requests, hasLength(1));
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'VERTICAL_READY_AHEAD_DEFERRED',
        ),
        isEmpty,
        reason:
            'No retained page precedes ordinal zero, and the forward cursor '
            'is already terminal. Repeated boundary updates must not become '
            'deferred next-page work or interaction-path log spam.',
      );
    },
  );

  test(
    'a structural preemption retains an exact decoded page without reread',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);

      final requested = harness.controller.requestForwardDemand(1);
      await pumpEventQueue();
      harness.structuralMotionActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: true,
          entryCount: 240,
        ),
      );
      expect(await requested, isFalse);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);
      expect(harness.repository.requests, hasLength(1));

      harness.structuralMotionActive = false;
      final resumed = harness.controller.prepareReadyAheadAtIdle(
        reason: 'structuralMotionIdle',
      );
      await pumpEventQueue();

      expect(await resumed, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(harness.repository.requests, hasLength(1));
    },
  );

  test(
    'focus clear restores retained ready-ahead pages without rereading Room',
    () async {
      final harness = _PagingHarness(entryCount: 240);
      addTearDown(harness.dispose);
      await _fillInitialBank(harness);
      expect(harness.cache.highestReadyPageOrdinal, 5);
      expect(harness.repository.requests, hasLength(5));

      final snapshot = harness.controller.retainForEphemeralFocus();
      expect(snapshot, isNotNull);
      final focusFrame = _visible(
        '2026-08',
        epoch: 4,
        digest: 2,
        entryCount: 24,
        hasCursor: false,
      );
      harness.visibleFrames.publish(focusFrame);
      harness.controller.commitMetadata(
        focusFrame,
        geometryManifest: _manifestForFrame(focusFrame),
      );

      harness.visibleFrames.publish(harness.frame);
      expect(
        harness.controller.restoreEphemeralFocusSnapshot(
          snapshot!,
          harness.frame,
          geometryManifest: _manifestForFrame(harness.frame),
        ),
        isTrue,
      );
      expect(harness.cache.highestReadyPageOrdinal, 5);
      expect(harness.cache.pageForOrdinal(3), isNotNull);

      expect(
        await harness.controller.requestForwardDemand(5),
        isFalse,
        reason:
            'No read is necessary when the retained chain already satisfies '
            'the requested ready-ahead ordinal.',
      );
      expect(
        harness.repository.requests,
        hasLength(5),
        reason:
            'The exact base chain already owns ordinals 1–5; focus clear '
            'must not send the same ready-ahead pages through Room again.',
      );
    },
  );
  test(
    'raw pointer intent retains an acquired exact page until presentation is safe',
    () async {
      final harness = _PagingHarness(entryCount: 48);
      addTearDown(harness.dispose);

      final admitted = harness.controller.prepareReadyAheadAtIdle(
        reason: 'directChipPublication',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(1));

      harness.pointerIntentActive = true;
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 48,
        ),
      );

      expect(await admitted, isFalse);
      expect(harness.cache.pageForOrdinal(1), isNull);
      expect(harness.controller.committedPageDataPendingPresentation, isTrue);
      expect(
        harness.repository.requests,
        hasLength(1),
        reason: 'Pointer intent may not cancel or duplicate an admitted read.',
      );

      harness.pointerIntentActive = false;
      final resumed = harness.controller.prepareReadyAheadAtIdle(
        reason: 'pointerTapReleased',
      );
      expect(await resumed, isTrue);
      expect(harness.cache.pageForOrdinal(1), isNotNull);
      expect(harness.controller.committedPageDataPendingPresentation, isFalse);
      expect(harness.repository.requests, hasLength(1));
    },
  );
  test(
    'raw pointer intent records live demand without starting a repository read',
    () async {
      final harness = _PagingHarness(entryCount: 48);
      addTearDown(harness.dispose);

      FluviDiagnosticLogger.clear();
      harness.pointerIntentActive = true;
      expect(await harness.controller.requestForwardDemand(1), isFalse);
      expect(harness.repository.requests, isEmpty);
      final deferred = FluviDiagnosticLogger.entries.singleWhere(
        (event) => event.stage == 'VERTICAL_READY_AHEAD_DEFERRED',
      );
      expect(deferred.message, contains('pointerIntent=true'));

      expect(harness.controller.desiredForwardOrdinal, 1);

      harness.pointerIntentActive = false;
      final resumed = harness.controller.prepareReadyAheadAtIdle(
        reason: 'pointerTapReleased',
      );
      await pumpEventQueue();
      expect(harness.repository.requests, hasLength(1));
      harness.repository.complete(
        0,
        _page(
          '2026-07',
          generation: 1,
          ordinal: 1,
          hasNext: false,
          entryCount: 48,
        ),
      );
      expect(await resumed, isTrue);
      expect(harness.repository.requests, hasLength(1));
      expect(harness.cache.pageForOrdinal(1), isNotNull);
    },
  );
}

Future<void> _fillInitialBank(_PagingHarness harness) async {
  final ready = harness.controller.prepareReadyAheadAtIdle(reason: 'initial');
  await pumpEventQueue();
  for (var ordinal = 1; ordinal <= 5; ordinal += 1) {
    harness.repository.complete(
      0,
      _page(
        '2026-07',
        generation: 1,
        ordinal: ordinal,
        hasNext: true,
        entryCount: harness.entryCount,
      ),
    );
    if (ordinal < 5) await pumpEventQueue();
  }
  expect(await ready, isTrue);
}

final class _PagingHarness {
  _PagingHarness({
    required this.entryCount,
    this.configureSurfaceWidth = true,
    CommittedLogViewportCache? committedViewport,
  }) : repository = _PageRepository(),
       visibleFrames = DashboardVisibleFrameStore(),
       cache = committedViewport ?? CommittedLogViewportCache(pageSize: 24) {
    controller = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: visibleFrames,
      committedViewport: cache,
      pageSize: 24,
      isMotionActive: () => structuralMotionActive,
      isVerticalInteractionActive: () => verticalInteractionActive,
      isVerticalPointerIntentActive: () => pointerIntentActive,
      canRunBackgroundPrewarm: () => !verticalInteractionActive && gateOpen,
      onPagePipelineIdle: () => pipelineIdleCount += 1,
    );
    frame = _visible('2026-07', epoch: 3, digest: 1, entryCount: entryCount);
    visibleFrames.publish(frame);
    controller.commitMetadata(
      frame,
      geometryManifest: _manifestForFrame(frame),
    );
    if (configureSurfaceWidth) cache.configureSurfaceWidth(378);
  }

  final int entryCount;
  final bool configureSurfaceWidth;
  final _PageRepository repository;
  final DashboardVisibleFrameStore visibleFrames;
  final CommittedLogViewportCache cache;
  late final ExplicitCommittedPagingController controller;
  late final DashboardVisibleFrame frame;
  bool verticalInteractionActive = false;
  bool pointerIntentActive = false;
  bool structuralMotionActive = false;
  bool gateOpen = true;
  int pipelineIdleCount = 0;

  void dispose() {
    controller.dispose();
    cache.dispose();
    visibleFrames.dispose();
  }
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
  required int entryCount,
  bool hasCursor = true,
}) {
  final scope = _scope(month);
  return DashboardVisibleFrame.fromPrepared(
    _prepared(
      month,
      digest: digest,
      hasCursor: hasCursor,
      entryCount: entryCount,
    ),
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
  required int entryCount,
}) {
  final scope = _scope(month);
  final rootCount = entryCount.clamp(0, 24).toInt();
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
      groups: rootCount == 0
          ? const <DashboardDayLogGroupViewModel>[]
          : <DashboardDayLogGroupViewModel>[
              DashboardDayLogGroupViewModel(
                dateKey: '2026-07-01',
                dayLabel: '2026. július 1.',
                rows: List<DashboardLogRowViewModel>.generate(
                  rootCount,
                  _row,
                  growable: false,
                ),
              ),
            ],
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
  required int ordinal,
  required bool hasNext,
  required int entryCount,
}) {
  final scope = _scope(month);
  final start = ordinal * 24;
  final rowCount = (entryCount - start).clamp(0, 24).toInt();
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
      groups: rowCount == 0
          ? const <DashboardDayLogGroupViewModel>[]
          : <DashboardDayLogGroupViewModel>[
              DashboardDayLogGroupViewModel(
                dateKey: '2026-07-01',
                dayLabel: '2026. július 1.',
                rows: List<DashboardLogRowViewModel>.generate(
                  rowCount,
                  (index) => _row(start + index),
                  growable: false,
                ),
              ),
            ],
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

DashboardLogRowViewModel _row(int index) => DashboardLogRowViewModel(
  entryId: 'row-$index',
  displayName: 'Partner $index',
  categoryDisplayName: 'Kategória',
  formattedAmount: '1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.income,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Partner $index',
);

CommittedVerticalGeometryManifest _manifestForFrame(
  DashboardVisibleFrame frame,
) => CommittedVerticalGeometryManifest.compile(
  queryKey: frame.queryKey,
  coreRevision: frame.coreRevision,
  pageSize: 24,
  totalEntryCount: frame.logBox.entryCount,
  dayBuckets: <CommittedVerticalGeometryDayBucket>[
    if (frame.logBox.entryCount > 0)
      CommittedVerticalGeometryDayBucket(
        bookedLocalEpochDay: 20_000,
        entryCount: frame.logBox.entryCount,
      ),
  ],
);
