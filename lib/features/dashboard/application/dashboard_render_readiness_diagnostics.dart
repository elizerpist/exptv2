import 'package:flutter/foundation.dart';

import 'dashboard_performance_counters.dart';

enum DashboardRenderReadinessEventType {
  firstUseWorkStarted,
  firstUseWorkCompleted,
  firstUseWorkFailed,
  logBoxFramePresentationStarted,
  logBoxFramePresented,
  railCriticalCacheMiss,
  realGestureSummary,
  readinessPhaseEntered,
  readinessTaskStarted,
  readinessTaskCompleted,
  readinessTaskFailed,
  readinessReady,
}

extension DashboardRenderReadinessEventWireName
    on DashboardRenderReadinessEventType {
  String get wireName => switch (this) {
    DashboardRenderReadinessEventType.firstUseWorkStarted =>
      'FIRST_USE_WORK_STARTED',
    DashboardRenderReadinessEventType.firstUseWorkCompleted =>
      'FIRST_USE_WORK_COMPLETED',
    DashboardRenderReadinessEventType.firstUseWorkFailed =>
      'FIRST_USE_WORK_FAILED',
    DashboardRenderReadinessEventType.logBoxFramePresentationStarted =>
      'LOGBOX_FRAME_PRESENTATION_STARTED',
    DashboardRenderReadinessEventType.logBoxFramePresented =>
      'LOGBOX_FRAME_PRESENTED',
    DashboardRenderReadinessEventType.railCriticalCacheMiss =>
      'RAIL_CRITICAL_CACHE_MISS',
    DashboardRenderReadinessEventType.realGestureSummary =>
      'REAL_GESTURE_SUMMARY',
    DashboardRenderReadinessEventType.readinessPhaseEntered =>
      'READINESS_PHASE_ENTERED',
    DashboardRenderReadinessEventType.readinessTaskStarted =>
      'READINESS_TASK_STARTED',
    DashboardRenderReadinessEventType.readinessTaskCompleted =>
      'READINESS_TASK_COMPLETED',
    DashboardRenderReadinessEventType.readinessTaskFailed =>
      'READINESS_TASK_FAILED',
    DashboardRenderReadinessEventType.readinessReady => 'READINESS_READY',
  };
}

enum DashboardRenderSubsystem {
  logBoxRenderSurface,
  viewportPayload,
  categoryRaster,
  textLayoutSlots,
  semanticsSurface,
  layerSurface,
}

@immutable
final class DashboardRenderDiagnosticContext {
  const DashboardRenderDiagnosticContext({
    required this.gestureId,
    required this.displayFrameId,
  });

  final int gestureId;
  final int displayFrameId;
}

typedef DashboardRenderDiagnosticContextProvider =
    DashboardRenderDiagnosticContext Function();

@immutable
final class DashboardRenderReadinessEvent {
  const DashboardRenderReadinessEvent({
    required this.type,
    required this.timestampMicros,
    this.subsystem,
    this.queryKey,
    this.entryCount = 0,
    this.durationMicros = 0,
    this.gestureId = 0,
    this.displayFrameId = 0,
    this.groupCount = 0,
    this.previewRowCount = 0,
    this.buildMicros = 0,
    this.layoutMicros = 0,
    this.paintMicros = 0,
    this.rasterMicros = 0,
    this.allocationBytes = 0,
    this.rowSlotsPainted = 0,
    this.renderObjectsCreated = 0,
    this.renderObjectsUpdated = 0,
    this.semanticsNodes = 0,
    this.layersCreated = 0,
    this.frameMissedBudget = false,
    this.sampleCount = 0,
    this.totalDistance = 0,
    this.gestureDurationMicros = 0,
    this.p50SampleGapMicros = 0,
    this.p95SampleGapMicros = 0,
    this.maxSampleGapMicros = 0,
    this.rawVelocityEstimate = 0,
    this.dragEndVelocity = 0,
    this.ballisticInputVelocity = 0,
    this.startIndex = 0,
    this.finalIndex = 0,
    this.uiMissedFramesDuringGesture = 0,
    this.uiMissedFramesAtRelease = 0,
    this.renderWorkDuringReleaseMicros = 0,
    this.readinessPhase,
    this.readinessTask,
    this.startMicros = 0,
    this.coreRevision = 0,
    this.generation = 0,
    this.error,
  });

