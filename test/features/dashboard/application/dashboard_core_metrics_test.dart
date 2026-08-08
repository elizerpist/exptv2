import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';

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

  test('exports the latest post-layout LogBox extent snapshot', () {
    final core = DashboardCoreController();
    addTearDown(core.dispose);

    core.recordLogBoxRenderExtent(
      const DashboardLogBoxRenderExtentSnapshot(
        presentation: null,
        payloadLaneMode: null,
        payloadViewportId: 7,
        renderDomain: DashboardLogBoxRenderDomain.committedVertical,
        readyRows: 94,
        drawableExtent: 5850,
        renderSurfaceHeight: 5850,
        sliverScrollExtent: 5878,
        viewportDimension: 392,
        minScrollExtent: 0,
        maxScrollExtent: 5486,
        pixels: 947,
        isMismatch: false,
      ),
    );

    final report = core.exportPhysicalRailReport();
    final presentation = report['logBoxPresentation']! as Map<String, Object?>;
    expect(presentation['renderDomain'], 'committedVertical');
    expect(presentation['readyRows'], 94);
    expect(presentation['drawableExtent'], 5850);
    expect(presentation['maxScrollExtent'], 5486);
    expect(presentation['scrollExtentMismatchCount'], 0);
  });
}
