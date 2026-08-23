import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dashboard_header_deep_drift.dart';
import 'dashboard_header_tap_wave.dart';

/// The normal animated route always evaluates the material field per fragment.
/// A shader failure is handled by the native static gradient painter, outside
/// this plan, so no sparse endpoint fallback can be selected here.
enum DashboardHeaderRenderBackend { fragmentShader }

enum DashboardHeaderFieldEvaluation { perFragment }

@immutable
final class DashboardHeaderFragmentRenderPlan {
  const DashboardHeaderFragmentRenderPlan._({
    required this.backend,
    required this.fieldEvaluation,
    required this.logicalSize,
    required this.physicalSize,
    required this.renderScale,
  });

  factory DashboardHeaderFragmentRenderPlan.resolve({
    required Size logicalSize,
    required double devicePixelRatio,
    required double renderScale,
  }) {
    final dpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    final boundedScale = renderScale.clamp(.35, 1.0).toDouble();
    final safeLogical = Size(
      math.max(0, logicalSize.width),
      math.max(0, logicalSize.height),
    );
    // Render quality changes shader-internal procedural complexity; it must
    // never switch the normal production surface back to sparse Dart vertices.
    return DashboardHeaderFragmentRenderPlan._(
      backend: DashboardHeaderRenderBackend.fragmentShader,
      fieldEvaluation: DashboardHeaderFieldEvaluation.perFragment,
      logicalSize: safeLogical,
      physicalSize: Size(
        (safeLogical.width * dpr).ceilToDouble(),
        (safeLogical.height * dpr).ceilToDouble(),
      ),
      renderScale: boundedScale,
    );
  }

  final DashboardHeaderRenderBackend backend;
  final DashboardHeaderFieldEvaluation fieldEvaluation;
  final Size logicalSize;
  final Size physicalSize;
  final double renderScale;

  int get dartSurfaceFieldSamplesPerTick => 0;
}

/// Fixed-size GPU input for the already bounded Color Lab ripple bank.  No
/// pointer path can turn this into an unbounded per-frame allocation.
final class DashboardHeaderTapRippleUniformBank {
  DashboardHeaderTapRippleUniformBank()
    : _slots = List<DashboardHeaderTapRippleUniformSlot>.generate(
        10,
        (_) => DashboardHeaderTapRippleUniformSlot(),
        growable: false,
      );

  final List<DashboardHeaderTapRippleUniformSlot> _slots;
  var _activeCount = 0;

  factory DashboardHeaderTapRippleUniformBank.fromState({
    required DashboardHeaderTapWaveState state,
    required Duration elapsed,
  }) =>
      DashboardHeaderTapRippleUniformBank()
        ..update(state: state, elapsed: elapsed);

  void update({
    required DashboardHeaderTapWaveState state,
    required Duration elapsed,
  }) {
    var index = 0;
    for (final ripple in state.ripples) {
      if (index == _slots.length) break;
      final age = elapsed - ripple.startedAt;
      if (age < Duration.zero || age >= const Duration(milliseconds: 1685)) {
        continue;
      }
      _slots[index++].set(
        x: ripple.origin.dx,
        y: ripple.origin.dy,
        age: age.inMicroseconds / 1684800,
      );
    }
    for (var clearIndex = index; clearIndex < _slots.length; clearIndex += 1) {
      _slots[clearIndex].clear();
    }
    _activeCount = index;
  }

  int get activeCount => _activeCount;
  List<DashboardHeaderTapRippleUniformSlot> get slots => _slots;
  int get dartSurfaceFieldSamplesPerTick => 0;
}

final class DashboardHeaderTapRippleUniformSlot {
  double x = 0;
  double y = 0;
  double age = 0;
  double active = 0;

  void set({required double x, required double y, required double age}) {
    this.x = x;
    this.y = y;
    this.age = age;
    active = 1;
  }

  void clear() {
    x = 0;
    y = 0;
    age = 0;
    active = 0;
  }
}

