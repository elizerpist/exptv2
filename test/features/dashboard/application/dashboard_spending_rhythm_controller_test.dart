import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_spending_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final snapshot = _snapshot();

  test('DAY projects eight prepared local three-hour parts', () {
    final analysis = DashboardSpendingRhythmProjector.project(
      snapshot: snapshot,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: const DayScope(LocalDate(year: 2022, month: 3, day: 2)),
    );

    expect(analysis, isA<DaySpendingRhythm>());
    expect(analysis.buckets, hasLength(8));
    expect(analysis.buckets.map((bucket) => bucket.label), <String>[
      '0',
      '3',
      '6',
      '9',
      '12',
      '15',
      '18',
      '21',
    ]);
    expect(
      analysis.buckets.map((bucket) => bucket.accessibilityLabel),
      <String>[
        'Éjfél',
        'Hajnal',
        'Reggel',
        'Délelőtt',
        'Kora délután',
        'Délután',
        'Este',
        'Késő este',
      ],
    );
    expect(analysis.buckets.map((bucket) => bucket.actualScaled100), <int>[
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      160,
    ]);
  });

  test('MONTH materializes every selected historical calendar day', () {
    final analysis = DashboardSpendingRhythmProjector.project(
      snapshot: snapshot,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: const MonthScope(YearMonth(year: 2022, month: 3)),
    );

    expect(analysis, isA<MonthSpendingRhythm>());
    expect(analysis.buckets, hasLength(31));
    expect(analysis.buckets.first.actualScaled100, 80);
    expect(analysis.buckets[1].actualScaled100, 160);
    expect(analysis.buckets[2].actualScaled100, 0);
    expect(analysis.buckets.last.label, '31');
  });

  test('MONTH keeps each real calendar length, including zero-spend days', () {
    final emptySnapshot = PreparedSpendingRhythmSnapshot(
      coreRevision: 8,
      incomeBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 1),
      expenseBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 1),
    );
    int countFor(YearMonth month) => DashboardSpendingRhythmProjector.project(
      snapshot: emptySnapshot,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: MonthScope(month),
    ).buckets.length;

    expect(countFor(const YearMonth(year: 2023, month: 2)), 28);
    expect(countFor(const YearMonth(year: 2024, month: 2)), 29);
    expect(countFor(const YearMonth(year: 2024, month: 4)), 30);
    expect(countFor(const YearMonth(year: 2024, month: 7)), 31);
  });

  test(
    'YEAR is fixed Jan through Dec instead of a six-month rolling window',
    () {
      final analysis = DashboardSpendingRhythmProjector.project(
        snapshot: snapshot,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        scope: const YearScope(2022),
      );

      expect(analysis, isA<YearSpendingRhythm>());
      expect(analysis.buckets, hasLength(12));
      expect(analysis.buckets.first.label, 'JAN');
      expect(analysis.buckets[2].actualScaled100, 240);
      expect(analysis.buckets.last.label, 'DEC');
    },
  );

  test('SUM retains concrete zero years inside the target history span', () {
    final analysis = DashboardSpendingRhythmProjector.project(
      snapshot: snapshot,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: const AllTimeScope(),
    );

    expect(analysis, isA<SumSpendingRhythm>());
    expect(analysis.buckets.map((bucket) => bucket.label), <String>[
      '2022',
      '2023',
      '2024',
    ]);
    expect(analysis.buckets.map((bucket) => bucket.actualScaled100), <int>[
      240,
      0,
      400,
    ]);
  });

  test('SUM never truncates a long concrete calendar-year domain', () {
    final first = _epochDay(1990, 1, 1);
    final last = _epochDay(2021, 1, 1);
    final longSnapshot = PreparedSpendingRhythmSnapshot(
      coreRevision: 9,
      incomeBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 1),
      expenseBank: PreparedSpendingRhythmDirectionBank(
        targetCount: 1,
        targetOffsets: const <int>[0, 2],
        epochDays: <int>[first, last],
        dailyActualScaled100: const <int>[1, 1],
        dayPartActualScaled100: const <int>[
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    );
    final analysis = DashboardSpendingRhythmProjector.project(
      snapshot: longSnapshot,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: const AllTimeScope(),
    );

    expect(analysis.buckets, hasLength(32));
    expect(analysis.buckets.first.label, '1990');
    expect(analysis.buckets.last.label, '2021');
    expect(analysis.buckets[1].actualScaled100, 0);
  });

  test('average preserves fractional values and includes zero buckets', () {
    final analysis = DaySpendingRhythm(
      coreRevision: 7,
      direction: LedgerDirection.expense,
      targetHandle: 0,
      scope: const DayScope(LocalDate(year: 2022, month: 3, day: 1)),
      buckets: const <SpendingRhythmBucket>[
        SpendingRhythmBucket(
          label: '1',
          accessibilityLabel: '1',
          actualScaled100: 5000,
        ),
        SpendingRhythmBucket(
          label: '2',
          accessibilityLabel: '2',
          actualScaled100: 20000,
        ),
        SpendingRhythmBucket(
          label: '3',
          accessibilityLabel: '3',
          actualScaled100: 10000,
        ),
        SpendingRhythmBucket(
          label: '4',
          accessibilityLabel: '4',
          actualScaled100: 0,
        ),
        SpendingRhythmBucket(
          label: '5',
          accessibilityLabel: '5',
          actualScaled100: 0,
        ),
        SpendingRhythmBucket(
          label: '6',
          accessibilityLabel: '6',
          actualScaled100: 0,
        ),
        SpendingRhythmBucket(
          label: '7',
          accessibilityLabel: '7',
          actualScaled100: 0,
        ),
        SpendingRhythmBucket(
          label: '8',
          accessibilityLabel: '8',
          actualScaled100: 0,
        ),
      ],
    );

    expect(analysis.averageActualScaled100, 4375);
  });
}

PreparedSpendingRhythmSnapshot _snapshot() {
  final first = _epochDay(2022, 3, 1);
  final second = _epochDay(2022, 3, 2);
  final later = _epochDay(2024, 7, 1);
  return PreparedSpendingRhythmSnapshot(
    coreRevision: 7,
    incomeBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 1),
    expenseBank: PreparedSpendingRhythmDirectionBank(
      targetCount: 1,
      targetOffsets: const <int>[0, 3],
      epochDays: <int>[first, second, later],
      dailyActualScaled100: const <int>[80, 160, 400],
      dayPartActualScaled100: const <int>[
        80,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        160,
        0,
        0,
        0,
        0,
        400,
        0,
        0,
        0,
      ],
    ),
  );
}

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;
