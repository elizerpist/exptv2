import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import 'category_icon_badge.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    required this.onSelect,
    required this.onModify,
    required this.onDelete,
    this.active = false,
  });

  final TransactionCategory category;
  final int transactionCount;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onDelete;
  final bool active;

  bool get _hasTransactions => transactionCount > 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: active
                  ? AppColors.primaryActiveBackground
                  : AppColors.gray50,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                key: ValueKey(
                  'category-card-${category.transactionCategoryID}',
                ),
                onTap: () => onSelect(category),
                onLongPress: () => onModify(category),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 85, 12, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.gray200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        category.name,
                        key: ValueKey(
                          'category-card-title-${category.transactionCategoryID}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$transactionCount tranzakció',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                key: ValueKey(
                  'category-icon-${category.transactionCategoryID}',
                ),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(category),
                onLongPress: () => onModify(category),
                child: CategoryIconBadge(
                  category: category,
                  size: 65,
                  iconSize: 44,
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              key: ValueKey(
                'category-delete-${category.transactionCategoryID}',
              ),
              onTap: _hasTransactions ? null : () => onDelete(category),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _hasTransactions
                      ? AppColors.gray500.withValues(alpha: 0.3)
                      : AppColors.expense.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