/// Retained fixed-capacity input for the CSS-source pink overlay and pointer
/// trail. It replaces the Canvas saveLayer/ImageFilter lane with analytical
/// full-surface fields in the existing Header FragmentProgram.
final class DashboardHeaderTapWaveVisualUniformBank {
  DashboardHeaderTapWaveVisualUniformBank()
    : _trails = List<DashboardHeaderTapWaveTrailFrame>.generate(
        26,
        (_) => DashboardHeaderTapWaveTrailFrame(),
        growable: false,
      );

  final DashboardHeaderTapWaveOverlayFrame overlay =
      DashboardHeaderTapWaveOverlayFrame();
  final List<DashboardHeaderTapWaveTrailFrame> _trails;
  var _activeTrailCount = 0;
  var interactionOpacity = 1.0;
  var trailSize = 82.0;

  List<DashboardHeaderTapWaveTrailFrame> get trails => _trails;
  int get activeTrailCount => _activeTrailCount;

  void update({
    required DashboardHeaderTapWaveState state,
    required Duration elapsed,
  }) {
    state.writeOverlayFrame(timestamp: elapsed, into: overlay);
    interactionOpacity = state.tuning.valueFor('interactionOpacity') / 100;
    trailSize = state.tuning.valueFor('trailSize');
    var index = 0;
    for (final trail in state.trails) {
      if (index == _trails.length) break;
      state.writeTrailFrame(
        trail: trail,
        timestamp: elapsed,
        into: _trails[index],
      );
      if (_trails[index].opacity > 0) index += 1;
    }
    for (var clear = index; clear < _trails.length; clear += 1) {
      _trails[clear].clear();
    }
    _activeTrailCount = index;
  }
}

/// Compact render input. Financial presentation resolves this before paint;
/// the shader knows only palette, time and source effect parameters.
@immutable
final class DashboardHeaderFragmentPaintInput {
  const DashboardHeaderFragmentPaintInput({
    required this.phase,
    required this.elapsed,
    required this.effectShaderId,
    required this.paletteSplitPercent,
    required this.opacity,
    required this.pulse,
    required this.shaderQuality,
    required this.canonicalColors,
    required this.canonicalStops,
    required this.commonSettings,
    required this.deepDrift,
    required this.background,
    required this.interior,
    required this.ripples,
    required this.tapRippleRadiusTravel,
    required this.tapRippleIntensity,
    required this.tapPulseLight,
    required this.tapVisuals,
  });

  final double phase;
  final Duration elapsed;

  /// Stable common-Header shader ABI id, never a Dart enum index.
  final int effectShaderId;
  final double paletteSplitPercent;
  final double opacity;
  final double pulse;

  /// Shader-internal procedural-detail factor; never chooses a mesh topology.
  final double shaderQuality;
  final List<Color> canonicalColors;
  final List<double> canonicalStops;
  final List<double> commonSettings;
  final DashboardHeaderDeepDriftSkeleton deepDrift;
  final DashboardHeaderFragmentPortalInput background;
  final DashboardHeaderFragmentPortalInput interior;
  final DashboardHeaderTapRippleUniformBank ripples;
  final double tapRippleRadiusTravel;
  final double tapRippleIntensity;
  final double tapPulseLight;
  final DashboardHeaderTapWaveVisualUniformBank tapVisuals;
}

@immutable
final class DashboardHeaderFragmentPortalInput {
  const DashboardHeaderFragmentPortalInput({
    required this.enabled,
    required this.effectIndex,
    required this.phase,
    required this.paletteCenterPercent,
    required this.paletteWindowPercent,
    required this.rotationEnabled,
    required this.rotationSpeed,
    required this.settings,
  });

  final bool enabled;
  final int effectIndex;
  final double phase;
  final double paletteCenterPercent;
  final double paletteWindowPercent;
  final bool rotationEnabled;
  final double rotationSpeed;
  final List<double> settings;
}

/// Versioned flattened ABI shared by the retained Flutter [FragmentShader]
/// writer and its runtime-stage contract tests.  The canonical Header field
/// owns the entire palette field; keeping this layout explicit prevents a
/// later bank insertion from silently redirecting Portal values.
abstract final class DashboardHeaderFragmentUniformLayout {
  static const int version = 3;
  static const int canonicalGradientStopCapacity = 10;
  static const int canonicalGradientStopUniformFloatCount = 12;
  static const int canonicalGradientActiveStopCountOffset = 10;

