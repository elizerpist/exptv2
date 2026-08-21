import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Pure, deterministic parts of the Fluvi-native Deep Drift material field.
/// The fragment shader owns full-surface evaluation; these helpers freeze the
/// compact blob contract and make its math regression-testable in Dart.
abstract final class DashboardHeaderDeepDriftMath {
  static double cubicKernel(double r2) {
    if (!r2.isFinite || r2 <= 0) return r2 == 0 ? 1 : 0;
    if (r2 >= 1) return 0;
    final h = 1 - r2;
    return h * h * (3 - 2 * h);
  }

  static double cubicKernelDerivative(double r2) {
    if (!r2.isFinite || r2 <= 0 || r2 >= 1) return 0;
    final h = 1 - r2;
    return -6 * h * (1 - h);
  }

  static DashboardHeaderDeepDriftBlobSample sampleBlob({
    required double pointX,
    required double pointY,
    required double centerX,
    required double centerY,
    required double inverseRadiusX,
    required double inverseRadiusY,
  }) {
    final qx = (pointX - centerX) * inverseRadiusX;
    final qy = (pointY - centerY) * inverseRadiusY;
    final r2 = qx * qx + qy * qy;
    final derivative = cubicKernelDerivative(r2);
    return DashboardHeaderDeepDriftBlobSample(
      r2: r2,
      density: cubicKernel(r2),
      gradientX: derivative * 2 * qx * inverseRadiusX,
      gradientY: derivative * 2 * qy * inverseRadiusY,
    );
  }

  static DashboardHeaderDeepDriftDepthBWeights depthBWeights(
    double separation,
  ) {
    final safe = separation.clamp(0.0, 1.0).toDouble();
    return DashboardHeaderDeepDriftDepthBWeights(
      near: .5 + .25 * safe,
      middle: .5,
      far: .5 - .25 * safe,
    );
  }

  /// Near is deliberately first: every following layer is attenuated by the
  /// already-accumulated front transmittance.
  static double composeFrontToBack({
    required double base,
    required DashboardHeaderDeepDriftLayerContribution near,
    required DashboardHeaderDeepDriftLayerContribution middle,
    required DashboardHeaderDeepDriftLayerContribution far,
  }) {
    var accumulated = 0.0;
    var transmittance = 1.0;
    for (final layer in <DashboardHeaderDeepDriftLayerContribution>[
      near,
      middle,
      far,
    ]) {
      final alpha = layer.alpha.clamp(0.0, 1.0).toDouble();
      accumulated += transmittance * layer.color * alpha;
      transmittance *= 1 - alpha;
    }
    return accumulated + transmittance * base;
  }
}

@immutable
final class DashboardHeaderDeepDriftBlobSample {
  const DashboardHeaderDeepDriftBlobSample({
    required this.r2,
    required this.density,
    required this.gradientX,
    required this.gradientY,
  });

  final double r2;
  final double density;
  final double gradientX;
  final double gradientY;
}

@immutable
final class DashboardHeaderDeepDriftDepthBWeights {
  const DashboardHeaderDeepDriftDepthBWeights({
    required this.near,
    required this.middle,
    required this.far,
  });

  final double near;
  final double middle;
  final double far;
}

@immutable
final class DashboardHeaderDeepDriftLayerContribution {
  const DashboardHeaderDeepDriftLayerContribution({
    required this.color,
    required this.alpha,
  });

  final double color;
  final double alpha;
}

/// Retained O(15) CPU transform skeleton for the shader's fifteen compact
/// blobs. Its storage is never replaced during Header phase ticks.
final class DashboardHeaderDeepDriftSkeleton {
  static const int layerCount = 3;
  static const int blobsPerLayer = 5;
  static const int blobCount = layerCount * blobsPerLayer;
  static const int _valuesPerBlob = 4;
  static const int _valuesPerLayer = 4;

