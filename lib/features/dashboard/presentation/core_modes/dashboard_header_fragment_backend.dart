import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dashboard_header_tap_wave.dart';

/// The production max-fidelity route.  The legacy [ui.Vertices] renderer is
/// intentionally a low-quality fallback: it evaluates a procedural field at
/// sparse nodes, whereas this backend evaluates it for every painted fragment.
enum DashboardHeaderRenderBackend { legacyMesh, fragmentShader }

enum DashboardHeaderFieldEvaluation { sparseVertices, perFragment }

@immutable
final class DashboardHeaderFragmentRenderPlan {
  const DashboardHeaderFragmentRenderPlan._({
    required this.backend,
    required this.fieldEvaluation,
    required this.logicalSize,
    required this.physicalSize,
    required this.renderScale,
    required this.legacyMeshColumns,
    required this.legacyMeshRows,
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
    // High quality is deliberately a different backend, not a denser Dart
    // grid. It has no mesh dimensions at all.
    if (boundedScale >= 1) {
      return DashboardHeaderFragmentRenderPlan._(
        backend: DashboardHeaderRenderBackend.fragmentShader,
        fieldEvaluation: DashboardHeaderFieldEvaluation.perFragment,
        logicalSize: safeLogical,
        physicalSize: Size(
          (safeLogical.width * dpr).ceilToDouble(),
          (safeLogical.height * dpr).ceilToDouble(),
        ),
        renderScale: boundedScale,
        legacyMeshColumns: null,
        legacyMeshRows: null,
      );
    }
    return DashboardHeaderFragmentRenderPlan._(
      backend: DashboardHeaderRenderBackend.legacyMesh,
      fieldEvaluation: DashboardHeaderFieldEvaluation.sparseVertices,
      logicalSize: safeLogical,
      physicalSize: Size(
        (safeLogical.width * dpr).ceilToDouble(),
        (safeLogical.height * dpr).ceilToDouble(),
      ),
      renderScale: boundedScale,
      legacyMeshColumns: math.max(
        16,
        (safeLogical.width * boundedScale / 4).round(),
      ),
      legacyMeshRows: math.max(
        6,
        (safeLogical.height * boundedScale / 4).round(),
      ),
    );
  }

  final DashboardHeaderRenderBackend backend;
  final DashboardHeaderFieldEvaluation fieldEvaluation;
  final Size logicalSize;
  final Size physicalSize;
  final double renderScale;
  final int? legacyMeshColumns;
  final int? legacyMeshRows;

  int get dartSurfaceFieldSamplesPerTick => 0;
}

/// Fixed-size GPU input for the already bounded Color Lab ripple bank.  No
/// pointer path can turn this into an unbounded per-frame allocation.
@immutable
final class DashboardHeaderTapRippleUniformBank {
  const DashboardHeaderTapRippleUniformBank._({
    required this.activeCount,
    required this.slots,
  });

  factory DashboardHeaderTapRippleUniformBank.fromState({
    required DashboardHeaderTapWaveState state,
    required Duration elapsed,
  }) {
    final slots = List<DashboardHeaderTapRippleUniformSlot>.filled(
      10,
      DashboardHeaderTapRippleUniformSlot.empty,
      growable: false,
    );
    var index = 0;
    for (final ripple in state.ripples) {
      if (index == slots.length) break;
      final age = elapsed - ripple.startedAt;
      if (age < Duration.zero || age >= const Duration(milliseconds: 1685)) {
        continue;
      }
      slots[index++] = DashboardHeaderTapRippleUniformSlot(
        x: ripple.origin.dx,
        y: ripple.origin.dy,
        age: age.inMicroseconds / 1684800,
        active: 1,
      );
    }
    return DashboardHeaderTapRippleUniformBank._(
      activeCount: index,
      slots: List<DashboardHeaderTapRippleUniformSlot>.unmodifiable(slots),
    );
  }

  final int activeCount;
  final List<DashboardHeaderTapRippleUniformSlot> slots;
  int get dartSurfaceFieldSamplesPerTick => 0;
}

@immutable
final class DashboardHeaderTapRippleUniformSlot {
  const DashboardHeaderTapRippleUniformSlot({
    required this.x,
    required this.y,
    required this.age,
    required this.active,
  });

  static const DashboardHeaderTapRippleUniformSlot empty =
      DashboardHeaderTapRippleUniformSlot(x: 0, y: 0, age: 0, active: 0);

  final double x;
  final double y;
  final double age;
  final double active;
}

/// Compact render input. Financial presentation resolves this before paint;
/// the shader knows only palette, time and source effect parameters.
@immutable
final class DashboardHeaderFragmentPaintInput {
  const DashboardHeaderFragmentPaintInput({
    required this.phase,
    required this.elapsed,
    required this.effectIndex,
    required this.paletteSplitPercent,
    required this.opacity,
    required this.pulse,
    required this.colorA,
    required this.colorB,
    required this.canonicalColors,
    required this.canonicalStops,
    required this.commonSettings,
    required this.background,
    required this.interior,
    required this.ripples,
    required this.tapRippleRadiusTravel,
    required this.tapRippleIntensity,
    required this.tapPulseLight,
  });

  final double phase;
  final Duration elapsed;
  final int effectIndex;
  final double paletteSplitPercent;
  final double opacity;
  final double pulse;
  final Color colorA;
  final Color colorB;
  final List<Color> canonicalColors;
  final List<double> canonicalStops;
  final List<double> commonSettings;
  final DashboardHeaderFragmentPortalInput background;
  final DashboardHeaderFragmentPortalInput interior;
  final DashboardHeaderTapRippleUniformBank ripples;
  final double tapRippleRadiusTravel;
  final double tapRippleIntensity;
  final double tapPulseLight;
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

/// Retained runtime-shader owner. Its [ChangeNotifier] is listened to only by
/// the Header [CustomPainter], so async shader readiness cannot publish a
/// Dashboard/Budget semantic state or rebuild Header content.
final class DashboardHeaderFragmentBackend extends ChangeNotifier {
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
  ) {
    var index = 0;
    void f(double value) =>
        shader.setFloat(index++, value.isFinite ? value : 0);
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
    f(input.effectIndex.toDouble());
    f(input.opacity);
    f(input.paletteSplitPercent / 100);
    f(input.pulse);
    color(input.colorA);
    color(input.colorB);
    for (var colorIndex = 0; colorIndex < 4; colorIndex += 1) {
      color(
        colorIndex < input.canonicalColors.length
            ? input.canonicalColors[colorIndex]
            : input.canonicalColors.last,
      );
    }
    for (var stopIndex = 0; stopIndex < 4; stopIndex += 1) {
      f(
        stopIndex < input.canonicalStops.length
            ? input.canonicalStops[stopIndex]
            : 1,
      );
    }
    bank(input.commonSettings, 40);
    _writePortal(f, input.background);
    _writePortal(f, input.interior);
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
    for (var index = 0; index < 12; index += 1) {
      f(index < value.settings.length ? value.settings[index] : 0);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
