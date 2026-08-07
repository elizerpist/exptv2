import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_readiness.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  test(
    'ready waits for index resources and the visible LogBox frame',
    () async {
      final indexReady = Completer<void>();
      final resourcesReady = Completer<void>();
      final phases = <DashboardInteractionReadinessPhase>[];
      final frame = _frame();
      var resourceDpr = 0.0;
      final readiness = DashboardInteractionReadiness(
        buildInitialFrame: () async {
          await indexReady.future;
          return frame;
        },
        prepareRenderCriticalResources: (devicePixelRatio) async {
          resourceDpr = devicePixelRatio;
          await resourcesReady.future;
        },
      );
      addTearDown(readiness.dispose);
      readiness.addListener(() => phases.add(readiness.phase));

      var startCompleted = false;
      final start = readiness
          .start(devicePixelRatio: 3)
          .whenComplete(() => startCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(readiness.phase, DashboardInteractionReadinessPhase.indexBuilding);

      indexReady.complete();
      await Future<void>.delayed(Duration.zero);
      expect(
        readiness.phase,
        DashboardInteractionReadinessPhase.presentationPreparing,
      );
      expect(resourceDpr, 3);

      resourcesReady.complete();
      await Future<void>.delayed(Duration.zero);
      expect(
        readiness.phase,
        DashboardInteractionReadinessPhase.renderCriticalWarmup,
      );
      expect(readiness.isReady, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(startCompleted, isFalse);

      expect(
        readiness.markLogBoxFramePresented(viewportId: frame.logBox.viewportId),
        isTrue,
      );
      await start;

      expect(readiness.phase, DashboardInteractionReadinessPhase.ready);
      expect(readiness.isInteractive, isTrue);
      expect(readiness.report()['phase'], 'ready');
      expect(
        readiness.report()['phaseDurationsMicros'],
        isA<Map<String, int>>(),
      );
      expect(
        phases,
        containsAllInOrder(<DashboardInteractionReadinessPhase>[
          DashboardInteractionReadinessPhase.indexBuilding,
          DashboardInteractionReadinessPhase.presentationPreparing,
          DashboardInteractionReadinessPhase.renderCriticalWarmup,
          DashboardInteractionReadinessPhase.ready,
        ]),
      );
    },
  );

  test(
    'stale or premature surface acknowledgement cannot open interaction',
    () async {
      final frame = _frame();
      final resourcesReady = Completer<void>();
      final readiness = DashboardInteractionReadiness(
        buildInitialFrame: () async => frame,
        prepareRenderCriticalResources: (_) => resourcesReady.future,
      );
      addTearDown(readiness.dispose);

      final start = readiness.start(devicePixelRatio: 2);
      await Future<void>.delayed(Duration.zero);
      expect(
        readiness.markLogBoxFramePresented(viewportId: frame.logBox.viewportId),
        isFalse,
        reason: 'A surface cannot acknowledge before resources are complete.',
      );

      resourcesReady.complete();
      await Future<void>.delayed(Duration.zero);
      expect(
        readiness.markLogBoxFramePresented(
          viewportId: frame.logBox.viewportId + 1,
        ),
        isFalse,
        reason: 'A stale payload may not open the interaction gate.',
      );
      expect(readiness.isReady, isFalse);

      readiness.markLogBoxFramePresented(viewportId: frame.logBox.viewportId);
      await start;
      expect(readiness.isReady, isTrue);
    },
  );

  test('failed startup retries through the same readiness owner', () async {
    final frame = _frame();
    var attempts = 0;
    final readiness = DashboardInteractionReadiness(
      buildInitialFrame: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('synthetic');
        return frame;
      },
      prepareRenderCriticalResources: (_) async {},
    );
    addTearDown(readiness.dispose);

    await readiness.start(devicePixelRatio: 1);
    expect(readiness.phase, DashboardInteractionReadinessPhase.failed);
    expect(readiness.isInteractive, isFalse);

    final retry = readiness.start(devicePixelRatio: 1);
    await Future<void>.delayed(Duration.zero);
    expect(
      readiness.phase,
      DashboardInteractionReadinessPhase.renderCriticalWarmup,
    );
    readiness.markLogBoxFramePresented(viewportId: frame.logBox.viewportId);
    await retry;

    expect(attempts, 2);
    expect(readiness.isReady, isTrue);
  });
}

DashboardVisibleFrame _frame() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: AllTimeScope(),
  );
  final prepared = runtimeTestFrame(scope, revision: 1);
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: TimePlane.sum,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}
