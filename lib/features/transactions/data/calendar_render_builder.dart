import 'package:flutter/material.dart';

import '../models/calendar_render_models.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class CalendarRenderBuilder {
  const CalendarRenderBuilder._();

  static const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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

  static CalendarYearRenderData buildYear({
    required int year,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required double thresholdValue,
    required double heatmapMinValue,
    required double heatmapCurrentValue,
    DateTime? today,
    double? customThresholdMin,
    double? customThresholdMax,
  }) {
    final todayValue = today ?? DateTime.now();
    final normalizedToday = _dateOnly(todayValue);
    final byDate = <DateTime, List<TransactionRecord>>{};
    for (final record in transactions) {
      final parsed = _parseDate(record.normalizedDate);
      if (parsed == null) continue;
      final date = _dateOnly(parsed);
      byDate.putIfAbsent(date, () => []).add(record);
    }

    final dailyExpenses = byDate.values
        .map(
          (records) => records
              .where((record) => record.amount < 0)
              .fold<double>(0, (sum, record) => sum + record.amount.abs()),
        )
        .where((value) => value > 0)
        .toList();
    final calculatedMin = dailyExpenses.isEmpty
        ? 0.0
        : dailyExpenses.reduce((a, b) => a < b ? a : b);
    final calculatedMax = dailyExpenses.isEmpty
        ? 1000.0
        : dailyExpenses.reduce((a, b) => a > b ? a : b);
    final thresholdMin = customThresholdMin ?? calculatedMin;
    final thresholdMax = customThresholdMax ?? calculatedMax;

    final categoryColors = <int, Color>{
      for (final category in categories)
        category.transactionCategoryID: category.slotColor,
    };

    return CalendarYearRenderData(
      year: year,
      thresholdRange: CalendarThresholdRange(
        min: thresholdMin,
        max: thresholdMax,
      ),
      months: List.generate(12, (index) {
        final month = index + 1;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final firstDay = DateTime(year, month, 1);
        final leadingBlankDays = firstDay.weekday - 1;
        var monthIncome = 0.0;
        var monthExpense = 0.0;
        var transactionCount = 0;
        final days = <CalendarDayRenderData>[];

        for (var day = 1; day <= daysInMonth; day += 1) {
          final date = DateTime(year, month, day);
          final dateKey = _dateOnly(date);
          final records = byDate.containsKey(dateKey)
              ? byDate[dateKey]!
              : const <TransactionRecord>[];
          transactionCount += records.length;
          var income = 0.0;
          var expense = 0.0;
          final expenseByCategory = <int, double>{};
          for (final record in records) {
            if (record.amount > 0) {
              income += record.amount;
            } else if (record.amount < 0) {
              final absolute = record.amount.abs();
              expense += absolute;
              expenseByCategory.update(
                record.transactionCategoryID,
                (value) => value + absolute,
                ifAbsent: () => absolute,
              );
            }
          }
          monthIncome += income;
          monthExpense += expense;
          final dominantCategoryId = _dominantCategoryId(expenseByCategory);
          days.add(
            CalendarDayRenderData(
              date: date,
              day: day,
              income: income,
              expense: expense,
              hasIncome: income > 0,
              hasExpense: expense > 0,
              meetsThreshold: expense >= thresholdValue,
              heatmapPercentage: _heatmapPercentage(
                expense,
                heatmapMinValue,
                heatmapCurrentValue,
              ),
              dominantCategoryId: dominantCategoryId,
              dominantCategoryColor: _categoryColor(
                dominantCategoryId,
                categoryColors,
              ),
              isToday: _dateOnly(date) == normalizedToday,
            ),
          );
        }

        return CalendarMonthRenderData(
          year: year,
          month: month,
          name: monthNames[index],
          weekdayLabels: weekdayLabels,
          leadingBlankDays: leadingBlankDays,
          days: days,
          income: monthIncome,
          expense: monthExpense,
          balance: monthIncome - monthExpense,
          transactionCount: transactionCount,
        );
      }),
    );
  }

  static DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final compact = value.replaceAll('.', '-');
    return DateTime.tryParse(compact);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static double _heatmapPercentage(
    double expense,
    double minValue,
    double currentValue,
  ) {
    if (expense <= minValue || currentValue <= minValue) return 0;
    final percentage = (expense - minValue) / (currentValue - minValue);
    return percentage.clamp(0, 1).toDouble();
  }

  static int? _dominantCategoryId(Map<int, double> expenseByCategory) {
    int? id;
    var amount = -1.0;
    for (final entry in expenseByCategory.entries) {
      if (entry.value > amount) {
        id = entry.key;
        amount = entry.value;
      }
    }
    return id;
  }

  static Color _categoryColor(int? id, Map<int, Color> categoryColors) {
    if (id == null) return const Color(0xFF9CA3AF);
    final explicitColor = categoryColors[id];
    if (explicitColor != null) return explicitColor;
    return switch (id) {
      1 => const Color(0xFFEF4444),
      2 => const Color(0xFFF97316),
      4 => const Color(0xFF22C55E),
      6 => const Color(0xFFF472B6),
      11 => const Color(0xFF38BDF8),
      15 => const Color(0xFF64748B),
      21 => const Color(0xFFEC4899),
      _ => const Color(0xFF9CA3AF),
    };
  }
}
