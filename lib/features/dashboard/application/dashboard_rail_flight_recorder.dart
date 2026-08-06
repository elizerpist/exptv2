import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../shared/motion/centered_carousel/centered_carousel_motion_diagnostics.dart';
import '../motion/dashboard_motion_state.dart';
import '../motion/dashboard_semantic_catalog.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_dashboard_index.dart';
import '../time_navigation/domain/time_plane.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_performance_counters.dart';

typedef DashboardRailFlightClock = int Function();
typedef DashboardRailFlightContextProvider =
    DashboardRailFlightContext Function();

enum DashboardRailFlightEventType {
  gestureStart,
  gestureSampleSummary,
  gestureReleased,
  ballisticStarted,
  semanticChildCrossed,
  presentationApplyStarted,
  presentationApplyCompleted,
  scrollMetricsChanged,
  scrollActivityChanged,
  frameTiming,
  railSettled,
}

extension DashboardRailFlightEventWireName on DashboardRailFlightEventType {
  String get wireName => switch (this) {
    DashboardRailFlightEventType.gestureStart => 'GESTURE_START',
    DashboardRailFlightEventType.gestureSampleSummary =>
      'GESTURE_SAMPLE_SUMMARY',
    DashboardRailFlightEventType.gestureReleased => 'GESTURE_RELEASED',
    DashboardRailFlightEventType.ballisticStarted => 'BALLISTIC_STARTED',
    DashboardRailFlightEventType.semanticChildCrossed =>
      'SEMANTIC_CHILD_CROSSED',
    DashboardRailFlightEventType.presentationApplyStarted =>
      'PRESENTATION_APPLY_STARTED',
    DashboardRailFlightEventType.presentationApplyCompleted =>
      'PRESENTATION_APPLY_COMPLETED',
    DashboardRailFlightEventType.scrollMetricsChanged =>
      'SCROLL_METRICS_CHANGED',
    DashboardRailFlightEventType.scrollActivityChanged =>
      'SCROLL_ACTIVITY_CHANGED',
    DashboardRailFlightEventType.frameTiming => 'FRAME_TIMING',
    DashboardRailFlightEventType.railSettled => 'RAIL_SETTLED',
  };
}

@immutable
final class DashboardRailFlightContext {
  const DashboardRailFlightContext({
    required this.motionEpoch,
    required this.navigationEpoch,
    required this.presentationEpoch,
    required this.queryKey,
    required this.parentQueryKey,
    required this.direction,
    required this.childKind,
    required this.plane,
    required this.semanticIndex,
    required this.coreRevision,
    required this.presentationGeneration,
    required this.presentationMode,
    required this.dataOrigin,
    required this.hasData,
    required this.entryCount,
    required this.preparedPreviewRowCount,
    required this.frameDigest,
    required this.displayFrameNumber,
    required this.motionState,
  });

  final int motionEpoch;
  final int navigationEpoch;
  final int presentationEpoch;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final LedgerDirection direction;
  final DashboardChildKind childKind;
  final TimePlane plane;
  final int semanticIndex;
  final int coreRevision;
  final int presentationGeneration;
  final DashboardVisibleMode presentationMode;
  final DashboardDataOrigin dataOrigin;
  final bool hasData;
  final int entryCount;
  final int preparedPreviewRowCount;
  final int frameDigest;
  final int displayFrameNumber;
  final DashboardMotionActivity motionState;

  DashboardRailFlightContext copyWith({
    LedgerQueryKey? queryKey,
    LedgerQueryKey? parentQueryKey,
    LedgerDirection? direction,
    DashboardChildKind? childKind,
    TimePlane? plane,
    int? semanticIndex,
    int? coreRevision,
    int? presentationGeneration,
    DashboardVisibleMode? presentationMode,
    DashboardDataOrigin? dataOrigin,
    bool? hasData,
    int? entryCount,
    int? preparedPreviewRowCount,
    int? frameDigest,
    int? displayFrameNumber,
    DashboardMotionActivity? motionState,
  }) => DashboardRailFlightContext(
    motionEpoch: motionEpoch,
    navigationEpoch: navigationEpoch,
    presentationEpoch: presentationEpoch,
    queryKey: queryKey ?? this.queryKey,
    parentQueryKey: parentQueryKey ?? this.parentQueryKey,
    direction: direction ?? this.direction,
    childKind: childKind ?? this.childKind,
    plane: plane ?? this.plane,
    semanticIndex: semanticIndex ?? this.semanticIndex,
    coreRevision: coreRevision ?? this.coreRevision,
    presentationGeneration:
        presentationGeneration ?? this.presentationGeneration,
    presentationMode: presentationMode ?? this.presentationMode,
    dataOrigin: dataOrigin ?? this.dataOrigin,
    hasData: hasData ?? this.hasData,
    entryCount: entryCount ?? this.entryCount,
    preparedPreviewRowCount:
        preparedPreviewRowCount ?? this.preparedPreviewRowCount,
    frameDigest: frameDigest ?? this.frameDigest,
    displayFrameNumber: displayFrameNumber ?? this.displayFrameNumber,
    motionState: motionState ?? this.motionState,
  );
}

