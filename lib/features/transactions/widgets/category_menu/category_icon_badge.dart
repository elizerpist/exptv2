import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import '../../slots/category_color_manager.dart';
import '../category_slot_icon.dart';

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    this.category,
    this.colorSlot,
    this.iconSlot,
    this.size = 46,
    this.iconSize = 28,
    this.backgroundColor,
    this.showShadow = true,
    this.showQuestionMark = false,
  });

  final TransactionCategory? category;
  final int? colorSlot;
  final int? iconSlot;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final bool showShadow;
  final bool showQuestionMark;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        backgroundColor ??
        category?.slotColor ??
        CategoryColorManager.color(colorSlot);
    final resolvedIconSlot = iconSlot ?? category?.iconSlot;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedColor,
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: showQuestionMark
          ? Icon(Icons.question_mark, color: AppColors.white, size: iconSize)
          : CategorySlotIcon(
              slot: resolvedIconSlot,
              color: AppColors.white,
              size: iconSize,
            ),
    );
  }
}
