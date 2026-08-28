import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_expansion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_upper_vertical_gesture_coordinator.dart';

void main() {
  test(
    'surface drag and boundary overscroll use the one Header expansion owner',
    () {
      final direct = DashboardExpansionController();
      direct
        ..beginDrag()
        ..dragBy(-42);

      final coordinated = DashboardExpansionController();
      final coordinator = DashboardUpperVerticalGestureCoordinator(
        expansion: coordinated,
        mapViewportDelta: (delta) => delta,
      );
      coordinator.dragByViewport(-42);

      expect(coordinated.progress, direct.progress);
      expect(coordinated.isDragging, isTrue);

      final beforeHandoff = coordinated.progress;
      coordinator.consumeBoundaryOverscroll(12);
      expect(coordinated.progress, greaterThan(beforeHandoff));

      coordinator.end();
      expect(coordinated.isDragging, isFalse);
    },
  );
}
