import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Optional, typed observer for proving carousel motion invariants.
///
/// The carousel checks [isEnabled] before creating an event. Production uses
/// no sink, so the normal motion path performs neither clock reads nor event
/// allocations.
abstract interface class CenteredCarouselMotionDiagnosticSink {
  bool get isEnabled;

  void record(CenteredCarouselMotionDiagnosticEvent event);
}

/// Bounded semantic-tick cadence measurement shared by feature rails.
///
/// Raw scroll/pointer evidence remains owned by
/// [CenteredCarouselMotionDiagnosticSink]. This accumulator records only
/// discrete semantic crossings and therefore performs no per-pixel logging or
/// unbounded allocation on the motion path.
final class CenteredCarouselSemanticCadenceAccumulator {
  CenteredCarouselSemanticCadenceAccumulator({this.capacity = 64})
    : assert(capacity > 1);

  final int capacity;
  final List<int> _tickMicros = <int>[];
  int _startedAtMicros = 0;
  int _tickCount = 0;
  int _duplicateTickCount = 0;
  int _skippedSemanticIndexCount = 0;
  int? _lastSemanticIndex;

  void reset({int? startedAtMicros}) {
    _tickMicros.clear();
    _startedAtMicros = startedAtMicros ?? developer.Timeline.now;
    _tickCount = 0;
    _duplicateTickCount = 0;
    _skippedSemanticIndexCount = 0;
    _lastSemanticIndex = null;
  }

  void recordTick(int semanticIndex, {int? timestampMicros}) {
    final now = timestampMicros ?? developer.Timeline.now;
    if (_startedAtMicros == 0) reset(startedAtMicros: now);
    final previousIndex = _lastSemanticIndex;
    if (previousIndex != null) {
      final distance = (semanticIndex - previousIndex).abs();
      if (distance == 0) {
        _duplicateTickCount += 1;
      } else if (distance > 1) {
        _skippedSemanticIndexCount += distance - 1;
      }
    }
    _lastSemanticIndex = semanticIndex;
    _tickCount += 1;
    if (_tickMicros.length == capacity) _tickMicros.removeAt(0);
    _tickMicros.add(now);
  }

  CenteredCarouselSemanticCadenceSnapshot snapshot({int? endedAtMicros}) {
    final ended = endedAtMicros ?? developer.Timeline.now;
    final intervals = <int>[
      for (var index = 1; index < _tickMicros.length; index += 1)
        _tickMicros[index] - _tickMicros[index - 1],
    ]..sort();
    int percentile(double fraction) {
      if (intervals.isEmpty) return 0;
      final index = ((intervals.length - 1) * fraction).round();
      return intervals[index];
    }

    return CenteredCarouselSemanticCadenceSnapshot(
      tickCount: _tickCount,
      retainedTickCount: _tickMicros.length,
      durationMicros: _startedAtMicros == 0 ? 0 : ended - _startedAtMicros,
      firstTickLatencyMicros: _tickMicros.isEmpty || _startedAtMicros == 0
          ? 0
          : _tickMicros.first - _startedAtMicros,
      interTickMinimumMicros: intervals.isEmpty ? 0 : intervals.first,
      interTickMedianMicros: percentile(.50),
      interTickP95Micros: percentile(.95),
      interTickMaximumMicros: intervals.isEmpty ? 0 : intervals.last,
      longGapCount: intervals.where((value) => value > 32000).length,
      duplicateTickCount: _duplicateTickCount,
      skippedSemanticIndexCount: _skippedSemanticIndexCount,
    );
  }
}

@immutable
final class CenteredCarouselSemanticCadenceSnapshot {
  const CenteredCarouselSemanticCadenceSnapshot({
    required this.tickCount,
    required this.retainedTickCount,
    required this.durationMicros,
    required this.firstTickLatencyMicros,
    required this.interTickMinimumMicros,
    required this.interTickMedianMicros,
    required this.interTickP95Micros,
    required this.interTickMaximumMicros,
    required this.longGapCount,
    required this.duplicateTickCount,
    required this.skippedSemanticIndexCount,
  });

  final int tickCount;
  final int retainedTickCount;
  final int durationMicros;
  final int firstTickLatencyMicros;
  final int interTickMinimumMicros;
  final int interTickMedianMicros;
  final int interTickP95Micros;
  final int interTickMaximumMicros;
  final int longGapCount;
  final int duplicateTickCount;
  final int skippedSemanticIndexCount;
}

@immutable
final class CenteredCarouselMotionIdentity {
  const CenteredCarouselMotionIdentity({
    required this.controllerIdentity,
    required this.positionIdentity,
    required this.physicsIdentity,
    required this.viewportIdentity,
  });

  final int controllerIdentity;
  final int positionIdentity;
  final int physicsIdentity;
  final int viewportIdentity;
}

@immutable
final class CenteredCarouselScrollGeometry {
  const CenteredCarouselScrollGeometry({
    required this.pixels,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.viewportDimension,
    required this.itemExtent,
    required this.devicePixelRatio,
  });

  final double pixels;
  final double minScrollExtent;
  final double maxScrollExtent;
  final double viewportDimension;
  final double itemExtent;
  final double devicePixelRatio;

  bool hasSameScrollMetrics(CenteredCarouselScrollGeometry other) =>
      minScrollExtent == other.minScrollExtent &&
      maxScrollExtent == other.maxScrollExtent &&
      viewportDimension == other.viewportDimension &&
      itemExtent == other.itemExtent &&
      devicePixelRatio == other.devicePixelRatio;
}

