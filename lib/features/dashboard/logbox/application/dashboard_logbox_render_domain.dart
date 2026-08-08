import '../../visible/domain/dashboard_visible_frame.dart';
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
  required DashboardVisibleFrame? frame,
  required CommittedLogViewportCache committedViewport,
}) {
  final payload = frame?.logBox;
  if (frame == null ||
      payload == null ||
      frame.mode != DashboardVisibleMode.committed ||
      !committedViewport.isVerticalRenderingActive ||
      !committedViewport.hasExactCommittedScope ||
      committedViewport.queryKey != frame.queryKey ||
      committedViewport.coreRevision != frame.coreRevision ||
      committedViewport.surfaceWidth == null ||
      committedViewport.rootPageViewportId != payload.viewportId) {
    return DashboardLogBoxRenderDomain.railPreview;
  }
  return DashboardLogBoxRenderDomain.committedVertical;
}