/// One compact typed record. Fields not meaningful for an event retain their
/// zero/null value, avoiding a Map allocation in the interaction path.
@immutable
final class DashboardRailFlightEvent {
  const DashboardRailFlightEvent({
    required this.type,
    required this.timestampMicros,
    required this.gestureId,
    required this.context,
    this.sampleCount = 0,
    this.totalPointerDistance = 0,
    this.gestureDurationMicros = 0,
    this.maxInstantVelocity = 0,
    this.averageVelocity = 0,
    this.lastThreeSampleVelocities = const <double>[],
    this.pointerEventGapP50Micros = 0,
    this.pointerEventGapP95Micros = 0,
    this.longestPointerEventGapMicros = 0,
    this.pointerX = 0,
    this.pointerY = 0,
    this.dragEndVelocity = 0,
    this.primaryVelocity = 0,
    this.ballisticInputVelocity = 0,
    this.startPixels = 0,
    this.releasePixels = 0,
    this.finalPixels = 0,
    this.startLogicalIndex = 0,
    this.finalLogicalIndex = 0,
    this.targetPixels,
    this.targetRawIndex,
    this.identities,
    this.geometry,
    this.oldGeometry,
    this.activityInterruptCount = 0,
    this.metricChangeCount = 0,
    this.crossedChildCount = 0,
    this.populatedChildCrossCount = 0,
    this.emptyChildCrossCount = 0,
    this.elapsedMicros = 0,
    this.previousActivity,
    this.nextActivity,
    this.previousActivityIdentity = 0,
    this.nextActivityIdentity = 0,
    this.activityReason,
    this.simulationKind,
    this.applyMicros = 0,
    this.selectorMicros = 0,
    this.equalityMicros = 0,
    this.notifierMicros = 0,
    this.amountBindMicros = 0,
    this.countBindMicros = 0,
    this.logViewportBindMicros = 0,
    this.presentationApplyTotalMicros = 0,
    this.presentationApplyMaxMicros = 0,
    this.widgetsMarkedNeedsBuild = 0,
    this.renderObjectsMarkedNeedsLayout = 0,
    this.renderObjectsMarkedNeedsPaint = 0,
    this.rootDashboardRebuildScheduled = false,
    this.railRebuildScheduled = false,
    this.logViewportRebuildScheduled = false,
    this.rootRebuildCount = 0,
    this.railRebuildCount = 0,
    this.logViewportRebuildCount = 0,
    this.dataIoCount = 0,
    this.platformCallCount = 0,
    this.sqlCount = 0,
    this.uiFrameCountDuringDrag = 0,
    this.missedFrameCountDuringDrag = 0,
    this.uiFrameP50Micros = 0,
    this.uiFrameP90Micros = 0,
    this.uiFrameP95Micros = 0,
    this.uiFrameP99Micros = 0,
    this.rasterFrameP50Micros = 0,
    this.rasterFrameP90Micros = 0,
    this.rasterFrameP95Micros = 0,
    this.rasterFrameP99Micros = 0,
    this.longestUiFrameMicros = 0,
    this.longestRasterFrameMicros = 0,
    this.buildDurationMicros = 0,
    this.layoutDurationMicros = 0,
    this.paintDurationMicros = 0,
    this.rasterDurationMicros = 0,
    this.missedFrameCount = 0,
    this.gcCount = 0,
    this.gcPauseMicros = 0,
    this.allocationBytes = 0,
  });

