import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// Shared physical material rules for Mind/Balance; targets and content motion
/// remain mode-owned. No opaque plate is painted across an opened contact lane.
class DashboardJoinedMotherCardMaterial extends StatelessWidget {
  const DashboardJoinedMotherCardMaterial({
    super.key,
    required this.headerBounds,
    required this.bodyBounds,
    required this.shape,
    required this.separation,
    required this.opacity,
    required this.headerBase,
    required this.shadows,
    required this.border,
    required this.semanticKey,
    this.bodyKey,
    this.child,
  });
  final Rect headerBounds, bodyBounds;
  final DashboardHeaderContentSeamShape shape;
  final double separation, opacity;
  final Color headerBase;
  final List<BoxShadow> shadows;
  final BoxBorder? border;
  final Key semanticKey;
  final Key? bodyKey;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final bounds = headerBounds.expandToInclude(bodyBounds);
    final body = bodyBounds.shift(-bounds.topLeft);
    Widget perimeter(List<BoxShadow> depth, BoxBorder? outline, Color? base) =>
        CustomPaint(
          painter: _JoinedPerimeterPainter(
            headerBounds: headerBounds,
            bodyBounds: bodyBounds,
            paintBounds: bounds,
            shape: shape,
            separation: separation,
            opacity: opacity,
            shadows: depth,
            border: outline,
            headerBase: base,
            fillBorder: border,
          ),
        );
    return DashboardCoreModeFramePosition(
      bounds: DashboardBounds(
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
      ),
      child: IgnorePointer(
        child: SizedBox.expand(
          key: semanticKey,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: perimeter(shadows, null, headerBase)),
              Positioned.fromRect(
                rect: body,
                child: Opacity(
                  opacity: opacity,
                  child: SizedBox.expand(
                    key: bodyKey ?? const ValueKey('moving-mother-card-body'),
                    child: CustomPaint(
                      painter: _MovingBodyPainter(
                        shape.contentRadius,
                        shadows,
                        border,
                        separation,
                      ),
                      child: ClipRRect(
                        borderRadius: shape.contentRadius,
                        child: child ?? const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: perimeter(const [], border, null)),
            ],
          ),
        ),
      ),
    );
  }
}

