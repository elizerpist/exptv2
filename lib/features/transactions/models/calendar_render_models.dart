import 'package:flutter/material.dart';

class CalendarThresholdRange {
  const CalendarThresholdRange({required this.min, required this.max});

  final double min;
  final double max;
}

class CalendarYearRenderData {
  const CalendarYearRenderData({
    required this.year,
    required this.months,
    required this.thresholdRange,
  });

  final int year;
  final List<CalendarMonthRenderData> months;
  final CalendarThresholdRange thresholdRange;
}

class CalendarMonthRenderData {
  const CalendarMonthRenderData({
    required this.year,
    required this.month,
    required this.name,
    required this.weekdayLabels,
    required this.leadingBlankDays,
    required this.days,
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
  });

  final int year;
  final int month;
  final String name;
  final List<String> weekdayLabels;
  final int leadingBlankDays;
  final List<CalendarDayRenderData> days;
  final double income;
  final double expense;
  final double balance;
  final int transactionCount;

  bool get hasTransactions => transactionCount > 0;
}

class CalendarDayRenderData {
  const CalendarDayRenderData({
    required this.date,
    required this.day,
    required this.income,
    required this.expense,
    required this.hasIncome,
    required this.hasExpense,
    required this.meetsThreshold,
    required this.heatmapPercentage,
    required this.dominantCategoryId,
    required this.dominantCategoryColor,
    required this.isToday,
  });

  final DateTime date;
  final int day;
  final double income;
  final double expense;
  final bool hasIncome;
  final bool hasExpense;
  final bool meetsThreshold;
  final double heatmapPercentage;
  final int? dominantCategoryId;
  final Color dominantCategoryColor;
  final bool isToday;
}
