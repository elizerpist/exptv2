import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/application/dashboard_startup_warmup_coordinator.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('defers non-critical startup phases until rail or header motion is idle',
      () async {
    final motion = ValueNotifier(true);
    addTearDown(motion.dispose);
    final events = <String>[];
    final coordinator = DashboardStartupWarmupCoordinator(
      ensureCurrentBundle: () async {
        events.add('current');
        return _bundle();
      },
      warmCurrentAndAdjacentCategoryAssets: (_) async {
        events.add('assets');
      },
      prewarmAdjacentBundles: (_) async {
        events.add('adjacent');
      },
      isCriticalMotionActive: () => motion.value,
      motionListenable: motion,
    );
    addTearDown(coordinator.dispose);

    final running = coordinator.start();
    await Future<void>.delayed(Duration.zero);

    expect(events, ['current']);
    expect(coordinator.phase, DashboardStartupWarmupPhase.currentBundleReady);

    motion.value = false;
    await running;

    expect(events, ['current', 'assets', 'adjacent']);
    expect(coordinator.phase, DashboardStartupWarmupPhase.complete);
  });
}

DashboardParentDisplayBundle _bundle() {
  final parent = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
  );
  return DashboardParentDisplayBundle.completeFinite(
    parentScope: parent,
    plane: TimePlane.month,
    coreRevision: 1,
    expectedChildren: const <CurrentLedgerQueryScope>[],
    snapshots: const <DashboardLogPreviewSnapshot>[],
  );
}
