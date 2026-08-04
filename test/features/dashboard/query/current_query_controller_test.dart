import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
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

class _StableRevisionRepository
    implements DashboardLedgerRepository, DashboardCoreRevisionRepository {
  final revisions = StreamController<int>.broadcast();
  int reads = 0;
  int exactWatchSubscriptions = 0;
  int revisionSubscriptions = 0;
  int revision = 1;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads += 1;
    return DashboardLedgerResult(
      totalMinor: revision * 100,
      entryCount: revision,
      coreRevision: revision,
      scopeKey: scope.key.value,
      direction: scope.direction.name,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    exactWatchSubscriptions += 1;
    return const Stream<DashboardLedgerResult>.empty();
  }

  @override
  Stream<int> watchCoreRevision() {
    revisionSubscriptions += 1;
    return revisions.stream;
  }

  Future<void> emitRevision(int value) async {
    revision = value;
    revisions.add(value);
    await Future<void>.value();
  }

  Future<void> dispose() => revisions.close();
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

  test(
    'fresh cached scope promotion does not request a delayed live lease',
    () async {
      final repository = _ImmediateRepository();
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
        liveLeaseQuiescence: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.setTimeScope(const YearScope(2025));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      controller.setTimeScope(const YearScope(2026));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.reads, 2);

      controller.setTimeScope(const YearScope(2025));

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.scope.timeScope, const YearScope(2025));
      expect(controller.state.result?.totalMinor, 100);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        repository.reads,
        2,
        reason: 'A fresh cache hit must not restart repository/native work.',
      );
    },
  );

  test(
    'stable revision repositories use one-shot reads, not exact watches',
    () async {
      final repository = _StableRevisionRepository();
      addTearDown(repository.dispose);
      final counters = DashboardPerformanceCounters();
      final controller = CurrentQueryController(
        repository: repository,
        performanceCounters: counters,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const YearScope(2026),
        ),
      );
      addTearDown(controller.dispose);

      controller.refresh(reason: 'testInitial');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.result?.totalMinor, 100);
      expect(repository.reads, 1);
      expect(repository.exactWatchSubscriptions, 0);
      expect(repository.revisionSubscriptions, 1);

      controller.refresh(reason: 'testManualRefresh');
      await Future<void>.delayed(Duration.zero);

      expect(repository.reads, 2);
      expect(repository.exactWatchSubscriptions, 0);
      expect(repository.revisionSubscriptions, 1);
      expect(counters.value(DashboardPerformanceMetric.repositoryRead), 2);
      expect(counters.value(DashboardPerformanceMetric.oneShotRead), 2);
      expect(counters.value(DashboardPerformanceMetric.exactWatchStart), 0);
      expect(
        counters.value(DashboardPerformanceMetric.coreRevisionSubscription),
        1,
      );
    },
  );

  test(
    'core revision refresh waits until the active motion epoch ends',
    () async {
      final repository = _StableRevisionRepository();
      addTearDown(repository.dispose);
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const YearScope(2026),
        ),
        liveLeaseQuiescence: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.refresh(reason: 'testInitial');
      await Future<void>.delayed(Duration.zero);
      expect(repository.reads, 1);

      controller.invalidatePendingLiveLease(motionEpoch: 7);
      await repository.emitRevision(2);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.reads, 1);

      controller.resumeBackgroundAfterMotion(motionEpoch: 7);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.reads, 2);
      expect(controller.state.result?.totalMinor, 200);
      expect(repository.exactWatchSubscriptions, 0);
      expect(repository.revisionSubscriptions, 1);
    },
  );

  test(
    'core revision delegates one complete refresh after the matching motion idle',
    () async {
      final repository = _StableRevisionRepository();
      addTearDown(repository.dispose);
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const YearScope(2026),
        ),
      );
      addTearDown(controller.dispose);

      controller.refresh(reason: 'testInitial');
      await Future<void>.delayed(Duration.zero);
      final requestedRevisions = <int>[];
      controller.setCoreRevisionRefreshHandler((revision) async {
        requestedRevisions.add(revision);
        final scope = controller.state.scope;
        return controller.commitPreparedResult(
          scope,
          DashboardLedgerResult(
            totalMinor: revision * 100,
            entryCount: revision,
            coreRevision: revision,
            scopeKey: scope.key.value,
            direction: scope.direction.name,
          ),
          reason: 'completeBundleRevisionRefresh',
        );
      });

      controller.invalidatePendingLiveLease(motionEpoch: 11);
      await repository.emitRevision(2);
      await Future<void>.delayed(Duration.zero);

      expect(requestedRevisions, isEmpty);
      expect(repository.reads, 1);
      expect(controller.state.result?.coreRevision, 1);

      controller.resumeBackgroundAfterMotion(motionEpoch: 10);
      await Future<void>.delayed(Duration.zero);
      expect(requestedRevisions, isEmpty);

      controller.resumeBackgroundAfterMotion(motionEpoch: 11);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(requestedRevisions, <int>[2]);
      expect(repository.reads, 1);
      expect(controller.state.result?.coreRevision, 2);
      expect(controller.pendingCoreRevision, isNull);
      expect(controller.exactWatchStartCount, 0);
    },
  );

  test(
    'prepared exact result commits without repository or watch work',
    () async {
      final repository = _ImmediateRepository();
      final initialScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final targetScope = initialScope.copyWith(
        timeScope: const YearScope(2026),
      );
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: initialScope,
        liveLeaseQuiescence: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      final committed = controller.commitPreparedResult(
        targetScope,
        DashboardLedgerResult(
          totalMinor: 12345,
          entryCount: 6,
          coreRevision: 7,
          scopeKey: targetScope.key.value,
        ),
        reason: 'childSettled',
      );

      expect(committed, isTrue);
      expect(controller.state.scope, targetScope);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.result?.totalMinor, 12345);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.reads, 0);
    },
  );

  test('prepared result with a different QueryKey is rejected atomically', () {
    final repository = _ImmediateRepository();
    final initialScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
    );
    final targetScope = initialScope.copyWith(timeScope: const YearScope(2026));
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: initialScope,
    );
    addTearDown(controller.dispose);

    final committed = controller.commitPreparedResult(
      targetScope,
      const DashboardLedgerResult(
        totalMinor: 12345,
        entryCount: 6,
        coreRevision: 7,
        scopeKey: 'expense|year:2025|categories:|partners:|refinements:',
      ),
      reason: 'childSettled',
    );

    expect(committed, isFalse);
    expect(controller.state.scope, initialScope);
    expect(controller.state.result, isNull);
    expect(repository.reads, 0);
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

  test('identical fresh result does not notify the query root twice', () async {
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

    var notifications = 0;
    controller.addListener(() => notifications += 1);
    const result = DashboardLedgerResult(
      totalMinor: 68900000,
      entryCount: 94,
      coreRevision: 12,
    );
    await repository.emit(repository.requestedKeys.single, result);
    expect(notifications, 1);
    await repository.emit(repository.requestedKeys.single, result);
    expect(notifications, 1);
  });

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
    'old committed result warms cache without notifying a different child preview',
    () async {
      final repository = _StreamingRepository();
      addTearDown(repository.dispose);
      final parent = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      final child = parent.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 14)),
      );
      final store = DashboardPresentationStore();
      addTearDown(store.dispose);
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.month,
          parentQueryKey: parent.key,
          childQueryKey: child.key,
          railOpen: true,
          direction: parent.direction,
          presentationEpoch: 2,
        ),
      );
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: parent,
        presentationStore: store,
      );
      addTearDown(controller.dispose);
      controller.refresh();
      await Future<void>.value();

      var notifications = 0;
      controller.addListener(() => notifications += 1);
      await repository.emit(
        repository.requestedKeys.single,
        DashboardLedgerResult(
          totalMinor: 123,
          entryCount: 1,
          coreRevision: 1,
          scopeKey: parent.key.value,
        ),
      );

      expect(controller.state.result?.totalMinor, 123);
      expect(notifications, 0);
      expect(store.lateCommittedResultCachedCount, 1);
      expect(store.activeSnapshot, isNull);
    },
  );

  test(
    'rapid scope commits coalesce live lease activation to the latest scope',
    () async {
      final repository = _StreamingRepository();
      addTearDown(repository.dispose);
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
        ),
        liveLeaseQuiescence: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.refresh();
      await Future<void>.value();
      expect(repository.requestedKeys, hasLength(1));

      controller.setTimeScope(const YearScope(2025));
      controller.setTimeScope(const YearScope(2026));
      expect(repository.requestedKeys, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.requestedKeys, hasLength(2));
      expect(repository.requestedKeys.last, contains('year:2026'));
      expect(controller.state.scope.timeScope, const YearScope(2026));
    },
  );
}
