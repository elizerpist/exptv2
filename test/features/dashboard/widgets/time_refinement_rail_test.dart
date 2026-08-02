import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
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
}
