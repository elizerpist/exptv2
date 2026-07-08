import 'dart:math' as math;

import '../data/stats_year_data.dart';

class StatsCategoryScopeSeries {
  const StatsCategoryScopeSeries({
    required this.occurrence,
    required this.valueIndex,
    required this.riskSegments,
    required this.kontrollScore,
    required this.macd,
    required this.monthlyBars,
    required this.latestImpactLabel,
  });

  final List<StatsSeriesPoint> occurrence;
  final List<StatsSeriesPoint> valueIndex;
  final List<StatsRiskSegment> riskSegments;
  final double kontrollScore;
  final List<StatsMacdBar> macd;
  final List<StatsMonthlyScopeBar> monthlyBars;
  final String? latestImpactLabel;

  static StatsCategoryScopeSeries fromYearData(StatsYearData data) {
    final dailyAmounts = <double>[];
    for (final month in data.graphMonths) {
      dailyAmounts.addAll(month.days.map((day) => day.scopeAmount));
    }
    final categoryNames = <int, String>{};
    for (final month in data.graphMonths) {
      for (final categoryId in month.scopeCategoryTotals.keys) {
        categoryNames[categoryId] = 'Kategória $categoryId';
      }
    }
    return _build(
      threshold: data.thresholdValue,
      dailyScopeAmounts: dailyAmounts,
      window: _trendWindowForDays(dailyAmounts.length),
      monthlyCategoryTotals: data.graphMonths
          .map((month) => month.scopeCategoryTotals)
          .toList(growable: false),
      monthlyThresholdHitDays: data.graphMonths
          .map((month) => month.thresholdHitDays)
          .toList(growable: false),
      categoryNames: categoryNames,
    );
  }

  static StatsCategoryScopeSeries fromDailySamples({
    required double threshold,
    required List<double> dailyScopeAmounts,
    int window = 7,
  }) {
    return _build(
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      window: window,
      monthlyCategoryTotals: const <Map<int, double>>[],
      monthlyThresholdHitDays: const <int>[],
      categoryNames: const <int, String>{},
    );
  }

  static StatsCategoryScopeSeries fromPressureValues(
    List<double> pressureValues, {
    int shortWindow = 7,
    int longWindow = 21,
    int signalWindow = 5,
  }) {
    final points = [
      for (var i = 0; i < pressureValues.length; i += 1)
        StatsSeriesPoint(index: i, value: pressureValues[i]),
    ];
    return StatsCategoryScopeSeries(
      occurrence: points,
      valueIndex: points,
      riskSegments: const <StatsRiskSegment>[],
      kontrollScore: _scoreFromPressure(pressureValues),
      macd: _macd(
        pressureValues,
        shortWindow: shortWindow,
        longWindow: longWindow,
        signalWindow: signalWindow,
      ),
      monthlyBars: const <StatsMonthlyScopeBar>[],
      latestImpactLabel: null,
    );
  }

