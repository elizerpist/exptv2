import 'package:flutter/foundation.dart';

enum DashboardMotionActivity { idle, drag, ballistic, programmatic, settling }

@immutable
final class DashboardMotionState {
  const DashboardMotionState({
    required this.offset,
    required this.velocity,
    required this.activity,
    required this.semanticIndex,
    required this.motionEpoch,
    required this.gestureId,
  });

  const DashboardMotionState.initial({this.semanticIndex = 0})
    : offset = 0,
      velocity = 0,
      activity = DashboardMotionActivity.idle,
      motionEpoch = 0,
      gestureId = 0;

  final double offset;
  final double velocity;
  final DashboardMotionActivity activity;
  final int semanticIndex;
  final int motionEpoch;
  final int gestureId;

  bool get isActive => activity != DashboardMotionActivity.idle;

  DashboardMotionState copyWith({
    double? offset,
    double? velocity,
    DashboardMotionActivity? activity,
    int? semanticIndex,
    int? motionEpoch,
    int? gestureId,
  }) => DashboardMotionState(
    offset: offset ?? this.offset,
    velocity: velocity ?? this.velocity,
    activity: activity ?? this.activity,
    semanticIndex: semanticIndex ?? this.semanticIndex,
    motionEpoch: motionEpoch ?? this.motionEpoch,
    gestureId: gestureId ?? this.gestureId,
  );
}

@immutable
final class DashboardMotionContext {
  const DashboardMotionContext({
    required this.gestureId,
    required this.motionEpoch,
    required this.semanticIndex,
  });

  final int gestureId;
  final int motionEpoch;
  final int semanticIndex;
}
