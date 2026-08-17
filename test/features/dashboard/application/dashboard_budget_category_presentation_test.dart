import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_presentation.dart';

void main() {
  test(
    'maps the authoritative category collection immediately in its order',
    () {
      final categories = ValueNotifier<List<FluviCategory>>([
        _category(
          id: 'groceries',
          name: 'Groceries',
          colorId: 'color_08',
          iconId: 'icon_08',
        ),
        _category(
          id: 'travel',
          name: 'Travel',
          colorId: 'color_13',
          iconId: 'icon_11',
        ),
        _category(
          id: 'uncategorized',
          name: 'Uncategorized',
          colorId: 'color_01',
          iconId: 'icon_01',
          isSystemUncategorized: true,
        ),
      ]);
      final inputCounts = <int>[];
      final presentation = DashboardBudgetCategoryPresentation(
        categoryCollection: categories,
        onInputUpdated: inputCounts.add,
      );
      addTearDown(categories.dispose);
      addTearDown(presentation.dispose);

      expect(presentation.value.map((item) => item.id), [
        'groceries',
        'travel',
        'uncategorized',
      ]);
      expect(presentation.value[0].displayName, 'Groceries');
      expect(presentation.value[0].colorId, 'color_08');
      expect(presentation.value[0].iconId, 'icon_08');
      expect(inputCounts, [3]);
    },
  );

  test('updates only when category presentation changes', () {
    final groceries = _category(id: 'groceries');
    final categories = ValueNotifier<List<FluviCategory>>([groceries]);
    final inputCounts = <int>[];
    final presentation = DashboardBudgetCategoryPresentation(
      categoryCollection: categories,
      onInputUpdated: inputCounts.add,
    );
    addTearDown(categories.dispose);
    addTearDown(presentation.dispose);

    categories.value = [_category(id: 'groceries')];
    categories.value = [
      _category(id: 'groceries', colorId: 'color_13', updatedAtUtcMs: 2),
    ];

    expect(presentation.value.single.colorId, 'color_13');
    expect(inputCounts, [1, 1]);
  });
}

FluviCategory _category({
  required String id,
  String name = 'Groceries',
  String colorId = 'color_08',
  String iconId = 'icon_08',
  bool isSystemUncategorized = false,
  int updatedAtUtcMs = 1,
}) => FluviCategory(
  id: id,
  name: name,
  colorId: colorId,
  iconId: iconId,
  isSystemUncategorized: isSystemUncategorized,
  createdAtUtcMs: 1,
  updatedAtUtcMs: updatedAtUtcMs,
);