  static StatsCategoryScopeSeries fromMonthlyCategoryTotals({
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    return _build(
      threshold: 1,
      dailyScopeAmounts: const <double>[],
      window: 1,
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
  }

  static List<StatsRiskSegment> classifyRiskSegments({
    required List<double> occurrenceValues,
    required List<double> valueIndexValues,
    double noiseThreshold = 0.5,
  }) {
    final count = math.min(occurrenceValues.length, valueIndexValues.length);
    if (count < 2) return const <StatsRiskSegment>[];
    return [
      for (var i = 1; i < count; i += 1)
        StatsRiskSegment(
          startIndex: i - 1,
          endIndex: i,
          colorHex: _riskColor(
            occurrenceValues[i] - occurrenceValues[i - 1],
            valueIndexValues[i] - valueIndexValues[i - 1],
            noiseThreshold,
          ),
        ),
    ];
  }

  static StatsCategoryScopeSeries _build({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required int window,
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    final occurrenceValues = _occurrenceValues(
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      window: window,
    );
    final valueIndexValues = _valueIndexValues(
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      window: window,
    );
    final pressureValues = [
      for (
        var i = 0;
        i < math.min(occurrenceValues.length, valueIndexValues.length);
        i += 1
      )
        0.4 * occurrenceValues[i] + 0.6 * valueIndexValues[i],
    ];
    final monthlyBars = _monthlyBars(
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
    return StatsCategoryScopeSeries(
      occurrence: [
        for (var i = 0; i < occurrenceValues.length; i += 1)
          StatsSeriesPoint(index: i, value: occurrenceValues[i]),
      ],
      valueIndex: [
        for (var i = 0; i < valueIndexValues.length; i += 1)
          StatsSeriesPoint(index: i, value: valueIndexValues[i]),
      ],
      riskSegments: classifyRiskSegments(
        occurrenceValues: occurrenceValues,
        valueIndexValues: valueIndexValues,
      ),
      kontrollScore: _scoreFromPressure(pressureValues),
      macd: _macd(pressureValues),
      monthlyBars: monthlyBars,
      latestImpactLabel: _latestImpactLabel(monthlyBars),
    );
  }

  static List<double> _occurrenceValues({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required int window,
  }) {
    if (dailyScopeAmounts.isEmpty) return const <double>[];
    return [
      for (var i = 0; i < dailyScopeAmounts.length; i += 1)
        _rollingWindow(
              dailyScopeAmounts,
              i,
              window,
            ).where((amount) => amount >= threshold && amount > 0).length /
            _rollingWindow(dailyScopeAmounts, i, window).length *
            100,
    ];
  }

  static List<double> _valueIndexValues({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required int window,
  }) {
    if (dailyScopeAmounts.isEmpty) return const <double>[];
    final rollingValues = [
      for (var i = 0; i < dailyScopeAmounts.length; i += 1)
        _rollingWindow(dailyScopeAmounts, i, window).fold<double>(
          0,
          (sum, amount) =>
              amount >= threshold && amount > 0 ? sum + amount : sum,
        ),
    ];
    final maxValue = rollingValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (maxValue <= 0) return List<double>.filled(dailyScopeAmounts.length, 0);
    return [for (final value in rollingValues) value / maxValue * 100];
  }

  static List<double> _rollingWindow(
    List<double> values,
    int endIndex,
    int window,
  ) {
    final safeWindow = math.max(1, window);
    final start = math.max(0, endIndex - safeWindow + 1);
    return values.sublist(start, endIndex + 1);
  }

  static String? _riskColor(
    double occurrenceDelta,
    double valueDelta,
    double noiseThreshold,
  ) {
    final occurrenceFlat = occurrenceDelta.abs() <= noiseThreshold;
    final valueFlat = valueDelta.abs() <= noiseThreshold;
    if (occurrenceFlat && valueFlat) return null;
    final occurrenceImproves = occurrenceDelta < -noiseThreshold;
    final valueImproves = valueDelta < -noiseThreshold;
    final occurrenceWorsens = occurrenceDelta > noiseThreshold;
    final valueWorsens = valueDelta > noiseThreshold;
    if (occurrenceImproves && valueImproves) return '#10B981';
    if (occurrenceWorsens && valueWorsens) return '#EF4444';
    return '#F97316';
  }

  static double _scoreFromPressure(List<double> pressureValues) {
    if (pressureValues.isEmpty) return 100;
    if (pressureValues.length == 1) {
      return (100 - pressureValues.single).clamp(0, 100).toDouble();
    }
    final split = math.max(1, pressureValues.length ~/ 2);
    final prior = _average(pressureValues.take(split));
    final recent = _average(pressureValues.skip(split));
    final worseningPenalty = math.max(0, recent - prior) * 0.5;
    return (100 - recent - worseningPenalty).clamp(0, 100).toDouble();
  }

  static List<StatsMacdBar> _macd(
    List<double> pressureValues, {
    int shortWindow = 7,
    int longWindow = 21,
    int signalWindow = 5,
  }) {
    if (pressureValues.isEmpty) return const <StatsMacdBar>[];
    final short = _ema(pressureValues, shortWindow);
    final long = _ema(pressureValues, longWindow);
    final macd = [
      for (var i = 0; i < pressureValues.length; i += 1) short[i] - long[i],
    ];
    final signal = _ema(macd, signalWindow);
    return [
      for (var i = 0; i < macd.length; i += 1)
        StatsMacdBar(
          index: i,
          value: macd[i],
          signalValue: signal[i],
          colorHex: macd[i] >= 0 ? '#EF4444' : '#22C55E',
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

  static List<StatsMonthlyScopeBar> _monthlyBars({
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    return [
      for (var i = 0; i < monthlyCategoryTotals.length; i += 1)
        _monthlyBar(
          monthIndex: i,
          categoryTotals: monthlyCategoryTotals[i],
          thresholdHitDays: i < monthlyThresholdHitDays.length
              ? monthlyThresholdHitDays[i]
              : 0,
          categoryNames: categoryNames,
        ),
    ];
  }

  static StatsMonthlyScopeBar _monthlyBar({
    required int monthIndex,
    required Map<int, double> categoryTotals,
    required int thresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final otherAmount = sorted
        .skip(3)
        .fold<double>(0, (sum, entry) => sum + entry.value);
    final segments = <StatsCategoryStackSegment>[
      for (var i = 0; i < top.length; i += 1)
        StatsCategoryStackSegment(
          label: categoryNames[top[i].key] ?? 'Kategória ${top[i].key}',
          amount: top[i].value,
          colorHex: _categoryPalette[i],
        ),
      if (otherAmount > 0)
        const StatsCategoryStackSegment(
          label: 'Egyéb',
          amount: 0,
          colorHex: '#CBD5E1',
        ).copyWith(amount: otherAmount),
    ];
    final total = sorted.fold<double>(0, (sum, entry) => sum + entry.value);
    return StatsMonthlyScopeBar(
      monthIndex: monthIndex,
      totalAmount: total,
      thresholdHitDays: thresholdHitDays,
      segments: List.unmodifiable(segments),
      impactValue: thresholdHitDays > 0 ? total / thresholdHitDays : null,
    );
  }

  static String? _latestImpactLabel(List<StatsMonthlyScopeBar> bars) {
    for (final bar in bars.reversed) {
      final value = bar.impactValue;
      if (value != null) return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return null;
  }

  static double _average(Iterable<double> values) {
    var count = 0;
    var sum = 0.0;
    for (final value in values) {
      count += 1;
      sum += value;
    }
    return count == 0 ? 0 : sum / count;
  }

  static int _trendWindowForDays(int dayCount) {
    if (dayCount <= 45) return 7;
    if (dayCount <= 180) return 14;
    return 21;
  }

  static const _categoryPalette = ['#06B6D4', '#0EA5A4', '#F97316'];
}

class StatsSeriesPoint {
  const StatsSeriesPoint({required this.index, required this.value});

  final int index;
  final double value;
}

class StatsRiskSegment {
  const StatsRiskSegment({
    required this.startIndex,
    required this.endIndex,
    required this.colorHex,
  });

  final int startIndex;
  final int endIndex;
  final String? colorHex;
}

class StatsMacdBar {
  const StatsMacdBar({
    required this.index,
    required this.value,
    required this.signalValue,
    required this.colorHex,
  });

  final int index;
  final double value;
  final double signalValue;
  final String colorHex;
}

class StatsMonthlyScopeBar {
  const StatsMonthlyScopeBar({
    required this.monthIndex,
    required this.totalAmount,
    required this.thresholdHitDays,
    required this.segments,
    required this.impactValue,
  });

  final int monthIndex;
  final double totalAmount;
  final int thresholdHitDays;
  final List<StatsCategoryStackSegment> segments;
  final double? impactValue;
}

class StatsCategoryStackSegment {
  const StatsCategoryStackSegment({
    required this.label,
    required this.amount,
    required this.colorHex,
  });

  final String label;
  final double amount;
  final String colorHex;

  StatsCategoryStackSegment copyWith({double? amount}) {
    return StatsCategoryStackSegment(
      label: label,
      amount: amount ?? this.amount,
      colorHex: colorHex,
    );
  }
}
