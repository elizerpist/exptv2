import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/summary_text_content.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_temporal_component_carousel.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_segmented_target_acceptance.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  test('coordinator transfers ownership and detach removes stale surfaces', () {
    final coordinator = DashboardTemporalCarouselCoordinator();
    final a = Object(), b = Object();
    var first = 0, second = 0;
    coordinator.attach(a, () => first++);
    coordinator.attach(b, () => second++);
    coordinator.claim(a);
    expect(first, 0);
    expect(second, 1);
    coordinator.claim(b);
    expect(first, 1);
    expect(second, 1);
    coordinator.detach(a);
    coordinator.preemptAll();
    expect(first, 1);
    expect(second, 2);
  });

  test(
    'visual frames are generation guarded and never navigate by themselves',
    () {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
      );
      final coordinator = DashboardTemporalCarouselCoordinator();
      addTearDown(navigation.dispose);
      addTearDown(coordinator.dispose);
      final a = Object(), b = Object();
      final origin = navigation.state;
      coordinator.claim(a);
      final first = coordinator.noteMotionStarted();
      coordinator.publishDayMotion(
        a,
        DashboardTemporalDayVisualMotion(
          origin: origin,
          rawIndex: .25,
          isMoving: true,
          source: DashboardTemporalMotionSource.balanceRhythm,
          generation: first,
        ),
      );
      expect(coordinator.dayVisualMotion!.rawIndex, .25);
      expect(navigation.state, same(origin));
      coordinator.claim(b);
      final second = coordinator.noteMotionStarted();
      coordinator.publishDayMotion(
        b,
        DashboardTemporalDayVisualMotion(
          origin: origin,
          rawIndex: -.75,
          isMoving: true,
          source: DashboardTemporalMotionSource.summaryPill,
          generation: second,
        ),
      );
      final latest = coordinator.dayVisualMotion;
      coordinator.publishDayMotion(
        a,
        DashboardTemporalDayVisualMotion(
          origin: origin,
          rawIndex: 5,
          isMoving: true,
          source: DashboardTemporalMotionSource.balanceRhythm,
          generation: first,
        ),
      );
      coordinator.finishDayMotion(
        a,
        first,
        acceptedTarget: origin,
        acceptedOffset: 5,
      );
      expect(coordinator.dayVisualMotion, same(latest));
      expect(coordinator.activeOwner, same(b));
      expect(navigation.state, same(origin));
    },
  );

  testWidgets(
    'deferred rich publication does not delay passive visual motion or invent a canonical day',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final coordinator = DashboardTemporalCarouselCoordinator();
      addTearDown(navigation.dispose);
      addTearDown(coordinator.dispose);
      var pending = navigation.state;
      var crossings = 0;
      Widget track(bool rail) => SizedBox(
        width: 300,
        height: 59,
        child: DashboardTemporalComponentCarousel(
          key: ValueKey(rail ? 'deferred-rail' : 'deferred-summary'),
          height: 59,
          itemExtent: 59,
          visualContentOffset: 0,
          navigation: navigation,
          semanticsLabel: rail ? 'rail' : 'summary',
          coordinator: coordinator,
          motionSource: rail
              ? DashboardTemporalMotionSource.balanceRhythm
              : DashboardTemporalMotionSource.summaryPill,
          scrollDirection: rail ? Axis.horizontal : Axis.vertical,
          presentation: SummaryTemporalFlingPresentation.dynamicTrio,
          component: DashboardTemporalAnchorComponent.day,
          candidateForOffset: (origin, offset) =>
              navigation.temporalComponentOffsetCandidate(
                plane: origin.plane,
                isRailOpen: origin.isRailOpen,
                component: DashboardTemporalAnchorComponent.day,
                offset: offset,
                base: origin,
              ),
          labelForCandidate: (candidate) => '${candidate.dayCursor}',
          onCrossed: (candidate) {
            crossings++;
            pending = candidate;
            return DashboardSegmentedTargetAcceptance
                .acceptedDeferredForPainterResource;
          },
          visualBuilder: rail
              ? (context, state) => const SizedBox.expand()
              : null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [track(false), track(true)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('deferred-rail'));
      final summary = find.byKey(const ValueKey('deferred-summary'));
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      final moving = tester
          .state<DashboardTemporalComponentCarouselState>(summary)
          .visualState;
      expect(moving.isFollowing, isTrue);
      expect(moving.rawIndex, greaterThan(1));
      expect(navigation.state.dayCursor, 14);
      expect(pending.dayCursor, 15);
      expect(
        find.descendant(of: summary, matching: find.text('15')),
        findsOneWidget,
      );
      expect(crossings, 1);
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigation.state.dayCursor, 14);
      expect(
        tester
            .state<DashboardTemporalComponentCarouselState>(summary)
            .visualState
            .rawIndex,
        1,
      );
      navigation.commitTemporalCandidate(pending);
      await tester.pump();
      final installed = tester
          .state<DashboardTemporalComponentCarouselState>(summary)
          .visualState;
      expect(installed.origin.dayCursor, 15);
      expect(installed.rawIndex, 0);
      expect(crossings, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'rejected final day releases both visual surfaces back to canonical state',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      final coordinator = DashboardTemporalCarouselCoordinator();
      addTearDown(navigation.dispose);
      addTearDown(coordinator.dispose);
      var pending = navigation.state;
      var crossings = 0;
      Widget track(bool rail) => SizedBox(
        width: 300,
        height: 59,
        child: DashboardTemporalComponentCarousel(
          key: ValueKey(rail ? 'deferred-rail' : 'deferred-summary'),
          height: 59,
          itemExtent: 59,
          visualContentOffset: 0,
          navigation: navigation,
          semanticsLabel: rail ? 'rail' : 'summary',
          coordinator: coordinator,
          motionSource: rail
              ? DashboardTemporalMotionSource.balanceRhythm
              : DashboardTemporalMotionSource.summaryPill,
          scrollDirection: rail ? Axis.horizontal : Axis.vertical,
          presentation: SummaryTemporalFlingPresentation.dynamicTrio,
          component: DashboardTemporalAnchorComponent.day,
          candidateForOffset: (origin, offset) =>
              navigation.temporalComponentOffsetCandidate(
                plane: origin.plane,
                isRailOpen: origin.isRailOpen,
                component: DashboardTemporalAnchorComponent.day,
                offset: offset,
                base: origin,
              ),
          labelForCandidate: (candidate) => '${candidate.dayCursor}',
          onCrossed: (candidate) {
            crossings++;
            pending = candidate;
            return DashboardSegmentedTargetAcceptance.rejectedNotPrepared;
          },
          visualBuilder: rail
              ? (context, state) => const SizedBox.expand()
              : null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [track(false), track(true)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('deferred-rail'));
      final summary = find.byKey(const ValueKey('deferred-summary'));
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      final moving = tester
          .state<DashboardTemporalComponentCarouselState>(summary)
          .visualState;
      expect(moving.isFollowing, isTrue);
      expect(moving.rawIndex, greaterThan(1));
      expect(navigation.state.dayCursor, 14);
      expect(pending.dayCursor, 15);
      expect(
        find.descendant(of: summary, matching: find.text('15')),
        findsOneWidget,
      );
      expect(crossings, 1);
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigation.state.dayCursor, 14);
      for (final surface in [summary, rail]) {
        final installed = tester
            .state<DashboardTemporalComponentCarouselState>(surface)
            .visualState;
        expect(installed.origin.dayCursor, 14);
        expect(installed.rawIndex, 0);
        expect(installed.isMoving, isFalse);
      }
      expect(crossings, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'horizontal shared adapter uses fractional physical motion and exact acceptance',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 15),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(navigation.dispose);
      var raw = 0.0, crossings = 0, settles = 0;
      var candidateCalls = 0;
      final coordinator = DashboardTemporalCarouselCoordinator();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 100,
              child: DashboardTemporalComponentCarousel(
                key: const ValueKey('rail'),
                coordinator: coordinator,
                height: 100,
                visualContentOffset: 0,
                navigation: navigation,
                semanticsLabel: 'day rail',
                component: DashboardTemporalAnchorComponent.day,
                presentation: SummaryTemporalFlingPresentation.dynamicTrio,
                scrollDirection: Axis.horizontal,
                itemExtent: 10,
                visibleItemCount: 61,
                candidateForOffset: (origin, offset) {
                  candidateCalls++;
                  return navigation.temporalComponentOffsetCandidate(
                    plane: TimePlane.month,
                    isRailOpen: true,
                    component: DashboardTemporalAnchorComponent.day,
                    offset: offset,
                    base: origin,
                  );
                },
                labelForCandidate: (candidate) => '${candidate.dayCursor}',
                onCrossed: (candidate) {
                  crossings++;
                  return DashboardSegmentedTargetAcceptance.acceptedExact;
                },
                onSettled: (_) => settles++,
                visualBuilder: (context, state) {
                  raw = state.rawIndex;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        candidateCalls,
        0,
        reason: 'Invisible carousel cells must not project temporal candidates',
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('rail'))),
      );
      await gesture.moveBy(const Offset(-35, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-24, 0));
      await tester.pump();
      expect(raw, greaterThan(0));
      expect(raw % 1, isNot(0));
      expect(crossings, greaterThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(settles, 1);
      settles = 0;
      await tester.fling(
        find.byKey(const ValueKey('rail')),
        const Offset(-120, 0),
        1800,
      );
      await tester.pump(const Duration(milliseconds: 16));
      coordinator.preemptAll();
      await tester.pumpAndSettle();
      expect(
        settles,
        0,
        reason: 'A superseded flight cannot emit a stale idle settlement',
      );
    },
  );

  testWidgets(
    'raw vertical contact preempts sibling without taking vertical navigation',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 15),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
      );
      addTearDown(navigation.dispose);
      final coordinator = DashboardTemporalCarouselCoordinator();
      var interrupted = 0, crossings = 0, vertical = 0;
      coordinator.attach(Object(), () => interrupted++);
      await tester.pumpWidget(
        MaterialApp(
          home: GestureDetector(
            onVerticalDragUpdate: (_) => vertical++,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 100,
                child: DashboardTemporalComponentCarousel(
                  key: const ValueKey('rail'),
                  height: 100,
                  visualContentOffset: 0,
                  navigation: navigation,
                  semanticsLabel: 'day rail',
                  component: DashboardTemporalAnchorComponent.day,
                  presentation: SummaryTemporalFlingPresentation.dynamicTrio,
                  scrollDirection: Axis.horizontal,
                  itemExtent: 10,
                  visibleItemCount: 61,
                  coordinator: coordinator,
                  candidateForOffset: (origin, offset) =>
                      navigation.temporalComponentOffsetCandidate(
                        plane: TimePlane.month,
                        isRailOpen: true,
                        component: DashboardTemporalAnchorComponent.day,
                        offset: offset,
                        base: origin,
                      ),
                  labelForCandidate: (candidate) => '${candidate.dayCursor}',
                  onCrossed: (candidate) {
                    crossings++;
                    return DashboardSegmentedTargetAcceptance.acceptedExact;
                  },
                  visualBuilder: (context, state) => const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('rail')),
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      expect(interrupted, 1);
      expect(crossings, 0);
      expect(vertical, greaterThan(0));
    },
  );
  testWidgets(
    'legacy Summary old pointer cannot commit after another temporal surface preempts it',
    (tester) async {
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 15),
      );
      final visible = DashboardVisibleFrameStore();
      final motion = SummaryNavigationMotionController();
      final coordinator = DashboardTemporalCarouselCoordinator();
      addTearDown(navigation.dispose);
      addTearDown(visible.dispose);
      addTearDown(motion.dispose);
      var moves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: DashboardSummaryPill(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 378,
                height: 59,
              ),
              navigation: navigation,
              visibleFrames: visible,
              navigationMotionController: motion,
              temporalCarouselCoordinator: coordinator,
              horizontalCandidateBuilder: (_) =>
                  const SummaryTextContent(title: 'Havi', subtitle: 'Július'),
              onToggleRail: () {},
              onMoveFiner: () {},
              onMoveBroader: () {},
              onMovePrevious: () => moves++,
              onMoveNext: () => moves++,
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DashboardSummaryPill)),
      );
      await gesture.moveBy(const Offset(-45, 0));
      await tester.pump();
      coordinator.preemptAll();
      await gesture.moveBy(const Offset(-45, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(moves, 0);
      await tester.drag(
        find.byType(DashboardSummaryPill),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();
      expect(moves, 1);
    },
  );
}