  static const int sizeStart = 0;
  static const int elapsed = 2;
  static const int phase = 3;
  static const int effect = 4;
  static const int opacity = 5;
  static const int paletteSplit = 6;
  static const int pulse = 7;
  static const int shaderQuality = 8;
  static const int gradientColorStart = 9;
  static const int gradientColorFloatCount = 40;
  static const int gradientStopStart = 49;
  static const int commonSettingsStart = 61;
  static const int commonSettingsFloatCount = 40;
  static const int deepBlobStart = 101;
  static const int deepBlobFloatCount = 60;
  static const int deepLayerStart = 161;
  static const int deepLayerFloatCount = 12;
  static const int backgroundEnabled = 173;
  static const int backgroundEffect = 174;
  static const int backgroundPhase = 175;
  static const int backgroundCenter = 176;
  static const int backgroundWindow = 177;
  static const int backgroundRotationEnabled = 178;
  static const int backgroundRotationSpeed = 179;
  static const int backgroundSettingsStart = 180;
  static const int interiorEnabled = 192;
  static const int interiorEffect = 193;
  static const int interiorPhase = 194;
  static const int interiorCenter = 195;
  static const int interiorWindow = 196;
  static const int interiorRotationEnabled = 197;
  static const int interiorRotationSpeed = 198;
  static const int interiorSettingsStart = 199;
  static const int portalSettingsFloatCount = 12;
  static const int rippleCount = 211;
  static const int tapVisualStart = 255;
  static const int trailStart = 264;
  static const int floatCount = 368;

  /// Emits exactly the scalar order declared in
  /// `dashboard_header_field.frag`. The production writer supplies
  /// [setFloat] directly to [ui.FragmentShader.setFloat], so this is not a
  /// detached test serialization.
  static void write({
    required Size size,
    required DashboardHeaderFragmentPaintInput input,
    required void Function(int index, double value) setFloat,
  }) {
    var index = 0;
    void f(double value) {
      setFloat(index++, value.isFinite ? value : 0);
    }

    void color(Color color) {
      f(color.r);
      f(color.g);
      f(color.b);
      f(color.a);
    }

    void bank(List<double> values, int size) {
      for (var item = 0; item < size; item += 1) {
        f(item < values.length ? values[item] : 0);
      }
    }

    f(size.width);
    f(size.height);
    f(input.elapsed.inMicroseconds / Duration.microsecondsPerSecond);
    f(input.phase);
    f(input.effectShaderId.toDouble());
    f(input.opacity);
    f(input.paletteSplitPercent / 100);
    f(input.pulse);
    f(input.shaderQuality);
    assert(index == gradientColorStart);
    final fallbackColor = input.canonicalColors.isEmpty
        ? const Color(0xff000000)
        : input.canonicalColors.last;
    for (
      var colorIndex = 0;
      colorIndex < canonicalGradientStopCapacity;
      colorIndex += 1
    ) {
      color(
        colorIndex < input.canonicalColors.length
            ? input.canonicalColors[colorIndex]
            : fallbackColor,
      );
    }
    assert(index == gradientStopStart);
    final activeStopCount = math.max(
      2,
      math.min(
        canonicalGradientStopCapacity,
        math.min(input.canonicalColors.length, input.canonicalStops.length),
      ),
    );
    for (
      var stopIndex = 0;
      stopIndex < canonicalGradientStopUniformFloatCount;
      stopIndex += 1
    ) {
      if (stopIndex == canonicalGradientActiveStopCountOffset) {
        f(activeStopCount.toDouble());
      } else {
        f(
          stopIndex < canonicalGradientStopCapacity &&
                  stopIndex < input.canonicalStops.length
              ? input.canonicalStops[stopIndex]
              : 1,
        );
      }
    }
    assert(index == commonSettingsStart);
    bank(input.commonSettings, commonSettingsFloatCount);
    assert(index == deepBlobStart);
    bank(input.deepDrift.blobStorage, deepBlobFloatCount);
    assert(index == deepLayerStart);
    bank(input.deepDrift.layerStorage, deepLayerFloatCount);
    assert(index == backgroundEnabled);
    _writePortal(f, input.background);
    assert(index == interiorEnabled);
    _writePortal(f, input.interior);
    assert(index == rippleCount);
    f(input.ripples.activeCount.toDouble());
    f(input.tapRippleRadiusTravel);
    f(input.tapRippleIntensity);
    f(input.tapPulseLight);
    for (final slot in input.ripples.slots) {
      f(slot.x);
      f(slot.y);
      f(slot.age);
      f(slot.active);
    }
    assert(index == tapVisualStart);
    f(input.tapVisuals.overlay.active);
    f(input.tapVisuals.overlay.x);
    f(input.tapVisuals.overlay.y);
    f(input.tapVisuals.overlay.opacity);
    f(input.tapVisuals.overlay.scale);
    f(input.tapVisuals.overlay.blur);
    f(input.tapVisuals.interactionOpacity);
    f(input.tapVisuals.activeTrailCount.toDouble());
    f(input.tapVisuals.trailSize);
    assert(index == trailStart);
    for (final trail in input.tapVisuals.trails) {
      f(trail.x);
      f(trail.y);
      f(trail.opacity);
      f(trail.scale);
    }
    assert(index == floatCount);
  }