  final DashboardRailFlightEventType type;
  final int timestampMicros;
  final int gestureId;
  final DashboardRailFlightContext context;
  final int sampleCount;
  final double totalPointerDistance;
  final int gestureDurationMicros;
  final double maxInstantVelocity;
  final double averageVelocity;
  final List<double> lastThreeSampleVelocities;
  final int pointerEventGapP50Micros;
  final int pointerEventGapP95Micros;
  final int longestPointerEventGapMicros;
  final double pointerX;
  final double pointerY;
  final double dragEndVelocity;
  final double primaryVelocity;
  final double ballisticInputVelocity;
  final double startPixels;
  final double releasePixels;
  final double finalPixels;
  final int startLogicalIndex;
  final int finalLogicalIndex;
  final double? targetPixels;
  final double? targetRawIndex;
  final CenteredCarouselMotionIdentity? identities;
  final CenteredCarouselScrollGeometry? geometry;
  final CenteredCarouselScrollGeometry? oldGeometry;
  final int activityInterruptCount;
  final int metricChangeCount;
  final int crossedChildCount;
  final int populatedChildCrossCount;
  final int emptyChildCrossCount;
  final int elapsedMicros;
  final CenteredCarouselActivityKind? previousActivity;
  final CenteredCarouselActivityKind? nextActivity;
  final int previousActivityIdentity;
  final int nextActivityIdentity;
  final CenteredCarouselActivityChangeReason? activityReason;
  final CenteredCarouselSimulationKind? simulationKind;
  final int applyMicros;
  final int selectorMicros;
  final int equalityMicros;
  final int notifierMicros;
  final int amountBindMicros;
  final int countBindMicros;
  final int logViewportBindMicros;
  final int presentationApplyTotalMicros;
  final int presentationApplyMaxMicros;
  final int widgetsMarkedNeedsBuild;
  final int renderObjectsMarkedNeedsLayout;
  final int renderObjectsMarkedNeedsPaint;
  final bool rootDashboardRebuildScheduled;
  final bool railRebuildScheduled;
  final bool logViewportRebuildScheduled;
  final int rootRebuildCount;
  final int railRebuildCount;
  final int logViewportRebuildCount;
  final int dataIoCount;
  final int platformCallCount;
  final int sqlCount;
  final int uiFrameCountDuringDrag;
  final int missedFrameCountDuringDrag;
  final int uiFrameP50Micros;
  final int uiFrameP90Micros;
  final int uiFrameP95Micros;
  final int uiFrameP99Micros;
  final int rasterFrameP50Micros;
  final int rasterFrameP90Micros;
  final int rasterFrameP95Micros;
  final int rasterFrameP99Micros;
  final int longestUiFrameMicros;
  final int longestRasterFrameMicros;
  final int buildDurationMicros;
  final int layoutDurationMicros;
  final int paintDurationMicros;
  final int rasterDurationMicros;
  final int missedFrameCount;
  final int gcCount;
  final int gcPauseMicros;
  final int allocationBytes;

  LedgerQueryKey get queryKey => context.queryKey;
  LedgerQueryKey get parentQueryKey => context.parentQueryKey;
  int get entryCount => context.entryCount;
  int get preparedPreviewRowCount => context.preparedPreviewRowCount;

  /// Allocates only when profile tooling exports the bounded ring after a
  /// gesture; it is never called by the interaction path itself.
  Map<String, Object?> toReportMap() => <String, Object?>{
    'event': type.wireName,
    'timestamp_micros': timestampMicros,
    'gesture_id': gestureId,
    'motion_epoch': context.motionEpoch,
    'navigation_epoch': context.navigationEpoch,
    'presentation_epoch': context.presentationEpoch,
    'query_key': context.queryKey.value,
    'parent_query_key': context.parentQueryKey.value,
    'direction': context.direction.name,
    'child_kind': context.childKind.name,
    'plane': context.plane.name,
    'semantic_index': context.semanticIndex,
    'core_revision': context.coreRevision,
    'presentation_generation': context.presentationGeneration,
    'presentation_mode': context.presentationMode.name,
    'data_origin': context.dataOrigin.name,
    'motion_state': context.motionState.name,
    'display_frame_number': context.displayFrameNumber,
    'has_data': context.hasData,
    'entry_count': context.entryCount,
    'preview_row_count': context.preparedPreviewRowCount,
    'frame_digest': context.frameDigest,
    'sample_count': sampleCount,
    'total_pointer_distance': totalPointerDistance,
    'gesture_duration_micros': gestureDurationMicros,
    'max_instant_velocity': maxInstantVelocity,
    'average_velocity': averageVelocity,
    'last_three_sample_velocities': lastThreeSampleVelocities,
    'pointer_gap_p50_micros': pointerEventGapP50Micros,
    'pointer_gap_p95_micros': pointerEventGapP95Micros,
    'longest_pointer_gap_micros': longestPointerEventGapMicros,
    'pointer_x': pointerX,
    'pointer_y': pointerY,
    'drag_end_velocity': dragEndVelocity,
    'primary_velocity': primaryVelocity,
    'ballistic_input_velocity': ballisticInputVelocity,
    'start_pixels': startPixels,
    'release_pixels': releasePixels,
    'final_pixels': finalPixels,
    'start_logical_index': startLogicalIndex,
    'final_logical_index': finalLogicalIndex,
    'target_pixels': targetPixels,
    'target_raw_index': targetRawIndex,
    'identities': identities == null
        ? null
        : <String, Object?>{
            'controller': identities!.controllerIdentity,
            'position': identities!.positionIdentity,
            'physics': identities!.physicsIdentity,
            'viewport': identities!.viewportIdentity,
          },
    'geometry': geometry == null
        ? null
        : <String, Object?>{
            'pixels': geometry!.pixels,
            'min_extent': geometry!.minScrollExtent,
            'max_extent': geometry!.maxScrollExtent,
            'viewport_dimension': geometry!.viewportDimension,
            'item_extent': geometry!.itemExtent,
            'device_pixel_ratio': geometry!.devicePixelRatio,
          },
    'activity_interrupt_count': activityInterruptCount,
    'metric_change_count': metricChangeCount,
    'crossed_child_count': crossedChildCount,
    'populated_child_cross_count': populatedChildCrossCount,
    'empty_child_cross_count': emptyChildCrossCount,
    'elapsed_micros': elapsedMicros,
    'previous_activity': previousActivity?.name,
    'next_activity': nextActivity?.name,
    'activity_reason': activityReason?.name,
    'simulation_kind': simulationKind?.name,
    'apply_micros': applyMicros,
    'selector_micros': selectorMicros,
    'equality_micros': equalityMicros,
    'notifier_micros': notifierMicros,
    'amount_bind_micros': amountBindMicros,
    'count_bind_micros': countBindMicros,
    'log_viewport_bind_micros': logViewportBindMicros,
    'presentation_apply_total_micros': presentationApplyTotalMicros,
    'presentation_apply_max_micros': presentationApplyMaxMicros,
    'widgets_marked_needs_build': widgetsMarkedNeedsBuild,
    'render_objects_marked_needs_layout': renderObjectsMarkedNeedsLayout,
    'render_objects_marked_needs_paint': renderObjectsMarkedNeedsPaint,
    'root_rebuild_count': rootRebuildCount,
    'rail_rebuild_count': railRebuildCount,
    'log_viewport_rebuild_count': logViewportRebuildCount,
    'data_io_count': dataIoCount,
    'platform_call_count': platformCallCount,
    'sql_count': sqlCount,
    'ui_frame_count_during_drag': uiFrameCountDuringDrag,
    'missed_frame_count_during_drag': missedFrameCountDuringDrag,
    'ui_frame_p50_micros': uiFrameP50Micros,
    'ui_frame_p90_micros': uiFrameP90Micros,
    'ui_frame_p95_micros': uiFrameP95Micros,
    'ui_frame_p99_micros': uiFrameP99Micros,
    'raster_frame_p50_micros': rasterFrameP50Micros,
    'raster_frame_p90_micros': rasterFrameP90Micros,
    'raster_frame_p95_micros': rasterFrameP95Micros,
    'raster_frame_p99_micros': rasterFrameP99Micros,
    'longest_ui_frame_micros': longestUiFrameMicros,
    'longest_raster_frame_micros': longestRasterFrameMicros,
    'build_duration_micros': buildDurationMicros,
    'layout_duration_micros': layoutDurationMicros,
    'paint_duration_micros': paintDurationMicros,
    'raster_duration_micros': rasterDurationMicros,
    'missed_frame_count': missedFrameCount,
    'gc_count': gcCount,
    'gc_pause_micros': gcPauseMicros,
    'allocation_bytes': allocationBytes,
  };
}

