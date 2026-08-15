import 'dart:math' as math;

/// Separates a physical viewport from the optional terminal space that keeps
/// the final LogBox clear of shell-owned navigation chrome.
///
/// The terminal inset is one scroll-only tail. It is never row, page, cached
/// scene, or virtual-geometry data. When the complete content already fits in
/// the viewport, no tail is installed and no artificial scroll range exists.
final class DashboardLogBoxTerminalExtent {
  const DashboardLogBoxTerminalExtent._({
    required this.viewportDimension,
    required this.renderSurfaceExtent,
    required this.terminalBottomInset,
  });

  factory DashboardLogBoxTerminalExtent.resolve({
    required double logBoxContentExtent,
    required double viewportDimension,
    required double terminalBottomInset,
  }) {
    final viewport = math.max(0.0, viewportDimension).toDouble();
    final content = math.max(0.0, logBoxContentExtent).toDouble();
    final requestedInset = math.max(0.0, terminalBottomInset).toDouble();
    final needsScrollableTail =
        content > 0 && content + requestedInset > viewport;
    return DashboardLogBoxTerminalExtent._(
      viewportDimension: viewport,
      // A short exact scope keeps its own exact surface height. The viewport
      // still reaches the physical bottom, but it has no invented content or
      // scroll range merely to fill that space. The empty state remains a
      // viewport-sized stable render host so its later first publication does
      // not create or replace the scroll surface.
      renderSurfaceExtent: content == 0 ? viewport : content,
      terminalBottomInset: needsScrollableTail ? requestedInset : 0,
    );
  }

  /// The actual `CustomScrollView` viewport. Navigation chrome must not
  /// subtract from this physical hit-test/layout domain.
  final double viewportDimension;

  /// The one LogBox render-surface sliver extent. This is not augmented by a
  /// navigation amount when a real scroll tail is needed.
  final double renderSurfaceExtent;

  /// A separate sliver after [renderSurfaceExtent].
  final double terminalBottomInset;

  double get effectiveScrollContentExtent =>
      renderSurfaceExtent + terminalBottomInset;

  double get maxScrollExtent =>
      math.max(0.0, effectiveScrollContentExtent - viewportDimension);
}
