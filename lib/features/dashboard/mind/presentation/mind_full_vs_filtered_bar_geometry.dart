import 'dart:math' as math;

/// Shared truthful geometry for a full-scope neutral reference bar and its
/// current-scope foreground overlay. Both consumers normalize against the
/// full-scope maximum, never the filtered maximum.
abstract final class MindFullVsFilteredBarGeometry {
  static bool hasReference(int fullAmount) => fullAmount > 0;

  static bool hasForeground(int filteredAmount) => filteredAmount > 0;

  static double heightForFraction({
    required double plotHeight,
    required double fraction,
    required bool hasAmount,
    double minimumVisibleHeight = 0,
  }) {
    if (!hasAmount || plotHeight <= 0) return 0;
    return math.min(
      plotHeight,
      math.max(minimumVisibleHeight, plotHeight * fraction),
    );
  }
}
