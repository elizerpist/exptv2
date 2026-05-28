import 'package:flutter/material.dart';

import '../../models/transaction_category.dart';
import '../../state/transaction_store.dart';
import '../slide_up_menu_card.dart';
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
  });

  final TransactionStore store;
  final VoidCallback onClose;
  final VoidCallback onAdd;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TransactionMenuMetrics.overlayTop,
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideUpMenuCard(
        cardKey: const ValueKey('category-menu-overlay'),
        onDismissed: onClose,
        child: CategoryMenuPanel(
          key: const ValueKey('category-picker-panel'),
          activeType: store.activeType,
          categories: store.categories,
          categoryTransactionCounts: store.categoryTransactionCounts,
          activeCategory: store.activeCategory,
          onSelect: onSelect,
          onModify: onModify,
          onDelete: onDelete,
          onAdd: onAdd,
          onClose: onClose,
        ),
      ),
    );
  }
}