enum CenteredCarouselSimulationKind { scrollSpring, parent, none }

enum CenteredCarouselActivityKind {
  detached,
  idle,
  hold,
  drag,
  ballistic,
  driven,
  other,
}

enum CenteredCarouselActivityChangeReason {
  positionAttached,
  positionDetached,
  pointerDown,
  dragStarted,
  scrollSample,
  ballisticStarted,
  scrollingIdle,
  metricsChanged,
}

enum CenteredCarouselMetricsChangeReason {
  viewportNotification,
  positionAttached,
}

@immutable
sealed class CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselMotionDiagnosticEvent({
    required this.gestureId,
    required this.timestampMicros,
  });

  final int gestureId;
  final int timestampMicros;
}

@immutable
final class CenteredCarouselGestureStarted
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselGestureStarted({
    required super.gestureId,
    required super.timestampMicros,
    required this.eventTimestampMicros,
    required this.startPixels,
    required this.startLogicalIndex,
    required this.pointerX,
    required this.pointerY,
    required this.identities,
    required this.geometry,
  });

  final int eventTimestampMicros;
  final double startPixels;
  final int startLogicalIndex;
  final double pointerX;
  final double pointerY;
  final CenteredCarouselMotionIdentity identities;
  final CenteredCarouselScrollGeometry geometry;
}

@immutable
final class CenteredCarouselGestureSample
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselGestureSample({
    required super.gestureId,
    required super.timestampMicros,
    required this.eventTimestampMicros,
    required this.pointerX,
    required this.pointerY,
  });

  final int eventTimestampMicros;
  final double pointerX;
  final double pointerY;
}

@immutable
final class CenteredCarouselGestureReleased
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselGestureReleased({
    required super.gestureId,
    required super.timestampMicros,
    required this.eventTimestampMicros,
    required this.dragEndVelocityX,
    required this.dragEndVelocityY,
    required this.primaryVelocity,
    required this.startPixels,
    required this.releasePixels,
    required this.semanticStartIndex,
    required this.semanticReleaseIndex,
    required this.identities,
    required this.geometry,
  });

  final int eventTimestampMicros;
  final double dragEndVelocityX;
  final double dragEndVelocityY;
  final double primaryVelocity;
  final double startPixels;
  final double releasePixels;
  final int semanticStartIndex;
  final int semanticReleaseIndex;
  final CenteredCarouselMotionIdentity identities;
  final CenteredCarouselScrollGeometry geometry;
}

@immutable
final class CenteredCarouselBallisticStarted
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselBallisticStarted({
    required super.gestureId,
    required super.timestampMicros,
    required this.inputVelocity,
    required this.simulationKind,
    required this.simulationStartPosition,
    required this.targetPixels,
    required this.targetRawIndex,
    required this.identities,
    required this.geometry,
    required this.activityIdentity,
  });

  final double inputVelocity;
  final CenteredCarouselSimulationKind simulationKind;
  final double simulationStartPosition;
  final double? targetPixels;
  final double? targetRawIndex;
  final CenteredCarouselMotionIdentity identities;
  final CenteredCarouselScrollGeometry geometry;
  final int activityIdentity;
}

@immutable
final class CenteredCarouselScrollMetricsChanged
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselScrollMetricsChanged({
    required super.gestureId,
    required super.timestampMicros,
    required this.oldGeometry,
    required this.newGeometry,
    required this.correctedPixels,
    required this.reason,
    required this.activityIdentity,
  });

  final CenteredCarouselScrollGeometry oldGeometry;
  final CenteredCarouselScrollGeometry newGeometry;
  final double correctedPixels;
  final CenteredCarouselMetricsChangeReason reason;
  final int activityIdentity;
}

@immutable
final class CenteredCarouselScrollActivityChanged
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselScrollActivityChanged({
    required super.gestureId,
    required super.timestampMicros,
    required this.previousActivity,
    required this.nextActivity,
    required this.previousActivityIdentity,
    required this.nextActivityIdentity,
    required this.reason,
    required this.currentPixels,
    required this.currentVelocity,
  });

  final CenteredCarouselActivityKind previousActivity;
  final CenteredCarouselActivityKind nextActivity;
  final int previousActivityIdentity;
  final int nextActivityIdentity;
  final CenteredCarouselActivityChangeReason reason;
  final double currentPixels;
  final double currentVelocity;
}

@immutable
final class CenteredCarouselSettled
    extends CenteredCarouselMotionDiagnosticEvent {
  const CenteredCarouselSettled({
    required super.gestureId,
    required super.timestampMicros,
    required this.inputVelocity,
    required this.startPixels,
    required this.finalPixels,
    required this.startLogicalIndex,
    required this.finalLogicalIndex,
    required this.elapsedMicros,
    required this.crossedChildCount,
    required this.activityInterruptCount,
    required this.metricChangeCount,
    required this.identities,
    required this.geometry,
  });

  final double inputVelocity;
  final double startPixels;
  final double finalPixels;
  final int startLogicalIndex;
  final int finalLogicalIndex;
  final int elapsedMicros;
  final int crossedChildCount;
  final int activityInterruptCount;
  final int metricChangeCount;
  final CenteredCarouselMotionIdentity identities;
  final CenteredCarouselScrollGeometry geometry;
}
