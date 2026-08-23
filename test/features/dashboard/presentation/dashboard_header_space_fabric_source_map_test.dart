import 'dart:math' as math;

import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _spaceFabricEffects = <DashboardHeaderEffectId>[
  DashboardHeaderEffectId.metricBloom,
  DashboardHeaderEffectId.gravitationalFabric,
  DashboardHeaderEffectId.breathingMetric,
  DashboardHeaderEffectId.tidalCurvature,
];

void main() {
  group('Space Fabric source-map temporal contract', () {
    for (final effect in _spaceFabricEffects) {
      test(
        'RED ${effect.name} materially evolves its source map at defaults',
        () {
          final settings = _defaultSettings(effect);
          final metrics = _sourceMapDelta(
            effect: effect,
            settings: settings,
            seconds: 3,
          );

          // .008 normalized source space is several physical Header pixels at
          // the production 400 px-scale target. This makes numerical motion
          // insufficient: a broad portion of the actual transported material
          // must move.
          expect(
            metrics.mean,
            greaterThanOrEqualTo(.006),
            reason: '$effect source-map mean delta: $metrics',
          );
          expect(
            metrics.p90,
            greaterThanOrEqualTo(.012),
            reason: '$effect: $metrics',
          );
          expect(
            metrics.movedFraction,
            greaterThanOrEqualTo(.25),
            reason: '$effect: $metrics',
          );
        },
      );

      test('${effect.name} remains topology safe while it evolves', () {
        final settings = _defaultSettings(effect);
        for (final seconds in <double>[0, 1, 3, 5, 8]) {
          final range = _jacobianRange(
            effect: effect,
            settings: settings,
            seconds: seconds,
          );
          expect(
            range.min,
            greaterThan(0),
            reason: '$effect at ${seconds}s: $range',
          );
        }
      });

      test('${effect.name} freezes its source map at speed zero', () {
        final settings = _defaultSettings(effect)..['speed'] = 0;
        final metrics = _sourceMapDelta(
          effect: effect,
          settings: settings,
          seconds: 60,
        );
        expect(metrics.max, lessThan(1e-12), reason: '$effect: $metrics');
      });
    }

    test('RED mode-count aggregation does not collapse Metric Bloom temporal '
        'source-map energy', () {
      final defaultSettings = _defaultSettings(
        DashboardHeaderEffectId.metricBloom,
      );
      final oneField = _sourceMapDelta(
        effect: DashboardHeaderEffectId.metricBloom,
        settings: <String, double>{...defaultSettings, 'fieldCount': 1},
        seconds: 3,
      );
      final defaultFields = _sourceMapDelta(
        effect: DashboardHeaderEffectId.metricBloom,
        settings: defaultSettings,
        seconds: 3,
      );
      expect(
        defaultFields.mean,
        greaterThanOrEqualTo(oneField.mean * .45),
        reason:
            'default=${defaultFields.mean} oneField=${oneField.mean}; '
            'more analytic fields must not erase visible temporal energy',
      );
    });
  });
}

Map<String, double> _defaultSettings(
  DashboardHeaderEffectId effect,
) => <String, double>{
  for (final control in DashboardHeaderEffectCatalog.effectFor(effect).controls)
    control.id: control.defaultValue,
};

_SourceMapDelta _sourceMapDelta({
  required DashboardHeaderEffectId effect,
  required Map<String, double> settings,
  required double seconds,
}) {
  final values = <double>[];
  for (var y = 1; y < 24; y += 1) {
    for (var x = 1; x < 48; x += 1) {
      final uv = _Uv(x / 48, y / 24);
      final start = _spaceFabricSourceUv(
        effect: effect,
        settings: settings,
        uv: uv,
        phase: 0,
      );
      final end = _spaceFabricSourceUv(
        effect: effect,
        settings: settings,
        uv: uv,
        phase: seconds * _value(settings, 'speed'),
      );
      values.add((end - start).length);
    }
  }
  values.sort();
  final total = values.fold<double>(0, (sum, value) => sum + value);
  return _SourceMapDelta(
    mean: total / values.length,
    p50: values[(values.length * .50).floor()],
    p90: values[(values.length * .90).floor()],
    max: values.last,
    movedFraction:
        values.where((value) => value >= .008).length / values.length,
  );
}