  static const List<double> _baseX = <double>[
    .23,
    .48,
    .76,
    .36,
    .65,
    .18,
    .47,
    .73,
    .33,
    .82,
    .28,
    .57,
    .79,
    .42,
    .68,
  ];
  static const List<double> _baseY = <double>[
    .28,
    .18,
    .34,
    .70,
    .68,
    .22,
    .43,
    .25,
    .74,
    .62,
    .36,
    .20,
    .54,
    .78,
    .70,
  ];
  static const List<double> _baseRadiusX = <double>[
    .30,
    .37,
    .32,
    .34,
    .29,
    .38,
    .33,
    .40,
    .29,
    .36,
    .43,
    .39,
    .35,
    .46,
    .41,
  ];
  static const List<double> _baseRadiusY = <double>[
    .24,
    .31,
    .28,
    .36,
    .27,
    .31,
    .26,
    .35,
    .32,
    .29,
    .39,
    .34,
    .30,
    .42,
    .36,
  ];

  final List<double> _blobStorage = List<double>.filled(
    blobCount * _valuesPerBlob,
    0,
    growable: false,
  );
  final List<double> _layerStorage = List<double>.filled(
    layerCount * _valuesPerLayer,
    0,
    growable: false,
  );

  List<double> get blobStorage => _blobStorage;
  List<double> get layerStorage => _layerStorage;

  /// The packed [settings] are in the exact Deep Drift catalog order.
  void advance({required Duration elapsed, required List<double> settings}) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final strength = _setting(settings, 0, .82);
    final speed = _setting(settings, 1, .32);
    final blobScale = _setting(settings, 2, 1);
    final anisotropy = _setting(settings, 3, .55);
    final depthSeparation = _setting(settings, 8, .72);
    final driftSpread = _setting(settings, 10, .62);
    final breathingAmount = _setting(settings, 13, .06);
    final breathingSpeed = _setting(settings, 14, .25);
    final t = seconds * speed;

    for (var layer = 0; layer < layerCount; layer += 1) {
      final layerOffset = layer * _valuesPerLayer;
      final depth = layer / (layerCount - 1);
      final layerPhase = .47 + layer * 1.73;
      final angle = t * (.13 + layer * .025) + layerPhase;
      final breathScale = switch (layer) {
        0 => 1.0,
        1 => .625,
        _ => .375,
      };
      final breathing =
          math.sin(
            seconds * breathingSpeed * (.92 + layer * .11) + layerPhase,
          ) *
          breathingAmount *
          breathScale;
      _layerStorage[layerOffset] = math.cos(angle);
      _layerStorage[layerOffset + 1] = math.sin(angle);
      _layerStorage[layerOffset + 2] = breathing;
      _layerStorage[layerOffset + 3] = depthSeparation * depth;
    }

    for (var index = 0; index < blobCount; index += 1) {
      final layer = index ~/ blobsPerLayer;
      final layerOffset = layer * _valuesPerLayer;
      final output = index * _valuesPerBlob;
      final depth = layer / (layerCount - 1);
      final layerMotion = 1 - depth * .46;
      final phase = .41 + index * 1.137;
      final motion = driftSpread * strength * layerMotion;
      final driftX =
          motion *
          (.055 * math.sin(t * (.63 + index * .017) + phase) +
              .018 * math.sin(t * (1.17 + index * .011) + phase * 2.1));
      final driftY =
          motion *
          (.046 * math.cos(t * (.53 + index * .019) + phase * 1.4) +
              .015 * math.sin(t * (.97 + index * .013) + phase * .7));
      final breathing = _layerStorage[layerOffset + 2];
      final scale = math.max(.08, blobScale * (1 + breathing));
      final stretch =
          1 + anisotropy * (.20 + .16 * math.sin(.71 + index * .93));
      _blobStorage[output] = (_baseX[index] + driftX).clamp(.0, 1.0);
      _blobStorage[output + 1] = (_baseY[index] + driftY).clamp(.0, 1.0);
      _blobStorage[output + 2] =
          1 / math.max(.04, _baseRadiusX[index] * scale * stretch);
      _blobStorage[output + 3] =
          1 / math.max(.04, _baseRadiusY[index] * scale / stretch);
    }
  }

  static double _setting(List<double> values, int index, double fallback) =>
      index < values.length && values[index].isFinite
      ? values[index]
      : fallback;
}
