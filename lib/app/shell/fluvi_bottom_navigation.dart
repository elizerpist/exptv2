import 'package:flutter/material.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../core/design/fluvi_highlight.dart';
import '../../core/design/fluvi_rounded_box.dart';
import 'fluvi_center_fab.dart';

/// Fixed first-slice navigation with one active dashboard destination.
class FluviBottomNavigation extends StatelessWidget {
  const FluviBottomNavigation({super.key, required this.onDashboardTap});

  final VoidCallback onDashboardTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FluviVisualTokens.navigationHeight,
      child: CustomPaint(
        painter: const FluviConvexCenterBottomNavigationPainter(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: FluviVisualTokens.navigationHorizontalInset,
              right: FluviVisualTokens.navigationHorizontalInset,
              bottom: FluviVisualTokens.navigationItemBottomInset,
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
              top: FluviVisualTokens.centerFabTopInset,
              left: 0,
              right: 0,
              child: Center(child: FluviCenterFab()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the navigation surface as a raised convex center, not a notch.
class FluviConvexCenterBottomNavigationPainter extends CustomPainter {
  const FluviConvexCenterBottomNavigationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const sideTopY = FluviVisualTokens.navigationBumpSideTop;
    const peakY = FluviVisualTokens.navigationBumpPeak;
    const bumpHalfWidth = FluviVisualTokens.navigationBumpHalfWidth;
    final path = Path()
      ..moveTo(0, sideTopY)
      ..lineTo(centerX - bumpHalfWidth, sideTopY)
      ..cubicTo(centerX - 38, sideTopY, centerX - 42, peakY, centerX, peakY)
      ..cubicTo(
        centerX + 42,
        peakY,
        centerX + 38,
        sideTopY,
        centerX + bumpHalfWidth,
        sideTopY,
      )
      ..lineTo(size.width, sideTopY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = FluviVisualTokens.surface
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant FluviConvexCenterBottomNavigationPainter oldDelegate,
  ) {
    return false;
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
          child: active
              ? FluviRoundedBox(
                  gradient: FluviVisualTokens.appHighlightGradient,
                  padding: const EdgeInsets.symmetric(
                    vertical: FluviVisualTokens.navigationItemVerticalInset,
                  ),
                  child: _NavigationItemContent(
                    icon: icon,
                    iconColor: iconColor,
                    label: label,
                    labelStyle: labelStyle,
                    active: active,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: FluviVisualTokens.navigationItemVerticalInset,
                  ),
                  child: _NavigationItemContent(
                    icon: icon,
                    iconColor: iconColor,
                    label: label,
                    labelStyle: labelStyle,
                    active: active,
                  ),
                ),
        ),
      ),
    );
  }
}

class _NavigationItemContent extends StatelessWidget {
  const _NavigationItemContent({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelStyle,
    required this.active,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final TextStyle labelStyle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        active
            ? FluviHighlightMask(
                child: Icon(
                  icon,
                  color: FluviVisualTokens.appHighlightText,
                  size: FluviVisualTokens.navigationIconSize,
                ),
              )
            : Icon(
                icon,
                color: iconColor,
                size: FluviVisualTokens.navigationIconSize,
              ),
        active
            ? FluviHighlightMask(
                child: Text(
                  label,
                  style: labelStyle.copyWith(
                    color: FluviVisualTokens.appHighlightText,
                  ),
                ),
              )
            : Text(label, style: labelStyle),
      ],
    );
  }
}
