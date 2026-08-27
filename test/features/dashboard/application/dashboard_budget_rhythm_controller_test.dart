import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/time/fluvi_clock.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'projects the fake local Wednesday through seven chronological days even when navigation retains July',
    () {
      final projection = DashboardBudgetRhythmProjector.project(
        snapshot: _rhythmSnapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.month,
        localClockDate: DateTime(2026, 8, 19, 16, 42),
      );

      expect(projection.title, '7 napos ritmus');
      expect(projection.windowEnd, DateTime.utc(2026, 8, 19));
      expect(projection.bars, hasLength(7));
      expect(projection.bars.map((bar) => bar.label), <String>[
        'Cs',
        'P',
        'Szo',
        'V',
        'H',
        'K',
        'Sze',
      ]);
      expect(projection.bars.map((bar) => bar.actualScaled100), <int>[
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(projection.bars.last.visualFraction, 1);
      expect(projection.bars.first.visualFraction, closeTo(1 / 7, .0001));
    },
  );

  test(
    'uses only the selected category range and keeps a zero window flat',
    () {
      final category = DashboardBudgetRhythmProjector.project(
        snapshot: _rhythmSnapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 1,
        plane: TimePlane.month,
        localClockDate: DateTime(2026, 8, 19),
      );
      final zero = DashboardBudgetRhythmProjector.project(
        snapshot: _rhythmSnapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 2,
        plane: TimePlane.month,
        localClockDate: DateTime(2026, 8, 19),
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
    'projects six current months and five current years from the local clock',
    () {
      final month = DashboardBudgetRhythmProjector.project(
        snapshot: _rhythmSnapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.year,
        localClockDate: DateTime(2026, 8, 19),
      );
      final years = DashboardBudgetRhythmProjector.project(
        snapshot: _rhythmSnapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 0,
        plane: TimePlane.sum,
        localClockDate: DateTime(2026, 8, 19),
      );

      expect(month.title, '6 havi ritmus');
      expect(month.bars.map((bar) => bar.label), <String>[
        'már',
        'ápr',
        'máj',
        'jún',
        'júl',
        'aug',
      ]);
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

  test(
    'controller uses its injected local clock and refreshes at midnight',
    () {
      final clock = _FakeClock(DateTime(2026, 8, 19, 23, 59));
      final rollover = _FakeRolloverScheduler();
      final categories = ValueNotifier<List<FluviCategory>>(
        const <FluviCategory>[],
      );
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(timeScope: const AllTimeScope(), plane: TimePlane.sum),
      );
      final snapshot = _limitSnapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 19),
      );
      final navigation = DashboardNavigationController(
        initialDate: DateTime(2026, 7, 19),
        initialPlane: TimePlane.month,
        initialDirection: LedgerDirection.expense,
        initialCoreRevision: 7,
      );
      final controller = DashboardBudgetRhythmController(
        presentation: presentation,
        navigation: navigation,
        visibleFrame: visible,
        snapshotForCurrentFrame: () => snapshot,
        clock: clock,
        scheduleRollover: rollover.call,
      );
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);
      addTearDown(navigation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      expect(navigation.state.temporalAnchor.visibleMonth, 7);
      expect(navigation.state.temporalAnchor.visibleDay, 19);
      expect(
        controller.value!.projection.windowEnd,
        DateTime.utc(2026, 8, 19),
        reason:
            'The all-time dashboard is the only rhythm state whose endpoint '
            'comes from the local clock.',
      );
      expect(rollover.delays.single, const Duration(minutes: 1));

      clock.value = DateTime(2026, 8, 20);
      rollover.fire();

      expect(controller.value!.projection.windowEnd, DateTime.utc(2026, 8, 20));
      expect(rollover.delays, hasLength(2));
    },
  );

  test('a visible temporal preview, rather than the committed clock window, '
      'owns the rhythm endpoint during a day crossing', () {
    final clock = _FakeClock(DateTime(2026, 8, 19, 12));
    final categories = ValueNotifier<List<FluviCategory>>(
      const <FluviCategory>[],
    );
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(
      _visibleFrame(
        timeScope: const DayScope(LocalDate(year: 2026, month: 8, day: 18)),
        plane: TimePlane.month,
      ),
    );
    final snapshot = _limitSnapshot();
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => snapshot,
      logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 19),
    );
    final navigation = DashboardNavigationController(
      initialDate: DateTime(2026, 7, 19),
      initialPlane: TimePlane.month,
      initialDirection: LedgerDirection.expense,
      initialCoreRevision: 7,
    );
    final controller = DashboardBudgetRhythmController(
      presentation: presentation,
      navigation: navigation,
      visibleFrame: visible,
      snapshotForCurrentFrame: () => snapshot,
      clock: clock,
      scheduleRollover: _FakeRolloverScheduler().call,
    );
    addTearDown(controller.dispose);
    addTearDown(presentation.dispose);
    addTearDown(navigation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    expect(
      controller.value!.projection.windowEnd,
      DateTime.utc(2026, 8, 18),
      reason:
          'The accepted preview day must reach the rhythm card before '
          'settlement or a wall-clock rollover.',
    );
  });
}

PreparedBudgetRhythmSnapshot _rhythmSnapshot() {
  final aggregate = <PreparedBudgetRhythmPoint>[
    for (var day = 13; day <= 19; day += 1)
      PreparedBudgetRhythmPoint(
        epochDay: _epochDay(2026, 8, day),
        actualScaled100: day - 12,
      ),
    const PreparedBudgetRhythmPoint(epochDay: 19500, actualScaled100: 8),
    const PreparedBudgetRhythmPoint(epochDay: 19000, actualScaled100: 22),
    const PreparedBudgetRhythmPoint(epochDay: 19300, actualScaled100: 23),
    const PreparedBudgetRhythmPoint(epochDay: 19600, actualScaled100: 24),
  ]..sort((left, right) => left.epochDay.compareTo(right.epochDay));
  final category = <PreparedBudgetRhythmPoint>[
    PreparedBudgetRhythmPoint(
      epochDay: _epochDay(2026, 8, 19),
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

PreparedBudgetLimitSnapshot _limitSnapshot() {
  final rhythm = _rhythmSnapshot();
  PreparedBudgetLimitDirectionBank bank(List<String> ids) {
    final targetCount = ids.length + 1;
    return PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: ids,
      cells: List<PreparedBudgetLimitCell>.filled(
        14 * targetCount,
        const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
      ),
    );
  }

  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(const <String>[]),
    expenseBank: bank(const <String>['category-a', 'category-b']),
    rhythmSnapshot: rhythm,
  );
}

DashboardVisibleFrame _visibleFrame({
  LedgerTimeScope timeScope = const MonthScope(YearMonth(year: 2026, month: 1)),
  TimePlane plane = TimePlane.month,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: timeScope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 7,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const [],
      entryCount: 0,
      nextCursor: null,
      direction: LedgerDirection.expense,
    ),
    presentationDigest: 1,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: plane,
    railOpen: false,
    semanticIndex: 0,
    childLabel: 'January',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

final class _FakeClock implements FluviClock {
  _FakeClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final class _FakeRolloverScheduler {
  final List<Duration> delays = <Duration>[];
  VoidCallback? _callback;

  VoidCallback call(Duration delay, VoidCallback callback) {
    delays.add(delay);
    _callback = callback;
    return () {};
  }

  void fire() => _callback!.call();
}
