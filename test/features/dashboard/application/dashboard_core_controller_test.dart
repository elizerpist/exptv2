import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _RecordingDashboardRepository implements DashboardLedgerRepository {
  final requestedScopes = <LedgerTimeScope>[];
  int watchCount = 0;

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    requestedScopes.add(scope.timeScope);
    return const DashboardLedgerResult(totalMinor: 0);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
    requestedScopes.add(scope.timeScope);
    yield const DashboardLedgerResult(totalMinor: 0);
  }
}

class _DirectionDashboardRepository implements DashboardLedgerRepository {
  int reads = 0;
  int watches = 0;

  DashboardLedgerResult _result(CurrentLedgerQueryScope scope) =>
      DashboardLedgerResult(
        totalMinor: scope.direction == LedgerDirection.income
            ? 70700000
            : 68900000,
        entryCount: scope.direction == LedgerDirection.income ? 6 : 94,
        coreRevision: 1,
      );

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads += 1;
    return _result(scope);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watches += 1;
    yield _result(scope);
  }
}

class _ColdParentDashboardRepository
    implements DashboardLedgerRepository, DashboardChildPreviewRepository {
  _ColdParentDashboardRepository(this.results);

  final Map<String, DashboardLedgerResult> results;
  final childBundleRequests = <String>[];

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async =>
      results[scope.key.value] ??
      DashboardLedgerResult(
        totalMinor: 0,
        entryCount: 0,
        coreRevision: 1,
        scopeKey: scope.key.value,
      );

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => Stream.fromFuture(read(scope, pageSize: pageSize, after: after));

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) async {
    childBundleRequests.add(request.parentScope.key.value);
    return DashboardChildPreviewBundle(
      parentScope: request.parentScope,
      childPeriod: request.childPeriod,
      coreRevision: 1,
      childrenByQueryKey: const {},
    );
  }
}

void main() {
  test('forwards every owned child state notification to core listeners', () {
    final core = DashboardCoreController();
    var notifications = 0;
    core.addListener(() => notifications += 1);

    core.expansion.setProgress(1);
    core.rail.setExpanded(true);
    core.transactionDirection.select(TransactionDirection.expense);

    expect(notifications, 3);
    core.dispose();
  });

  test('demo month navigation retargets the production query scope', () async {
    final repository = _RecordingDashboardRepository();
    final core = DashboardCoreController(
      queryRepository: repository,
      initialDate: DateTime(2026, 8, 2),
    );
    addTearDown(core.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(
      repository.requestedScopes.last,
      const MonthScope(YearMonth(year: 2026, month: 8)),
    );

    core.rail.navigateToMonth(const YearMonth(year: 2026, month: 7));
    await Future<void>.delayed(Duration.zero);

    expect(
      core.query.state.scope.timeScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    expect(
      repository.requestedScopes,
      contains(const MonthScope(YearMonth(year: 2026, month: 7))),
      reason:
          'the canonical July request must be present even when the shared '
          'background coordinator subsequently prewarms June/August',
    );
  });

  test(
    'cold parent navigation commits one complete target bundle without a dash',
    () async {
      final may = DashboardLedgerResult(
        totalMinor: 61200000,
        entryCount: 94,
        coreRevision: 1,
        scopeKey: 'income|month:2026-05|categories:|partners:|refinements:',
      );
      final april = DashboardLedgerResult(
        totalMinor: 73500000,
        entryCount: 88,
        coreRevision: 1,
        scopeKey: 'income|month:2026-04|categories:|partners:|refinements:',
      );
      final repository = _ColdParentDashboardRepository({
        may.scopeKey!: may,
        april.scopeKey!: april,
      });
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 5, 14),
        autoStartQuery: true,
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final mayKey = core.query.state.scope.key;
      expect(core.presentationStore.activeSnapshot?.queryKey, mayKey);
      expect(core.presentationStore.activeSnapshot?.totalMinor, 61200000);
      expect(core.presentationStore.activeSnapshot?.entryCount, 94);
      final publishCountBefore =
          core.presentationStore.visiblePresentationPublishCount;

      core.rail.navigateToMonth(const YearMonth(year: 2026, month: 4));

      // Navigation has moved, but the outgoing complete bundle owns the
      // visible frame until the target parent bundle is ready.
      expect(core.presentationStore.activeSnapshot?.queryKey, mayKey);
      expect(core.presentationStore.activeSnapshot?.totalMinor, 61200000);
      expect(core.presentationStore.activeSnapshot?.entryCount, 94);
      expect(core.presentationStore.stalePlaceholderPublishCount, 0);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final aprilKey = core.query.state.scope.key;
      expect(aprilKey.value, april.scopeKey);
      expect(core.presentationStore.activeSnapshot?.queryKey, aprilKey);
      expect(core.presentationStore.activeSnapshot?.totalMinor, 73500000);
      expect(core.presentationStore.activeSnapshot?.entryCount, 88);
      expect(
        core.presentationStore.visiblePresentationPublishCount,
        publishCountBefore + 1,
      );
      expect(core.presentationStore.stalePlaceholderPublishCount, 0);
      expect(repository.childBundleRequests, contains(april.scopeKey));
      expect(core.rail.state.plane, TimePlane.month);
    },
  );

  test(
    'rail preview does not notify the dashboard root or create a query',
    () async {
      final repository = _RecordingDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);
      final watchCountBeforePreviews = repository.watchCount;
      var rootNotifications = 0;
      core.addListener(() => rootNotifications += 1);

      for (var index = 0; index < 100; index += 1) {
        core.rail.previewChildLogicalIndex(index);
      }

      expect(repository.watchCount, watchCountBeforePreviews);
      expect(rootNotifications, 0);
      expect(core.presentationStore.repositoryReadCountDuringMotion, 0);
      expect(core.presentationStore.nativeCallCountDuringMotion, 0);
      expect(core.presentationStore.watchSubscribeCountDuringMotion, 0);
      expect(core.presentationStore.programmaticScrollCountDuringMotion, 0);
    },
  );

  test(
    'direction toggle atomically selects amount and count from one snapshot',
    () async {
      final repository = _DirectionDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(
        core.presentationStore.activeSnapshot?.scope?.direction,
        LedgerDirection.income,
      );
      expect(core.presentationStore.activeSnapshot?.totalMinor, 70700000);
      expect(core.presentationStore.activeSnapshot?.entryCount, 6);

      core.transactionDirection.select(TransactionDirection.expense);
      await Future<void>.delayed(Duration.zero);

      final snapshot = core.presentationStore.activeSnapshot;
      expect(snapshot?.scope?.direction, LedgerDirection.expense);
      expect(snapshot?.totalMinor, 68900000);
      expect(snapshot?.entryCount, 94);
      expect(snapshot?.queryKey, core.query.state.scope.key);
    },
  );
}
