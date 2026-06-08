import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../slots/category_color_manager.dart';
import 'category_icon_badge.dart';

class CategoryPreviewPill extends StatelessWidget {
  const CategoryPreviewPill({
    super.key,
    required this.name,
    required this.colorSlot,
    required this.iconSlot,
    this.surfaceColor = AppColors.white,
    this.bodySurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final String name;
  final int colorSlot;
  final int iconSlot;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction bodySurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;

  @override
  Widget build(BuildContext context) {
    return ExpenseSurfaceContainer(
      surfaceKey: const ValueKey('category-preview-pill-surface'),
      style: bodySurfaceStyle,
      color: surfaceColor,
      borderRadius: BorderRadius.circular(25),
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      neutralBorder: Border.all(color: AppColors.gray200),
      neutralShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
      ],
      child: Row(
        children: [
          ExpenseSurfaceContainer(
            surfaceKey: const ValueKey('category-preview-avatar-surface'),
            style: avatarSurfaceStyle,
            color: CategoryColorManager.color(colorSlot),
            primary: true,
            primaryColor: CategoryColorManager.color(colorSlot),
            borderRadius: BorderRadius.circular(23),
            width: 46,
            height: 46,
            child: CategoryIconBadge(
              colorSlot: colorSlot,
              iconSlot: iconSlot,
              backgroundColor: Colors.transparent,
              showShadow: false,
              size: 46,
              iconSize: 32,
            ),
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
