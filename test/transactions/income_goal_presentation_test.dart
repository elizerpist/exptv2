import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/income_goal_presentation.dart';
import 'package:exptv2/features/transactions/models/overview_budget_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('income overview goal formats missing complete surplus and no goal', () {
    final missing = IncomeGoalPresentation.fromOverview(
      overview(amount: 420000, limitAmount: 600000),
    );
    expect(missing.actualIncome, 420000);
    expect(missing.goal, 600000);
    expect(missing.hasGoal, isTrue);
    expect(missing.rawProgress, moreOrLessEquals(0.7));
    expect(missing.ringProgress, moreOrLessEquals(0.7));
    expect(missing.missing, 180000);
    expect(missing.surplus, 0);
    expect(missing.statusText, '180 000 Ft hiányzik');
    expect(missing.isComplete, isFalse);

    final complete = IncomeGoalPresentation.fromOverview(
      overview(amount: 600000, limitAmount: 600000),
    );
    expect(complete.statusText, 'Cél megvan');
    expect(complete.ringProgress, 1);
    expect(complete.isComplete, isTrue);

    final surplus = IncomeGoalPresentation.fromOverview(
      overview(amount: 750000, limitAmount: 600000),
    );
    expect(surplus.rawProgress, moreOrLessEquals(1.25));
    expect(surplus.ringProgress, 1);
    expect(surplus.surplus, 150000);
    expect(surplus.statusText, '+150 000 Ft plusz');
    expect(surplus.isComplete, isTrue);

    final noGoal = IncomeGoalPresentation.fromOverview(
      overview(amount: 420000, hasLimit: false, limitAmount: 0),
    );
    expect(noGoal.hasGoal, isFalse);
    expect(noGoal.rawProgress, 0);
    expect(noGoal.ringProgress, 0);
    expect(noGoal.statusText, 'Nincs cél');
    expect(noGoal.isComplete, isFalse);
  });

  test('income category goal uses category earned amount and goal', () {
    final presentation = IncomeGoalPresentation.fromCategory(
      categoryBar(spent: 125000, limitAmount: 200000),
    );

    expect(presentation.actualIncome, 125000);
    expect(presentation.goal, 200000);
    expect(presentation.statusText, '75 000 Ft hiányzik');
    expect(presentation.ringProgress, moreOrLessEquals(0.625));
  });
}

OverviewBudgetData overview({
  required double amount,
  required double limitAmount,
  bool hasLimit = true,
}) {
  return OverviewBudgetData(
    kind: BudgetGoalKind.incomeGoal,
    window: LimitWindow.monthly,
    periodKey: '2026-07',
    amount: amount,
    hasLimit: hasLimit,
    limitAmount: limitAmount,
    alertActive: false,
    sourceLimit: null,
  );
}

CategoryBudgetBarData categoryBar({
  required double spent,
  required double limitAmount,
  bool hasLimit = true,
}) {
  return CategoryBudgetBarData(
    key: 'category-1-income-monthly-2026-07',
    targetType: LimitTargetType.category,
    targetId: 1,
    transactionType: TransactionType.income,
    window: LimitWindow.monthly,
    periodKey: '2026-07',
    title: 'Fizetés',
    spent: spent,
    hasLimit: hasLimit,
    limitAmount: limitAmount,
    alertActive: false,
    color: const Color(0xff22c55e),
    iconSlot: null,
    category: null,
    sourceLimit: null,
  );
}
