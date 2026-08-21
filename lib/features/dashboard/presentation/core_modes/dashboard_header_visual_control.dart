import 'package:flutter/foundation.dart';

/// Source-owned numeric control metadata shared by the Header effect catalogs.
/// A unit belongs to the control metadata rather than the tuner widget so the
/// visual source contract remains testable outside a widget tree.
@immutable
final class DashboardHeaderEffectControl {
  const DashboardHeaderEffectControl({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
    this.unit = '',
  });

  final String id;
  final String label;
  final double min;
  final double max;
  final double step;
  final double defaultValue;
  final String unit;

  double normalize(double candidate) {
    final bounded = candidate.isFinite
        ? candidate.clamp(min, max).toDouble()
        : defaultValue;
    final snapped = min + ((bounded - min) / step).round() * step;
    final decimals = _decimalPlaces(step);
    return decimals == 0
        ? snapped.roundToDouble()
        : double.parse(snapped.toStringAsFixed(decimals));
  }

  static int _decimalPlaces(double value) {
    final text = value.toString();
    final decimal = text.indexOf('.');
    return decimal == -1 ? 0 : text.length - decimal - 1;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderEffectControl &&
      id == other.id &&
      label == other.label &&
      min == other.min &&
      max == other.max &&
      step == other.step &&
      defaultValue == other.defaultValue &&
      unit == other.unit;

  @override
  int get hashCode =>
      Object.hash(id, label, min, max, step, defaultValue, unit);
}
