import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../../../support/avatar_target_liveness_fixture.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_pump.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  for (final scenario in ['cold', 'persistent20cycles', 'sparse']) {
    final coldPartialHotset = scenario != 'persistent20cycles';
    testWidgets(
      'AVL persistent real CoreDashboard nonempty Avatar final-target liveness without Time scenario=$scenario',
      (tester) async {
        final repository = AvatarTargetLivenessRepository(
          populatedHandles: scenario == 'sparse' ? {1, 7, 8} : null,
        );
        final core = DashboardCoreController(
          dataRepository: repository,
          initialDate: DateTime.utc(2026, 7, 14),
          initialCoreRevision: 1,
          initialDirection: LedgerDirection.expense,
          initialPlane: TimePlane.month,
          initialRailOpen: false,
        );
        final mode = DashboardCoreModeController(
          initialMode: DashboardModeSpec.budget,
        );
        final categories = ValueNotifier<List<FluviCategory>>(
          repository.categories,
        );
        addTearDown(core.dispose);
        addTearDown(mode.dispose);
        addTearDown(categories.dispose);
        await core.bootstrap();
        if (coldPartialHotset) {
          // A valid partially prepared semantic horizon, with no manually
          // installed painter/cache resources. Mount expands it to all targets.
          core.primeBudgetAvatarFocusHotset(const [
            DashboardFocusFacet(
              id: 'avatar-category-1',
              displayName: 'Category 1',
            ),
          ]);
        }
        await pumpDashboardSurface(
          tester,
          CoreDashboard(
            controller: core,
            modeController: mode,
            categoryCollection: categories,
          ),
        );
        // FakeAsync otherwise repeatedly drains the scheduler's rejected idle
        // Timer.run before it can advance the next animation frame. Execute the
        // real callback: Core still rejects stale/motion-blocked hotset work.
        final priorSchedulingStrategy = tester.binding.schedulingStrategy;
        tester.binding.schedulingStrategy =
            ({required priority, required scheduler}) => true;
        addTearDown(
          () => tester.binding.schedulingStrategy = priorSchedulingStrategy,
        );
        for (var frame = 0; frame < (coldPartialHotset ? 0 : 80); frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (core.budgetAvatarLiveRootReady.value) break;
        }
        final rail = tester.widget<BudgetTargetAvatarRail>(
          find.byType(BudgetTargetAvatarRail),
        );
        final cache = tester
            .widget<DashboardLogBoxViewport>(
              find.byType(DashboardLogBoxViewport),
            )
            .preparedSceneCache!;
        expect(rail.presentation.targetForHandle(8), isNotNull);
        expect(rail.presentation.targetForHandle(9), isNull);
        expect(
          core.visibleFrames.logBoxLane.value!.logBox.previewRowCount,
          repository.rows.length,
        );
        final owner = tester.state(find.byType(CoreDashboard));
        final carouselFinder = find.byKey(
          const ValueKey('budget-target-avatar-carousel'),
        );
        final carousel = tester.widget<CenteredCarousel>(carouselFinder);
        final controller = carousel.controller;
        final position = controller.scrollController.position;
        final physics = controller.physicsCreationCount;
        final observedNonempty = <int>{};
        final observedEmpty = <int>{};
        final cycleCount = scenario == 'persistent20cycles' ? 20 : 2;
        for (var flight = 0; flight < cycleCount * 2; flight++) {
          final startSequence =
              FluviDiagnosticLogger.entries.lastOrNull?.sequence ?? 0;
          Iterable<FluviDiagnosticEvent> flightEvents() => FluviDiagnosticLogger
              .entries
              .where((event) => (event.sequence ?? 0) > startSequence);
          await tester.fling(
            find.byKey(const ValueKey('budget-target-avatar-carousel')),
            Offset(flight.isEven ? -180 : 180, 0),
            2400,
          );
          for (var frame = 0; frame < 180; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            final events = flightEvents();
            if (events.any((event) => event.stage == 'AV|FLING_SETTLED') &&
                !core.diagnostics.isMotionActive &&
                core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'] ==
                    0 &&
                core.budgetAvatarTargetPainted.value?.targetHandle ==
                    rail.presentation.value.selectedHandle &&
                core.navigation.state.parentQueryScope.categoryIds.toString() ==
                    core.visibleFrames.logBoxLane.value!.scope.categoryIds
                        .toString()) {
              await tester.pump(const Duration(milliseconds: 16));
              await tester.pump(const Duration(milliseconds: 16));
              break;
            }
          }
          final settles = flightEvents().where(
            (event) => event.stage == 'AV|FLING_SETTLED',
          );
          expect(settles, isNotEmpty);
          final physical = int.parse(
            RegExp(
              r'settledTargetHandle=(\d+)',
            ).firstMatch(settles.last.scope!)!.group(1)!,
          );
          final target = rail.presentation.targetForHandle(physical)!;
          final expectedCategory = target.category?.id;
          final expectedIds = expectedCategory == null
              ? <String>{}
              : {expectedCategory};
          final trace = flightEvents()
              .where(
                (event) =>
                    event.stage.startsWith('AV') ||
                    event.stage.contains('FOCUS'),
              )
              .map((e) => '${e.stage} ${e.scope}')
              .join('\n');
          expect(
            rail.presentation.value.selectedHandle,
            physical,
            reason: 'flight=$flight\n$trace',
          );
          expect(core.focus.state?.category?.id, expectedCategory);
          expect(
            core.visibleFrames.logBoxLane.value!.scope.categoryIds,
            expectedIds,
          );
          expect(
            core.navigation.state.parentQueryScope.categoryIds,
            expectedIds,
          );
          expect(core.budgetAvatarTargetPainted.value?.targetHandle, physical);
          final expectedRows = expectedCategory == null
              ? repository.rows.length
              : repository.rows
                    .where((row) => row.categoryId == expectedCategory)
                    .length;
          expect(
            core.visibleFrames.logBoxLane.value!.logBox.previewRowCount,
            expectedRows,
          );
          final events = flightEvents();
          for (final event in events.where(
            (event) => event.stage == 'AV|LOGBOX_TARGET_PAINTED',
          )) {
            final handle = _field(event.scope!, 'targetHandle');
            if (event.scope!.contains('exactEmpty=true')) {
              observedEmpty.add(handle);
            } else {
              observedNonempty.add(handle);
            }
          }
          for (final stage in [
            'BUDGET_HEADER_PAINTED',
            'BUDGET_PROGRESS_PAINTED',
          ]) {
            final paints = events.where((event) => event.stage == stage);
            expect(paints, isNotEmpty, reason: '$stage final=$physical');
            final paint = paints.last;
            expect(
              _field(paint.scope!, 'targetHandle'),
              physical,
              reason: '$stage ${paint.scope}',
            );
            expect(
              _field(paint.scope!, 'displayNumeratorScaled100'),
              rail.presentation.value.liveSelection.displayNumeratorScaled100,
              reason: stage,
            );
            expect(
              _field(paint.scope!, 'displayDenominatorScaled100'),
              rail.presentation.value.liveSelection.displayDenominatorScaled100,
              reason: stage,
            );
          }
          final requests = events
              .where((event) => event.stage == 'AV|PREVIEW_REQUESTED')
              .length;
          final terminals = events.where(
            (event) => event.stage == 'AV|PREVIEW_TERMINAL',
          );
          expect(
            terminals.length,
            requests,
            reason: 'Each preview must terminate once: flight=$flight',
          );
          expect(
            terminals.any(
              (event) => event.scope!.contains('explicitInvariantFailure'),
            ),
            isFalse,
          );
          expect(
            core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
            0,
          );
          expect(
            core.budgetAvatarFocusHotsetDiagnostics['cached'],
            lessThanOrEqualTo(17),
          );
          expect(
            core.budgetAvatarFocusHotsetDiagnostics['pending'],
            lessThanOrEqualTo(17),
          );
          expect(cache.retainedCandidateBankCount, lessThanOrEqualTo(6));
          expect(
            cache.preparedSceneCount,
            lessThanOrEqualTo(cache.maximumRetainedScenes),
          );
          expect(
            cache.retainedCandidateEstimatedBytes,
            lessThanOrEqualTo(cache.maximumRetainedCandidateBytes),
          );
          expect(
            core.retainedPreparedQueryCandidateCount,
            lessThanOrEqualTo(6),
          );
          expect(
            cache.retainedCandidatePreparedRowCount,
            lessThanOrEqualTo(repository.rows.length * 6),
          );
          expect(
            FluviDiagnosticLogger.retainedEntryCount,
            lessThanOrEqualTo(1000),
          );
          expect(controller.scrollController.position, same(position));
          expect(controller.physicsCreationCount, physics);
          expect(
            tester.widget<CenteredCarousel>(carouselFinder).controller,
            same(controller),
          );
          expect(
            cache.hasCompleteReadablePhaseAFor(
              core.visibleFrames.logBoxLane.value!.logBox,
            ),
            isTrue,
          );
          expect(tester.state(find.byType(CoreDashboard)), same(owner));
        }
        expect(
          observedNonempty,
          containsAll(
            scenario == 'sparse'
                ? [0, 1, 7, 8]
                : List.generate(9, (index) => index),
          ),
        );
        if (scenario == 'sparse') {
          expect(observedEmpty, containsAll([2, 3, 4, 5, 6]));
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final sequenceScenario in ['month', 'monthTimeControl', 'day']) {
    final withTimeControl = sequenceScenario == 'monthTimeControl';
    testWidgets(
      'AVL physical startup sequence 3 2 1 0 8 7 6 scenario=$sequenceScenario',
      (tester) async {
        final session = await _PhysicalAvatarSequence.mount(
          tester,
          timeRailOpen: sequenceScenario == 'day',
        );
        expect(session.logBoxViewportDimension, greaterThan(0));
        expect(
          session.core.budgetAvatarFocusHotsetDiagnostics['pending'],
          greaterThan(0),
          reason: 'The first real pointer must start before broad prewarming.',
        );
        final observed = <int>[];
        final initialTimeIndex =
            session.core.motion.carouselController.selectedLogicalIndex;
        for (final target in [3, 2, 1, 0, 8, 7, 6]) {
          FluviDiagnosticLogger.clear();
          await session.dragAvatarTo(target);
          await session.expectFinalTarget(target);
          observed.add(session.physicalHandle);
          expect(
            session.core.motion.carouselController.selectedLogicalIndex,
            initialTimeIndex,
            reason: 'The startup sequence uses Avatar pointers only.',
          );
        }
        expect(observed, [3, 2, 1, 0, 8, 7, 6]);

        if (withTimeControl) {
          final beforeController = session.carousel.controller;
          final beforePosition = beforeController.scrollController.position;
          final beforePhysics = beforeController.physicsCreationCount;
          final beforeCache = session.cache;
          final beforeVisible = session.core.visibleFrames.value!.queryKey;
          final beforeCanonical = session.core.paging.committedQueryKey;
          final beforeReady = session.cache.hasCompleteReadablePhaseAFor(
            session.core.visibleFrames.logBoxLane.value!.logBox,
          );
          final beforeBroadReady = session.core.budgetAvatarLiveRootReady.value;
          final beforePending = session
              .core
              .budgetAvatarFocusHotsetDiagnostics['pendingCandidate'];
          await session.sameScopeTimeGesture();
          // Time may intentionally reset transient focus. Compare the same
          // complete Avatar outcome before and after the one genuine Time
          // gesture; no result in the first sequence depended on that reset.
          for (final target in [3, 2, 1, 0, 8, 7, 6]) {
            FluviDiagnosticLogger.clear();
            await session.dragAvatarTo(target);
            await session.expectFinalTarget(target);
          }
          expect(session.physicalHandle, 6);
          expect(session.rail.presentation.value.selectedHandle, 6);
          expect(session.core.focus.state?.category?.id, 'avatar-category-6');
          expect(session.core.visibleFrames.value!.queryKey, beforeVisible);
          expect(session.core.paging.committedQueryKey, beforeCanonical);
          expect(
            session.core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'],
            beforePending,
          );
          expect(
            session.core.budgetAvatarLiveRootReady.value,
            beforeBroadReady,
          );
          expect(
            session.cache.hasCompleteReadablePhaseAFor(
              session.core.visibleFrames.logBoxLane.value!.logBox,
            ),
            beforeReady,
          );
          expect(session.core.budgetAvatarTargetPainted.value?.targetHandle, 6);
          expect(session.carousel.controller, same(beforeController));
          expect(
            session.carousel.controller.scrollController.position,
            same(beforePosition),
          );
          expect(
            session.carousel.controller.physicsCreationCount,
            beforePhysics,
          );
          expect(session.cache, same(beforeCache));
        }
        await session.unmount();
      },
    );
  }

  testWidgets(
    'AVL earlier target 1 paints before final physical target 8 exact binder miss',
    (tester) async {
      final session = await _PhysicalAvatarSequence.mount(tester);
      FluviDiagnosticLogger.clear();
      final pointer = await session.startAvatarPointer();
      await session.moveAvatarPointerTo(pointer, 1);
      await session.waitFor(
        () => session.core.budgetAvatarTargetPainted.value?.targetHandle == 1,
        reason:
            'Target 1 must actually paint while the first pointer is still held.',
      );
      expect(session.rail.presentation.value.selectedHandle, 1);
      expect(
        session.cache.hasCompleteReadablePhaseAFor(
          session.core.visibleFrames.logBoxLane.value!.logBox,
        ),
        isTrue,
      );
      final earlierPaint = session.core.budgetAvatarTargetPainted.value!;
      expect(earlierPaint.exactEmpty, isFalse);

      // Cross directly from logical 1 to -1 (category 8) without a display
      // frame between targets. The cold partial hotset is the same genuine
      // startup condition as the existing cold composition test; the cache
      // binder and production resource callback remain attached unchanged.
      await session.moveAvatarPointerTo(pointer, -1, singleMove: true);
      await session.releasePointer(pointer);
      final misses = FluviDiagnosticLogger.entries.where(
        (event) =>
            event.stage == 'AV|LIVE_ROOT_MISS' &&
            event.scope?.contains('targetHandle=8 ') == true,
      );
      expect(
        misses,
        isNotEmpty,
        reason:
            'Final target 8 must hit the real nonempty exact binder.\n${session.trace}',
      );
      expect(misses.last.entryCount, greaterThan(0));
      await session.expectFinalTarget(8);
      expect(
        session.core.budgetAvatarTargetPainted.value!.focusGeneration,
        greaterThan(earlierPaint.focusGeneration),
      );
      await session.unmount();
    },
  );

  testWidgets(
    'AVL retained painted target 1 yields to cold final 8 after real resource replacement',
    (tester) async {
      final session = await _PhysicalAvatarSequence.mount(tester);
      const warmTargets = [
        DashboardFocusFacet(id: 'avatar-category-1', displayName: 'Category 1'),
        DashboardFocusFacet(id: 'avatar-category-2', displayName: 'Category 2'),
      ];
      session.core.primeBudgetAvatarFocusHotset(warmTargets);
      await tester.pump(const Duration(milliseconds: 16));
      session.core.primeBudgetAvatarFocusHotset(warmTargets);
      await session.waitFor(
        () => session.core.budgetAvatarLiveRootReady.value,
        reason:
            'The aggregate and targets 1/2 must naturally finish partial warmup.',
      );
      final controller = session.carousel.controller;
      final position = controller.scrollController.position;
      final cache = session.cache;
      FluviDiagnosticLogger.clear();
      final pointer = await session.startAvatarPointer();
      await session.moveAvatarPointerTo(pointer, 1);
      await session.waitFor(
        () => session.core.budgetAvatarTargetPainted.value?.targetHandle == 1,
        reason: 'The real cache must paint target 1 before the hotset expands.',
      );
      final earlierPaint = session.core.budgetAvatarTargetPainted.value!;
      expect(earlierPaint.exactEmpty, isFalse);
      expect(session.rail.presentation.value.selectedHandle, 1);
      await session.releasePointer(pointer);
      await session.waitFor(
        () =>
            !session.core.diagnostics.isMotionActive &&
            session.core.budgetAvatarTargetPainted.value?.targetHandle == 1 &&
            session.core.navigation.state.parentQueryScope.categoryIds.contains(
              'avatar-category-1',
            ) &&
            session.core.paging.committedQueryKey ==
                session.core.visibleFrames.logBoxLane.value!.logBox.queryKey,
        reason: 'The real painted target 1 must first become canonical.',
      );
      // Control a real resource-identity loss after an actual target-1 paint.
      // The production cache performs the one-payload preparation and atomic
      // lane replacement. No binder, return value or callback is substituted.
      final retainedPayload =
          session.core.visibleFrames.logBoxLane.value!.logBox;
      await cache.prepareLiveInteractionResourceWindow(
        lane: DashboardLiveInteractionResourceLane.budgetAvatarPreview,
        resourceKey: 'avatar-regression-retained-target-1',
        window: DashboardLogBoxSceneWindow(
          identity: 'avatar-regression-retained-target-1',
          payloads: [retainedPayload],
        ),
        surfaceWidth: cache.surfaceWidth,
        devicePixelRatio: tester.view.devicePixelRatio,
      );
      expect(cache.hasCompleteReadablePhaseAFor(retainedPayload), isTrue);
      session.core.primeBudgetAvatarFocusHotset([
        for (final category in session.repository.categories)
          DashboardFocusFacet(id: category.id, displayName: category.name),
      ]);
      expect(session.rail.presentation.targetForHandle(8), isNotNull);
      expect(session.carousel.controller, same(controller));
      expect(
        session.carousel.controller.scrollController.position,
        same(position),
      );
      expect(session.cache, same(cache));
      expect(
        session.core.budgetAvatarFocusHotsetDiagnostics['pending'],
        greaterThan(0),
      );
      final finalPointer = await session.startAvatarPointer();
      session.pointerTime += const Duration(milliseconds: 40);
      await finalPointer.moveBy(
        const Offset(24, 0),
        timeStamp: session.pointerTime,
      );
      await session.moveAvatarPointerTo(finalPointer, -1, singleMove: true);
      await session.releasePointer(finalPointer);
      final misses = FluviDiagnosticLogger.entries.where(
        (event) =>
            event.stage == 'AV|LIVE_ROOT_MISS' &&
            event.scope?.contains('targetHandle=8 ') == true,
      );
      expect(misses, isNotEmpty, reason: session.trace);
      expect(misses.last.entryCount, greaterThan(0));
      await session.expectFinalTarget(8);
      expect(
        session.core.budgetAvatarTargetPainted.value!.focusGeneration,
        greaterThan(earlierPaint.focusGeneration),
      );
      await session.unmount();
    },
  );

  testWidgets(
    'AVL real CoreDashboard correlates accepted target 3 phase-A and Budget fan-out',
    (tester) async {
      final session = await _PhysicalAvatarSequence.mount(tester);
      FluviDiagnosticLogger.clear();

      await session.dragAvatarTo(3);
      await session.expectFinalTarget(3);

      final correlations = FluviDiagnosticLogger.entries.where(
        (event) => event.stage == 'AV|VISIBLE_SEMANTIC_COMMIT_CORRELATED',
      );
      expect(correlations, isNotEmpty, reason: session.trace);
      final correlation = correlations.last;
      expect(_field(correlation.scope!, 'targetHandle'), 3);
      expect(_field(correlation.scope!, 'focusGeneration'), greaterThan(0));
      expect(
        _field(correlation.scope!, 'phaseAPublishMicros'),
        greaterThanOrEqualTo(0),
      );
      expect(
        _field(correlation.scope!, 'phaseBActivationMicros'),
        greaterThanOrEqualTo(0),
      );
      expect(
        _field(correlation.scope!, 'budgetFanoutMicros'),
        greaterThanOrEqualTo(0),
      );
      expect(
        _field(correlation.scope!, 'corePublishToFanoutMicros'),
        greaterThanOrEqualTo(0),
      );
      expect(
        correlation.scope,
        contains('repositoryRequestsAtTick=0 indexBuildsAtTick=0 '),
      );
      expect(correlation.scope, contains('scenePreparesAtTick=0 '));
      expect(
        correlation.scope,
        contains('canonicalPersistenceCommitsAtTick=0'),
      );
      final headerPaint = FluviDiagnosticLogger.entries.lastWhere(
        (event) =>
            event.stage == 'BUDGET_HEADER_PAINTED' &&
            _field(event.scope!, 'targetHandle') == 3,
      );
      expect(
        _field(headerPaint.scope!, 'headerSubtreePaintMicros'),
        greaterThanOrEqualTo(0),
      );
      final progressPaint = FluviDiagnosticLogger.entries.lastWhere(
        (event) =>
            event.stage == 'BUDGET_PROGRESS_PAINTED' &&
            _field(event.scope!, 'targetHandle') == 3,
      );
      expect(
        _field(progressPaint.scope!, 'progressChromePaintMicros'),
        greaterThanOrEqualTo(0),
      );

      await session.unmount();
    },
  );
}

int _field(String scope, String name) =>
    int.parse(RegExp('(?:^| )$name=(-?\\d+)').firstMatch(scope)!.group(1)!);

/// Only orchestrates real pointers and observations in the production widget
/// composition. Existing Core/cache/binder/rail owners remain untouched.
class _PhysicalAvatarSequence {
  _PhysicalAvatarSequence(this.tester, this.repository, this.core, this.owner);

  final WidgetTester tester;
  final AvatarTargetLivenessRepository repository;
  final DashboardCoreController core;
  final State owner;
  Duration pointerTime = Duration.zero;

  static Future<_PhysicalAvatarSequence> mount(
    WidgetTester tester, {
    bool timeRailOpen = false,
  }) async {
    final repository = AvatarTargetLivenessRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
      initialDate: DateTime.utc(2026, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
      initialPlane: TimePlane.month,
      initialRailOpen: timeRailOpen,
    );
    final mode = DashboardCoreModeController(
      initialMode: DashboardModeSpec.budget,
    );
    final categories = ValueNotifier<List<FluviCategory>>(
      repository.categories,
    );
    addTearDown(core.dispose);
    addTearDown(mode.dispose);
    addTearDown(categories.dispose);
    await core.bootstrap();
    core.primeBudgetAvatarFocusHotset(const [
      DashboardFocusFacet(id: 'avatar-category-1', displayName: 'Category 1'),
    ]);
    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: core,
        modeController: mode,
        categoryCollection: categories,
      ),
      // The open day rail and focused-query chips leave a zero-height inner
      // LogBox at 412x892. Keep production geometry unchanged and give this
      // day-paint test a real visible viewport (see retained diagnostic log).
      surfaceSize: timeRailOpen
          ? const Size(412, 1200)
          : dashboardTestSurfaceSize,
    );
    final priorSchedulingStrategy = tester.binding.schedulingStrategy;
    tester.binding.schedulingStrategy =
        ({required priority, required scheduler}) => true;
    addTearDown(
      () => tester.binding.schedulingStrategy = priorSchedulingStrategy,
    );
    return _PhysicalAvatarSequence(
      tester,
      repository,
      core,
      tester.state(find.byType(CoreDashboard)),
    );
  }

  Finder get avatarFinder =>
      find.byKey(const ValueKey('budget-target-avatar-carousel'));
  BudgetTargetAvatarRail get rail => tester.widget<BudgetTargetAvatarRail>(
    find.byType(BudgetTargetAvatarRail),
  );
  CenteredCarousel get carousel =>
      tester.widget<CenteredCarousel>(avatarFinder);
  DashboardLogBoxPreparedSceneCache get cache => tester
      .widget<DashboardLogBoxViewport>(find.byType(DashboardLogBoxViewport))
      .preparedSceneCache!;
  int get physicalHandle =>
      ((carousel.controller.rawCenteredLogicalIndex.round() % 9) + 9) % 9;
  double get logBoxViewportDimension => tester
      .stateList<ScrollableState>(
        find.descendant(
          of: find.byType(DashboardLogBoxViewport),
          matching: find.byType(Scrollable),
        ),
      )
      .singleWhere((state) => state.position.axis == Axis.vertical)
      .position
      .viewportDimension;
  String get trace => FluviDiagnosticLogger.entries
      .where(
        (event) =>
            event.stage.startsWith('AV') || event.stage.contains('FOCUS'),
      )
      .map((event) => '${event.stage} ${event.scope}')
      .join('\n');

  Future<TestGesture> startAvatarPointer() {
    pointerTime += const Duration(milliseconds: 500);
    return tester.startGesture(tester.getCenter(avatarFinder));
  }

  Future<void> moveAvatarPointerTo(
    TestGesture pointer,
    int rawTarget, {
    bool singleMove = false,
  }) async {
    expect(carousel.spec.itemExtent, 58);
    for (var step = 0; step < 64; step++) {
      final remaining = rawTarget - carousel.controller.rawCenteredLogicalIndex;
      if (remaining.abs() < .01) return;
      final distance = -remaining * carousel.spec.itemExtent;
      // Recognize the pointer before yielding a frame for idle prewarming;
      // subsequent samples remain slow physical steps toward the true center.
      final maximumStep = step == 0 && !carousel.controller.isScrolling
          ? 24.0
          : 8.0;
      pointerTime += const Duration(milliseconds: 40);
      await pointer.moveBy(
        Offset(
          singleMove
              ? distance
              : distance.clamp(-maximumStep, maximumStep).toDouble(),
          0,
        ),
        timeStamp: pointerTime,
      );
      if (singleMove) return;
      await tester.pump(const Duration(milliseconds: 40));
    }
    fail(
      'Physical Avatar pointer did not reach raw target $rawTarget: '
      '${carousel.controller.rawCenteredLogicalIndex}.\n$trace',
    );
  }

  Future<void> releasePointer(TestGesture pointer) async {
    // A stationary timestamped sample drains velocity without modifying
    // ScrollPosition or the protected carousel physics.
    pointerTime += const Duration(milliseconds: 400);
    await pointer.moveBy(Offset.zero, timeStamp: pointerTime);
    pointerTime += const Duration(milliseconds: 40);
    await pointer.up(timeStamp: pointerTime);
  }

  Future<void> dragAvatarTo(int handle) async {
    final raw = carousel.controller.rawCenteredLogicalIndex.round();
    final forward = (handle - physicalHandle + 9) % 9;
    final steps = forward > 4 ? forward - 9 : forward;
    final pointer = await startAvatarPointer();
    await moveAvatarPointerTo(pointer, raw + steps);
    await releasePointer(pointer);
  }

  Future<void> waitFor(bool Function() ready, {required String reason}) async {
    for (var frame = 0; frame < 240; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (ready()) return;
    }
    final viewport = tester.widget<DashboardLogBoxViewport>(
      find.byType(DashboardLogBoxViewport),
    );
    final payload = core.visibleFrames.logBoxLane.value!.logBox;
    fail(
      '$reason\nviewportBounds=${viewport.bounds} '
      'physicalHandle=$physicalHandle '
      'selectedHandle=${rail.presentation.value.selectedHandle} '
      'paintedHandle=${core.budgetAvatarTargetPainted.value?.targetHandle} '
      'canonicalQuery=${core.paging.committedQueryKey?.value} '
      'hotsetDiagnostics=${core.budgetAvatarFocusHotsetDiagnostics} '
      'viewportRect=${tester.getRect(find.byType(DashboardLogBoxViewport))} '
      'query=${payload.queryKey.value} '
      'rowCount=${payload.previewRowCount} '
      'exactCacheReady=${cache.hasCompleteReadablePhaseAFor(payload)} '
      'cacheReadableRows=${cache.readablePhaseARowCountFor(payload)} '
      'cacheReport=${cache.report()} '
      'lastRenderExtent=${FluviDiagnosticLogger.entries.where((event) => event.stage == 'VERTICAL_EXTENT_PUBLISHED').lastOrNull?.message}\n$trace',
    );
  }

  Future<void> expectFinalTarget(
    int handle, {
    bool requireSettledEvent = true,
  }) async {
    final category = handle == 0 ? null : 'avatar-category-$handle';
    final expectedIds = <String>{?category};
    await waitFor(
      () =>
          !core.diagnostics.isMotionActive &&
          core.budgetAvatarTargetPainted.value?.targetHandle == handle &&
          core.navigation.state.parentQueryScope.categoryIds.toString() ==
              expectedIds.toString() &&
          core.budgetAvatarFocusHotsetDiagnostics['pendingCandidate'] == 0,
      reason:
          'Final physical target $handle must become exact and canonical without a second gesture.',
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(physicalHandle, handle, reason: trace);
    expect(rail.presentation.value.selectedHandle, handle, reason: trace);
    expect(core.focus.state?.category?.id, category);
    final payload = core.visibleFrames.logBoxLane.value!;
    expect(payload.scope.categoryIds, expectedIds);
    expect(core.paging.committedQueryKey, payload.logBox.queryKey);
    expect(payload.logBox.previewRowCount, handle == 0 ? 8 : 1);
    expect(logBoxViewportDimension, greaterThan(0));
    expect(cache.hasCompleteReadablePhaseAFor(payload.logBox), isTrue);
    expect(
      core.budgetAvatarTargetPainted.value?.queryKey,
      payload.logBox.queryKey.value,
    );
    expect(core.budgetAvatarTargetPainted.value?.exactEmpty, isFalse);
    if (requireSettledEvent) {
      final settles = FluviDiagnosticLogger.entries.where(
        (event) => event.stage == 'AV|FLING_SETTLED',
      );
      expect(settles, isNotEmpty, reason: trace);
      expect(_field(settles.last.scope!, 'settledTargetHandle'), handle);
    }
    for (final stage in ['BUDGET_HEADER_PAINTED', 'BUDGET_PROGRESS_PAINTED']) {
      final paints = FluviDiagnosticLogger.entries.where(
        (event) => event.stage == stage,
      );
      expect(paints, isNotEmpty, reason: '$stage final=$handle');
      expect(_field(paints.last.scope!, 'targetHandle'), handle);
      expect(
        _field(paints.last.scope!, 'displayNumeratorScaled100'),
        rail.presentation.value.liveSelection.displayNumeratorScaled100,
      );
      expect(
        _field(paints.last.scope!, 'displayDenominatorScaled100'),
        rail.presentation.value.liveSelection.displayDenominatorScaled100,
      );
    }
    final requests = FluviDiagnosticLogger.entries.where(
      (event) => event.stage == 'AV|PREVIEW_REQUESTED',
    );
    final terminals = FluviDiagnosticLogger.entries.where(
      (event) => event.stage == 'AV|PREVIEW_TERMINAL',
    );
    expect(terminals.length, requests.length, reason: trace);
    expect(
      terminals.any(
        (event) => event.scope!.contains('explicitInvariantFailure'),
      ),
      isFalse,
    );
    expect(tester.state(find.byType(CoreDashboard)), same(owner));
  }

  Future<void> sameScopeTimeGesture() async {
    final finder = find.byKey(
      const ValueKey('dashboard-summary-shell-transform'),
    );
    final scope = core.visibleFrames.logBoxLane.value!.scope.timeScope;
    pointerTime += const Duration(milliseconds: 500);
    final pointer = await tester.startGesture(tester.getCenter(finder));
    pointerTime += const Duration(milliseconds: 40);
    await pointer.moveBy(const Offset(-24, 0), timeStamp: pointerTime);
    await tester.pump(const Duration(milliseconds: 40));
    pointerTime += const Duration(milliseconds: 40);
    await pointer.moveBy(const Offset(-2, 0), timeStamp: pointerTime);
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      core.isMotionLaneActive(DashboardMotionLane.summaryShell),
      isTrue,
      reason:
          'Negative control must exercise the actual Summary Time recognizer.',
    );
    expect(
      tester.widget<Transform>(finder).transform.getTranslation().x,
      isNot(0),
    );
    pointerTime += const Duration(milliseconds: 80);
    await pointer.moveBy(const Offset(2, 0), timeStamp: pointerTime);
    await releasePointer(pointer);
    await waitFor(
      () => !core.diagnostics.isMotionActive,
      reason: 'The actual same-scope Time gesture must settle.',
    );
    expect(
      core.visibleFrames.logBoxLane.value!.scope.timeScope,
      scope,
      reason: 'The Time control returns within the same semantic month.',
    );
  }

  Future<void> unmount() => tester.pumpWidget(const SizedBox());
}
