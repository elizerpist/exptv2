import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _RecordingDashboardRepository implements DashboardLedgerRepository {
  final requestedScopes = <LedgerTimeScope>[];

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
    requestedScopes.add(scope.timeScope);
    yield const DashboardLedgerResult(totalMinor: 0);
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
}
