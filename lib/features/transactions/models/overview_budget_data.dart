import 'budget_goal_kind.dart';
import 'category_limit.dart';
import 'transaction_record.dart';

class OverviewBudgetData {
  const OverviewBudgetData({
    required this.kind,
    required this.window,
    required this.periodKey,
    required this.amount,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.sourceLimit,
  });

  final BudgetGoalKind kind;
  final LimitWindow window;
  final String periodKey;
  final double amount;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final CategoryLimit? sourceLimit;

  String get key => 'overview-${kind.key}-${window.nativeValue}-$periodKey';
  String get title => kind.title;
  String get formattedAmount => formatHuf(amount);
  String get formattedLimit => formatHuf(limitAmount);
  String get displayAmount =>
      hasLimit ? '$formattedAmount / $formattedLimit' : formattedAmount;
}