_JacobianRange _jacobianRange({
  required DashboardHeaderEffectId effect,
  required Map<String, double> settings,
  required double seconds,
}) {
  const epsilon = .002;
  var minimum = double.infinity;
  var maximum = -double.infinity;
  final phase = seconds * _value(settings, 'speed');
  for (var y = 2; y < 23; y += 1) {
    for (var x = 2; x < 47; x += 1) {
      final uv = _Uv(x / 48, y / 24);
      final xPair = (
        _spaceFabricSourceUv(
          effect: effect,
          settings: settings,
          uv: _Uv(uv.x + epsilon, uv.y),
          phase: phase,
        ),
        _spaceFabricSourceUv(
          effect: effect,
          settings: settings,
          uv: _Uv(uv.x - epsilon, uv.y),
          phase: phase,
        ),
      );
      final yPair = (
        _spaceFabricSourceUv(
          effect: effect,
          settings: settings,
          uv: _Uv(uv.x, uv.y + epsilon),
          phase: phase,
        ),
        _spaceFabricSourceUv(
          effect: effect,
          settings: settings,
          uv: _Uv(uv.x, uv.y - epsilon),
          phase: phase,
        ),
      );
      final dx = (xPair.$1 - xPair.$2) / (2 * epsilon);
      final dy = (yPair.$1 - yPair.$2) / (2 * epsilon);
      final determinant = dx.x * dy.y - dx.y * dy.x;
      minimum = math.min(minimum, determinant);
      maximum = math.max(maximum, determinant);
    }
  }
  return _JacobianRange(minimum, maximum);
}

// This test-only mirror is deliberately restricted to the source-map probe.
// The production authority remains shaders/dashboard_header_field.frag; the
// companion source-contract test keeps the shader lane and its single owned
// phase input explicit. A deterministic mirror is required because a normal
// RGB palette raster cannot encode both sourceUv components independently.
_Uv _spaceFabricSourceUv({
  required DashboardHeaderEffectId effect,
  required Map<String, double> settings,
  required _Uv uv,
  required double phase,
}) {
  final strength = _saturate(_value(settings, 'strength'));
  if (strength == 0) return uv;
  final scale = math.max(.25, _value(settings, 'scale'));
  final seed = _value(settings, 'seed');
  final localTime = phase * 7.0;
  final count = _modeCount(effect, settings);
  var displacement = _Uv.zero;
  for (var index = 0; index < count; index += 1) {
    final i = index.toDouble();
    final phaseOffset = _seedPhase(seed, i + 8);
    final double wander = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'wander'),
      DashboardHeaderEffectId.gravitationalFabric => _value(settings, 'wander'),
      DashboardHeaderEffectId.breathingMetric => _value(settings, 'wander'),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'wander'),
      _ => 0.0,
    };
    final double anisotropy = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'anisotropy'),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'eccentricity',
      ),
      DashboardHeaderEffectId.breathingMetric => _value(settings, 'anisotropy'),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'anisotropy'),
      _ => 0.0,
    };
    final double softness = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'softness'),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'softness',
      ),
      DashboardHeaderEffectId.breathingMetric => _value(settings, 'softness'),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'softness'),
      _ => 0.0,
    };
    final double breathing = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'breathing'),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'precession',
      ),
      DashboardHeaderEffectId.breathingMetric => _value(
        settings,
        'breathingDepth',
      ),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'exchange'),
      _ => 0.0,
    };
    final double compression = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'compression'),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'compensation',
      ),
      DashboardHeaderEffectId.breathingMetric => _value(
        settings,
        'compensation',
      ),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'exchange'),
      _ => 0.0,
    };
    final double magnification = switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(settings, 'magnification'),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'wellStrength',
      ),
      DashboardHeaderEffectId.breathingMetric => _value(
        settings,
        'breathingDepth',
      ),
      DashboardHeaderEffectId.tidalCurvature => _value(settings, 'curvature'),
      _ => 0.0,
    };
    final primaryBreath = math.sin(localTime * (.71 + i * .083) + phaseOffset);
    final secondaryBreath = math.sin(
      localTime * (1.19 + i * .061) + phaseOffset * 1.73,
    );
    final breathingWave = _saturate(
      .5 + primaryBreath * .34 + secondaryBreath * .16,
    );
    final trajectoryGain = switch (effect) {
      DashboardHeaderEffectId.metricBloom => 1.0,
      DashboardHeaderEffectId.gravitationalFabric => 1.32,
      DashboardHeaderEffectId.breathingMetric => 1.10,
      DashboardHeaderEffectId.tidalCurvature => 1.12,
      _ => 1.0,
    };
    final centerRadius = (.20 + wander * .42) * trajectoryGain;
    var center = _Uv(
      .5 +
          math.sin(phaseOffset * 1.31 + localTime * (.53 + i * .037)) *
              centerRadius,
      .5 +
          math.cos(phaseOffset * .83 - localTime * (.41 + i * .029)) *
              centerRadius *
              .72,
    );
    center +=
        _Uv(
          math.sin(localTime * (1.07 + i * .071) + phaseOffset * 1.41),
          math.cos(localTime * (.89 + i * .053) - phaseOffset * 1.19),
        ) *
        (.050 + wander * .095) *
        trajectoryGain;
    if (effect == DashboardHeaderEffectId.tidalCurvature) {
      final pairSign = index.isEven ? -1.0 : 1.0;
      final separation = _value(settings, 'separation');
      center +=
          _Uv(
            math.cos(localTime * .29 + phaseOffset),
            math.sin(localTime * .37 - phaseOffset),
          ) *
          pairSign *
          separation *
          .35;
    }
    final angle =
        phaseOffset +
        localTime * (.17 + anisotropy * .26) +
        i * (1.17 + anisotropy * .39);
    final baseAxis = _lerp(.17, .31, softness) / scale;
    final shapeWave = math.sin(
      localTime * (.91 + i * .047) + phaseOffset * 1.37,
    );
    final aspect =
        _lerp(1, 2.05, anisotropy) *
        math.max(
          .45,
          1 +
              (breathingWave - .5) * (.52 + breathing * .95) +
              shapeWave * (.22 + anisotropy * .18),
        );
    final axes = _Uv(baseAxis * aspect, baseAxis / aspect);
    var localMagnification =
        magnification *
        math.max(
          .12,
          .78 +
              (breathingWave - .5) * (1.05 + breathing * .70) +
              shapeWave * .22,
        );
    if (effect == DashboardHeaderEffectId.tidalCurvature) {
      localMagnification *=
          .58 + breathingWave * _value(settings, 'exchange') * .42;
    }
    displacement += _compensatedKernel(
      uv: uv,
      center: center,
      angle: angle,
      axes: axes,
      magnification: localMagnification,
      compression: compression,
    );
  }
  final variantEnergy = switch (effect) {
    DashboardHeaderEffectId.metricBloom => 7.2,
    DashboardHeaderEffectId.gravitationalFabric => 12.0,
    DashboardHeaderEffectId.breathingMetric => 9.0,
    DashboardHeaderEffectId.tidalCurvature => 9.3,
    _ => 1.0,
  };
  final normalized =
      displacement / math.sqrt(math.max(1, count)) * variantEnergy;
  const limit = .11;
  final limited = normalized / (1 + normalized.length / limit);
  return uv + limited * strength * _boundaryEnvelope(uv);
}

