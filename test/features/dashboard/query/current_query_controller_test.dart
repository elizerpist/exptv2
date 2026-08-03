import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart';

class _DelayedRepository implements DashboardLedgerRepository {
  final pending = <String, Completer<DashboardLedgerResult>>{};
  final requestedKeys = <String>[];

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    final key = scope.key.value;
    requestedKeys.add(key);
    final completer = Completer<DashboardLedgerResult>();
    pending[key] = completer;
    return completer.future;
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    return Stream.fromFuture(read(scope, pageSize: pageSize, after: after));
  }
}

class _ImmediateRepository implements DashboardLedgerRepository {
  int reads = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads += 1;
    return const DashboardLedgerResult(totalMinor: 100, coreRevision: 7);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    return Stream.fromFuture(read(scope, pageSize: pageSize, after: after));
  }
}

class _DenseImmediateRepository implements DashboardLedgerRepository {
  _DenseImmediateRepository()
    : _entries = List<DashboardLedgerEntry>.generate(
        1001,
        (index) => DashboardLedgerEntry(
          id: 'cached-row-$index',
          partnerId: 'partner-1',
          categoryId: 'category-1',
          direction: 'expense',
          amountMinor: 1,
          bookedLocalEpochDay: 20525,
          bookedLocalTimeMinutes: 720,
        ),
      );

  final List<DashboardLedgerEntry> _entries;
  int reads = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads += 1;
    return DashboardLedgerResult(
      totalMinor: 1001,
      entryCount: _entries.length,
      coreRevision: 7,
      entries: _entries,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => Stream.fromFuture(read(scope, pageSize: pageSize, after: after));
}

class _StreamingRepository implements DashboardLedgerRepository {
  final streams = <String, StreamController<DashboardLedgerResult>>{};
  final requestedKeys = <String>[];

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    return const DashboardLedgerResult(totalMinor: 0);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    requestedKeys.add(scope.key.value);
    return (streams[scope.key.value] ??=
            StreamController<DashboardLedgerResult>.broadcast())
        .stream;
  }

  Future<void> emit(String key, DashboardLedgerResult value) async {
    streams[key]?.add(value);
    await Future<void>.value();
  }

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _CompletedWithoutSnapshotRepository implements DashboardLedgerRepository {
  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => const DashboardLedgerResult(totalMinor: 0);

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => const Stream<DashboardLedgerResult>.empty();
}

class _PrefetchRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository {
  int watchCalls = 0;
  int prefetchCalls = 0;

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
    return DashboardLedgerResult(
      totalMinor: 901489,
      entryCount: 4,
      coreRevision: 12,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
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
  test(
    'query key is identical for equivalent scopes regardless of facet order',
    () {
      final first = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
        categoryIds: const {'b', 'a'},
        partnerIds: const {'p2', 'p1'},
        refinements: const {'note': 'food', 'min': 100},
      );
      final second = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
        categoryIds: const {'a', 'b'},
        partnerIds: const {'p1', 'p2'},
        refinements: const {'min': 100, 'note': 'food'},
      );

      expect(first, second);
      expect(first.key, second.key);
      expect(first.key.value, contains('expense|month:2026-05'));
    },
  );

  test(
    'same scope is deduplicated and changed scope starts one read',
    () async {
      final repository = _DelayedRepository();
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(controller.dispose);

      controller.setTimeScope(const AllTimeScope());
      expect(repository.requestedKeys, isEmpty);

      controller.setTimeScope(const YearScope(2026));
      expect(repository.requestedKeys, hasLength(1));
      expect(repository.requestedKeys.single, contains('year:2026'));
    },
  );

