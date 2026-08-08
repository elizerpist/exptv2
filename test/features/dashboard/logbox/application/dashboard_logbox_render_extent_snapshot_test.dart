import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';

void main() {
  test(
    'preview extent reports rendered payload separately from old committed cache',
    () {
      const snapshot = DashboardLogBoxRenderExtentSnapshot(
        presentation: null,
        payloadLaneMode: null,
        payloadViewportId: 7,
        renderDomain: DashboardLogBoxRenderDomain.railPreview,
        renderedRowCount: 24,
        renderedContentExtent: 1760,
        previewPayloadRows: 24,
        previewSurfaceHeight: 1760,
        committedCacheQueryKey: 'expense|month:2026-06',
        committedCacheGeneration: 4,
        committedCacheReadyRows: 94,
        committedCacheDrawableExtent: 5850,
        renderSurfaceHeight: 1760,
        sliverScrollExtent: 1760,
        viewportDimension: 420,
        minScrollExtent: 0,
        maxScrollExtent: 1340,
        pixels: 120,
        isMismatch: false,
      );

      final report = snapshot.toReportMap();
      expect(report['renderDomain'], 'railPreview');
      expect(report['renderedRowCount'], 24);
      expect(report['renderedContentExtent'], 1760);
      expect(report['previewPayloadRows'], 24);
      expect(report['previewSurfaceHeight'], 1760);
      expect(report['committedCacheQueryKey'], 'expense|month:2026-06');
      expect(report['committedCacheGeneration'], 4);
      expect(report['committedCacheReadyRows'], 94);
      expect(report['committedCacheDrawableExtent'], 5850);
      expect(report.containsKey('readyRows'), isFalse);
      expect(report.containsKey('drawableExtent'), isFalse);
    },
  );
}
