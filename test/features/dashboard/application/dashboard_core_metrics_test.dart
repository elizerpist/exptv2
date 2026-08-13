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
        renderedRowCount: 94,
        renderedContentExtent: 5850,
        previewPayloadRows: 24,
        previewSurfaceHeight: 1800,
        committedCacheQueryKey: 'expense|month:2026-06',
        committedCacheGeneration: 3,
        committedCacheReadyRows: 94,
        committedCacheDrawableExtent: 5850,
        renderSurfaceHeight: 5850,
        sliverScrollExtent: 5878,
        viewportDimension: 392,
        minScrollExtent: 0,
        maxScrollExtent: 5486,
        pixels: 947,
        isMismatch: false,
      ),
    );
    core.recordVerticalCommittedScopeReset();

    final report = core.exportPhysicalRailReport();
    final presentation = report['logBoxPresentation']! as Map<String, Object?>;
    expect(presentation['renderDomain'], 'committedVertical');
    expect(presentation['renderedRowCount'], 94);
    expect(presentation['renderedContentExtent'], 5850);
    expect(presentation['committedCacheReadyRows'], 94);
    expect(presentation['committedCacheDrawableExtent'], 5850);
    expect(presentation['maxScrollExtent'], 5486);
    expect(presentation['scrollExtentMismatchCount'], 0);
    expect(presentation['verticalCommittedScopeResetCount'], 1);
  });

  test(
    'vertical input is distinct from structural motion and resumes cleanly',
    () {
      final core = DashboardCoreController();
      addTearDown(core.dispose);

      expect(core.verticalInteractionActive, isFalse);
      expect(core.diagnostics.isMotionActive, isFalse);

      core.beginVerticalInteraction();

      expect(core.verticalInteractionActive, isTrue);
      expect(
        core.diagnostics.isMotionActive,
        isFalse,
        reason:
            'Vertical input must not enter the structural/rail gate that '
            'defers sequential committed page acquisition.',
      );

      core.resumeSceneWindowMaintenanceAfterVerticalInput();

      expect(core.verticalInteractionActive, isFalse);
    },
  );
}
