import 'package:flutter/widgets.dart';

/// Immutable observation emitted after the framework has handled one
/// [ScrollPosition.goBallistic] invocation.
///
/// This is intentionally diagnostic-only: the viewport retains the framework
/// physics and forwards the exact velocity unchanged.
@immutable
final class DashboardVerticalBallisticObservation {
  const DashboardVerticalBallisticObservation({
    required this.pixels,
    required this.maxScrollExtent,
    required this.initialVelocity,
    required this.releaseInvocation,
    required this.goBallisticInvocationCount,
    required this.ballisticStarted,
  });

  final double pixels;
  final double maxScrollExtent;
  final double initialVelocity;
  final bool releaseInvocation;
  final int goBallisticInvocationCount;
  final bool ballisticStarted;
}

/// One content-dimension application observed by the stable vertical
/// [ScrollPosition].
@immutable
final class DashboardVerticalContentDimensionObservation {
  const DashboardVerticalContentDimensionObservation({
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.ballisticActive,
  });

  final double minScrollExtent;
  final double maxScrollExtent;
  final bool ballisticActive;
}

/// A stable viewport-owned controller that observes framework handoff
/// decisions without changing the simulation, velocity or physics.
///
/// There is exactly one instance for a [DashboardLogBoxViewport] lifetime.
/// It is not a paging/cache owner and does not alter scroll behavior.
final class DashboardVerticalScrollController extends ScrollController {
  DashboardVerticalScrollController({
    required this.onBallistic,
    required this.onContentDimensionsChanged,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  final ValueChanged<DashboardVerticalBallisticObservation> onBallistic;
  final ValueChanged<DashboardVerticalContentDimensionObservation>
  onContentDimensionsChanged;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _DashboardVerticalScrollPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
    onBallistic: onBallistic,
    onContentDimensionsChanged: onContentDimensionsChanged,
  );
}

final class _DashboardVerticalScrollPosition
    extends ScrollPositionWithSingleContext {
  _DashboardVerticalScrollPosition({
    required super.physics,
    required super.context,
    required super.initialPixels,
    required super.keepScrollOffset,
    required super.oldPosition,
    required super.debugLabel,
    required this.onBallistic,
    required this.onContentDimensionsChanged,
  });

  final ValueChanged<DashboardVerticalBallisticObservation> onBallistic;
  final ValueChanged<DashboardVerticalContentDimensionObservation>
  onContentDimensionsChanged;
  int _goBallisticInvocationCount = 0;

  @override
  void goBallistic(double velocity) {
    _goBallisticInvocationCount += 1;
    final releaseInvocation = activity is DragScrollActivity;
    // This call is deliberately unmodified. The framework remains the only
    // authority that selects the simulation or decides to remain idle.
    super.goBallistic(velocity);
    onBallistic(
      DashboardVerticalBallisticObservation(
        pixels: pixels,
        maxScrollExtent: maxScrollExtent,
        initialVelocity: velocity,
        releaseInvocation: releaseInvocation,
        goBallisticInvocationCount: _goBallisticInvocationCount,
        ballisticStarted: activity is BallisticScrollActivity,
      ),
    );
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final changed =
        !hasContentDimensions ||
        this.minScrollExtent != minScrollExtent ||
        this.maxScrollExtent != maxScrollExtent;
    final accepted = super.applyContentDimensions(
      minScrollExtent,
      maxScrollExtent,
    );
    if (changed) {
      onContentDimensionsChanged(
        DashboardVerticalContentDimensionObservation(
          minScrollExtent: minScrollExtent,
          maxScrollExtent: maxScrollExtent,
          ballisticActive: activity is BallisticScrollActivity,
        ),
      );
    }
    return accepted;
  }
}