/// Fixed-capacity dashboard flight recorder.
///
/// Pointer samples update one bounded accumulator. Only aggregate gesture and
/// semantic boundary events enter the ring; there is no per-pixel log stream.
final class DashboardRailFlightRecorder
    implements CenteredCarouselMotionDiagnosticSink {
  DashboardRailFlightRecorder({
    required this.enabled,
    this.capacity = 512,
    this.collectFrameTimings = true,
    DashboardRailFlightClock? clockMicros,
  }) : assert(capacity > 0),
       _clockMicros = clockMicros ?? (() => developer.Timeline.now),
       _ring = List<DashboardRailFlightEvent?>.filled(
         capacity,
         null,
         growable: false,
       ) {
    if (enabled && collectFrameTimings) {
      _timingsCallback = _recordFrameTimings;
      SchedulerBinding.instance.addTimingsCallback(_timingsCallback!);
    }
  }

  final bool enabled;
  final int capacity;
  final bool collectFrameTimings;
  final DashboardRailFlightClock _clockMicros;
  final List<DashboardRailFlightEvent?> _ring;
  DashboardRailFlightContextProvider? _contextProvider;
  DashboardPerformanceCounters? _performanceCounters;
  _GestureAccumulator? _active;
  int _writeCursor = 0;
  int _length = 0;
  bool _disposed = false;
  TimingsCallback? _timingsCallback;
  int _latestSelectorGeneration = -1;
  int _latestSelectorMicros = 0;
  _PendingPresentationApply? _pendingApply;

  int overwrittenEventCount = 0;

  @override
  bool get isEnabled => enabled && !_disposed;

  void bindContextProvider(DashboardRailFlightContextProvider provider) {
    _contextProvider = provider;
  }

  void bindPerformanceCounters(DashboardPerformanceCounters counters) {
    _performanceCounters = counters;
  }

  @override
  void record(CenteredCarouselMotionDiagnosticEvent event) {
    if (!isEnabled) return;
    final context = _requireContext();
    switch (event) {
      case CenteredCarouselGestureStarted():
        _active = _GestureAccumulator(
          event,
          counterStart: _performanceCounters?.snapshotValues(),
        );
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.gestureStart,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            startPixels: event.startPixels,
            startLogicalIndex: event.startLogicalIndex,
            pointerX: event.pointerX,
            pointerY: event.pointerY,
            identities: event.identities,
            geometry: event.geometry,
          ),
        );
      case CenteredCarouselGestureSample():
        _active?.addSample(event);
      case CenteredCarouselGestureReleased():
        final active = _active;
        if (active != null) {
          _append(active.summary(context, _clockMicros()));
        }
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.gestureReleased,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            dragEndVelocity: event.dragEndVelocityX,
            primaryVelocity: event.primaryVelocity,
            startPixels: event.startPixels,
            releasePixels: event.releasePixels,
            startLogicalIndex: event.semanticStartIndex,
            finalLogicalIndex: event.semanticReleaseIndex,
            identities: event.identities,
            geometry: event.geometry,
          ),
        );
      case CenteredCarouselBallisticStarted():
        _active?.ballisticInputVelocity = event.inputVelocity;
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.ballisticStarted,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            ballisticInputVelocity: event.inputVelocity,
            startPixels: event.simulationStartPosition,
            targetPixels: event.targetPixels,
            targetRawIndex: event.targetRawIndex,
            identities: event.identities,
            geometry: event.geometry,
            nextActivityIdentity: event.activityIdentity,
            simulationKind: event.simulationKind,
          ),
        );
      case CenteredCarouselScrollMetricsChanged():
        _active?.metricChangeCount += 1;
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.scrollMetricsChanged,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            oldGeometry: event.oldGeometry,
            geometry: event.newGeometry,
            releasePixels: event.correctedPixels,
            metricChangeCount: _active?.metricChangeCount ?? 1,
            nextActivityIdentity: event.activityIdentity,
          ),
        );
      case CenteredCarouselScrollActivityChanged():
        final interrupted =
            event.previousActivity == CenteredCarouselActivityKind.ballistic &&
            event.nextActivity != CenteredCarouselActivityKind.ballistic &&
            event.nextActivity != CenteredCarouselActivityKind.idle;
        if (interrupted) _active?.activityInterruptCount += 1;
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.scrollActivityChanged,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            previousActivity: event.previousActivity,
            nextActivity: event.nextActivity,
            previousActivityIdentity: event.previousActivityIdentity,
            nextActivityIdentity: event.nextActivityIdentity,
            activityReason: event.reason,
            startPixels: event.currentPixels,
            ballisticInputVelocity: event.currentVelocity,
          ),
        );
      case CenteredCarouselSettled():
        final active = _active;
        if (active != null) {
          _append(
            active.frameTiming(context, _clockMicros(), _performanceCounters),
          );
        }
        _append(
          DashboardRailFlightEvent(
            type: DashboardRailFlightEventType.railSettled,
            timestampMicros: event.timestampMicros,
            gestureId: event.gestureId,
            context: context,
            ballisticInputVelocity: event.inputVelocity,
            startPixels: event.startPixels,
            finalPixels: event.finalPixels,
            startLogicalIndex: event.startLogicalIndex,
            finalLogicalIndex: event.finalLogicalIndex,
            elapsedMicros: event.elapsedMicros,
            crossedChildCount: event.crossedChildCount,
            populatedChildCrossCount: active?.populatedChildCrossCount ?? 0,
            emptyChildCrossCount: active?.emptyChildCrossCount ?? 0,
            activityInterruptCount: event.activityInterruptCount,
            metricChangeCount: event.metricChangeCount,
            presentationApplyTotalMicros:
                active?.presentationApplyTotalMicros ?? 0,
            presentationApplyMaxMicros: active?.presentationApplyMaxMicros ?? 0,
            rootRebuildCount:
                active?.counterDelta(
                  _performanceCounters,
                  DashboardPerformanceMetric.dashboardRootBuild,
                ) ??
                0,
            railRebuildCount:
                active?.counterDelta(
                  _performanceCounters,
                  DashboardPerformanceMetric.railSubtreeBuild,
                ) ??
                0,
            logViewportRebuildCount:
                active?.counterDelta(
                  _performanceCounters,
                  DashboardPerformanceMetric.logViewportBuild,
                ) ??
                0,
            dataIoCount: active?.dataIoCount(_performanceCounters) ?? 0,
            platformCallCount:
                active?.counterDelta(
                  _performanceCounters,
                  DashboardPerformanceMetric.platformCallsDuringMotion,
                ) ??
                0,
            sqlCount:
                active?.counterDelta(
                  _performanceCounters,
                  DashboardPerformanceMetric.sqlCallsDuringMotion,
                ) ??
                0,
            identities: event.identities,
            geometry: event.geometry,
          ),
        );
        _active = null;
    }
  }

  List<DashboardRailFlightEvent> snapshot() {
    if (_length == 0) return const <DashboardRailFlightEvent>[];
    final start = _length == capacity ? _writeCursor : 0;
    return List<DashboardRailFlightEvent>.unmodifiable(
      List<DashboardRailFlightEvent>.generate(_length, (index) {
        return _ring[(start + index) % capacity]!;
      }, growable: false),
    );
  }

  void clear() {
    _ring.fillRange(0, _ring.length, null);
    _writeCursor = 0;
    _length = 0;
    overwrittenEventCount = 0;
    _active = null;
    _pendingApply = null;
  }

  void dispose() {
    final timingsCallback = _timingsCallback;
    if (timingsCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(timingsCallback);
      _timingsCallback = null;
    }
    _disposed = true;
    _active = null;
    _contextProvider = null;
    _performanceCounters = null;
    _pendingApply = null;
  }

  void recordPreparedFrameSelected(
    DashboardVisibleFrame frame, {
    required int selectorMicros,
  }) {
    if (!isEnabled) return;
    _latestSelectorGeneration = frame.frameGeneration;
    _latestSelectorMicros = selectorMicros;
    final context = _contextForFrame(frame);
    if (context.hasData) {
      _active?.populatedChildCrossCount += 1;
    } else {
      _active?.emptyChildCrossCount += 1;
    }
    _append(
      DashboardRailFlightEvent(
        type: DashboardRailFlightEventType.semanticChildCrossed,
        timestampMicros: _clockMicros(),
        gestureId: _active?.gestureId ?? 0,
        context: context,
        selectorMicros: selectorMicros,
      ),
    );
  }

  void recordPresentationApplyStarted(
    DashboardVisibleFrame frame,
    DashboardPerformanceCounters counters,
  ) {
    if (!isEnabled) return;
    final selectorMicros = frame.frameGeneration == _latestSelectorGeneration
        ? _latestSelectorMicros
        : 0;
    final context = _contextForFrame(frame);
    _pendingApply = _PendingPresentationApply(
      frame: frame,
      context: context,
      startedMicros: _clockMicros(),
      selectorMicros: selectorMicros,
      countersBefore: counters.snapshotValues(),
    );
    _append(
      DashboardRailFlightEvent(
        type: DashboardRailFlightEventType.presentationApplyStarted,
        timestampMicros: _pendingApply!.startedMicros,
        gestureId: _active?.gestureId ?? 0,
        context: context,
        selectorMicros: selectorMicros,
      ),
    );
  }

  void recordPresentationApplyCompleted(
    DashboardVisibleFrame frame, {
    required int applyMicros,
    required int equalityMicros,
    required int notifierMicros,
    required DashboardPerformanceCounters counters,
  }) {
    if (!isEnabled) return;
    final pending = _pendingApply;
    if (pending == null ||
        pending.frame.frameGeneration != frame.frameGeneration) {
      return;
    }
    pending
      ..applyMicros = applyMicros
      ..equalityMicros = equalityMicros
      ..notifierMicros = notifierMicros;
    final active = _active;
    if (active != null) {
      active.presentationApplyTotalMicros += applyMicros;
      if (applyMicros > active.presentationApplyMaxMicros) {
        active.presentationApplyMaxMicros = applyMicros;
      }
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!isEnabled || !identical(_pendingApply, pending)) return;
      _pendingApply = null;
      final after = counters.snapshotValues();
      int delta(DashboardPerformanceMetric metric) =>
          after[metric.index] - pending.countersBefore[metric.index];
      final amountMicros = delta(DashboardPerformanceMetric.amountBindMicros);
      final countMicros = delta(DashboardPerformanceMetric.countBindMicros);
      final logMicros = delta(DashboardPerformanceMetric.logViewportBindMicros);
      final rootBuilds = delta(DashboardPerformanceMetric.dashboardRootBuild);
      final railBuilds = delta(DashboardPerformanceMetric.railSubtreeBuild);
      final logBuilds = delta(DashboardPerformanceMetric.logBoxBuild);
      final widgetsMarked =
          delta(DashboardPerformanceMetric.amountBuild) +
          delta(DashboardPerformanceMetric.countBuild) +
          delta(DashboardPerformanceMetric.logBoxBuild) +
          delta(DashboardPerformanceMetric.summaryNavigationTextBuild);
      final layoutMarks =
          delta(DashboardPerformanceMetric.railLayout) +
          delta(DashboardPerformanceMetric.logLayout);
      final paintMarks =
          delta(DashboardPerformanceMetric.railPaint) +
          delta(DashboardPerformanceMetric.logPaint);
      _append(
        DashboardRailFlightEvent(
          type: DashboardRailFlightEventType.presentationApplyCompleted,
          timestampMicros: _clockMicros(),
          gestureId: _active?.gestureId ?? 0,
          context: pending.context,
          applyMicros: pending.applyMicros,
          selectorMicros: pending.selectorMicros,
          equalityMicros: pending.equalityMicros,
          notifierMicros: pending.notifierMicros,
          amountBindMicros: amountMicros,
          countBindMicros: countMicros,
          logViewportBindMicros: logMicros,
          widgetsMarkedNeedsBuild: widgetsMarked,
          renderObjectsMarkedNeedsLayout: layoutMarks,
          renderObjectsMarkedNeedsPaint: paintMarks,
          rootDashboardRebuildScheduled: rootBuilds > 0,
          railRebuildScheduled: railBuilds > 0,
          logViewportRebuildScheduled: logBuilds > 0,
        ),
      );
    });
  }

  DashboardRailFlightContext _requireContext() {
    final provider = _contextProvider;
    if (provider == null) {
      throw StateError('Dashboard rail flight context is not bound.');
    }
    return provider();
  }

  DashboardRailFlightContext _contextForFrame(DashboardVisibleFrame frame) {
    final base = _requireContext();
    final prepared = frame.preparedFrame;
    return base.copyWith(
      queryKey: frame.queryKey,
      parentQueryKey: frame.parentQueryKey,
      direction: frame.direction,
      plane: frame.plane,
      semanticIndex: frame.semanticChildIndex,
      coreRevision: frame.coreRevision,
      presentationGeneration: frame.frameGeneration,
      presentationMode: frame.mode,
      hasData: prepared.entryCount > 0,
      entryCount: prepared.entryCount,
      preparedPreviewRowCount: prepared.stableRowIdentities.length,
      frameDigest: frame.visualDigest,
    );
  }

  void _append(DashboardRailFlightEvent event) {
    if (_length == capacity) {
      overwrittenEventCount += 1;
    } else {
      _length += 1;
    }
    _ring[_writeCursor] = event;
    _writeCursor = (_writeCursor + 1) % capacity;
  }

  void _recordFrameTimings(List<FrameTiming> timings) {
    final active = _active;
    if (!isEnabled || active == null) return;
    for (final timing in timings) {
      active.addFrameTiming(timing);
    }
  }
}

