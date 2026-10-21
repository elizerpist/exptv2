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
