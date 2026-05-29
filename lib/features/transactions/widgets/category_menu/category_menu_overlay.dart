import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../models/transaction_category.dart';
import '../../state/transaction_store.dart';
import '../transaction_menu_metrics.dart';
import 'category_menu_panel.dart';

enum CategoryOverlayMode { picker }

class CategoryMenuOverlay extends StatelessWidget {
  const CategoryMenuOverlay({
    super.key,
    required this.store,
    required this.onClose,
    required this.onAdd,
    required this.onModify,
    required this.onSelect,
    required this.onDelete,
    this.top = TransactionMenuMetrics.overlayTop,
    this.bottom = AppDimensions.bottomNavHeight,
    this.activeType,
    this.activeCategory,
  });

  final TransactionStore store;
  final VoidCallback onClose;
  final VoidCallback onAdd;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onDelete;
  final double top;
  final double bottom;
  final TransactionType? activeType;
  final TransactionCategory? activeCategory;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: bottom,
      child: Material(
        key: const ValueKey('category-menu-overlay'),
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppColors.gray200),
          ),
          child: CategoryMenuPanel(
            key: const ValueKey('category-picker-panel'),
            activeType: activeType ?? store.activeType,
            categories: store.categories,
            categoryTransactionCounts: store.categoryTransactionCounts,
            activeCategory: activeCategory ?? store.activeCategory,
            onSelect: onSelect,
            onModify: onModify,
            onDelete: onDelete,
            onAdd: onAdd,
            onClose: onClose,
          ),
        ),
      ),
    );
  }
}
