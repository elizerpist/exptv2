import 'package:exptv2/features/transactions/data/limit_manager.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildBars keeps monthly yearly and all time category limits separate',
    () {
      final category = categoryFixture(6, 'Food', TransactionType.expense);
      final transactions = [
        transactionFixture(1, '2026.05.03', -100, 6),
        transactionFixture(2, '2026.04.03', -200, 6),
        transactionFixture(3, '2025.05.03', -300, 6),
        transactionFixture(4, '2026.05.04', 999, 5),
      ];
      final limits = [
        limitFixture(
          window: LimitWindow.monthly,
          periodKey: '2026-05',
          amount: 150,
        ),
        limitFixture(
          window: LimitWindow.yearly,
          periodKey: '2026',
          amount: 1000,
        ),
        limitFixture(
          window: LimitWindow.allTime,
          periodKey: 'all',
          amount: 2000,
        ),
      ];

      final monthly = LimitManager.buildBars(
        categories: [category],
        transactions: transactions,
        limits: limits,
        activeType: TransactionType.expense,
        summaryWindow: SummaryWindow.monthly,
        referenceDate: DateTime(2026, 5, 17),
      ).single;
      final yearly = LimitManager.buildBars(
        categories: [category],
        transactions: transactions,
        limits: limits,
        activeType: TransactionType.expense,
        summaryWindow: SummaryWindow.yearly,
        referenceDate: DateTime(2026, 5, 17),
      ).single;
      final allTime = LimitManager.buildBars(
        categories: [category],
        transactions: transactions,
        limits: limits,
        activeType: TransactionType.expense,
        summaryWindow: SummaryWindow.allTime,
        referenceDate: DateTime(2026, 5, 17),
      ).single;

      expect(monthly.periodKey, '2026-05');
      expect(monthly.spent, 100);
      expect(monthly.limitAmount, 150);
      expect(yearly.periodKey, '2026');
      expect(yearly.spent, 300);
      expect(yearly.limitAmount, 1000);
      expect(allTime.periodKey, 'all');
      expect(allTime.spent, 600);
      expect(allTime.limitAmount, 2000);
    },
  );

  test('progressColor follows the original white orange red thresholds', () {
    expect(LimitManager.progressColor(79, 100), Colors.white);
    expect(LimitManager.progressColor(80, 100), const Color(0xffff8800));
    expect(LimitManager.progressColor(100, 100), const Color(0xffff4444));
  });
}

TransactionCategory categoryFixture(int id, String name, TransactionType type) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': name,
    'type': type.hungarianValue,
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}

TransactionRecord transactionFixture(
  int id,
  String date,
  double amount,
  int categoryId,
) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '12:00',
    'merchant': 'Merchant',
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}

CategoryLimit limitFixture({
  required LimitWindow window,
  required String periodKey,
  required double amount,
}) {
  return CategoryLimit(
    id: 1,
    targetType: LimitTargetType.category,
    targetId: 6,
    transactionType: 'expense',
    window: window,
    periodKey: periodKey,
    hasLimit: true,
    limitAmount: amount,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  );
}
