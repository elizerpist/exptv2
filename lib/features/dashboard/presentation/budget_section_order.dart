import 'package:flutter/foundation.dart';

/// Order of the two existing Budget presentation sections. This remains
/// independent from whether their outer surface is Split or Unified.
enum BudgetSectionOrder {
  avatarsThenChart('Avatarok → diagram'),
  chartThenAvatars('Diagram → avatarok');

  const BudgetSectionOrder(this.label);
  final String label;

  /// The selected avatar's interactive/painted shell is 40px taller than
  /// the authored 72px structural rail. When that shell follows the chart it
  /// needs this exact extra tail before the page dots and downstream LogBox
  /// geometry; the avatars-first baseline already consumes the overflow above
  /// the chart heading.
  static const double chartThenAvatarsExtraModeContentHeight = 40;
}

final class BudgetSectionOrderController
    extends ValueNotifier<BudgetSectionOrder> {
  BudgetSectionOrderController() : super(BudgetSectionOrder.avatarsThenChart);

  void select(BudgetSectionOrder order) {
    if (value != order) value = order;
  }

  void reset() => select(BudgetSectionOrder.avatarsThenChart);
}
