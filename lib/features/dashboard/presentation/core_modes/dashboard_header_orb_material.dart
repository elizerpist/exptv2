import 'dart:math' as math;
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

  /// Crossfading is enough for the calm material fields. Deep Drift and the
  /// Portal layers contain travelling structure, so their finite launcher
  /// package requests denser *real shader* samples before it is blended.
  bool get requiresDenseOrbSampling =>
      tuning.effect == DashboardHeaderEffectId.deepDrift ||
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

  /// A cache key for every input that can affect a launcher texture.  The
  /// live phase/elapsed clock is intentionally absent: a cached finite
  /// package keeps its original clock origin and native selects its current
  /// phase when it is republished.
  String get orbVisualCacheKey => <Object?>[
    'header-material-v5-shader${DashboardHeaderFragmentUniformLayout.version}',
    tuning.effect.name,
    tuning.paletteOrientation.enabled,
    tuning.paletteOrientation.baseAngleDegrees,
    tuning.paletteOrientation.sweepDegrees,
    tuning.paletteOrientation.speed,
    tuning.paletteOrientation.phaseDegrees,
    _numberListKey(frame.colors.map((color) => color.toARGB32())),
    _numberListKey(frame.stops),
    frame.opacity,
    frame.paletteSplitPercent,
    _settingsKey(tuning.settingsFor(tuning.effect)),
    _background.orbVisualCacheKey,
    _interior.orbVisualCacheKey,
  ].join('|');

  static String _numberListKey(Iterable<num> values) => values.join(',');

  static String _settingsKey(Map<String, double> settings) {
    final keys = settings.keys.toList(growable: false)..sort();
    return keys.map((key) => '$key=${settings[key]}').join(',');
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

  String get orbVisualCacheKey => <Object?>[
    enabled,
    effect.name,
    paletteCenterPercent,
    paletteWindowPercent,
    rotationEnabled,
    rotationSpeed,
    DashboardHeaderMaterialSnapshot._settingsKey(settings),
  ].join(',');

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
    if (!_usesStatic(snapshot)) await _backend.waitForReadiness();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintMaterial(
      canvas: canvas,
      snapshot: snapshot,
      logicalSize: logicalSize,
      offset: offset,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }

  /// Renders the production shader directly into the square orb texture.
  ///
  /// `uSize` remains the header's original physical rectangle while
  /// `uRasterSize` is the bounded square output. This avoids first allocating
  /// a complete physical header bitmap for every animation sample.
  Future<ui.Image> renderOrbTexture({
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required int orbSizePx,
    required Duration offset,
    double devicePixelRatio = 1,
  }) async {
    final width = math.max(1, (headerSize.width * devicePixelRatio).round());
    final height = math.max(1, (headerSize.height * devicePixelRatio).round());
    final sourceSize = Size(width.toDouble(), height.toDouble());
    final targetSize = orbSizePx.clamp(1, 512).toInt();
    if (!_usesStatic(snapshot)) await _backend.waitForReadiness();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (_usesStatic(snapshot) || !_backend.isReady) {
      canvas.save();
      canvas.scale(
        targetSize / sourceSize.width,
        targetSize / sourceSize.height,
      );
      _paintMaterial(
        canvas: canvas,
        snapshot: snapshot,
        logicalSize: sourceSize,
        offset: offset,
      );
      canvas.restore();
    } else {
      _paintMaterial(
        canvas: canvas,
        snapshot: snapshot,
        logicalSize: sourceSize,
        rasterSize: Size.square(targetSize.toDouble()),
        offset: offset,
      );
    }
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(targetSize, targetSize);
    } finally {
      picture.dispose();
    }
  }

  void _paintMaterial({
    required Canvas canvas,
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size logicalSize,
    required Duration offset,
    Size? rasterSize,
  }) {
    // Dashboard's visual material has an opaque white base; opacity is then
    // applied once by the shared static/shader route.
    canvas.drawRect(Offset.zero & logicalSize, Paint()..color = Colors.white);
    if (_usesStatic(snapshot)) {
      DashboardHeaderStaticColorRenderer.paint(
        canvas: canvas,
        rect: Offset.zero & logicalSize,
        colors: snapshot.frame.colors,
        stops: snapshot.frame.stops,
        opacity: snapshot.frame.opacity,
      );
      return;
    }
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
      rasterSize: rasterSize,
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

  static bool _usesStatic(DashboardHeaderMaterialSnapshot snapshot) =>
      snapshot.tuning.effect == DashboardHeaderEffectId.staticEffect &&
      !snapshot._background.enabled &&
      !snapshot._interior.enabled;

  void dispose() {
    if (_ownsBackend) _backend.dispose();
  }
}

/// Maps the complete normalized Header rectangle into a square texture.
///
/// The normal Android 12+ path clips the *whole* animated ViewFlipper with a
/// geometric outline. This keeps an edge fixed during a crossfade and avoids
/// sampling a binary circle into every exported image. Older hosts can request
/// [applyCircularAlphaMask], which performs the same clipping with an
/// anti-aliased alpha mask as a compatibility fallback.
abstract final class DashboardHeaderOrbFrameMapper {
  static Future<ui.Image> map({
    required ui.Image header,
    required int orbSizePx,
    bool applyCircularAlphaMask = false,
  }) async {
    final targetSize = orbSizePx.clamp(1, 512);
    final destination = ui.Rect.fromLTWH(
      0,
      0,
      targetSize.toDouble(),
      targetSize.toDouble(),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;
    if (applyCircularAlphaMask) {
      canvas.saveLayer(destination, ui.Paint());
      canvas.drawCircle(
        destination.center,
        targetSize / 2,
        ui.Paint()
          ..color = const ui.Color(0xffffffff)
          ..isAntiAlias = true
          ..blendMode = ui.BlendMode.src,
      );
    }
    canvas.drawImageRect(
      header,
      ui.Rect.fromLTWH(0, 0, header.width.toDouble(), header.height.toDouble()),
      destination,
      applyCircularAlphaMask ? (paint..blendMode = ui.BlendMode.srcIn) : paint,
    );
    if (applyCircularAlphaMask) canvas.restore();
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(targetSize, targetSize);
    } finally {
      picture.dispose();
    }
  }
}
