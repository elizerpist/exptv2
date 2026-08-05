import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_bootstrap_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _CountingRepository implements DashboardLedgerRepository {
  int watchCount = 0;
  CurrentLedgerQueryScope? lastWatchedScope;

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    return const DashboardLedgerResult(totalMinor: 1, entryCount: 1);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
    lastWatchedScope = scope;
    yield const DashboardLedgerResult(totalMinor: 1, entryCount: 1);
  }
}

class _SeedBootstrapOverlapRepository
    implements DashboardLedgerRepository, DashboardChildPreviewRepository {
  final Completer<DashboardChildPreviewBundle> _childBundle =
      Completer<DashboardChildPreviewBundle>();
  int watchCount = 0;
  int childBundleReadCount = 0;
  final List<CurrentLedgerQueryScope> readScopes = <CurrentLedgerQueryScope>[];
  final List<DashboardChildPreviewBundleRequest> childBundleRequests =
      <DashboardChildPreviewBundleRequest>[];
  DashboardChildPreviewBundleRequest? childBundleRequest;

  DashboardLedgerResult _result(CurrentLedgerQueryScope scope) =>
      DashboardLedgerResult(
        totalMinor: scope.direction == LedgerDirection.income
            ? 70700000
            : 68900000,
        entryCount: scope.direction == LedgerDirection.income ? 6 : 94,
        coreRevision: 1,
        scopeKey: scope.key.value,
        timeScopeKey: scope.timeScope.canonicalKey,
        direction: scope.direction.name,
      );

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    readScopes.add(scope);
    return _result(scope);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
    yield _result(scope);
  }

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) {
    childBundleReadCount += 1;
    childBundleRequests.add(request);
    childBundleRequest = request;
    return _childBundle.future;
  }

  void completeChildBundle() {
    final request = childBundleRequest!;
    _childBundle.complete(
      DashboardChildPreviewBundle(
        parentScope: request.parentScope,
        childPeriod: request.childPeriod,
        coreRevision: 1,
        childrenByQueryKey: const {},
      ),
    );
  }
}

void main() {
  test(
    'seed-gated startup does not query before the seed commit boundary',
    () async {
      final repository = _CountingRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        autoStartQuery: false,
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(repository.watchCount, 0);

      core.startQuery(reason: 'postSeed');
      await Future<void>.delayed(Duration.zero);
      expect(repository.watchCount, 1);
    },
  );

  test(
    'seed-gated startup blocks parent bundle preparation before seed commit',
    () async {
      final repository = _CountingRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        autoStartQuery: false,
        seedReady: false,
      );
      addTearDown(core.dispose);

      final bundle = await core.summaryMetrics.prepareParentDisplayBundle(
        parentScope: core.query.state.scope,
        childPeriod: TimeChildPeriod.day,
        source: 'preSeedTest',
      );

      expect(bundle, isNull);
      expect(repository.watchCount, 0);
      expect(core.summaryMetrics.isSeedReady, isFalse);

      core.startQuery(reason: 'postSeed');
      await Future<void>.delayed(Duration.zero);

      expect(core.summaryMetrics.isSeedReady, isTrue);
      expect(repository.watchCount, 1);
    },
  );

  test('seed-gated startup reads the scope selected during the seed', () async {
    final repository = _CountingRepository();
    final core = DashboardCoreController(
      queryRepository: repository,
      initialDate: DateTime(2026, 8, 2),
      autoStartQuery: false,
    );
    addTearDown(core.dispose);

    core.rail.navigateToMonth(const YearMonth(year: 2026, month: 7));
    await Future<void>.delayed(Duration.zero);

    expect(repository.watchCount, 0);
    core.startQuery(reason: 'postSeed');
    await Future<void>.delayed(Duration.zero);

    expect(repository.watchCount, 1);
    expect(
      repository.lastWatchedScope?.timeScope,
      core.rail.state.effectiveScope,
    );
    expect(core.query.state.scope.timeScope, core.rail.state.effectiveScope);
  });

  test(
    'bootstrap completes a snapshot-less seed prewarm with the parent snapshot',
    () async {
      final repository = _SeedBootstrapOverlapRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 8, 2),
        autoStartQuery: false,
        seedReady: false,
      );
      addTearDown(core.dispose);
      final bootstrap = DashboardBootstrapController(
        store: core.presentationStore,
        readInitialBundle: core.readParentDisplayBundleForBootstrap,
      );
      addTearDown(bootstrap.dispose);

      core.rail.navigateToMonth(const YearMonth(year: 2026, month: 7));
      core.startQuery(reason: 'postSeed');
      final startup = bootstrap.start();

      await core.query.waitForCurrentSnapshot();
      await pumpEventQueue(times: 2);
      expect(repository.childBundleReadCount, 1);
      expect(repository.watchCount, 1);

      repository.completeChildBundle();
      await startup.timeout(const Duration(seconds: 1));

      expect(bootstrap.phase, DashboardBootstrapPhase.ready);
      expect(bootstrap.snapshot?.totalMinor, 70700000);
      expect(bootstrap.snapshot?.entryCount, 6);
      expect(
        bootstrap.snapshot?.scope?.timeScope.canonicalKey,
        'month:2026-07',
      );
      expect(
        repository.childBundleRequests.where(
          (request) => request.parentScope.key == bootstrap.snapshot?.queryKey,
        ),
        hasLength(1),
      );
      expect(repository.watchCount, 1);
      expect(
        repository.readScopes.where(
          (scope) => scope.key == bootstrap.snapshot?.queryKey,
        ),
        isEmpty,
      );
      expect(
        core.parentBundleRegistry.pinnedKey?.parentQueryKey,
        bootstrap.snapshot?.queryKey,
      );
    },
  );
}
