import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'balance_alternative_visual_tokens.dart';

/// Physical coordinates for a capsule whose centre, not leading edge, is data.
/// Endpoints are inset by half its width so the capsule stays inside the track.
@immutable
final class BalanceImpactMeterGeometry {
  BalanceImpactMeterGeometry(this.size)
    : markerSize = Size(
        math.min(size.width * .16, size.height * .95),
        size.height * .66,
      );
  final Size size, markerSize;
  double get start => 1 + markerSize.width / 2;
  double get end => size.width - start;
  double centerAt(double fraction) =>
      start + (end - start) * fraction.clamp(0.0, 1.0);
  Rect markerAt(double fraction) => Rect.fromCenter(
    center: Offset(centerAt(fraction), size.height / 2),
    width: markerSize.width,
    height: markerSize.height,
  );
}

/// The original Daily Impact material and renderer, with an axis-aware child.
/// Knows only a normalized marker coordinate; no financial metric or navigation.
final class BalanceImpactMeter extends StatelessWidget {
  const BalanceImpactMeter({
    super.key,
    required this.markerFraction,
    required this.markerColor,
    this.orientation = Axis.vertical,
    this.width,
    this.height,
    this.showMarker = true,
  });
  final double markerFraction;
  final Color markerColor;
  final Axis orientation;
  final double? width, height;
  final bool showMarker;

  static BoxDecoration trackDecoration(double radius) => BoxDecoration(
    color: const Color(0xFFF6F9FD),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFDDE6F1)),
    boxShadow: const [
      BoxShadow(color: Color(0x100D2859), blurRadius: 8, offset: Offset(0, 4)),
    ],
  );
  static BoxDecoration markerDecoration(Color color, double radius) =>
      BoxDecoration(
        color: color.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .36), blurRadius: 12),
        ],
      );
  @override
  Widget build(BuildContext context) {
    if (orientation == Axis.vertical) {
      // Preserve the original Container/FractionallySizedBox render tree and
      // source-pixel radii exactly for the legacy seven-day card.
      return Container(
        width: width,
        height: height,
        decoration: trackDecoration(BalanceAlternativeHtmlTokens.logical(36)),
        child: showMarker
            ? FractionallySizedBox(
                alignment: Alignment(0, 1 - markerFraction * 2),
                heightFactor: .49,
                widthFactor: .66,
                child: DecoratedBox(
                  decoration: markerDecoration(
                    markerColor,
                    BalanceAlternativeHtmlTokens.logical(30),
                  ),
                ),
              )
            : null,
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: trackDecoration((height ?? 64) / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = BalanceImpactMeterGeometry(constraints.biggest);
          return ClipRRect(
            borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
            child: Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth / 2 - .5,
                  top: 3,
                  bottom: 3,
                  child: Container(
                    key: const ValueKey('balance-impact-meter-reference'),
                    width: 1,
                    color: const Color(0xffb8c6da),
                  ),
                ),
                if (showMarker)
                  Positioned.fromRect(
                    rect: geometry.markerAt(markerFraction),
                    child: DecoratedBox(
                      key: const ValueKey('balance-impact-meter-marker'),
                      decoration: markerDecoration(
                        markerColor,
                        constraints.maxHeight / 2,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
