import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import 'category_card.dart';

class CategoryMenuPanel extends StatelessWidget {
  const CategoryMenuPanel({
    super.key,
    required this.activeType,
    required this.categories,
    required this.categoryTransactionCounts,
    required this.activeCategory,
    required this.onSelect,
    required this.onModify,
    required this.onDelete,
    required this.onAdd,
    required this.onClose,
  });

  final TransactionType activeType;
  final List<TransactionCategory> categories;
  final Map<int, int> categoryTransactionCounts;
  final TransactionCategory? activeCategory;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onDelete;
  final VoidCallback onAdd;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final filtered = categories
        .where((category) => category.normalizedType == activeType)
        .toList();
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 12,
                child: IconButton(
                  key: const ValueKey('category-menu-back-button'),
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back, color: AppColors.gray500),
                  splashRadius: 22,
                ),
              ),
              const Text(
                'Válassz kategóriát',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              Positioned(
                right: 12,
                child: IconButton(
                  key: const ValueKey('category-add-button'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, color: AppColors.gray500),
                  splashRadius: 22,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 14,
              mainAxisExtent: 150,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final category = filtered[index];
              final count =
                  categoryTransactionCounts[category.transactionCategoryID] ??
                  0;
              return CategoryCard(
                category: category,
                transactionCount: count,
                active:
                    activeCategory?.transactionCategoryID ==
                    category.transactionCategoryID,
                onSelect: onSelect,
                onModify: onModify,
                onDelete: onDelete,
              );
            },
          ),
        ),
      ],
    );
  }
}