int _modeCount(DashboardHeaderEffectId effect, Map<String, double> settings) =>
    switch (effect) {
      DashboardHeaderEffectId.metricBloom => _value(
        settings,
        'fieldCount',
      ).round().clamp(1, 5).toInt(),
      DashboardHeaderEffectId.gravitationalFabric => _value(
        settings,
        'wellCount',
      ).round().clamp(1, 6).toInt(),
      DashboardHeaderEffectId.breathingMetric => _value(
        settings,
        'regionCount',
      ).round().clamp(1, 4).toInt(),
      DashboardHeaderEffectId.tidalCurvature =>
        (_value(settings, 'pairCount') * 2).round().clamp(2, 6).toInt(),
      _ => 1,
    };

_Uv _compensatedKernel({
  required _Uv uv,
  required _Uv center,
  required double angle,
  required _Uv axes,
  required double magnification,
  required double compression,
}) {
  final relative = uv - center;
  final major = _Uv(math.cos(angle), math.sin(angle));
  final minor = _Uv(-major.y, major.x);
  final local = _Uv(
    relative.dot(major) / math.max(.04, axes.x),
    relative.dot(minor) / math.max(.04, axes.y),
  );
  final radiusSquared = local.dot(local);
  final inner = math.exp(-radiusSquared * 1.45);
  final outer = math.exp(-radiusSquared * .19);
  final metric = -magnification * .145 * inner + compression * .055 * outer;
  return relative * metric;
}

double _seedPhase(double seed, double index) =>
    math.sin(seed * (.00173 + index * .00019) + index * 17.31) * math.pi;

double _boundaryEnvelope(_Uv uv) {
  final edgeX = math.min(uv.x, 1 - uv.x);
  final edgeY = math.min(uv.y, 1 - uv.y);
  return _smooth01(0, .115, edgeX) * _smooth01(0, .115, edgeY);
}

double _value(Map<String, double> values, String key) => values[key] ?? 0;
double _saturate(double value) => value.clamp(0, 1).toDouble();
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _smooth01(double left, double right, double value) {
  final t = _saturate((value - left) / math.max(.000001, right - left));
  return t * t * (3 - 2 * t);
}

final class _Uv {
  const _Uv(this.x, this.y);

  static const zero = _Uv(0, 0);
  final double x;
  final double y;

  double get length => math.sqrt(x * x + y * y);
  double dot(_Uv other) => x * other.x + y * other.y;
  _Uv operator +(_Uv other) => _Uv(x + other.x, y + other.y);
  _Uv operator -(_Uv other) => _Uv(x - other.x, y - other.y);
  _Uv operator *(double scalar) => _Uv(x * scalar, y * scalar);
  _Uv operator /(double scalar) => _Uv(x / scalar, y / scalar);
}

final class _SourceMapDelta {
  const _SourceMapDelta({
    required this.mean,
    required this.p50,
    required this.p90,
    required this.max,
    required this.movedFraction,
  });

  final double mean;
  final double p50;
  final double p90;
  final double max;
  final double movedFraction;

  @override
  String toString() =>
      'mean=$mean p50=$p50 p90=$p90 max=$max movedFraction=$movedFraction';
}

final class _JacobianRange {
  const _JacobianRange(this.min, this.max);
  final double min;
  final double max;

  @override
  String toString() => 'min=$min max=$max';
}
