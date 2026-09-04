import '../../visible/domain/dashboard_logbox_presentation_binding.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_logbox_render_domain.dart';

/// One post-layout report of the exact LogBox surface exposed to Flutter.
///
/// This is presentation metadata only. It never retains page rows or takes
/// part in paging, rail selection, or scroll-position mutation.
final class DashboardLogBoxRenderExtentSnapshot {
  const DashboardLogBoxRenderExtentSnapshot({
    required this.presentation,
    required this.payloadLaneMode,
    required this.payloadViewportId,
    required this.renderDomain,
    required this.renderedRowCount,
    this.payloadRowCount = 0,
    this.drawableRowCount = 0,
    this.paintedRowCount = 0,
    this.readablePhaseARowCount = 0,
    this.readablePhaseARowsPainted = 0,
    this.richPhaseBRowsPainted = 0,
    required this.renderedContentExtent,
    required this.previewPayloadRows,
    required this.previewSurfaceHeight,
    required this.committedCacheQueryKey,
    required this.committedCacheGeneration,
    this.committedCacheGeometryGeneration,
    required this.committedCacheReadyRows,
    required this.committedCacheDrawableExtent,
    this.committedCacheReadyFrontierOrdinal = -1,
    required this.renderSurfaceHeight,
    required this.sliverScrollExtent,
    this.terminalBottomInset = 0,
    double? effectiveScrollContentExtent,
    required this.viewportDimension,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.pixels,
    required this.isMismatch,
  }) : effectiveScrollContentExtent =
           effectiveScrollContentExtent ??
           renderSurfaceHeight + terminalBottomInset;

  final DashboardLogBoxPresentationBinding? presentation;
  final DashboardVisibleMode? payloadLaneMode;
  final int? payloadViewportId;
  final DashboardLogBoxRenderDomain renderDomain;

  /// Legacy payload/domain row count retained for existing consumers. It is
  /// not physical paint evidence; use the explicit counts below for that.
  final int renderedRowCount;
  final int payloadRowCount;
  final int drawableRowCount;
  final int paintedRowCount;

  /// Explicit Phase-A/Phase-B paint evidence. A non-zero [paintedRowCount]
  /// alone cannot prove readable transaction content because the old fallback
  /// drew only bars and a dot from semantic identity.
  final int readablePhaseARowCount;
  final int readablePhaseARowsPainted;
  final int richPhaseBRowsPainted;
  final double renderedContentExtent;
  final int previewPayloadRows;
  final double previewSurfaceHeight;
  final String? committedCacheQueryKey;
  final int? committedCacheGeneration;

  /// Immutable committed-world geometry identity observed by the render
  /// surface. This is intentionally separate from the paging/resource
  /// generation so a post-promotion acknowledgement can be diagnosed without
  /// conflating page readiness with the exact geometry it painted.
  final int? committedCacheGeometryGeneration;
  final int committedCacheReadyRows;
  final double committedCacheDrawableExtent;
  final int committedCacheReadyFrontierOrdinal;
  final double renderSurfaceHeight;
  final double sliverScrollExtent;
  final double terminalBottomInset;
  final double effectiveScrollContentExtent;
  final double viewportDimension;
  final double minScrollExtent;
  final double maxScrollExtent;
  final double pixels;
  final bool isMismatch;

  Map<String, Object?> toReportMap() => <String, Object?>{
    'authoritativePresentationMode': presentation?.mode.name ?? 'unbound',
    'payloadLaneMode': payloadLaneMode?.name ?? 'unbound',
    'renderDomain': renderDomain.name,
    'payloadViewportId': payloadViewportId,
    'authoritativeViewportId': presentation?.viewportId,
    'queryKey': presentation?.queryKey.value,
    'coreRevision': presentation?.coreRevision,
    'presentationEpoch': presentation?.presentationEpoch,
    'frameGeneration': presentation?.frameGeneration,
    'renderedRowCount': renderedRowCount,
    'payloadRowCount': payloadRowCount,
    'drawableRowCount': drawableRowCount,
    'paintedRowCount': paintedRowCount,
    'readablePhaseARowCount': readablePhaseARowCount,
    'readablePhaseARowsPainted': readablePhaseARowsPainted,
    'richPhaseBRowsPainted': richPhaseBRowsPainted,
    'renderedContentExtent': renderedContentExtent,
    'previewPayloadRows': previewPayloadRows,
    'previewSurfaceHeight': previewSurfaceHeight,
    'committedCacheQueryKey': committedCacheQueryKey,
    'committedCacheGeneration': committedCacheGeneration,
    'committedCacheGeometryGeneration': committedCacheGeometryGeneration,
    'committedCacheReadyRows': committedCacheReadyRows,
    'committedCacheDrawableExtent': committedCacheDrawableExtent,
    'committedCacheReadyFrontierOrdinal': committedCacheReadyFrontierOrdinal,
    'renderSurfaceHeight': renderSurfaceHeight,
    'sliverScrollExtent': sliverScrollExtent,
    'terminalBottomInset': terminalBottomInset,
    'effectiveScrollContentExtent': effectiveScrollContentExtent,
    'viewportDimension': viewportDimension,
    'minScrollExtent': minScrollExtent,
    'maxScrollExtent': maxScrollExtent,
    'pixels': pixels,
    'scrollExtentMismatch': isMismatch,
  };
}
