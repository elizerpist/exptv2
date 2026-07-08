import 'package:exptv2/features/stats/data/stats_scope_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes empty and all-selected scopes to ALL', () {
    expect(
      StatsScopeSelection.normalize(
        selectedCategoryIds: const {},
        availableCategoryIds: const {1, 2, 3},
      ).isAll,
      isTrue,
    );
    expect(
      StatsScopeSelection.normalize(
        selectedCategoryIds: const {1, 2, 3},
        availableCategoryIds: const {1, 2, 3},
      ).isAll,
      isTrue,
    );
  });

  test('keeps partial selections as custom scope', () {
    final selection = StatsScopeSelection.normalize(
      selectedCategoryIds: const {1, 3},
      availableCategoryIds: const {1, 2, 3},
    );

    expect(selection.isAll, isFalse);
    expect(selection.selectedCategoryIds, {1, 3});
    expect(selection.chipLabel, '2');
  });

  test('filters unavailable category ids before normalizing', () {
    final selection = StatsScopeSelection.normalize(
      selectedCategoryIds: const {1, 2, 99},
      availableCategoryIds: const {1, 2, 3},
    );

    expect(selection.isAll, isFalse);
    expect(selection.selectedCategoryIds, {1, 2});
    expect(selection.includesCategory(1), isTrue);
    expect(selection.includesCategory(3), isFalse);
    expect(selection.includesCategory(null), isFalse);
  });

  test('ALL includes uncategorized active-side records', () {
    final selection = StatsScopeSelection.normalize(
      selectedCategoryIds: const {},
      availableCategoryIds: const {1, 2, 3},
    );

    expect(selection.includesCategory(1), isTrue);
    expect(selection.includesCategory(null), isTrue);
    expect(selection.chipLabel, 'ALL');
  });
}
