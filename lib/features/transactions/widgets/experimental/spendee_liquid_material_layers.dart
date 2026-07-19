import 'package:flutter/material.dart';

class SpendeeLiquidMaterialLayers extends StatelessWidget {
  const SpendeeLiquidMaterialLayers({
    super.key,
    required this.glareKey,
    required this.borderRadius,
    required this.child,
    this.softness = 0,
  });

  final Key glareKey;
  final double borderRadius;
  final double softness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedSoftness = _clampUnit(softness);
    return DecoratedBox(
      decoration: _liquidBaseDecoration(borderRadius, resolvedSoftness),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: glareKey,
                decoration: _liquidGlareDecoration(
                  borderRadius,
                  resolvedSoftness,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: _liquidEdgeDecoration(
                  borderRadius,
                  resolvedSoftness,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration spendeeLiquidOuterShadow(double radius, {double softness = 0}) {
  final resolvedSoftness = _clampUnit(softness);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(
          0xFF0A2638,
        ).withValues(alpha: _lerp(.18, .11, resolvedSoftness)),
        offset: const Offset(0, 12),
        blurRadius: _lerp(34, 24, resolvedSoftness),
      ),
      BoxShadow(
        color: Colors.white.withValues(
          alpha: _lerp(.34, .11, resolvedSoftness),
        ),
        offset: const Offset(-1.5, -1.5),
        blurRadius: _lerp(5, 3, resolvedSoftness),
      ),
    ],
  );
}

BoxDecoration _liquidBaseDecoration(double radius, double softness) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: _lerp(.66, .30, softness)),
        Colors.white.withValues(alpha: _lerp(.22, .08, softness)),
        const Color(0xFF37D6F2).withValues(alpha: _lerp(.10, .045, softness)),
      ],
      stops: const [0, .56, 1],
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: _lerp(.80, .34, softness)),
      width: _lerp(1.45, .95, softness),
    ),
  );
}

BoxDecoration _liquidGlareDecoration(double radius, double softness) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: RadialGradient(
      center: Alignment(-.82, -.96),
      radius: .92,
      colors: [
        Colors.white.withValues(alpha: _lerp(.90, .20, softness)),
        Colors.white.withValues(alpha: _lerp(.44, .11, softness)),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0, .34, .78],
    ),
  );
}

BoxDecoration _liquidEdgeDecoration(double radius, double softness) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: _lerp(.44, .16, softness)),
        Colors.white.withValues(alpha: 0),
        const Color(0xFF3DAFCF).withValues(alpha: _lerp(.19, .075, softness)),
      ],
      stops: const [0, .52, 1],
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: _lerp(.46, .20, softness)),
      width: .75,
    ),
  );
}

double _clampUnit(double value) {
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

double _lerp(double begin, double end, double t) {
  return begin + (end - begin) * t;
}
