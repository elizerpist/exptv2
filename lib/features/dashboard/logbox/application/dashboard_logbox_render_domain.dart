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

DashboardLogBoxRenderDomain resolveDashboardLogBoxRenderDomain({
  required DashboardLogViewportState? payload,
  required DashboardLogBoxPresentationBinding? presentation,
  required CommittedLogViewportCache committedViewport,
}) {
  if (payload == null ||
      presentation == null ||
      presentation.mode != DashboardVisibleMode.committed ||
      payload.queryKey != presentation.queryKey ||
      payload.revision != presentation.coreRevision ||
      !committedViewport.isVerticalRenderingActive ||
      !committedViewport.hasExactCommittedScope ||
      committedViewport.queryKey != presentation.queryKey ||
      committedViewport.coreRevision != presentation.coreRevision ||
      committedViewport.surfaceWidth == null ||
      committedViewport.rootPageViewportId != payload.viewportId ||
      presentation.viewportId != payload.viewportId) {
    return DashboardLogBoxRenderDomain.railPreview;
  }
  return DashboardLogBoxRenderDomain.committedVertical;
}
