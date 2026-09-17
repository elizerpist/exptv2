import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  DashboardLedgerEntry entry({
    required String id,
    required String direction,
    required int amount,
    required LocalDate date,
  }) => DashboardLedgerEntry(
    id: id,
    partnerId: 'partner',
    categoryId: 'category',
    direction: direction,
    amountMinor: amount,
    bookedLocalEpochDay: date.epochDay,
    bookedLocalTimeMinutes: 0,
  );

  test('FTR-04 retains full-year monthly income and expense independently', () {
    final aggregates = MindYearHeatmapMonthlyAggregates.fromDirectionalEntries(
      year: 2027,
      incomeEntries: <DashboardLedgerEntry>[
        entry(
          id: 'income-january',
          direction: 'income',
          amount: 10000,
          date: const LocalDate(year: 2027, month: 1, day: 4),
        ),
        entry(
          id: 'income-february',
          direction: 'income',
          amount: 20000,
          date: const LocalDate(year: 2027, month: 2, day: 4),
        ),
      ],
      expenseEntries: <DashboardLedgerEntry>[
        entry(
          id: 'expense-january-a',
          direction: 'expense',
          amount: 3000,
          date: const LocalDate(year: 2027, month: 1, day: 10),
        ),
        entry(
          id: 'expense-january-b',
          direction: 'expense',
          amount: 2000,
          date: const LocalDate(year: 2027, month: 1, day: 14),
        ),
      ],
    );

    expect(aggregates.incomeForMonth(1), 10000);
    expect(aggregates.expenseForMonth(1), 5000);
    expect(aggregates.netForMonth(1), 5000);
    expect(aggregates.incomeForMonth(2), 20000);
    expect(aggregates.expenseForMonth(2), 0);
    expect(aggregates.netForMonth(2), 20000);
    expect(aggregates.incomeForMonth(12), 0);
  });

  test(
    'FTR-04 uses the query-independent aggregate Budget cells, not a focused membership seed',
    () {
      PreparedBudgetLimitDirectionBank bankFor(Map<int, int> actualByMonth) =>
          PreparedBudgetLimitDirectionBank(
            orderedCategoryIds: const <String>[],
            cells: List<PreparedBudgetLimitCell>.generate(
              // SUM + YEAR + the twelve months for the one-year snapshot.
              14,
              (slice) => PreparedBudgetLimitCell(
                actualScaled100: switch (slice) {
                  2 => actualByMonth[1] ?? 0,
                  3 => actualByMonth[2] ?? 0,
                  _ => 0,
                },
                limitScaled100: null,
              ),
              growable: false,
            ),
          );
      final snapshot = PreparedBudgetLimitSnapshot(
        coreRevision: 7,
        yearWindowStart: 2027,
        yearWindowEndInclusive: 2027,
        incomeBank: bankFor(<int, int>{1: 10000, 2: 20000}),
        expenseBank: bankFor(<int, int>{1: 3000, 2: 5000}),
      );

      final aggregates =
          MindYearHeatmapMonthlyAggregateBank.fromPreparedBudgetSnapshot(
            snapshot,
          ).forYear(2027);

      expect(aggregates.incomeForMonth(1), 10000);
      expect(aggregates.expenseForMonth(1), 3000);
      expect(aggregates.netForMonth(1), 7000);
      expect(aggregates.incomeForMonth(2), 20000);
      expect(aggregates.expenseForMonth(2), 5000);
      expect(aggregates.netForMonth(2), 15000);
    },
  );
}
