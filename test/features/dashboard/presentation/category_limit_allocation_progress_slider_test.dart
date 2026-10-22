import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/category_limit_allocation_progress_slider.dart';

void main() {
  test(
    'category allocation/progress segments retain the limit-thumb boundary',
    () {
      final presentation = CategoryLimitSliderPresentation.resolve(
        actualScaled100: 2000000,
        limitScaled100: 5000000,
        maxScaled100: 6000000,
      );

      expect(presentation.spentScaled100, 2000000);
      expect(presentation.remainingAllocatedScaled100, 3000000);
      expect(presentation.unallocatedCapacityScaled100, 1000000);
      expect(presentation.overspendScaled100, 0);
      expect(presentation.limitRatio, closeTo(5 / 6, .000001));
    },
  );

  test('overspend clamps opaque material at the category-limit thumb', () {
    final presentation = CategoryLimitSliderPresentation.resolve(
      actualScaled100: 8000000,
      limitScaled100: 5000000,
      maxScaled100: 6000000,
    );

    expect(presentation.spentScaled100, 5000000);
    expect(presentation.remainingAllocatedScaled100, 0);
    expect(presentation.unallocatedCapacityScaled100, 1000000);
    expect(presentation.overspendScaled100, 3000000);
    expect(presentation.spentRatio, presentation.limitRatio);
  });

  test('zero capacity is a stable non-dividing presentation', () {
    final presentation = CategoryLimitSliderPresentation.resolve(
      actualScaled100: 100000,
      limitScaled100: 0,
      maxScaled100: 0,
    );

    expect(presentation.hasCapacity, isFalse);
    expect(presentation.spentRatio, 0);
    expect(presentation.remainingAllocatedRatio, 0);
    expect(presentation.neutralCapacityRatio, 0);
  });
}
