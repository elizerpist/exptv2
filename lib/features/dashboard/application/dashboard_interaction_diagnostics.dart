import 'package:flutter/foundation.dart';

import '../query/domain/current_ledger_query_scope.dart';
import '../motion/dashboard_motion_state.dart';
import '../runtime/domain/prepared_dashboard_index.dart';
import 'dashboard_performance_counters.dart';

enum DashboardInteractionEvent {
  globalRevisionWatchSubscribed,
  globalRevisionChanged,
  indexBuildStarted,
  indexBuildReady,
  indexPublished,
  navPresentationSelected,
  railChildCrossed,
  settleMetadataCommitted,
  verticalPageRequested,
  motionDataIoViolation,
  motionGestureStarted,
  motionBallisticStarted,
  motionFrameTargetSelected,
  visibleFramePublished,
  motionSettled,
  staleCallbackRejected,
}

extension DashboardInteractionEventWireName on DashboardInteractionEvent {
  String get wireName => switch (this) {
    DashboardInteractionEvent.globalRevisionWatchSubscribed =>
      'GLOBAL_REVISION_WATCH_SUBSCRIBED',
    DashboardInteractionEvent.globalRevisionChanged =>
      'GLOBAL_REVISION_CHANGED',
    DashboardInteractionEvent.indexBuildStarted => 'INDEX_BUILD_STARTED',
    DashboardInteractionEvent.indexBuildReady => 'INDEX_BUILD_READY',
    DashboardInteractionEvent.indexPublished => 'INDEX_PUBLISHED',
    DashboardInteractionEvent.navPresentationSelected =>
      'NAV_PRESENTATION_SELECTED',
    DashboardInteractionEvent.railChildCrossed => 'RAIL_CHILD_CROSSED',
    DashboardInteractionEvent.settleMetadataCommitted =>
      'SETTLE_METADATA_COMMITTED',
    DashboardInteractionEvent.verticalPageRequested =>
      'VERTICAL_PAGE_REQUESTED',
    DashboardInteractionEvent.motionDataIoViolation =>
      'MOTION_DATA_IO_VIOLATION',
    DashboardInteractionEvent.motionGestureStarted => 'MOTION_GESTURE_STARTED',
    DashboardInteractionEvent.motionBallisticStarted =>
      'MOTION_BALLISTIC_STARTED',
    DashboardInteractionEvent.motionFrameTargetSelected =>
      'MOTION_FRAME_TARGET_SELECTED',
    DashboardInteractionEvent.visibleFramePublished =>
      'VISIBLE_FRAME_PUBLISHED',
    DashboardInteractionEvent.motionSettled => 'MOTION_SETTLED',
    DashboardInteractionEvent.staleCallbackRejected =>
      'STALE_CALLBACK_REJECTED',
  };
}

enum DashboardDataOperation {
  sql,
  platformChannel,
  repositoryRead,
  liveLeaseStart,
  logBoxProjection,
  formatting,
}

@immutable
final class DashboardDiagnosticContext {
  const DashboardDiagnosticContext({
    required this.gestureId,
    required this.motionEpoch,
    required this.navigationEpoch,
    required this.presentationEpoch,
    required this.queryKey,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.semanticIndex,
    required this.frameNumber,
    this.presentationGeneration = 0,
    this.dataGeneration = 0,
    this.presentationMode = DashboardPresentationMode.committed,
    this.dataOrigin = DashboardDataOrigin.preparedIndex,
    this.motionState = DashboardMotionActivity.idle,
    this.acquisitionReason,
  });

  static const empty = DashboardDiagnosticContext(
    gestureId: 0,
    motionEpoch: 0,
    navigationEpoch: 0,
    presentationEpoch: 0,
    queryKey: null,
    parentQueryKey: null,
    coreRevision: 0,
    semanticIndex: -1,
    frameNumber: 0,
  );

  final int gestureId;
  final int motionEpoch;
  final int navigationEpoch;
  final int presentationEpoch;
  final LedgerQueryKey? queryKey;
  final LedgerQueryKey? parentQueryKey;
  final int coreRevision;
  final int semanticIndex;
  final int frameNumber;
  final int presentationGeneration;
  final int dataGeneration;
  final DashboardPresentationMode presentationMode;
  final DashboardDataOrigin dataOrigin;
  final DashboardMotionActivity motionState;
  final DataAcquisitionReason? acquisitionReason;

  DashboardDiagnosticContext copyWith({
    int? gestureId,
    int? motionEpoch,
    int? navigationEpoch,
    int? presentationEpoch,
    LedgerQueryKey? queryKey,
    LedgerQueryKey? parentQueryKey,
    int? coreRevision,
    int? semanticIndex,
    int? frameNumber,
    int? presentationGeneration,
    int? dataGeneration,
    DashboardPresentationMode? presentationMode,
    DashboardDataOrigin? dataOrigin,
    DashboardMotionActivity? motionState,
    DataAcquisitionReason? acquisitionReason,
  }) => DashboardDiagnosticContext(
    gestureId: gestureId ?? this.gestureId,
    motionEpoch: motionEpoch ?? this.motionEpoch,
    navigationEpoch: navigationEpoch ?? this.navigationEpoch,
    presentationEpoch: presentationEpoch ?? this.presentationEpoch,
    queryKey: queryKey ?? this.queryKey,
    parentQueryKey: parentQueryKey ?? this.parentQueryKey,
    coreRevision: coreRevision ?? this.coreRevision,
    semanticIndex: semanticIndex ?? this.semanticIndex,
    frameNumber: frameNumber ?? this.frameNumber,
    presentationGeneration:
        presentationGeneration ?? this.presentationGeneration,
    dataGeneration: dataGeneration ?? this.dataGeneration,
    presentationMode: presentationMode ?? this.presentationMode,
    dataOrigin: dataOrigin ?? this.dataOrigin,
    motionState: motionState ?? this.motionState,
    acquisitionReason: acquisitionReason ?? this.acquisitionReason,
  );
}

