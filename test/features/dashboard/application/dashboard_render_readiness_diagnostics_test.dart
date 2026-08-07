import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_render_readiness_diagnostics.dart';

void main() {
  test(
    'bounded diagnostics retain first-use and LogBox presentation evidence',
    () {
      final diagnostics = DashboardRenderReadinessDiagnostics(
        enabled: true,
        capacity: 4,
        failOnPostReadyViolation: false,
      );

      diagnostics.recordFirstUseStarted(
        subsystem: DashboardRenderSubsystem.logBoxRenderSurface,
        queryKey: 'q0',
        entryCount: 0,
      );
      diagnostics.recordFirstUseCompleted(
        subsystem: DashboardRenderSubsystem.logBoxRenderSurface,
        queryKey: 'q0',
        entryCount: 0,
        durationMicros: 40,
      );
      diagnostics.recordLogBoxPresentationStarted(
        gestureId: 7,
        displayFrameId: 11,
        queryKey: 'q1',
        entryCount: 94,
        groupCount: 12,
        previewRowCount: 24,
      );
      diagnostics.recordLogBoxPresented(
        gestureId: 7,
        displayFrameId: 11,
        queryKey: 'q1',
        entryCount: 94,
        groupCount: 12,
        previewRowCount: 24,
        buildMicros: 10,
        layoutMicros: 20,
        paintMicros: 30,
        rowSlotsPainted: 8,
        semanticsNodes: 8,
      );
      diagnostics.recordFirstUseStarted(
        subsystem: DashboardRenderSubsystem.categoryRaster,
        queryKey: 'q2',
        entryCount: 1,
      );

      final events = diagnostics.snapshot();
      expect(events, hasLength(4));
      expect(
        events.first.type,
        DashboardRenderReadinessEventType.firstUseWorkCompleted,
        reason: 'The ring must evict its oldest record at fixed capacity.',
      );
      expect(
        events[2].type,
        DashboardRenderReadinessEventType.logBoxFramePresented,
      );
      expect(events[2].rowSlotsPainted, 8);
      expect(events[2].semanticsNodes, 8);
    },
  );

  test(
    'post-ready rail-critical first use and cache misses are violations',
    () {
      final counters = DashboardPerformanceCounters();
      final diagnostics =
          DashboardRenderReadinessDiagnostics(
              enabled: true,
              failOnPostReadyViolation: false,
            )
            ..bindPerformanceCounters(counters)
            ..markReady();

      diagnostics.recordFirstUseStarted(
        subsystem: DashboardRenderSubsystem.categoryRaster,
        queryKey: 'q',
        entryCount: 24,
        railCritical: true,
      );
      diagnostics.recordRailCriticalCacheMiss(
        subsystem: DashboardRenderSubsystem.viewportPayload,
        queryKey: 'q',
      );

      expect(diagnostics.postReadyFirstUseViolationCount, 1);
      expect(diagnostics.railCriticalCacheMissCount, 1);
      expect(
        counters.value(DashboardPerformanceMetric.postReadyFirstUseViolation),
        1,
      );
      expect(
        counters.value(DashboardPerformanceMetric.railCriticalCacheMiss),
        1,
      );
      expect(
        diagnostics.snapshot().map((event) => event.wireName),
        containsAll(<String>[
          'FIRST_USE_WORK_STARTED',
          'RAIL_CRITICAL_CACHE_MISS',
        ]),
      );
    },
  );

  test('readiness timeline records terminal task state and failure context', () {
    final diagnostics = DashboardRenderReadinessDiagnostics(
      enabled: true,
      clock: _Clock().call,
    );

    diagnostics.recordReadinessPhaseEntered(
      phase: 'renderCriticalWarmup',
      startMicros: 100,
      queryKey: 'income|month:2026-07',
      coreRevision: 7,
      generation: 11,
    );
    diagnostics.recordReadinessTaskStarted(
      phase: 'renderCriticalWarmup',
      task: 'textLayoutSlots',
      startMicros: 120,
      queryKey: 'income|month:2026-07',
      coreRevision: 7,
      generation: 11,
    );
    diagnostics.recordReadinessTaskFailed(
      phase: 'renderCriticalWarmup',
      task: 'textLayoutSlots',
      startMicros: 120,
      durationMicros: 30,
      queryKey: 'income|month:2026-07',
      coreRevision: 7,
      generation: 11,
      error: 'StateError: synthetic',
    );

    final events = diagnostics.snapshot();
    expect(
      events.map((event) => event.wireName),
      <String>[
        'READINESS_PHASE_ENTERED',
        'READINESS_TASK_STARTED',
        'READINESS_TASK_FAILED',
      ],
    );
    expect(events.last.readinessTask, 'textLayoutSlots');
    expect(events.last.error, 'StateError: synthetic');
    expect(events.last.durationMicros, 30);
  });

  test('physical report exports first ten gesture and render timelines', () {
    final diagnostics = DashboardRenderReadinessDiagnostics(enabled: true);
    for (var index = 0; index < 12; index += 1) {
      diagnostics.recordRealGestureSummary(
        gestureId: index + 1,
        sampleCount: 8,
        totalDistance: 240,
        durationMicros: 100000,
        p50SampleGapMicros: 8000,
        p95SampleGapMicros: 12000,
        maxSampleGapMicros: 15000,
        rawVelocityEstimate: 2200,
        dragEndVelocity: 2180,
        ballisticInputVelocity: 2180,
        startIndex: 2,
        finalIndex: 7,
        uiMissedFramesDuringGesture: 0,
        uiMissedFramesAtRelease: 0,
        renderWorkDuringReleaseMicros: 400,
      );
    }

    final report = diagnostics.exportPhysicalReport(
      motionEvents: const <Map<String, Object?>>[
        <String, Object?>{
          'event': 'GESTURE_RELEASED',
          'gesture_id': 1,
          'drag_end_velocity': 2180,
        },
        <String, Object?>{
          'event': 'RAIL_SETTLED',
          'gesture_id': 1,
          'final_logical_index': 7,
        },
      ],
    );
    expect(report['schema'], 'fluvi.dashboard.physical-rail.v1');
    expect(report['firstTenFlings'], isA<List<Object?>>());
    expect((report['firstTenFlings']! as List<Object?>), hasLength(10));
    final first =
        (report['firstTenFlings']! as List<Object?>).first
            as Map<String, Object?>;
    expect(first['motionTimeline'], hasLength(2));
    expect(first['logBoxTimeline'], isEmpty);
    expect(report['motionEvents'], hasLength(2));
    expect(report['motionOverwrittenEventCount'], 0);
    expect(report['renderOverwrittenEventCount'], 0);
    expect(report['logBoxPresentationSummary'], isA<Map<String, Object?>>());
    expect(report['measurementCapabilities'], isA<Map<String, Object?>>());
    expect(report['railCriticalCacheMissCount'], 0);
    expect(report['postReadyFirstUseViolationCount'], 0);
  });
}

final class _Clock {
  int _value = 200;

  int call() => _value++;
}
