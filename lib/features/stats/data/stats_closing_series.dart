import 'dart:math' as math;

import '../../transactions/models/transaction_category.dart';
import 'stats_year_data.dart';

class StatsClosingSeries {
  const StatsClosingSeries({
    required this.driftMarker,
    required this.driftGradientHexes,
    required this.closePulseBars,
    required this.monthlyCloseBars,
  });

  final double driftMarker;
  final List<String> driftGradientHexes;
  final List<StatsClosePulseBar> closePulseBars;
  final List<StatsMonthlyCloseBar> monthlyCloseBars;

  static const closingDriftGradient = [
    '#EF4444',
    '#FEE2E2',
    '#FFFFFF',
    '#DCFCE7',
    '#22C55E',
  ];

  static StatsClosingSeries fromYearData(StatsYearData data) {
    return fromMonthCloses(
      activeType: data.activeType,
      closes: data.graphMonths.map((month) => month.closingAmount).toList(),
      thresholdHitDays: data.graphMonths
          .map((month) => month.thresholdHitDays)
          .toList(),
    );
  }

  static StatsClosingSeries fromMonthCloses({
    required TransactionType activeType,
    required List<double> closes,
    required List<int> thresholdHitDays,
  }) {
    final deltas = _deltas(closes);
    final pressureDeltas = [
      for (final delta in deltas)
        activeType == TransactionType.expense ? delta : -delta,
    ];
    return StatsClosingSeries(
      driftMarker: _driftMarker(activeType: activeType, deltas: deltas),
      driftGradientHexes: closingDriftGradient,
      closePulseBars: _closePulseBars(
        activeMonthCount: closes.length,
        pressureDeltas: pressureDeltas,
      ),
      monthlyCloseBars: [
        for (var i = 0; i < closes.length; i += 1)
          StatsMonthlyCloseBar(
            monthIndex: i,
            amount: closes[i],
            thresholdHitDays: i < thresholdHitDays.length
                ? thresholdHitDays[i]
                : 0,
            barColorHex: activeType == TransactionType.expense
                ? '#EF4444'
                : '#22C55E',
            secondaryBarColorHex: activeType == TransactionType.expense
                ? '#FCA5A5'
                : '#86EFAC',
            thresholdPointColorHex: activeType == TransactionType.expense
                ? '#EF4444'
                : '#22C55E',
          ),
      ],
    );
  }

  static List<double> _deltas(List<double> closes) {
    if (closes.length < 2) return const <double>[];
    return [
      for (var i = 1; i < closes.length; i += 1) closes[i] - closes[i - 1],
    ];
  }

  static double _driftMarker({
    required TransactionType activeType,
    required List<double> deltas,
  }) {
    if (deltas.isEmpty) return 0.5;
    final maxAbsDelta = deltas.fold<double>(
      0,
      (max, delta) => math.max(max, delta.abs()),
    );
    if (maxAbsDelta == 0) return 0.5;
    final normalized = [
      for (final delta in deltas)
        (activeType == TransactionType.expense ? -delta : delta) / maxAbsDelta,
    ];
    final drift =
        normalized.fold<double>(0, (sum, value) => sum + value) /
        normalized.length;
    return (0.5 + 0.5 * drift).clamp(0.0, 1.0).toDouble();
  }

  static List<StatsClosePulseBar> _closePulseBars({
    required int activeMonthCount,
    required List<double> pressureDeltas,
  }) {
    if (pressureDeltas.isEmpty) return const <StatsClosePulseBar>[];
    final windows = _pulseWindows(activeMonthCount);
    final short = _ema(pressureDeltas, windows.shortWindow);
    final long = _ema(pressureDeltas, windows.longWindow);
    return [
      for (var i = 0; i < pressureDeltas.length; i += 1)
        StatsClosePulseBar(
          index: i + 1,
          value: short[i] - long[i],
          colorHex: short[i] - long[i] >= 0 ? '#EF4444' : '#22C55E',
        ),
    ];
  }

  static _ClosePulseWindows _pulseWindows(int activeMonthCount) {
    if (activeMonthCount < 5) {
      return const _ClosePulseWindows(shortWindow: 1, longWindow: 3);
    }
    if (activeMonthCount <= 8) {
      return const _ClosePulseWindows(shortWindow: 2, longWindow: 4);
    }
    return const _ClosePulseWindows(shortWindow: 3, longWindow: 6);
  }

  static List<double> _ema(List<double> values, int window) {
    if (values.isEmpty) return const <double>[];
    final safeWindow = math.max(1, window);
    final multiplier = 2 / (safeWindow + 1);
    final output = <double>[values.first];
    for (final value in values.skip(1)) {
      output.add((value - output.last) * multiplier + output.last);
    }
    return output;
  }
}

class StatsClosePulseBar {
  const StatsClosePulseBar({
    required this.index,
    required this.value,
    required this.colorHex,
  });

  final int index;
  final double value;
  final String colorHex;
}

class StatsMonthlyCloseBar {
  const StatsMonthlyCloseBar({
    required this.monthIndex,
    required this.amount,
    required this.thresholdHitDays,
    required this.barColorHex,
    required this.secondaryBarColorHex,
    required this.thresholdPointColorHex,
  });

  final int monthIndex;
  final double amount;
  final int thresholdHitDays;
  final String barColorHex;
  final String secondaryBarColorHex;
  final String thresholdPointColorHex;
}

class _ClosePulseWindows {
  const _ClosePulseWindows({
    required this.shortWindow,
    required this.longWindow,
  });

  final int shortWindow;
  final int longWindow;
}
