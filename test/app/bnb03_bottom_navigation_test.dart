import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/shell/bnb03_bottom_navigation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shell_presentation.dart';

void main() {
  const size = Size(428, 75);

  Bnb03BottomNavigationContour contour(DashboardBottomNavEdgeShape shape) =>
      Bnb03BottomNavigationContour(
        edgeShape: shape,
        fabCenterX: 214,
        fabCenterY: 24,
        fabRadius: 48,
        cornerRadius: 32,
      );

  test('straight outer contour reaches both screen-edge top corners', () {
    final rounded = contour(
      DashboardBottomNavEdgeShape.rounded,
    ).physicalPath(size);
    final straight = contour(
      DashboardBottomNavEdgeShape.straight,
    ).physicalPath(size);

    expect(straight.contains(const Offset(0, .25)), isTrue);
    expect(straight.contains(const Offset(427.75, .25)), isTrue);
    expect(rounded.contains(const Offset(0, .25)), isFalse);
    expect(rounded.contains(const Offset(427.75, .25)), isFalse);
  });

  test('outer shape changes preserve the center FAB contour geometry', () {
    final rounded = contour(
      DashboardBottomNavEdgeShape.rounded,
    ).topContour(size);
    final straight = contour(
      DashboardBottomNavEdgeShape.straight,
    ).topContour(size);

    // Both paths use the same FAB-derived arc. Shape selection must only
    // alter the two outer terminations, never the original 24px protrusion.
    expect(rounded.getBounds().top, -24);
    expect(straight.getBounds().top, -24);
    expect(rounded.getBounds().center.dx, straight.getBounds().center.dx);
  });

  testWidgets('shape and border controls preserve the authored FAB rect', (
    tester,
  ) async {
    Future<Rect> pump(
      DashboardBottomNavEdgeShape shape,
      DashboardBottomNavTopBorder border,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Bnb03BottomNavigation(
                selected: Bnb03Item.home,
                edgeShape: shape,
                topBorder: border,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('bnb03-physical-bar-surface')),
        findsOneWidget,
      );
      return tester.getRect(
        find.byKey(const ValueKey('bnb03-fab-outer-purple-ring')),
      );
    }

    final roundedOff = await pump(
      DashboardBottomNavEdgeShape.rounded,
      DashboardBottomNavTopBorder.off,
    );
    final straightOn = await pump(
      DashboardBottomNavEdgeShape.straight,
      DashboardBottomNavTopBorder.thinGrey,
    );
    expect(straightOn, roundedOff);
  });
}
