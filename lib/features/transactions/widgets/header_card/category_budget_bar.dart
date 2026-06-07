import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/category_budget_bar_data.dart';
import '../../slots/category_icon_manager.dart';
import 'budget_bar_geometry.dart';
import 'category_progress_bar.dart';

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
    final remainingRatio = bar.hasLimit && bar.limitAmount > 0
        ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
        : 1.0;
    final iconSize = height * 0.65;
    final iconLeftPadding = height * 0.28;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = BudgetBarGeometry.visibleWidth(
          availableWidth: constraints.maxWidth,
          height: height,
          ratio: remainingRatio,
        );
        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              SizedBox(
                key: const ValueKey('category-budget-background'),
                width: constraints.maxWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: Material(
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
                        child: ColoredBox(
                          key: const ValueKey('category-budget-remaining-fill'),
                          color: bar.color,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: iconLeftPadding,
                                  ),
                                  child: Image(
                                    image: CategoryIconManager.assetImage(
                                      bar.iconSlot,
                                    ),
                                    width: compactIcon
                                        ? iconSize
                                        : height * 0.64,
                                    height: compactIcon
                                        ? iconSize
                                        : height * 0.64,
                                    color: AppColors.white,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.category_outlined,
                                          color: AppColors.white,
                                          size: compactIcon
                                              ? iconSize
                                              : height * 0.64,
                                        ),
                                  ),
                                ),
                              ),
                              if (bar.hasLimit)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 12,
                                  child: CategoryProgressBar(
                                    spent: bar.spent,
                                    limitAmount: bar.limitAmount,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
