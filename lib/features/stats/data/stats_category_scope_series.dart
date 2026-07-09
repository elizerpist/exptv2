import 'dart:math' as math;

import '../../transactions/models/transaction_category.dart';
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
    required this.controlBars,
    required this.secondaryLine,
    required this.monthLabels,
    required this.secondaryMetricLabel,
    required this.secondaryReferenceAmount,
    required this.dynamicEmaPeriod,
  });

  final List<StatsSeriesPoint> occurrence;
  final List<StatsSeriesPoint> valueIndex;
  final List<StatsRiskSegment> riskSegments;
  final double kontrollScore;
  final List<StatsMacdBar> macd;
  final List<StatsMonthlyScopeBar> monthlyBars;
  final String? latestImpactLabel;
  final List<StatsControlBar> controlBars;
  final List<StatsSeriesPoint> secondaryLine;
  final List<String> monthLabels;
  final String secondaryMetricLabel;
  final double secondaryReferenceAmount;
  final int dynamicEmaPeriod;

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
      activeType: data.activeType,
      threshold: data.thresholdValue,
      dailyScopeAmounts: dailyAmounts,
      graphMonths: data.graphMonths,
      monthLabels: _monthLabels(data.graphMonths),
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
    TransactionType activeType = TransactionType.expense,
  }) {
    return _build(
      activeType: activeType,
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      graphMonths: const <StatsMonthData>[],
      monthLabels: const <String>[],
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
      controlBars: const <StatsControlBar>[],
      secondaryLine: const <StatsSeriesPoint>[],
      monthLabels: const <String>[],
      secondaryMetricLabel: 'kiugras index',
      secondaryReferenceAmount: 0,
      dynamicEmaPeriod: 0,
    );
  }

  static StatsCategoryScopeSeries fromMonthlyCategoryTotals({
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    return _build(
      activeType: TransactionType.expense,
      threshold: 1,
      dailyScopeAmounts: const <double>[],
      graphMonths: const <StatsMonthData>[],
      monthLabels: [
        for (var i = 0; i < monthlyCategoryTotals.length; i += 1)
          _monthAbbreviations[i % _monthAbbreviations.length],
      ],
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
    required TransactionType activeType,
    required double threshold,
    required List<double> dailyScopeAmounts,
    required List<StatsMonthData> graphMonths,
    required List<String> monthLabels,
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
    final controlData = activeType == TransactionType.income
        ? _incomeControlData(graphMonths: graphMonths)
        : _expenseControlData(
            threshold: threshold,
            dailyScopeAmounts: dailyScopeAmounts,
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
      kontrollScore: controlData.kontrollScore,
      macd: _macd(pressureValues),
      monthlyBars: monthlyBars,
      latestImpactLabel: _latestImpactLabel(monthlyBars),
      controlBars: controlData.controlBars,
      secondaryLine: controlData.secondaryLine,
      monthLabels: monthLabels,
      secondaryMetricLabel: controlData.secondaryMetricLabel,
      secondaryReferenceAmount: controlData.secondaryReferenceAmount,
      dynamicEmaPeriod: controlData.dynamicEmaPeriod,
    );
  }

  static _StatsCategoryControlData _expenseControlData({
    required double threshold,
    required List<double> dailyScopeAmounts,
  }) {
    if (dailyScopeAmounts.isEmpty) {
      return const _StatsCategoryControlData(
        controlBars: <StatsControlBar>[],
        secondaryLine: <StatsSeriesPoint>[],
        secondaryMetricLabel: 'kiugras index',
        secondaryReferenceAmount: 0,
        dynamicEmaPeriod: 0,
        kontrollScore: 100,
      );
    }
    final thresholdEnabled = threshold > 0;
    final activeScopeDays = dailyScopeAmounts
        .where((amount) => amount > 0)
        .length;
    final emaPeriod = _dynamicEmaPeriod(activeScopeDays);
    final frequencyRaw = <double>[];
    final valueRaw = <double>[];
    final impactRaw = <double>[];
    for (final amount in dailyScopeAmounts) {
      final active = amount > 0;
      final hit = thresholdEnabled ? amount >= threshold && active : active;
      frequencyRaw.add(hit ? 1 : 0);
      valueRaw.add(active ? amount : 0);
      impactRaw.add(hit ? amount : 0);
    }
    final frequencyAverage = _average(frequencyRaw);
    final valueAverage = _average(valueRaw);
    final impactAverage = _average(impactRaw);
    final rawControl = <double>[
      for (var i = 0; i < dailyScopeAmounts.length; i += 1)
        (50 *
                (0.35 * _ratio(frequencyRaw[i], frequencyAverage) +
                    0.35 * _ratio(valueRaw[i], valueAverage) +
                    0.30 * _ratio(impactRaw[i], impactAverage)))
            .clamp(0, 100)
            .toDouble(),
    ];
    final smoothedControl = _ema(rawControl, emaPeriod);
    final secondaryRawValues = _expenseSecondaryIndexValues(
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      window: emaPeriod,
    );
    final secondaryValues = _ema(secondaryRawValues, emaPeriod);
    final referenceValues = secondaryRawValues.where((value) => value > 0);
    return _StatsCategoryControlData(
      controlBars: [
        for (var i = 0; i < smoothedControl.length; i += 1)
          StatsControlBar(
            index: i,
            value: smoothedControl[i],
            colorHex: _controlColor(
              activeType: TransactionType.expense,
              value: smoothedControl[i],
            ),
          ),
      ],
      secondaryLine: [
        for (var i = 0; i < secondaryValues.length; i += 1)
          StatsSeriesPoint(index: i, value: secondaryValues[i]),
      ],
      secondaryMetricLabel: thresholdEnabled
          ? 'kiugras index'
          : 'aktiv nap index',
      secondaryReferenceAmount: _average(referenceValues),
      dynamicEmaPeriod: emaPeriod,
      kontrollScore: _scoreFromPressure(smoothedControl),
    );
  }

  static List<double> _expenseSecondaryIndexValues({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required int window,
  }) {
    final thresholdEnabled = threshold > 0;
    if (!thresholdEnabled) {
      return _activeIntensityIndexValues(dailyScopeAmounts);
    }
    return [
      for (var i = 0; i < dailyScopeAmounts.length; i += 1)
        _expenseSpikeSeverityIndex(
          threshold: threshold,
          windowAmounts: _rollingWindow(dailyScopeAmounts, i, window),
        ),
    ];
  }

  static double _expenseSpikeSeverityIndex({
    required double threshold,
    required List<double> windowAmounts,
  }) {
    if (threshold <= 0) return 0;
    var severityTotal = 0.0;
    var hitCount = 0;
    for (final amount in windowAmounts) {
      if (amount < threshold || amount <= 0) continue;
      severityTotal += ((amount - threshold) / threshold * 100)
          .clamp(0, 100)
          .toDouble();
      hitCount += 1;
    }
    return hitCount > 0 ? severityTotal / hitCount : 0;
  }

  static List<double> _activeIntensityIndexValues(List<double> amounts) {
    final activeAmounts = amounts.where((amount) => amount > 0).toList();
    if (amounts.isEmpty) return const <double>[];
    if (activeAmounts.isEmpty) return List<double>.filled(amounts.length, 0);
    final minActive = activeAmounts.fold<double>(activeAmounts.first, math.min);
    final maxActive = activeAmounts.fold<double>(activeAmounts.first, math.max);
    final spread = maxActive - minActive;
    return [
      for (final amount in amounts)
        if (amount <= 0)
          50
        else if (spread <= 0)
          50
        else
          (50 + 50 * ((amount - minActive) / spread)).clamp(50, 100).toDouble(),
    ];
  }

  static _StatsCategoryControlData _incomeControlData({
    required List<StatsMonthData> graphMonths,
  }) {
    if (graphMonths.isEmpty) {
      return const _StatsCategoryControlData(
        controlBars: <StatsControlBar>[],
        secondaryLine: <StatsSeriesPoint>[],
        secondaryMetricLabel: 'elteres index',
        secondaryReferenceAmount: 0,
        dynamicEmaPeriod: 0,
        kontrollScore: 50,
      );
    }
    final monthlyTotals = [for (final month in graphMonths) month.scopeTotal];
    final monthlyReference = _average(monthlyTotals);
    final activeDayCounts = [
      for (final month in graphMonths)
        month.days.where((day) => day.scopeAmount > 0).length.toDouble(),
    ];
    final activeDayReference = _average(
      activeDayCounts.where((days) => days > 0),
    );
    final totalIndexes = [
      for (final total in monthlyTotals)
        (50 * _ratio(total, monthlyReference)).clamp(0, 100).toDouble(),
    ];
    final activeDayIndexes = [
      for (final days in activeDayCounts)
        (50 * _ratio(days, activeDayReference)).clamp(0, 100).toDouble(),
    ];
    final stabilityIndexes = <double>[];
    for (var i = 0; i < totalIndexes.length; i += 1) {
      if (i == 0) {
        stabilityIndexes.add(50);
        continue;
      }
      final delta = (totalIndexes[i] - totalIndexes[i - 1]).abs();
      stabilityIndexes.add((100 - delta * 1.2).clamp(0, 100).toDouble());
    }
    final incomeHealthValues = [
      for (var i = 0; i < monthlyTotals.length; i += 1)
        (0.55 * totalIndexes[i] +
                0.25 * activeDayIndexes[i] +
                0.20 * stabilityIndexes[i])
            .clamp(0, 100)
            .toDouble(),
    ];
    final rawDeviationValues = [
      for (var i = 0; i < monthlyTotals.length; i += 1)
        (0.65 * (totalIndexes[i] - 50).abs() * 2 +
                0.35 * (activeDayIndexes[i] - 50).abs() * 2)
            .clamp(0, 100)
            .toDouble(),
    ];
    final secondaryValues = _ema(rawDeviationValues, 2);
    return _StatsCategoryControlData(
      controlBars: [
        for (var i = 0; i < incomeHealthValues.length; i += 1)
          StatsControlBar(
            index: i,
            value: incomeHealthValues[i],
            colorHex: _controlColor(
              activeType: TransactionType.income,
              value: incomeHealthValues[i],
            ),
          ),
      ],
      secondaryLine: [
        for (var i = 0; i < secondaryValues.length; i += 1)
          StatsSeriesPoint(index: i, value: secondaryValues[i]),
      ],
      secondaryMetricLabel: 'elteres index',
      secondaryReferenceAmount: monthlyReference,
      dynamicEmaPeriod: 0,
      kontrollScore: _scoreFromIncomeHealth(incomeHealthValues),
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

  static double _scoreFromIncomeHealth(List<double> incomeHealthValues) {
    if (incomeHealthValues.isEmpty) return 50;
    if (incomeHealthValues.length == 1) {
      return incomeHealthValues.single.clamp(0, 100).toDouble();
    }
    final split = math.max(1, incomeHealthValues.length ~/ 2);
    final prior = _average(incomeHealthValues.take(split));
    final recent = _average(incomeHealthValues.skip(split));
    final declinePenalty = math.max(0, prior - recent) * 0.5;
    return (recent - declinePenalty).clamp(0, 100).toDouble();
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

  static double _ratio(double value, double reference) {
    if (reference <= 0) return 0;
    return value / reference;
  }

  static int _dynamicEmaPeriod(int activeScopeDays) {
    final period = (22 - 0.45 * activeScopeDays).round();
    return period.clamp(7, 18);
  }

  static String _controlColor({
    required TransactionType activeType,
    required double value,
  }) {
    if ((value - 50).abs() < 0.05) return '#64748B';
    final aboveBaseline = value > 50;
    if (activeType == TransactionType.income) {
      return aboveBaseline ? '#22C55E' : '#EF4444';
    }
    return aboveBaseline ? '#EF4444' : '#22C55E';
  }

  static List<String> _monthLabels(List<StatsMonthData> months) {
    return [for (final month in months) _monthAbbreviations[month.month - 1]];
  }

  static int _trendWindowForDays(int dayCount) {
    if (dayCount <= 45) return 7;
    if (dayCount <= 180) return 14;
    return 21;
  }

  static const _categoryPalette = ['#06B6D4', '#0EA5A4', '#F97316'];
  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class StatsSeriesPoint {
  const StatsSeriesPoint({required this.index, required this.value});

  final int index;
  final double value;
}

class StatsControlBar {
  const StatsControlBar({
    required this.index,
    required this.value,
    required this.colorHex,
  });

  final int index;
  final double value;
  final String colorHex;

  double get deltaFromBaseline => value - 50;
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

class _StatsCategoryControlData {
  const _StatsCategoryControlData({
    required this.controlBars,
    required this.secondaryLine,
    required this.secondaryMetricLabel,
    required this.secondaryReferenceAmount,
    required this.dynamicEmaPeriod,
    required this.kontrollScore,
  });

  final List<StatsControlBar> controlBars;
  final List<StatsSeriesPoint> secondaryLine;
  final String secondaryMetricLabel;
  final double secondaryReferenceAmount;
  final int dynamicEmaPeriod;
  final double kontrollScore;
}
