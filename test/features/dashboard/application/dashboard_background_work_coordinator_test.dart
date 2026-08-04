import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_background_work_coordinator.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';

void main() {
  DashboardBackgroundWorkCoordinator coordinator() =>
      DashboardBackgroundWorkCoordinator(
        scheduleDrain: (drain) => scheduleMicrotask(drain),
      );

  test(
    'queued work starts only after the latest interaction becomes idle',
    () async {
      final work = coordinator();
      addTearDown(work.dispose);
      final started = <String>[];
      const key = DashboardBackgroundJobKey(
        type: DashboardBackgroundJobType.adjacentParentPrewarm,
        semanticKey: 'month:2026-08',
      );

      work.beginInteraction(3);
      final result = work.schedule(
        key: key,
        priority: DashboardBackgroundPriority.low,
        task: (token) async {
          started.add(key.semanticKey);
          return token.canContinue;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(started, isEmpty);

      work.endInteraction(2);
      await Future<void>.delayed(Duration.zero);
      expect(started, isEmpty);

      work.endInteraction(3);
      expect(await result, isTrue);
      expect(started, <String>['month:2026-08']);
    },
  );

  test('the same semantic job is deduplicated', () async {
    final counters = DashboardPerformanceCounters();
    final work = DashboardBackgroundWorkCoordinator(
      scheduleDrain: (drain) => scheduleMicrotask(drain),
      performanceCounters: counters,
    );
    addTearDown(work.dispose);
    var starts = 0;
    const key = DashboardBackgroundJobKey(
      type: DashboardBackgroundJobType.coreRevisionRefresh,
      semanticKey: 'income|month:2026-07|revision:2',
    );

    final first = work.schedule(
      key: key,
      priority: DashboardBackgroundPriority.critical,
      task: (_) async {
        starts += 1;
        return true;
      },
    );
    final second = work.schedule(
      key: key,
      priority: DashboardBackgroundPriority.critical,
      task: (_) async {
        starts += 1;
        return true;
      },
    );

    expect(identical(first, second), isTrue);
    expect(await first, isTrue);
    expect(starts, 1);
    expect(work.deduplicatedCount, 1);
    expect(counters.value(DashboardPerformanceMetric.backgroundJobStarted), 1);
    expect(
      counters.value(DashboardPerformanceMetric.backgroundJobCompleted),
      1,
    );
    expect(
      counters.value(DashboardPerformanceMetric.backgroundJobDeduplicated),
      1,
    );
  });

  test('only one job runs and critical work precedes queued prewarm', () async {
    final work = coordinator();
    addTearDown(work.dispose);
    final order = <String>[];
    final criticalGate = Completer<void>();

    final low = work.schedule(
      key: const DashboardBackgroundJobKey(
        type: DashboardBackgroundJobType.adjacentParentPrewarm,
        semanticKey: 'adjacent',
      ),
      priority: DashboardBackgroundPriority.low,
      task: (_) async {
        order.add('low');
        return true;
      },
    );
    final critical = work.schedule(
      key: const DashboardBackgroundJobKey(
        type: DashboardBackgroundJobType.coreRevisionRefresh,
        semanticKey: 'revision',
      ),
      priority: DashboardBackgroundPriority.critical,
      task: (_) async {
        order.add('critical');
        await criticalGate.future;
        return true;
      },
    );
    await Future<void>.delayed(Duration.zero);

    expect(order, <String>['critical']);
    expect(work.runningCount, 1);

    criticalGate.complete();
    expect(await critical, isTrue);
    expect(await low, isTrue);
    expect(order, <String>['critical', 'low']);
    expect(work.maxConcurrentCount, 1);
  });

  test(
    'new interaction invalidates a running token and gates queued work',
    () async {
      final work = coordinator();
      addTearDown(work.dispose);
      final gate = Completer<void>();
      late DashboardBackgroundWorkToken runningToken;
      var queuedStarts = 0;

      final running = work.schedule(
        key: const DashboardBackgroundJobKey(
          type: DashboardBackgroundJobType.adjacentParentPrewarm,
          semanticKey: 'running',
        ),
        priority: DashboardBackgroundPriority.low,
        task: (token) async {
          runningToken = token;
          await gate.future;
          return token.canContinue;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(runningToken.canContinue, isTrue);

      work.beginInteraction(9);
      expect(runningToken.canContinue, isFalse);
      final queued = work.schedule(
        key: const DashboardBackgroundJobKey(
          type: DashboardBackgroundJobType.adjacentParentPrewarm,
          semanticKey: 'queued',
        ),
        priority: DashboardBackgroundPriority.low,
        task: (_) async {
          queuedStarts += 1;
          return true;
        },
      );
      gate.complete();
      expect(await running, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(queuedStarts, 0);

      work.endInteraction(9);
      expect(await queued, isTrue);
      expect(queuedStarts, 1);
    },
  );

  test('latest job supersedes older queued work in the same group', () async {
    final work = coordinator();
    addTearDown(work.dispose);
    final started = <String>[];
    work.beginInteraction(1);

    final old = work.schedule(
      key: const DashboardBackgroundJobKey(
        type: DashboardBackgroundJobType.adjacentParentPrewarm,
        semanticKey: 'old-parent',
      ),
      priority: DashboardBackgroundPriority.low,
      supersedeGroup: 'adjacent-parent',
      task: (_) async {
        started.add('old');
        return true;
      },
    );
    final latest = work.schedule(
      key: const DashboardBackgroundJobKey(
        type: DashboardBackgroundJobType.adjacentParentPrewarm,
        semanticKey: 'latest-parent',
      ),
      priority: DashboardBackgroundPriority.low,
      supersedeGroup: 'adjacent-parent',
      task: (_) async {
        started.add('latest');
        return true;
      },
    );

    expect(await old, isFalse);
    work.endInteraction(1);
    expect(await latest, isTrue);
    expect(started, <String>['latest']);
    expect(work.supersededCount, 1);
  });
}
