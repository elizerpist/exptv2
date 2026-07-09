import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android seed spans five years and bumps demo seed version', () {
    final source = File(
      'android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt',
    ).readAsStringSync();

    expect(source, contains('const val version = 2026070901'));
    expect(source, contains('private const val seedStartYear = 2021'));
    expect(source, contains('private const val seedStartMonth = 6'));
    expect(source, contains('private const val seedMonthCount = 61'));
    expect(source, contains('while (monthOffset < seedMonthCount)'));
    expect(source, contains('if (year == 2026 && month == 6)'));
  });

  test('android seed contains the 2025 fast-food behavior sample', () {
    final source = File(
      'android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt',
    ).readAsStringSync();

    expect(
      source,
      contains('TransactionCategoryEntity(22, "Gyorsétterem", "kiadás"'),
    );
    expect(
      source,
      contains('buildFastFoodTransactions(year, month, days, idBase, random)'),
    );
    expect(source, contains('if (year != 2025) return emptyList()'));
    expect(source, contains('FastFoodPeriod(1..4, 12, 5, 4300, 5700)'));
    expect(source, contains('FastFoodPeriod(5..8, 5, 4, 8500, 13500)'));
    expect(source, contains('FastFoodPeriod(9..12, 2, 3, 1800, 4200)'));
    expect(source, contains('"McDonald\'s"'));
    expect(source, contains('"Burger King"'));
    expect(source, contains('"KFC"'));
    expect(source, contains('"Subway"'));
  });
}
