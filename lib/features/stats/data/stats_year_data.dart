import 'package:flutter/material.dart';

import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import 'stats_scope_model.dart';

enum StatsRenderMode { common }

enum StatsSummaryScope { allTime, yearly, monthly }

extension StatsRenderModeX on StatsRenderMode {
  String get title => switch (this) {
    StatsRenderMode.common => 'Common',
  };
}

class StatsYearData {
  const StatsYearData({
    required this.year,
    required this.activeType,
    required this.mode,
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
  });

  final int year;
  final TransactionType activeType;
  final StatsRenderMode mode;
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

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
    final totalCategoryTotals = <int, double>{};
    final vendorTotals = <String, _StatsVendorAccumulator>{};
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
      final matchesType = _recordType(record) == activeType;
      if (!matchesType) continue;
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
    final months = <StatsMonthData>[];
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
        final categoryAmounts = <int, double>{};

        for (final record in records) {
          final amount = record.amount.abs();
          if (thresholdValue > 0 && amount < thresholdValue) continue;
          activeAmount += amount;
          final categoryId = record.transactionCategoryID;
          final inScope = scopeSelection.includesCategory(categoryId);
          if (!inScope) continue;
          scopedAmount += amount;
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
        final intensity = thresholdValue <= 0
            ? 0.0
            : (scopedAmount / thresholdValue).clamp(0.0, 1.0).toDouble();
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
            meetsThreshold: meetsThreshold,
            heatmapIntensity: intensity,
            hasActiveTypeActivity: activeAmount > 0,
            dominantCategoryId: dominantCategoryId,
            dominantCategoryColor: _categoryColor(
              dominantCategoryId,
              categoriesById,
            ),
            isToday: _dateOnly(date) == normalizedToday,
          ),
        );
      }

      summaryTotal += scopeTotal;
      months.add(
        StatsMonthData(
          year: year,
          month: month,
          name: monthNames[index],
          weekdayLabels: weekdayLabels,
          leadingBlankDays: firstDay.weekday - 1,
          days: days,
          activeTotal: monthTotal,
          scopeTotal: scopeTotal,
          closingAmount: monthTotal,
          scopeCategoryTotals: Map.unmodifiable(scopeCategoryTotals),
          thresholdHitDays: thresholdHitDays,
          hotDays: hotDays,
          transactionCount: transactionCount,
        ),
      );
    }

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
    return StatsYearData(
      year: year,
      activeType: activeType,
      mode: mode,
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
  final Map<int, double> scopeCategoryTotals;
  final int thresholdHitDays;
  final int hotDays;
  final int transactionCount;

  bool get hasTransactions => transactionCount > 0;
}

class StatsDayData {
  const StatsDayData({
    required this.date,
    required this.day,
    required this.activeAmount,
    required this.scopeAmount,
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
  final bool meetsThreshold;
  final double heatmapIntensity;
  final bool hasActiveTypeActivity;
  final int? dominantCategoryId;
  final Color dominantCategoryColor;
  final bool isToday;
}
