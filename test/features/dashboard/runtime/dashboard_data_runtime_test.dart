import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_data_runtime.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'bootstrap owns one global revision subscription and one index build',
    () async {
      final repository = _RuntimeRepository();
      final scheduler = _StableFrameScheduler();
      final published = <PreparedDashboardIndex>[];
      final runtime = _runtime(repository, scheduler, published.add);
      addTearDown(runtime.dispose);

      final bootstrap = runtime.bootstrap();
      repository.emitRevision(0);
      await pumpEventQueue();
      expect(repository.indexRequests, isEmpty);

      repository.emitRevision(7);
      await pumpEventQueue();
      expect(repository.revisionListenCount, 1);
      expect(repository.indexRequests, hasLength(1));
      expect(
        repository.indexRequests.single.reason,
        DataAcquisitionReason.bootstrap,
      );

      repository.complete(0);
      final index = await bootstrap;

      expect(index.coreRevision, 7);
      expect(runtime.currentIndex, same(index));
      expect(published, <PreparedDashboardIndex>[index]);
      expect(repository.revisionListenCount, 1);
      expect(runtime.globalRevisionSubscribeCount, 1);
    },
  );

  test(
    'database revision completing during motion waits for one idle frame',
    () async {
      final repository = _RuntimeRepository();
      final scheduler = _StableFrameScheduler();
      final published = <PreparedDashboardIndex>[];
      final runtime = _runtime(repository, scheduler, published.add);
      addTearDown(runtime.dispose);
      final bootstrap = runtime.bootstrap(initialCoreRevision: 1);
      await pumpEventQueue();
      repository.complete(0);
      await bootstrap;
      final initial = runtime.currentIndex;

      runtime.setMotionActive(true);
      repository.emitRevision(2);
      await pumpEventQueue();
      expect(
        repository.indexRequests.last.reason,
        DataAcquisitionReason.databaseRevision,
      );
      repository.complete(0);
      await pumpEventQueue();

      expect(runtime.currentIndex, same(initial));
      expect(runtime.pendingIndex?.coreRevision, 2);
      expect(scheduler.pendingCount, 0);

      runtime.setMotionActive(false);
      expect(scheduler.pendingCount, 1);
      expect(runtime.currentIndex, same(initial));
      scheduler.fireFrame();

      expect(runtime.currentIndex?.coreRevision, 2);
      expect(runtime.pendingIndex, isNull);
      expect(published.map((index) => index.coreRevision), <int>[1, 2]);
    },
  );

  test('newer revision wins and an older generation cannot publish', () async {
    final repository = _RuntimeRepository();
    final scheduler = _StableFrameScheduler();
    final published = <PreparedDashboardIndex>[];
    final runtime = _runtime(repository, scheduler, published.add);
    addTearDown(runtime.dispose);
    final bootstrap = runtime.bootstrap(initialCoreRevision: 1);
    await pumpEventQueue();
    repository.complete(0);
    await bootstrap;

    repository.emitRevision(2);
    await pumpEventQueue();
    repository.emitRevision(3);
    await pumpEventQueue();
    expect(
      repository.indexRequests
          .skip(1)
          .map((request) => request.key.coreRevision),
      <int>[2, 3],
    );

    repository.complete(0, ignoreCancellation: true);
    await pumpEventQueue();
    expect(runtime.currentIndex?.coreRevision, 1);

    repository.complete(0);
    await pumpEventQueue();
    expect(runtime.currentIndex?.coreRevision, 1);
    expect(runtime.pendingIndex?.coreRevision, 3);
    scheduler.fireFrame();
    expect(runtime.currentIndex?.coreRevision, 3);
    expect(runtime.discardedIndexCount, 1);
    expect(published.map((index) => index.coreRevision), <int>[1, 3]);
  });

  test(
    'failed bootstrap retries without replacing the global observer',
    () async {
      final repository = _RuntimeRepository();
      final scheduler = _StableFrameScheduler();
      final published = <PreparedDashboardIndex>[];
      final runtime = _runtime(repository, scheduler, published.add);
      addTearDown(runtime.dispose);

      final first = runtime.bootstrap(initialCoreRevision: 1);
      await pumpEventQueue();
      repository.fail(0);
      await expectLater(first, throwsStateError);

      final retry = runtime.bootstrap(initialCoreRevision: 1);
      await pumpEventQueue();
      repository.complete(0);
      final index = await retry;

      expect(index.coreRevision, 1);
      expect(repository.indexRequests, hasLength(2));
      expect(repository.revisionListenCount, 1);
      expect(runtime.globalRevisionSubscribeCount, 1);
    },
  );

  test(
    'new revision supersedes a bootstrap build before first publish',
    () async {
      final repository = _RuntimeRepository();
      final scheduler = _StableFrameScheduler();
      final published = <PreparedDashboardIndex>[];
      final runtime = _runtime(repository, scheduler, published.add);
      addTearDown(runtime.dispose);

      final bootstrap = runtime.bootstrap(initialCoreRevision: 1);
      await pumpEventQueue();
      repository.emitRevision(2);
      await pumpEventQueue();
      repository.complete(0, ignoreCancellation: true);
      await pumpEventQueue();
      expect(
        repository.indexRequests.map((request) => request.key.coreRevision),
        <int>[1, 2],
      );
      repository.complete(0);

      final index = await bootstrap;
      expect(index.coreRevision, 2);
      expect(published.single.coreRevision, 2);
      expect(repository.revisionListenCount, 1);
    },
  );

  test('index and page acquisition reasons fail closed when crossed', () {
    expect(
      DataAcquisitionReason.explicitCommittedVerticalPaging.requireIndexBuild,
      throwsStateError,
    );
    expect(DataAcquisitionReason.bootstrap.requirePageRead, throwsStateError);
    expect(
      DataAcquisitionReason.databaseRevision.requirePageRead,
      throwsStateError,
    );
  });

  test(
    'query preparation is latest-wins and has no implicit publication',
    () async {
      final repository = _RuntimeRepository();
      final scheduler = _StableFrameScheduler();
      final published = <PreparedDashboardIndex>[];
      final runtime = _runtime(repository, scheduler, published.add);
      addTearDown(runtime.dispose);
      final bootstrap = runtime.bootstrap(initialCoreRevision: 1);
      await pumpEventQueue();
      repository.complete(0);
      await bootstrap;

      final queryTemplate = DashboardIndexRequestTemplate(
        filterScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const AllTimeScope(),
          temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>[
            QueryPeriodSelection.month(2026, 2),
            QueryPeriodSelection.month(2026, 8),
          ]),
        ),
        pageSize: 24,
        initialYear: 2026,
        yearWindowRadius: 12,
      );

      final prepared = runtime.prepareQuery(queryTemplate);
      await pumpEventQueue();
      expect(repository.indexRequests.last.reason, DataAcquisitionReason.query);
      expect(
        repository.indexRequests.last.filterScope.temporalFilter.isRestrictive,
        isTrue,
      );
      repository.complete(0);
      final preparedIndex = await prepared;

      expect(published, hasLength(1));
      expect(runtime.currentIndex?.key.temporalFilterKey, 'all');
      expect(
        runtime.requestTemplate.filterScope.temporalFilter.isRestrictive,
        isFalse,
        reason:
            'A prepared-but-unpublished query must not affect future '
            'runtime revision builds.',
      );

      runtime.commitPreparedQuery(preparedIndex, queryTemplate);
      expect(runtime.requestTemplate, same(queryTemplate));
    },
  );
}

