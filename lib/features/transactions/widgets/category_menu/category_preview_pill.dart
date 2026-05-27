import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../slots/category_color_manager.dart';
import 'category_icon_badge.dart';

class CategoryPreviewPill extends StatelessWidget {
  const CategoryPreviewPill({
    super.key,
    required this.name,
    required this.colorSlot,
    required this.iconSlot,
  });

  final String name;
  final int colorSlot;
  final int iconSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          CategoryIconBadge(
            colorSlot: colorSlot,
            iconSlot: iconSlot,
            backgroundColor: CategoryColorManager.color(colorSlot),
            size: 46,
            iconSize: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.trim().isEmpty ? 'Kategória neve' : name.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