final class _PendingPresentationApply {
  _PendingPresentationApply({
    required this.frame,
    required this.context,
    required this.startedMicros,
    required this.selectorMicros,
    required this.countersBefore,
  });

  final DashboardVisibleFrame frame;
  final DashboardRailFlightContext context;
  final int startedMicros;
  final int selectorMicros;
  final List<int> countersBefore;
  int applyMicros = 0;
  int equalityMicros = 0;
  int notifierMicros = 0;
}

final class _GestureAccumulator {
  _GestureAccumulator(
    CenteredCarouselGestureStarted start, {
    required this.counterStart,
  }) : gestureId = start.gestureId,
       startEventMicros = start.eventTimestampMicros,
       lastEventMicros = start.eventTimestampMicros,
       lastX = start.pointerX;

  static const int _gapBucketMicros = 1000;
  static const int _gapBucketCount = 65;

  final int gestureId;
  final List<int>? counterStart;
  final int startEventMicros;
  int lastEventMicros;
  double lastX;
  int sampleCount = 0;
  double totalPointerDistance = 0;
  double maxInstantVelocity = 0;
  double velocitySum = 0;
  double _lastVelocity1 = 0;
  double _lastVelocity2 = 0;
  double _lastVelocity3 = 0;
  int _velocityCount = 0;
  final List<int> _gapHistogram = List<int>.filled(
    _gapBucketCount,
    0,
    growable: false,
  );
  int longestGapMicros = 0;
  int metricChangeCount = 0;
  int activityInterruptCount = 0;
  double ballisticInputVelocity = 0;
  int populatedChildCrossCount = 0;
  int emptyChildCrossCount = 0;
  int presentationApplyTotalMicros = 0;
  int presentationApplyMaxMicros = 0;
  static const int _maximumFrameSamples = 512;
  final List<int> _uiFrameMicros = List<int>.filled(
    _maximumFrameSamples,
    0,
    growable: false,
  );
  final List<int> _rasterFrameMicros = List<int>.filled(
    _maximumFrameSamples,
    0,
    growable: false,
  );
  int _frameSampleCount = 0;
  int _missedFrameCount = 0;

