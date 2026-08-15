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
}) {
  final hasExactGeometry = hasExactCommittedLogBoxGeometry(
    payload: payload,
    presentation: presentation,
    committedViewport: committedViewport,
  );
  // The normal initial path deliberately stays in the rail-preview domain
  // until a real vertical gesture starts. If that exact rail scene is absent,
  // however, an already-prepared committed root fallback is the only valid
  // paint source. Promote it immediately rather than exposing geometry for a
  // non-empty page that the fail-closed painter must skip.
  final fallbackMustPaint =
      payload != null &&
      payload.previewRowCount > 0 &&
      !hasExactRailScene &&
      committedViewport.hasDrawableRootFallback;
  if (!hasExactGeometry ||
      payload == null ||
      (!committedViewport.isVerticalRenderingActive && !fallbackMustPaint) ||
      committedViewport.surfaceWidth == null ||
      (payload.previewRowCount > 0 &&
          !hasExactRailScene &&
          !committedViewport.hasDrawableRootFallback)) {
    return DashboardLogBoxRenderDomain.railPreview;
  }
  return DashboardLogBoxRenderDomain.committedVertical;
}