  final DashboardRenderReadinessEventType type;
  final int timestampMicros;
  final DashboardRenderSubsystem? subsystem;
  final String? queryKey;
  final int entryCount;
  final int durationMicros;
  final int gestureId;
  final int displayFrameId;
  final int groupCount;
  final int previewRowCount;
  final int buildMicros;
  final int layoutMicros;
  final int paintMicros;
  final int rasterMicros;
  final int allocationBytes;
  final int rowSlotsPainted;
  final int renderObjectsCreated;
  final int renderObjectsUpdated;
  final int semanticsNodes;
  final int layersCreated;
  final bool frameMissedBudget;
  final int sampleCount;
  final double totalDistance;
  final int gestureDurationMicros;
  final int p50SampleGapMicros;
  final int p95SampleGapMicros;
  final int maxSampleGapMicros;
  final double rawVelocityEstimate;
  final double dragEndVelocity;
  final double ballisticInputVelocity;
  final int startIndex;
  final int finalIndex;
  final int uiMissedFramesDuringGesture;
  final int uiMissedFramesAtRelease;
  final int renderWorkDuringReleaseMicros;
  final String? readinessPhase;
  final String? readinessTask;
  final int startMicros;
  final int coreRevision;
  final int generation;
  final String? error;

  String get wireName => type.wireName;

  Map<String, Object?> toMap() => <String, Object?>{
    'event': wireName,
    'timestampMicros': timestampMicros,
    'subsystem': subsystem?.name,
    'queryKey': queryKey,
    'entryCount': entryCount,
    'durationMicros': durationMicros,
    'gestureId': gestureId,
    'displayFrameId': displayFrameId,
    'groupCount': groupCount,
    'previewRowCount': previewRowCount,
    'buildMicros': buildMicros,
    'layoutMicros': layoutMicros,
    'paintMicros': paintMicros,
    'rasterMicros': rasterMicros,
    'allocationBytes': allocationBytes,
    'rowSlotsPainted': rowSlotsPainted,
    'renderObjectsCreated': renderObjectsCreated,
    'renderObjectsUpdated': renderObjectsUpdated,
    'semanticsNodes': semanticsNodes,
    'layersCreated': layersCreated,
    'frameMissedBudget': frameMissedBudget,
    'sampleCount': sampleCount,
    'totalDistance': totalDistance,
    'gestureDurationMicros': gestureDurationMicros,
    'p50SampleGapMicros': p50SampleGapMicros,
    'p95SampleGapMicros': p95SampleGapMicros,
    'maxSampleGapMicros': maxSampleGapMicros,
    'rawVelocityEstimate': rawVelocityEstimate,
    'dragEndVelocity': dragEndVelocity,
    'ballisticInputVelocity': ballisticInputVelocity,
    'startIndex': startIndex,
    'finalIndex': finalIndex,
    'logicalDelta': finalIndex - startIndex,
    'uiMissedFramesDuringGesture': uiMissedFramesDuringGesture,
    'uiMissedFramesAtRelease': uiMissedFramesAtRelease,
    'renderWorkDuringReleaseMicros': renderWorkDuringReleaseMicros,
    'phase': readinessPhase,
    'task': readinessTask,
    'startMicros': startMicros,
    'coreRevision': coreRevision,
    'generation': generation,
    'error': error,
  };
}

/// Focused bounded recorder for render readiness and device evidence.
///
/// The motion recorder remains the owner of per-gesture rail mechanics. This
/// owner records only the missing render/readiness facts and never writes to
/// stdout from an interaction callback.
final class DashboardRenderReadinessDiagnostics {
  DashboardRenderReadinessDiagnostics({
    this.enabled = false,
    this.capacity = 512,
    this.failOnPostReadyViolation = true,
    int Function()? clock,
  }) : assert(capacity > 0),
       _clock = clock ?? _defaultClock,
       _ring = List<DashboardRenderReadinessEvent?>.filled(
         capacity,
         null,
         growable: false,
       );

  final bool enabled;
  final int capacity;
  final bool failOnPostReadyViolation;
  final int Function() _clock;
  final List<DashboardRenderReadinessEvent?> _ring;
  int _writeCursor = 0;
  int _length = 0;
  bool _ready = false;
  DashboardPerformanceCounters? _performanceCounters;

  int overwrittenEventCount = 0;
  int postReadyFirstUseViolationCount = 0;
  int railCriticalCacheMissCount = 0;

  static int _defaultClock() => DateTime.now().microsecondsSinceEpoch;

  void markReady() => _ready = true;

  void bindPerformanceCounters(DashboardPerformanceCounters counters) {
    _performanceCounters = counters;
  }