  static void _writePortal(
    void Function(double value) f,
    DashboardHeaderFragmentPortalInput value,
  ) {
    f(value.enabled ? 1 : 0);
    f(value.effectIndex.toDouble());
    f(value.phase);
    f(value.paletteCenterPercent / 100);
    f(value.paletteWindowPercent / 100);
    f(value.rotationEnabled ? 1 : 0);
    f(value.rotationSpeed / 100);
    for (var index = 0; index < portalSettingsFloatCount; index += 1) {
      f(index < value.settings.length ? value.settings[index] : 0);
    }
  }
}

/// Retained runtime-shader owner. Its [ChangeNotifier] is listened to only by
/// the Header [CustomPainter], so async shader readiness cannot publish a
/// Dashboard/Budget semantic state or rebuild Header content.
final class DashboardHeaderFragmentBackend extends ChangeNotifier {
  /// The Header's canonical palette supports up to ten source knots. Retain
  /// every active one through the runtime shader ABI; four was the old
  /// endpoint-era cap.
  static const int canonicalGradientStopCapacity =
      DashboardHeaderFragmentUniformLayout.canonicalGradientStopCapacity;

  DashboardHeaderFragmentBackend({bool loadProgram = true}) {
    if (loadProgram) _load();
  }

  factory DashboardHeaderFragmentBackend.forTesting() =>
      DashboardHeaderFragmentBackend(loadProgram: false);

  static const String asset = 'shaders/dashboard_header_field.frag';
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  Object? _failure;
  bool _disposed = false;
  int _programCreations = 0;
  int _shaderCreations = 0;
  int _configurationGeneration = 0;

  Object get backendIdentity => this;
  Object get programIdentity => _program ?? this;
  Object get shaderIdentity => _shader ?? this;
  bool get isReady => _shader != null;
  Object? get failure => _failure;
  int get programCreations => _programCreations;
  int get shaderCreations => _shaderCreations;
  int get configurationGeneration => _configurationGeneration;
  int get dartSurfaceFieldSamplesPerTick => 0;

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(asset);
      if (_disposed) return;
      _program = program;
      _shader = program.fragmentShader();
      _programCreations += 1;
      _shaderCreations += 1;
      notifyListeners();
    } catch (error) {
      if (_disposed) return;
      _failure = error;
      notifyListeners();
    }
  }

  void markConfigurationChanged() => _configurationGeneration += 1;
  void markPhaseTick() {}

  bool paint(
    Canvas canvas,
    Size size, {
    required DashboardHeaderFragmentRenderPlan plan,
    required DashboardHeaderFragmentPaintInput input,
  }) {
    final shader = _shader;
    if (shader == null ||
        plan.backend != DashboardHeaderRenderBackend.fragmentShader ||
        size.isEmpty) {
      return false;
    }
    _writeUniforms(shader, size, input);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    return true;
  }

  void _writeUniforms(
    ui.FragmentShader shader,
    Size size,
    DashboardHeaderFragmentPaintInput input,
  ) => DashboardHeaderFragmentUniformLayout.write(
    size: size,
    input: input,
    setFloat: shader.setFloat,
  );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
