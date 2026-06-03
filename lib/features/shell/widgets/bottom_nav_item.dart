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
    this.onPointerDown,
    this.badgeCount = 0,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onPointerDown;
  final int badgeCount;

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
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => onPointerDown?.call(),
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
                    SizedBox(
                      width: 34,
                      height: AppDimensions.navIconSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            tab.icon,
                            size: AppDimensions.navIconSize,
                            color: color,
                          ),
                          if (badgeCount > 0)
                            Positioned(
                              top: -5,
                              right: 0,
                              child: _UnreadBadge(
                                tabId: tab.id,
                                count: badgeCount,
                              ),
                            ),
                        ],
                      ),
                    ),
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
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.tabId, required this.count});

  final String tabId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      key: ValueKey('bottom-nav-$tabId-unread-badge'),
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.expense,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
