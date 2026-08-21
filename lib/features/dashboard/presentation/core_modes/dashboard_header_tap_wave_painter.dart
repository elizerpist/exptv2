import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dashboard_header_tap_wave.dart';

/// Source-equivalent paint adapter for the Color Lab's Header touch layer.
/// The underlying procedural field receives the source ripple displacement in
/// the common material lane; this painter owns only the later screen-blended
/// pink overlay and pointer trail that source CSS draws above that field.
final class DashboardHeaderTapWavePainter {
  static final ColorFilter _overlaySaturation = _saturation(1.85);

  void paint(
    Canvas canvas,
    Size size, {
    required DashboardHeaderTapWaveState state,
    required Duration elapsed,
  }) {
    if (!state.requiresFrames || size.isEmpty) return;
    final overlay = state.overlayAt(elapsed);
    if (overlay != null && overlay.opacity > 0) {
      _paintOverlay(canvas, size, overlay, state.tuning);
    }
    for (final trail in state.trails) {
      _paintTrail(canvas, size, state, trail, elapsed);
    }
  }

  void _paintOverlay(
    Canvas canvas,
    Size size,
    DashboardHeaderTapWaveOverlay overlay,
    DashboardHeaderTapWaveTuning tuning,
  ) {
    final alpha = tuning.valueFor('interactionOpacity') / 100;
    final origin = Offset(
      overlay.origin.dx * size.width,
      overlay.origin.dy * size.height,
    );
    // CSS `radial-gradient(circle at x y)` defaults to farthest-corner. The
    // source pseudo-element is inset by 12 px before its scale transform.
    final expanded = Size(size.width + 24, size.height + 24);
    final expandedOrigin = origin + const Offset(12, 12);
    final radius = math.sqrt(
      math.max(expandedOrigin.dx, expanded.width - expandedOrigin.dx) *
              math.max(expandedOrigin.dx, expanded.width - expandedOrigin.dx) +
          math.max(expandedOrigin.dy, expanded.height - expandedOrigin.dy) *
              math.max(expandedOrigin.dy, expanded.height - expandedOrigin.dy),
    );
    final colors = <Color>[
      for (final color in overlay.colors)
        color.withValues(alpha: color.a * alpha * overlay.opacity),
    ];
    final shader =
        RadialGradient(
          colors: colors,
          stops: overlay.stops,
          radius: 1,
        ).createShader(
          Rect.fromCircle(center: expandedOrigin, radius: radius * .25),
        );
    final layerBounds = Offset.zero & size;
    canvas.saveLayer(
      layerBounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: overlay.blur,
          sigmaY: overlay.blur,
        )
        ..colorFilter = _overlaySaturation,
    );
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(overlay.scale);
    canvas.translate(-origin.dx, -origin.dy);
    canvas.drawRect(
      Rect.fromLTWH(-12, -12, expanded.width, expanded.height),
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.screen,
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintTrail(
    Canvas canvas,
    Size size,
    DashboardHeaderTapWaveState state,
    DashboardHeaderTapWaveTrail trail,
    Duration elapsed,
  ) {
    final values = state.trailSampleAt(trail: trail, timestamp: elapsed);
    if (values == null) return;
    final alpha = state.tuning.valueFor('interactionOpacity') / 100;
    final center = Offset(
      trail.origin.dx * size.width,
      trail.origin.dy * size.height,
    );
    final baseRadius = state.tuning.valueFor('trailSize') / 2;
    final radius = baseRadius * values.scale;
    final colors = <Color>[
      Color(0xffffa7e2).withValues(alpha: .96 * alpha * values.opacity),
      Color(0xffff8bda).withValues(alpha: .82 * alpha * values.opacity),
      Color(0xff8b3eff).withValues(alpha: .72 * alpha * values.opacity),
      Colors.white.withValues(alpha: .42 * alpha * values.opacity),
      Colors.white.withValues(alpha: 0),
    ];
    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: values.blur,
          sigmaY: values.blur,
        )
        ..colorFilter = _saturation(values.saturation),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader =
            RadialGradient(
              colors: colors,
              stops: const <double>[0, .18, .38, .62, .76],
            ).createShader(
              Rect.fromCircle(center: center, radius: math.max(1, radius)),
            )
        ..blendMode = BlendMode.screen,
    );
    canvas.restore();
  }

  static ColorFilter _saturation(double amount) {
    const r = .213;
    const g = .715;
    const b = .072;
    final inverse = 1 - amount;
    return ColorFilter.matrix(<double>[
      inverse * r + amount,
      inverse * g,
      inverse * b,
      0,
      0,
      inverse * r,
      inverse * g + amount,
      inverse * b,
      0,
      0,
      inverse * r,
      inverse * g,
      inverse * b + amount,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}
