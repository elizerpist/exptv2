import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/category_budget_bar_data.dart';
import '../category_slot_icon.dart';
import 'budget_bar_geometry.dart';
import 'category_progress_bar.dart';

class CategoryBudgetBar extends StatelessWidget {
  const CategoryBudgetBar({
    super.key,
    required this.bar,
    required this.onTap,
    this.compactIcon = false,
    this.height = 70,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.surfaceIndex = 0,
  });

  final CategoryBudgetBarData bar;
  final VoidCallback onTap;
  final bool compactIcon;
  final double height;
  final ExpenseSurfaceInteraction surfaceStyle;
  final int surfaceIndex;

  @override
  Widget build(BuildContext context) {
    final spentRatio = bar.hasLimit && bar.limitAmount > 0
        ? (bar.spent / bar.limitAmount).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final remainingRatio = bar.hasLimit && bar.limitAmount > 0
        ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
        : 1.0;
    final iconSize = height * 0.65;
    final iconLeftPadding = height * 0.28;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = BudgetBarGeometry.visibleWidth(
          availableWidth: constraints.maxWidth,
          height: height,
          ratio: remainingRatio,
        );
        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              SizedBox(
                key: const ValueKey('category-budget-background'),
                width: constraints.maxWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: _buildFill(iconSize, iconLeftPadding),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFill(double iconSize, double iconLeftPadding) {
    final radius = BorderRadius.circular(height / 2);
    if (surfaceStyle.hasPressEffect) {
      return ExpensePressable(
        enabled: true,
        builder: (context, pressed) {
          return GestureDetector(
            key: const ValueKey('category-budget-bar'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ExpenseSurfaceContainer(
              surfaceKey: ValueKey('backheader-bar-surface-$surfaceIndex'),
              style: surfaceStyle,
              color: bar.color,
              primary: true,
              primaryColor: bar.color,
              borderRadius: radius,
              pressed: pressed,
              height: height,
              child: _BarContent(
                bar: bar,
                height: height,
                compactIcon: compactIcon,
                iconSize: iconSize,
                iconLeftPadding: iconLeftPadding,
              ),
            ),
          );
        },
      );
    }
    return Material(
      key: const ValueKey('category-budget-bar'),
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: ColoredBox(
              key: const ValueKey('category-budget-remaining-fill'),
              color: bar.color,
              child: _BarContent(
                bar: bar,
                height: height,
                compactIcon: compactIcon,
                iconSize: iconSize,
                iconLeftPadding: iconLeftPadding,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarContent extends StatelessWidget {
  const _BarContent({
    required this.bar,
    required this.height,
    required this.compactIcon,
    required this.iconSize,
    required this.iconLeftPadding,
  });

  final CategoryBudgetBarData bar;
  final double height;
  final bool compactIcon;
  final double iconSize;
  final double iconLeftPadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: iconLeftPadding),
            child: CategorySlotIcon(
              slot: bar.iconSlot,
              color: AppColors.white,
              size: compactIcon ? iconSize : height * 0.64,
            ),
          ),
        ),
        if (bar.hasLimit)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: CategoryProgressBar(
              spent: bar.spent,
              limitAmount: bar.limitAmount,
            ),
          ),
      ],
    );
  }
}
