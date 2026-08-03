import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/performance/dashboard_performance_trace.dart';

void main() {
  setUp(() {
    DashboardPerformanceTrace.resetForTest(enabled: true);
  });

  tearDown(DashboardPerformanceTrace.resetForTest);

  test('records numeric events in bounded chronological ring order', () {
    for (
      var value = 0;
      value < DashboardPerformanceTrace.capacity + 3;
      value += 1
    ) {
      DashboardPerformanceTrace.record(
        DashboardPerformanceTraceKind.railFlingPlanCreated,
        valueA: value,
        valueB: value + 1,
        timestampMicros: value,
      );
    }

    final events = DashboardPerformanceTrace.events;
    expect(events, hasLength(DashboardPerformanceTrace.capacity));
    expect(events.first.valueA, 3);
    expect(events.last.valueB, DashboardPerformanceTrace.capacity + 3);
  });

  test('records UI and raster timing without a string diagnostic payload', () {
    DashboardPerformanceTrace.recordFrameTiming(
      timestampMicros: 123,
      uiMicros: 4,
      rasterMicros: 9,
    );

    expect(
      DashboardPerformanceTrace.events.single,
      const DashboardPerformanceTraceEvent(
        kind: DashboardPerformanceTraceKind.frameTiming,
        timestampMicros: 123,
        valueA: 4,
        valueB: 9,
      ),
    );
  });
}
