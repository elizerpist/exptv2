import 'package:flutter/foundation.dart';

/// Explicit provenance for a physical carousel activity.
enum RailMotionOrigin {
  none,
  userDrag,
  nativeBallistic,
  userTap,
  programmaticInitialisation,
  dimensionCorrection,
  programmaticRebase,
}

enum RailMotionState { idle, dragging, ballistic }

enum RailMotionEventKind {
  controllerAttached,
  activityChanged,
  programmaticMotionRequested,
  ballisticStarted,
  semanticSettle,
}

/// Fixed-shape data appended from the motion hot path.
///
/// Textual flow/query descriptions and stacks are intentionally excluded. A
/// diagnostics panel may format this data after the motion has ended.
@immutable
class RailMotionEvent {
  const RailMotionEvent({
    required this.kind,
    required this.epoch,
    required this.origin,
    required this.physicalIndex,
    required this.valueA,
    required this.valueB,
  });

  final RailMotionEventKind kind;
  final int epoch;
  final RailMotionOrigin origin;
  final int physicalIndex;
  final int valueA;
  final int valueB;
}

/// Bounded numeric ring buffer. Appending never formats, prints or copies an
/// event. [events] is an inspection/export boundary, not a motion API.
class RailMotionTrace {
  RailMotionTrace({this.capacity = 256}) : assert(capacity > 0);

  final int capacity;
  final List<RailMotionEvent> _events = <RailMotionEvent>[];

  List<RailMotionEvent> get events =>
      List<RailMotionEvent>.unmodifiable(_events);

  void record(
    RailMotionEventKind kind, {
    required int epoch,
    int physicalIndex = 0,
    RailMotionOrigin origin = RailMotionOrigin.none,
    int valueA = 0,
    int valueB = 0,
  }) {
    if (_events.length == capacity) {
      _events.removeAt(0);
    }
    _events.add(
      RailMotionEvent(
        kind: kind,
        epoch: epoch,
        origin: origin,
        physicalIndex: physicalIndex,
        valueA: valueA,
        valueB: valueB,
      ),
    );
  }

  void clear() => _events.clear();
}

@immutable
class RailMotionSnapshot {
  const RailMotionSnapshot({
    required this.epoch,
    required this.origin,
    required this.state,
  });

  final int epoch;
  final RailMotionOrigin origin;
  final RailMotionState state;
}
