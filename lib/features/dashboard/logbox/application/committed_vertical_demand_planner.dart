/// Pure O(1) forward-demand policy for the committed vertical viewport.
///
/// The lower edge of the visible viewport approaches the drawable frontier;
/// demand must therefore be derived from the last visible page, never from
/// the first page.
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
    // A viewport can momentarily report a large synthetic range while the
    // ready extent is growing. Keep the normal prefetch bank bounded relative
    // to the contiguous frontier; sequential drain will extend it on demand.
    final visibleLookahead = (lastVisibleOrdinal + lookaheadPages).clamp(
      0,
      highestReadyOrdinal + lookaheadPages,
    );
    final estimatedPage = viewportDimension > 0 ? viewportDimension : 1.0;
    final nearFrontier = distanceToDrawableEnd <= estimatedPage;
    final frontierMinimum = nearFrontier ? highestReadyOrdinal + 1 : 0;
    return <int>[currentDesiredOrdinal, visibleLookahead, frontierMinimum]
        .reduce((left, right) => left > right ? left : right)
        .clamp(0, lastPossibleOrdinal);
  }
}
