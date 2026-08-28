import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_auto_reset_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  test('reset plans mode then ordinary year and month selector targets', () {
    final plan = DashboardSummaryAutoResetPlan.resolve(
      plane: TimePlane.month,
      isRailOpen: true,
      year: 2022,
      month: 2,
      logicalToday: const LocalDate(year: 2026, month: 8, day: 28),
    );

    expect(plan.steps, const <DashboardSummaryAutoResetStep>[
      DashboardSummaryAutoResetStep.level(TimePlane.month, false),
      DashboardSummaryAutoResetStep.year(2026),
      DashboardSummaryAutoResetStep.month(8),
    ]);
  });

  test(
    'reset skips already-correct dimensions and never creates a day target',
    () {
      final plan = DashboardSummaryAutoResetPlan.resolve(
        plane: TimePlane.year,
        isRailOpen: false,
        year: 2026,
        month: 8,
        logicalToday: const LocalDate(year: 2026, month: 8, day: 28),
      );

      expect(plan.steps, const <DashboardSummaryAutoResetStep>[
        DashboardSummaryAutoResetStep.level(TimePlane.month, false),
      ]);
    },
  );

  test(
    'one reset sequencer cancels stale steps before a later interaction',
    () async {
      final gate = Completer<void>();
      final started = <DashboardSummaryAutoResetStep>[];
      final controller = DashboardSummaryAutoResetController();
      final plan = DashboardSummaryAutoResetPlan.resolve(
        plane: TimePlane.month,
        isRailOpen: true,
        year: 2022,
        month: 2,
        logicalToday: const LocalDate(year: 2026, month: 8, day: 28),
      );

      final running = controller.start(
        plan: plan,
        runStep: (step) async {
          started.add(step);
          if (step.kind == DashboardSummaryAutoResetStepKind.level) {
            await gate.future;
          }
        },
      );
      await Future<void>.delayed(Duration.zero);
      controller.cancel();
      gate.complete();
      await running;

      expect(started, hasLength(1));
      expect(controller.phase, DashboardSummaryAutoResetPhase.cancelled);
    },
  );

  test(
    'cancelling a waiting selector command prevents a late mounted tick',
    () async {
      final registry = DashboardSummaryAutoResetMotionRegistry();
      var lateRuns = 0;

      final waiting = registry.run(
        const DashboardSummaryAutoResetStep.year(2026),
      );
      await Future<void>.delayed(Duration.zero);
      registry.cancelMountedMotion();
      registry.attach(
        kind: DashboardSummaryAutoResetStepKind.year,
        runner: (_) async => lateRuns += 1,
        cancelMotion: () {},
      );
      await waiting;

      expect(lateRuns, 0);
    },
  );
}
