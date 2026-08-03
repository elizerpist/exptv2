import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';

class _CountingRepository implements DashboardLedgerRepository {
  int watchCount = 0;

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
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
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

      core.query.refresh(reason: 'postSeed');
      await Future<void>.delayed(Duration.zero);
      expect(repository.watchCount, 1);
    },
  );
}
