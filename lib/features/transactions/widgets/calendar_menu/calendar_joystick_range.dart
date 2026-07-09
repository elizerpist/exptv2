import 'dart:math' as math;

class CalendarJoystickRange {
  const CalendarJoystickRange({
    required this.min,
    required this.max,
    required this.step,
  });

  factory CalendarJoystickRange.adaptive({
    required double currentValue,
    required double observedMax,
    required double fallbackMax,
  }) {
    const min = 0.0;
    final safeFallback = fallbackMax > min ? fallbackMax : 50000.0;
    final sourceMax = math.max(currentValue, observedMax);
    final rawMax = math.max(
      sourceMax > min ? sourceMax * 1.2 : safeFallback,
      safeFallback,
    );
    final max = _niceCeil(rawMax);
    final step = _niceStep(max / 80);
    return CalendarJoystickRange(min: min, max: max, step: step);
  }

  final double min;
  final double max;
  final double step;

  double clamp(double value) => value.clamp(min, max).toDouble();

  double snap(double value) {
    final snapped = (value / step).round() * step;
    return clamp(snapped.toDouble());
  }

  static double _niceCeil(double value) {
    if (value <= 0) return 50000;
    final exponent = math.pow(10, _log10Floor(value)).toDouble();
    final normalized = value / exponent;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2.5
        ? 2.5
        : normalized <= 5
        ? 5
        : 10;
    return nice * exponent;
  }

  static double _niceStep(double value) {
    if (value <= 100) return 100;
    final exponent = math.pow(10, _log10Floor(value)).toDouble();
    final normalized = value / exponent;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * exponent;
  }

  static int _log10Floor(double value) {
    return (math.log(value) / math.ln10).floor();
  }
}
