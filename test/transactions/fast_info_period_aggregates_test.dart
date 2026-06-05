import 'package:exptv2/features/transactions/data/fast_info_period_aggregates.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric_snapshot.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses calendar and adjacent rolling period boundaries', () {
    final data = FastInfoPeriodAggregates(
      snapshot: FastInfoMetricSnapshot(
        now: DateTime(2026, 3, 31, 12),
        balance: 0,
        transactions: [
          _expense(1, '2026.03.31', 1000),
          _expense(2, '2026.03.30', 2000),
          _expense(3, '2026.03.25', 3000),
          _expense(4, '2026.02.28', 4000),
          _expense(5, '2026.02.25', 5000),
        ],
      ),
    );

    expect(data.todayExpense, 1000);
    expect(data.currentMonthExpense, 6000);
    expect(data.previousMonthSameDayExpense, 9000);
    expect(data.rolling30Expense, 6000);
    expect(data.previousRolling30Expense, 9000);
    expect(data.currentMonthDailySeries, hasLength(31));
    expect(data.currentMonthDailySeries[24], 3000);
    expect(data.currentMonthDailySeries[30], 1000);
    expect(data.previousMonthDailySeries, hasLength(28));
    expect(data.previousMonthDailySeries[24], 5000);
  });

  test('returns seven Monday-Sunday bars and marks future days', () {
    final data = FastInfoPeriodAggregates(
      snapshot: FastInfoMetricSnapshot(
        now: DateTime(2026, 4, 1, 12),
        balance: 0,
        transactions: [
          _expense(1, '2026.03.30', 100),
          _expense(2, '2026.03.31', 200),
          _expense(3, '2026.04.01', 300),
        ],
      ),
    );

    expect(data.currentWeekBars.map((bar) => bar.value).toList(), [
      100,
      200,
      300,
      0,
      0,
      0,
      0,
    ]);
    expect(data.currentWeekBars.map((bar) => bar.isFuture).toList(), [
      false,
      false,
      false,
      true,
      true,
      true,
      true,
    ]);
  });

  test('variable expense totals exclude activated recurring expenses', () {
    final data = FastInfoPeriodAggregates(
      snapshot: FastInfoMetricSnapshot(
        now: DateTime(2026, 6, 10, 12),
        balance: 0,
        transactions: [
          _expense(1, '2026.06.10', 5000),
          _expense(2, '2026.06.10', 200000, recurringTransactionId: 77),
        ],
      ),
    );

    expect(data.todayExpense, 205000);
    expect(data.todayVariableExpense, 5000);
    expect(
      data.variableExpenseBetween(data.currentMonthStart, data.tomorrow),
      5000,
    );
  });
}

TransactionRecord _expense(
  int id,
  String date,
  double amount, {
  int? recurringTransactionId,
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '12:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Expense $id',
    amount: -amount,
    userAssignedName: null,
    transactionCategoryID: 1,
    recurringTransactionId: recurringTransactionId,
  );
}