final class _JoinedPerimeterPainter extends CustomPainter {
  const _JoinedPerimeterPainter({
    required this.headerBounds,
    required this.bodyBounds,
    required this.paintBounds,
    required this.shape,
    required this.separation,
    required this.opacity,
    required this.shadows,
    required this.border,
    this.headerBase,
    this.fillBorder,
  });
  final Color? headerBase;
  final BoxBorder? fillBorder;
  final Rect headerBounds, bodyBounds, paintBounds;
  final DashboardHeaderContentSeamShape shape;
  final double separation, opacity;
  final List<BoxShadow> shadows;
  final BoxBorder? border;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = -paintBounds.topLeft;
    final header = headerBounds.shift(origin);
    final body = bodyBounds.shift(origin);
    final alpha = (1 - separation) * opacity;
    Path contour({Offset offset = Offset.zero, double spread = 0}) =>
        Path.combine(
          PathOperation.union,
          Path()..addRRect(
            shape.headerRadius.toRRect(header.shift(offset).inflate(spread)),
          ),
          Path()..addRRect(
            shape.contentRadius.toRRect(body.shift(offset).inflate(spread)),
          ),
        );
    for (final shadow in shadows) {
      final paint = shadow
          .copyWith(
            color: shadow.color.withValues(alpha: shadow.color.a * alpha),
          )
          .toPaint();
      if (separation == 0) {
        // Exact authored BoxDecoration endpoint, including its shadow raster.
        canvas.drawRRect(
          shape.outerRadius.toRRect(
            (Offset.zero & size)
                .shift(shadow.offset)
                .inflate(shadow.spreadRadius),
          ),
          paint,
        );
      } else {
        canvas.drawPath(
          contour(offset: shadow.offset, spread: shadow.spreadRadius),
          paint,
        );
      }
    }
    final base = headerBase;
    if (base != null) {
      final fill = Paint()..color = base.withValues(alpha: base.a * opacity);
      if (separation == 0) {
        // A joined contact is interior, including fractional device pixels.
        // One fill avoids antialiasing two coincident edges into a seam.
        canvas.drawRRect(
          shape.outerRadius.toRRect(
            _backgroundRect(Offset.zero & size, fillBorder),
          ),
          fill,
        );
      } else {
        final union = Path.combine(
          PathOperation.union,
          Path()..addRRect(
            shape.headerRadius.toRRect(
              _backgroundRect(header, fillBorder, bottom: separation),
            ),
          ),
          Path()..addRRect(
            shape.contentRadius.toRRect(
              _backgroundRect(body, fillBorder, top: separation),
            ),
          ),
        );
        canvas.drawPath(union, fill);
      }
    }
    final outline = border;
    if (outline != null) {
      if (separation == 0) {
        outline.paint(
          canvas,
          Offset.zero & size,
          borderRadius: shape.outerRadius,
        );
      } else {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outline.top.width
          ..color = outline.top.color.withValues(
            alpha: outline.top.color.a * alpha,
          );
        // A joined outline owns only outer edges. New contact-edge borders
        // belong to the independently interpolated Header/body, never a
        // full-strength compound-path stroke on the first fractional frame.
        final headerCut =
            header.bottom - shape.headerRadius.bottomLeft.y - outline.top.width;
        final bodyCut =
            body.top + shape.contentRadius.topLeft.y + outline.top.width;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, headerCut));
        canvas.drawRRect(shape.headerRadius.toRRect(header), paint);
        canvas.restore();
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, bodyCut, size.width, size.height));
        canvas.drawRRect(shape.contentRadius.toRRect(body), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JoinedPerimeterPainter old) =>
      old.bodyBounds != bodyBounds ||
      old.headerBounds != headerBounds ||
      old.paintBounds != paintBounds ||
      old.separation != separation ||
      old.opacity != opacity ||
      old.shape.headerRadius != shape.headerRadius ||
      old.shape.contentRadius != shape.contentRadius ||
      !listEquals(old.shadows, shadows) ||
      old.border != border ||
      old.headerBase != headerBase ||
      old.fillBorder != fillBorder;
}

// Match BoxDecoration's opaque-border background inset, retaining its radius
// rather than shrinking it. Contact-edge insets emerge with the physical seam.
Rect _backgroundRect(
  Rect rect,
  BoxBorder? border, {
  double top = 1,
  double bottom = 1,
}) {
  double inset(BorderSide side) =>
      side.color.a == 1 && side.style == BorderStyle.solid
      ? side.strokeInset / 2
      : 0;
  if (border is! Border) return rect;
  return Rect.fromLTRB(
    rect.left + inset(border.left),
    rect.top + inset(border.top) * top,
    rect.right - inset(border.right),
    rect.bottom - inset(border.bottom) * bottom,
  );
}

final class _MovingBodyPainter extends CustomPainter {
  const _MovingBodyPainter(
    this.radius,
    this.shadows,
    this.border,
    this.progress,
  );
  final BorderRadius radius;
  final List<BoxShadow> shadows;
  final BoxBorder? border;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (final shadow in shadows) {
      canvas.drawRRect(
        radius.toRRect(rect.shift(shadow.offset).inflate(shadow.spreadRadius)),
        shadow
            .copyWith(
              color: shadow.color.withValues(alpha: shadow.color.a * progress),
            )
            .toPaint(),
      );
    }
    BoxBorder.lerp(
      null,
      border,
      progress,
    )?.paint(canvas, rect, borderRadius: radius);
  }

  @override
  bool shouldRepaint(_MovingBodyPainter old) =>
      old.radius != radius ||
      !listEquals(old.shadows, shadows) ||
      old.border != border ||
      old.progress != progress;
}
