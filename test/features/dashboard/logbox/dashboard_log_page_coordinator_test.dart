import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart';
import 'package:fluvi/features/dashboard/logbox/data/dashboard_log_repository.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _LogRepository
    implements DashboardLedgerRepository, DashboardLogPageRepository {
  _LogRepository(this._initial);

  final DashboardLedgerResult _initial;
  final streams = <String, StreamController<DashboardLedgerResult>>{};
  int logPageReads = 0;
  DashboardDayGroupPage? nextPage;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => _initial;

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) =>
      (streams[scope.key.value] ??=
              StreamController<DashboardLedgerResult>.broadcast())
          .stream;

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    logPageReads += 1;
    return nextPage ??
        DashboardDayGroupPage(
          canonicalQueryKey: scope.key.value,
          coreRevision: 12,
          groups: const [],
          nextCursor: null,
        );
  }

  Future<void> emit(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result,
  ) async {
    streams[scope.key.value]!.add(result);
    await Future<void>.value();
  }

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _PrefetchLogRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository,
        DashboardLogPageRepository {
  int watchCalls = 0;
  int prefetchCalls = 0;
  int nextPageCalls = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => const DashboardLedgerResult(totalMinor: 0);

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) async {
    prefetchCalls += 1;
    const entry = DashboardLedgerEntry(
      id: 'prefetched-entry',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 901489,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 720,
    );
    return DashboardLedgerResult(
      totalMinor: 901489,
      entryCount: 1,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: const [
        DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: [entry]),
      ],
    );
  }

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    nextPageCalls += 1;
    return DashboardDayGroupPage(
      canonicalQueryKey: scope.key.value,
      coreRevision: 12,
      groups: const [],
      nextCursor: null,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    watchCalls += 1;
    return const Stream<DashboardLedgerResult>.empty();
  }
}

void main() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
  );

  const rows = <DashboardLedgerEntry>[
    DashboardLedgerEntry(
      id: 'entry-13-b',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 400000,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 720,
    ),
    DashboardLedgerEntry(
      id: 'entry-13-a',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 501489,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 600,
    ),
  ];

  test(
    'binds summary metrics and complete day rows from one committed snapshot',
    () async {
      final result = DashboardLedgerResult(
        totalMinor: 901489,
        entryCount: 2,
        scopeKey: scope.key.value,
        timeScopeKey: scope.timeScope.canonicalKey,
        direction: scope.direction.name,
        coreRevision: 12,
        entries: rows,
        dayGroups: const [
          DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: rows),
        ],
      );
      final repository = _LogRepository(result);
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      addTearDown(repository.dispose);

      query.refresh();
      await repository.emit(scope, result);

      final state = coordinator.state;
      expect(state, isA<DashboardLogData>());
      final data = state as DashboardLogData;
      expect(data.snapshot.summaryMetrics.canonicalQueryKey, scope.key.value);
      expect(data.snapshot.summaryMetrics.coreRevision, 12);
      expect(data.snapshot.summaryMetrics.totalMinor, 901489);
      expect(data.snapshot.summaryMetrics.entryCount, 2);
      expect(data.groups, hasLength(1));
      expect(data.groups.single.rows.map((row) => row.id), [
        'entry-13-b',
        'entry-13-a',
      ]);
      expect(repository.logPageReads, 0);
    },
  );

  test(
    'does not bind or query LogBox data while only a preview is changing',
    () async {
      final result = DashboardLedgerResult(
        totalMinor: 901489,
        entryCount: 2,
        scopeKey: scope.key.value,
        timeScopeKey: scope.timeScope.canonicalKey,
        direction: scope.direction.name,
        coreRevision: 12,
        entries: rows,
        dayGroups: const [
          DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: rows),
        ],
      );
      final repository = _LogRepository(result);
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      addTearDown(repository.dispose);

      query.refresh();
      await repository.emit(scope, result);
      final before = coordinator.state;

      // A child-rail preview never enters CurrentQueryController, so the
      // LogBox coordinator has no rebind or detail-page work to perform.
      await Future<void>.value();

      expect(coordinator.state, same(before));
      expect(repository.logPageReads, 0);
    },
  );

  test(
    'a resolved rail target prefetches invisibly and binds as a cache hit',
    () async {
      final repository = _PrefetchLogRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 13)),
      );

      final before = coordinator.state;
      await coordinator.prefetchForMotionTarget(
        target,
        reason: 'motionTargetResolved',
      );

      // Prefetch owns data cache only: the visible list cannot change before
      // the application's normal settled-scope commit.
      expect(coordinator.state, same(before));
      expect(repository.prefetchCalls, 1);
      expect(repository.watchCalls, 0);
      expect(repository.nextPageCalls, 0);

      query.setTimeScope(target.timeScope, reason: 'childSettled');

      final data = coordinator.state as DashboardLogData;
      expect(data.queryKey, target.key.value);
      expect(data.cacheHit, isTrue);
      expect(data.groups.single.rows.single.id, 'prefetched-entry');
      expect(repository.watchCalls, 0);
    },
  );

  test('appends one complete older day with stable query identity', () async {
    final first = DashboardLedgerResult(
      totalMinor: 1301489,
      entryCount: 3,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: const [
        DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: rows),
      ],
      nextDayCursor: const {'beforeLocalEpochDayExclusive': 20525},
    );
    final repository = _LogRepository(first)
      ..nextPage = DashboardDayGroupPage(
        canonicalQueryKey: scope.key.value,
        coreRevision: 12,
        groups: const [
          DashboardDayLogGroup(
            localDate: LocalDate(year: 2026, month: 3, day: 12),
            rows: [
              DashboardLedgerEntry(
                id: 'entry-12',
                partnerId: 'partner-1',
                categoryId: 'category-1',
                direction: 'expense',
                amountMinor: 400000,
                bookedLocalEpochDay: 20524,
                bookedLocalTimeMinutes: 600,
              ),
            ],
          ),
        ],
        nextCursor: null,
      );
    final query = CurrentQueryController(
      repository: repository,
      initialScope: scope,
    );
    final coordinator = DashboardLogPageCoordinator(
      query: query,
      repository: repository,
    );
    addTearDown(coordinator.dispose);
    addTearDown(query.dispose);
    addTearDown(repository.dispose);

    query.refresh();
    await repository.emit(scope, first);
    await coordinator.loadNextPage();

    final data = coordinator.state as DashboardLogData;
    expect(repository.logPageReads, 1);
    expect(data.queryKey, scope.key.value);
    expect(data.coreRevision, 12);
    expect(data.groups.map((group) => group.localDate.isoString), [
      '2026-03-13',
      '2026-03-12',
    ]);
    expect(data.groups.expand((group) => group.rows).map((row) => row.id), [
      'entry-13-b',
      'entry-13-a',
      'entry-12',
    ]);
    expect(data.hasNextPage, isFalse);
  });
}
