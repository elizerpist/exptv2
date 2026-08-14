/// Pure O(1) forward-demand policy for the committed vertical viewport.
///
/// The immutable virtual geometry supplies the last visible page, so demand
/// stays independent from the materialized ready frontier. It only calculates
/// a bounded target; it owns neither I/O nor cache resources.
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
    if (!hasMorePages || lastPossibleOrdinal <= currentDesiredOrdinal) {
      return currentDesiredOrdinal;
    }
    // The values remain parameters for low-frequency diagnostics and API
    // compatibility, but the scrollable extent is already complete. A page
    // completion must not generate an extent-frontier feedback loop.
    assert(highestReadyOrdinal >= -1);
    assert(distanceToDrawableEnd >= 0);
    assert(viewportDimension >= 0);
    final visibleLookahead = lastVisibleOrdinal + lookaheadPages;
    return (visibleLookahead > currentDesiredOrdinal
            ? visibleLookahead
            : currentDesiredOrdinal)
        .clamp(0, lastPossibleOrdinal);
  }
}
