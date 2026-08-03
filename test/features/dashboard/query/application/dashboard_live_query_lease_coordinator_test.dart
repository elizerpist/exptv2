import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test('only the latest pending lease is activated', () async {
    final coordinator = DashboardLiveQueryLeaseCoordinator(
      quiescence: const Duration(milliseconds: 10),
    );
    final activations = <int>[];
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
    );

    coordinator.request(
      scope: scope,
      generation: 1,
      activate: () => activations.add(1),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    coordinator.request(
      scope: scope,
      generation: 2,
      activate: () => activations.add(2),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(activations, <int>[2]);
    expect(coordinator.hasPendingRequest, isFalse);
  });

  test('cancel prevents a pending lease activation', () async {
    final coordinator = DashboardLiveQueryLeaseCoordinator(
      quiescence: const Duration(milliseconds: 10),
    );
    var activated = false;
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const YearScope(2026),
    );

    coordinator.request(
      scope: scope,
      generation: 1,
      activate: () => activated = true,
    );
    coordinator.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(activated, isFalse);
    expect(coordinator.hasPendingRequest, isFalse);
  });
}
