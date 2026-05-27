import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../app_tab.dart';

class BottomNavItem extends StatelessWidget {
  const BottomNavItem({
    super.key,
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : tab.inactiveColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.navItemHorizontalMargin,
        ),
        child: Material(
          color: active
              ? AppColors.primaryActiveBackground
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.navItemRadius),
          child: InkWell(
            key: ValueKey('bottom-nav-${tab.id}'),
            borderRadius: BorderRadius.circular(AppDimensions.navItemRadius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.navItemVerticalPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tab.icon, size: AppDimensions.navIconSize, color: color),
                  const SizedBox(height: AppDimensions.navLabelTopMargin),
                  Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