  test('a final-target prefetch warms the canonical scope cache', () async {
    final repository = _PrefetchRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      ),
    );
    addTearDown(controller.dispose);
    final target = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const DayScope(
        // March 13 is the complete local-day test fixture used by LogBox.
        LocalDate(year: 2026, month: 3, day: 13),
      ),
    );

    final prefetched = await controller.prefetchFirstDayGroupPage(target);
    controller.setTimeScope(target.timeScope, reason: 'childSettled');

    expect(prefetched?.scopeKey, target.key.value);
    expect(repository.prefetchCalls, 1);
    expect(repository.watchCalls, 0);
    expect(controller.state.scope, target);
    expect(controller.state.result?.entryCount, 4);
  });

  test('latest scope result wins over an older in-flight read', () async {
    final repository = _DelayedRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2025));
    controller.setTimeScope(const YearScope(2026));
    final oldKey = repository.requestedKeys[0];
    final newKey = repository.requestedKeys[1];

    repository.pending[oldKey]!.complete(
      const DashboardLedgerResult(totalMinor: 100),
    );
    await Future<void>.value();
    expect(controller.state.result, isNull);

    repository.pending[newKey]!.complete(
      const DashboardLedgerResult(totalMinor: 200),
    );
    await Future<void>.value();
    expect(controller.state.result?.totalMinor, 200);
    expect(controller.state.scope.timeScope, const YearScope(2026));
  });

  test('reuses a bounded scope cache and refresh invalidates it', () async {
    final repository = _ImmediateRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2026));
    await Future<void>.value();
    controller.setTimeScope(const AllTimeScope());
    await Future<void>.value();
    controller.setTimeScope(const YearScope(2026));
    await Future<void>.value();

    expect(repository.reads, 2);
    expect(controller.state.result?.totalMinor, 100);

    controller.refresh();
    await Future<void>.value();
    expect(repository.reads, 3);
    expect(controller.state.result?.totalMinor, 100);
  });

  test('evicts data cache entries above the 1000 decoded-row budget', () async {
    final repository = _DenseImmediateRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2026));
    await Future<void>.delayed(Duration.zero);
    controller.setTimeScope(const AllTimeScope());
    await Future<void>.delayed(Duration.zero);
    controller.setTimeScope(const YearScope(2026));
    await Future<void>.delayed(Duration.zero);

    // The current result remains visible, but its 1001 rows are too large for
    // the reusable data cache and therefore cannot become a false cache hit.
    expect(repository.reads, 3);
    expect(controller.state.isCacheHit, isFalse);
  });

  test(
    'applies a later dashboard stream emission without manual refresh',
    () async {
      final repository = _StreamingRepository();
      addTearDown(repository.dispose);
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
        ),
      );
      addTearDown(controller.dispose);

      controller.refresh();
      await Future<void>.value();
      expect(repository.requestedKeys, hasLength(1));

      await repository.emit(
        repository.requestedKeys.single,
        const DashboardLedgerResult(
          totalMinor: 68900000,
          entryCount: 100,
          coreRevision: 12,
        ),
      );

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.result?.totalMinor, 68900000);
      expect(controller.state.result?.entryCount, 100);
      expect(
        controller.state.result?.scopeKey,
        controller.state.scope.key.value,
      );
    },
  );

  test(
    'production query result reaches the amount presentation unchanged',
    () async {
      final repository = _StreamingRepository();
      addTearDown(repository.dispose);
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      addTearDown(controller.dispose);

      controller.refresh();
      await Future<void>.value();
      await repository.emit(
        repository.requestedKeys.last,
        const DashboardLedgerResult(
          totalMinor: 68900000,
          entryCount: 94,
          coreRevision: 12,
          scopeKey: 'expense|month:2026-07|categories:|partners:|refinements:',
        ),
      );

      final presentation = SummaryPillPresenter.presentMetrics(
        query: controller.state,
      );

      expect(presentation.formattedAmount, '689000,00 Ft');
      expect(presentation.scopeKey, scope.key.value);
      expect(presentation.totalMinor, 68900000);
      expect(presentation.entryCount, 94);
      expect(presentation.coreRevision, 12);
    },
  );

  test(
    'a native observer ending before its first snapshot ends loading with error',
    () async {
      final controller = CurrentQueryController(
        repository: _CompletedWithoutSnapshotRepository(),
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
        ),
      );
      addTearDown(controller.dispose);

      controller.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isA<StateError>());
    },
  );

  test('a newer scope cancels stale dashboard stream emissions', () async {
    final repository = _StreamingRepository();
    addTearDown(repository.dispose);
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2026));
    controller.setTimeScope(const MonthScope(YearMonth(year: 2026, month: 7)));
    expect(repository.requestedKeys, hasLength(2));

    await repository.emit(
      repository.requestedKeys[0],
      const DashboardLedgerResult(totalMinor: 111),
    );

    expect(controller.state.result, isNull);
    expect(
      controller.state.scope.timeScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
  });

  test(
    'drops a result whose time scope or direction mismatches its query key',
    () async {
      final repository = _StreamingRepository();
      addTearDown(repository.dispose);
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      addTearDown(controller.dispose);

      controller.refresh();
      await Future<void>.value();
      await repository.emit(
        scope.key.value,
        DashboardLedgerResult(
          totalMinor: 1,
          entryCount: 1,
          scopeKey: scope.key.value,
          timeScopeKey: 'month:2026-06',
          direction: LedgerDirection.income.name,
        ),
      );

      expect(controller.state.result, isNull);
      expect(controller.state.isLoading, isTrue);
    },
  );
}
