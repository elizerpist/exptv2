import 'package:flutter/material.dart';

import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import 'stats_scope_model.dart';

enum StatsRenderMode { common }

enum StatsSummaryScope { allTime, yearly, monthly }

extension StatsRenderModeX on StatsRenderMode {
  String get title => switch (this) {
    StatsRenderMode.common => 'Közös',
  };
}

class StatsYearData {
  const StatsYearData({
    required this.year,
    required this.activeType,
    required this.mode,
    required this.summaryScope,
    required this.thresholdValue,
    required this.months,
    required this.summaryTotal,
    required this.summaryValue,
    required this.headerLabel,
    required this.headerValue,
    required this.scopeLabel,
    required this.selectedCategoryIds,
    required this.categoryTotals,
    required this.vendorSummaries,
    required this.totalThresholdHitDays,
    required this.graphMonths,
    required this.graphStartMonth,
    required this.graphEndMonth,
    required this.metricMonthCount,
    required this.metricDayCount,
    required this.metricRecordCount,
    required this.metricActiveDayCount,
    required this.largestRecordAmount,
    required this.topMonthAmount,
    required this.topMonthLabel,
    required this.periodAmounts,
    required this.periodLabels,
    required this.scorePeriodAmounts,
    required this.matchingExpensePeriodAmounts,
    required this.periodClosingAmounts,
  });

  final int year;
  final TransactionType activeType;
  final StatsRenderMode mode;
  final StatsSummaryScope summaryScope;
  final double thresholdValue;
  final List<StatsMonthData> months;
  final double summaryTotal;
  final String summaryValue;
  final String headerLabel;
  final String headerValue;
  final String scopeLabel;
  final Set<int> selectedCategoryIds;
  final Map<int, double> categoryTotals;
  final List<StatsVendorSummary> vendorSummaries;
  final int totalThresholdHitDays;
  final List<StatsMonthData> graphMonths;
  final int graphStartMonth;
  final int graphEndMonth;
  final int metricMonthCount;
  final int metricDayCount;
  final int metricRecordCount;
  final int metricActiveDayCount;
  final double largestRecordAmount;
  final double topMonthAmount;
  final String topMonthLabel;
  final List<double> periodAmounts;
  final List<String> periodLabels;
  final List<double> scorePeriodAmounts;
  final List<double> matchingExpensePeriodAmounts;
  final List<double> periodClosingAmounts;

  static const monthNames = [
    'Január',
    'Február',
    'Március',
    'Április',
    'Május',
    'Június',
    'Július',
    'Augusztus',
    'Szeptember',
    'Október',
    'November',
    'December',
  ];

  static const weekdayLabels = ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V'];