DashboardDataRuntime _runtime(
  _RuntimeRepository repository,
  _StableFrameScheduler scheduler,
  void Function(PreparedDashboardIndex) onPublished,
) => DashboardDataRuntime(
  revisionObserver: GlobalCoreRevisionObserver(repository: repository),
  indexBuilder: PreparedDashboardIndexBuilder(repository: repository),
  requestTemplate: DashboardIndexRequestTemplate(
    filterScope: CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const AllTimeScope(),
    ),
    pageSize: 24,
    initialYear: 2026,
    yearWindowRadius: 12,
  ),
  stableFrameScheduler: scheduler,
  onIndexPublished: onPublished,
);

final class _StableFrameScheduler implements DashboardStableFrameScheduler {
  final List<void Function()> _callbacks = [];

  int get pendingCount => _callbacks.length;

  @override
  void scheduleStableFrame(void Function() callback) =>
      _callbacks.add(callback);

  void fireFrame() {
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }
}

final class _PendingIndex {
  const _PendingIndex(this.request, this.token, this.completer);

  final PreparedDashboardIndexRequest request;
  final DashboardIndexPreparationToken token;
  final Completer<PreparedDashboardIndex> completer;
}

final class _RuntimeRepository
    implements
        PreparedDashboardIndexRepository,
        DashboardCoreRevisionRepository {
  _RuntimeRepository() {
    _revisions = StreamController<int>.broadcast(
      onListen: () => revisionListenCount += 1,
      onCancel: () => revisionCancelCount += 1,
    );
  }

  late final StreamController<int> _revisions;
  int revisionListenCount = 0;
  int revisionCancelCount = 0;
  final List<PreparedDashboardIndexRequest> indexRequests = [];
  final List<_PendingIndex> _pending = [];

  void emitRevision(int revision) => _revisions.add(revision);

  @override
  Stream<int> watchCoreRevision() => _revisions.stream;

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    indexRequests.add(request);
    final completer = Completer<PreparedDashboardIndex>();
    _pending.add(_PendingIndex(request, token, completer));
    return completer.future;
  }

  void complete(int index, {bool ignoreCancellation = false}) {
    final pending = _pending.removeAt(index);
    if (!ignoreCancellation && pending.token.isCancelled) {
      pending.completer.completeError(StateError('cancelled'));
      return;
    }
    pending.completer.complete(
      PreparedDashboardIndex.complete(
        key: pending.request.key,
        frames: const {},
        catalogs: const {},
        generation: pending.token.generation,
        contentDigest: Object.hash(
          pending.request.key,
          pending.token.generation,
        ),
        preparedAt: DateTime.utc(2026, 8, 6),
        buildMetrics: const PreparedDashboardIndexBuildMetrics.synthetic(),
      ),
    );
  }

  void fail(int index) {
    final pending = _pending.removeAt(index);
    pending.completer.completeError(StateError('synthetic failure'));
  }
}
