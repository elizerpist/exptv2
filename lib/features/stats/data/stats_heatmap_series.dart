import 'dart:math' as math;

import 'stats_year_data.dart';

class StatsHeatmapSeries {
  const StatsHeatmapSeries({
    required this.density,
    required this.pulse,
    required this.monthlyBars,
    this.densityLineColorHex = '#06B6D4',
  });

  final List<StatsHeatmapPoint> density;
  final List<StatsHeatmapPulseBar> pulse;
  final List<StatsHeatmapMonthlyBar> monthlyBars;
  final String densityLineColorHex;

  static StatsHeatmapSeries fromYearData(StatsYearData data) {
    final dailyAmounts = <double>[];
    final monthIndexes = <int>[];
    for (
      var monthIndex = 0;
      monthIndex < data.graphMonths.length;
      monthIndex += 1
    ) {
      final month = data.graphMonths[monthIndex];
      dailyAmounts.addAll(month.days.map((day) => day.scopeAmount));
      monthIndexes.addAll(List<int>.filled(month.days.length, monthIndex));
    }
    final windows = _dynamicWindows(dailyAmounts.length);
    return fromDailySamples(
      threshold: data.thresholdValue,
      dailyScopeAmounts: dailyAmounts,
      monthIndexes: monthIndexes,
      densityWindow: windows.density,
      pulseShortWindow: windows.pulseShort,
      pulseLongWindow: windows.pulseLong,
    );
  }

  static StatsHeatmapSeries fromDailySamples({
    required double threshold,
    required List<double> dailyScopeAmounts,
    List<int>? monthIndexes,
    int densityWindow = 14,
    int pulseShortWindow = 5,
    int pulseLongWindow = 14,
  }) {
    final overs = [
      for (final amount in dailyScopeAmounts)
        amount >= threshold && amount > 0
            ? (threshold <= 0
                  ? 0.0
                  : (amount / threshold).clamp(0.0, 3.0).toDouble())
            : 0.0,
    ];
    final densityValues = [
      for (var i = 0; i < dailyScopeAmounts.length; i += 1)
        _rollingDensity(
          threshold: threshold,
          dailyScopeAmounts: dailyScopeAmounts,
          endIndex: i,
          window: densityWindow,
        ),
    ];
    final pulseValues = _pulseValues(
      overs,
      shortWindow: pulseShortWindow,
      longWindow: pulseLongWindow,
    );
    final resolvedMonthIndexes =
        monthIndexes ?? List<int>.filled(dailyScopeAmounts.length, 0);
    return StatsHeatmapSeries(
      density: [
        for (var i = 0; i < densityValues.length; i += 1)
          StatsHeatmapPoint(index: i, value: densityValues[i]),
      ],
      pulse: [
        for (var i = 0; i < pulseValues.length; i += 1)
          StatsHeatmapPulseBar(
            index: i,
            value: pulseValues[i],
            colorHex: pulseValues[i] >= 0 ? '#06B6D4' : '#CBD5E1',
          ),
      ],
      monthlyBars: _monthlyBars(
        overs: overs,
        monthIndexes: resolvedMonthIndexes,
      ),
    );
  }

  static double _rollingDensity({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required int endIndex,
    required int window,
  }) {
    if (dailyScopeAmounts.isEmpty) return 0;
    final safeWindow = math.max(1, window).toInt();
    final start = math.max(0, endIndex - safeWindow + 1).toInt();
    final values = dailyScopeAmounts.sublist(start, endIndex + 1);
    final hotDays = values
        .where((amount) => amount >= threshold && amount > 0)
        .length;
    return hotDays / values.length;
  }

  static List<double> _pulseValues(
    List<double> overs, {
    required int shortWindow,
    required int longWindow,
  }) {
    if (overs.isEmpty) return const <double>[];
    final short = _ema(overs, shortWindow);
    final long = _ema(overs, longWindow);
    return [for (var i = 0; i < overs.length; i += 1) short[i] - long[i]];
  }

  static List<StatsHeatmapMonthlyBar> _monthlyBars({
    required List<double> overs,
    required List<int> monthIndexes,
  }) {
    final byMonth = <int, List<double>>{};
    for (var i = 0; i < overs.length; i += 1) {
      final monthIndex = i < monthIndexes.length ? monthIndexes[i] : 0;
      byMonth.putIfAbsent(monthIndex, () => <double>[]).add(overs[i]);
    }
    return [
      for (final entry in byMonth.entries)
        StatsHeatmapMonthlyBar(
          monthIndex: entry.key,
          heatLoad: entry.value.fold<double>(0, (sum, value) => sum + value),
          hotDayCount: entry.value.where((value) => value > 0).length,
          segments: _segments(entry.value),
        ),
    ];
  }

  static List<StatsHeatmapLoadSegment> _segments(List<double> overs) {
    var low = 0.0;
    var middle = 0.0;
    var high = 0.0;
    for (final over in overs) {
      if (over <= 0) continue;
      low += math.min(over, 1);
      if (over > 1) middle += math.min(over - 1, 1);
      if (over > 2) high += math.min(over - 2, 1);
    }
    return [
      if (low > 0)
        StatsHeatmapLoadSegment(label: '1x', value: low, colorHex: '#DDF8FD'),
      if (middle > 0)
        StatsHeatmapLoadSegment(
          label: '2x',
          value: middle,
          colorHex: '#67E8F9',
        ),
      if (high > 0)
        StatsHeatmapLoadSegment(
          label: '3x cap',
          value: high,
          colorHex: '#06B6D4',
        ),
    ];
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

  static _HeatmapWindows _dynamicWindows(int dayCount) {
    if (dayCount <= 45) {
      return const _HeatmapWindows(density: 7, pulseShort: 3, pulseLong: 7);
    }
    if (dayCount <= 180) {
      return const _HeatmapWindows(density: 14, pulseShort: 5, pulseLong: 14);
    }
    return const _HeatmapWindows(density: 21, pulseShort: 7, pulseLong: 21);
  }
}

class StatsHeatmapPoint {
  const StatsHeatmapPoint({required this.index, required this.value});

  final int index;
  final double value;
}

class StatsHeatmapPulseBar {
  const StatsHeatmapPulseBar({
    required this.index,
    required this.value,
    required this.colorHex,
  });

  final int index;
  final double value;
  final String colorHex;
}

class StatsHeatmapMonthlyBar {
  const StatsHeatmapMonthlyBar({
    required this.monthIndex,
    required this.heatLoad,
    required this.hotDayCount,
    required this.segments,
  });

  final int monthIndex;
  final double heatLoad;
  final int hotDayCount;
  final List<StatsHeatmapLoadSegment> segments;
}

class StatsHeatmapLoadSegment {
  const StatsHeatmapLoadSegment({
    required this.label,
    required this.value,
    required this.colorHex,
  });

  final String label;
  final double value;
  final String colorHex;
}

class _HeatmapWindows {
  const _HeatmapWindows({
    required this.density,
    required this.pulseShort,
    required this.pulseLong,
  });

  final int density;
  final int pulseShort;
  final int pulseLong;
}
