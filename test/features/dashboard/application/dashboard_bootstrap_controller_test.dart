import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_bootstrap_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  test(
    'keeps the dashboard gated until presentation assets are prepared',
    () async {
      final assetsReady = Completer<void>();
      var dataBootstrapStarted = false;
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: AllTimeScope(),
      );
      final preparedFrame = runtimeTestFrame(scope, revision: 1);
      final frame = DashboardVisibleFrame.fromPrepared(
        preparedFrame,
        parentQueryKey: preparedFrame.parentQueryKey,
        plane: TimePlane.sum,
        railOpen: false,
        semanticIndex: 0,
        childLabel: '2026',
        navigationEpoch: 1,
        presentationEpoch: 1,
        frameGeneration: 1,
        mode: DashboardVisibleMode.committed,
      );
      final controller = DashboardBootstrapController(
        preparePresentationAssets: () => assetsReady.future,
        bootstrap: () async {
          dataBootstrapStarted = true;
          return frame;
        },
      );

      final start = controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isReady, isFalse);
      expect(dataBootstrapStarted, isFalse);

      assetsReady.complete();
      await start;

      expect(dataBootstrapStarted, isTrue);
      expect(controller.isReady, isTrue);
      controller.dispose();
    },
  );
}
