import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
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
    this.visible = true,
    this.surfaceColor = AppColors.white,
    this.bodySurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.buttonSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.selectedSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
  });

  final TransactionType activeType;
  final TransactionCategory? initialCategory;
  final double? panelHeight;
  final bool visible;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction bodySurfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
  final Color accentColor;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory>? onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SlideUpMenuCard(
      cardKey: const ValueKey('category-editor-slide-card'),
      debugLabel: initialCategory == null ? 'AddCategory' : 'EditCategory',
      panelHeight: panelHeight,
      visible: visible,
      keyboardAvoidance: true,
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
          surfaceColor: surfaceColor,
          bodySurfaceStyle: bodySurfaceStyle,
          buttonSurfaceStyle: buttonSurfaceStyle,
          selectedSurfaceStyle: selectedSurfaceStyle,
          accentColor: accentColor,
        ),
      ),
    );
  }
}
