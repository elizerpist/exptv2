import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_anchor.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  test(
    'projects the selected aggregate target into an inclusive seven-day window',
    () {
      final projection = DashboardBudgetRhythmProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.month,
        anchor: _anchor(year: 2026, month: 7, day: 1),
      );

      expect(projection.title, '7 napos ritmus');
      expect(projection.bars, hasLength(7));
      expect(projection.bars.map((bar) => bar.actualScaled100), <int>[
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(projection.bars.last.label, isNotEmpty);
      expect(projection.bars.last.visualFraction, 1);
      expect(projection.bars.first.visualFraction, closeTo(1 / 7, .0001));
    },
  );

  test(
    'uses only the selected category range and keeps a zero window flat',
    () {
      final category = DashboardBudgetRhythmProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 1,
        plane: TimePlane.month,
        anchor: _anchor(year: 2026, month: 7, day: 1),
      );
      final zero = DashboardBudgetRhythmProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 2,
        plane: TimePlane.month,
        anchor: _anchor(year: 2026, month: 7, day: 1),
      );

      expect(category.bars.map((bar) => bar.actualScaled100), <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        7,
      ]);
      expect(zero.bars.map((bar) => bar.visualFraction), everyElement(0));
    },
  );

  test(
    'projects trailing six months and five years across calendar boundaries',
    () {
      final month = DashboardBudgetRhythmProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.year,
        anchor: _anchor(year: 2026, month: 1, day: 1),
      );
      final years = DashboardBudgetRhythmProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.sum,
        anchor: _anchor(year: 2026, month: 1, day: 1),
      );

      expect(month.title, '6 havi ritmus');
      expect(month.bars, hasLength(6));
      expect(month.bars.first.label, 'aug');
      expect(month.bars.last.label, 'jan');
      expect(years.title, '5 éves ritmus');
      expect(years.bars.map((bar) => bar.label), <String>[
        '2022',
        '2023',
        '2024',
        '2025',
        '2026',
      ]);
    },
  );
}

DashboardTemporalAnchor _anchor({
  required int year,
  required int month,
  required int day,
}) => DashboardTemporalAnchor(
  visibleYear: year,
  visibleMonth: month,
  visibleDay: day,
  sourcePlane: TimePlane.month,
  sourceParentQueryKey: _queryKey,
  sourceChildQueryKey: _queryKey,
  sourceChildOrdinal: 0,
  direction: LedgerDirection.expense,
  filtersRefinementsIdentity: '',
  revision: 7,
  navigationEpoch: 1,
);

final _queryKey = LedgerQueryKey('rhythm-test');

PreparedBudgetRhythmSnapshot _snapshot() {
  final aggregate = <PreparedBudgetRhythmPoint>[
    for (var day = 25; day <= 30; day += 1)
      PreparedBudgetRhythmPoint(
        epochDay: _epochDay(2026, 6, day),
        actualScaled100: day - 24,
      ),
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2026, 7, 1),
      actualScaled100: 7,
    ),
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2025, 8, 1),
      actualScaled100: 8,
    ),
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2022, 1, 1),
      actualScaled100: 22,
    ),
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2023, 1, 1),
      actualScaled100: 23,
    ),
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2024, 1, 1),
      actualScaled100: 24,
    ),
  ]..sort((left, right) => left.epochDay.compareTo(right.epochDay));
  final category = <PreparedBudgetRhythmPoint>[
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2026, 7, 1),
      actualScaled100: 7,
    ),
  ];
  return PreparedBudgetRhythmSnapshot(
    coreRevision: 7,
    incomeBank: PreparedBudgetRhythmDirectionBank.empty(targetCount: 1),
    expenseBank: PreparedBudgetRhythmDirectionBank.fromTargetPoints(
      targetPoints: <List<PreparedBudgetRhythmPoint>>[
        aggregate,
        category,
        const <PreparedBudgetRhythmPoint>[],
      ],
    ),
  );
}

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
