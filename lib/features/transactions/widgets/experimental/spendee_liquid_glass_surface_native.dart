import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart' as lgr;

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
    final shape = lgr.LiquidRoundedSuperellipse(borderRadius: borderRadius);
    final framedChild = KeyedSubtree(
      key: fallbackKey,
      child: SpendeeLiquidMaterialLayers(
        glareKey: glareKey,
        borderRadius: borderRadius,
        softness: resolvedSoftness,
        child: child,
      ),
    );
    return lgr.LiquidGlass.withOwnLayer(
      settings: _settingsForSoftness(resolvedSoftness),
      shape: shape,
      child: framedChild,
    );
  }

  lgr.LiquidGlassSettings _settingsForSoftness(double softness) {
    return lgr.LiquidGlassSettings(
      glassColor: Colors.white.withValues(alpha: _lerp(.25, .10, softness)),
      thickness: _lerp(20, 11, softness),
      blur: _lerp(17, 12, softness),
      lightIntensity: _lerp(.95, .46, softness),
      ambientStrength: _lerp(.24, .12, softness),
      saturation: _lerp(1.35, 1.08, softness),
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
