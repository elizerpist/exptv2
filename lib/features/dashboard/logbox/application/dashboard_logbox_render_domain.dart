import 'dart:math' as math;

import '../../../../core/design/dashboard_logbox_layout_profile.dart';
import 'dashboard_log_viewport_state.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../../visible/domain/dashboard_logbox_presentation_binding.dart';
import 'committed_log_viewport_cache.dart';

/// The only LogBox rendering domain for one visible frame.
///
/// A rail preview is self-contained in the prepared rail scene cache. A
/// committed vertical frame may use its independent paged cache only when the
/// exact committed root is still installed. Keeping this choice in the
/// application contract prevents paint, hit testing, semantics, diagnostics,
/// and report export from inferring different owners from incidental cache
/// state.
enum DashboardLogBoxRenderDomain { railPreview, committedVertical }

/// Exact content geometry for the bounded prepared payload before a physical
/// vertical gesture takes ownership. This is deliberately independent of the
/// viewport-sized structural host used for an empty result and of the
/// committed virtual scroll world.
double dashboardLogBoxPayloadContentExtent({
  required DashboardLogViewportState? payload,
  required DashboardLogBoxLayoutProfile layoutProfile,
}) {
  if (payload == null || payload.previewRowCount == 0) return 0;
  // A sparse prepared-index frame must never materialize its group table from
  // layout or paint. Its live resource owner arms exact Phase-A geometry
  // before publication; until then this dormant fallback owns no scrollable
  // content extent.
  final geometry = payload.preparedSemanticPreviewGeometry;
  return geometry?.contentExtent(layoutProfile.rowHeight) ?? 0;
}

/// One extent authority for the one selected render domain.
///
/// A committed cache may already be exact while the renderer intentionally
/// stays in [DashboardLogBoxRenderDomain.railPreview]. In that state its
/// virtual geometry is a dormant fallback, not the current surface extent.
/// Selecting it here only when the selected paint domain is committed keeps
/// paint, first-row origin, terminal-tail calculation, semantics and the
/// post-layout acknowledgement on the same immutable visual authority.
double dashboardLogBoxSurfaceExtentForDomain({
  required DashboardLogBoxRenderDomain renderDomain,
  required DashboardLogViewportState? payload,
  required double minimumHeight,
  required CommittedLogViewportCache committedViewport,
  required DashboardLogBoxLayoutProfile layoutProfile,
}) {
  if (renderDomain == DashboardLogBoxRenderDomain.committedVertical &&
      committedViewport.hasVirtualGeometry) {
    return committedViewport.totalEntryCount == 0
        ? minimumHeight
        : math.max(0, committedViewport.contentHeight);
  }
  return math.max(
    minimumHeight,
    dashboardLogBoxPayloadContentExtent(
      payload: payload,
      layoutProfile: layoutProfile,
    ),
  );
}

/// Whether the currently published payload and cache share one exact immutable
/// committed geometry. This remains true while the painter deliberately stays
/// in [DashboardLogBoxRenderDomain.railPreview] before first vertical input.
///
/// Keeping the test here prevents the render-domain selector and the scroll
/// surface from deriving different scope identities from incidental cache
/// state.
bool hasExactCommittedLogBoxGeometry({
  required DashboardLogViewportState? payload,
  required DashboardLogBoxPresentationBinding? presentation,
  required CommittedLogViewportCache committedViewport,
}) =>
    payload != null &&
    presentation != null &&
    presentation.mode == DashboardVisibleMode.committed &&
    payload.queryKey == presentation.queryKey &&
    payload.revision == presentation.coreRevision &&
    committedViewport.hasExactCommittedScope &&
    committedViewport.hasVirtualGeometry &&
    committedViewport.queryKey == presentation.queryKey &&
    committedViewport.coreRevision == presentation.coreRevision &&
    committedViewport.rootPageViewportId == payload.viewportId &&
    presentation.viewportId == payload.viewportId;

DashboardLogBoxRenderDomain resolveDashboardLogBoxRenderDomain({
  required DashboardLogViewportState? payload,
  required DashboardLogBoxPresentationBinding? presentation,
  required CommittedLogViewportCache committedViewport,
  bool hasExactRailScene = false,
  bool hasCompleteReadablePhaseA = false,
}) {
  final hasExactGeometry = hasExactCommittedLogBoxGeometry(
    payload: payload,
    presentation: presentation,
    committedViewport: committedViewport,
  );
  // The normal initial path deliberately stays in the rail-preview domain
  // until a real vertical gesture starts. An already-prepared committed root
  // is an emergency paint source only when neither optional rich Phase B nor
  // the mandatory readable Phase-A bank can paint the exact target. Rich
  // readiness must never cause an otherwise drawable Phase-A target to change
  // domain, extent owner, or first-row geometry before vertical input.
  final fallbackMustPaint =
      payload != null &&
      payload.previewRowCount > 0 &&
      !hasExactRailScene &&
      !hasCompleteReadablePhaseA &&
      committedViewport.hasDrawableRootFallback;
  final hasCommittedPaintSource =
      hasExactRailScene || committedViewport.hasDrawableRootFallback;
  if (!hasExactGeometry ||
      payload == null ||
      (!committedViewport.isVerticalRenderingActive && !fallbackMustPaint) ||
      committedViewport.surfaceWidth == null ||
      (payload.previewRowCount > 0 && !hasCommittedPaintSource)) {
    return DashboardLogBoxRenderDomain.railPreview;
  }
  return DashboardLogBoxRenderDomain.committedVertical;
}
