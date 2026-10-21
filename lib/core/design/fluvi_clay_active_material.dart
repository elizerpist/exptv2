import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Scope-neutral light/body/depth recipe for Fluvi's small clay surfaces.
///
/// Feature renderers retain their own geometry and semantics. This core
/// recipe lets non-Budget renderers follow the established active Budget arc
/// language without depending on a Budget feature implementation.
@immutable
final class FluviClayActiveMaterial {
  const FluviClayActiveMaterial({
    required this.colors,
    required this.depthColors,
    this.stops = const <double>[0, .5, 1],
  });

  factory FluviClayActiveMaterial.forBase(Color base) {
    final colors = List<Color>.unmodifiable(<Color>[
      Color.lerp(base, Colors.white, .32)!,
      base,
      Color.lerp(base, const Color(0xFF172554), .18)!,
    ]);
    return FluviClayActiveMaterial(
      colors: colors,
      depthColors: List<Color>.unmodifiable(
        colors
            .map((color) => Color.lerp(color, const Color(0xFF172554), .36)!)
            .toList(growable: false),
      ),
    );
  }

  /// Builds the same soft clay depth family from an already-established
  /// product colour ramp. This lets a renderer retain its canonical visual
  /// identity while adding only volumetric treatment.
  factory FluviClayActiveMaterial.forGradient({
    required Color highlight,
    required Color body,
  }) {
    final colors = List<Color>.unmodifiable(<Color>[
      highlight,
      body,
      Color.lerp(body, const Color(0xFF172554), .18)!,
    ]);
    return FluviClayActiveMaterial(
      colors: colors,
      depthColors: List<Color>.unmodifiable(
        colors
            .map((color) => Color.lerp(color, const Color(0xFF172554), .36)!)
            .toList(growable: false),
      ),
    );
  }

  final List<Color> colors;
  final List<Color> depthColors;
  final List<double> stops;

  Color get highlight => colors.first;
  Color get body => colors[colors.length ~/ 2];
  Color get depth => colors.last;
  Color get shadow => depthColors.last.withValues(alpha: .24);

  bool sameVisualAs(FluviClayActiveMaterial other) =>
      listEquals(colors, other.colors) &&
      listEquals(depthColors, other.depthColors) &&
      listEquals(stops, other.stops);
}

/// The endpoint that visually leaves a shared baseline. It affects only the
/// clay silhouette; callers retain their own financial sign and geometry.
enum FluviClayCapsuleDirection { upward, downward }

/// Scope-neutral multi-pass capsule primitive used by bounded chart bars.
///
/// It deliberately knows nothing about Budget, Balance, or financial values:
/// callers supply the exact data rect, semantic material and baseline-facing
/// direction. The white strip is a vertical material feature rather than a
/// top-cap gloss, matching Fluvi's established annual clay vocabulary.
abstract final class FluviClayCapsulePainter {
  @visibleForTesting
  static Rect? lightStripRectFor(Rect rect) {
    if (rect.isEmpty) return null;
    final capInset = (rect.width * .22)
        .clamp(0.0, rect.height * .22)
        .toDouble();
    // A short nub has no readable capsule body between its two rounded ends.
    // Keep its depth/material but omit the strip rather than drawing a blob.
    if (rect.height <= math.max(rect.width * .44, 2)) return null;
    final height = rect.height - capInset * 2;
    if (height <= 0) return null;
    return Rect.fromLTWH(
      rect.left + rect.width * .18,
      rect.top + capInset,
      rect.width * .24,
      height,
    );
  }

  static void paint(
    Canvas canvas, {
    required Rect rect,
    required FluviClayActiveMaterial material,
    required FluviClayCapsuleDirection direction,
    bool showLightStrip = true,
  }) {
    if (rect.isEmpty) return;
    final depthOffset = Offset(
      rect.width * .10,
      math.max(.8, rect.width * .17),
    );
    final body = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      math.max(1, rect.height - depthOffset.dy),
    );
    final freeRadius = Radius.circular(
      math.min(body.width / 2, body.height / 2),
    );
    final baselineRadius = Radius.circular(math.min(2, freeRadius.x));
    final capsule = switch (direction) {
      FluviClayCapsuleDirection.upward => RRect.fromRectAndCorners(
        body,
        topLeft: freeRadius,
        topRight: freeRadius,
        bottomLeft: baselineRadius,
        bottomRight: baselineRadius,
      ),
      FluviClayCapsuleDirection.downward => RRect.fromRectAndCorners(
        body,
        topLeft: baselineRadius,
        topRight: baselineRadius,
        bottomLeft: freeRadius,
        bottomRight: freeRadius,
      ),
    };
    canvas.drawRRect(
      capsule.shift(depthOffset),
      Paint()
        ..color = material.shadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .14),
    );
    canvas.drawRRect(
      capsule.shift(Offset(0, rect.width * .10)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: material.depthColors,
          stops: material.stops,
        ).createShader(body),
    );
    canvas.drawRRect(
      capsule,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: material.colors,
          stops: material.stops,
        ).createShader(body),
    );
    if (!showLightStrip) return;
    final stripRect = lightStripRectFor(rect);
    if (stripRect == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripRect, Radius.circular(stripRect.width / 2)),
      Paint()..color = const Color(0x45FFFFFF),
    );
  }
}
