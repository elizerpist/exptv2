import 'package:flutter/foundation.dart';

/// One pure geometry authority for every scope-aware Spending Rhythm chart.
///
/// The supported Partner-card inner chart width is 358dp: the current 378dp
/// Card2 test frame less its existing 10dp outer inset on each side. The 2dp
/// minimum gap preserves distinct rounded bars at the maximum 31-calendar-day
/// density. Together they derive, rather than guess, the smallest legal bar.
@immutable
final class SpendingRhythmBarLayout {
  const SpendingRhythmBarLayout._({
    required this.barWidth,
    required this.gap,
    required this.pitch,
    required this.contentWidth,
    required this.scrollsHorizontally,
  });

  /// Former `_BudgetRhythmBar._trackWidth`; do not change without a visual
  /// source update and this contract test.
  static const double maxBarWidth = 11;
  static const double minimumGap = 2;
  static const double supportedMinimumChartWidth = 358;
  static const int maximumNonScrollableBarCount = 31;
  static const double minBarWidth =
      (supportedMinimumChartWidth -
          (maximumNonScrollableBarCount - 1) * minimumGap) /
      maximumNonScrollableBarCount;

  final double barWidth;
  final double gap;
  final double pitch;
  final double contentWidth;
  final bool scrollsHorizontally;

  static SpendingRhythmBarLayout resolve({
    required double availableWidth,
    required int barCount,
    required bool allowsHorizontalScroll,
  }) {
    if (availableWidth <= 0 || barCount <= 0) {
      throw ArgumentError(
        'Spending Rhythm layout needs positive bounds/count.',
      );
    }
    final scrolls =
        allowsHorizontalScroll && barCount > maximumNonScrollableBarCount;
    if (scrolls) {
      final pitch = minBarWidth + minimumGap;
      return SpendingRhythmBarLayout._(
        barWidth: minBarWidth,
        gap: minimumGap,
        pitch: pitch,
        contentWidth: barCount * minBarWidth + (barCount - 1) * minimumGap,
        scrollsHorizontally: true,
      );
    }
    final fitWidth = (availableWidth - (barCount - 1) * minimumGap) / barCount;
    final barWidth = fitWidth.clamp(minBarWidth, maxBarWidth).toDouble();
    final gap = barCount == 1
        ? 0.0
        : (availableWidth - barCount * barWidth) / (barCount - 1);
    if (gap < minimumGap - .0001) {
      throw ArgumentError.value(
        availableWidth,
        'availableWidth',
        'Unsupported non-scrollable Spending Rhythm viewport.',
      );
    }
    return SpendingRhythmBarLayout._(
      barWidth: barWidth,
      gap: gap,
      pitch: barWidth + gap,
      contentWidth: availableWidth,
      scrollsHorizontally: false,
    );
  }
}
