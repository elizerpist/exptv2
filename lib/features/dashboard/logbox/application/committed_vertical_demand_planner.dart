/// Pure O(1) forward-demand policy for the committed vertical viewport.
///
/// The lower edge of the drawable viewport approaches the ready frontier, so
/// demand is derived from the last visible page. It only calculates a bounded
/// target; it owns neither I/O nor cache resources.
final class CommittedVerticalDemandPlanner {
  const CommittedVerticalDemandPlanner._();

  static int plan({
    required int lastVisibleOrdinal,
    required int highestReadyOrdinal,
    required int currentDesiredOrdinal,
    required int lastPossibleOrdinal,
    required bool hasMorePages,
    required double distanceToDrawableEnd,
    required double viewportDimension,
    int lookaheadPages = 2,
  }) {
    if (!hasMorePages || lastPossibleOrdinal <= highestReadyOrdinal) {
      return currentDesiredOrdinal;
    }
    // A ScrollPosition can momentarily project beyond the contiguous exact
    // geometry while a page commit changes extent. Keep ordinary lookahead
    // bounded by the actual ready frontier, then protect that frontier as the
    // drawable end approaches.
    final visibleLookahead = (lastVisibleOrdinal + lookaheadPages).clamp(
      0,
      highestReadyOrdinal + lookaheadPages,
    );
    final effectiveViewport = viewportDimension > 0 ? viewportDimension : 1.0;
    final nearFrontier = distanceToDrawableEnd <= effectiveViewport;
    final frontierMinimum = nearFrontier ? highestReadyOrdinal + 1 : 0;
    return <int>[currentDesiredOrdinal, visibleLookahead, frontierMinimum]
        .reduce((left, right) => left > right ? left : right)
        .clamp(0, lastPossibleOrdinal);
  }
}
