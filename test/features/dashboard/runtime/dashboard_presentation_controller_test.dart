import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_presentation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:flutter/material.dart';

import 'dashboard_runtime_test_fixtures.dart';

void main() {
  testWidgets(
    'an interrupted SUM rail close and reopen synchronously recenters the retained year',
    (tester) async {
      final scheduler = _DisplayFrameScheduler();
      final baselineIndices = <int>[];
      final controller = DashboardPresentationController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        displayFrameScheduler: scheduler,
      );
      addTearDown(controller.dispose);
      controller.installIndex(
        buildRuntimeTestIndex(
          revision: 7,
          initialYear: 2025,
          yearWindowRadius: 5,
        ),
        publishImmediately: true,
      );
      controller.setRailOpen(true);
      scheduler.fireFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 96,
            child: TimeRefinementRail(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 378,
                height: 96,
              ),
              motion: controller.motion,
              onMotionBaselineEstablished: baselineIndices.add,
              onMotionStarted: controller.beginRailMotion,
            ),
          ),
        ),
      );
      await tester.pump();

      final catalog = controller.motion.catalog;
      final retained2025 = catalog.logicalIndexForValue(2025);
      final preview2021 = catalog.logicalIndexForValue(2021);
      final carousel = controller.motion.carouselController;
      final scrollController = carousel.scrollController;
      final position = scrollController.position;
      final physics = controller.motion.dashboardPhysics;

      controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      controller.motion.beginBallistic(2200);
      carousel.jumpToIndex(preview2021);
      scheduler.fireFrame();
      await tester.pump();

      expect(controller.navigation.state.retainedChildYear, 2025);
      expect(
        carousel.logicalIndexForPhysical(carousel.rawCenteredIndex.round()),
        preview2021,
      );

      controller.setRailOpen(false);
      scheduler.fireFrame();
      controller.setRailOpen(true);
      scheduler.fireFrame();
      await tester.pump();

      expect(controller.navigation.state.retainedChildYear, 2025);
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('year:2025'),
      );
      expect(controller.motion.state.semanticIndex, retained2025);
      expect(carousel.selectedLogicalIndex, retained2025);
      expect(
        carousel.logicalIndexForPhysical(carousel.rawCenteredIndex.round()),
        retained2025,
      );
      expect(carousel.rawCenteredLogicalIndex.round(), retained2025);
      expect(baselineIndices.last, retained2025);
      expect(baselineIndices, hasLength(greaterThan(1)));
      expect(controller.motion.state.activity.name, 'idle');
      expect(controller.motion.state.velocity, 0);
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(identical(controller.motion.dashboardPhysics, physics), isTrue);

      // A completion from the command interrupted by the structural close is
      // stale: it cannot retain or publish the previewed 2021 child.
      controller.settleRail(preview2021);
      expect(controller.navigation.state.retainedChildYear, 2025);
      expect(controller.motion.state.semanticIndex, retained2025);
    },
  );

  testWidgets(
    'a settled SUM rail child reopens at that canonical retained year',
    (tester) async {
      final scheduler = _DisplayFrameScheduler();
      final controller = DashboardPresentationController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.sum,
        displayFrameScheduler: scheduler,
      );
      addTearDown(controller.dispose);
      controller.installIndex(
        buildRuntimeTestIndex(
          revision: 7,
          initialYear: 2025,
          yearWindowRadius: 5,
        ),
        publishImmediately: true,
      );
      controller.setRailOpen(true);
      scheduler.fireFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 96,
            child: TimeRefinementRail(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 378,
                height: 96,
              ),
              motion: controller.motion,
              onMotionStarted: controller.beginRailMotion,
            ),
          ),
        ),
      );
      await tester.pump();

      final catalog = controller.motion.catalog;
      final settled2021 = catalog.logicalIndexForValue(2021);
      final carousel = controller.motion.carouselController;

      controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      carousel.jumpToIndex(settled2021);
      controller.semanticCrossed(settled2021);
      scheduler.fireFrame();
      controller.settleRail(settled2021);
      scheduler.fireFrame();
      await tester.pump();

      expect(controller.navigation.state.retainedChildYear, 2021);
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('year:2021'),
      );

      controller.setRailOpen(false);
      scheduler.fireFrame();
      controller.setRailOpen(true);
      scheduler.fireFrame();
      await tester.pump();

      expect(controller.navigation.state.retainedChildYear, 2021);
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('year:2021'),
      );
      expect(controller.motion.state.semanticIndex, settled2021);
      expect(carousel.selectedLogicalIndex, settled2021);
      expect(
        carousel.logicalIndexForPhysical(carousel.rawCenteredIndex.round()),
        settled2021,
      );
      expect(carousel.rawCenteredLogicalIndex.round(), settled2021);
    },
  );

  test(
    'bootstrap and every structural target select only the installed index',
    () {
      final scheduler = _DisplayFrameScheduler();
      final commits = <DashboardVisibleFrame>[];
      final controller = DashboardPresentationController(
        initialDate: DateTime(2026, 7, 14),
        displayFrameScheduler: scheduler,
        onCommittedFrame: commits.add,
      );
      addTearDown(controller.dispose);
      final index = buildRuntimeTestIndex(revision: 7);

      final initial = controller.installIndex(index, publishImmediately: true);
      expect(initial.queryKey.value, contains('month:2026-07'));
      expect(initial.coreRevision, 7);

      controller.setRailOpen(true);
      scheduler.fireFrame();
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('day:2026-07-14'),
      );

      controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
      scheduler.fireFrame();
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('day:2026-08-14'),
      );

      controller.selectDirection(LedgerDirection.expense);
      scheduler.fireFrame();
      expect(
        controller.visibleFrames.value?.queryKey.value,
        startsWith('expense|'),
      );

      controller.navigatePlane(finer: false);
      scheduler.fireFrame();
      expect(controller.navigation.state.plane, TimePlane.year);
      expect(
        controller.visibleFrames.value?.queryKey.value,
        contains('month:2026-08'),
      );
      expect(commits, isNotEmpty);
    },
  );

  test('crossing publishes prepared values and settle is a visual no-op', () {
    final scheduler = _DisplayFrameScheduler();
    final motionStates = <bool>[];
    final commits = <DashboardVisibleFrame>[];
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      displayFrameScheduler: scheduler,
      onMotionActiveChanged: motionStates.add,
      onCommittedFrame: commits.add,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );
    controller.setRailOpen(true);
    scheduler.fireFrame();

    controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
    controller.semanticCrossed(18);
    scheduler.fireFrame();
    final preview = controller.visibleFrames.value!;
    final publishes = controller.visibleFrames.visiblePublishCount;
    final committedCallbacks = commits.length;
    expect(preview.queryKey.value, contains('day:2026-07-19'));
    expect(preview.mode, DashboardVisibleMode.preview);

    controller.settleRail(18);

    expect(controller.visibleFrames.visiblePublishCount, publishes);
    expect(
      controller.visibleFrames.value?.preparedFrame,
      same(preview.preparedFrame),
    );
    expect(
      controller.visibleFrames.value?.mode,
      DashboardVisibleMode.committed,
    );
    expect(controller.committedState.committedQueryKey, preview.queryKey);
    expect(commits.length, committedCallbacks + 1);
    expect(motionStates, <bool>[true, false]);
  });

  test(
    'separate display frames expose intermediate values on the first fling',
    () {
      final scheduler = _DisplayFrameScheduler();
      final controller = DashboardPresentationController(
        initialDate: DateTime(2026, 7, 14),
        displayFrameScheduler: scheduler,
      );
      addTearDown(controller.dispose);
      controller.installIndex(
        buildRuntimeTestIndex(revision: 7),
        publishImmediately: true,
      );
      controller.setRailOpen(true);
      scheduler.fireFrame();
      controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      final visibleKeys = <String>[];
      controller.visibleFrames.addListener(
        () => visibleKeys.add(controller.visibleFrames.value!.queryKey.value),
      );

      for (final index in <int>[14, 15, 16, 17, 18]) {
        controller.semanticCrossed(index);
        scheduler.fireFrame();
      }

      expect(visibleKeys, hasLength(5));
      expect(visibleKeys.first, contains('day:2026-07-15'));
      expect(visibleKeys.last, contains('day:2026-07-19'));
    },
  );

  test(
    'revision index replacement keeps motion/controller/physics identity',
    () {
      final scheduler = _DisplayFrameScheduler();
      final controller = DashboardPresentationController(
        initialDate: DateTime(2026, 7, 14),
        displayFrameScheduler: scheduler,
      );
      addTearDown(controller.dispose);
      controller.installIndex(
        buildRuntimeTestIndex(revision: 7),
        publishImmediately: true,
      );
      final motion = controller.motion;
      final carousel = motion.carouselController;
      final scrollController = carousel.scrollController;
      final physics = motion.dashboardPhysics;

      controller.installIndex(
        buildRuntimeTestIndex(revision: 8, generation: 2),
        publishImmediately: true,
      );

      expect(identical(controller.motion, motion), isTrue);
      expect(identical(motion.carouselController, carousel), isTrue);
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(motion.dashboardPhysics, physics), isTrue);
      expect(controller.visibleFrames.value?.coreRevision, 8);
    },
  );

  test(
    'open-rail parent changes publish the deterministically retained child',
    () {
      final julyScheduler = _DisplayFrameScheduler();
      final july = DashboardPresentationController(
        initialDate: DateTime(2026, 7, 31),
        displayFrameScheduler: julyScheduler,
      );
      addTearDown(july.dispose);
      july.installIndex(
        buildRuntimeTestIndex(revision: 7),
        publishImmediately: true,
      );
      july.setRailOpen(true);
      julyScheduler.fireFrame();

      july.navigateParent(DashboardTimeNavigationChangeDirection.backward);
      julyScheduler.fireFrame();
      expect(
        july.visibleFrames.value?.queryKey.value,
        contains('day:2026-06-30'),
      );
      expect(july.visibleFrames.value?.queryKey, july.expectedVisibleQueryKey);

      final juneScheduler = _DisplayFrameScheduler();
      final june = DashboardPresentationController(
        initialDate: DateTime(2026, 6, 30),
        displayFrameScheduler: juneScheduler,
      );
      addTearDown(june.dispose);
      june.installIndex(
        buildRuntimeTestIndex(revision: 7),
        publishImmediately: true,
      );
      june.setRailOpen(true);
      juneScheduler.fireFrame();
      june.navigateParent(DashboardTimeNavigationChangeDirection.forward);
      juneScheduler.fireFrame();
      expect(
        june.visibleFrames.value?.queryKey.value,
        contains('day:2026-07-30'),
      );
      expect(june.visibleFrames.value?.queryKey, june.expectedVisibleQueryKey);
    },
  );

  test('year parent and rapid A-B-C changes retain the exact child key', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2025, 5, 14),
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );
    controller.navigatePlane(finer: false);
    scheduler.fireFrame();
    controller.setRailOpen(true);
    scheduler.fireFrame();

    controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    scheduler.fireFrame();
    expect(
      controller.visibleFrames.value?.queryKey.value,
      contains('month:2026-05'),
    );

    controller.navigateParent(DashboardTimeNavigationChangeDirection.backward);
    controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    controller.navigateParent(DashboardTimeNavigationChangeDirection.backward);
    scheduler.fireFrame();
    expect(
      controller.visibleFrames.value?.queryKey.value,
      contains('month:2025-05'),
    );
    expect(
      controller.visibleFrames.value?.queryKey,
      controller.expectedVisibleQueryKey,
    );
  });

  test('Year 2024 then 2026 switches to Month 2026 in one atomic frame', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 7,
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7, yearWindowRadius: 2),
      publishImmediately: true,
    );
    controller.navigatePlane(finer: false);
    scheduler.fireFrame();
    expect(controller.navigation.state.plane, TimePlane.year);

    controller.navigateParent(DashboardTimeNavigationChangeDirection.backward);
    controller.navigateParent(DashboardTimeNavigationChangeDirection.backward);
    expect(controller.navigation.temporalAnchor.visibleYear, 2024);
    controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    expect(controller.navigation.temporalAnchor.visibleYear, 2026);
    final publishCount = controller.visibleFrames.visiblePublishCount;

    controller.navigatePlane(finer: true);
    scheduler.fireFrame();

    expect(controller.navigation.state.plane, TimePlane.month);
    expect(
      controller.navigation.state.parentQueryKey.value,
      contains('month:2026-07'),
    );
    expect(
      controller.visibleFrames.value?.queryKey.value,
      contains('month:2026-07'),
    );
    expect(
      controller.visibleFrames.value?.queryKey,
      controller.expectedVisibleQueryKey,
    );
    expect(controller.visibleFrames.visiblePublishCount, publishCount + 1);
  });

  test('Month to Year to Month roundtrip retains the canonical July', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 7,
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );

    controller.navigatePlane(finer: false);
    scheduler.fireFrame();
    expect(controller.navigation.state.plane, TimePlane.year);
    expect(controller.navigation.state.retainedChildMonth, 7);
    expect(
      controller.navigation.state.parentQueryKey.value,
      contains('year:2026'),
    );

    controller.navigatePlane(finer: true);
    scheduler.fireFrame();

    expect(controller.navigation.state.plane, TimePlane.month);
    expect(
      controller.navigation.state.parentQueryKey.value,
      contains('month:2026-07'),
    );
    expect(controller.navigation.temporalAnchor.visibleMonth, 7);
    expect(
      controller.visibleFrames.value?.queryKey,
      controller.expectedVisibleQueryKey,
    );
  });

  test('bounded index rejects an out-of-window parent in RAM', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2027, 12, 14),
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );
    controller.setRailOpen(true);
    scheduler.fireFrame();
    final before = controller.visibleFrames.value;
    final beforeParent = controller.navigation.state.parentQueryKey;

    expect(
      controller.parentCandidate(
        DashboardTimeNavigationChangeDirection.forward,
      ),
      isNull,
    );
    controller.navigateParent(DashboardTimeNavigationChangeDirection.forward);
    scheduler.fireFrame();

    expect(controller.navigation.state.parentQueryKey, beforeParent);
    expect(controller.visibleFrames.value, same(before));
    expect(controller.expectedVisibleQueryKey, before?.queryKey);
  });

  test('direction replacement rejects an unflushed old-direction preview', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );
    controller.setRailOpen(true);
    scheduler.fireFrame();
    controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
    controller.semanticCrossed(20);

    controller.selectDirection(LedgerDirection.expense);
    scheduler.fireFrame();

    final visible = controller.visibleFrames.value!;
    expect(visible.queryKey.value, startsWith('expense|'));
    expect(visible.queryKey, controller.expectedVisibleQueryKey);
    expect(visible.amount.queryKey, visible.count.queryKey);
    expect(visible.count.queryKey, visible.logBox.queryKey);
  });

  test('seeded random navigation preserves visible index invariants', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7),
      publishImmediately: true,
    );
    final random = Random(0xF1_0A_1);

    for (var operation = 0; operation < 500; operation += 1) {
      switch (random.nextInt(5)) {
        case 0:
          controller.setRailOpen(!controller.navigation.state.isRailOpen);
        case 1:
          controller.navigatePlane(finer: random.nextBool());
        case 2:
          final state = controller.navigation.state;
          if (state.plane != TimePlane.sum) {
            final currentYear = state.plane == TimePlane.year
                ? state.yearCursor
                : state.monthCursor.year;
            final direction = currentYear <= 2025
                ? DashboardTimeNavigationChangeDirection.forward
                : currentYear >= 2027
                ? DashboardTimeNavigationChangeDirection.backward
                : random.nextBool()
                ? DashboardTimeNavigationChangeDirection.forward
                : DashboardTimeNavigationChangeDirection.backward;
            controller.navigateParent(direction);
          }
        case 3:
          controller.selectDirection(
            random.nextBool()
                ? LedgerDirection.income
                : LedgerDirection.expense,
          );
        case 4:
          if (controller.navigation.state.isRailOpen) {
            final catalog = controller.motion.catalog;
            final target = random.nextInt(catalog.length);
            controller.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
            controller.semanticCrossed(target);
            scheduler.fireFrame();
            controller.settleRail(target);
          }
      }
      scheduler.fireFrame();
      final visible = controller.visibleFrames.value!;
      expect(visible.queryKey, controller.expectedVisibleQueryKey);
      expect(visible.coreRevision, controller.index?.coreRevision);
      expect(visible.amount.queryKey, visible.queryKey);
      expect(visible.count.queryKey, visible.queryKey);
      expect(visible.logBox.queryKey, visible.queryKey);
      expect(visible.amount.coreRevision, visible.coreRevision);
      expect(visible.count.coreRevision, visible.coreRevision);
      expect(visible.logBox.revision, visible.coreRevision);
    }
  });
}

final class _DisplayFrameScheduler implements DashboardDisplayFrameScheduler {
  final List<void Function()> _callbacks = [];

  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(void Function() callback) => _callbacks.add(callback);

  void fireFrame() {
    currentFrameNumber += 1;
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}
