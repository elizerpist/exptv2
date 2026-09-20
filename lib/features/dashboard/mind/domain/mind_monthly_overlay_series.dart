import 'dart:math' as math;

/// Immutable month-by-month full-versus-current-scope comparison input shared
/// by Mind's Year and Sum visualizations. It owns neither membership nor range
/// selection: callers provide already-admitted full and preview totals.
final class MindMonthlyOverlaySeries {
  MindMonthlyOverlaySeries._({
    required List<MindMonthlyOverlayValue> values,
    required this.scale,
  }) : values = List<MindMonthlyOverlayValue>.unmodifiable(values);

  factory MindMonthlyOverlaySeries.fromTotals({
    required List<int> fullAmounts,
    required List<int> filteredAmounts,
  }) {
    if (fullAmounts.length != filteredAmounts.length) {
      throw ArgumentError.value(
        filteredAmounts,
        'filteredAmounts',
        'Must have one current-scope amount for every full amount.',
      );
    }
    final values = List<MindMonthlyOverlayValue>.generate(fullAmounts.length, (
      index,
    ) {
      final full = math.max(0, fullAmounts[index]);
      final filtered = math.max(0, filteredAmounts[index]);
      // A renderer remains bounded even if an upstream membership contract
      // is temporarily inconsistent. Production call sites additionally
      // retain their directional/full-source assertions at admission.
      return MindMonthlyOverlayValue(
        month: index + 1,
        fullAmount: full,
        filteredAmount: filtered.clamp(0, full).toInt(),
      );
    }, growable: false);
    return MindMonthlyOverlaySeries._(
      values: values,
      scale: MindMonthlyOverlayScale.forMaximum(
        values.fold<int>(
          0,
          (maximum, value) => math.max(maximum, value.fullAmount),
        ),
      ),
    );
  }

  factory MindMonthlyOverlaySeries.fromAmounts({
    required List<int> fullAmounts,
    required List<int> filteredAmounts,
  }) => MindMonthlyOverlaySeries.fromTotals(
    fullAmounts: fullAmounts,
    filteredAmounts: filteredAmounts,
  );

  final List<MindMonthlyOverlayValue> values;
  final MindMonthlyOverlayScale scale;
}

final class MindMonthlyOverlayValue {
  const MindMonthlyOverlayValue({
    required this.month,
    required this.fullAmount,
    required this.filteredAmount,
  });

  final int month;
  final int fullAmount;
  final int filteredAmount;
}

/// Deterministic approximately-five-interval monetary scale used by both
/// overlay surfaces, keeping grid interpretation consistent between Sum/Year.
final class MindMonthlyOverlayScale {
  MindMonthlyOverlayScale._({
    required this.top,
    required this.step,
    required List<int> levels,
  }) : levels = List<int>.unmodifiable(levels);

  factory MindMonthlyOverlayScale.forMaximum(int maximum) {
    if (maximum <= 0) {
      return MindMonthlyOverlayScale._(top: 0, step: 1, levels: const <int>[0]);
    }
    const targetIntervals = 5;
    final rawStep = maximum / targetIntervals;
    final exponent = math.pow(10, (math.log(rawStep) / math.ln10).floor());
    final normalized = rawStep / exponent;
    final factor = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    final step = (factor * exponent).round();
    final top = ((maximum + step - 1) ~/ step) * step;
    return MindMonthlyOverlayScale._(
      top: top,
      step: step,
      levels: List<int>.generate(top ~/ step + 1, (index) => index * step),
    );
  }

  final int top;
  final int step;
  final List<int> levels;
}