@immutable
final class DashboardInteractionDiagnosticEvent {
  const DashboardInteractionDiagnosticEvent({
    required this.event,
    required this.context,
    required this.source,
    required this.durationMicros,
  });

  final DashboardInteractionEvent event;
  final DashboardDiagnosticContext context;
  final String source;
  final int? durationMicros;

  String get name => event.wireName;
  int get gestureId => context.gestureId;
  int get motionEpoch => context.motionEpoch;
  int get navigationEpoch => context.navigationEpoch;
  int get presentationEpoch => context.presentationEpoch;
  LedgerQueryKey? get queryKey => context.queryKey;
  LedgerQueryKey? get parentQueryKey => context.parentQueryKey;
  int get coreRevision => context.coreRevision;
  int get semanticIndex => context.semanticIndex;
  int get frameNumber => context.frameNumber;
  int get presentationGeneration => context.presentationGeneration;
  int get dataGeneration => context.dataGeneration;
  DashboardPresentationMode get presentationMode => context.presentationMode;
  DashboardDataOrigin get dataOrigin => context.dataOrigin;
  DashboardMotionActivity get motionState => context.motionState;
  DataAcquisitionReason? get acquisitionReason => context.acquisitionReason;
}

typedef DashboardInteractionDiagnosticSink =
    void Function(DashboardInteractionDiagnosticEvent event);

/// Allocation-bounded dashboard instrumentation.
///
/// The production default has no event sink and suppresses per-crossing
/// events. Fixed numeric slots remain available to profile tooling without
/// retaining query objects, rows or callback queues.
final class DashboardInteractionDiagnostics {
  DashboardInteractionDiagnostics({
    DashboardPerformanceCounters? counters,
    this.sink,
    this.verboseSemanticCrossings = false,
  }) : counters = counters ?? DashboardPerformanceCounters();

  final DashboardPerformanceCounters counters;
  final DashboardInteractionDiagnosticSink? sink;
  final bool verboseSemanticCrossings;
  int _motionHotPathDepth = 0;
  bool _motionActive = false;

  bool get isInMotionHotPath => _motionHotPathDepth > 0;
  bool get isMotionActive => _motionActive;
  bool get hasSink => sink != null;
  bool get recordsSemanticCrossings => verboseSemanticCrossings && sink != null;

  void setMotionActive(bool active) => _motionActive = active;

  T runMotionHotPath<T>(T Function() operation) {
    _motionHotPathDepth += 1;
    try {
      return operation();
    } finally {
      _motionHotPathDepth -= 1;
    }
  }

  void record(
    DashboardInteractionEvent event, {
    required DashboardDiagnosticContext context,
    required String source,
    Duration? duration,
  }) {
    switch (event) {
      case DashboardInteractionEvent.visibleFramePublished:
        counters.increment(DashboardPerformanceMetric.visibleFramePublish);
      case DashboardInteractionEvent.staleCallbackRejected:
        counters.increment(DashboardPerformanceMetric.staleCallbacksDropped);
      case _:
        break;
    }
    if (!verboseSemanticCrossings &&
        (event == DashboardInteractionEvent.railChildCrossed ||
            event == DashboardInteractionEvent.motionFrameTargetSelected)) {
      return;
    }
    final target = sink;
    if (target == null) return;
    target(
      DashboardInteractionDiagnosticEvent(
        event: event,
        context: context,
        source: source,
        durationMicros: duration?.inMicroseconds,
      ),
    );
  }

  void recordDataOperation(
    DashboardDataOperation operation, {
    DashboardDiagnosticContext context = DashboardDiagnosticContext.empty,
    DataAcquisitionReason? acquisitionReason,
  }) {
    if (!isInMotionHotPath && !_motionActive) return;
    counters.increment(switch (operation) {
      DashboardDataOperation.sql =>
        DashboardPerformanceMetric.sqlCallsDuringMotion,
      DashboardDataOperation.platformChannel =>
        DashboardPerformanceMetric.platformCallsDuringMotion,
      DashboardDataOperation.repositoryRead =>
        DashboardPerformanceMetric.repositoryReadsDuringMotion,
      DashboardDataOperation.liveLeaseStart =>
        DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
      DashboardDataOperation.logBoxProjection =>
        DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
      DashboardDataOperation.formatting =>
        DashboardPerformanceMetric.formattingDuringMotion,
    });
    record(
      DashboardInteractionEvent.motionDataIoViolation,
      context: context.copyWith(acquisitionReason: acquisitionReason),
      source: operation.name,
    );
    assert(
      false,
      'Dashboard data operation ${operation.name} entered active motion.',
    );
  }
}