  void recordFirstUseStarted({
    required DashboardRenderSubsystem subsystem,
    required String queryKey,
    required int entryCount,
    bool railCritical = true,
  }) {
    final violation = _ready && railCritical;
    if (violation) {
      postReadyFirstUseViolationCount += 1;
      _performanceCounters?.increment(
        DashboardPerformanceMetric.postReadyFirstUseViolation,
      );
    }
    _add(
      DashboardRenderReadinessEvent(
        type: DashboardRenderReadinessEventType.firstUseWorkStarted,
        timestampMicros: _clock(),
        subsystem: subsystem,
        queryKey: queryKey,
        entryCount: entryCount,
      ),
    );
    assert(
      !violation || !failOnPostReadyViolation,
      'FIRST_USE_WORK_STARTED after DashboardInteractionReadiness.ready: '
      '${subsystem.name}',
    );
  }

  void recordFirstUseCompleted({
    required DashboardRenderSubsystem subsystem,
    required String queryKey,
    required int entryCount,
    required int durationMicros,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: DashboardRenderReadinessEventType.firstUseWorkCompleted,
      timestampMicros: _clock(),
      subsystem: subsystem,
      queryKey: queryKey,
      entryCount: entryCount,
      durationMicros: durationMicros,
    ),
  );

  void recordFirstUseFailed({
    required DashboardRenderSubsystem subsystem,
    required String queryKey,
    required int entryCount,
    required int durationMicros,
    required Object error,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: DashboardRenderReadinessEventType.firstUseWorkFailed,
      timestampMicros: _clock(),
      subsystem: subsystem,
      queryKey: queryKey,
      entryCount: entryCount,
      durationMicros: durationMicros,
      error: '$error',
    ),
  );

  void recordReadinessPhaseEntered({
    required String phase,
    required int startMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
  }) => _recordReadiness(
    type: DashboardRenderReadinessEventType.readinessPhaseEntered,
    phase: phase,
    startMicros: startMicros,
    durationMicros: 0,
    queryKey: queryKey,
    coreRevision: coreRevision,
    generation: generation,
  );

  void recordReadinessTaskStarted({
    required String phase,
    required String task,
    required int startMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
  }) => _recordReadiness(
    type: DashboardRenderReadinessEventType.readinessTaskStarted,
    phase: phase,
    task: task,
    startMicros: startMicros,
    durationMicros: 0,
    queryKey: queryKey,
    coreRevision: coreRevision,
    generation: generation,
  );

  void recordReadinessTaskCompleted({
    required String phase,
    required String task,
    required int startMicros,
    required int durationMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
  }) => _recordReadiness(
    type: DashboardRenderReadinessEventType.readinessTaskCompleted,
    phase: phase,
    task: task,
    startMicros: startMicros,
    durationMicros: durationMicros,
    queryKey: queryKey,
    coreRevision: coreRevision,
    generation: generation,
  );

  void recordReadinessTaskFailed({
    required String phase,
    required String task,
    required int startMicros,
    required int durationMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
    required Object error,
  }) => _recordReadiness(
    type: DashboardRenderReadinessEventType.readinessTaskFailed,
    phase: phase,
    task: task,
    startMicros: startMicros,
    durationMicros: durationMicros,
    queryKey: queryKey,
    coreRevision: coreRevision,
    generation: generation,
    error: '$error',
  );

  void recordReadinessReady({
    required String phase,
    required int startMicros,
    required int durationMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
  }) => _recordReadiness(
    type: DashboardRenderReadinessEventType.readinessReady,
    phase: phase,
    startMicros: startMicros,
    durationMicros: durationMicros,
    queryKey: queryKey,
    coreRevision: coreRevision,
    generation: generation,
  );

  void _recordReadiness({
    required DashboardRenderReadinessEventType type,
    required String phase,
    String? task,
    required int startMicros,
    required int durationMicros,
    required String queryKey,
    required int coreRevision,
    required int generation,
    String? error,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: type,
      timestampMicros: _clock(),
      queryKey: queryKey,
      durationMicros: durationMicros,
      readinessPhase: phase,
      readinessTask: task,
      startMicros: startMicros,
      coreRevision: coreRevision,
      generation: generation,
      error: error,
    ),
  );

  void recordRailCriticalCacheMiss({
    required DashboardRenderSubsystem subsystem,
    required String queryKey,
  }) {
    railCriticalCacheMissCount += 1;
    _performanceCounters?.increment(
      DashboardPerformanceMetric.railCriticalCacheMiss,
    );
    _add(
      DashboardRenderReadinessEvent(
        type: DashboardRenderReadinessEventType.railCriticalCacheMiss,
        timestampMicros: _clock(),
        subsystem: subsystem,
        queryKey: queryKey,
      ),
    );
    assert(
      !_ready || !failOnPostReadyViolation,
      'RAIL_CRITICAL_CACHE_MISS after DashboardInteractionReadiness.ready: '
      '${subsystem.name}',
    );
  }

