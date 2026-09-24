import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'expense|query-a',
    indexGeneration: 7,
    coreRevision: 11,
  );

  DashboardBalanceCategoryMoversPresentation movers({
    required LedgerTimeScope scope,
    required LocalDate asOf,
    required List<DashboardLedgerEntry> entries,
  }) => DashboardBalanceCategoryMoversProjection.build(
    identity: identity,
    timeScope: scope,
    selectedDirection: LedgerDirection.expense,
    logicalAsOfDate: asOf,
    entries: entries,
  );

  test(
    'MOVERS-RED: ranks financial impact ahead of raw percentage and keeps integer deltas',
    () {
      final result = movers(
        scope: const YearScope(2026),
        asOf: const LocalDate(year: 2027, month: 1, day: 1),
        entries: <DashboardLedgerEntry>[
          _entry('a-old', 'a', 500, 2025, 6, 1),
          _entry('a-now', 'a', 1500, 2026, 6, 1),
          _entry('b-old', 'b', 80000, 2025, 6, 1),
          _entry('b-now', 'b', 120000, 2026, 6, 1),
          _entry('gone', 'gone', 1000, 2025, 6, 2),
          _entry('new', 'new', 7000, 2026, 7, 1),
        ],
      );

      expect(result.movers.map((item) => item.id), <String>[
        'b',
        'new',
        'a',
        'gone',
      ]);
      expect(result.movers.first.deltaMinor, 40000);
      expect(result.movers.first.percentageBasisPoints, 5000);
      expect(result.movers[1].isNew, isTrue);
      expect(result.movers[1].percentageBasisPoints, isNull);
      expect(result.movers.last.percentageBasisPoints, -10000);
    },
  );

  test(
    'MOVERS-RED: derives exact historical/current calendar windows from logical as-of',
    () {
      final historicalMonth = movers(
        scope: const MonthScope(YearMonth(year: 2025, month: 2)),
        asOf: const LocalDate(year: 2026, month: 9, day: 23),
        entries: const <DashboardLedgerEntry>[],
      );
      expect(
        historicalMonth.currentWindow.startInclusive,
        const LocalDate(year: 2025, month: 2, day: 1),
      );
      expect(
        historicalMonth.currentWindow.endInclusive,
        const LocalDate(year: 2025, month: 2, day: 28),
      );
      expect(
        historicalMonth.referenceWindow.startInclusive,
        const LocalDate(year: 2025, month: 1, day: 1),
      );
      expect(
        historicalMonth.referenceWindow.endInclusive,
        const LocalDate(year: 2025, month: 1, day: 31),
      );

      final currentMonth = movers(
        scope: const MonthScope(YearMonth(year: 2026, month: 3)),
        asOf: const LocalDate(year: 2026, month: 3, day: 31),
        entries: const <DashboardLedgerEntry>[],
      );
      expect(
        currentMonth.currentWindow.endInclusive,
        const LocalDate(year: 2026, month: 3, day: 31),
      );
      expect(
        currentMonth.referenceWindow.endInclusive,
        const LocalDate(year: 2026, month: 2, day: 28),
      );

      final sum = movers(
        scope: const AllTimeScope(),
        asOf: const LocalDate(year: 2026, month: 9, day: 23),
        entries: const <DashboardLedgerEntry>[],
      );
      expect(
        sum.currentWindow.startInclusive,
        const LocalDate(year: 2026, month: 1, day: 1),
      );
      expect(
        sum.currentWindow.endInclusive,
        const LocalDate(year: 2026, month: 9, day: 23),
      );
      expect(
        sum.referenceWindow.startInclusive,
        const LocalDate(year: 2025, month: 1, day: 1),
      );
      expect(
        sum.referenceWindow.endInclusive,
        const LocalDate(year: 2025, month: 9, day: 23),
      );
    },
  );

  test(
    'MOVERS-RED: current month trend preserves daily comparison buckets and no-change state is explicit',
    () {
      final result = movers(
        scope: const MonthScope(YearMonth(year: 2026, month: 2)),
        asOf: const LocalDate(year: 2026, month: 2, day: 3),
        entries: <DashboardLedgerEntry>[
          _entry('food-now-1', 'food', 100, 2026, 2, 1),
          _entry('food-now-2', 'food', 200, 2026, 2, 3),
          _entry('food-before-1', 'food', 50, 2026, 1, 1),
          _entry('food-before-2', 'food', 70, 2026, 1, 3),
          _entry('same-before', 'same', 9, 2026, 1, 1),
          _entry('same-now', 'same', 9, 2026, 2, 1),
        ],
      );
      final food = result.movers.single;
      expect(food.id, 'food');
      expect(food.trend.map((point) => point.currentMinor), <int>[100, 0, 200]);
      expect(food.trend.map((point) => point.referenceMinor), <int>[50, 0, 70]);

      final unchanged = movers(
        scope: const DayScope(LocalDate(year: 2026, month: 2, day: 2)),
        asOf: const LocalDate(year: 2026, month: 2, day: 3),
        entries: const <DashboardLedgerEntry>[],
      );
      expect(unchanged.isNoChange, isTrue);
      expect(unchanged.movers, isEmpty);
    },
  );

  test('MOVERS-RED: deterministic category-id tie break is stable', () {
    final result = movers(
      scope: const DayScope(LocalDate(year: 2026, month: 2, day: 2)),
      asOf: const LocalDate(year: 2026, month: 2, day: 3),
      entries: <DashboardLedgerEntry>[
        _entry('z-before', 'z', 10, 2026, 2, 1),
        _entry('z-now', 'z', 30, 2026, 2, 2),
        _entry('a-before', 'a', 10, 2026, 2, 1),
        _entry('a-now', 'a', 30, 2026, 2, 2),
      ],
    );
    expect(result.movers.map((item) => item.id), <String>['a', 'z']);
  });

  test(
    'MOVERS-RECONNECT-RED: linked presentation retains only the ranked five movers',
    () {
      final result = movers(
        scope: const DayScope(LocalDate(year: 2026, month: 2, day: 2)),
        asOf: const LocalDate(year: 2026, month: 2, day: 3),
        entries: <DashboardLedgerEntry>[
          for (var index = 0; index < 6; index += 1) ...<DashboardLedgerEntry>[
            _entry('before-$index', 'category-$index', 10, 2026, 2, 1),
            _entry(
              'now-$index',
              'category-$index',
              (index + 1) * 100,
              2026,
              2,
              2,
            ),
          ],
        ],
      );

      expect(result.movers, hasLength(5));
      expect(result.movers.map((mover) => mover.id), <String>[
        'category-5',
        'category-4',
        'category-3',
        'category-2',
        'category-1',
      ]);
    },
  );
}

DashboardLedgerEntry _entry(
  String id,
  String categoryId,
  int amountMinor,
  int year,
  int month,
  int day,
) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$categoryId',
  categoryId: categoryId,
  categoryDisplayName: categoryId.toUpperCase(),
  categoryColorId: 'color_07',
  categoryIconId: 'icon_17',
  direction: LedgerDirection.expense.name,
  amountMinor: amountMinor,
  bookedLocalEpochDay: LocalDate(year: year, month: month, day: day).epochDay,
  bookedLocalTimeMinutes: 12 * 60,
);
