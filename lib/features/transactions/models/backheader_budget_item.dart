import 'category_budget_bar_data.dart';
import 'budget_goal_kind.dart';
import 'income_goal_presentation.dart';
import 'overview_budget_data.dart';
import 'transaction_category.dart';

enum BackheaderBudgetItemKind { overview, category }

class BackheaderBudgetItem {
  const BackheaderBudgetItem._({
    required this.kind,
    this.overview,
    this.category,
  });

  factory BackheaderBudgetItem.overview(OverviewBudgetData data) {
    return BackheaderBudgetItem._(
      kind: BackheaderBudgetItemKind.overview,
      overview: data,
    );
  }

  factory BackheaderBudgetItem.category(CategoryBudgetBarData data) {
    return BackheaderBudgetItem._(
      kind: BackheaderBudgetItemKind.category,
      category: data,
    );
  }

  final BackheaderBudgetItemKind kind;
  final OverviewBudgetData? overview;
  final CategoryBudgetBarData? category;

  String get key => overview?.key ?? category!.key;
  String get title => overview?.title ?? category!.title;
  String get amountText {
    final overviewData = overview;
    if (overviewData != null) {
      if (overviewData.kind == BudgetGoalKind.incomeGoal) {
        return IncomeGoalPresentation.fromOverview(overviewData).amountText;
      }
      return overviewData.displayAmount;
    }
    final categoryData = category!;
    if (categoryData.transactionType == TransactionType.income) {
      return IncomeGoalPresentation.fromCategory(categoryData).amountText;
    }
    return _categoryAmount(categoryData);
  }

  static String _categoryAmount(CategoryBudgetBarData bar) {
    return bar.hasLimit
        ? '${bar.formattedSpent} / ${bar.formattedLimit}'
        : bar.formattedSpent;
  }
}