  void recordLogBoxPresentationStarted({
    required int gestureId,
    required int displayFrameId,
    required String queryKey,
    required int entryCount,
    required int groupCount,
    required int previewRowCount,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: DashboardRenderReadinessEventType.logBoxFramePresentationStarted,
      timestampMicros: _clock(),
      gestureId: gestureId,
      displayFrameId: displayFrameId,
      queryKey: queryKey,
      entryCount: entryCount,
      groupCount: groupCount,
      previewRowCount: previewRowCount,
    ),
  );

  void recordLogBoxPresented({
    required int gestureId,
    required int displayFrameId,
    required String queryKey,
    required int entryCount,
    required int groupCount,
    required int previewRowCount,
    required int buildMicros,
    required int layoutMicros,
    required int paintMicros,
    required int rowSlotsPainted,
    required int semanticsNodes,
    int rasterMicros = 0,
    int allocationBytes = 0,
    int renderObjectsCreated = 0,
    int renderObjectsUpdated = 0,
    int layersCreated = 0,
    bool frameMissedBudget = false,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: DashboardRenderReadinessEventType.logBoxFramePresented,
      timestampMicros: _clock(),
      gestureId: gestureId,
      displayFrameId: displayFrameId,
      queryKey: queryKey,
      entryCount: entryCount,
      groupCount: groupCount,
      previewRowCount: previewRowCount,
      buildMicros: buildMicros,
      layoutMicros: layoutMicros,
      paintMicros: paintMicros,
      rasterMicros: rasterMicros,
      allocationBytes: allocationBytes,
      rowSlotsPainted: rowSlotsPainted,
      renderObjectsCreated: renderObjectsCreated,
      renderObjectsUpdated: renderObjectsUpdated,
      semanticsNodes: semanticsNodes,
      layersCreated: layersCreated,
      frameMissedBudget: frameMissedBudget,
    ),
  );

  void recordRealGestureSummary({
    required int gestureId,
    required int sampleCount,
    required double totalDistance,
    required int durationMicros,
    required int p50SampleGapMicros,
    required int p95SampleGapMicros,
    required int maxSampleGapMicros,
    required double rawVelocityEstimate,
    required double dragEndVelocity,
    required double ballisticInputVelocity,
    required int startIndex,
    required int finalIndex,
    required int uiMissedFramesDuringGesture,
    required int uiMissedFramesAtRelease,
    required int renderWorkDuringReleaseMicros,
  }) => _add(
    DashboardRenderReadinessEvent(
      type: DashboardRenderReadinessEventType.realGestureSummary,
      timestampMicros: _clock(),
      gestureId: gestureId,
      sampleCount: sampleCount,
      totalDistance: totalDistance,
      gestureDurationMicros: durationMicros,
      p50SampleGapMicros: p50SampleGapMicros,
      p95SampleGapMicros: p95SampleGapMicros,
      maxSampleGapMicros: maxSampleGapMicros,
      rawVelocityEstimate: rawVelocityEstimate,
      dragEndVelocity: dragEndVelocity,
      ballisticInputVelocity: ballisticInputVelocity,
      startIndex: startIndex,
      finalIndex: finalIndex,
      uiMissedFramesDuringGesture: uiMissedFramesDuringGesture,
      uiMissedFramesAtRelease: uiMissedFramesAtRelease,
      renderWorkDuringReleaseMicros: renderWorkDuringReleaseMicros,
    ),
  );

  List<DashboardRenderReadinessEvent> snapshot() {
    if (_length == 0) return const <DashboardRenderReadinessEvent>[];
    final start = _length == capacity ? _writeCursor : 0;
    return List<DashboardRenderReadinessEvent>.unmodifiable(
      List<DashboardRenderReadinessEvent>.generate(
        _length,
        (index) => _ring[(start + index) % capacity]!,
        growable: false,
      ),
    );
  }

