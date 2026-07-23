enum BudgetGoalKind { expenseBudget, incomeGoal, savingGoal }

extension BudgetGoalKindX on BudgetGoalKind {
  String get key => switch (this) {
    BudgetGoalKind.expenseBudget => 'expense_budget',
    BudgetGoalKind.incomeGoal => 'income_goal',
    BudgetGoalKind.savingGoal => 'saving_goal',
  };

  String get title => switch (this) {
    BudgetGoalKind.expenseBudget => 'Budget',
    BudgetGoalKind.incomeGoal => 'Összbevételi cél',
    BudgetGoalKind.savingGoal => 'Megtakaritas',
  };

  String get transactionType => switch (this) {
    BudgetGoalKind.expenseBudget => 'expense',
    BudgetGoalKind.incomeGoal => 'income',
    BudgetGoalKind.savingGoal => 'saving',
  };

  bool get usesCategorySegments => this != BudgetGoalKind.savingGoal;
  bool get warnsWhenHigh => this == BudgetGoalKind.expenseBudget;
}
