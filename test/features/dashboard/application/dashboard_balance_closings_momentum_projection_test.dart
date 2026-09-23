import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'closings-momentum-test',
    indexGeneration: 1,
    coreRevision: 1,
  );

  DashboardBalanceClosingsPresentation closings({
    required LedgerTimeScope scope,
    Iterable<DashboardLedgerEntry> income = const <DashboardLedgerEntry>[],
    Iterable<DashboardLedgerEntry> expense = const <DashboardLedgerEntry>[],
  }) => DashboardBalanceClosingsProjection.build(
    identity: identity,
    timeScope: scope,
    incomeEntries: income,
    expenseEntries: expense,
  );

  DashboardBalanceMomentumPresentation momentum({
    required LedgerTimeScope scope,
    required LocalDate asOf,
    int asOfMinute = 12 * 60,
    Iterable<DashboardLedgerEntry> income = const <DashboardLedgerEntry>[],
    Iterable<DashboardLedgerEntry> expense = const <DashboardLedgerEntry>[],
  }) => DashboardBalanceMomentumProjection.build(
    identity: identity,
    timeScope: scope,
    logicalAsOfDate: asOf,
    logicalAsOfLocalTimeMinutes: asOfMinute,
    incomeEntries: income,
    expenseEntries: expense,
  );

  group('Period Closings', () {
    test('CLOSING-SUM keeps only truthful represented annual net buckets', () {
      final result = closings(
        scope: const AllTimeScope(),
        income: <DashboardLedgerEntry>[
          entry('income-2024', 100, 2024, 1, 1, LedgerDirection.income),
          entry('income-2026', 50, 2026, 1, 1, LedgerDirection.income),
        ],
        expense: <DashboardLedgerEntry>[
          entry('expense-2025', 180, 2025, 1, 1, LedgerDirection.expense),
          entry('expense-2026', 50, 2026, 1, 2, LedgerDirection.expense),
        ],
      );

      expect(result.buckets.map((bucket) => bucket.label), <String>[
        '2024',
        '2025',
        '2026',
      ]);
      expect(result.buckets.map((bucket) => bucket.incomeMinor), <int>[
        100,
        0,
        50,
      ]);
      expect(result.buckets.map((bucket) => bucket.expenseMinor), <int>[
        0,
        180,
        50,
      ]);
      expect(result.buckets.map((bucket) => bucket.netMinor), <int>[
        100,
        -180,
        0,
      ]);
      expect(result.positiveBucketCount, 1);
    });

    test('CLOSING-YEAR has twelve non-cumulative calendar months', () {
      final result = closings(
        scope: const YearScope(2026),
        income: <DashboardLedgerEntry>[
          entry('income-jan', 100, 2026, 1, 1, LedgerDirection.income),
        ],
        expense: <DashboardLedgerEntry>[
          entry('expense-feb', 40, 2026, 2, 2, LedgerDirection.expense),
        ],
      );

      expect(result.buckets, hasLength(12));
      expect(result.buckets[0].netMinor, 100);
      expect(result.buckets[1].netMinor, -40);
      expect(result.buckets[2].netMinor, 0);
    });

    test(
      'CLOSING-MONTH keeps daily results non-cumulative across leap February',
      () {
        final result = closings(
          scope: const MonthScope(YearMonth(year: 2024, month: 2)),
          income: <DashboardLedgerEntry>[
            entry('income-day-1', 100, 2024, 2, 1, LedgerDirection.income),
          ],
          expense: <DashboardLedgerEntry>[
            entry('expense-day-2', 40, 2024, 2, 2, LedgerDirection.expense),
          ],
        );

        expect(result.buckets, hasLength(29));
        expect(result.buckets[0].netMinor, 100);
        expect(result.buckets[1].netMinor, -40);
        expect(result.buckets.last.netMinor, 0);
      },
    );

    test('CLOSING-MONTH uses each real 28, 30 and 31-day calendar domain', () {
      for (final sample in <(int, int, int)>[
        (2026, 2, 28),
        (2026, 4, 30),
        (2026, 5, 31),
      ]) {
        final result = closings(
          scope: MonthScope(YearMonth(year: sample.$1, month: sample.$2)),
        );
        expect(result.buckets, hasLength(sample.$3));
        expect(result.buckets.last.netMinor, 0);
      }
    });

    test('CLOSING-DAY maps all six Balance-local boundary intervals', () {
      final minutes = <int>[
        0,
        359,
        360,
        539,
        540,
        719,
        720,
        1079,
        1080,
        1259,
        1260,
        1439,
      ];
      final result = closings(
        scope: DayScope(const LocalDate(year: 2026, month: 9, day: 23)),
        income: <DashboardLedgerEntry>[
          for (var index = 0; index < minutes.length; index += 1)
            entry(
              'income-$index',
              10,
              2026,
              9,
              23,
              LedgerDirection.income,
              minute: minutes[index],
            ),
        ],
      );

      expect(result.buckets.map((bucket) => bucket.label), <String>[
        'Éjjel',
        'Reggel',
        'Délelőtt',
        'Délután',
        'Este',
        'Késő este',
      ]);
      expect(result.buckets.map((bucket) => bucket.incomeMinor), <int>[
        20,
        20,
        20,
        20,
        20,
        20,
      ]);
    });

    test(
      'CLOSING-DAY combines directional membership and retains a true zero',
      () {
        final date = const LocalDate(year: 2026, month: 9, day: 23);
        final result = closings(
          scope: DayScope(date),
          income: <DashboardLedgerEntry>[
            entry(
              'night-income',
              100,
              2026,
              9,
              23,
              LedgerDirection.income,
              minute: 0,
            ),
          ],
          expense: <DashboardLedgerEntry>[
            entry(
              'night-expense',
              -40,
              2026,
              9,
              23,
              LedgerDirection.expense,
              minute: 359,
            ),
            entry(
              'evening-expense',
              -20,
              2026,
              9,
              23,
              LedgerDirection.expense,
              minute: 1080,
            ),
          ],
        );
        expect(result.buckets[0].incomeMinor, 100);
        expect(result.buckets[0].expenseMinor, 40);
        expect(result.buckets[0].netMinor, 60);
        expect(result.buckets[4].netMinor, -20);
        expect(result.buckets[1].netMinor, 0);
      },
    );
  });

  group('Balance Momentum', () {
    test(
      'MOMENTUM-SUM normalizes leap-year YTD windows by their actual days',
      () {
        final result = momentum(
          scope: const AllTimeScope(),
          asOf: const LocalDate(year: 2024, month: 2, day: 29),
          income: <DashboardLedgerEntry>[
            entry('history', 1, 2022, 12, 31, LedgerDirection.income),
            entry('current', 600, 2024, 1, 1, LedgerDirection.income),
            entry('previous', 580, 2023, 1, 1, LedgerDirection.income),
          ],
        );

        expect(result.isAvailable, isTrue);
        expect(result.currentDuration, 60);
        expect(result.previousDuration, 59);
        expect(result.currentNetMinor, 600);
        expect(result.previousNetMinor, 580);
        expect(result.momentum, closeTo(0.1694915, 0.00001));
      },
    );

    test(
      'MOMENTUM-YEAR compares current MTD with the clamped previous month',
      () {
        final result = momentum(
          scope: const YearScope(2026),
          asOf: const LocalDate(year: 2026, month: 3, day: 31),
          income: <DashboardLedgerEntry>[
            entry('history', 1, 2025, 1, 1, LedgerDirection.income),
            entry('march', 310, 2026, 3, 1, LedgerDirection.income),
            entry('february', 290, 2026, 2, 1, LedgerDirection.income),
          ],
        );

        expect(result.currentDuration, 31);
        expect(result.previousDuration, 28);
        expect(result.currentNetPace, 10);
        expect(result.previousNetPace, closeTo(290 / 28, 0.00001));
        expect(result.state, DashboardBalanceMomentumState.weakeningSurplus);
      },
    );

    test('MOMENTUM-MONTH rolls across a previous calendar month', () {
      final result = momentum(
        scope: const MonthScope(YearMonth(year: 2026, month: 9)),
        asOf: const LocalDate(year: 2026, month: 9, day: 3),
        income: <DashboardLedgerEntry>[
          entry('history', 1, 2026, 8, 1, LedgerDirection.income),
          entry('current', 70, 2026, 9, 1, LedgerDirection.income),
          entry('previous', 35, 2026, 8, 27, LedgerDirection.income),
        ],
      );

      expect(result.currentDuration, 7);
      expect(result.previousDuration, 7);
      expect(result.currentNetPace, 10);
      expect(result.previousNetPace, 5);
      expect(result.state, DashboardBalanceMomentumState.strengtheningSurplus);
    });

    test(
      'MOMENTUM-MONTH anchors a completed historical month at its final day',
      () {
        final result = momentum(
          scope: const MonthScope(YearMonth(year: 2025, month: 2)),
          asOf: const LocalDate(year: 2026, month: 9, day: 23),
          income: <DashboardLedgerEntry>[
            entry('history', 1, 2025, 2, 7, LedgerDirection.income),
            entry('current', 70, 2025, 2, 28, LedgerDirection.income),
            entry('previous', 35, 2025, 2, 14, LedgerDirection.income),
          ],
        );
        expect(
          result.currentWindow?.endInclusive,
          const LocalDate(year: 2025, month: 2, day: 28),
        );
        expect(
          result.previousWindow?.endInclusive,
          const LocalDate(year: 2025, month: 2, day: 21),
        );
        expect(result.currentDuration, 7);
        expect(result.previousDuration, 7);
      },
    );

    test(
      'MOMENTUM-DAY compares equal elapsed hours and has no zero-time division',
      () {
        final date = const LocalDate(year: 2026, month: 9, day: 23);
        final available = momentum(
          scope: DayScope(date),
          asOf: date,
          asOfMinute: 14 * 60 + 37,
          income: <DashboardLedgerEntry>[
            entry('history', 1, 2026, 9, 21, LedgerDirection.income),
            entry('today', 1460, 2026, 9, 23, LedgerDirection.income),
            entry('yesterday', 730, 2026, 9, 22, LedgerDirection.income),
          ],
        );
        final unavailable = momentum(
          scope: DayScope(date),
          asOf: date,
          asOfMinute: 0,
          income: <DashboardLedgerEntry>[
            entry('history', 1, 2026, 9, 21, LedgerDirection.income),
          ],
        );

        expect(available.currentDuration, 877);
        expect(available.previousDuration, 877);
        expect(available.currentNetPace, closeTo(1460 * 60 / 877, 0.001));
        expect(available.previousNetPace, closeTo(730 * 60 / 877, 0.001));
        expect(
          available.state,
          DashboardBalanceMomentumState.strengtheningSurplus,
        );
        expect(unavailable.isAvailable, isFalse);
        expect(unavailable.state, DashboardBalanceMomentumState.unavailable);
      },
    );

    test('MOMENTUM-DAY uses full prior days for a historical selected day', () {
      final selected = const LocalDate(year: 2025, month: 7, day: 2);
      final result = momentum(
        scope: DayScope(selected),
        asOf: const LocalDate(year: 2026, month: 9, day: 23),
        income: <DashboardLedgerEntry>[
          entry('history', 1, 2025, 6, 30, LedgerDirection.income),
          entry('current', 240, 2025, 7, 2, LedgerDirection.income),
          entry('previous', 120, 2025, 7, 1, LedgerDirection.income),
        ],
      );
      expect(result.currentDuration, 24 * 60);
      expect(result.previousDuration, 24 * 60);
      expect(result.currentNetPace, 10);
      expect(result.previousNetPace, 5);
    });

    test(
      'MOMENTUM distinguishes proved-zero movement from missing history',
      () {
        final date = const LocalDate(year: 2026, month: 9, day: 23);
        final provedZero = momentum(
          scope: DayScope(date),
          asOf: date,
          asOfMinute: 60,
          income: <DashboardLedgerEntry>[
            entry('admission-history', 1, 2026, 9, 21, LedgerDirection.income),
          ],
        );
        final missing = momentum(
          scope: DayScope(date),
          asOf: date,
          asOfMinute: 60,
        );
        expect(provedZero.isAvailable, isTrue);
        expect(provedZero.state, DashboardBalanceMomentumState.stableBreakEven);
        expect(provedZero.momentum.isNaN, isFalse);
        expect(provedZero.momentum.isInfinite, isFalse);
        expect(missing.isAvailable, isFalse);
      },
    );

    test('MOMENTUM has explicit four quadrants and zero-axis states', () {
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: -2, momentum: 1),
        DashboardBalanceMomentumState.recovery,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 2, momentum: 1),
        DashboardBalanceMomentumState.strengtheningSurplus,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: -2, momentum: -1),
        DashboardBalanceMomentumState.deepeningDeficit,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 2, momentum: -1),
        DashboardBalanceMomentumState.weakeningSurplus,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 2, momentum: 0),
        DashboardBalanceMomentumState.stableSurplus,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: -2, momentum: 0),
        DashboardBalanceMomentumState.stableDeficit,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 0, momentum: 2),
        DashboardBalanceMomentumState.improvingBreakEven,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 0, momentum: -2),
        DashboardBalanceMomentumState.worseningBreakEven,
      );
      expect(
        DashboardBalanceMomentumState.resolve(currentNetPace: 0, momentum: 0),
        DashboardBalanceMomentumState.stableBreakEven,
      );
    });
  });
}

DashboardLedgerEntry entry(
  String id,
  int amountMinor,
  int year,
  int month,
  int day,
  LedgerDirection direction, {
  int minute = 12 * 60,
}) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  categoryId: 'category-$id',
  direction: direction.name,
  amountMinor: amountMinor,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: minute,
);
