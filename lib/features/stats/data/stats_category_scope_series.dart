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
    this.scoreLine = const <StatsSeriesPoint>[],
    this.helperBars = const <StatsHelperBar>[],
    this.monthTicks = const <StatsMonthTick>[],
    this.incomeComparisonBars = const <StatsIncomeComparisonBar>[],
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
  final List<StatsSeriesPoint> scoreLine;
  final List<StatsHelperBar> helperBars;
  final List<StatsMonthTick> monthTicks;
  final List<StatsIncomeComparisonBar> incomeComparisonBars;

  static StatsCategoryScopeSeries fromYearData(StatsYearData data) {
    if (data.summaryScope == StatsSummaryScope.allTime ||
        data.summaryScope == StatsSummaryScope.monthly) {
      return _buildPeriodSeries(
        activeType: data.activeType,
        threshold: data.thresholdValue,
        amounts: data.activeType == TransactionType.expense
            ? data.scorePeriodAmounts
            : data.periodAmounts,
        matchingExpenseAmounts: data.matchingExpensePeriodAmounts,
        labels: data.periodLabels,
        preserveAllSamples: data.summaryScope == StatsSummaryScope.monthly,
        monthlyCategoryTotals: [
          for (final month in data.graphMonths) month.scopeCategoryTotals,
        ],
        monthlyThresholdHitDays: [
          for (final month in data.graphMonths) month.thresholdHitDays,
        ],
        categoryNames: const <int, String>{},
      );
    }
    final graphDayCount = data.graphMonths.fold<int>(
      0,
      (count, month) => count + month.days.length,
    );
    final categoryNames = <int, String>{};
    for (final month in data.graphMonths) {
      for (final categoryId in month.scopeCategoryTotals.keys) {
        categoryNames[categoryId] = 'Kategória $categoryId';
      }
    }
    return _build(
      activeType: data.activeType,
      threshold: data.thresholdValue,
      dailyScopeAmounts: const <double>[],
      graphMonths: data.graphMonths,
      monthLabels: _monthLabels(data.graphMonths),
      window: _trendWindowForDays(graphDayCount),
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
      scoreLine: points,
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
    if (activeType == TransactionType.income) {
      return _buildIncomeHtmlSeries(
        threshold: threshold,
        graphMonths: graphMonths,
        monthLabels: monthLabels,
        monthlyCategoryTotals: monthlyCategoryTotals,
        monthlyThresholdHitDays: monthlyThresholdHitDays,
        categoryNames: categoryNames,
      );
    }
    return _buildExpenseHtmlSeries(
      threshold: threshold,
      dailyScopeAmounts: dailyScopeAmounts,
      graphMonths: graphMonths,
      monthLabels: monthLabels,
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
  }

  static StatsCategoryScopeSeries _buildPeriodSeries({
    required TransactionType activeType,
    required double threshold,
    required List<double> amounts,
    required List<double> matchingExpenseAmounts,
    required List<String> labels,
    required bool preserveAllSamples,
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    final monthlyBars = _monthlyBars(
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
    if (activeType == TransactionType.income) {
      final visibleIndexes = [
        for (var i = 0; i < amounts.length; i += 1)
          if (preserveAllSamples || amounts[i] > 0) i,
      ];
      final visibleAmounts = [
        for (final index in visibleIndexes) amounts[index],
      ];
      final patternIndexes = [
        for (final index in visibleIndexes)
          if (amounts[index] > 0) index,
      ];
      final patternAmounts = [
        for (final index in patternIndexes) amounts[index],
      ];
      final scoreValues = _incomePatternTrendValues(patternAmounts);
      final scoreLine = [
        for (var i = 0; i < scoreValues.length; i += 1)
          StatsSeriesPoint(
            index: i,
            value: scoreValues[i],
            position: preserveAllSamples
                ? _normalizedPosition(patternIndexes[i], amounts.length)
                : _normalizedPosition(i, scoreValues.length),
          ),
      ];
      final maxTotal = math.max(1, visibleAmounts.fold<double>(0, math.max));
      final amountLine = [
        for (var i = 0; i < visibleAmounts.length; i += 1)
          StatsSeriesPoint(
            index: i,
            value: (visibleAmounts[i] / maxTotal * 100)
                .clamp(0, 100)
                .toDouble(),
            position: _normalizedPosition(i, visibleAmounts.length),
          ),
      ];
      final visibleLabels = [
        for (final index in visibleIndexes)
          if (index < labels.length) labels[index],
      ];
      final monthTicks = _periodTicks(visibleLabels);
      final helperBars = _incomeThresholdExcessBars(
        patternAmounts,
        threshold,
        positions: [
          for (var i = 0; i < patternIndexes.length; i += 1)
            preserveAllSamples
                ? _normalizedPosition(patternIndexes[i], amounts.length)
                : _normalizedPosition(i, patternIndexes.length),
        ],
      );
      final incomeComparisonBars = [
        for (var i = 0; i < visibleIndexes.length; i += 1)
          _incomeComparisonBar(
            index: i,
            incomeAmount: visibleAmounts[i],
            expenseAmount: visibleIndexes[i] < matchingExpenseAmounts.length
                ? matchingExpenseAmounts[visibleIndexes[i]]
                : 0,
            position: preserveAllSamples
                ? _barCenterPosition(visibleIndexes[i], amounts.length)
                : _barCenterPosition(i, visibleIndexes.length),
          ),
      ];
      return StatsCategoryScopeSeries(
        occurrence: const <StatsSeriesPoint>[],
        valueIndex: amountLine,
        riskSegments: const <StatsRiskSegment>[],
        kontrollScore: scoreLine.isNotEmpty ? scoreLine.last.value : 50,
        macd: const <StatsMacdBar>[],
        monthlyBars: monthlyBars,
        latestImpactLabel: _latestImpactLabel(monthlyBars),
        controlBars: [
          for (final point in scoreLine)
            StatsControlBar(
              index: point.index,
              value: point.value,
              colorHex: _scoreColorHex(point.value),
              position: point.position,
            ),
        ],
        secondaryLine: amountLine,
        monthLabels: [for (final tick in monthTicks) tick.label],
        secondaryMetricLabel: 'küszöb feletti többlet',
        secondaryReferenceAmount: threshold,
        dynamicEmaPeriod: 0,
        scoreLine: scoreLine,
        helperBars: helperBars,
        monthTicks: monthTicks,
        incomeComparisonBars: incomeComparisonBars,
      );
    }
    final monthTicks = _periodTicks(labels);
    return _buildExpenseHtmlSeries(
      threshold: threshold,
      dailyScopeAmounts: amounts,
      graphMonths: const <StatsMonthData>[],
      monthLabels: labels,
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    ).withMonthTicks(monthTicks);
  }

  StatsCategoryScopeSeries withMonthTicks(List<StatsMonthTick> ticks) {
    return StatsCategoryScopeSeries(
      occurrence: occurrence,
      valueIndex: valueIndex,
      riskSegments: riskSegments,
      kontrollScore: kontrollScore,
      macd: macd,
      monthlyBars: monthlyBars,
      latestImpactLabel: latestImpactLabel,
      controlBars: controlBars,
      secondaryLine: secondaryLine,
      monthLabels: [for (final tick in ticks) tick.label],
      secondaryMetricLabel: secondaryMetricLabel,
      secondaryReferenceAmount: secondaryReferenceAmount,
      dynamicEmaPeriod: dynamicEmaPeriod,
      scoreLine: scoreLine,
      helperBars: helperBars,
      monthTicks: ticks,
      incomeComparisonBars: incomeComparisonBars,
    );
  }

  static StatsCategoryScopeSeries _buildExpenseHtmlSeries({
    required double threshold,
    required List<double> dailyScopeAmounts,
    required List<StatsMonthData> graphMonths,
    required List<String> monthLabels,
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    final allDays = graphMonths.isNotEmpty
        ? [
            for (final month in graphMonths)
              for (final day in month.days)
                _ScopeDaySample(
                  month: month.month,
                  amount: day.scoreScopeAmount,
                ),
          ]
        : [
            for (var i = 0; i < dailyScopeAmounts.length; i += 1)
              _ScopeDaySample(month: null, amount: dailyScopeAmounts[i]),
          ];
    final monthlyBars = _monthlyBars(
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
    final firstScopeIndex = allDays.indexWhere(
      (day) => _isThresholdHit(day.amount, threshold),
    );
    var lastScopeIndex = -1;
    for (var i = allDays.length - 1; i >= 0; i -= 1) {
      if (_isThresholdHit(allDays[i].amount, threshold)) {
        lastScopeIndex = i;
        break;
      }
    }
    if (firstScopeIndex < 0 || lastScopeIndex < firstScopeIndex) {
      const scoreLine = [StatsSeriesPoint(index: 0, value: 100, position: 0.5)];
      return StatsCategoryScopeSeries(
        occurrence: const <StatsSeriesPoint>[],
        valueIndex: const <StatsSeriesPoint>[],
        riskSegments: const <StatsRiskSegment>[],
        kontrollScore: 100,
        macd: const <StatsMacdBar>[],
        monthlyBars: monthlyBars,
        latestImpactLabel: _latestImpactLabel(monthlyBars),
        controlBars: const <StatsControlBar>[],
        secondaryLine: const <StatsSeriesPoint>[],
        monthLabels: const <String>[],
        secondaryMetricLabel: threshold > 0
            ? 'küszöb feletti többlet'
            : 'minimum alapú eltérés',
        secondaryReferenceAmount: 0,
        dynamicEmaPeriod: 7,
        scoreLine: scoreLine,
        helperBars: const <StatsHelperBar>[],
        monthTicks: const <StatsMonthTick>[],
      );
    }

    final graphDays = allDays.sublist(firstScopeIndex, lastScopeIndex + 1);
    final hitDays = [
      for (final day in graphDays)
        if (_isThresholdHit(day.amount, threshold)) day,
    ];
    final helperBars = _expenseHelperBars(
      threshold: threshold,
      graphDays: graphDays,
      hitDays: hitDays,
    );
    final monthTicks = _monthTicksForGraphDays(graphDays);
    final focusScopeDays = hitDays.length;
    final amountMax = math.max(
      1,
      hitDays.fold<double>(0, (max, day) => math.max(max, day.amount)),
    );

    if (focusScopeDays <= 12) {
      final scoreLine = [
        for (var i = 0; i < hitDays.length; i += 1)
          StatsSeriesPoint(
            index: i,
            value: (100 - hitDays[i].amount / amountMax * 100)
                .clamp(0, 100)
                .toDouble(),
            position: _positionInGraph(hitDays[i], graphDays),
          ),
      ];
      final amountLine = [
        for (var i = 0; i < hitDays.length; i += 1)
          StatsSeriesPoint(
            index: i,
            value: (hitDays[i].amount / amountMax * 100)
                .clamp(0, 100)
                .toDouble(),
            position: _positionInGraph(hitDays[i], graphDays),
          ),
      ];
      return StatsCategoryScopeSeries(
        occurrence: [
          for (var i = 0; i < hitDays.length; i += 1)
            StatsSeriesPoint(
              index: i,
              value: 100,
              position: _positionInGraph(hitDays[i], graphDays),
            ),
        ],
        valueIndex: amountLine,
        riskSegments: const <StatsRiskSegment>[],
        kontrollScore: scoreLine.isNotEmpty ? scoreLine.last.value : 100,
        macd: const <StatsMacdBar>[],
        monthlyBars: monthlyBars,
        latestImpactLabel: _latestImpactLabel(monthlyBars),
        controlBars: [
          for (final point in scoreLine)
            StatsControlBar(
              index: point.index,
              value: point.value,
              colorHex: _scoreColorHex(point.value),
              position: point.position,
            ),
        ],
        secondaryLine: amountLine,
        monthLabels: [for (final tick in monthTicks) tick.label],
        secondaryMetricLabel: threshold > 0
            ? 'küszöb feletti többlet'
            : 'minimum alapú eltérés',
        secondaryReferenceAmount: 0,
        dynamicEmaPeriod: 1,
        scoreLine: scoreLine,
        helperBars: helperBars,
        monthTicks: monthTicks,
      );
    }

    const behaviorWindow = 31;
    const halfWindow = behaviorWindow ~/ 2;
    final rollingOccurrences = <double>[];
    final rollingAmounts = <double>[];
    for (var i = firstScopeIndex; i <= lastScopeIndex; i += 1) {
      final start = math.max(firstScopeIndex, i - halfWindow);
      final end = math.min(lastScopeIndex, i + halfWindow);
      var occurrence = 0.0;
      var total = 0.0;
      for (var windowIndex = start; windowIndex <= end; windowIndex += 1) {
        final amount = allDays[windowIndex].amount;
        if (!_isThresholdHit(amount, threshold)) continue;
        occurrence += 1;
        total += amount;
      }
      rollingOccurrences.add(occurrence);
      rollingAmounts.add(total);
    }
    final emaPeriod = _dynamicEmaPeriod(focusScopeDays);
    final smoothedOccurrences = _ema(rollingOccurrences, emaPeriod);
    final smoothedAmounts = _ema(rollingAmounts, emaPeriod);
    final occurrenceMax = math.max(
      1,
      smoothedOccurrences.fold<double>(0, math.max),
    );
    final amountMaxDense = math.max(
      1,
      smoothedAmounts.fold<double>(0, math.max),
    );
    final occurrenceValues = [
      for (final value in smoothedOccurrences)
        (value / occurrenceMax * 100).clamp(0, 100).toDouble(),
    ];
    final amountValues = [
      for (final value in smoothedAmounts)
        (value / amountMaxDense * 100).clamp(0, 100).toDouble(),
    ];
    final pressureValues = [
      for (var i = 0; i < occurrenceValues.length; i += 1)
        occurrenceValues[i] * 0.5 + amountValues[i] * 0.5,
    ];
    final scoreValues = [
      for (final value in pressureValues)
        (100 - value).clamp(0, 100).toDouble(),
    ];
    final scoreLine = [
      for (var i = 0; i < scoreValues.length; i += 1)
        StatsSeriesPoint(
          index: i,
          value: scoreValues[i],
          position: _normalizedPosition(i, scoreValues.length),
        ),
    ];
    final occurrenceLine = [
      for (var i = 0; i < occurrenceValues.length; i += 1)
        StatsSeriesPoint(
          index: i,
          value: occurrenceValues[i],
          position: _normalizedPosition(i, occurrenceValues.length),
        ),
    ];
    final amountLine = [
      for (var i = 0; i < amountValues.length; i += 1)
        StatsSeriesPoint(
          index: i,
          value: amountValues[i],
          position: _normalizedPosition(i, amountValues.length),
        ),
    ];
    return StatsCategoryScopeSeries(
      occurrence: occurrenceLine,
      valueIndex: amountLine,
      riskSegments: classifyRiskSegments(
        occurrenceValues: occurrenceValues,
        valueIndexValues: amountValues,
      ),
      kontrollScore: scoreLine.isNotEmpty ? scoreLine.last.value : 100,
      macd: _macd(pressureValues),
      monthlyBars: monthlyBars,
      latestImpactLabel: _latestImpactLabel(monthlyBars),
      controlBars: [
        for (final point in scoreLine)
          StatsControlBar(
            index: point.index,
            value: point.value,
            colorHex: _scoreColorHex(point.value),
            position: point.position,
          ),
      ],
      secondaryLine: amountLine,
      monthLabels: [for (final tick in monthTicks) tick.label],
      secondaryMetricLabel: threshold > 0
          ? 'küszöb feletti többlet'
          : 'minimum alapú eltérés',
      secondaryReferenceAmount: 0,
      dynamicEmaPeriod: emaPeriod,
      scoreLine: scoreLine,
      helperBars: helperBars,
      monthTicks: monthTicks,
    );
  }

  static StatsCategoryScopeSeries _buildIncomeHtmlSeries({
    required double threshold,
    required List<StatsMonthData> graphMonths,
    required List<String> monthLabels,
    required List<Map<int, double>> monthlyCategoryTotals,
    required List<int> monthlyThresholdHitDays,
    required Map<int, String> categoryNames,
  }) {
    final visibleMonths = graphMonths
        .where((month) => month.scopeTotal > 0)
        .where((month) => threshold <= 0 || month.thresholdHitDays > 0)
        .toList(growable: false);
    final monthlyBars = _monthlyBars(
      monthlyCategoryTotals: monthlyCategoryTotals,
      monthlyThresholdHitDays: monthlyThresholdHitDays,
      categoryNames: categoryNames,
    );
    final totals = [
      for (final month in visibleMonths) _incomeMetricTotal(month, threshold),
    ];
    final scoreValues = _incomePatternTrendValues(totals);
    final scoreLine = [
      for (var i = 0; i < scoreValues.length; i += 1)
        StatsSeriesPoint(
          index: i,
          value: scoreValues[i],
          position: _normalizedPosition(i, scoreValues.length),
        ),
    ];
    final maxTotal = math.max(1, totals.fold<double>(0, math.max));
    final amountLine = [
      for (var i = 0; i < totals.length; i += 1)
        StatsSeriesPoint(
          index: i,
          value: (totals[i] / maxTotal * 100).clamp(0, 100).toDouble(),
          position: _normalizedPosition(i, totals.length),
        ),
    ];
    final monthTicks = [
      for (var i = 0; i < visibleMonths.length; i += 1)
        StatsMonthTick(
          label: _monthAbbreviations[visibleMonths[i].month - 1],
          position: _normalizedPosition(i, visibleMonths.length),
        ),
    ];
    final graphDays = [
      for (final month in graphMonths)
        for (final day in month.days)
          _ScopeDaySample(month: month.month, amount: day.scopeAmount),
    ];
    final helperDays = [
      for (final day in graphDays)
        if (_isThresholdHit(day.amount, threshold)) day,
    ];
    final helperBars = _incomeThresholdExcessBars(
      [for (final day in helperDays) day.amount],
      threshold,
      positions: [
        for (final day in helperDays) _positionInGraph(day, graphDays),
      ],
    );
    final incomeComparisonBars = [
      for (var i = 0; i < visibleMonths.length; i += 1)
        _incomeComparisonBar(
          index: i,
          incomeAmount: totals[i],
          expenseAmount: visibleMonths[i].matchingExpenseTotal,
          position: _barCenterPosition(i, visibleMonths.length),
        ),
    ];
    return StatsCategoryScopeSeries(
      occurrence: const <StatsSeriesPoint>[],
      valueIndex: amountLine,
      riskSegments: const <StatsRiskSegment>[],
      kontrollScore: scoreLine.isNotEmpty ? scoreLine.last.value : 50,
      macd: const <StatsMacdBar>[],
      monthlyBars: monthlyBars,
      latestImpactLabel: _latestImpactLabel(monthlyBars),
      controlBars: [
        for (final point in scoreLine)
          StatsControlBar(
            index: point.index,
            value: point.value,
            colorHex: _scoreColorHex(point.value),
            position: point.position,
          ),
      ],
      secondaryLine: amountLine,
      monthLabels: [for (final tick in monthTicks) tick.label],
      secondaryMetricLabel: 'küszöb feletti többlet',
      secondaryReferenceAmount: threshold,
      dynamicEmaPeriod: 0,
      scoreLine: scoreLine,
      helperBars: helperBars,
      monthTicks: monthTicks,
      incomeComparisonBars: incomeComparisonBars,
    );
  }

  static StatsIncomeComparisonBar _incomeComparisonBar({
    required int index,
    required double incomeAmount,
    required double expenseAmount,
    required double position,
  }) {
    final signedValue = incomeAmount - expenseAmount;
    return StatsIncomeComparisonBar(
      index: index,
      incomeAmount: incomeAmount,
      expenseAmount: expenseAmount,
      signedValue: signedValue,
      position: position,
      colorHex: signedValue > 0
          ? '#22C55E'
          : signedValue < 0
          ? '#EF4444'
          : '#FBBF24',
    );
  }

  static bool _isThresholdHit(double amount, double threshold) {
    return amount > 0 && amount >= threshold;
  }

  static double _normalizedPosition(int index, int length) {
    return length <= 1 ? 0.5 : index / (length - 1);
  }

  static double _barCenterPosition(int index, int length) {
    return length <= 0 ? 0.5 : (index + 0.5) / length;
  }

  static double _positionInGraph(
    _ScopeDaySample day,
    List<_ScopeDaySample> graphDays,
  ) {
    final index = graphDays.indexOf(day);
    return _normalizedPosition(index < 0 ? 0 : index, graphDays.length);
  }

  static List<StatsMonthTick> _monthTicksForGraphDays(
    List<_ScopeDaySample> graphDays,
  ) {
    if (graphDays.isEmpty) return const <StatsMonthTick>[];
    final ticks = <StatsMonthTick>[];
    final seen = <int>{};
    for (var i = 0; i < graphDays.length; i += 1) {
      final month = graphDays[i].month;
      if (month == null || seen.contains(month)) continue;
      seen.add(month);
      ticks.add(
        StatsMonthTick(
          label: _monthAbbreviations[month - 1],
          position: _normalizedPosition(i, graphDays.length),
        ),
      );
    }
    return List.unmodifiable(ticks);
  }

  static List<StatsMonthTick> _periodTicks(List<String> labels) {
    if (labels.isEmpty) return const <StatsMonthTick>[];
    final indexes = _visibleTickIndexes(labels.length);
    return [
      for (final index in indexes)
        StatsMonthTick(
          label: labels[index],
          position: _normalizedPosition(index, labels.length),
        ),
    ];
  }

  static List<int> _visibleTickIndexes(int count) {
    if (count <= 0) return const <int>[];
    final indexes = <int>{0, count - 1};
    if (count <= 10) {
      indexes.addAll(List<int>.generate(count, (index) => index));
    } else if (count <= 16) {
      for (var i = 1; i < count - 1; i += 2) {
        indexes.add(i);
      }
    } else if (count <= 31) {
      for (var display = 5; display < count; display += 5) {
        indexes.add(display - 1);
      }
    } else {
      for (var display = 10; display < count; display += 10) {
        indexes.add(display - 1);
      }
    }
    return indexes.toList()..sort();
  }

  static List<StatsHelperBar> _expenseHelperBars({
    required double threshold,
    required List<_ScopeDaySample> graphDays,
    required List<_ScopeDaySample> hitDays,
  }) {
    if (hitDays.isEmpty) return const <StatsHelperBar>[];
    final rawValues = [for (final day in hitDays) day.amount];
    final deltas = threshold > 0
        ? _thresholdExcessDeltas(rawValues, threshold)
        : _amountMinDeltas(rawValues);
    final bars = <StatsHelperBar>[];
    for (var graphIndex = 0; graphIndex < graphDays.length; graphIndex += 1) {
      final day = graphDays[graphIndex];
      if (!_isThresholdHit(day.amount, threshold)) continue;
      final hitIndex = bars.length;
      bars.add(
        StatsHelperBar(
          index: hitIndex,
          rawValue: day.amount,
          value: deltas[hitIndex],
          position: _normalizedPosition(graphIndex, graphDays.length),
          colorHex: '#EF4444',
        ),
      );
    }
    return bars;
  }

  static List<double> _thresholdExcessDeltas(
    List<double> values,
    double threshold,
  ) {
    if (threshold <= 0) return _amountMinDeltas(values);
    final excessValues = [
      for (final value in values) math.max(0.0, value - threshold),
    ];
    final maxExcess = math.max(1, excessValues.fold<double>(0, math.max));
    return [
      for (final value in excessValues)
        (value / maxExcess * 100).clamp(0, 100).toDouble(),
    ];
  }

  static List<double> _amountMinDeltas(List<double> values) {
    if (values.isEmpty) return const <double>[];
    final min = values.fold<double>(values.first, math.min);
    final maxSpread = math.max(
      1,
      values.map((value) => value - min).fold<double>(0, math.max),
    );
    return [
      for (final value in values)
        ((value - min) / maxSpread * 100).clamp(0, 100).toDouble(),
    ];
  }

  static double _incomeMetricTotal(StatsMonthData month, double threshold) {
    if (threshold <= 0) return month.scopeTotal;
    return month.days.fold<double>(
      0,
      (sum, day) => day.meetsThreshold ? sum + day.scopeAmount : sum,
    );
  }

  static List<double> _incomePatternTrendValues(List<double> monthlyTotals) {
    if (monthlyTotals.isEmpty) return const <double>[];
    return [
      for (var i = 0; i < monthlyTotals.length; i += 1)
        _incomePatternTrendScore(
          monthlyTotals.take(i).toList(),
          monthlyTotals[i],
        ),
    ];
  }

  static double _incomePatternTrendScore(
    List<double> previousVisibleValues,
    double recentPatternAvg,
  ) {
    if (recentPatternAvg <= 0 || previousVisibleValues.isEmpty) return 50;
    final previousWindowSize = math.min(3, previousVisibleValues.length);
    final previousPatternAvg = _average(
      previousVisibleValues.skip(
        previousVisibleValues.length - previousWindowSize,
      ),
    );
    final baseline = math.max(
      1,
      math.max(
        previousPatternAvg,
        _median([...previousVisibleValues, recentPatternAvg]),
      ),
    );
    final trendDelta = (recentPatternAvg - previousPatternAvg) / baseline;
    final trendAdjustment = (trendDelta * 35).clamp(-30, 30).toDouble();
    return (50 + trendAdjustment).clamp(0, 100).toDouble();
  }

  static List<StatsHelperBar> _incomeThresholdExcessBars(
    List<double> totals,
    double threshold, {
    List<double>? positions,
  }) {
    if (totals.isEmpty) return const <StatsHelperBar>[];
    final values = threshold > 0
        ? _thresholdExcessDeltas(totals, threshold)
        : _amountMinDeltas(totals);
    return [
      for (var i = 0; i < totals.length; i += 1)
        StatsHelperBar(
          index: i,
          rawValue: totals[i],
          value: values[i],
          position: positions != null && i < positions.length
              ? positions[i]
              : _normalizedPosition(i, totals.length),
          colorHex: '#22C55E',
        ),
    ];
  }

  static String _scoreColorHex(double value) {
    if (value < 45) return '#EF4444';
    if (value < 60) return '#FBBF24';
    return '#22C55E';
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

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static int _dynamicEmaPeriod(int activeScopeDays) {
    final period = (22 - 0.45 * activeScopeDays).round();
    return period.clamp(7, 18);
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
    'Már',
    'Ápr',
    'Máj',
    'Jún',
    'Júl',
    'Aug',
    'Szep',
    'Okt',
    'Nov',
    'Dec',
  ];
}

class StatsSeriesPoint {
  const StatsSeriesPoint({
    required this.index,
    required this.value,
    this.position,
  });

  final int index;
  final double value;
  final double? position;
}

class StatsControlBar {
  const StatsControlBar({
    required this.index,
    required this.value,
    required this.colorHex,
    this.position,
  });

  final int index;
  final double value;
  final String colorHex;
  final double? position;

  double get deltaFromBaseline => value - 50;
}

class StatsHelperBar {
  const StatsHelperBar({
    required this.index,
    required this.rawValue,
    required this.value,
    required this.position,
    required this.colorHex,
  });

  final int index;
  final double rawValue;
  final double value;
  final double position;
  final String colorHex;
}

class StatsIncomeComparisonBar {
  const StatsIncomeComparisonBar({
    required this.index,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.signedValue,
    required this.position,
    required this.colorHex,
  });

  final int index;
  final double incomeAmount;
  final double expenseAmount;
  final double signedValue;
  final double position;
  final String colorHex;
}

class StatsMonthTick {
  const StatsMonthTick({required this.label, required this.position});

  final String label;
  final double position;
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

class _ScopeDaySample {
  const _ScopeDaySample({required this.month, required this.amount});

  final int? month;
  final double amount;
}