  Map<String, Object?> exportPhysicalReport({
    Iterable<Map<String, Object?>> motionEvents =
        const <Map<String, Object?>>[],
    int motionOverwrittenEventCount = 0,
  }) {
    final events = snapshot();
    final motion = motionEvents.toList(growable: false);
    final gestureSummaries = events
        .where(
          (event) =>
              event.type ==
              DashboardRenderReadinessEventType.realGestureSummary,
        )
        .take(10)
        .toList(growable: false);
    final presentations = events
        .where(
          (event) =>
              event.type ==
              DashboardRenderReadinessEventType.logBoxFramePresented,
        )
        .map((event) => event.toMap())
        .toList(growable: false);
    final firstTen = gestureSummaries
        .map((gesture) {
          final gestureId = gesture.gestureId;
          return <String, Object?>{
            ...gesture.toMap(),
            'motionTimeline': motion
                .where((event) => event['gesture_id'] == gestureId)
                .toList(growable: false),
            'logBoxTimeline': presentations
                .where((event) => event['gestureId'] == gestureId)
                .toList(growable: false),
          };
        })
        .toList(growable: false);
    final firstUse = events
        .where(
          (event) =>
              event.type ==
                  DashboardRenderReadinessEventType.firstUseWorkStarted ||
              event.type ==
                  DashboardRenderReadinessEventType.firstUseWorkCompleted ||
              event.type ==
                  DashboardRenderReadinessEventType.firstUseWorkFailed,
        )
        .map((event) => event.toMap())
        .toList(growable: false);
    final cacheMisses = events
        .where(
          (event) =>
              event.type ==
              DashboardRenderReadinessEventType.railCriticalCacheMiss,
        )
        .map((event) => event.toMap())
        .toList(growable: false);
    final readinessTimeline = events
        .where(
          (event) => switch (event.type) {
            DashboardRenderReadinessEventType.readinessPhaseEntered ||
            DashboardRenderReadinessEventType.readinessTaskStarted ||
            DashboardRenderReadinessEventType.readinessTaskCompleted ||
            DashboardRenderReadinessEventType.readinessTaskFailed ||
            DashboardRenderReadinessEventType.readinessReady => true,
            _ => false,
          },
        )
        .map((event) => event.toMap())
        .toList(growable: false);
    final presentedEvents = events
        .where(
          (event) =>
              event.type ==
              DashboardRenderReadinessEventType.logBoxFramePresented,
        )
        .toList(growable: false);
    Map<String, Object?> durationSummary(
      String name,
      int Function(DashboardRenderReadinessEvent event) select,
    ) {
      final values = presentedEvents.map(select).toList()..sort();
      int percentile(double fraction) {
        if (values.isEmpty) return 0;
        return values[((values.length - 1) * fraction).ceil()];
      }

      return <String, Object?>{
        '${name}P50Micros': percentile(.50),
        '${name}P95Micros': percentile(.95),
        '${name}P99Micros': percentile(.99),
      };
    }

    return <String, Object?>{
      'schema': 'fluvi.dashboard.physical-rail.v1',
      'generatedAtMicros': _clock(),
      'firstTenFlings': firstTen,
      'logBoxPresentations': presentations,
      'firstUseEvents': firstUse,
      'railCriticalCacheMisses': cacheMisses,
      'readinessTimeline': readinessTimeline,
      'motionEvents': motion,
      'logBoxPresentationSummary': <String, Object?>{
        'sampleCount': presentedEvents.length,
        ...durationSummary('build', (event) => event.buildMicros),
        ...durationSummary('layout', (event) => event.layoutMicros),
        ...durationSummary('paint', (event) => event.paintMicros),
        'maximumRowSlotsPainted': presentedEvents.fold<int>(
          0,
          (maximum, event) =>
              event.rowSlotsPainted > maximum ? event.rowSlotsPainted : maximum,
        ),
        'missedBudgetCount': presentedEvents
            .where((event) => event.frameMissedBudget)
            .length,
      },
      'measurementCapabilities': const <String, Object?>{
        'realPointerSampling': true,
        'flutterFrameTiming': true,
        'logBoxUiBuildLayoutPaint': true,
        'perGestureGc': false,
        'perGestureAllocationBytes': false,
      },
      'motionOverwrittenEventCount': motionOverwrittenEventCount,
      'renderOverwrittenEventCount': overwrittenEventCount,
      'railCriticalCacheMissCount': railCriticalCacheMissCount,
      'postReadyFirstUseViolationCount': postReadyFirstUseViolationCount,
    };
  }

  void _add(DashboardRenderReadinessEvent event) {
    if (!enabled) return;
    if (_length == capacity) overwrittenEventCount += 1;
    _ring[_writeCursor] = event;
    _writeCursor = (_writeCursor + 1) % capacity;
    if (_length < capacity) _length += 1;
  }
}
