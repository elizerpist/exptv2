import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'category_budget_bar_data.dart';
import 'overview_budget_data.dart';
import 'transaction_record.dart';

class IncomeGoalPresentation {
  const IncomeGoalPresentation({
    required this.actualIncome,
    required this.goal,
    required this.hasGoal,
    required this.progressColor,
  });

  factory IncomeGoalPresentation.fromOverview(OverviewBudgetData overview) {
    return IncomeGoalPresentation(
      actualIncome: overview.amount,
      goal: overview.hasLimit ? overview.limitAmount : 0,
      hasGoal: overview.hasLimit && overview.limitAmount > 0,
      progressColor: AppColors.income,
    );
  }

  factory IncomeGoalPresentation.fromCategory(CategoryBudgetBarData category) {
    return IncomeGoalPresentation(
      actualIncome: category.spent,
      goal: category.hasLimit ? category.limitAmount : 0,
      hasGoal: category.hasLimit && category.limitAmount > 0,
      progressColor: category.color,
    );
  }

  final double actualIncome;
  final double goal;
  final bool hasGoal;
  final Color progressColor;

  double get rawProgress {
    if (!hasGoal || goal <= 0) return 0;
    return actualIncome / goal;
  }

  double get ringProgress => rawProgress.clamp(0.0, 1.0).toDouble();

  double get missing {
    if (!hasGoal) return 0;
    return (goal - actualIncome).clamp(0.0, double.infinity).toDouble();
  }

  double get surplus {
    if (!hasGoal) return 0;
    return (actualIncome - goal).clamp(0.0, double.infinity).toDouble();
  }

  bool get isComplete => hasGoal && actualIncome >= goal;

  Color get effectiveProgressColor {
    if (!hasGoal) return progressColor;
    return isComplete ? AppColors.income : progressColor;
  }

  String get statusText {
    if (!hasGoal) return 'Nincs cél';
    if (actualIncome < goal) return '${formatHuf(missing)} hiányzik';
    if (actualIncome > goal) return '+${formatHuf(surplus)} plusz';
    return 'Cél megvan';
  }

  String get amountText {
    final formattedActual = formatHuf(actualIncome);
    if (!hasGoal) return formattedActual;
    return '$formattedActual / ${formatHuf(goal)} cél';
  }
}
