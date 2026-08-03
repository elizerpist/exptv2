import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
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

  DashboardLedgerResult _result(scope) => DashboardLedgerResult(
    totalMinor: scope.direction == LedgerDirection.income ? 70700000 : 68900000,
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
      repository.requestedScopes.last,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
  });

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
