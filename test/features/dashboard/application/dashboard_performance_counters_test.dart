import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
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
      ..increment(DashboardPerformanceMetric.parentBundleLookup)
      ..increment(DashboardPerformanceMetric.repositoryRead, by: 4)
      ..increment(DashboardPerformanceMetric.amountAnimationStarted);

    counters.reset();

    expect(identityHashCode(counters), identity);
    expect(counters.snapshot().values, everyElement(0));
  });

  test('rejects negative increments so diagnostics stay truthful', () {
    final counters = DashboardPerformanceCounters();

    expect(
      () =>
          counters.increment(DashboardPerformanceMetric.repositoryRead, by: -1),
      throwsArgumentError,
    );
  });

  test('dashboard core shares the same counter owner with every work lane', () {
    final counters = DashboardPerformanceCounters();
    final controller = DashboardCoreController(
      autoStartQuery: false,
      performanceCounters: counters,
    );
    addTearDown(controller.dispose);

    expect(controller.performanceCounters, same(counters));
    expect(controller.query.performanceCounters, same(counters));
    expect(controller.backgroundWork.performanceCounters, same(counters));
    expect(
      controller.summaryMetrics.parentBundleRegistry.performanceCounters,
      same(counters),
    );
  });
}
