import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/category_budget_bar_data.dart';
import '../../slots/category_icon_manager.dart';

class CategoryBudgetBar extends StatelessWidget {
  const CategoryBudgetBar({
    super.key,
    required this.bar,
    required this.onTap,
    this.compactIcon = false,
    this.height = 70,
  });

  final CategoryBudgetBarData bar;
  final VoidCallback onTap;
  final bool compactIcon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final spentRatio = bar.hasLimit && bar.limitAmount > 0
        ? (bar.spent / bar.limitAmount).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Material(
      key: const ValueKey('category-budget-bar'),
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(height / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  key: const ValueKey('category-budget-remaining-fill'),
                  color: bar.color,
                ),
                if (spentRatio > 0)
                  FractionallySizedBox(
                    key: const ValueKey('category-budget-spent-overlay'),
                    widthFactor: spentRatio,
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(color: bar.color.withValues(alpha: 0.30)),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Image(
                      image: CategoryIconManager.assetImage(bar.iconSlot),
                      width: compactIcon ? 35 : 45,
                      height: compactIcon ? 35 : 45,
                      color: AppColors.white,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category_outlined,
                        color: AppColors.white,
                        size: compactIcon ? 35 : 45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
