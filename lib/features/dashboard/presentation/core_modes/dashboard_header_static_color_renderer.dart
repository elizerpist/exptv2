import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Exact production port of the historical Spendee Budget2 static gradient.
///
/// Provenance:
/// - source branch: `spendeetest`
/// - source path:
///   `lib/features/transactions/widgets/experimental/balance/`
///   `spendee_balance_visual_spec.dart`
/// - source blob: `bea3a36482686b1ef7a537046dcce0f2c443918a`
///
/// CSS linear-gradient angles cannot be represented by a pair of Flutter
/// [Alignment]s without changing their geometry on non-square Header bounds.
/// This class retains the source primitive's exact rect-derived endpoints and
/// delegates rasterisation directly to [ui.Gradient.linear].
@immutable
final class DashboardHeaderSpendeeBudget2CssLinearGradient extends Gradient {
  const DashboardHeaderSpendeeBudget2CssLinearGradient({
    required this.cssDegrees,
    required super.colors,
    super.stops,
    this.tileMode = TileMode.clamp,
  });

  final double cssDegrees;
  final TileMode tileMode;

  ({Offset start, Offset end}) endpointsFor(Rect rect) {
    final radians = cssDegrees * math.pi / 180;
    final direction = Offset(math.sin(radians), -math.cos(radians));
    final lineLength =
        rect.width * direction.dx.abs() + rect.height * direction.dy.abs();
    final halfVector = direction * (lineLength / 2);
    return (start: rect.center - halfVector, end: rect.center + halfVector);
  }

  @override
  ui.Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final (:start, :end) = endpointsFor(rect);
    final resolvedStops =
        stops ??
        List<double>.generate(
          colors.length,
          (index) => index / (colors.length - 1),
          growable: false,
        );
    return ui.Gradient.linear(start, end, colors, resolvedStops, tileMode);
  }

  @override
  DashboardHeaderSpendeeBudget2CssLinearGradient scale(double factor) {
    return DashboardHeaderSpendeeBudget2CssLinearGradient(
      cssDegrees: cssDegrees,
      colors: colors
          .map((color) => Color.lerp(null, color, factor)!)
          .toList(growable: false),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  DashboardHeaderSpendeeBudget2CssLinearGradient withOpacity(double opacity) {
    return DashboardHeaderSpendeeBudget2CssLinearGradient(
      cssDegrees: cssDegrees,
      colors: colors
          .map((color) => color.withValues(alpha: color.a * opacity))
          .toList(growable: false),
      stops: stops,
      tileMode: tileMode,
    );
  }
}

/// The single static Budget Header colour authority.
///
/// Budget semantics resolve the complete finite palette window before this
/// renderer is called. This paint-only owner neither derives target colours
/// nor understands progress, Portal state or animation phase.
abstract final class DashboardHeaderStaticColorRenderer {
  static const double cssDegrees = 112;
  static const String rendererId = 'spendeeBudget2CssLinearGradient';
  static const String sourceBranch = 'spendeetest';
  static const String sourceBlob = 'bea3a36482686b1ef7a537046dcce0f2c443918a';

  /// The isolated static base is painted natively and must not require the
  /// runtime FragmentProgram to exist or become ready.
  static const bool fragmentBaseRequired = false;

  static DashboardHeaderSpendeeBudget2CssLinearGradient gradientFor({
    required List<Color> colors,
    required List<double> stops,
  }) => DashboardHeaderSpendeeBudget2CssLinearGradient(
    cssDegrees: cssDegrees,
    colors: colors,
    stops: stops,
  );

  static void paint({
    required Canvas canvas,
    required Rect rect,
    required List<Color> colors,
    required List<double> stops,
    required double opacity,
  }) {
    final boundedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    final gradient = gradientFor(
      colors: colors,
      stops: stops,
    ).withOpacity(boundedOpacity);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
}
