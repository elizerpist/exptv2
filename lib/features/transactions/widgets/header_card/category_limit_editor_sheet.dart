import 'package:flutter/material.dart';

import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/category_budget_bar_data.dart';
import 'budget_target_editor_sheet.dart';

typedef CategoryLimitSave =
    Future<void> Function({
      required double limitAmount,
      required bool alertActive,
    });

class CategoryLimitEditorSheet extends StatelessWidget {
  const CategoryLimitEditorSheet({
    super.key,
    required this.bar,
    required this.onCancel,
    required this.onSave,
    this.allBars = const [],
  });

  final CategoryBudgetBarData bar;
  final List<CategoryBudgetBarData> allBars;
  final VoidCallback onCancel;
  final CategoryLimitSave onSave;

  @override
  Widget build(BuildContext context) {
    return BudgetTargetEditorSheet(
      item: BackheaderBudgetItem.category(bar),
      categoryBars: allBars.isEmpty ? [bar] : allBars,
      periodIncome: 0,
      onCancel: onCancel,
      onSaveOverview: (
        BudgetGoalKind kind, {
        required double limitAmount,
        required bool alertActive,
      }) async {},
      onSaveCategory: (
        CategoryBudgetBarData categoryBar, {
        required double limitAmount,
        required bool alertActive,
      }) async {
        await onSave(
          limitAmount: limitAmount,
          alertActive: alertActive,
        );
      },
    );
  }
}
