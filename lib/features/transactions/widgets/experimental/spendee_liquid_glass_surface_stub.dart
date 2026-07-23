import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'spendee_liquid_material_layers.dart';

class SpendeeLiquidGlassSurface extends StatelessWidget {
  const SpendeeLiquidGlassSurface({
    super.key,
    required this.fallbackKey,
    required this.glareKey,
    required this.borderRadius,
    required this.child,
    this.softness = 0,
  });

  final Key fallbackKey;
  final Key glareKey;
  final double borderRadius;
  final double softness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedSoftness = _clampUnit(softness);
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: spendeeLiquidOuterShadow(
        borderRadius,
        softness: resolvedSoftness,
      ),
      child: ClipRRect(
        key: fallbackKey,
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: _lerp(18, 12, resolvedSoftness),
            sigmaY: _lerp(18, 12, resolvedSoftness),
          ),
          child: SpendeeLiquidMaterialLayers(
            glareKey: glareKey,
            borderRadius: borderRadius,
            softness: resolvedSoftness,
            child: child,
          ),
        ),
      ),
    );
  }
}

double _clampUnit(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

double _lerp(double begin, double end, double t) {
  return begin + (end - begin) * t;
}
