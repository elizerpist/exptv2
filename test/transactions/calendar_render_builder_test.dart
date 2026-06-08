import 'package:exptv2/features/transactions/data/calendar_render_builder.dart';
import 'package:exptv2/features/transactions/models/calendar_menu_mode.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calendar menu modes keep compact visual options', () {
    expect(CalendarMenuMode.values, const [
      CalendarMenuMode.category,
      CalendarMenuMode.summary,
      CalendarMenuMode.heatmap,
    ]);
    expect(CalendarMenuMode.category.title, 'Domináns kategória');
    expect(CalendarMenuMode.summary.title, 'Összefoglaló');
    expect(CalendarMenuMode.heatmap.title, 'Hőtérkép');
  });

  test('render builder creates 12 Monday-first month grids', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: const [],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
    );

    expect(data.year, 2026);
    expect(data.months.length, 12);
    expect(data.months.first.month, 1);
    expect(data.months.first.name, 'January');
    expect(data.months.first.weekdayLabels, const [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ]);
    expect(data.months.first.days.length, 31);
    expect(data.months.first.leadingBlankDays, 3);
    expect(data.thresholdRange.min, 0);
    expect(data.thresholdRange.max, 1000);
  });

  test('render builder calculates threshold, summary, and heatmap values', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: [
        record(id: 1, date: '2026.05.04', amount: -5000, categoryId: 6),
        record(id: 2, date: '2026.05.04', amount: 2000, categoryId: 5),
        record(id: 3, date: '2026.05.08', amount: -15000, categoryId: 7),
      ],
      categories: [
        category(id: 6, colorSlot: 7),
        category(id: 7, colorSlot: 1),
      ],
      thresholdValue: 10000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 20000,
      today: DateTime(2026, 5, 4),
    );

    final may = data.months[4];
    expect(data.thresholdRange.min, 5000);
    expect(data.thresholdRange.max, 15000);
    expect(may.income, 2000);
    expect(may.expense, 20000);
    expect(may.balance, -18000);
    expect(may.transactionCount, 3);

    final may4 = may.days[3];
    expect(may4.hasIncome, isTrue);
    expect(may4.hasExpense, isTrue);
    expect(may4.meetsThreshold, isFalse);
    expect(may4.heatmapPercentage, 0.25);
    expect(may4.isToday, isTrue);

    final may8 = may.days[7];
    expect(may8.meetsThreshold, isTrue);
    expect(may8.heatmapPercentage, 0.75);
    expect(may8.dominantCategoryId, 7);
    expect(may8.dominantCategoryColor, const Color(0xFFF97316));
  });

  test('custom threshold min and max override calculated expense range', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: [
        record(id: 1, date: '2026.05.04', amount: -5000, categoryId: 6),
      ],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
      customThresholdMin: 100,
      customThresholdMax: 9000,
    );

    expect(data.thresholdRange.min, 100);
    expect(data.thresholdRange.max, 9000);
  });
}

TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
}) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '12:00',
    'merchant': 'Shop',
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}

TransactionCategory category({required int id, required int colorSlot}) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': 'Category $id',
    'type': 'kiadás',
    'colorSlot': colorSlot,
    'iconSlot': 0,
    'backgroundColor': '#64748b',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}
