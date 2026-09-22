import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense|filtered',
    indexGeneration: 4,
    coreRevision: 9,
  );

  test(
    'P2-SUM/YEAR RED: resident directional membership produces exact annual and twelve-month paired totals',
    () {
      final income = <DashboardLedgerEntry>[
        _entry('income-2024', 'income', 100000, 2024, 2, 1),
        _entry('income-2025', 'income', 200000, 2025, 7, 12),
        _entry('income-2026', 'income', 300000, 2026, 1, 5),
      ];
      final expense = <DashboardLedgerEntry>[
        _entry('expense-2025', 'expense', 200000, 2025, 7, 20),
        _entry('expense-2026', 'expense', 80000, 2026, 2, 4),
      ];

      final sum = DashboardBalancePrimaryProjection.build(
        identity: identity,
        timeScope: const AllTimeScope(),
        incomeEntries: income,
        expenseEntries: expense,
      );
      expect(sum.mode, DashboardBalancePrimaryMode.sum);
      expect(sum.periodPairs.map((pair) => pair.value), <int>[
        2024,
        2025,
        2026,
      ]);
      expect(sum.periodPairs.map((pair) => pair.incomeMinor), <int>[
        100000,
        200000,
        300000,
      ]);
      expect(sum.periodPairs.map((pair) => pair.expenseMinor), <int>[
        0,
        200000,
        80000,
      ]);
      expect(sum.incomeTotalMinor, 600000);
      expect(sum.expenseTotalMinor, 280000);
      expect(sum.netTotalMinor, 320000);

      final year = DashboardBalancePrimaryProjection.build(
        identity: identity,
        timeScope: const YearScope(2026),
        incomeEntries: income,
        expenseEntries: expense,
      );
      expect(year.mode, DashboardBalancePrimaryMode.year);
      expect(year.periodPairs, hasLength(12));
      expect(year.periodPairs.first.value, 1);
      expect(year.periodPairs[1].value, 2);
      expect(year.periodPairs.first.incomeMinor, 300000);
      expect(year.periodPairs[1].expenseMinor, 80000);
      expect(year.incomeTotalMinor, 300000);
      expect(year.expenseTotalMinor, 80000);
    },
  );

  test(
    'P2-MONTH-REBASE RED: daily Income and Expense steps begin at month-local zero and end at exact metrics',
    () {
      final projection = DashboardBalancePrimaryProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        incomeEntries: <DashboardLedgerEntry>[
          _entry('income-june', 'income', 900000, 2026, 6, 30),
          _entry('income-july-3', 'income', 700000, 2026, 7, 3),
          _entry('income-july-18', 'income', 7000, 2026, 7, 18),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('expense-june', 'expense', 400000, 2026, 6, 29),
          _entry('expense-july-2', 'expense', 20000, 2026, 7, 2),
          _entry('expense-july-18', 'expense', 30000, 2026, 7, 18),
        ],
      );

      expect(projection.mode, DashboardBalancePrimaryMode.month);
      expect(projection.dailyPoints, hasLength(31));
      expect(projection.dailyPoints.first.incomeMinor, 0);
      expect(projection.dailyPoints.first.expenseMinor, 0);
      expect(projection.dailyPoints[1].expenseMinor, 20000);
      expect(projection.dailyPoints[2].incomeMinor, 700000);
      expect(projection.dailyPoints[16].incomeMinor, 700000);
      expect(projection.dailyPoints[17].incomeMinor, 707000);
      expect(projection.dailyPoints[17].expenseMinor, 50000);
      expect(projection.dailyPoints.last.incomeMinor, 707000);
      expect(projection.dailyPoints.last.expenseMinor, 50000);
      expect(projection.incomeTotalMinor, 707000);
      expect(projection.expenseTotalMinor, 50000);
      expect(projection.netTotalMinor, 657000);
    },
  );

  test('P2-DAY-OUT-OF-SCOPE RED: Day has no Balance chart payload', () {
    final projection = DashboardBalancePrimaryProjection.build(
      identity: identity,
      timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 18)),
      incomeEntries: const <DashboardLedgerEntry>[],
      expenseEntries: const <DashboardLedgerEntry>[],
    );

    expect(projection.mode, DashboardBalancePrimaryMode.unsupportedDay);
    expect(projection.periodPairs, isEmpty);
    expect(projection.dailyPoints, isEmpty);
  });
}

DashboardLedgerEntry _entry(
  String id,
  String direction,
  int amount,
  int year,
  int month,
  int day,
) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  categoryId: 'category-$direction',
  direction: direction,
  amountMinor: amount,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: 12 * 60,
);
