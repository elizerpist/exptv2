import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'time navigation commits before asynchronous Budget Card2 preparation completes',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      final ready = Completer<bool>();
      core.attachBudgetDistributionTimePublicationPreparer(
        prepare: (_) => ready.future,
      );

      core.navigatePlane(finer: false);
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.year);

      ready.complete(true);
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.year);
    },
  );

  test(
    'Segmented motion defers cache-miss Card2 projection until the selector is idle',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialPlane: TimePlane.month,
        initialCoreRevision: 1,
      );
      addTearDown(core.dispose);
      await core.bootstrap();
      var prepareCalls = 0;
      core.attachBudgetDistributionTimePublicationPreparer(
        prepare: (_) {
          prepareCalls += 1;
          return Future<bool>.value(true);
        },
      );

      core.beginSegmentedSummaryMotion();
      core.navigatePlane(finer: false);
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.year);
      expect(
        prepareCalls,
        0,
        reason:
            'A cache-miss Canvas-bank build is maintenance work and cannot '
            'run between ballistic Segmented crossings.',
      );

      core.endSegmentedSummaryMotion();
      await pumpEventQueue();

      expect(prepareCalls, 1);
    },
  );
}
