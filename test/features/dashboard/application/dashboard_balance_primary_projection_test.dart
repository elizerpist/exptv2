import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
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

  test(
    'L3-RED: Day keeps scope-local Cashflow totals although its large chart is unsupported',
    () {
      final projection = DashboardBalancePrimaryProjection.build(
        identity: identity,
        timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 18)),
        incomeEntries: <DashboardLedgerEntry>[
          _entry('income-prior', 'income', 100000, 2026, 7, 17),
          _entry('income-day', 'income', 7000, 2026, 7, 18),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('expense-day', 'expense', 2500, 2026, 7, 18),
          _entry('expense-later', 'expense', 8000, 2026, 7, 19),
        ],
      );

      expect(projection.mode, DashboardBalancePrimaryMode.unsupportedDay);
      expect(projection.incomeTotalMinor, 7000);
      expect(projection.expenseTotalMinor, 2500);
      expect(projection.netTotalMinor, 4500);
    },
  );

  test(
    'L4-RED: linked latest transactions stay in scope and order both directions',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: <DashboardLedgerEntry>[
          _entry('income-july', 'income', 7000, 2026, 7, 20),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('expense-july-late', 'expense', 5000, 2026, 7, 28),
          _entry('expense-august', 'expense', 9000, 2026, 8, 1),
        ],
      );

      expect(
        linked.latestTransactions.map((transaction) => transaction.entryId),
        <String>['expense-july-late', 'income-july'],
      );
      expect(linked.cashflow.incomeTotalMinor, 7000);
      expect(linked.cashflow.expenseTotalMinor, 5000);
    },
  );

  test(
    'LATEST-VISUAL-RED: latest projection retains admitted category visual metadata',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            'latest-with-visuals',
            'expense',
            -5000,
            2026,
            7,
            28,
            categoryColorId: 'color_07',
            categoryIconId: 'icon_17',
          ),
        ],
      );

      final latest = linked.latestTransactions.single;
      expect(latest.categoryColorId, 'color_07');
      expect(latest.categoryIconId, 'icon_17');
    },
  );

  test(
    'LATEST-TIME-RED: latest projection retains the authoritative local minutes',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: const <DashboardLedgerEntry>[],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            'latest-local-time',
            'expense',
            -5000,
            2026,
            7,
            28,
            localTimeMinutes: 8 * 60 + 7,
          ),
        ],
      );

      expect(linked.latestTransactions.single.localTimeMinutes, 8 * 60 + 7);
    },
  );

  test(
    'LATEST-TIME: a visible local-time change invalidates linked presentation even with fixed UTC ordering',
    () {
      DashboardBalanceLinkedPresentation build(int localMinutes) =>
          DashboardBalanceLinkedProjection.build(
            identity: identity,
            timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
            selectedDirection: LedgerDirection.expense,
            incomeEntries: const <DashboardLedgerEntry>[],
            expenseEntries: <DashboardLedgerEntry>[
              _entry(
                'fixed-utc-order',
                'expense',
                -5000,
                2026,
                7,
                28,
                localTimeMinutes: localMinutes,
                occurredAtUtcMs: 1722168000000,
              ),
            ],
          );

      final noon = build(12 * 60);
      final evening = build(18 * 60 + 7);
      expect(
        noon.latestTransactions.single.occurredOrder,
        evening.latestTransactions.single.occurredOrder,
      );
      expect(noon.presentationId, isNot(evening.presentationId));
    },
  );

  test(
    'L5-RED: linked top category ranks absolute amount on active direction only',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const YearScope(2026),
        selectedDirection: LedgerDirection.expense,
        incomeEntries: <DashboardLedgerEntry>[
          _entry(
            'income-larger',
            'income',
            50000,
            2026,
            7,
            1,
            categoryId: 'salary',
          ),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            'expense-food-first',
            'expense',
            -4000,
            2026,
            7,
            2,
            categoryId: 'food',
          ),
          _entry(
            'expense-food-second',
            'expense',
            -5000,
            2026,
            7,
            3,
            categoryId: 'food',
          ),
        ],
      );

      expect(linked.topCategories.single.id, 'food');
      expect(linked.topCategories.single.amountMinor, 9000);
      expect(linked.topCategories.single.direction, LedgerDirection.expense);
    },
  );

  test(
    'L6-RED: linked top partner ranks transaction count on active direction only',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const YearScope(2026),
        selectedDirection: LedgerDirection.income,
        incomeEntries: <DashboardLedgerEntry>[
          _entry(
            'recurring-1',
            'income',
            10,
            2026,
            1,
            1,
            partnerId: 'recurring',
          ),
          _entry(
            'recurring-2',
            'income',
            10,
            2026,
            2,
            1,
            partnerId: 'recurring',
          ),
          _entry(
            'recurring-3',
            'income',
            10,
            2026,
            3,
            1,
            partnerId: 'recurring',
          ),
          _entry('one-off', 'income', 99999, 2026, 4, 1, partnerId: 'one-off'),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            'expense-many',
            'expense',
            -10,
            2026,
            1,
            1,
            partnerId: 'expense-only',
          ),
          _entry(
            'expense-many-2',
            'expense',
            -10,
            2026,
            1,
            2,
            partnerId: 'expense-only',
          ),
          _entry(
            'expense-many-3',
            'expense',
            -10,
            2026,
            1,
            3,
            partnerId: 'expense-only',
          ),
          _entry(
            'expense-many-4',
            'expense',
            -10,
            2026,
            1,
            4,
            partnerId: 'expense-only',
          ),
        ],
      );

      expect(linked.topPartners.first.id, 'recurring');
      expect(linked.topPartners.first.transactionCount, 3);
      expect(linked.topPartners.first.direction, LedgerDirection.income);
    },
  );

  test(
    'MOVERS: linked payload publishes the bounded selected-direction projection',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const YearScope(2026),
        selectedDirection: LedgerDirection.expense,
        logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 24),
        incomeEntries: <DashboardLedgerEntry>[
          _entry(
            'income-only',
            'income',
            999999,
            2026,
            8,
            1,
            categoryId: 'income',
          ),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          for (var index = 0; index < 6; index += 1) ...<DashboardLedgerEntry>[
            _entry(
              'old-$index',
              'expense',
              -(100 + index),
              2025,
              8,
              1,
              categoryId: 'category-$index',
            ),
            _entry(
              'now-$index',
              'expense',
              -(1000 + index),
              2026,
              8,
              1,
              categoryId: 'category-$index',
            ),
          ],
        ],
      );

      expect(linked.categoryMovers, isNotNull);
      expect(linked.categoryMovers!.selectedDirection, LedgerDirection.expense);
      expect(linked.categoryMovers!.movers, hasLength(5));
      expect(
        linked.categoryMovers!.movers.map((mover) => mover.id),
        isNot(contains('income')),
      );
    },
  );

  test(
    'PC1/BM1 RED: one linked Balance payload carries dual-direction Closings and Momentum from resident histories',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: DayScope(const LocalDate(year: 2026, month: 9, day: 23)),
        selectedDirection: LedgerDirection.expense,
        logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 23),
        logicalAsOfLocalTimeMinutes: 14 * 60 + 37,
        incomeEntries: <DashboardLedgerEntry>[
          _entry('history', 'income', 1, 2026, 9, 21),
          _entry('today-income', 'income', 900, 2026, 9, 23),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('today-expense', 'expense', -400, 2026, 9, 23),
          _entry('yesterday-expense', 'expense', -100, 2026, 9, 22),
        ],
      );

      expect(linked.closings.buckets, hasLength(6));
      expect(linked.closings.buckets[3].netMinor, 500);
      expect(linked.momentum.isAvailable, isTrue);
      expect(linked.momentum.currentNetMinor, 500);
      expect(linked.momentum.previousNetMinor, -100);
      expect(linked.momentum.logicalAsOfLocalTimeMinutes, 14 * 60 + 37);
    },
  );

  test(
    'BX-OWNER RED: one linked presentation owns both-direction Retention and Stability once',
    () {
      final linked = DashboardBalanceLinkedProjection.build(
        identity: identity,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
        selectedDirection: LedgerDirection.expense,
        logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 23),
        incomeEntries: <DashboardLedgerEntry>[
          for (var month = 1; month <= 8; month += 1)
            _entry('income-$month', 'income', 1000 + month, 2026, month, 1),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry('expense-aug', 'expense', -400, 2026, 8, 2),
        ],
      );

      expect(linked.retention.selectedPeriod!.id, 'month:2026-8');
      expect(linked.retention.selectedPeriod!.incomeMinor, 1008);
      expect(linked.retention.selectedPeriod!.expenseMinor, 400);
      expect(linked.stability.observations, hasLength(8));
      expect(linked.stability.isAvailable, isTrue);
      expect(linked.retention.identity, linked.identity);
      expect(linked.stability.identity, linked.identity);
    },
  );
}

DashboardLedgerEntry _entry(
  String id,
  String direction,
  int amount,
  int year,
  int month,
  int day, {
  String? categoryId,
  String? partnerId,
  String? categoryDisplayName,
  String? partnerDisplayName,
  String? categoryColorId,
  String? categoryIconId,
  int localTimeMinutes = 12 * 60,
  int? occurredAtUtcMs,
}) => DashboardLedgerEntry(
  id: id,
  partnerId: partnerId ?? 'partner-$id',
  categoryId: categoryId ?? 'category-$direction',
  direction: direction,
  amountMinor: amount,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: localTimeMinutes,
  occurredAtUtcMs: occurredAtUtcMs,
  categoryDisplayName: categoryDisplayName,
  partnerDisplayName: partnerDisplayName,
  categoryColorId: categoryColorId,
  categoryIconId: categoryIconId,
);
