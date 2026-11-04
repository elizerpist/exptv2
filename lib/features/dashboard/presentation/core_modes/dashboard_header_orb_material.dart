import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dashboard_header_fragment_backend.dart';
import 'dashboard_header_deep_drift.dart';
import 'dashboard_header_portal_material_field.dart';
import 'dashboard_header_static_color_renderer.dart';
import 'dashboard_header_visual_engine.dart';

/// Immutable, interaction-free input for a launcher material export.
///
/// This is deliberately captured from the same [DashboardHeaderVisualFrame]
/// and [DashboardHeaderVisualController] that paint Dashboard.  Rendering it
/// at [elapsed] never advances or otherwise touches the visible controller.
@immutable
final class DashboardHeaderMaterialSnapshot {
  const DashboardHeaderMaterialSnapshot._({
    required this.frame,
    required this.tuning,
    required this.phase,
    required this.elapsed,
    required _DashboardHeaderMaterialPortalSnapshot background,
    required _DashboardHeaderMaterialPortalSnapshot interior,
  }) : _background = background,
       _interior = interior;

  factory DashboardHeaderMaterialSnapshot.capture({
    required DashboardHeaderVisualController controller,
    required DashboardHeaderVisualFrame frame,
  }) => DashboardHeaderMaterialSnapshot._(
    frame: DashboardHeaderVisualFrame(
      colors: List<Color>.unmodifiable(frame.colors),
      stops: List<double>.unmodifiable(frame.stops),
      opacity: frame.opacity,
      colorA: frame.colorA,
      colorB: frame.colorB,
      paletteSplitPercent: frame.paletteSplitPercent,
      staticInterpolation: frame.staticInterpolation,
    ),
    tuning: controller.tuning.value,
    phase: controller.phase,
    elapsed: controller.elapsed,
    background: _DashboardHeaderMaterialPortalSnapshot.capture(
      controller.portalBackgroundMorph,
    ),
    interior: _DashboardHeaderMaterialPortalSnapshot.capture(
      controller.portalInnerMotion,
    ),
  );

  final DashboardHeaderVisualFrame frame;
  final DashboardHeaderVisualTuning tuning;
  final double phase;
  final Duration elapsed;
  final _DashboardHeaderMaterialPortalSnapshot _background;
  final _DashboardHeaderMaterialPortalSnapshot _interior;

  DashboardHeaderEffectSpec get effect =>
      DashboardHeaderEffectCatalog.effectFor(tuning.effect);

  double get _effectSpeed => tuning.settingsFor(tuning.effect)['speed'] ?? 0;

  bool get isAnimated =>
      (tuning.effect != DashboardHeaderEffectId.staticEffect &&
          _effectSpeed > 0) ||
      _background.hasMotion ||
      _interior.hasMotion;

  Duration elapsedAt(Duration offset) => elapsed + offset;

  double phaseAt(Duration offset) {
    if (tuning.effect == DashboardHeaderEffectId.staticEffect) return phase;
    return phase +
        offset.inMicroseconds / Duration.microsecondsPerSecond * _effectSpeed;
  }

  /// The Header controls phase in phase-units/second. The slowest meaningful
  /// material cycle is therefore sampled over one complete 2π phase turn.
  /// This is intentionally not capped to a short cosmetic loop: a user-set
  /// slow effect keeps its source speed in the launcher package.
  int get characteristicCycleMs {
    if (!isAnimated) return 1000;
    final speed = _effectSpeed > 0
        ? _effectSpeed
        : math.max(_background.phaseSpeed, _interior.phaseSpeed);
    if (speed <= 0) return 1000;
    return ((2 * math.pi / speed) * 1000).round().clamp(1000, 3600000);
  }