  static StatsYearData build({
    required int year,
    required TransactionType activeType,
    required StatsRenderMode mode,
    required double thresholdValue,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required Set<int> selectedCategoryIds,
    Set<String> vendorFilters = const <String>{},
    StatsSummaryScope summaryScope = StatsSummaryScope.yearly,
    int? month,
    DateTime? today,
  }) {
    final activeCategoryIds = categories
        .where((category) => category.normalizedType == activeType)
        .map((category) => category.transactionCategoryID)
        .toSet();
    final scopeSelection = StatsScopeSelection.normalize(
      selectedCategoryIds: selectedCategoryIds,
      availableCategoryIds: activeCategoryIds,
    );
    final scopedCategoryIds = scopeSelection.selectedCategoryIds;
    final categoriesById = <int, TransactionCategory>{
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    final normalizedToday = _dateOnly(today ?? DateTime.now());
    final targetMonth = (month ?? normalizedToday.month).clamp(1, 12).toInt();
    final byDate = <DateTime, List<TransactionRecord>>{};
    final incomeByDisplayDate = <DateTime, double>{};
    final expenseByDisplayDate = <DateTime, double>{};
    final rawScoreDayTotals = <DateTime, double>{};
    final incomeDayTotals = <DateTime, double>{};
    final expenseDayTotals = <DateTime, double>{};
    final totalCategoryTotals = <int, double>{};
    final vendorTotals = <String, _StatsVendorAccumulator>{};
    final metricActiveDates = <DateTime>{};
    final metricDayTotals = <DateTime, double>{};
    final metricMonthTotals = <String, double>{};
    final metricYearTotals = <int, double>{};
    var metricRecordCount = 0;
    var largestRecordAmount = 0.0;
    int? firstActiveMonth;
    int? lastActiveMonth;
    for (final record in transactions) {
      final parsed = _parseDate(record.normalizedDate);
      if (parsed == null) continue;
      final displayDate = _displayDateForScope(
        parsed: parsed,
        year: year,
        month: targetMonth,
        summaryScope: summaryScope,
      );
      if (displayDate == null) continue;
      if (!_matchesVendorFilter(record, vendorFilters)) continue;
      final recordType = _recordType(record);
      final amount = record.amount.abs();
      final originalDate = _dateOnly(parsed);
      final canonicalDisplayTotals = recordType == TransactionType.income
          ? incomeByDisplayDate
          : expenseByDisplayDate;
      final canonicalOriginalTotals = recordType == TransactionType.income
          ? incomeDayTotals
          : expenseDayTotals;
      canonicalDisplayTotals.update(
        _dateOnly(displayDate),
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      canonicalOriginalTotals.update(
        originalDate,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      final matchesType = recordType == activeType;
      if (!matchesType) continue;
      if (scopeSelection.includesCategory(record.transactionCategoryID)) {
        rawScoreDayTotals.update(
          originalDate,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
      firstActiveMonth = firstActiveMonth == null
          ? displayDate.month
          : (displayDate.month < firstActiveMonth
                ? displayDate.month
                : firstActiveMonth);
      lastActiveMonth = lastActiveMonth == null
          ? displayDate.month
          : (displayDate.month > lastActiveMonth
                ? displayDate.month
                : lastActiveMonth);
      byDate
          .putIfAbsent(_dateOnly(displayDate), () => <TransactionRecord>[])
          .add(record);
    }

    var summaryTotal = 0.0;
    final unscaledMonths = <StatsMonthData>[];
    final heatCategoryId = scopeSelection.isAll
        ? (activeCategoryIds.length == 1 ? activeCategoryIds.single : null)
        : (scopedCategoryIds.length == 1 ? scopedCategoryIds.single : null);
    final heatColor = heatCategoryId == null
        ? const Color(0xFF06B6D4)
        : _categoryColor(heatCategoryId, categoriesById);
    for (var index = 0; index < 12; index += 1) {
      final month = index + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final firstDay = DateTime(year, month, 1);
      final days = <StatsDayData>[];
      var monthTotal = 0.0;
      var scopeTotal = 0.0;
      var thresholdHitDays = 0;
      var hotDays = 0;
      var transactionCount = 0;
      final scopeCategoryTotals = <int, double>{};

      for (var day = 1; day <= daysInMonth; day += 1) {
        final date = DateTime(year, month, day);
        final records = byDate[_dateOnly(date)] ?? const <TransactionRecord>[];
        transactionCount += records.length;
        var activeAmount = 0.0;
        var scopedAmount = 0.0;
        var rawScopedAmount = 0.0;
        final categoryAmounts = <int, double>{};

        for (final record in records) {
          final amount = record.amount.abs();
          final categoryId = record.transactionCategoryID;
          final inScope = scopeSelection.includesCategory(categoryId);
          if (inScope) rawScopedAmount += amount;
          if (thresholdValue > 0 && amount < thresholdValue) continue;
          activeAmount += amount;
          if (!inScope) continue;
          scopedAmount += amount;
          metricRecordCount += 1;
          if (amount > largestRecordAmount) largestRecordAmount = amount;
          final parsedOriginal = _parseDate(record.normalizedDate);
          if (parsedOriginal != null) {
            final originalDate = _dateOnly(parsedOriginal);
            metricActiveDates.add(originalDate);
            metricDayTotals.update(
              originalDate,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
            final monthKey = _monthKey(
              parsedOriginal.year,
              parsedOriginal.month,
            );
            metricMonthTotals.update(
              monthKey,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
            metricYearTotals.update(
              parsedOriginal.year,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
          }
          if (categoryId != null) {
            categoryAmounts.update(
              categoryId,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
            scopeCategoryTotals.update(
              categoryId,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
            totalCategoryTotals.update(
              categoryId,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
          }
          final vendorName = record.displayMerchant.trim().isEmpty
              ? record.merchant.trim()
              : record.displayMerchant.trim();
          if (vendorName.isNotEmpty) {
            vendorTotals
                .putIfAbsent(
                  vendorName,
                  () => _StatsVendorAccumulator(vendorName),
                )
                .add(amount: amount, categoryId: categoryId);
          }
        }

        final dominantCategoryId = _dominantCategoryId(categoryAmounts);
        final meetsThreshold = scopedAmount > 0;
        if (meetsThreshold) thresholdHitDays += 1;
        if (activeAmount >= thresholdValue && activeAmount > 0) hotDays += 1;
        monthTotal += activeAmount;
        scopeTotal += scopedAmount;
        days.add(
          StatsDayData(
            date: date,
            day: day,
            activeAmount: activeAmount,
            scopeAmount: scopedAmount,
            scoreScopeAmount: rawScopedAmount,
            meetsThreshold: meetsThreshold,
            heatmapIntensity: 0,
            hasActiveTypeActivity: activeAmount > 0,
            dominantCategoryId: dominantCategoryId,
            dominantCategoryColor: heatColor,
            isToday: _dateOnly(date) == normalizedToday,
          ),
        );
      }

      summaryTotal += scopeTotal;
      final canonicalIncome = _monthTotal(incomeByDisplayDate, year, month);
      final canonicalExpense = _monthTotal(expenseByDisplayDate, year, month);
      unscaledMonths.add(
        StatsMonthData(
          year: year,
          month: month,
          name: monthNames[index],
          weekdayLabels: weekdayLabels,
          leadingBlankDays: firstDay.weekday - 1,
          days: days,
          activeTotal: monthTotal,
          scopeTotal: scopeTotal,
          closingAmount: canonicalIncome - canonicalExpense,
          matchingExpenseTotal: canonicalExpense,
          scopeCategoryTotals: Map.unmodifiable(scopeCategoryTotals),
          thresholdHitDays: thresholdHitDays,
          hotDays: hotDays,
          transactionCount: transactionCount,
        ),
      );
    }

    final maxHeatAmount = unscaledMonths
        .expand((month) => month.days)
        .fold<double>(
          0,
          (max, day) => day.scopeAmount > max ? day.scopeAmount : max,
        );
    final months = [
      for (final month in unscaledMonths)
        month.copyWith(
          days: [
            for (final day in month.days)
              day.copyWith(
                heatmapIntensity: day.meetsThreshold && maxHeatAmount > 0
                    ? (day.scopeAmount / maxHeatAmount)
                          .clamp(0.0, 1.0)
                          .toDouble()
                    : 0,
              ),
          ],
        ),
    ];

    final scopeLabel = _scopeLabel(
      activeType: activeType,
      scopedCategoryIds: scopedCategoryIds,
      categoriesById: categoriesById,
    );
    final totalThresholdHitDays = months.fold<int>(
      0,
      (sum, month) => sum + month.thresholdHitDays,
    );
    final graphStartMonth = summaryScope == StatsSummaryScope.monthly
        ? targetMonth
        : firstActiveMonth ?? 1;
    final graphEndMonth = summaryScope == StatsSummaryScope.monthly
        ? targetMonth
        : lastActiveMonth ?? 12;
    final graphMonths = months
        .where(
          (month) =>
              month.month >= graphStartMonth && month.month <= graphEndMonth,
        )
        .toList(growable: false);
    final periodMetrics = _periodMetrics(
      year: year,
      month: targetMonth,
      summaryScope: summaryScope,
      activeDates: metricActiveDates,
      dayTotals: metricDayTotals,
      monthTotals: metricMonthTotals,
      yearTotals: metricYearTotals,
    );
    final scorePeriodAmounts = _scorePeriodAmounts(
      summaryScope: summaryScope,
      year: year,
      month: targetMonth,
      labels: periodMetrics.periodLabels,
      rawDayTotals: rawScoreDayTotals,
      threshold: thresholdValue,
    );
    final matchingExpensePeriodAmounts = _canonicalPeriodAmounts(
      summaryScope: summaryScope,
      year: year,
      month: targetMonth,
      labels: periodMetrics.periodLabels,
      dayTotals: expenseDayTotals,
    );
    final matchingIncomePeriodAmounts = _canonicalPeriodAmounts(
      summaryScope: summaryScope,
      year: year,
      month: targetMonth,
      labels: periodMetrics.periodLabels,
      dayTotals: incomeDayTotals,
    );
    return StatsYearData(
      year: year,
      activeType: activeType,
      mode: mode,
      summaryScope: summaryScope,
      thresholdValue: thresholdValue,
      months: List.unmodifiable(months),
      summaryTotal: summaryTotal,
      summaryValue: formatHuf(summaryTotal),
      headerLabel: _headerLabel(mode),
      headerValue: _headerValue(
        mode: mode,
        activeType: activeType,
        thresholdValue: thresholdValue,
        months: months,
        scopeLabel: scopeLabel,
        totalThresholdHitDays: totalThresholdHitDays,
      ),
      scopeLabel: scopeLabel,
      selectedCategoryIds: Set.unmodifiable(scopedCategoryIds),
      categoryTotals: Map.unmodifiable(totalCategoryTotals),
      vendorSummaries: _vendorSummaries(vendorTotals, categoriesById),
      totalThresholdHitDays: totalThresholdHitDays,
      graphMonths: List.unmodifiable(graphMonths),
      graphStartMonth: graphStartMonth,
      graphEndMonth: graphEndMonth,
      metricMonthCount: periodMetrics.monthCount,
      metricDayCount: periodMetrics.dayCount,
      metricRecordCount: metricRecordCount,
      metricActiveDayCount: metricActiveDates.length,
      largestRecordAmount: largestRecordAmount,
      topMonthAmount: periodMetrics.topMonthAmount,
      topMonthLabel: periodMetrics.topMonthLabel,
      periodAmounts: List.unmodifiable(periodMetrics.periodAmounts),
      periodLabels: List.unmodifiable(periodMetrics.periodLabels),
      scorePeriodAmounts: List.unmodifiable(scorePeriodAmounts),
      matchingExpensePeriodAmounts: List.unmodifiable(
        matchingExpensePeriodAmounts,
      ),
      periodClosingAmounts: List.unmodifiable([
        for (
          var index = 0;
          index < periodMetrics.periodLabels.length;
          index += 1
        )
          matchingIncomePeriodAmounts[index] -
              matchingExpensePeriodAmounts[index],
      ]),
    );
  }

  static String _headerLabel(StatsRenderMode mode) => switch (mode) {
    StatsRenderMode.common => 'SZŰRÉS PONTSZÁM',
  };

  static String _headerValue({
    required StatsRenderMode mode,
    required TransactionType activeType,
    required double thresholdValue,
    required List<StatsMonthData> months,
    required String scopeLabel,
    required int totalThresholdHitDays,
  }) {
    return switch (mode) {
      StatsRenderMode.common => _categoryScopeHeader(
        months: months,
        scopeLabel: scopeLabel,
        totalThresholdHitDays: totalThresholdHitDays,
      ),
    };
  }

  static String _categoryScopeHeader({
    required List<StatsMonthData> months,
    required String scopeLabel,
    required int totalThresholdHitDays,
  }) {
    final firstQuarter = months
        .take(3)
        .fold<int>(0, (sum, month) => sum + month.thresholdHitDays);
    final lastQuarter = months
        .skip(9)
        .fold<int>(0, (sum, month) => sum + month.thresholdHitDays);
    if (firstQuarter > 0 || lastQuarter > 0) {
      return '$scopeLabel $firstQuarter → $lastQuarter nap';
    }
    return '$scopeLabel: $totalThresholdHitDays nap';
  }

  static String _scopeLabel({
    required TransactionType activeType,
    required Set<int> scopedCategoryIds,
    required Map<int, TransactionCategory> categoriesById,
  }) {
    if (scopedCategoryIds.isEmpty) return 'Minden kategória';
    final names =
        scopedCategoryIds
            .map((id) => categoriesById[id]?.name.trim())
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toList()
          ..sort();
    if (names.isEmpty) return 'Minden kategória';
    if (names.length <= 2) return names.join(' + ');
    return '${names.first} +${names.length - 1}';
  }

  static TransactionType _recordType(TransactionRecord record) =>
      record.amount > 0 ? TransactionType.income : TransactionType.expense;

  static bool _matchesVendorFilter(
    TransactionRecord record,
    Set<String> vendorFilters,
  ) {
    if (vendorFilters.isEmpty) return true;
    final displayName = record.displayMerchant.trim();
    final originalName = record.merchant.trim();
    return vendorFilters.contains(displayName) ||
        vendorFilters.contains(originalName);
  }

  static DateTime? _displayDateForScope({
    required DateTime parsed,
    required int year,
    required int month,
    required StatsSummaryScope summaryScope,
  }) {
    return switch (summaryScope) {
      StatsSummaryScope.yearly =>
        parsed.year == year ? _dateOnly(parsed) : null,
      StatsSummaryScope.monthly =>
        parsed.year == year && parsed.month == month ? _dateOnly(parsed) : null,
      StatsSummaryScope.allTime => DateTime(
        year,
        parsed.month,
        parsed.day.clamp(1, DateTime(year, parsed.month + 1, 0).day).toInt(),
      ),
    };
  }

  static int? _dominantCategoryId(Map<int, double> categoryAmounts) {
    int? id;
    var amount = -1.0;
    for (final entry in categoryAmounts.entries) {
      if (entry.value > amount) {
        id = entry.key;
        amount = entry.value;
      }
    }
    return id;
  }

  static Color _categoryColor(
    int? categoryId,
    Map<int, TransactionCategory> categoriesById,
  ) {
    if (categoryId == null) return const Color(0xFF06B6D4);
    return categoriesById[categoryId]?.slotColor ?? const Color(0xFF06B6D4);
  }

  static DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    return DateTime.tryParse(value.replaceAll('.', '-'));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _monthKey(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  static double _monthTotal(
    Map<DateTime, double> dayTotals,
    int year,
    int month,
  ) {
    return dayTotals.entries
        .where((entry) => entry.key.year == year && entry.key.month == month)
        .fold<double>(0, (sum, entry) => sum + entry.value);
  }

  static List<double> _scorePeriodAmounts({
    required StatsSummaryScope summaryScope,
    required int year,
    required int month,
    required List<String> labels,
    required Map<DateTime, double> rawDayTotals,
    required double threshold,
  }) {
    final qualifying = <DateTime, double>{
      for (final entry in rawDayTotals.entries)
        if (entry.value > 0 && entry.value >= threshold) entry.key: entry.value,
    };
    if (summaryScope == StatsSummaryScope.allTime) {
      if (qualifying.isEmpty) return const <double>[];
      final dates = qualifying.keys.toList()..sort();
      final first = dates.first;
      final dayCount = dates.last.difference(first).inDays + 1;
      return [
        for (var offset = 0; offset < dayCount; offset += 1)
          qualifying[_dateOnly(first.add(Duration(days: offset)))] ?? 0,
      ];
    }
    return _canonicalPeriodAmounts(
      summaryScope: summaryScope,
      year: year,
      month: month,
      labels: labels,
      dayTotals: qualifying,
    );
  }

  static List<double> _canonicalPeriodAmounts({
    required StatsSummaryScope summaryScope,
    required int year,
    required int month,
    required List<String> labels,
    required Map<DateTime, double> dayTotals,
  }) {
    return switch (summaryScope) {
      StatsSummaryScope.monthly => [
        for (var day = 1; day <= labels.length; day += 1)
          dayTotals[DateTime(year, month, day)] ?? 0,
      ],
      StatsSummaryScope.yearly => [
        for (var valueMonth = 1; valueMonth <= labels.length; valueMonth += 1)
          dayTotals.entries
              .where(
                (entry) =>
                    entry.key.year == year && entry.key.month == valueMonth,
              )
              .fold<double>(0, (sum, entry) => sum + entry.value),
      ],
      StatsSummaryScope.allTime => [
        for (final label in labels)
          dayTotals.entries
              .where((entry) => entry.key.year == int.tryParse(label))
              .fold<double>(0, (sum, entry) => sum + entry.value),
      ],
    };
  }

  static _StatsPeriodMetrics _periodMetrics({
    required int year,
    required int month,
    required StatsSummaryScope summaryScope,
    required Set<DateTime> activeDates,
    required Map<DateTime, double> dayTotals,
    required Map<String, double> monthTotals,
    required Map<int, double> yearTotals,
  }) {
    final topMonth = _topMonth(monthTotals);
    return switch (summaryScope) {
      StatsSummaryScope.monthly => _StatsPeriodMetrics(
        monthCount: 1,
        dayCount: DateTime(year, month + 1, 0).day,
        topMonthAmount: topMonth.amount,
        topMonthLabel: topMonth.label,
        periodAmounts: _dailyPeriodAmounts(year, month, dayTotals),
        periodLabels: [
          for (var day = 1; day <= DateTime(year, month + 1, 0).day; day += 1)
            day.toString(),
        ],
      ),
      StatsSummaryScope.yearly => _StatsPeriodMetrics(
        monthCount: 12,
        dayCount: DateTime(year + 1).difference(DateTime(year)).inDays,
        topMonthAmount: topMonth.amount,
        topMonthLabel: topMonth.label,
        periodAmounts: [
          for (var valueMonth = 1; valueMonth <= 12; valueMonth += 1)
            monthTotals[_monthKey(year, valueMonth)] ?? 0,
        ],
        periodLabels: [
          for (var valueMonth = 1; valueMonth <= 12; valueMonth += 1)
            _monthAbbreviation(valueMonth),
        ],
      ),
      StatsSummaryScope.allTime => _allTimePeriodMetrics(
        activeDates: activeDates,
        monthTotals: monthTotals,
        yearTotals: yearTotals,
        topMonth: topMonth,
      ),
    };
  }

  static _StatsPeriodMetrics _allTimePeriodMetrics({
    required Set<DateTime> activeDates,
    required Map<String, double> monthTotals,
    required Map<int, double> yearTotals,
    required _TopMonth topMonth,
  }) {
    if (activeDates.isEmpty) {
      return _StatsPeriodMetrics(
        monthCount: 0,
        dayCount: 0,
        topMonthAmount: 0,
        topMonthLabel: '-',
        periodAmounts: const <double>[],
        periodLabels: const <String>[],
      );
    }
    final sortedDates = activeDates.toList()..sort();
    final first = sortedDates.first;
    final last = sortedDates.last;
    final monthCount =
        (last.year - first.year) * 12 + (last.month - first.month) + 1;
    final years = yearTotals.keys.toList()..sort();
    return _StatsPeriodMetrics(
      monthCount: monthCount,
      dayCount: last.difference(first).inDays + 1,
      topMonthAmount: topMonth.amount,
      topMonthLabel: topMonth.label,
      periodAmounts: [
        for (final valueYear in years) yearTotals[valueYear] ?? 0,
      ],
      periodLabels: [for (final valueYear in years) valueYear.toString()],
    );
  }

  static List<double> _dailyPeriodAmounts(
    int year,
    int month,
    Map<DateTime, double> dayTotals,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return [
      for (var day = 1; day <= daysInMonth; day += 1)
        dayTotals[DateTime(year, month, day)] ?? 0,
    ];
  }

  static _TopMonth _topMonth(Map<String, double> monthTotals) {
    if (monthTotals.isEmpty) return const _TopMonth(amount: 0, label: '-');
    final entries = monthTotals.entries.toList()
      ..sort((left, right) {
        final amountOrder = right.value.compareTo(left.value);
        if (amountOrder != 0) return amountOrder;
        return left.key.compareTo(right.key);
      });
    final key = entries.first.key;
    final year = int.tryParse(key.substring(0, 4)) ?? 0;
    final month = int.tryParse(key.substring(5, 7)) ?? 1;
    final multiYear =
        monthTotals.keys.map((value) => value.substring(0, 4)).toSet().length >
        1;
    return _TopMonth(
      amount: entries.first.value,
      label: multiYear
          ? '${monthNames[month - 1]} $year'
          : monthNames[month - 1],
    );
  }

  static String _monthAbbreviation(int month) {
    const labels = [
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
    return labels[(month - 1).clamp(0, 11)];
  }

  static List<StatsVendorSummary> _vendorSummaries(
    Map<String, _StatsVendorAccumulator> totals,
    Map<int, TransactionCategory> categoriesById,
  ) {
    final rows =
        [
          for (final accumulator in totals.values)
            accumulator.toSummary(categoriesById),
        ]..sort((left, right) {
          final totalOrder = right.total.compareTo(left.total);
          if (totalOrder != 0) return totalOrder;
          return left.name.compareTo(right.name);
        });
    return List.unmodifiable(rows);
  }
}

class StatsVendorSummary {
  const StatsVendorSummary({
    required this.name,
    required this.total,
    required this.count,
    required this.color,
  });

  final String name;
  final double total;
  final int count;
  final Color color;
}

class _StatsVendorAccumulator {
  _StatsVendorAccumulator(this.name);

  final String name;
  final categoryTotals = <int, double>{};
  double total = 0;
  int count = 0;

  void add({required double amount, required int? categoryId}) {
    total += amount;
    count += 1;
    if (categoryId == null) return;
    categoryTotals.update(
      categoryId,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
  }

  StatsVendorSummary toSummary(Map<int, TransactionCategory> categoriesById) {
    int? dominantCategoryId;
    var dominantAmount = -1.0;
    for (final entry in categoryTotals.entries) {
      if (entry.value <= dominantAmount) continue;
      dominantCategoryId = entry.key;
      dominantAmount = entry.value;
    }
    return StatsVendorSummary(
      name: name,
      total: total,
      count: count,
      color: StatsYearData._categoryColor(dominantCategoryId, categoriesById),
    );
  }
}

class _StatsPeriodMetrics {
  const _StatsPeriodMetrics({
    required this.monthCount,
    required this.dayCount,
    required this.topMonthAmount,
    required this.topMonthLabel,
    required this.periodAmounts,
    required this.periodLabels,
  });

  final int monthCount;
  final int dayCount;
  final double topMonthAmount;
  final String topMonthLabel;
  final List<double> periodAmounts;
  final List<String> periodLabels;
}

class _TopMonth {
  const _TopMonth({required this.amount, required this.label});

  final double amount;
  final String label;
}

class StatsMonthData {
  const StatsMonthData({
    required this.year,
    required this.month,
    required this.name,
    required this.weekdayLabels,
    required this.leadingBlankDays,
    required this.days,
    required this.activeTotal,
    required this.scopeTotal,
    required this.closingAmount,
    required this.matchingExpenseTotal,
    required this.scopeCategoryTotals,
    required this.thresholdHitDays,
    required this.hotDays,
    required this.transactionCount,
  });

  final int year;
  final int month;
  final String name;
  final List<String> weekdayLabels;
  final int leadingBlankDays;
  final List<StatsDayData> days;
  final double activeTotal;
  final double scopeTotal;
  final double closingAmount;
  final double matchingExpenseTotal;
  final Map<int, double> scopeCategoryTotals;
  final int thresholdHitDays;
  final int hotDays;
  final int transactionCount;

  bool get hasTransactions => transactionCount > 0;

  StatsMonthData copyWith({List<StatsDayData>? days}) {
    return StatsMonthData(
      year: year,
      month: month,
      name: name,
      weekdayLabels: weekdayLabels,
      leadingBlankDays: leadingBlankDays,
      days: days ?? this.days,
      activeTotal: activeTotal,
      scopeTotal: scopeTotal,
      closingAmount: closingAmount,
      matchingExpenseTotal: matchingExpenseTotal,
      scopeCategoryTotals: scopeCategoryTotals,
      thresholdHitDays: thresholdHitDays,
      hotDays: hotDays,
      transactionCount: transactionCount,
    );
  }
}

class StatsDayData {
  const StatsDayData({
    required this.date,
    required this.day,
    required this.activeAmount,
    required this.scopeAmount,
    required this.scoreScopeAmount,
    required this.meetsThreshold,
    required this.heatmapIntensity,
    required this.hasActiveTypeActivity,
    required this.dominantCategoryId,
    required this.dominantCategoryColor,
    required this.isToday,
  });

  final DateTime date;
  final int day;
  final double activeAmount;
  final double scopeAmount;
  final double scoreScopeAmount;
  final bool meetsThreshold;
  final double heatmapIntensity;
  final bool hasActiveTypeActivity;
  final int? dominantCategoryId;
  final Color dominantCategoryColor;
  final bool isToday;

  StatsDayData copyWith({double? heatmapIntensity}) {
    return StatsDayData(
      date: date,
      day: day,
      activeAmount: activeAmount,
      scopeAmount: scopeAmount,
      scoreScopeAmount: scoreScopeAmount,
      meetsThreshold: meetsThreshold,
      heatmapIntensity: heatmapIntensity ?? this.heatmapIntensity,
      hasActiveTypeActivity: hasActiveTypeActivity,
      dominantCategoryId: dominantCategoryId,
      dominantCategoryColor: dominantCategoryColor,
      isToday: isToday,
    );
  }
}
