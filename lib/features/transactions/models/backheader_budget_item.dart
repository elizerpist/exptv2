import 'category_budget_bar_data.dart';
import 'overview_budget_data.dart';

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
  String get amountText => overview?.displayAmount ?? _categoryAmount(category!);

  static String _categoryAmount(CategoryBudgetBarData bar) {
    return bar.hasLimit
        ? '${bar.formattedSpent} / ${bar.formattedLimit}'
        : bar.formattedSpent;
  }
}
