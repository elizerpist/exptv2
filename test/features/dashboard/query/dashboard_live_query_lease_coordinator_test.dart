import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_motion.dart';

CurrentLedgerQueryScope _scope(int year) => CurrentLedgerQueryScope(
  direction: LedgerDirection.expense,
  timeScope: YearScope(year),
);

void main() {
  test('rapid committed intents activate only the latest idle lease', () async {
    final activated = <CurrentLedgerQueryScope>[];
    final coordinator = DashboardLiveQueryLeaseCoordinator(
      quiescence: Duration.zero,
      activateLease: activated.add,
    );
    addTearDown(coordinator.dispose);

    for (var year = 2020; year != 2030; year += 1) {
      coordinator.request(_scope(year), motionEpoch: year);
    }
    await Future<void>.delayed(Duration.zero);

    expect(activated, <CurrentLedgerQueryScope>[_scope(2029)]);
  });

  test(
    'active native motion prevents a pending lease from activating',
    () async {
      final activated = <CurrentLedgerQueryScope>[];
      final coordinator = DashboardLiveQueryLeaseCoordinator(
        quiescence: Duration.zero,
        activateLease: activated.add,
      );
      addTearDown(coordinator.dispose);

      coordinator.onMotion(
        const RailMotionSnapshot(
          epoch: 1,
          origin: RailMotionOrigin.nativeBallistic,
          state: RailMotionState.ballistic,
        ),
      );
      coordinator.request(_scope(2026), motionEpoch: 1);
      await Future<void>.delayed(Duration.zero);

      expect(activated, isEmpty);
    },
  );
}
