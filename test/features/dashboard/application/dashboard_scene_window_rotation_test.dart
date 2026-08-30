import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_prepared_revision_bundle.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rail-critical window covers every prepared query exactly once',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final window = core.railCriticalSceneWindowForIndex(index);

      expect(
        window.sceneCount,
        index.frames.length + index.compactZeroFrames.length,
      );
      expect(
        window.payloads.map((payload) => payload.queryKey.value).toSet(),
        hasLength(index.frames.length + index.compactZeroFrames.length),
      );
    },
  );

  test(
    'query publication bundle separates the visible parent from its immediate rail domain',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final publicationBundle = DashboardPreparedRevisionBundle.forIndex(
        core.preparedIndex!,
        publicationState: core.navigation.state,
      );

      expect(
        publicationBundle.structuralPublicationSceneWindow.sceneCount,
        lessThan(
          core.preparedIndex!.frames.length +
              core.preparedIndex!.compactZeroFrames.length,
        ),
      );
      expect(
        publicationBundle.structuralPublicationSceneWindow.payloads.map(
          (payload) => payload.queryKey,
        ),
        contains(core.navigation.state.parentQueryKey),
      );
      expect(
        publicationBundle.railInteractionSceneWindow.sceneCount,
        greaterThan(
          publicationBundle.structuralPublicationSceneWindow.sceneCount,
        ),
      );
    },
  );

  test(
    'a prepared revision bundle rejects a Budget bank from another revision',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final yearCount =
          index.key.yearWindowEndInclusive - index.key.yearWindowStart + 1;
      final snapshot = PreparedBudgetLimitSnapshot(
        coreRevision: index.coreRevision + 1,
        yearWindowStart: index.key.yearWindowStart,
        yearWindowEndInclusive: index.key.yearWindowEndInclusive,
        incomeBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>[],
          cells: List<PreparedBudgetLimitCell>.filled(
            1 + yearCount + yearCount * 12,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
        ),
        expenseBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>[],
          cells: List<PreparedBudgetLimitCell>.filled(
            1 + yearCount + yearCount * 12,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
        ),
      );

      expect(
        () => DashboardPreparedRevisionBundle.forIndex(
          index,
          budgetLimitSnapshot: snapshot,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'an initially open rail activates its full immediate interaction domain before the first fling',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final initialWindow = core.renderCriticalLogBoxSceneWindow();
      final interaction = core.railInteractionSceneWindowFor(
        core.navigation.state,
      );

      expect(
        initialWindow.payloads.map((payload) => payload.queryKey.value).toSet(),
        interaction.payloads.map((payload) => payload.queryKey.value).toSet(),
        reason:
            'An already-open rail is interactive on its first human gesture; '
            'its siblings cannot wait for a cancellable background warmup.',
      );

      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(cache.dispose);
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      final firstFlingTarget = interaction.payloads.firstWhere(
        (payload) => payload.queryKey.value.contains('day:2026-07-15'),
      );
      expect(
        cache.railCriticalSceneFor(firstFlingTarget),
        isNotNull,
        reason:
            'The first rail gesture must find its next day scene in the '
            'already activated startup bank.',
      );
    },
  );

  test(
    'an open-rail structural publication includes only its retained child twins',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final publication = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      final queryKeys = publication.payloads
          .map((payload) => payload.queryKey.value)
          .toSet();

      expect(publication.sceneCount, lessThanOrEqualTo(4));
      expect(
        queryKeys,
        contains('income|day:2026-07-14|categories:|partners:|refinements:'),
      );
      expect(
        queryKeys,
        contains('expense|day:2026-07-14|categories:|partners:|refinements:'),
      );
      expect(
        queryKeys,
        isNot(
          contains('income|day:2026-07-15|categories:|partners:|refinements:'),
        ),
        reason:
            'Only the currently visible rail child is structural-publication '
            'critical; siblings remain in the bounded interaction bank.',
      );
    },
  );

  test(
    'initial activation retains the exact minimal scene window it activated',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final activated = core.renderCriticalLogBoxSceneWindow();
      expect(
        activated.sceneCount,
        lessThan(
          core.preparedIndex!.frames.length +
              core.preparedIndex!.compactZeroFrames.length,
        ),
      );

      core.recordInitialSceneWindowActivation(activated);

      expect(
        core.renderCriticalLogBoxSceneWindow().payloads.map(
          (payload) => payload.queryKey.value,
        ),
        unorderedEquals(
          activated.payloads.map((payload) => payload.queryKey.value),
        ),
        reason:
            'A minimal cache activation must not be relabelled as a complete '
            'index bank. Later navigation needs to request only its exact '
            'candidate window.',
      );
    },
  );

  test(
    'demanded navigation window stays canonical when a full bank is active',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final index = core.preparedIndex!;
      final fullWindow = core.railCriticalSceneWindowForIndex(index);
      core.recordInitialSceneWindowActivation(fullWindow);

      final demanded = core.renderCriticalLogBoxSceneWindowFor(
        core.navigation.state,
      );

      expect(
        demanded.sceneCount,
        lessThan(index.frames.length + index.compactZeroFrames.length),
      );
      expect(
        demanded.payloads.map((payload) => payload.queryKey.value).toSet(),
        hasLength(demanded.sceneCount),
      );
    },
  );

  test(
    'input cancels speculative preparation without rejecting navigation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final preparation = Completer<void>();
      var cancellations = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (_, {required retainViewportId}) => preparation.future,
        activate: (_) {},
        cancel: () {
          cancellations += 1;
          if (!preparation.isCompleted) preparation.complete();
        },
      );

      final parentMove = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      await pumpEventQueue();
      expect(core.sceneWindowPreparing.value, isTrue);

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.navigatePlane(finer: false);
      core.setRailOpen(true);

      await parentMove;
      expect(cancellations, greaterThanOrEqualTo(1));
      expect(
        core.navigation.state.plane,
        TimePlane.month,
        reason:
            'A cancelled candidate is not allowed to publish before its '
            'required scene coverage is active.',
      );
      expect(
        core.navigation.state.isRailOpen,
        isFalse,
        reason:
            'Opening the rail is a structural visibility transition. A '
            'cancelled interaction-bank preparation must keep the already '
            'drawable closed state visible.',
      );
    },
  );

  test(
    'a revision publishes its index and complete rail bank together',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initialWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      final allowNextBank = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          await allowNextBank.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final publication = core.installPreparedIndex(
        buildRuntimeTestIndex(revision: 2, generation: 2),
      );
      await Future<void>.microtask(() {});
      expect(core.activePreparedRevisionBundle!.coreRevision, 1);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:1|'));

      allowNextBank.complete();
      await publication;
      expect(core.activePreparedRevisionBundle!.coreRevision, 2);
      expect(cache.activeWindowIdentity, contains('rail-critical:rev:2|'));
      expect(cache.activeWindowManifest!.isComplete, isTrue);
    },
  );

  test(
    'an open-rail revision activates its immediate sibling domain before the first fling',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.year,
        initialRailOpen: true,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      final initialWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);
      final preparedWindows = <DashboardLogBoxSceneWindow>[];
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) {
          preparedWindows.add(window);
          return cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final next = buildRuntimeTestIndex(
        revision: 2,
        generation: 2,
        entryCountForScope: (_) => 24,
        previewRowCountForScope: (scope) => switch (scope.timeScope) {
          MonthScope(:final value) when value.year == 2026 => 2,
          _ => 0,
        },
      );
      await core.installPreparedIndex(next);

      final interaction = core.railInteractionSceneWindowFor(
        core.navigation.state,
        indexOverride: next,
      );
      final revisionWindow = preparedWindows.firstWhere(
        (window) => window.identity.contains('rail-critical:rev:2|index:2'),
      );
      expect(
        revisionWindow.payloads.map((payload) => payload.queryKey).toSet(),
        interaction.payloads.map((payload) => payload.queryKey).toSet(),
        reason:
            'The revision publication itself, not a cancellable later warmup, '
            'must prepare an already-open rail for its first fling.',
      );
      expect(
        interaction.payloads
            .where((payload) => payload.previewRowCount > 0)
            .every((payload) => cache.railCriticalSceneFor(payload) != null),
        isTrue,
        reason:
            'An index replacement while the rail is already open must not '
            'hand its first sibling fling to cancellable background warmup.',
      );
    },
  );

  test('a complete active rail bank eliminates sibling rebase work', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialPlane: TimePlane.month,
      initialCoreRevision: 1,
    );
    final cache = DashboardLogBoxPreparedSceneCache();
    addTearDown(core.dispose);
    addTearDown(cache.dispose);
    await core.bootstrap();
    final window = core.railCriticalSceneWindowForIndex(core.preparedIndex!);
    await cache.prepareWindow(window: window, surfaceWidth: 378);
    cache.activateWindow(window);
    core.recordInitialSceneWindowActivation(window);
    var prepares = 0;
    core.attachLogBoxSceneWindowCoordinator(
      prepare: (_, {required retainViewportId}) async => prepares += 1,
      activate: (_) {},
      report: cache.report,
    );

    core.setRailOpen(true);
    final sibling = core.motion.catalog.logicalIndexForValue(6);
    core.semanticCrossed(sibling);
    core.settleRail(sibling);
    await pumpEventQueue();

    expect(prepares, 0);
    expect(cache.railCriticalLookupMissCount, 0);
  });

  test(
    'minimal publication bank keeps the direction twin paint-ready synchronously',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      expect(
        core
            .activePreparedRevisionBundle!
            .structuralPublicationSceneWindow
            .sceneCount,
        lessThan(core.preparedIndex!.frames.length),
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );

      expect(
        core
            .activePreparedRevisionBundle!
            .structuralPublicationSceneWindow
            .payloads
            .map((payload) => payload.queryKey.value),
        contains('expense|month:2026-07|categories:|partners:|refinements:'),
        reason:
            'The interaction-critical publication bank must contain the exact '
            'opposite-direction parent before the user can tap it.',
      );
      expect(
        core.activePreparedRevisionBundle!.railInteractionSceneWindow.payloads
            .map((payload) => payload.queryKey.value),
        contains('expense|day:2026-07-14|categories:|partners:|refinements:'),
        reason:
            'The opposite-direction immediate rail domain must be prepared '
            'once as well, so a direction switch remains paint-ready during '
            'rail movement.',
      );

      final preparesBeforeDirectionChange = prepares;
      core.selectDirection(TransactionDirection.expense);
      expect(core.navigation.state.parentQueryScope.direction.name, 'expense');
      displayFrames.flush();

      expect(
        prepares,
        preparesBeforeDirectionChange,
        reason:
            'Direction twins share one canonical critical bank; changing only '
            'direction must not schedule asynchronous scene preparation.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
        reason:
            'The visible expense payload must be drawable before any event-loop '
            'or rebase work is allowed to run.',
      );
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'minimal publication bank rebases exact scenes across plane transitions',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );

      core.navigatePlane(finer: false);
      displayFrames.flush();
      await _waitForSceneWindowIdle(core);
      displayFrames.flush();

      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );

      core.navigatePlane(finer: true);
      displayFrames.flush();
      await _waitForSceneWindowIdle(core);
      displayFrames.flush();

      expect(
        core.navigation.state.plane,
        TimePlane.month,
        reason:
            'The second structural transition must select the MONTH target.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      expect(
        prepares,
        greaterThanOrEqualTo(3),
        reason:
            'The two structural publications are required; bounded rail '
            'warming may also have started independently.',
      );
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'plane navigation keeps the current visible scope until its exact window is active',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final activeWindow = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: activeWindow, surfaceWidth: 378);
      cache.activateWindow(activeWindow);
      core.recordInitialSceneWindowActivation(activeWindow);

      final targetPreparationStarted = Completer<void>();
      final allowTargetActivation = Completer<void>();
      addTearDown(() {
        if (!allowTargetActivation.isCompleted) {
          allowTargetActivation.complete();
        }
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (!targetPreparationStarted.isCompleted) {
            targetPreparationStarted.complete();
          }
          await allowTargetActivation.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      final yearCandidate = core.presentation.planeCandidate(finer: false);
      final yearWindow = core.renderCriticalLogBoxSceneWindowFor(yearCandidate);
      expect(
        activeWindow.payloads.map((payload) => payload.queryKey.value),
        isNot(contains(yearWindow.payloads.first.queryKey.value)),
        reason: 'The test must begin outside the active month-plane window.',
      );
      final currentPayload = core.visibleFrames.value!.logBox;
      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.sceneWindowPreparing.value, isTrue);
      expect(
        core.navigation.state.plane,
        TimePlane.month,
        reason:
            'A structural candidate without an active scene must remain '
            'offscreen rather than publishing a fail-closed blank LogBox.',
      );
      expect(cache.railCriticalSceneFor(currentPayload), isNotNull);
      await targetPreparationStarted.future.timeout(const Duration(seconds: 1));

      allowTargetActivation.complete();
      await pumpEventQueue();
      displayFrames.flush();

      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'parent navigation keeps the current visible scope until its exact window is active',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final activeWindow = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: activeWindow, surfaceWidth: 378);
      cache.activateWindow(activeWindow);
      core.recordInitialSceneWindowActivation(activeWindow);

      final targetPreparationStarted = Completer<void>();
      final allowTargetActivation = Completer<void>();
      addTearDown(() {
        if (!allowTargetActivation.isCompleted) {
          allowTargetActivation.complete();
        }
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (!targetPreparationStarted.isCompleted) {
            targetPreparationStarted.complete();
          }
          await allowTargetActivation.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      final currentPayload = core.visibleFrames.value!.logBox;
      final navigation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.navigation.state.monthCursor.month, 7);
      expect(cache.railCriticalSceneFor(currentPayload), isNotNull);
      await targetPreparationStarted.future.timeout(const Duration(seconds: 1));

      allowTargetActivation.complete();
      await navigation;
      displayFrames.flush();

      expect(core.navigation.state.monthCursor.month, 6);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      expect(cache.railCriticalLookupMissCount, 0);
    },
  );

  test(
    'an open-rail Summary parent transition publishes its O(1) first frame before interaction warmup',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.recordInitialSceneWindowActivation(initial);

      final preparationStarted = Completer<void>();
      final allowPreparation = Completer<void>();
      addTearDown(() {
        if (!allowPreparation.isCompleted) allowPreparation.complete();
      });
      DashboardLogBoxSceneWindow? requested;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          requested = window;
          if (!preparationStarted.isCompleted) preparationStarted.complete();
          await allowPreparation.future;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      final candidate = core.previewParent(
        DashboardTimeNavigationChangeDirection.backward,
      )!;
      final expectedPublication = core.structuralPublicationSceneWindowFor(
        candidate,
      );
      final transition = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      await preparationStarted.future.timeout(const Duration(seconds: 1));

      expect(core.navigation.state.monthCursor.month, 7);
      expect(requested?.sceneCount, expectedPublication.sceneCount);
      expect(
        requested!.sceneCount,
        lessThanOrEqualTo(4),
        reason:
            'An open rail does not turn a Summary-parent swipe into a full '
            'target sibling-bank foreground barrier.',
      );

      allowPreparation.complete();
      await transition;
      displayFrames.flush();

      expect(core.navigation.state.monthCursor.month, 6);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
    },
  );

  test(
    'an idle adjacent parent hotset makes the next open-rail Summary move a retained interaction hit',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final active = core.railInteractionSceneWindowFor(core.navigation.state);
      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      core.recordInitialSceneWindowActivation(active);

      var genericPrepareCalls = 0;
      var retainedPrepareCalls = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          genericPrepareCalls += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        prepareRetained:
            (window, {required retainedKey, required retainViewportId}) async {
              retainedPrepareCalls += 1;
              await cache.prepareRetainedWindow(
                retainedKey: retainedKey,
                window: window,
                retainViewportId: retainViewportId,
                surfaceWidth: 378,
              );
            },
        hasRetained: cache.hasRetainedWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      displayFrames.flush();
      await pumpEventQueue(times: 20);

      expect(retainedPrepareCalls, greaterThanOrEqualTo(1));
      final candidate = core.previewParent(
        DashboardTimeNavigationChangeDirection.backward,
      )!;
      final candidateInteraction = core.railInteractionSceneWindowFor(
        candidate,
      );
      expect(cache.hasRetainedWindow(candidateInteraction), isTrue);

      final navigation = core.navigateParent(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(core.navigation.state.monthCursor.month, 6);
      for (final payload in candidateInteraction.payloads) {
        expect(
          cache.railCriticalSceneFor(payload),
          isNotNull,
          reason:
              'The already-retained interaction bank must become active in '
              'the same parent-navigation turn; later background warmup may '
              'not be the source of the visible sibling domain.',
        );
      }
      await navigation;
      expect(genericPrepareCalls, greaterThanOrEqualTo(0));
    },
  );

  test(
    'RED LIVE-TIME: an experimental MONTH crossing activates its retained root before settle',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final active = core.railInteractionSceneWindowFor(core.navigation.state);
      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      core.recordInitialSceneWindowActivation(active);

      var genericPrepareCalls = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          genericPrepareCalls += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        prepareRetained:
            (window, {required retainedKey, required retainViewportId}) async {
              await cache.prepareRetainedWindow(
                retainedKey: retainedKey,
                window: window,
                retainViewportId: retainViewportId,
                surfaceWidth: 378,
              );
            },
        hasRetained: cache.hasRetainedWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      displayFrames.flush();
      await pumpEventQueue(times: 20);

      final candidate = core.navigation.temporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.month,
        offset: -1,
      )!;
      final candidateInteraction = core.railInteractionSceneWindowFor(
        candidate,
      );
      expect(cache.hasRetainedWindow(candidateInteraction), isTrue);
      final genericPrepareCallsBeforeCross = genericPrepareCalls;

      core.navigateExperimentalTemporalComponentOffset(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.month,
        offset: -1,
      );
      displayFrames.flush();

      expect(
        core.navigation.state.monthCursor.month,
        6,
        reason:
            'A semantic carousel crossing must publish its exact prepared '
            'visible target while the gesture is still active.',
      );
      expect(
        core.visibleFrames.logBoxLane.value!.queryKey,
        candidate.temporalAnchor.sourceChildQueryKey,
      );
      for (final payload in candidateInteraction.payloads) {
        expect(
          cache.railCriticalSceneFor(payload),
          isNotNull,
          reason: 'The retained exact root must activate in the crossing turn.',
        );
      }
      expect(
        genericPrepareCalls,
        genericPrepareCallsBeforeCross,
        reason: 'A transient crossing must not request foreground scene work.',
      );

      final visibleBeforeSettle = core.visibleFrames.value;
      core.settleExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.month,
      );
      await pumpEventQueue(times: 20);

      expect(core.navigation.state.monthCursor.month, 6);
      for (final payload in candidateInteraction.payloads) {
        expect(
          cache.railCriticalSceneFor(payload),
          isNotNull,
          reason: 'Settle must activate every retained rail-critical scene.',
        );
      }
      expect(
        genericPrepareCalls,
        genericPrepareCallsBeforeCross,
        reason:
            'Settle promotes the already-visible retained hotset rather than '
            'requesting foreground work.',
      );
      expect(core.visibleFrames.value, same(visibleBeforeSettle));
    },
  );

  test(
    'restricted Summary parent hotset retains the wrapped boundary target',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 8, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();
      await core.applyQuery(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
          temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
            QueryPeriodSelection.month(2026, 6),
            QueryPeriodSelection.month(2026, 7),
            QueryPeriodSelection.month(2026, 8),
          }),
        ),
      );

      final active = core.railInteractionSceneWindowFor(core.navigation.state);
      await cache.prepareWindow(window: active, surfaceWidth: 378);
      cache.activateWindow(active);
      core.recordInitialSceneWindowActivation(active);

      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        prepareRetained:
            (window, {required retainedKey, required retainViewportId}) async {
              await cache.prepareRetainedWindow(
                retainedKey: retainedKey,
                window: window,
                retainViewportId: retainViewportId,
                surfaceWidth: 378,
              );
            },
        hasRetained: cache.hasRetainedWindow,
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await _flushDisplayFramesUntilIdle(core, displayFrames);

      final wrapped = core.previewParent(
        DashboardTimeNavigationChangeDirection.forward,
      )!;
      expect(wrapped.monthCursor.month, 6);
      final wrappedInteraction = core.railInteractionSceneWindowFor(wrapped);
      expect(cache.hasRetainedWindow(wrappedInteraction), isTrue);

      await core.navigateParent(DashboardTimeNavigationChangeDirection.forward);
      expect(core.navigation.state.monthCursor.month, 6);
      for (final payload in wrappedInteraction.payloads) {
        if (payload.flatItems.isEmpty) continue;
        expect(cache.railCriticalSceneFor(payload), isNotNull);
      }
    },
  );

  test(
    'input keeps an in-flight required scene preparation alive instead of restarting it',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var blockNextPreparation = false;
      var prepares = 0;
      var cancellations = 0;
      Completer<void>? blockedPreparation;
      final blockedPreparationStarted = Completer<void>();
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          if (blockNextPreparation &&
              window.sceneCount < core.preparedIndex!.frames.length) {
            blockedPreparation = Completer<void>();
            if (!blockedPreparationStarted.isCompleted) {
              blockedPreparationStarted.complete();
            }
            await blockedPreparation!.future;
            return;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          cancellations += 1;
          final pending = blockedPreparation;
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeDemand = prepares;

      blockNextPreparation = true;
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();
      expect(
        prepares,
        preparesBeforeDemand + 1,
        reason:
            'Foreground structural publication must begin during active '
            'motion; only interaction warming is deferred.',
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await blockedPreparationStarted.future;
      expect(prepares, preparesBeforeDemand + 1);
      final cancellationsBeforeInput = cancellations;

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      await pumpEventQueue();
      expect(
        cancellations,
        cancellationsBeforeInput,
        reason:
            'The exact required target is already cooperatively slice-bounded; '
            'input may cancel speculation but must not erase its progress.',
      );

      blockNextPreparation = false;
      blockedPreparation!.complete();
      core.settleRail(0);
      displayFrames.flush();
      await pumpEventQueue();

      expect(
        prepares,
        preparesBeforeDemand + 1,
        reason:
            'The same required target completes from its existing work rather '
            'than restarting after every pointer-down.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
    },
  );

  test(
    'a newer deferred coverage target supersedes a cancelled in-flight target',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var blockNextPreparation = false;
      var prepares = 0;
      Completer<void>? blockedPreparation;
      final blockedPreparationStarted = Completer<void>();
      final preparedWindows = <Set<String>>[];
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          preparedWindows.add(
            window.payloads.map((payload) => payload.queryKey.value).toSet(),
          );
          if (blockNextPreparation &&
              window.sceneCount < core.preparedIndex!.frames.length) {
            blockedPreparation = Completer<void>();
            if (!blockedPreparationStarted.isCompleted) {
              blockedPreparationStarted.complete();
            }
            await blockedPreparation!.future;
            return;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          final pending = blockedPreparation;
          if (pending != null && !pending.isCompleted) {
            pending.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeDemand = prepares;

      blockNextPreparation = true;
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      final targetB = core.presentation
          .planeCandidate(finer: false)
          .parentQueryKey;
      core.navigatePlane(finer: false); // B = 2026 year plane.
      displayFrames.flush();
      await pumpEventQueue();
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await blockedPreparationStarted.future;

      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      await pumpEventQueue();
      final targetC = core.previewParent(
        DashboardTimeNavigationChangeDirection.backward,
      )!;
      unawaited(
        core.navigateParent(DashboardTimeNavigationChangeDirection.backward),
      );
      displayFrames.flush();
      await pumpEventQueue();

      blockNextPreparation = false;
      core.settleRail(0);
      await pumpEventQueue();

      expect(
        prepares,
        preparesBeforeDemand + 2,
        reason: 'Only B once and its newer C replacement may be prepared.',
      );
      expect(
        preparedWindows.last,
        contains(targetC.parentQueryKey.value),
        reason: 'The retry must prepare the newer C target, never restart B.',
      );
      expect(preparedWindows.last, isNot(contains(targetB.value)));
    },
  );

  test(
    'motion keeps rail warming deferred while foreground plane publication proceeds',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeMotion = prepares;

      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.selectDirection(TransactionDirection.expense);
      core.navigatePlane(finer: false);
      displayFrames.flush();
      await pumpEventQueue();

      expect(core.navigation.state.parentQueryScope.direction.name, 'expense');
      expect(
        core.navigation.state.plane,
        TimePlane.year,
        reason:
            'The small foreground YEAR scene is safe to prepare while the '
            'Summary animation is active, so the plane must not wait for idle.',
      );
      expect(
        prepares,
        preparesBeforeMotion + 1,
        reason:
            'Only the O(1) publication target runs during motion; the rail '
            'interaction domain remains background work.',
      );

      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await _waitForSceneWindowIdle(core);

      expect(
        prepares,
        greaterThanOrEqualTo(preparesBeforeMotion + 1),
        reason:
            'Idle may now start the separate rail-interaction warmup, but it '
            'must not delay or revert the already committed YEAR target.',
      );
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      expect(core.navigation.state.plane, TimePlane.year);
    },
  );

  test(
    'an old SUM settle cannot supersede a pending SUM to YEAR transition',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var blockYearWindow = false;
      final yearPreparationStarted = Completer<void>();
      final allowYearActivation = Completer<void>();
      late String yearParentQueryKey;
      addTearDown(() {
        if (!allowYearActivation.isCompleted) allowYearActivation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (blockYearWindow &&
              window.coverageIdentity?.parentQueryKey == yearParentQueryKey) {
            if (!yearPreparationStarted.isCompleted) {
              yearPreparationStarted.complete();
            }
            await allowYearActivation.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );
      // Deliberately keep the interaction warmup out of this race fixture.
      // The production idle warmup normally makes SUM -> YEAR a cache hit;
      // this test exercises the remaining cold path where a previous warmup
      // was cancelled before the structural intent arrived.
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );

      core.presentation.setRailOpen(true);
      final sum2025 = core.motion.catalog.logicalIndexForValue(2025);
      core.beginRailMotion(CenteredCarouselMotionOrigin.programmatic);
      core.semanticCrossed(sum2025);
      displayFrames.flush();
      await pumpEventQueue();

      final yearCandidate = core.presentation.planeCandidate(finer: true);
      expect(yearCandidate.parentQueryKey.value, contains('|year:2025|'));
      yearParentQueryKey = yearCandidate.parentQueryKey.value;
      blockYearWindow = true;
      core.navigatePlane(finer: true);
      // This settle is from the still-committed SUM rail. It may retain
      // temporal metadata, but must never replace the pending YEAR
      // renderability requirement while the candidate waits for its bank.
      core.settleRail(sum2025);
      displayFrames.flush();
      await yearPreparationStarted.future.timeout(const Duration(seconds: 1));

      expect(core.navigation.state.plane, TimePlane.sum);
      allowYearActivation.complete();
      await _waitForSceneWindowIdle(core);
      displayFrames.flush();

      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        cache.railCriticalSceneFor(
          core
              .structuralPublicationSceneWindowFor(core.navigation.state)
              .payloads
              .first,
        ),
        isNotNull,
      );
    },
  );

  test(
    'repeated identical Summary Pill intents join one pending preparation',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      var cancellations = 0;
      var blockYearWindow = false;
      final yearPreparationStarted = Completer<void>();
      final allowYearActivation = Completer<void>();
      late String yearParentQueryKey;
      addTearDown(() {
        if (!allowYearActivation.isCompleted) allowYearActivation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          if (blockYearWindow &&
              window.coverageIdentity?.parentQueryKey == yearParentQueryKey) {
            if (!yearPreparationStarted.isCompleted) {
              yearPreparationStarted.complete();
            }
            await allowYearActivation.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          cancellations += 1;
          cache.cancelInFlightPreparation();
        },
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeIntent = prepares;

      yearParentQueryKey = core.presentation
          .planeCandidate(finer: true)
          .parentQueryKey
          .value;
      blockYearWindow = true;
      core.navigatePlane(finer: true);
      displayFrames.flush();
      await yearPreparationStarted.future.timeout(const Duration(seconds: 1));

      core.navigatePlane(finer: true);
      core.navigatePlane(finer: true);
      displayFrames.flush();
      await pumpEventQueue();

      expect(prepares, preparesBeforeIntent + 1);
      expect(cancellations, 0);

      allowYearActivation.complete();
      await _waitForSceneWindowIdle(core);
      displayFrames.flush();

      expect(core.navigation.state.plane, TimePlane.year);
    },
  );

  test(
    'an old settle and repeated same target keep one pending YEAR intent',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      var prepares = 0;
      var yearPrepares = 0;
      var cancellations = 0;
      late String yearParentQueryKey;
      final yearPreparationStarted = Completer<void>();
      final allowYearActivation = Completer<void>();
      addTearDown(() {
        if (!allowYearActivation.isCompleted) allowYearActivation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          if (window.coverageIdentity?.parentQueryKey == yearParentQueryKey) {
            yearPrepares += 1;
            if (!yearPreparationStarted.isCompleted) {
              yearPreparationStarted.complete();
            }
            await allowYearActivation.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          cancellations += 1;
          cache.cancelInFlightPreparation();
        },
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          generation: 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );
      final preparesBeforeIntent = prepares;

      core.presentation.setRailOpen(true);
      final sum2025 = core.motion.catalog.logicalIndexForValue(2025);
      core.beginRailMotion(CenteredCarouselMotionOrigin.programmatic);
      core.semanticCrossed(sum2025);
      displayFrames.flush();
      await pumpEventQueue();
      yearParentQueryKey = core.presentation
          .planeCandidate(finer: true)
          .parentQueryKey
          .value;

      core.navigatePlane(finer: true);
      core.settleRail(sum2025); // Old committed SUM settle.
      displayFrames.flush();
      await yearPreparationStarted.future.timeout(const Duration(seconds: 1));

      core.navigatePlane(finer: true); // Same uncommitted YEAR intent.
      displayFrames.flush();
      await pumpEventQueue();

      expect(prepares, greaterThanOrEqualTo(preparesBeforeIntent + 1));
      expect(yearPrepares, 1);
      expect(cancellations, 0);

      allowYearActivation.complete();
      await _waitForSceneWindowIdle(core);
      displayFrames.flush();
      expect(core.navigation.state.plane, TimePlane.year);
    },
  );

  test(
    'prepared-index publication cancels old-index scene work immediately',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final oldIndexGeneration = core.preparedIndex!.generation;
      final oldCoreRevision = core.preparedIndex!.coreRevision;
      final oldYearParentQueryKey = core.presentation
          .planeCandidate(finer: true)
          .parentQueryKey
          .value;
      var oldPreparationCount = 0;
      final oldPreparationStarted = Completer<void>();
      final oldPreparation = Completer<void>();
      addTearDown(() {
        if (!oldPreparation.isCompleted) oldPreparation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (window.coverageIdentity?.indexGeneration == oldIndexGeneration &&
              window.coverageIdentity?.parentQueryKey ==
                  oldYearParentQueryKey) {
            oldPreparationCount += 1;
            if (!oldPreparationStarted.isCompleted) {
              oldPreparationStarted.complete();
            }
            await oldPreparation.future;
            return;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: () {
          if (!oldPreparation.isCompleted) {
            oldPreparation.completeError(
              const DashboardLogBoxScenePreparationCancelled(),
            );
          }
        },
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      core.navigatePlane(finer: true);
      displayFrames.flush();
      await oldPreparationStarted.future.timeout(const Duration(seconds: 1));

      final publication = core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: oldCoreRevision,
          generation: oldIndexGeneration + 2,
          previewRowCountForScope: (_) => 1,
        ),
        publicationState: core.navigation.state,
      );

      expect(
        await publication.timeout(
          const Duration(milliseconds: 250),
          onTimeout: () => false,
        ),
        isTrue,
        reason:
            'A Query/index publication must invalidate, not wait behind, an '
            'old immutable-index navigation preparation.',
      );
      expect(core.preparedIndex!.generation, oldIndexGeneration + 2);
      expect(oldPreparationCount, 1);
    },
  );

  test(
    'rail interaction warmup follows structural publication without delaying it',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      // Record before attaching the coordinator so this setup has no
      // speculative interaction preparation in flight.
      core.recordInitialSceneWindowActivation(initial);

      final interactionStarted = Completer<void>();
      final allowInteraction = Completer<void>();
      final preparedWindows = <DashboardLogBoxSceneWindow>[];
      addTearDown(() {
        if (!allowInteraction.isCompleted) allowInteraction.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          preparedWindows.add(window);
          if (window.sceneCount > 4) {
            if (!interactionStarted.isCompleted) interactionStarted.complete();
            await allowInteraction.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      core.navigatePlane(finer: false); // month -> year
      await interactionStarted.future.timeout(const Duration(seconds: 1));

      expect(core.navigation.state.plane, TimePlane.year);
      expect(preparedWindows.first.sceneCount, lessThanOrEqualTo(4));
      expect(preparedWindows.last.sceneCount, greaterThan(4));
      expect(
        cache.railCriticalSceneFor(preparedWindows.first.payloads.first),
        isNotNull,
        reason:
            'The YEAR parent publishes only once its small foreground window '
            'is drawable, while the sibling bank may still be warming.',
      );

      allowInteraction.complete();
      await pumpEventQueue();
    },
  );

  test(
    'idle rail warmup prewarms both adjacent Summary Pill publication targets',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.recordInitialSceneWindowActivation(initial);

      final preparedWindows = <DashboardLogBoxSceneWindow>[];
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          preparedWindows.add(window);
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final finerCandidate = core.presentation.planeCandidate(finer: true);
      final coarserCandidate = core.presentation.planeCandidate(finer: false);
      final finerPublication = core.structuralPublicationSceneWindowFor(
        finerCandidate,
      );
      final coarserPublication = core.structuralPublicationSceneWindowFor(
        coarserCandidate,
      );
      core.setMotionLaneActive(DashboardMotionLane.visualHost, true);
      core.setMotionLaneActive(DashboardMotionLane.visualHost, false);
      await pumpEventQueue();

      expect(preparedWindows, isNotEmpty);
      final warmupKeys = preparedWindows.last.payloads
          .map((payload) => payload.queryKey.value)
          .toSet();
      expect(
        warmupKeys,
        containsAll(
          finerPublication.payloads.map((payload) => payload.queryKey.value),
        ),
      );
      expect(
        warmupKeys,
        containsAll(
          coarserPublication.payloads.map((payload) => payload.queryKey.value),
        ),
      );

      final preparesBeforeTap = preparedWindows.length;
      core.navigatePlane(finer: true);
      expect(core.navigation.state.plane, finerCandidate.plane);
      expect(
        preparedWindows.length,
        preparesBeforeTap,
        reason:
            'The deterministic next-plane parent was already in the bounded '
            'idle warmup, so the tap takes the cache-hit publication path.',
      );
    },
  );

  test(
    'opening an unwarmed rail keeps the current frame until its interaction bank is ready',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.recordInitialSceneWindowActivation(initial);

      final interactionStarted = Completer<void>();
      final allowInteraction = Completer<void>();
      addTearDown(() {
        if (!allowInteraction.isCompleted) allowInteraction.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (window.sceneCount > 4) {
            if (!interactionStarted.isCompleted) interactionStarted.complete();
            await allowInteraction.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final closedFrame = core.visibleFrames.value!.logBox;
      core.setRailOpen(true);
      await interactionStarted.future.timeout(const Duration(seconds: 1));

      expect(core.navigation.state.isRailOpen, isFalse);
      expect(cache.railCriticalSceneFor(closedFrame), isNotNull);

      allowInteraction.complete();
      await _waitForSceneWindowIdle(core);
      expect(core.navigation.state.isRailOpen, isTrue);
      expect(
        cache.railCriticalSceneFor(core.visibleFrames.value!.logBox),
        isNotNull,
      );
      final interaction = core.railInteractionSceneWindowFor(
        core.navigation.state,
      );
      for (final payload in interaction.payloads) {
        if (payload.flatItems.isEmpty) continue;
        expect(
          cache.railCriticalSceneFor(payload),
          isNotNull,
          reason:
              'Once the explicitly opened rail becomes interactive, every '
              'non-empty first-fling sibling (including its direction twin) '
              'must already be drawable rather than depending on a later '
              'background warmup.',
        );
      }
    },
  );

  test(
    'a close intent supersedes an in-flight rail-open preparation',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.recordInitialSceneWindowActivation(initial);

      final interactionStarted = Completer<void>();
      final allowInteraction = Completer<void>();
      addTearDown(() {
        if (!allowInteraction.isCompleted) allowInteraction.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (window.sceneCount > 4) {
            if (!interactionStarted.isCompleted) interactionStarted.complete();
            await allowInteraction.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      core.setRailOpen(true);
      await interactionStarted.future.timeout(const Duration(seconds: 1));
      expect(core.navigation.state.isRailOpen, isFalse);

      // The committed state is still closed, but this is a newer user intent.
      // It must invalidate the pending open rather than being treated as a
      // redundant request for the old committed state.
      core.toggleRail();
      allowInteraction.complete();
      await _waitForSceneWindowIdle(core);

      expect(
        core.navigation.state.isRailOpen,
        isFalse,
        reason:
            'A stale asynchronous open completion must not overwrite the '
            'newer close intent.',
      );
    },
  );

  test(
    'a rapid open close open sequence commits only the latest rail intent',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initial = core.structuralPublicationSceneWindowFor(
        core.navigation.state,
      );
      await cache.prepareWindow(window: initial, surfaceWidth: 378);
      cache.activateWindow(initial);
      core.recordInitialSceneWindowActivation(initial);

      final interactionStarted = Completer<void>();
      final allowInteraction = Completer<void>();
      addTearDown(() {
        if (!allowInteraction.isCompleted) allowInteraction.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          if (window.sceneCount > 4) {
            if (!interactionStarted.isCompleted) interactionStarted.complete();
            await allowInteraction.future;
          }
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      core.toggleRail(); // closed -> desired open; expensive interaction bank.
      await interactionStarted.future.timeout(const Duration(seconds: 1));
      core.toggleRail(); // desired open -> close, despite stale committed false.
      core.toggleRail(); // desired close -> open, before older work completes.
      allowInteraction.complete();
      await _waitForSceneWindowIdle(core);

      expect(
        core.navigation.state.isRailOpen,
        isTrue,
        reason:
            'Each toggle must invert the latest desired visibility, so the '
            'last intent—not the first stale async completion—wins.',
      );
    },
  );

  test(
    'structural plane publication windows stay independent of rail sibling count',
    () async {
      final cases = <TimePlane, bool>{
        TimePlane.sum: true,
        TimePlane.year: true,
        TimePlane.month: false,
      };
      for (final entry in cases.entries) {
        final core = DashboardCoreController(
          initialDate: DateTime(2026, 7, 14),
          initialPlane: entry.key,
          initialCoreRevision: 1,
        );
        addTearDown(core.dispose);
        await core.bootstrap();

        final candidate = core.presentation.planeCandidate(finer: entry.value);
        final publication = core.renderCriticalLogBoxSceneWindowFor(candidate);

        expect(
          publication.sceneCount,
          lessThanOrEqualTo(4),
          reason:
              'A ${entry.key.name} plane transition may prepare the visible '
              'parent and direction twin, but never the entire sibling rail.',
        );
      }
    },
  );

  test(
    'an open-rail Summary plane transition prepares only its first-frame hotset',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      final preparationStarted = Completer<DashboardLogBoxSceneWindow>();
      final allowPreparation = Completer<void>();
      addTearDown(() {
        if (!allowPreparation.isCompleted) allowPreparation.complete();
      });
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          preparationStarted.complete(window);
          await allowPreparation.future;
        },
        activate: (_) {},
        cancel: () {},
      );

      core.navigatePlane(finer: false);
      final requested = await preparationStarted.future.timeout(
        const Duration(seconds: 1),
      );

      expect(
        requested.sceneCount,
        lessThanOrEqualTo(4),
        reason:
            'An open rail does not make every target sibling publication '
            'critical; only the first drawable parent/retained-child twins '
            'may block the Summary Pill transition.',
      );
    },
  );

  test(
    'a structural foreground publication request begins while summary motion is active',
    () async {
      final displayFrames = _DisplayFrameScheduler();
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
        displayFrameScheduler: displayFrames,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      await core.bootstrap();

      final initialWindow = core.renderCriticalLogBoxSceneWindow();
      await cache.prepareWindow(window: initialWindow, surfaceWidth: 378);
      cache.activateWindow(initialWindow);
      core.recordInitialSceneWindowActivation(initialWindow);

      var prepares = 0;
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) async {
          prepares += 1;
          await cache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            surfaceWidth: 378,
          );
        },
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        scheduleRebase: displayFrames.scheduleFrame,
        report: cache.report,
      );

      core.setMotionLaneActive(DashboardMotionLane.summaryShell, true);
      core.navigatePlane(finer: false);
      await pumpEventQueue();

      expect(
        prepares,
        1,
        reason:
            'Structural publication is foreground work and must not wait for '
            'the Summary Pill animation lane to become idle.',
      );
      expect(
        core.navigation.state.plane,
        TimePlane.year,
        reason:
            'The already completed O(1) foreground preparation may publish '
            'before the independently animated Summary lane becomes idle.',
      );
    },
  );
}

Future<void> _waitForSceneWindowIdle(DashboardCoreController core) async {
  for (var attempt = 0; attempt < 32; attempt += 1) {
    await pumpEventQueue();
    if (!core.sceneWindowPreparing.value) return;
  }
  fail('Scene window preparation did not return to idle.');
}

Future<void> _flushDisplayFramesUntilIdle(
  DashboardCoreController core,
  _DisplayFrameScheduler displayFrames,
) async {
  for (var attempt = 0; attempt < 32; attempt += 1) {
    await pumpEventQueue();
    displayFrames.flush();
    await pumpEventQueue();
    if (!core.sceneWindowPreparing.value &&
        !displayFrames.hasPendingCallbacks) {
      await pumpEventQueue();
      if (!core.sceneWindowPreparing.value &&
          !displayFrames.hasPendingCallbacks) {
        return;
      }
    }
  }
  fail('Display-frame work did not return to idle.');
}

final class _DisplayFrameScheduler implements DashboardDisplayFrameScheduler {
  final List<VoidCallback> _callbacks = <VoidCallback>[];
  int _frame = 0;

  @override
  int get currentFrameNumber => _frame;

  bool get hasPendingCallbacks => _callbacks.isNotEmpty;

  @override
  void scheduleFrame(VoidCallback callback) => _callbacks.add(callback);

  void flush() {
    _frame += 1;
    final callbacks = List<VoidCallback>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}
