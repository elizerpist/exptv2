import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/category_budget_bar_data.dart';
import '../../slots/category_icon_manager.dart';
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
    final amountText = bar.hasLimit
        ? '${bar.formattedSpent} / ${bar.formattedLimit}'
        : bar.formattedSpent;
    return Material(
      key: const ValueKey('category-budget-bar'),
      color: bar.color,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.white),
          ),
          padding: const EdgeInsets.only(left: 15, right: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Image(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: bar.hasLimit ? 41 : 8,
                        top: bar.hasLimit ? 0 : 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              bar.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              amountText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (bar.hasLimit)
                Positioned(
                  left: compactIcon ? 60 : 45,
                  right: compactIcon ? 47 : 43,
                  bottom: 22,
                  child: CategoryProgressBar(
                    spent: bar.spent,
                    limitAmount: bar.limitAmount,
                  ),
                ),
              if (bar.hasLimit)
                Positioned(
                  right: -5,
                  top: 14,
                  child: Icon(
                    bar.alertActive
                        ? Icons.notifications
                        : Icons.notifications_none_outlined,
                    color: AppColors.white,
                    size: compactIcon ? 25 : 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
