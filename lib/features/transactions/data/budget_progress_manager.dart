import 'package:flutter/material.dart';

import '../models/budget_goal_kind.dart';
import '../models/budget_progress_segment.dart';
import '../models/category_budget_bar_data.dart';

class BudgetProgressManager {
  static const savingColor = Color(0xff10b981);

  static BudgetProgressData overviewProgress({
    required BudgetGoalKind kind,
    required double limitAmount,
    required List<CategoryBudgetBarData> categoryBars,
    required double periodIncome,
    required double periodExpense,
  }) {
    final hasLimit = limitAmount > 0;
    if (!hasLimit) {
      return const BudgetProgressData(
        hasLimit: false,
        amount: 0,
        limitAmount: 0,
        ratio: 0,
        segments: [],
      );
    }

    final amount = switch (kind) {
      BudgetGoalKind.expenseBudget => periodExpense,
      BudgetGoalKind.incomeGoal => periodIncome,
      BudgetGoalKind.savingGoal => (periodIncome - periodExpense)
          .clamp(0.0, double.infinity)
          .toDouble(),
    };

    final segments = kind == BudgetGoalKind.savingGoal
        ? _savingSegments(amount: amount, limitAmount: limitAmount)
        : _categorySegments(categoryBars, limitAmount);

    return BudgetProgressData(
      hasLimit: true,
      amount: amount,
      limitAmount: limitAmount,
      ratio: amount / limitAmount,
      segments: segments,
      warnsWhenHigh: kind.warnsWhenHigh,
    );
  }

  static double availableCategoryLimit({
    required double overviewLimit,
    required List<CategoryBudgetBarData> categoryBars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return 0;
    final usedByOthers = categoryBars
        .where((bar) => !_sameTarget(bar, activeBar))
        .where((bar) => bar.hasLimit && bar.limitAmount > 0)
        .fold<double>(0, (sum, bar) => sum + bar.limitAmount);
    return (overviewLimit - usedByOthers)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  static List<BudgetProgressSegment> _categorySegments(
    List<CategoryBudgetBarData> bars,
    double limitAmount,
  ) {
    if (limitAmount <= 0) return const [];
    return bars
        .where((bar) => bar.spent > 0)
        .map(
          (bar) => BudgetProgressSegment(
            amount: bar.spent,
            fraction: (bar.spent / limitAmount).clamp(0.0, 1.0).toDouble(),
            color: bar.color,
          ),
        )
        .toList();
  }

  static List<BudgetProgressSegment> _savingSegments({
    required double amount,
    required double limitAmount,
  }) {
    if (amount <= 0 || limitAmount <= 0) return const [];
    return [
      BudgetProgressSegment(
        amount: amount,
        fraction: (amount / limitAmount).clamp(0.0, 1.0).toDouble(),
        color: savingColor,
      ),
    ];
  }

  static bool _sameTarget(
    CategoryBudgetBarData left,
    CategoryBudgetBarData right,
  ) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }
}
