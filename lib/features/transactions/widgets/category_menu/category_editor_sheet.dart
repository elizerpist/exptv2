import 'package:flutter/material.dart';

import '../../models/transaction_category.dart';
import '../slide_up_menu_card.dart';
import 'category_editor_panel.dart';

class CategoryEditorSheet extends StatelessWidget {
  const CategoryEditorSheet({
    super.key,
    required this.activeType,
    required this.onSave,
    required this.onClose,
    this.initialCategory,
    this.onDelete,
    this.panelHeight,
  });

  final TransactionType activeType;
  final TransactionCategory? initialCategory;
  final double? panelHeight;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory>? onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SlideUpMenuCard(
      cardKey: const ValueKey('category-editor-slide-card'),
      debugLabel: initialCategory == null ? 'AddCategory' : 'EditCategory',
      panelHeight: panelHeight,
      onDismissed: onClose,
      child: SafeArea(
        top: false,
        bottom: false,
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
