import 'package:flutter/foundation.dart';

import '../query/domain/current_ledger_query_scope.dart';
import 'dashboard_performance_counters.dart';

enum DashboardInteractionEvent {
  motionGestureStarted,
  motionBallisticStarted,
  motionSemanticCrossed,
  motionFrameTargetSelected,
  visibleFramePublished,
  motionSettled,
  committedFramePromoted,
  liveLeaseStarted,
  liveFrameAccepted,
  preparedDeckCacheHit,
  preparedDeckCacheMiss,
  preparedDeckStarted,
  preparedDeckReady,
  preparedDeckDiscarded,
  staleCallbackRejected,
}

extension DashboardInteractionEventWireName on DashboardInteractionEvent {
  String get wireName => switch (this) {
    DashboardInteractionEvent.motionGestureStarted => 'MOTION_GESTURE_STARTED',
    DashboardInteractionEvent.motionBallisticStarted =>
      'MOTION_BALLISTIC_STARTED',
    DashboardInteractionEvent.motionSemanticCrossed =>
      'MOTION_SEMANTIC_CROSSED',
    DashboardInteractionEvent.motionFrameTargetSelected =>
      'MOTION_FRAME_TARGET_SELECTED',
    DashboardInteractionEvent.visibleFramePublished =>
      'VISIBLE_FRAME_PUBLISHED',
    DashboardInteractionEvent.motionSettled => 'MOTION_SETTLED',
    DashboardInteractionEvent.committedFramePromoted =>
      'COMMITTED_FRAME_PROMOTED',
    DashboardInteractionEvent.liveLeaseStarted => 'LIVE_LEASE_STARTED',
    DashboardInteractionEvent.liveFrameAccepted => 'LIVE_FRAME_ACCEPTED',
    DashboardInteractionEvent.preparedDeckCacheHit => 'PREPARED_DECK_CACHE_HIT',
    DashboardInteractionEvent.preparedDeckCacheMiss =>
      'PREPARED_DECK_CACHE_MISS',
    DashboardInteractionEvent.preparedDeckStarted => 'PREPARED_DECK_STARTED',
    DashboardInteractionEvent.preparedDeckReady => 'PREPARED_DECK_READY',
    DashboardInteractionEvent.preparedDeckDiscarded =>
      'PREPARED_DECK_DISCARDED',
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
      case DashboardInteractionEvent.preparedDeckDiscarded:
        counters.increment(DashboardPerformanceMetric.staleCallbacksDropped);
      case _:
        break;
    }
    if (!verboseSemanticCrossings &&
        (event == DashboardInteractionEvent.motionSemanticCrossed ||
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

  void recordDataOperation(DashboardDataOperation operation) {
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
  }
}
