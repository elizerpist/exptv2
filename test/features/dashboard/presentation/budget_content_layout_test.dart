import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Budget content layout exposes only Split and Unified Card', () {
    expect(BudgetContentLayout.values, const <BudgetContentLayout>[
      BudgetContentLayout.split,
      BudgetContentLayout.unifiedCard,
    ]);

    final controller = BudgetContentCardStyleController();
    addTearDown(controller.dispose);
    expect(controller.value, BudgetContentLayout.split);
    controller.select(BudgetContentLayout.unifiedCard);
    expect(controller.value, BudgetContentLayout.unifiedCard);
  });
}
