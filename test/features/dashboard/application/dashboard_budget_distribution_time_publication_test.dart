import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'time navigation commits only after the exact Budget Card2 drawable is ready',
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

      expect(
        core.navigation.state.plane,
        TimePlane.month,
        reason: 'the semantic period may not outrun its renderer-ready Card2.',
      );

      ready.complete(true);
      await pumpEventQueue();

      expect(core.navigation.state.plane, TimePlane.year);
    },
  );
}
