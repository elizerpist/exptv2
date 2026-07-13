import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'spendee_header_visual_spec.dart';

class SpendeeHeaderGlassPainter extends CustomPainter {
  const SpendeeHeaderGlassPainter(this.spec);

  final SpendeeHeaderVisualSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final glass = spec.glass;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = cssLinearGradientShader(
          rect: rect,
          cssAngleDegrees: spec.gradientCssAngleDegrees,
          colors: spec.gradientColors,
          stops: spec.gradientStops,
        ),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = cssLinearGradientShader(
          rect: rect,
          cssAngleDegrees: glass.diagonalGlossCssAngleDegrees,
          colors: <Color>[
            Colors.white.withValues(alpha: glass.diagonalGlossOpacity),
            Colors.transparent,
          ],
          stops: <double>[0, glass.diagonalGlossEndStop],
        ),
    );

    final reactiveCenter = Offset(
      size.width - glass.reactiveGlossRightInset,
      glass.reactiveGlossY,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          reactiveCenter,
          _farthestCornerRadius(rect, reactiveCenter),
          <Color>[
            spec.reactiveGlossColor,
            Colors.white.withValues(alpha: glass.reactiveGlossOpacities[1]),
            Colors.transparent,
          ],
          glass.reactiveGlossStops,
        ),
    );

    final whiteCenter = Offset(
      size.width * glass.whiteGlossCenter.dx,
      size.height * glass.whiteGlossCenter.dy,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          whiteCenter,
          _farthestCornerRadius(rect, whiteCenter),
          <Color>[
            Colors.white.withValues(alpha: glass.whiteGlossOpacity),
            Colors.transparent,
          ],
          <double>[0, glass.whiteGlossEndStop],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant SpendeeHeaderGlassPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}

class SpendeeHeaderBorderPainter extends CustomPainter {
  const SpendeeHeaderBorderPainter(this.spec);

  final SpendeeHeaderVisualSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final glass = spec.glass;
    final halfStroke = glass.borderWidth / 2;
    final rect = (Offset.zero & size).deflate(halfStroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(glass.radius - halfStroke)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glass.borderWidth
        ..color = glass.borderColor
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant SpendeeHeaderBorderPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}

class SpendeeHeaderOuterGlowPainter extends CustomPainter {
  const SpendeeHeaderOuterGlowPainter(this.spec);

  final SpendeeHeaderVisualSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final glow = spec.glow;
    final expanded = rect.inflate(glow.blurSigma * 3);

    canvas.saveLayer(
      expanded,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: glow.blurSigma,
          sigmaY: glow.blurSigma,
        ),
    );
    canvas.saveLayer(rect, Paint());

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(glow.radius)),
      Paint()
        ..shader = cssLinearGradientShader(
          rect: rect,
          cssAngleDegrees: spec.gradientCssAngleDegrees,
          colors: spec.gradientColors
              .map((color) => color.withValues(alpha: glow.opacity))
              .toList(growable: false),
          stops: spec.gradientStops,
        ),
    );

    final fadeStop = (glow.verticalFadeHeight / size.height).clamp(0.0, 1.0);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const <Color>[Colors.transparent, Colors.white, Colors.white],
          <double>[0, fadeStop, 1],
        ),
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 2, size.height / 2);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(Offset.zero, 1, <Color>[
          for (final opacity in glow.radialMaskOpacities)
            Colors.white.withValues(alpha: opacity),
        ], glow.radialMaskStops),
    );
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpendeeHeaderOuterGlowPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}

class SpendeeHeaderMenuSurfacePainter extends CustomPainter {
  const SpendeeHeaderMenuSurfacePainter(this.spec);

  final SpendeeHeaderMenuSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(spec.radius));
    canvas.drawRRect(outer, Paint()..color = spec.fillColor);

    final insetRect = rect.deflate(spec.insetWidth);
    final insetRRect = RRect.fromRectAndRadius(
      insetRect,
      Radius.circular(spec.radius - spec.insetWidth),
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height / 2));
    canvas.drawRRect(
      insetRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.insetWidth
        ..color = spec.topInsetColor,
    );
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, size.height / 2, size.width, size.height));
    canvas.drawRRect(
      insetRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.insetWidth
        ..color = spec.bottomInsetColor,
    );
    canvas.restore();

    final halfStroke = spec.borderWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(halfStroke),
        Radius.circular(spec.radius - halfStroke),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spec.borderWidth
        ..color = spec.borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant SpendeeHeaderMenuSurfacePainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}

Shader cssLinearGradientShader({
  required Rect rect,
  required double cssAngleDegrees,
  required List<Color> colors,
  required List<double> stops,
}) {
  final radians = cssAngleDegrees * math.pi / 180;
  final direction = Offset(math.sin(radians), -math.cos(radians));
  final lineLength =
      direction.dx.abs() * rect.width + direction.dy.abs() * rect.height;
  final halfVector = direction * (lineLength / 2);
  return ui.Gradient.linear(
    rect.center - halfVector,
    rect.center + halfVector,
    colors,
    stops,
  );
}

double _farthestCornerRadius(Rect rect, Offset center) {
  return <Offset>[
    rect.topLeft,
    rect.topRight,
    rect.bottomLeft,
    rect.bottomRight,
  ].map((corner) => (corner - center).distance).reduce(math.max);
}
