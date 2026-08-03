import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 72);

void main() {
  testWidgets(
    'closed rail mount keeps the canonical child inert until a user gesture',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      addTearDown(navigation.dispose);
      var visualPreviewCount = 0;
      navigation.addListener(() {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRefinementRail(
              bounds: _bounds,
              controller: navigation,
              onPreviewLogicalIndexChanged: (_, _) => visualPreviewCount += 1,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(navigation.state.isRailOpen, isFalse);
      expect(navigation.state.navigationRevision, 0);
      expect(navigation.state.settledChildDay, 14);
      expect(navigation.state.previewChild, isNull);
      expect(navigation.timeCarousel.selectedIndex, 13);
      expect(visualPreviewCount, 0);
    },
  );

  testWidgets(
    'open rail establishes its canonical baseline without autonomous child navigation',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      addTearDown(navigation.dispose);
      navigation.setRailOpen(true);
      final revisionAfterOpening = navigation.state.navigationRevision;
      var visualPreviewCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRefinementRail(
              bounds: _bounds,
              controller: navigation,
              onPreviewLogicalIndexChanged: (_, _) => visualPreviewCount += 1,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(navigation.state.navigationRevision, revisionAfterOpening);
      expect(navigation.state.settledChildDay, 14);
      expect(navigation.state.previewChild, isNull);
      expect(navigation.selectedChildLogicalIndex, 13);
      expect(
        navigation.timeCarousel.selectedPhysicalIndex,
        CenteredCarouselController.virtualAnchorIndex + 13,
      );
      expect(visualPreviewCount, 0);
      expect(navigation.timeCarousel.scrollController.positions, hasLength(1));
      final attachments = navigation.timeCarousel.motionTrace.events
          .where(
            (event) => event.kind == RailMotionEventKind.controllerAttached,
          )
          .toList();
      expect(attachments, hasLength(1));
      expect(
        attachments.single.physicalIndex,
        CenteredCarouselController.virtualAnchorIndex + 13,
      );
      expect(attachments.single.valueB, 1);
      expect(
        navigation.timeCarousel.motionTrace.events.where(
          (event) => event.kind == RailMotionEventKind.ballisticStarted,
        ),
        isEmpty,
      );
      expect(
        navigation.timeCarousel.motionTrace.events.where(
          (event) =>
              event.kind == RailMotionEventKind.programmaticMotionRequested,
        ),
        isEmpty,
      );
      expect(
        navigation.timeCarousel.motionTrace.events.where(
          (event) => event.kind == RailMotionEventKind.semanticSettle,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'a second fling keeps the latest rail target instead of collapsing to one item',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      addTearDown(navigation.dispose);
      navigation.setRailOpen(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRefinementRail(bounds: _bounds, controller: navigation),
          ),
        ),
      );
      await tester.pump();

      final initialIndex = navigation.timeCarousel.selectedIndex;
      await tester.fling(find.byType(ListView), const Offset(-360, 0), 2200);
      await tester.pump(const Duration(milliseconds: 45));
      await tester.fling(find.byType(ListView), const Offset(-360, 0), 2200);
      await tester.pumpAndSettle();

      expect(
        navigation.timeCarousel.selectedIndex,
        greaterThan(initialIndex + 1),
      );
      expect(
        navigation.state.settledChild,
        navigation.timeCarousel.selectedIndex + 1,
      );
      expect(navigation.state.previewChild, isNull);
      final finalEpoch = navigation.timeCarousel.motion.epoch;
      expect(finalEpoch, greaterThan(0));
      expect(
        navigation.timeCarousel.motionTrace.events
            .where(
              (event) =>
                  event.kind == RailMotionEventKind.semanticSettle &&
                  event.epoch == finalEpoch,
            )
            .length,
        1,
      );
      expect(
        navigation.timeCarousel.motionTrace.events
            .where(
              (event) =>
                  event.kind ==
                      RailMotionEventKind.programmaticMotionRequested &&
                  event.epoch == finalEpoch,
            )
            .length,
        0,
      );
    },
  );

  testWidgets(
    'one controller and position survive one hundred preview-driven rebuilds',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      addTearDown(navigation.dispose);
      navigation.setRailOpen(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: navigation,
              builder: (context, _) =>
                  TimeRefinementRail(bounds: _bounds, controller: navigation),
            ),
          ),
        ),
      );
      await tester.pump();
      final carouselController = navigation.timeCarousel.scrollController;
      final position = carouselController.position;
      final physics = tester.widget<ListView>(find.byType(ListView)).physics;

      for (var index = 0; index < 100; index += 1) {
        navigation.previewChildLogicalIndex(index % 31);
      }
      await tester.pump();

      expect(
        identical(navigation.timeCarousel.scrollController, carouselController),
        isTrue,
      );
      expect(
        identical(navigation.timeCarousel.scrollController.position, position),
        isTrue,
      );
      expect(navigation.timeCarousel.scrollController.positions, hasLength(1));
      expect(
        tester.widget<ListView>(find.byType(ListView)).physics,
        same(physics),
      );
    },
  );

  testWidgets(
    'nearest child previews emit visual ticks without changing query semantics',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      addTearDown(navigation.dispose);
      navigation.setRailOpen(true);
      final ticks = <(int, int)>[];
      final motion = SummaryNavigationMotionController();
      addTearDown(motion.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeRefinementRail(
              bounds: _bounds,
              controller: navigation,
              onPreviewLogicalIndexChanged: (oldIndex, newIndex) {
                ticks.add((oldIndex, newIndex));
                motion.triggerRailTick(
                  oldLogicalIndex: oldIndex,
                  newLogicalIndex: newIndex,
                );
              },
              onMotionBaselineEstablished: motion.resetRailTickBaseline,
            ),
          ),
        ),
      );
      await tester.pump();

      final carousel = tester.widget<CenteredCarousel<int>>(
        find.byKey(const ValueKey('dashboard-time-rail')),
      );
      final selected = navigation.selectedChildLogicalIndex;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      carousel.onPreviewChanged!(selected + 1);
      carousel.onPreviewChanged!(selected + 1);
      carousel.onPreviewChanged!(selected + 2);
      await tester.pump();

      expect(ticks, [(selected, selected + 1), (selected + 1, selected + 2)]);
      expect(motion.railTick, SummaryRailTick(selected + 1, selected + 2));
      expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
      expect(navigation.state.previewChild, selected + 3);
      expect(navigation.state.effectiveScope, navigation.state.childScope);
      await gesture.cancel();
    },
  );

  testWidgets(
    'a reconfigured rail resets motion dedupe before the next visible tick',
    (tester) async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final motion = SummaryNavigationMotionController();
      addTearDown(navigation.dispose);
      addTearDown(motion.dispose);
      navigation.setRailOpen(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: navigation,
              builder: (context, _) => TimeRefinementRail(
                bounds: _bounds,
                controller: navigation,
                onPreviewLogicalIndexChanged: (oldIndex, newIndex) {
                  motion.triggerRailTick(
                    oldLogicalIndex: oldIndex,
                    newLogicalIndex: newIndex,
                  );
                },
                onMotionBaselineEstablished: motion.resetRailTickBaseline,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final carousel = tester.widget<CenteredCarousel<int>>(
        find.byKey(const ValueKey('dashboard-time-rail')),
      );
      final selected = navigation.selectedChildLogicalIndex;
      final firstGesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      carousel.onPreviewChanged!(selected + 1);
      await tester.pump();
      expect(motion.railTick, SummaryRailTick(selected, selected + 1));
      await firstGesture.cancel();

      final reconfiguredSelected = navigation.selectedChildLogicalIndex;

      navigation.moveParentPrevious();
      await tester.pump();
      expect(navigation.selectedChildLogicalIndex, reconfiguredSelected);

      final secondGesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      carousel.onPreviewChanged!(reconfiguredSelected + 1);
      await tester.pump();
      expect(motion.railTick?.oldLogicalIndex, reconfiguredSelected);
      expect(motion.railTick?.newLogicalIndex, reconfiguredSelected + 1);
      await secondGesture.cancel();
    },
  );
}
