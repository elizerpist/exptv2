import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Canonical multi-pass annual clay rendering, extracted unchanged from Budget.
/// Only physical geometry and resolved material enter this primitive.
abstract final class FluviYearClayCapsulePainter {
  static void paint(
    Canvas canvas, {
    required Rect rect,
    required List<Color> colors,
    required List<Color> depthColors,
    required List<double> stops,
    required bool showDecorativeStrip,
  }) {
    final radius = Radius.circular(rect.width / 2);
    final capsule = RRect.fromRectAndRadius(rect, radius);
    final depthOffset = Offset(
      rect.width * .10,
      math.max(.8, rect.width * .17),
    );
    canvas.drawRRect(
      capsule.shift(depthOffset),
      Paint()
        ..color = depthColors.last.withValues(alpha: .34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .14),
    );
    canvas.drawRRect(
      capsule.shift(Offset(0, rect.width * .10)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: depthColors,
          stops: stops,
        ).createShader(rect),
    );
    canvas.drawRRect(
      capsule,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
    if (!showDecorativeStrip) return;
    final capInset = math.min(rect.width * .22, rect.height * .22);
    final stripRect = Rect.fromLTWH(
      rect.left + rect.width * .18,
      rect.top + capInset,
      rect.width * .24,
      math.max(0, rect.height - capInset * 2),
    );
    if (stripRect.height <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripRect, Radius.circular(stripRect.width / 2)),
      Paint()..color = const Color(0x45FFFFFF),
    );
  }

  static void paintZeroRail(
    Canvas canvas, {
    required Rect rect,
    required List<Color> colors,
    required List<double> stops,
    required Color shadowColor,
    required Color glossColor,
    required bool showDecorativeStrip,
  }) {
    final radius = Radius.circular(rect.height / 2);
    final rail = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(
      rail.shift(Offset(0, rect.height * .8)),
      Paint()
        ..color = shadowColor.withValues(alpha: .52)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * .8),
    );
    canvas.drawRRect(
      rail.shift(Offset(0, rect.height * .36)),
      Paint()..color = colors.last,
    );
    canvas.drawRRect(
      rail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
    if (!showDecorativeStrip) return;
    final inset = rect.height * .85;
    final glossRect = Rect.fromLTWH(
      rect.left + inset,
      rect.top + rect.height * .18,
      math.max(0, rect.width - inset * 2),
      math.max(.5, rect.height * .27),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(glossRect.height / 2)),
      Paint()..color = glossColor,
    );
  }

  static void paintFutureMarker(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color shadowColor,
    required Color depthColor,
  }) {
    canvas.drawCircle(
      center.translate(radius * .28, radius * .4),
      radius,
      Paint()
        ..color = shadowColor.withValues(alpha: .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .75),
    );
    final dotRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.5),
          colors: <Color>[
            const Color(0xCCFFFFFF),
            depthColor.withValues(alpha: .78),
          ],
        ).createShader(dotRect),
    );
  }
}
