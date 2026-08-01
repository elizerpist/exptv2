import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../core/design/fluvi_highlight.dart';

enum Bnb03Item { home, search, shop, cart, profile }

class _Bnb03FabCorePainter extends CustomPainter {
  const _Bnb03FabCorePainter({required this.gradient});

  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..isAntiAlias = true
        ..shader = gradient.createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _Bnb03FabCorePainter oldDelegate) {
    return oldDelegate.gradient != gradient;
  }
}

/// Pixel-faithful Flutter port of the Figma component:
/// BNB-03 / Mode=Light.
///
/// Figma base geometry:
/// - bar: 428 x 75
/// - top corner radius: 32
/// - center button: 96 x 96 at x=169.5, y=-24
/// - inner purple circle: 84 x 84
/// - icons: 24 x 24
/// - labels: 12 px, 14 px line box
///
/// At 428 logical pixels this matches the original Figma dimensions 1:1.
/// At other widths the whole component scales uniformly.
class Bnb03BottomNavigation extends StatelessWidget {
  const Bnb03BottomNavigation({
    super.key,
    required this.selected,
    required this.onChanged,
    this.width,
    this.fontFamily = 'SF Pro Text',
  });

  final Bnb03Item selected;
  final ValueChanged<Bnb03Item> onChanged;

  /// Leave null to use the available width.
  final double? width;

  /// The Figma file uses SF Pro Text Regular.
  /// Add that font to your own app assets for exact typography.
  final String fontFamily;

  static const double _figmaWidth = 428;
  static const double _barHeight = 75;
  static const double _overflowTop = 24;
  static const double _totalHeight = _barHeight + _overflowTop;

  static const Color _unselected = Color(0xFF9DB2CE);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _figmaWidth;
        final actualWidth = width ?? available;
        final scale = actualWidth / _figmaWidth;

        double s(double value) => value * scale;

        return SizedBox(
          width: actualWidth,
          height: s(_totalHeight),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: s(_overflowTop),
                width: actualWidth,
                height: s(_barHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(s(32)),
                      topRight: Radius.circular(s(32)),
                    ),
                  ),
                ),
              ),

              // Left group: x=25, width=142, gap=8.
              Positioned(
                left: s(25),
                top: s(_overflowTop),
                width: s(142),
                height: s(75),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavItem(
                      scale: scale,
                      width: 64,
                      label: 'Home',
                      selected: selected == Bnb03Item.home,
                      linearIcon: IconsaxPlusLinear.home_2,
                      boldIcon: IconsaxPlusBold.home_2,
                      iconLeft: 20,
                      textLeft: 15,
                      fontFamily: fontFamily,
                      onTap: () => onChanged(Bnb03Item.home),
                    ),
                    SizedBox(width: s(8)),
                    _NavItem(
                      scale: scale,
                      width: 70,
                      label: 'Search',
                      selected: selected == Bnb03Item.search,
                      linearIcon: IconsaxPlusLinear.search_normal,
                      boldIcon: IconsaxPlusBold.search_normal,
                      iconLeft: 23,
                      textLeft: 15,
                      fontFamily: fontFamily,
                      onTap: () => onChanged(Bnb03Item.search),
                    ),
                  ],
                ),
              ),

              // Right group: x=273, width=130, gap=8.
              Positioned(
                left: s(273),
                top: s(_overflowTop),
                width: s(130),
                height: s(75),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavItem(
                      scale: scale,
                      width: 55,
                      label: 'Cart',
                      selected: selected == Bnb03Item.cart,
                      linearIcon: IconsaxPlusLinear.bag,
                      boldIcon: IconsaxPlusBold.bag,
                      iconLeft: 15.5,
                      textLeft: 15,
                      fontFamily: fontFamily,
                      onTap: () => onChanged(Bnb03Item.cart),
                    ),
                    SizedBox(width: s(8)),
                    _NavItem(
                      scale: scale,
                      width: 67,
                      label: 'Profile',
                      selected: selected == Bnb03Item.profile,
                      linearIcon: IconsaxPlusLinear.user,
                      boldIcon: IconsaxPlusBold.user,
                      iconLeft: 21.5,
                      textLeft: 15,
                      fontFamily: fontFamily,
                      onTap: () => onChanged(Bnb03Item.profile),
                    ),
                  ],
                ),
              ),

              // Exact Figma placement: x=169.5, y=-24 relative to the 75px bar.
              // The wrapper starts 24px above the bar, so its local y is 0 here.
              Positioned(
                left: s(169.5),
                top: 0,
                width: s(96),
                height: s(96),
                child: Semantics(
                  button: true,
                  selected: selected == Bnb03Item.shop,
                  label: 'Shop',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onChanged(Bnb03Item.shop),
                      child: Container(
                        padding: EdgeInsets.all(s(6)),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          key: const ValueKey('bnb03-fab-outer-purple-ring'),
                          padding: EdgeInsets.all(s(6)),
                          decoration: const BoxDecoration(
                            color: FluviVisualTokens.appHighlightBorderColor,
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            key: const ValueKey('bnb03-fab-core'),
                            painter: const _Bnb03FabCorePainter(
                              gradient: FluviVisualTokens.appHighlightGradient,
                            ),
                            child: Center(
                              child: Icon(
                                selected == Bnb03Item.shop
                                    ? IconsaxPlusBold.shop
                                    : IconsaxPlusLinear.shop,
                                size: s(24),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.scale,
    required this.width,
    required this.label,
    required this.selected,
    required this.linearIcon,
    required this.boldIcon,
    required this.iconLeft,
    required this.textLeft,
    required this.fontFamily,
    required this.onTap,
  });

  final double scale;
  final double width;
  final String label;
  final bool selected;
  final IconData linearIcon;
  final IconData boldIcon;
  final double iconLeft;
  final double textLeft;
  final String fontFamily;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * scale;
    final color = selected
        ? FluviVisualTokens.appHighlightPressedColor
        : Bnb03BottomNavigation._unselected;

    return SizedBox(
      width: s(width),
      height: s(75),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  left: s(iconLeft),
                  top: s(12.5),
                  width: s(24),
                  height: s(24),
                  child: selected
                      ? FluviHighlightMask(
                          child: Icon(
                            boldIcon,
                            size: s(24),
                            color: Colors.white,
                          ),
                        )
                      : Icon(linearIcon, size: s(24), color: color),
                ),
                Positioned(
                  left: s(textLeft),
                  top: s(48.5),
                  height: s(14),
                  child: selected
                      ? FluviHighlightMask(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontFamily: fontFamily,
                              fontSize: s(12),
                              height: 14 / 12,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w400,
                            fontFamily: fontFamily,
                            fontSize: s(12),
                            height: 14 / 12,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