  void addSample(CenteredCarouselGestureSample sample) {
    final gap = sample.eventTimestampMicros - lastEventMicros;
    final delta = sample.pointerX - lastX;
    if (gap > 0) {
      final velocity = delta * Duration.microsecondsPerSecond / gap;
      final speed = velocity.abs();
      if (speed > maxInstantVelocity) maxInstantVelocity = speed;
      velocitySum += velocity;
      _lastVelocity1 = _lastVelocity2;
      _lastVelocity2 = _lastVelocity3;
      _lastVelocity3 = velocity;
      _velocityCount += 1;
      final bucket = (gap ~/ _gapBucketMicros).clamp(0, _gapBucketCount - 1);
      _gapHistogram[bucket] += 1;
      if (gap > longestGapMicros) longestGapMicros = gap;
    }
    totalPointerDistance += delta.abs();
    sampleCount += 1;
    lastEventMicros = sample.eventTimestampMicros;
    lastX = sample.pointerX;
  }

  DashboardRailFlightEvent summary(
    DashboardRailFlightContext context,
    int timestampMicros,
  ) => DashboardRailFlightEvent(
    type: DashboardRailFlightEventType.gestureSampleSummary,
    timestampMicros: timestampMicros,
    gestureId: gestureId,
    context: context,
    sampleCount: sampleCount,
    totalPointerDistance: totalPointerDistance,
    gestureDurationMicros: lastEventMicros - startEventMicros,
    maxInstantVelocity: maxInstantVelocity,
    averageVelocity: _velocityCount == 0 ? 0 : velocitySum / _velocityCount,
    lastThreeSampleVelocities: List<double>.unmodifiable(
      switch (_velocityCount) {
        0 => const <double>[],
        1 => <double>[_lastVelocity3],
        2 => <double>[_lastVelocity2, _lastVelocity3],
        _ => <double>[_lastVelocity1, _lastVelocity2, _lastVelocity3],
      },
    ),
    pointerEventGapP50Micros: _percentileGap(.50),
    pointerEventGapP95Micros: _percentileGap(.95),
    longestPointerEventGapMicros: longestGapMicros,
    uiFrameCountDuringDrag: _captureFrameCountAtRelease(),
    missedFrameCountDuringDrag: _captureMissedFrameCountAtRelease(),
  );

