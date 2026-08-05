import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_diagnostics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';

void main() {
  test('keeps one fixed numeric slot per declared dashboard metric', () {
    final counters = DashboardPerformanceCounters();

    for (final metric in DashboardPerformanceMetric.values) {
      counters.increment(metric);
      counters.increment(metric, by: 2);
    }

    expect(counters.slotCount, DashboardPerformanceMetric.values.length);
    expect(
      counters.snapshot().keys,
      orderedEquals(DashboardPerformanceMetric.values),
    );
    expect(counters.snapshot().values, everyElement(3));
  });

  test('reset clears every metric without replacing the counter owner', () {
    final counters = DashboardPerformanceCounters();
    final identity = identityHashCode(counters);
    counters
      ..increment(DashboardPerformanceMetric.visibleFramePublish)
      ..increment(DashboardPerformanceMetric.repositoryReadsDuringMotion, by: 4)
      ..increment(DashboardPerformanceMetric.amountAnimationStarted);

    counters.reset();

    expect(identityHashCode(counters), identity);
    expect(counters.snapshot().values, everyElement(0));
  });

  test('rejects negative increments so diagnostics stay truthful', () {
    final counters = DashboardPerformanceCounters();

    expect(
      () => counters.increment(
        DashboardPerformanceMetric.repositoryReadsDuringMotion,
        by: -1,
      ),
      throwsArgumentError,
    );
  });

  test('dashboard core and diagnostics share one fixed counter owner', () {
    final counters = DashboardPerformanceCounters();
    final diagnostics = DashboardInteractionDiagnostics(counters: counters);
    final controller = DashboardCoreController(
      initialCoreRevision: 1,
      performanceCounters: counters,
      interactionDiagnostics: diagnostics,
    );
    addTearDown(controller.dispose);

    expect(controller.performanceCounters, same(counters));
    expect(controller.diagnostics, same(diagnostics));
    expect(controller.diagnostics.counters, same(counters));
  });
}
