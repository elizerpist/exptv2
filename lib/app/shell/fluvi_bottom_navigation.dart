import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';
import 'fluvi_center_fab.dart';

/// Fixed first-slice navigation with one active dashboard destination.
class FluviBottomNavigation extends StatelessWidget {
  const FluviBottomNavigation({super.key, required this.onDashboardTap});

  final VoidCallback onDashboardTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: FluviVisualTokens.surface),
      child: SizedBox(
        height: FluviVisualTokens.navigationHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FluviVisualTokens.navigationHorizontalInset,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavigationItem(
                    semanticKey: const ValueKey('dashboard-nav-item'),
                    label: 'Dashboard',
                    icon: Icons.home_outlined,
                    active: true,
                    onTap: onDashboardTap,
                  ),
                  const _NavigationItem(
                    semanticKey: ValueKey('settings-nav-item'),
                    label: 'Beállítások',
                    icon: Icons.settings_outlined,
                    active: false,
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: FluviVisualTokens.centerFabBottomInset,
              child: FluviCenterFab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.semanticKey,
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
  });

  final String label;
  final Key semanticKey;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? FluviVisualTokens.navigationActiveIcon
        : FluviVisualTokens.navigationInactiveIcon;
    final labelStyle = active
        ? FluviVisualTokens.navigationActiveLabelTextStyle
        : FluviVisualTokens.navigationLabelTextStyle;
    return Semantics(
      key: semanticKey,
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: onTap == null
            ? HitTestBehavior.deferToChild
            : HitTestBehavior.opaque,
        child: SizedBox(
          width: FluviVisualTokens.navigationItemWidth,
          child: DecoratedBox(
            decoration: active
                ? const BoxDecoration(
                    color: FluviVisualTokens.navigationActiveSurface,
                    borderRadius: FluviVisualTokens.cardRadius,
                  )
                : const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: FluviVisualTokens.navigationItemVerticalInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: FluviVisualTokens.navigationIconSize,
                  ),
                  Text(label, style: labelStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
