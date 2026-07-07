import 'package:flutter/material.dart';

import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';

enum StatsRenderMode { categoryScope, closing, heatmap }

extension StatsRenderModeX on StatsRenderMode {
  String get title => switch (this) {
    StatsRenderMode.categoryScope => 'Kategória scope',
    StatsRenderMode.closing => 'Hózárás',
    StatsRenderMode.heatmap => 'Hőtérkép',
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
    required this.totalThresholdHitDays,
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
  final int totalThresholdHitDays;

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
    DateTime? today,
  }) {
    final activeCategoryIds = categories
        .where((category) => category.normalizedType == activeType)
        .map((category) => category.transactionCategoryID)
        .toSet();
    final scopedCategoryIds = selectedCategoryIds
        .where(activeCategoryIds.contains)
        .toSet();
    final allActiveCategoriesSelected = scopedCategoryIds.isEmpty;
    final categoriesById = <int, TransactionCategory>{
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    final normalizedToday = _dateOnly(today ?? DateTime.now());
    final byDate = <DateTime, List<TransactionRecord>>{};
    for (final record in transactions) {
      final parsed = _parseDate(record.normalizedDate);
      if (parsed == null || parsed.year != year) continue;
      final matchesType = _recordType(record) == activeType;
      if (!matchesType) continue;
      byDate
          .putIfAbsent(_dateOnly(parsed), () => <TransactionRecord>[])
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

      for (var day = 1; day <= daysInMonth; day += 1) {
        final date = DateTime(year, month, day);
        final records = byDate[_dateOnly(date)] ?? const <TransactionRecord>[];
        transactionCount += records.length;
        var activeAmount = 0.0;
        var scopedAmount = 0.0;
        final categoryAmounts = <int, double>{};

        for (final record in records) {
          final amount = record.amount.abs();
          activeAmount += amount;
          final categoryId = record.transactionCategoryID;
          final inScope =
              allActiveCategoriesSelected ||
              (categoryId != null && scopedCategoryIds.contains(categoryId));
          if (!inScope) continue;
          scopedAmount += amount;
          if (categoryId != null) {
            categoryAmounts.update(
              categoryId,
              (value) => value + amount,
              ifAbsent: () => amount,
            );
          }
        }

        final dominantCategoryId = _dominantCategoryId(categoryAmounts);
        final meetsThreshold =
            scopedAmount >= thresholdValue && scopedAmount > 0;
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

      summaryTotal += monthTotal;
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
      totalThresholdHitDays: totalThresholdHitDays,
    );
  }

  static String _headerLabel(StatsRenderMode mode) => switch (mode) {
    StatsRenderMode.categoryScope => 'SCOPE TREND',
    StatsRenderMode.closing => 'HÓZÁRÁS',
    StatsRenderMode.heatmap => 'HEATMAP',
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
      StatsRenderMode.categoryScope => _categoryScopeHeader(
        months: months,
        scopeLabel: scopeLabel,
        totalThresholdHitDays: totalThresholdHitDays,
      ),
      StatsRenderMode.closing =>
        '${_worseningMonthCount(months, activeType)} romló hónap idén',
      StatsRenderMode.heatmap =>
        '$totalThresholdHitDays forró nap ${_compactThreshold(thresholdValue)} felett',
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

  static int _worseningMonthCount(
    List<StatsMonthData> months,
    TransactionType activeType,
  ) {
    var count = 0;
    double? previous;
    for (final month in months) {
      if (!month.hasTransactions) continue;
      final current = month.activeTotal;
      final previousValue = previous;
      if (previousValue != null) {
        final worse = activeType == TransactionType.expense
            ? current > previousValue
            : current < previousValue;
        if (worse) count += 1;
      }
      previous = current;
    }
    return count;
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

  static String _compactThreshold(double value) {
    if (value >= 1000 && value % 1000 == 0) {
      return '${(value / 1000).round()}k';
    }
    return formatHuf(value).replaceAll(' Ft', '');
  }

  static TransactionType _recordType(TransactionRecord record) =>
      record.amount > 0 ? TransactionType.income : TransactionType.expense;

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
