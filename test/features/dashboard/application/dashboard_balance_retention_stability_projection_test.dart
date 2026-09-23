import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'retention-stability-test',
    indexGeneration: 1,
    coreRevision: 1,
  );
  const asOf = LocalDate(year: 2026, month: 9, day: 23);

  DashboardBalanceRetentionPresentation retention({
    required LedgerTimeScope scope,
    Iterable<DashboardLedgerEntry> income = const <DashboardLedgerEntry>[],
    Iterable<DashboardLedgerEntry> expense = const <DashboardLedgerEntry>[],
  }) => DashboardBalanceRetentionProjection.build(
    identity: identity,
    timeScope: scope,
    incomeEntries: income,
    expenseEntries: expense,
  );

  DashboardBalanceStabilityPresentation stability({
    required LedgerTimeScope scope,
    Iterable<DashboardLedgerEntry> income = const <DashboardLedgerEntry>[],
    Iterable<DashboardLedgerEntry> expense = const <DashboardLedgerEntry>[],
  }) => DashboardBalanceStabilityProjection.build(
    identity: identity,
    timeScope: scope,
    logicalAsOfDate: asOf,
    incomeEntries: income,
    expenseEntries: expense,
  );

  group('Retention Ratio', () {
    test('RET-01 retains the exact signed basis-point formula', () {
      final surplus = retention(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('income', 1200000, 2026, 1, 1, LedgerDirection.income),
        ],
        expense: <DashboardLedgerEntry>[
          entry('expense', -900000, 2026, 1, 1, LedgerDirection.expense),
        ],
      ).selectedPeriod!;
      expect(surplus.retentionBasisPoints, 2500);
      expect(surplus.netMinor, 300000);
      expect(surplus.state, DashboardBalanceRetentionState.value);

      final deficit = retention(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('income', 1000000, 2026, 1, 1, LedgerDirection.income),
        ],
        expense: <DashboardLedgerEntry>[
          entry('expense', -1200000, 2026, 1, 1, LedgerDirection.expense),
        ],
      ).selectedPeriod!;
      expect(deficit.retentionBasisPoints, -2000);

      final allRetained = retention(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('income', 1000000, 2026, 1, 1, LedgerDirection.income),
        ],
      ).selectedPeriod!;
      expect(allRetained.retentionBasisPoints, 10000);
    });

    test('RET-02 distinguishes no income from no data without infinity', () {
      final noIncome = retention(
        scope: const AllTimeScope(),
        expense: <DashboardLedgerEntry>[
          entry('expense', -400, 2026, 1, 1, LedgerDirection.expense),
        ],
      ).selectedPeriod!;
      expect(noIncome.state, DashboardBalanceRetentionState.noIncome);
      expect(noIncome.retentionBasisPoints, isNull);

      final noData = retention(scope: const AllTimeScope()).selectedPeriod!;
      expect(noData.state, DashboardBalanceRetentionState.noData);
      expect(noData.retentionBasisPoints, isNull);
    });

    test(
      'RET-03 SUM is one all-history aggregate rather than annual children',
      () {
        final result = retention(
          scope: const AllTimeScope(),
          income: <DashboardLedgerEntry>[
            entry('income-2024', 100, 2024, 1, 1, LedgerDirection.income),
            entry('income-2026', 300, 2026, 1, 1, LedgerDirection.income),
          ],
          expense: <DashboardLedgerEntry>[
            entry('expense-2025', -100, 2025, 1, 1, LedgerDirection.expense),
          ],
        );
        expect(result.periods, hasLength(1));
        expect(result.selectedPeriod!.incomeMinor, 400);
        expect(result.selectedPeriod!.expenseMinor, 100);
        expect(result.selectedPeriod!.retentionBasisPoints, 7500);
      },
    );

    test(
      'RET-04 YEAR compares truthful year siblings and highlights selected',
      () {
        final result = retention(
          scope: const YearScope(2025),
          income: <DashboardLedgerEntry>[
            entry('income-2023', 100, 2023, 1, 1, LedgerDirection.income),
            entry('income-2025', 100, 2025, 1, 1, LedgerDirection.income),
            entry('income-2026', 100, 2026, 1, 1, LedgerDirection.income),
          ],
          expense: <DashboardLedgerEntry>[
            entry('expense-2023', -88, 2023, 1, 1, LedgerDirection.expense),
            entry('expense-2025', -79, 2025, 1, 1, LedgerDirection.expense),
            entry('expense-2026', -104, 2026, 1, 1, LedgerDirection.expense),
          ],
        );
        expect(result.periods.map((period) => period.label), <String>[
          '2023',
          '2024',
          '2025',
          '2026',
        ]);
        expect(
          result.periods.where((period) => period.selected).single.label,
          '2025',
        );
        expect(result.selectedPeriod!.retentionBasisPoints, 2100);
      },
    );

    test('RET-05/06 MONTH and DAY use continuous month siblings', () {
      final rows = <DashboardLedgerEntry>[
        entry('nov', 100, 2025, 11, 1, LedgerDirection.income),
        entry('dec', 100, 2025, 12, 1, LedgerDirection.income),
        entry('jan', 100, 2026, 1, 1, LedgerDirection.income),
        entry('feb', 100, 2026, 2, 1, LedgerDirection.income),
      ];
      final month = retention(
        scope: const MonthScope(YearMonth(year: 2026, month: 1)),
        income: rows,
      );
      final day = retention(
        scope: const DayScope(LocalDate(year: 2026, month: 1, day: 21)),
        income: rows,
      );
      expect(month.periods.map((period) => period.id), <String>[
        'month:2025-11',
        'month:2025-12',
        'month:2026-1',
        'month:2026-2',
      ]);
      expect(
        day.periods.map((period) => period.id),
        month.periods.map((period) => period.id),
      );
      expect(month.selectedPeriod!.id, 'month:2026-1');
      expect(day.selectedPeriod!.id, 'month:2026-1');
    });
  });

  group('Cashflow Stability', () {
    test(
      'STAB-01/02/03 calculates monthly net and robust median deviation once',
      () {
        final result = stability(
          scope: const AllTimeScope(),
          income: <DashboardLedgerEntry>[
            entry('jan', 90000, 2026, 1, 1, LedgerDirection.income),
            entry('feb', 110000, 2026, 2, 1, LedgerDirection.income),
            entry('mar', 85000, 2026, 3, 1, LedgerDirection.income),
            entry('apr', 105000, 2026, 4, 1, LedgerDirection.income),
            entry('may', 100000, 2026, 5, 1, LedgerDirection.income),
          ],
        );
        expect(result.isAvailable, isTrue);
        expect(result.observations.map((value) => value.netMinor), <int>[
          90000,
          110000,
          85000,
          105000,
          100000,
        ]);
        expect(result.medianNetTimesTwo, 200000);
        expect(result.typicalDeviationTimesTwo, 20000);
        expect(result.typicalBandLowerTimesTwo, 180000);
        expect(result.typicalBandUpperTimesTwo, 220000);
      },
    );

    test('STAB-04 has an exact doubled-minor rule for even samples', () {
      final result = stability(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('jan', 0, 2026, 1, 1, LedgerDirection.income),
          entry('feb', 100, 2026, 2, 1, LedgerDirection.income),
          entry('mar', 200, 2026, 3, 1, LedgerDirection.income),
          entry('apr', 300, 2026, 4, 1, LedgerDirection.income),
        ],
      );
      expect(result.medianNetTimesTwo, 300);
      expect(result.typicalDeviationTimesTwo, 200);
    });

    test('STAB-05 zero deviation is finite and remains available', () {
      final result = stability(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('jan', 100, 2026, 1, 1, LedgerDirection.income),
          entry('feb', 100, 2026, 2, 1, LedgerDirection.income),
          entry('mar', 100, 2026, 3, 1, LedgerDirection.income),
        ],
      );
      expect(result.isAvailable, isTrue);
      expect(result.typicalDeviationTimesTwo, 0);
    });

    test(
      'STAB-06/07 excludes current partial month and scopes selected year',
      () {
        final result = stability(
          scope: const YearScope(2026),
          income: <DashboardLedgerEntry>[
            entry('jan', 10, 2026, 1, 1, LedgerDirection.income),
            entry('aug', 20, 2026, 8, 1, LedgerDirection.income),
            entry('sep-partial', 999, 2026, 9, 1, LedgerDirection.income),
          ],
        );
        expect(result.observations.map((value) => value.id), <String>[
          'month:2026-1',
          'month:2026-2',
          'month:2026-3',
          'month:2026-4',
          'month:2026-5',
          'month:2026-6',
          'month:2026-7',
          'month:2026-8',
        ]);
        expect(result.observations.last.netMinor, 20);
      },
    );

    test(
      'STAB-08/09 trailing twelve complete months crosses years for Month and Day',
      () {
        final income = <DashboardLedgerEntry>[
          for (var index = 0; index < 14; index += 1)
            entry(
              'month-$index',
              index,
              2025 + ((index + 7) ~/ 12),
              ((index + 7) % 12) + 1,
              1,
              LedgerDirection.income,
            ),
        ];
        final month = stability(
          scope: const MonthScope(YearMonth(year: 2026, month: 8)),
          income: income,
        );
        final day = stability(
          scope: const DayScope(LocalDate(year: 2026, month: 8, day: 4)),
          income: income,
        );
        expect(month.observations, hasLength(12));
        expect(month.observations.first.id, 'month:2025-9');
        expect(month.observations.last.id, 'month:2026-8');
        expect(
          day.observations.map((item) => item.id),
          month.observations.map((item) => item.id),
        );
      },
    );

    test('STAB-10 requires three truthful complete monthly observations', () {
      final result = stability(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('jan', 10, 2026, 1, 1, LedgerDirection.income),
          entry('feb', 20, 2026, 2, 1, LedgerDirection.income),
        ],
      );
      expect(result.isAvailable, isFalse);
      expect(result.sampleCount, 2);
      expect(result.medianNetTimesTwo, isNull);
      expect(result.typicalDeviationTimesTwo, isNull);
    });
  });
}

DashboardLedgerEntry entry(
  String id,
  int amountMinor,
  int year,
  int month,
  int day,
  LedgerDirection direction,
) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  categoryId: 'category-$id',
  direction: direction.name,
  amountMinor: amountMinor,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: 12 * 60,
);
