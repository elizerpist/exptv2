import 'dart:math' as math;

import 'limit_allocation_manager.dart';

class LimitSliderRange {
  const LimitSliderRange({
    required this.value,
    required this.max,
    required this.divisions,
    required this.enabled,
  });

  static const fallbackMax = 100000.0;

  final double value;
  final double max;
  final int divisions;
  final bool enabled;

  static LimitSliderRange unconstrained({
    required double amount,
    required double rememberedMax,
  }) {
    final max = math.max(fallbackMax, math.max(amount, rememberedMax));
    return _build(amount: amount, max: max, enabled: true);
  }

  static LimitSliderRange constrained({
    required double amount,
    required double rememberedMax,
    required double maxAllowed,
    required bool hasExistingLimit,
  }) {
    if (maxAllowed <= 0 && !hasExistingLimit) {
      return _build(amount: 0, max: 1, enabled: false);
    }
    final max = math.max(maxAllowed, math.max(amount, rememberedMax));
    return _build(amount: amount, max: math.max(max, 1), enabled: true);
  }

  static LimitSliderRange _build({
    required double amount,
    required double max,
    required bool enabled,
  }) {
    final safeMax = max <= 0 ? 1.0 : max;
    return LimitSliderRange(
      value: amount.clamp(0.0, safeMax).toDouble(),
      max: safeMax,
      divisions: LimitAllocationManager.sliderDivisions(safeMax),
      enabled: enabled,
    );
  }
}
