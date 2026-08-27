import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/design/dashboard_mode_palette.dart';
import '../../core/design/fluvi_highlight.dart';
import '../../features/dashboard/presentation/dashboard_shell_presentation.dart';

enum Bnb03Item { home, search, shop, cart, profile }

/// The one physical BottomNav path owner. It keeps the center FAB arc and the
/// selected outer top-edge termination in one coordinate system, so fill and
/// the optional border cannot disagree or cut through the FAB as a rectangular
/// `Border(top:)` would.
@immutable
final class Bnb03BottomNavigationContour {
  const Bnb03BottomNavigationContour({
    required this.edgeShape,
    required this.fabCenterX,
    required this.fabCenterY,
    required this.fabRadius,
    required this.cornerRadius,
  });

  final DashboardBottomNavEdgeShape edgeShape;
  final double fabCenterX;
  final double fabCenterY;
  final double fabRadius;
  final double cornerRadius;

  Path physicalPath(Size size) {
    final path = topContour(size)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  Path topContour(Size size) {
    final path = Path();
    final radius = edgeShape == DashboardBottomNavEdgeShape.rounded
        ? cornerRadius.clamp(0.0, size.width / 2)
        : 0.0;
    if (radius == 0) {
      path.moveTo(0, 0);
    } else {
      path
        ..moveTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0);
    }
    final verticalDistance = fabCenterY.abs();
    final arcHalfWidth = verticalDistance >= fabRadius
        ? 0.0
        : math.sqrt(
            fabRadius * fabRadius - verticalDistance * verticalDistance,
          );
    final leftArc = fabCenterX - arcHalfWidth;
    path.lineTo(leftArc, 0);
    if (arcHalfWidth > 0) {
      // Two 60° circle-derived cubic arcs: begin/end at the bar top and
      // crest at the original FAB top (centerY - radius). This deliberately
      // avoids an implicit `arcTo` connector, whose tangent can differ from
      // the fill path and make the thin contour appear to notch too deeply.
      final cubicFactor = 4 / 3 * math.tan(math.pi / 12);
      final tangent = fabRadius * cubicFactor;
      final crestY = fabCenterY - fabRadius;
      final leftControlX = leftArc + tangent * .5;
      final crestLeftControlX = fabCenterX - tangent;
      final crestRightControlX = fabCenterX + tangent;
      final rightArc = fabCenterX + arcHalfWidth;
      final rightControlX = rightArc - tangent * .5;
      final controlY = -tangent * math.sqrt(3) / 2;
      path
        ..cubicTo(
          leftControlX,
          controlY,
          crestLeftControlX,
          crestY,
          fabCenterX,
          crestY,
        )
        ..cubicTo(
          crestRightControlX,
          crestY,
          rightControlX,
          controlY,
          rightArc,
          0,
        );
    }
    path.lineTo(size.width - radius, 0);
    if (radius > 0) {
      path.quadraticBezierTo(size.width, 0, size.width, radius);
    }
    return path;
  }
}

class _Bnb03BarSurfacePainter extends CustomPainter {
  const _Bnb03BarSurfacePainter({required this.contour});

  final Bnb03BottomNavigationContour contour;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(contour.physicalPath(size), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _Bnb03BarSurfacePainter oldDelegate) =>
      oldDelegate.contour != contour;
}

/// Drawn after the FAB, so the one canonical contour is never hidden by the
/// FAB's white backing layer. This is paint-only and has no interaction role.
class _Bnb03TopContourPainter extends CustomPainter {
  const _Bnb03TopContourPainter({required this.contour});

  final Bnb03BottomNavigationContour contour;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      contour.topContour(size),
      Paint()
        ..color = FluviVisualTokens.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _Bnb03TopContourPainter oldDelegate) =>
      oldDelegate.contour != contour;
}

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

class _Bnb03FabRingPainter extends CustomPainter {
  const _Bnb03FabRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..isAntiAlias = true
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _Bnb03FabRingPainter oldDelegate) {
    return oldDelegate.color != color;
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
    this.edgeShape = DashboardBottomNavEdgeShape.rounded,
    this.topBorder = DashboardBottomNavTopBorder.off,
  });

  final Bnb03Item selected;
  final ValueChanged<Bnb03Item> onChanged;

  /// Leave null to use the available width.
  final double? width;

  /// The Figma file uses SF Pro Text Regular.
  /// Add that font to your own app assets for exact typography.
  final String fontFamily;
  final DashboardBottomNavEdgeShape edgeShape;
  final DashboardBottomNavTopBorder topBorder;

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
        final contour = Bnb03BottomNavigationContour(
          edgeShape: edgeShape,
          fabCenterX: actualWidth / 2,
          // The bar begins 24px below the 96px outer FAB canvas.
          fabCenterY: s(24),
          fabRadius: s(48),
          cornerRadius: s(32),
        );

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
                child: CustomPaint(
                  key: const ValueKey('bnb03-physical-bar-surface'),
                  painter: _Bnb03BarSurfacePainter(contour: contour),
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
                key: const ValueKey('bnb03-fab-layer'),
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
                        child: SizedBox.expand(
                          child: CustomPaint(
                            key: const ValueKey('bnb03-fab-outer-purple-ring'),
                            painter: const _Bnb03FabRingPainter(
                              color: FluviVisualTokens.appHighlightBorderColor,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(s(6)),
                              child: SizedBox.expand(
                                child: CustomPaint(
                                  key: const ValueKey('bnb03-fab-core'),
                                  painter: const _Bnb03FabCorePainter(
                                    gradient:
                                        FluviVisualTokens.appHighlightGradient,
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
                  ),
                ),
              ),
              if (topBorder == DashboardBottomNavTopBorder.thinGrey)
                Positioned(
                  key: const ValueKey('bnb03-top-contour-layer'),
                  left: 0,
                  top: s(_overflowTop),
                  width: actualWidth,
                  height: s(_barHeight),
                  child: IgnorePointer(
                    key: const ValueKey('bnb03-top-contour-overlay'),
                    child: CustomPaint(
                      key: const ValueKey('bnb03-top-contour-overlay-paint'),
                      painter: _Bnb03TopContourPainter(contour: contour),
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
