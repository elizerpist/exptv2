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
      carousel.onPreviewChanged!(selected + 1);
      carousel.onPreviewChanged!(selected + 1);
      carousel.onPreviewChanged!(selected + 2);
      await tester.pump();

      expect(ticks, [(selected, selected + 1), (selected + 1, selected + 2)]);
      expect(motion.railTick, SummaryRailTick(selected + 1, selected + 2));
      expect(motion.stagedText.phase, SummaryStagedTextPhase.idle);
      expect(navigation.state.previewChild, selected + 3);
      expect(navigation.state.effectiveScope, navigation.state.childScope);
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
            body: TimeRefinementRail(
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
      );
      await tester.pump();

      final carousel = tester.widget<CenteredCarousel<int>>(
        find.byKey(const ValueKey('dashboard-time-rail')),
      );
      final selected = navigation.selectedChildLogicalIndex;
      carousel.onPreviewChanged!(selected + 1);
      expect(motion.railTick, SummaryRailTick(selected, selected + 1));

      navigation.moveParentPrevious();
      await tester.pump();
      expect(navigation.selectedChildLogicalIndex, selected);

      carousel.onPreviewChanged!(selected + 1);
      expect(motion.railTick, SummaryRailTick(selected, selected + 1));
    },
  );
}