  void addFrameTiming(FrameTiming timing) {
    if (_frameSampleCount >= _maximumFrameSamples) return;
    final uiMicros = timing.buildDuration.inMicroseconds;
    final rasterMicros = timing.rasterDuration.inMicroseconds;
    _uiFrameMicros[_frameSampleCount] = uiMicros;
    _rasterFrameMicros[_frameSampleCount] = rasterMicros;
    _frameSampleCount += 1;
    if (uiMicros > 16667 || rasterMicros > 16667) {
      _missedFrameCount += 1;
    }
  }

  DashboardRailFlightEvent frameTiming(
    DashboardRailFlightContext context,
    int timestampMicros,
    DashboardPerformanceCounters? counters,
  ) {
    final ui = _sortedFrameValues(_uiFrameMicros);
    final raster = _sortedFrameValues(_rasterFrameMicros);
    return DashboardRailFlightEvent(
      type: DashboardRailFlightEventType.frameTiming,
      timestampMicros: timestampMicros,
      gestureId: gestureId,
      context: context,
      uiFrameP50Micros: _percentile(ui, .50),
      uiFrameP90Micros: _percentile(ui, .90),
      uiFrameP95Micros: _percentile(ui, .95),
      uiFrameP99Micros: _percentile(ui, .99),
      rasterFrameP50Micros: _percentile(raster, .50),
      rasterFrameP90Micros: _percentile(raster, .90),
      rasterFrameP95Micros: _percentile(raster, .95),
      rasterFrameP99Micros: _percentile(raster, .99),
      longestUiFrameMicros: ui.isEmpty ? 0 : ui.last,
      longestRasterFrameMicros: raster.isEmpty ? 0 : raster.last,
      buildDurationMicros: _sumFrameValues(_uiFrameMicros),
      layoutDurationMicros:
          counterDelta(counters, DashboardPerformanceMetric.railLayoutMicros) +
          counterDelta(counters, DashboardPerformanceMetric.logLayoutMicros),
      paintDurationMicros:
          counterDelta(counters, DashboardPerformanceMetric.railPaintMicros) +
          counterDelta(counters, DashboardPerformanceMetric.logPaintMicros),
      rasterDurationMicros: _sumFrameValues(_rasterFrameMicros),
      missedFrameCount: _missedFrameCount,
    );
  }

