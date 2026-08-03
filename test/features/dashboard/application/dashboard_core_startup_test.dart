import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
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
}
