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
    required this.renderedContentExtent,
    required this.previewPayloadRows,
    required this.previewSurfaceHeight,
    required this.committedCacheQueryKey,
    required this.committedCacheGeneration,
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
  final double renderedContentExtent;
  final int previewPayloadRows;
  final double previewSurfaceHeight;
  final String? committedCacheQueryKey;
  final int? committedCacheGeneration;
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
    'renderedRowCount': renderedRowCount,
    'payloadRowCount': payloadRowCount,
    'drawableRowCount': drawableRowCount,
    'paintedRowCount': paintedRowCount,
    'renderedContentExtent': renderedContentExtent,
    'previewPayloadRows': previewPayloadRows,
    'previewSurfaceHeight': previewSurfaceHeight,
    'committedCacheQueryKey': committedCacheQueryKey,
    'committedCacheGeneration': committedCacheGeneration,
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