  int _captureFrameCountAtRelease() => _frameSampleCount;

  int _captureMissedFrameCountAtRelease() => _missedFrameCount;

  int counterDelta(
    DashboardPerformanceCounters? counters,
    DashboardPerformanceMetric metric,
  ) {
    final before = counterStart;
    if (before == null || counters == null) return 0;
    return counters.value(metric) - before[metric.index];
  }

  int dataIoCount(DashboardPerformanceCounters? counters) {
    var total = 0;
    for (final metric in const <DashboardPerformanceMetric>[
      DashboardPerformanceMetric.sqlCallsDuringMotion,
      DashboardPerformanceMetric.platformCallsDuringMotion,
      DashboardPerformanceMetric.repositoryReadsDuringMotion,
      DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
      DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
      DashboardPerformanceMetric.formattingDuringMotion,
    ]) {
      total += counterDelta(counters, metric);
    }
    return total;
  }

  List<int> _sortedFrameValues(List<int> source) {
    if (_frameSampleCount == 0) return const <int>[];
    final values = source.sublist(0, _frameSampleCount)..sort();
    return values;
  }

  int _sumFrameValues(List<int> source) {
    var total = 0;
    for (var index = 0; index < _frameSampleCount; index += 1) {
      total += source[index];
    }
    return total;
  }

  static int _percentile(List<int> sorted, double percentile) {
    if (sorted.isEmpty) return 0;
    final index = ((sorted.length - 1) * percentile).ceil();
    return sorted[index];
  }

  int _percentileGap(double percentile) {
    if (sampleCount == 0) return 0;
    final target = (sampleCount * percentile).ceil();
    var cumulative = 0;
    for (var index = 0; index < _gapHistogram.length; index += 1) {
      cumulative += _gapHistogram[index];
      if (cumulative >= target) return index * _gapBucketMicros;
    }
    return (_gapBucketCount - 1) * _gapBucketMicros;
  }
}
