import 'package:flutter/foundation.dart';

/// Order of the two existing Budget presentation sections. This remains
/// independent from whether their outer surface is Split or Unified.
enum BudgetSectionOrder {
  avatarsThenChart('Avatarok → diagram'),
  chartThenAvatars('Diagram → avatarok');

  const BudgetSectionOrder(this.label);
  final String label;
}

final class BudgetSectionOrderController
    extends ValueNotifier<BudgetSectionOrder> {
  BudgetSectionOrderController() : super(BudgetSectionOrder.avatarsThenChart);

  void select(BudgetSectionOrder order) {
    if (value != order) value = order;
  }

  void reset() => select(BudgetSectionOrder.avatarsThenChart);
}
