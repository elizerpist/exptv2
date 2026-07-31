import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_expansion_controller.dart';

void main() {
  group('DashboardExpansionController', () {
    test('turns a 100 px upward drag into a collapsed snap', () {
      final controller = DashboardExpansionController();

      controller.beginDrag();
      controller.dragBy(-100);

      expect(controller.progress, 100);
      expect(controller.endDrag(), DashboardExpansionTarget.collapsed);
      expect(controller.progress, 180);
    });

    test('snaps an exact 90 px drag back to expanded', () {
      final controller = DashboardExpansionController();

      controller.beginDrag();
      controller.dragBy(-90);

      expect(controller.endDrag(), DashboardExpansionTarget.expanded);
      expect(controller.progress, 0);
    });

    test('clamps upward and downward drag progress at both endpoints', () {
      final controller = DashboardExpansionController();

      controller.beginDrag();
      controller.dragBy(-1000);
      expect(controller.progress, 180);

      controller.dragBy(1000);
      expect(controller.progress, 0);
    });
  });

  test('DashboardCoreController owns one disposable expansion controller', () {
    final core = DashboardCoreController();
    var notifications = 0;
    core.expansion.addListener(() => notifications += 1);

    core.expansion.setProgress(12);
    expect(notifications, 1);
    expect(core.expansion, isA<DashboardExpansionController>());

    core.dispose();
    expect(
      () => core.expansion.addListener(() => notifications += 1),
      throwsFlutterError,
    );
  });

  test('derives travel and snap threshold from configured layout metrics', () {
    final metrics = DashboardLayoutMetrics.reference.copyWith(
      collapseTravel: 240,
    );
    final controller = DashboardExpansionController(metrics: metrics);

    expect(controller.collapseTravel, 240);
    expect(controller.snapThreshold, 120);

    controller.beginDrag();
    controller.dragBy(-120);
    expect(controller.endDrag(), DashboardExpansionTarget.expanded);

    controller.beginDrag();
    controller.dragBy(-121);
    expect(controller.endDrag(), DashboardExpansionTarget.collapsed);
    expect(controller.progress, 240);
  });
}
