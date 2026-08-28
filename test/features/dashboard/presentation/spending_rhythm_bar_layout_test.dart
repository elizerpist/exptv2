import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/spending_rhythm_bar_layout.dart';

void main() {
  group('SpendingRhythmBarLayout', () {
    test('keeps eight DAY parts at the existing 11dp authored maximum', () {
      final layout = SpendingRhythmBarLayout.resolve(
        availableWidth: SpendingRhythmBarLayout.supportedMinimumChartWidth,
        barCount: 8,
        allowsHorizontalScroll: false,
      );

      expect(layout.barWidth, SpendingRhythmBarLayout.maxBarWidth);
      expect(layout.gap, greaterThan(SpendingRhythmBarLayout.minimumGap));
      expect(layout.scrollsHorizontally, isFalse);
    });

    test('fits every 31-day month at the derived width with equal gaps', () {
      final layout = SpendingRhythmBarLayout.resolve(
        availableWidth: SpendingRhythmBarLayout.supportedMinimumChartWidth,
        barCount: 31,
        allowsHorizontalScroll: false,
      );

      expect(layout.scrollsHorizontally, isFalse);
      expect(
        layout.barWidth,
        greaterThanOrEqualTo(SpendingRhythmBarLayout.minBarWidth),
      );
      expect(
        layout.barWidth,
        lessThanOrEqualTo(SpendingRhythmBarLayout.maxBarWidth),
      );
      expect(
        layout.gap,
        greaterThanOrEqualTo(SpendingRhythmBarLayout.minimumGap),
      );
      expect(
        layout.contentWidth,
        closeTo(SpendingRhythmBarLayout.supportedMinimumChartWidth, .0001),
      );
    });

    test(
      'keeps a SUM domain beyond 31 years scrollable instead of shrinking bars',
      () {
        final layout = SpendingRhythmBarLayout.resolve(
          availableWidth: SpendingRhythmBarLayout.supportedMinimumChartWidth,
          barCount: 32,
          allowsHorizontalScroll: true,
        );

        expect(layout.scrollsHorizontally, isTrue);
        expect(layout.barWidth, SpendingRhythmBarLayout.minBarWidth);
        expect(
          layout.contentWidth,
          greaterThan(SpendingRhythmBarLayout.supportedMinimumChartWidth),
        );
      },
    );
  });
}
