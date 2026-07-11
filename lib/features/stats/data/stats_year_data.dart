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
    required this.visibleTransactions,
    required this.observedMaximum,
    required this.largestVisibleVendor,
    required this.canonicalIncomeTotal,
    required this.canonicalExpenseTotal,
    required this.sumYearSummaries,
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
  final List<TransactionRecord> visibleTransactions;
  final double observedMaximum;
  final String largestVisibleVendor;
  final double canonicalIncomeTotal;
  final double canonicalExpenseTotal;
  final List<StatsSumYearSummary> sumYearSummaries;

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
    final byDate = <int, List<_StatsDatedRecord>>{};
    final parsedDateCache = <String, _StatsDateParts?>{};
    final incomeByDisplayMonth = <int, double>{};
    final expenseByDisplayMonth = <int, double>{};
    final rawScoreDayTotals = <int, double>{};
    final incomeDayTotals = <int, double>{};
    final expenseDayTotals = <int, double>{};
    final totalCategoryTotals = <int, double>{};
    final vendorTotals = <String, _StatsVendorAccumulator>{};
    final metricActiveDates = <int>{};
    final metricDayTotals = <int, double>{};
    final metricMonthTotals = <int, double>{};
    final metricYearTotals = <int, double>{};
    final visibleTransactions = <TransactionRecord>[];
    final sumYearBuilders = <int, _StatsSumYearSummaryBuilder>{};
    var metricRecordCount = 0;
    var largestRecordAmount = 0.0;
    var largestVisibleVendor = 'Nincs találat';
    var canonicalIncomeTotal = 0.0;
    var canonicalExpenseTotal = 0.0;
    int? firstActiveMonth;
    int? lastActiveMonth;
    for (final record in transactions) {
      final originalDate = parsedDateCache.putIfAbsent(record.date, () {
        return _parseDate(record.date);
      });
      if (originalDate == null) continue;
      final inPeriod = switch (summaryScope) {
        StatsSummaryScope.yearly => originalDate.year == year,
        StatsSummaryScope.monthly =>
          originalDate.year == year && originalDate.month == targetMonth,
        StatsSummaryScope.allTime => true,
      };
      if (!inPeriod) continue;
      final displayDay = summaryScope == StatsSummaryScope.allTime
          ? originalDate.day.clamp(1, _daysInMonth(year, originalDate.month))
          : originalDate.day;
      final displayDateKey = originalDate.month * 100 + displayDay;
      if (!_matchesVendorFilter(record, vendorFilters)) continue;
      final recordType = _recordType(record);
      final amount = record.amount.abs();
      final sumYearBuilder = sumYearBuilders.putIfAbsent(
        originalDate.year,
        () => _StatsSumYearSummaryBuilder(originalDate.year),
      );
      sumYearBuilder.closingAmount += record.amount;
      if (recordType == TransactionType.income) {
        canonicalIncomeTotal += amount;
      } else {
        canonicalExpenseTotal += amount;
      }
      final canonicalDisplayTotals = recordType == TransactionType.income
          ? incomeByDisplayMonth
          : expenseByDisplayMonth;
      final canonicalOriginalTotals = recordType == TransactionType.income
          ? incomeDayTotals
          : expenseDayTotals;
      canonicalDisplayTotals.update(
        originalDate.month,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      canonicalOriginalTotals.update(
        originalDate.dateKey,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      final matchesType = recordType == activeType;
      if (!matchesType) continue;
      final isInCategoryScope = scopeSelection.includesCategory(
        record.transactionCategoryID,
      );
      if (isInCategoryScope) {
        rawScoreDayTotals.update(
          originalDate.dateKey,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        firstActiveMonth = firstActiveMonth == null
            ? originalDate.month
            : (originalDate.month < firstActiveMonth
                  ? originalDate.month
                  : firstActiveMonth);
        lastActiveMonth = lastActiveMonth == null
            ? originalDate.month
            : (originalDate.month > lastActiveMonth
                  ? originalDate.month
                  : lastActiveMonth);
      }
      byDate
          .putIfAbsent(displayDateKey, () => <_StatsDatedRecord>[])
          .add(_StatsDatedRecord(record, originalDate));
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
        final records =
            byDate[month * 100 + day] ?? const <_StatsDatedRecord>[];
        var activeAmount = 0.0;
        var scopedAmount = 0.0;
        var rawScopedAmount = 0.0;
        final categoryAmounts = <int, double>{};

        for (final datedRecord in records) {
          final record = datedRecord.record;
          final amount = record.amount.abs();
          final categoryId = record.transactionCategoryID;
          final inScope = scopeSelection.includesCategory(categoryId);
          if (inScope) rawScopedAmount += amount;
          if (thresholdValue > 0 && amount < thresholdValue) continue;
          if (!inScope) continue;
          activeAmount += amount;
          scopedAmount += amount;
          transactionCount += 1;
          metricRecordCount += 1;
          visibleTransactions.add(record);
          if (amount > largestRecordAmount) {
            largestRecordAmount = amount;
            largestVisibleVendor = record.displayMerchant.trim().isEmpty
                ? record.merchant.trim()
                : record.displayMerchant.trim();
            if (largestVisibleVendor.isEmpty) {
              largestVisibleVendor = 'Nincs találat';
            }
          }
          final originalDate = datedRecord.originalDate;
          metricActiveDates.add(originalDate.dateKey);
          metricDayTotals.update(
            originalDate.dateKey,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
          final monthKey = originalDate.monthKey;
          metricMonthTotals.update(
            monthKey,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
          metricYearTotals.update(
            originalDate.year,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
          sumYearBuilders[originalDate.year]?.monthTotals.update(
            originalDate.month,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
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
            isToday: date == normalizedToday,
          ),
        );
      }

      summaryTotal += scopeTotal;
      final canonicalIncome = incomeByDisplayMonth[month] ?? 0;
      final canonicalExpense = expenseByDisplayMonth[month] ?? 0;
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
    final observedMaximum = rawScoreDayTotals.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
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
    final sumYearSummaries = [
      for (final builder in sumYearBuilders.values) builder.build(),
    ]..sort((left, right) => right.year.compareTo(left.year));
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
      visibleTransactions: List.unmodifiable(visibleTransactions),
      observedMaximum: observedMaximum,
      largestVisibleVendor: largestVisibleVendor,
      canonicalIncomeTotal: canonicalIncomeTotal,
      canonicalExpenseTotal: canonicalExpenseTotal,
      sumYearSummaries: List.unmodifiable(sumYearSummaries),
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

  static _StatsDateParts? _parseDate(String value) {
    if (value.length == 10 &&
        (value[4] == '-' || value[4] == '.') &&
        value[7] == value[4]) {
      final year = int.tryParse(value.substring(0, 4));
      final month = int.tryParse(value.substring(5, 7));
      final day = int.tryParse(value.substring(8, 10));
      if (year == null || month == null || day == null) return null;
      if (month < 1 ||
          month > 12 ||
          day < 1 ||
          day > _daysInMonth(year, month)) {
        return null;
      }
      return _StatsDateParts(year, month, day);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return _StatsDateParts(parsed.year, parsed.month, parsed.day);
    }
    final legacy = DateTime.tryParse(value.replaceAll('.', '-'));
    return legacy == null
        ? null
        : _StatsDateParts(legacy.year, legacy.month, legacy.day);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _daysInMonth(int year, int month) {
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && _isLeapYear(year)) return 29;
    return days[month - 1];
  }

  static bool _isLeapYear(int year) =>
      year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);

  static int _dateOrdinalFromKey(int key) {
    final year = key ~/ 10000;
    final month = (key ~/ 100) % 100;
    final day = key % 100;
    final adjustedYear = year - (month <= 2 ? 1 : 0);
    final era = adjustedYear ~/ 400;
    final yearOfEra = adjustedYear - era * 400;
    final adjustedMonth = month + (month > 2 ? -3 : 9);
    final dayOfYear = (153 * adjustedMonth + 2) ~/ 5 + day - 1;
    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra;
  }

  static List<double> _scorePeriodAmounts({
    required StatsSummaryScope summaryScope,
    required int year,
    required int month,
    required List<String> labels,
    required Map<int, double> rawDayTotals,
    required double threshold,
  }) {
    final qualifying = <int, double>{
      for (final entry in rawDayTotals.entries)
        if (entry.value > 0 && entry.value >= threshold) entry.key: entry.value,
    };
    if (summaryScope == StatsSummaryScope.allTime) {
      if (qualifying.isEmpty) return const <double>[];
      final dates = qualifying.keys.toList()..sort();
      final amounts = <double>[];
      int? previousOrdinal;
      for (final date in dates) {
        final ordinal = _dateOrdinalFromKey(date);
        if (previousOrdinal != null) {
          final gap = ordinal - previousOrdinal - 1;
          if (gap > 0) amounts.addAll(List<double>.filled(gap, 0));
        }
        amounts.add(qualifying[date]!);
        previousOrdinal = ordinal;
      }
      return amounts;
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
    required Map<int, double> dayTotals,
  }) {
    if (summaryScope == StatsSummaryScope.monthly) {
      return [
        for (var day = 1; day <= labels.length; day += 1)
          dayTotals[year * 10000 + month * 100 + day] ?? 0,
      ];
    }
    if (summaryScope == StatsSummaryScope.yearly) {
      final amounts = List<double>.filled(labels.length, 0);
      for (final entry in dayTotals.entries) {
        if (entry.key ~/ 10000 != year) continue;
        final index = (entry.key ~/ 100) % 100 - 1;
        if (index >= 0 && index < amounts.length) {
          amounts[index] += entry.value;
        }
      }
      return amounts;
    }
    final totalsByYear = <int, double>{};
    for (final entry in dayTotals.entries) {
      totalsByYear.update(
        entry.key ~/ 10000,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    return [for (final label in labels) totalsByYear[int.tryParse(label)] ?? 0];
  }

  static _StatsPeriodMetrics _periodMetrics({
    required int year,
    required int month,
    required StatsSummaryScope summaryScope,
    required Set<int> activeDates,
    required Map<int, double> dayTotals,
    required Map<int, double> monthTotals,
    required Map<int, double> yearTotals,
  }) {
    final topMonth = _topMonth(monthTotals);
    return switch (summaryScope) {
      StatsSummaryScope.monthly => _StatsPeriodMetrics(
        monthCount: 1,
        dayCount: _daysInMonth(year, month),
        topMonthAmount: topMonth.amount,
        topMonthLabel: topMonth.label,
        periodAmounts: _dailyPeriodAmounts(year, month, dayTotals),
        periodLabels: [
          for (var day = 1; day <= _daysInMonth(year, month); day += 1)
            day.toString(),
        ],
      ),
      StatsSummaryScope.yearly => _StatsPeriodMetrics(
        monthCount: 12,
        dayCount: _isLeapYear(year) ? 366 : 365,
        topMonthAmount: topMonth.amount,
        topMonthLabel: topMonth.label,
        periodAmounts: [
          for (var valueMonth = 1; valueMonth <= 12; valueMonth += 1)
            monthTotals[year * 100 + valueMonth] ?? 0,
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
    required Set<int> activeDates,
    required Map<int, double> monthTotals,
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
    final firstYear = first ~/ 10000;
    final firstMonth = (first ~/ 100) % 100;
    final lastYear = last ~/ 10000;
    final lastMonth = (last ~/ 100) % 100;
    final monthCount =
        (lastYear - firstYear) * 12 + (lastMonth - firstMonth) + 1;
    final years = yearTotals.keys.toList()..sort();
    return _StatsPeriodMetrics(
      monthCount: monthCount,
      dayCount: _dateOrdinalFromKey(last) - _dateOrdinalFromKey(first) + 1,
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
    Map<int, double> dayTotals,
  ) {
    final daysInMonth = _daysInMonth(year, month);
    return [
      for (var day = 1; day <= daysInMonth; day += 1)
        dayTotals[year * 10000 + month * 100 + day] ?? 0,
    ];
  }

  static _TopMonth _topMonth(Map<int, double> monthTotals) {
    if (monthTotals.isEmpty) return const _TopMonth(amount: 0, label: '-');
    final entries = monthTotals.entries.toList()
      ..sort((left, right) {
        final amountOrder = right.value.compareTo(left.value);
        if (amountOrder != 0) return amountOrder;
        return left.key.compareTo(right.key);
      });
    final key = entries.first.key;
    final year = key ~/ 100;
    final month = key % 100;
    final multiYear =
        monthTotals.keys.map((value) => value ~/ 100).toSet().length > 1;
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

class StatsSumYearSummary {
  const StatsSumYearSummary({
    required this.year,
    required this.monthTotals,
    required this.closingAmount,
  });

  final int year;
  final Map<int, double> monthTotals;
  final double closingAmount;

  double get scopeTotal =>
      monthTotals.values.fold<double>(0, (sum, value) => sum + value);

  double get maxMonthTotal => monthTotals.values.fold<double>(
    0,
    (max, value) => value > max ? value : max,
  );
}

class _StatsSumYearSummaryBuilder {
  _StatsSumYearSummaryBuilder(this.year);

  final int year;
  final monthTotals = <int, double>{};
  double closingAmount = 0;

  StatsSumYearSummary build() => StatsSumYearSummary(
    year: year,
    monthTotals: Map.unmodifiable(monthTotals),
    closingAmount: closingAmount,
  );
}

class _StatsDatedRecord {
  const _StatsDatedRecord(this.record, this.originalDate);

  final TransactionRecord record;
  final _StatsDateParts originalDate;
}

class _StatsDateParts {
  const _StatsDateParts(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  int get dateKey => year * 10000 + month * 100 + day;
  int get monthKey => year * 100 + month;
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
