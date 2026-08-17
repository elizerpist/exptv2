import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'maps the authoritative category collection after the aggregate in its order',
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
      final harness = _PresentationHarness(categories, inputCounts.add);
      addTearDown(harness.dispose);

      expect(harness.presentation.value.items.map((item) => item.stableId), [
        'aggregate',
        'category:groceries',
        'category:travel',
        'category:uncategorized',
      ]);
      expect(harness.presentation.value.items[1].title, 'Groceries');
      expect(harness.presentation.value.items[1].colorId, 'color_08');
      expect(harness.presentation.value.items[1].iconId, 'icon_08');
      expect(inputCounts, [3]);
    },
  );

  test(
    'updates category visuals without treating direction as category input',
    () {
      final groceries = _category(id: 'groceries');
      final categories = ValueNotifier<List<FluviCategory>>([groceries]);
      final inputCounts = <int>[];
      final harness = _PresentationHarness(categories, inputCounts.add);
      addTearDown(harness.dispose);

      categories.value = [_category(id: 'groceries')];
      categories.value = [
        _category(id: 'groceries', colorId: 'color_13', updatedAtUtcMs: 2),
      ];
      harness.direction.select(TransactionDirection.income);

      expect(harness.presentation.value.items[1].colorId, 'color_13');
      expect(harness.presentation.value.items.first.title, 'Összbevételi cél');
      expect(inputCounts, [1, 1]);
    },
  );
}

final class _PresentationHarness {
  _PresentationHarness(this.categories, ValueChanged<int> onInputUpdated)
    : visibleFrame = ValueNotifier<DashboardVisibleFrame?>(null),
      direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      ) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visibleFrame,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => null,
      onInputUpdated: onInputUpdated,
    );
  }

  final ValueNotifier<List<FluviCategory>> categories;
  final ValueNotifier<DashboardVisibleFrame?> visibleFrame;
  final TransactionDirectionController direction;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    visibleFrame.dispose();
    direction.dispose();
    categories.dispose();
  }
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
