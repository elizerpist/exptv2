import 'package:flutter/material.dart';

import '../../models/transaction_category.dart';
import '../../state/transaction_store.dart';
import 'category_editor_panel.dart';
import 'category_menu_panel.dart';

enum CategoryOverlayMode { picker, add, modify }

class CategoryMenuOverlay extends StatelessWidget {
  const CategoryMenuOverlay({
    super.key,
    required this.store,
    required this.mode,
    required this.onClose,
    required this.onAdd,
    required this.onModify,
    required this.onSelect,
    required this.onSave,
    required this.onDelete,
    this.editingCategory,
  });

  final TransactionStore store;
  final CategoryOverlayMode mode;
  final TransactionCategory? editingCategory;
  final VoidCallback onClose;
  final VoidCallback onAdd;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('category-menu-overlay'),
      top: 286,
      left: 0,
      right: 0,
      bottom: 5,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: switch (mode) {
          CategoryOverlayMode.picker => CategoryMenuPanel(
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
          CategoryOverlayMode.add => CategoryEditorPanel(
            key: const ValueKey('category-add-panel'),
            activeType: store.activeType,
            onSave: onSave,
            onClose: onClose,
          ),
          CategoryOverlayMode.modify => CategoryEditorPanel(
            key: ValueKey(
              'category-modify-panel-${editingCategory?.transactionCategoryID ?? 0}',
            ),
            activeType: store.activeType,
            initialCategory: editingCategory,
            onSave: onSave,
            onDelete: onDelete,
            onClose: onClose,
          ),
        },
      ),
    );
  }
}