  DashboardHeaderFragmentPaintInput inputAt(
    Duration offset,
    DashboardHeaderDeepDriftSkeleton deepDrift,
  ) {
    final settings = tuning.settingsFor(tuning.effect);
    final common = _pack(
      DashboardHeaderEffectCatalog.effectFor(tuning.effect).controls,
      settings,
      length: 40,
    );
    _packOrientation(common, tuning.paletteOrientation);
    final atElapsed = elapsedAt(offset);
    if (tuning.effect == DashboardHeaderEffectId.deepDrift) {
      deepDrift.advance(elapsed: atElapsed, settings: common);
    }
    return DashboardHeaderFragmentPaintInput(
      phase: phaseAt(offset),
      elapsed: atElapsed,
      effectShaderId: effect.shaderId,
      paletteSplitPercent: frame.paletteSplitPercent,
      opacity: frame.opacity,
      pulse: 0,
      shaderQuality:
          tuning.effect == DashboardHeaderEffectId.staticEffect ||
              tuning.effect == DashboardHeaderEffectId.deepDrift
          ? 1
          : (settings['renderScale'] ?? 1).clamp(.35, 1).toDouble(),
      canonicalColors: frame.colors,
      canonicalStops: frame.stops,
      commonSettings: common,
      deepDrift: deepDrift,
      background: _background.inputAt(offset),
      interior: _interior.inputAt(offset),
      ripples: DashboardHeaderTapRippleUniformBank(),
      tapRippleRadiusTravel: 0,
      tapRippleIntensity: 0,
      tapPulseLight: 0,
      tapVisuals: DashboardHeaderTapWaveVisualUniformBank(),
    );
  }

  static List<double> _pack(
    List<DashboardHeaderEffectControl> controls,
    Map<String, double> settings, {
    required int length,
  }) => List<double>.generate(
    length,
    (index) => index < controls.length
        ? settings[controls[index].id] ?? controls[index].defaultValue
        : 0,
    growable: false,
  );

  static void _packOrientation(
    List<double> target,
    DashboardHeaderPaletteOrientationTuning orientation,
  ) {
    target[36] = orientation.enabled ? 1 : 0;
    target[37] = orientation.packedBaseAndPhaseDegrees;
    target[38] = orientation.sweepDegrees;
    target[39] = orientation.speed;
  }
}

@immutable
final class _DashboardHeaderMaterialPortalSnapshot {
  const _DashboardHeaderMaterialPortalSnapshot({
    required this.enabled,
    required this.effect,
    required this.phase,
    required this.paletteCenterPercent,
    required this.paletteWindowPercent,
    required this.rotationEnabled,
    required this.rotationSpeed,
    required this.settings,
  });

  factory _DashboardHeaderMaterialPortalSnapshot.capture(
    DashboardHeaderPortalChannelState state,
  ) {
    final effect = state.effect;
    return _DashboardHeaderMaterialPortalSnapshot(
      enabled: state.enabled,
      effect: effect,
      phase: state.phaseFor(effect),
      paletteCenterPercent: state.paletteCenterPercent,
      paletteWindowPercent: state.paletteWindowPercent,
      rotationEnabled: state.rotationEnabled,
      rotationSpeed: state.rotationSpeed,
      settings: Map<String, double>.unmodifiable(state.settingsFor(effect)),
    );
  }

  final bool enabled;
  final DashboardHeaderPortalMaterialEffectId effect;
  final double phase;
  final double paletteCenterPercent;
  final double paletteWindowPercent;
  final bool rotationEnabled;
  final double rotationSpeed;
  final Map<String, double> settings;

  bool get requiresFrames =>
      enabled &&
      DashboardHeaderPortalMaterialCatalog.effectFor(effect).isAnimated;

  double get phaseSpeed {
    if (!requiresFrames) return 0;
    final control =
        effect == DashboardHeaderPortalMaterialEffectId.livingArchipelago
        ? 'wanderSpeed'
        : 'driftSpeed';
    return (settings[control] ?? 0) / 24;
  }

  bool get hasMotion => phaseSpeed > 0;

  DashboardHeaderFragmentPortalInput inputAt(Duration offset) {
    final advanced = requiresFrames
        ? DashboardHeaderPortalMaterialField.advancePhase(
            effect: effect,
            phase: phase,
            elapsedSeconds:
                offset.inMicroseconds / Duration.microsecondsPerSecond,
            settings: settings,
          )
        : phase;
    final controls = DashboardHeaderPortalMaterialCatalog.effectFor(
      effect,
    ).controls;
    final packed = List<double>.generate(
      12,
      (index) => index < controls.length
          ? settings[controls[index].id] ?? controls[index].defaultValue
          : 0,
      growable: false,
    );
    return DashboardHeaderFragmentPortalInput(
      enabled: enabled,
      effectIndex: effect.index,
      phase: advanced,
      paletteCenterPercent: paletteCenterPercent,
      paletteWindowPercent: paletteWindowPercent,
      rotationEnabled: rotationEnabled,
      rotationSpeed: rotationSpeed,
      settings: packed,
    );
  }
}

