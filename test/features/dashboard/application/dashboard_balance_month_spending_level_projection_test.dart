import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_month_spending_level_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

const identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'test',
  indexGeneration: 1,
  coreRevision: 1,
);
DashboardLedgerEntry entry(int year, int month, int day, int amount) =>
    DashboardLedgerEntry(
      id: '$year-$month-$day-$amount',
      partnerId: 'p',
      categoryId: 'c',
      direction: 'expense',
      amountMinor: amount,
      bookedLocalEpochDay: LocalDate(
        year: year,
        month: month,
        day: day,
      ).epochDay,
      bookedLocalTimeMinutes: 0,
    );
void main() {
  DashboardBalanceMonthSpendingLevelPresentation build(
    List<DashboardLedgerEntry> expense, {
    int year = 2026,
    int month = 4,
    LocalDate now = const LocalDate(year: 2026, month: 5, day: 1),
    List<DashboardLedgerEntry>? income,
  }) => DashboardBalanceMonthSpendingLevelProjection.build(
    identity: identity,
    timeScope: MonthScope(YearMonth(year: year, month: month)),
    incomeEntries: income ?? [entry(2025, 1, 1, 0)],
    expenseEntries: expense,
    logicalAsOfDate: now,
  );
  test('median ignores outlier; ratios below equal above one', () {
    for (final amount in [50, 100, 150]) {
      final result = build([
        entry(2026, 1, 1, 100),
        entry(2026, 2, 1, 10000),
        entry(2026, 3, 1, -100),
        entry(2026, 4, 1, amount),
      ]);
      expect(result.referenceExpenseTimesTwo, 200);
      expect(result.ratio, amount / 100);
      expect(result.comparableMonthCount, 3);
    }
  });
  test(
    'current month uses same day prefixes and excludes later booked expenses',
    () {
      final result = build([
        for (var month = 1; month <= 4; month++) ...[
          entry(2026, month, 10, 100),
          entry(2026, month, 16, 900),
        ],
      ], now: const LocalDate(year: 2026, month: 4, day: 15));
      expect(result.currentExpenseMinor, 100);
      expect(result.referenceExpenseTimesTwo, 200);
      expect(result.ratio, 1);
    },
  );
  test('month length leap day and year rollover use calendar windows', () {
    final leap = build(
      [
        entry(2023, 12, 31, 100),
        entry(2024, 1, 31, 100),
        entry(2024, 2, 29, 100),
        entry(2024, 3, 30, 100),
      ],
      year: 2024,
      month: 3,
      income: [entry(2023, 1, 1, 0)],
      now: const LocalDate(year: 2024, month: 3, day: 31),
    );
    expect(leap.ratio, 1);
    final rollover = build(
      [
        entry(2025, 10, 1, 10),
        entry(2025, 11, 1, 20),
        entry(2025, 12, 1, 30),
        entry(2026, 1, 1, 40),
      ],
      month: 1,
      now: const LocalDate(year: 2026, month: 2, day: 1),
    );
    expect(rollover.referenceExpenseTimesTwo, 40);
    expect(rollover.ratio, 2);
  });
  test(
    'missing coverage partial oldest month zero and future are explicit',
    () {
      final missing = build([entry(2026, 2, 15, 10)], income: []);
      expect(missing.comparableMonthCount, 1);
      expect(
        missing.status,
        DashboardBalanceMonthSpendingLevelStatus.insufficientHistory,
      );
      expect(missing.ratio, isNull);
      final zero = build([]);
      expect(
        zero.status,
        DashboardBalanceMonthSpendingLevelStatus.zeroReference,
      );
      expect(zero.ratio, isNull);
      final future = build([], month: 6);
      expect(future.status, DashboardBalanceMonthSpendingLevelStatus.future);
      expect(future.ratio, isNull);
      final empty = build([], income: []);
      expect(empty.comparableMonthCount, 0);
    },
  );
  test('linked month owns comparison with complete resident membership', () {
    final linked = DashboardBalanceLinkedProjection.build(
      identity: identity,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 4)),
      selectedDirection: LedgerDirection.income,
      incomeEntries: [entry(2025, 1, 1, 1)],
      expenseEntries: [
        for (var month = 1; month <= 4; month++) entry(2026, month, 1, -100),
      ],
      logicalAsOfDate: const LocalDate(year: 2026, month: 5, day: 1),
    );
    expect(linked.spendingLevel?.ratio, 1);
    expect(linked.spendingLevel?.identity, linked.identity);
    expect(linked.cashflow.expenseTotalMinor, -100);
  });
}
