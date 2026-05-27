import 'package:flutter/material.dart';

import '../../models/transaction_category.dart';
import '../transaction_menu_metrics.dart';
import 'category_editor_panel.dart';

class CategoryEditorSheet extends StatelessWidget {
  const CategoryEditorSheet({
    super.key,
    required this.activeType,
    required this.onSave,
    required this.onClose,
    this.initialCategory,
    this.onDelete,
  });

  final TransactionType activeType;
  final TransactionCategory? initialCategory;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory>? onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cardHeight = screenHeight - TransactionMenuMetrics.overlayTop;
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('category-editor-slide-card'),
        height: cardHeight,
        width: double.infinity,
        child: CategoryEditorPanel(
          activeType: activeType,
          initialCategory: initialCategory,
          onSave: onSave,
          onDelete: onDelete,
          onClose: onClose,
        ),
      ),
    );
  }
}
