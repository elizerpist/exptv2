import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import '../../slots/category_color_manager.dart';
import '../../slots/category_icon_manager.dart';

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    this.category,
    this.colorSlot,
    this.iconSlot,
    this.size = 46,
    this.iconSize = 28,
    this.backgroundColor,
  });

  final TransactionCategory? category;
  final int? colorSlot;
  final int? iconSlot;
  final double size;
  final double iconSize;
  final Color? backgroundColor;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ImageIcon(
        CategoryIconManager.assetImage(resolvedIconSlot),
        color: AppColors.white,
        size: iconSize,
      ),
    );
  }
}
