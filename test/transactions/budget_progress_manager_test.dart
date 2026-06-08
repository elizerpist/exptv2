import 'package:exptv2/features/transactions/data/budget_progress_manager.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense overview progress includes only categories with spending', () {
    final bars = [
      barFixture(6, 'Food', 50, const Color(0xffef4444)),
      barFixture(7, 'Travel', 25, const Color(0xff22c55e)),
      barFixture(8, 'Unused', 0, const Color(0xff3b82f6)),
    ];

    final progress = BudgetProgressManager.overviewProgress(
      kind: BudgetGoalKind.expenseBudget,
      limitAmount: 100,
      categoryBars: bars,
      periodIncome: 0,
      periodExpense: 75,
    );

    expect(progress.hasLimit, isTrue);
    expect(progress.ratio, 0.75);
    expect(progress.remainingFraction, 0.25);
    expect(progress.segments, hasLength(2));
    expect(progress.segments[0].amount, 50);
    expect(progress.segments[0].fraction, 0.5);
    expect(progress.segments[1].amount, 25);
    expect(progress.segments[1].fraction, 0.25);
  });

  test(
    'income goal uses income category bars and treats full progress as success',
    () {
      final bars = [
        barFixture(
          5,
          'Salary',
          600,
          const Color(0xff06b6d4),
          type: TransactionType.income,
        ),
        barFixture(
          9,
          'Bonus',
          200,
          const Color(0xffa855f7),
          type: TransactionType.income,
        ),
        barFixture(
          10,
          'Unused',
          0,
          const Color(0xfff97316),
          type: TransactionType.income,
        ),
      ];

      final progress = BudgetProgressManager.overviewProgress(
        kind: BudgetGoalKind.incomeGoal,
        limitAmount: 800,
        categoryBars: bars,
        periodIncome: 800,
        periodExpense: 0,
      );

      expect(progress.ratio, 1);
      expect(progress.isSuccess, isTrue);
      expect(progress.isWarning, isFalse);
      expect(progress.isDanger, isFalse);
      expect(progress.segments.map((segment) => segment.amount), [600, 200]);
    },
  );

  test(
    'saving goal uses income minus expense and clamps negative balance to zero',
    () {
      final positive = BudgetProgressManager.overviewProgress(
        kind: BudgetGoalKind.savingGoal,
        limitAmount: 200,
        categoryBars: const [],
        periodIncome: 900,
        periodExpense: 750,
      );
      final negative = BudgetProgressManager.overviewProgress(
        kind: BudgetGoalKind.savingGoal,
        limitAmount: 200,
        categoryBars: const [],
        periodIncome: 100,
        periodExpense: 150,
      );

      expect(positive.amount, 150);
      expect(positive.ratio, 0.75);
      expect(positive.segments, hasLength(1));
      expect(negative.amount, 0);
      expect(negative.ratio, 0);
      expect(negative.segments, isEmpty);
    },
  );

  test('category max excludes the currently edited category', () {
    final current = barFixture(
      6,
      'Food',
      25,
      const Color(0xffef4444),
      limit: 50,
    );
    final other = barFixture(
      7,
      'Travel',
      0,
      const Color(0xff22c55e),
      limit: 25,
    );

    expect(
      BudgetProgressManager.availableCategoryLimit(
        overviewLimit: 100,
        categoryBars: [current, other],
        activeBar: current,
      ),
      75,
    );
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title,
  double spent,
  Color color, {
  double limit = 0,
  TransactionType type = TransactionType.expense,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': type.hungarianValue,
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': false,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: type,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    color: color,
    iconSlot: 2,
    category: category,
    sourceLimit: null,
  );
}
