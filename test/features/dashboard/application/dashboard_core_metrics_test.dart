import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';

void main() {
  test('threads the configured geometry metrics into its expansion owner', () {
    final metrics = DashboardLayoutMetrics.reference.copyWith(
      collapseTravel: 300,
    );
    final core = DashboardCoreController(metrics: metrics);

    expect(core.metrics, same(metrics));
    expect(core.expansion.collapseTravel, 300);
    expect(core.expansion.snapThreshold, 150);
    core.dispose();
  });
}