/// One offscreen instance of the production Header material renderer.
///
/// It owns its own retained shader and Deep Drift storage. It never installs a
/// ticker and has no reference to the dashboard's live clock after snapshot
/// capture.
final class DashboardHeaderMaterialFrameRenderer {
  DashboardHeaderMaterialFrameRenderer({
    DashboardHeaderFragmentBackend? backend,
  }) : _backend = backend ?? DashboardHeaderFragmentBackend(),
       _ownsBackend = backend == null;

  final DashboardHeaderFragmentBackend _backend;
  final bool _ownsBackend;
  final DashboardHeaderDeepDriftSkeleton _deepDrift =
      DashboardHeaderDeepDriftSkeleton();

  Future<ui.Image> render({
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required Duration offset,
    double devicePixelRatio = 1,
  }) async {
    final width = math.max(1, (headerSize.width * devicePixelRatio).round());
    final height = math.max(1, (headerSize.height * devicePixelRatio).round());
    final logicalSize = Size(width.toDouble(), height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Dashboard's visual material has an opaque white base; opacity is then
    // applied once by the shared static/shader route.
    canvas.drawRect(Offset.zero & logicalSize, Paint()..color = Colors.white);
    final usesStatic =
        snapshot.tuning.effect == DashboardHeaderEffectId.staticEffect &&
        !snapshot._background.enabled &&
        !snapshot._interior.enabled;
    if (usesStatic) {
      DashboardHeaderStaticColorRenderer.paint(
        canvas: canvas,
        rect: Offset.zero & logicalSize,
        colors: snapshot.frame.colors,
        stops: snapshot.frame.stops,
        opacity: snapshot.frame.opacity,
      );
    } else {
      await _backend.waitForReadiness();
      final plan = DashboardHeaderFragmentRenderPlan.resolve(
        logicalSize: logicalSize,
        devicePixelRatio: 1,
        renderScale: 1,
      );
      final painted = _backend.paint(
        canvas,
        logicalSize,
        plan: plan,
        input: snapshot.inputAt(offset, _deepDrift),
      );
      if (!painted) {
        DashboardHeaderStaticColorRenderer.paint(
          canvas: canvas,
          rect: Offset.zero & logicalSize,
          colors: snapshot.frame.colors,
          stops: snapshot.frame.stops,
          opacity: snapshot.frame.opacity,
        );
      }
    }
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }

  void dispose() {
    if (_ownsBackend) _backend.dispose();
  }
}

/// Maps all of the normalized Header rectangle to an alpha-masked orb.  It
/// intentionally has no radial shade, highlight, crop, or material math.
abstract final class DashboardHeaderOrbFrameMapper {
  static Future<ui.Image> map({
    required ui.Image header,
    required int orbSizePx,
  }) async {
    final source = await header.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (source == null) throw StateError('Header pixels are unavailable.');
    final targetSize = orbSizePx.clamp(1, 512);
    final target = Uint8List(targetSize * targetSize * 4);
    final bytes = source.buffer.asUint8List();
    for (var y = 0; y < targetSize; y += 1) {
      final normalizedY = (y + .5) / targetSize;
      for (var x = 0; x < targetSize; x += 1) {
        final normalizedX = (x + .5) / targetSize;
        final dx = normalizedX - .5;
        final dy = normalizedY - .5;
        final out = (y * targetSize + x) * 4;
        if (dx * dx + dy * dy > .25) continue;
        final sx = (normalizedX * (header.width - 1)).round().clamp(
          0,
          header.width - 1,
        );
        final sy = (normalizedY * (header.height - 1)).round().clamp(
          0,
          header.height - 1,
        );
        final input = (sy * header.width + sx) * 4;
        target[out] = bytes[input];
        target[out + 1] = bytes[input + 1];
        target[out + 2] = bytes[input + 2];
        target[out + 3] = bytes[input + 3];
      }
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      target,
      targetSize,
      targetSize,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
