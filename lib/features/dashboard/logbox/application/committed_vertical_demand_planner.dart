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
    double? pageExtent,
    double forwardVelocityPixelsPerSecond = 0,
    int observedPageReadyMicros = 0,
    int maximumLookaheadPages = 2,
    int lookaheadPages = 2,
  }) {
    if (!hasMorePages || lastPossibleOrdinal <= highestReadyOrdinal) {
      return currentDesiredOrdinal;
    }
    if (lookaheadPages < 2 || maximumLookaheadPages < lookaheadPages) {
      throw ArgumentError('Committed forward lookahead bounds are invalid.');
    }
    // A viewport can momentarily report a large synthetic range while the
    // ready extent is growing. Keep the normal prefetch bank bounded relative
    // to the contiguous frontier; sequential drain will extend it on demand.
    final effectivePageExtent = (pageExtent ?? viewportDimension) > 0
        ? pageExtent ?? viewportDimension
        : 1.0;
    final pageLatencySeconds = observedPageReadyMicros <= 0
        ? 0.0
        : observedPageReadyMicros / Duration.microsecondsPerSecond;
    final forwardConsumptionPages = forwardVelocityPixelsPerSecond <= 0
        ? 0
        : (forwardVelocityPixelsPerSecond *
                  pageLatencySeconds /
                  effectivePageExtent)
              .ceil();
    // Preserve the established two-page floor. A measured slow page gets one
    // bounded extra buffer after the distance that can be consumed while that
    // sequential keyset read is pending.
    final adaptiveExtra = forwardConsumptionPages == 0
        ? 0
        : forwardConsumptionPages + 1;
    final adaptiveLookahead = (lookaheadPages + adaptiveExtra)
        .clamp(lookaheadPages, maximumLookaheadPages)
        .toInt();
    final visibleLookahead = (lastVisibleOrdinal + adaptiveLookahead).clamp(
      0,
      highestReadyOrdinal + adaptiveLookahead,
    );
    final estimatedPage = viewportDimension > 0 ? viewportDimension : 1.0;
    final nearFrontier = distanceToDrawableEnd <= estimatedPage;
    final frontierMinimum = nearFrontier ? highestReadyOrdinal + 1 : 0;
    return <int>[currentDesiredOrdinal, visibleLookahead, frontierMinimum]
        .reduce((left, right) => left > right ? left : right)
        .clamp(0, lastPossibleOrdinal);
  }
}
