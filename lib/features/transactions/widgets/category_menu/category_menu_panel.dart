import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
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
    this.surfaceColor = AppColors.white,
    this.cardSurfaceColor = AppColors.white,
    this.cardSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
    this.activeBackgroundColor = AppColors.primaryActiveBackground,
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
  final Color surfaceColor;
  final Color cardSurfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final Color accentColor;
  final Color activeBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final filtered = categories
        .where((category) => category.normalizedType == activeType)
        .toList();
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(
              height: 54,
              child: Center(
                child: Text(
                  'Válassz kategóriát',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
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
                      categoryTransactionCounts[category
                          .transactionCategoryID] ??
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
                    surfaceColor: cardSurfaceColor,
                    cardSurfaceStyle: cardSurfaceStyle,
                    avatarSurfaceStyle: avatarSurfaceStyle,
                    accentColor: accentColor,
                    activeBackgroundColor: activeBackgroundColor,
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 16,
          child: FloatingActionButton.small(
            key: const ValueKey('category-menu-add-button'),
            heroTag: null,
            tooltip: 'Új kategória',
            onPressed: onAdd,
            backgroundColor: accentColor,
            foregroundColor: AppColors.white,
            elevation: 3,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}
