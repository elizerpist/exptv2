import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

@immutable
class RailFlingPlan {
  const RailFlingPlan({
    this.gestureEpoch = 0,
    this.createdAtPointerTimestamp = Duration.zero,
    required this.startPositionPx,
    required this.inputVelocityPxPerSecond,
    required this.clampedVelocityPxPerSecond,
    required this.effectiveVelocityPxPerSecond,
    required this.velocityBand,
    required this.itemDelta,
    required this.targetRawIndex,
    required this.targetPhysicalIndex,
    required this.targetLogicalIndex,
    required int maximumStep,
    required int projectedRawIndex,
  }) : _maximumStep = maximumStep,
       _projectedRawIndex = projectedRawIndex;

  final int gestureEpoch;
  final Duration createdAtPointerTimestamp;
  final double startPositionPx;
  final double inputVelocityPxPerSecond;
  final double clampedVelocityPxPerSecond;
  final double effectiveVelocityPxPerSecond;
  final String velocityBand;
  final int itemDelta;
  final int targetRawIndex;
  final int targetPhysicalIndex;
  final int targetLogicalIndex;

  final int _maximumStep;
  final int _projectedRawIndex;

  RailFlingPlan copyWith({
    int? gestureEpoch,
    Duration? createdAtPointerTimestamp,
    int? targetPhysicalIndex,
    int? targetLogicalIndex,
  }) => RailFlingPlan(
    gestureEpoch: gestureEpoch ?? this.gestureEpoch,
    createdAtPointerTimestamp:
        createdAtPointerTimestamp ?? this.createdAtPointerTimestamp,
    startPositionPx: startPositionPx,
    inputVelocityPxPerSecond: inputVelocityPxPerSecond,
    clampedVelocityPxPerSecond: clampedVelocityPxPerSecond,
    effectiveVelocityPxPerSecond: effectiveVelocityPxPerSecond,
    velocityBand: velocityBand,
    itemDelta: itemDelta,
    targetRawIndex: targetRawIndex,
    targetPhysicalIndex: targetPhysicalIndex ?? this.targetPhysicalIndex,
    targetLogicalIndex: targetLogicalIndex ?? this.targetLogicalIndex,
    maximumStep: _maximumStep,
    projectedRawIndex: _projectedRawIndex,
  );
}

int maximumStepForVelocity(
  double velocityItemsPerSecond, {
  int maxItemsPerFling = 5,
}) {
  final speed = velocityItemsPerSecond.abs();
  final profileStep = speed < .80
      ? 0
      : speed < 5.00
      ? 1
      : speed < 10.00
      ? 2
      : speed < 16.00
      ? 3
      : speed < 24.00
      ? 4
      : 5;
  return math.min(profileStep, maxItemsPerFling);
}

String velocityBandFor(double velocityItemsPerSecond) {
  final speed = velocityItemsPerSecond.abs();
  if (speed < .80) return 'nearest';
  if (speed < 5.00) return 'max-1';
  if (speed < 10.00) return 'max-2';
  if (speed < 16.00) return 'max-3';
  if (speed < 24.00) return 'max-4';
  return 'max-5';
}

double snapVelocityFor({
  required double effectiveVelocity,
  required double itemExtent,
}) {
  return (effectiveVelocity * .18).clamp(-itemExtent * 4.5, itemExtent * 4.5);
}

SpringDescription springForVelocity({
  required double velocityItemsPerSecond,
  required SpringDescription baseSpring,
}) {
  final speedT = ((velocityItemsPerSecond.abs() - .5) / 11.5)
      .clamp(0.0, 1.0)
      .toDouble();
  return SpringDescription.withDampingRatio(
    mass: baseSpring.mass,
    stiffness: lerpDouble(175.0, 340.0, speedT)!,
    ratio: 1.05,
  );
}

double calculateTargetRawIndex({
  required double currentPixels,
  required double velocity,
  required double itemExtent,
  required double minScrollExtent,
  required CenterSnapScrollPhysics physics,
}) {
  final plan = createFlingPlan(
    currentPixels: currentPixels,
    velocity: velocity,
    itemExtent: itemExtent,
    minScrollExtent: minScrollExtent,
    physics: physics,
  );
  return plan.targetRawIndex.toDouble();
}

RailFlingPlan createFlingPlan({
  int gestureEpoch = 0,
  Duration createdAtPointerTimestamp = Duration.zero,
  int Function(int physicalIndex)? logicalIndexForPhysical,
  required double currentPixels,
  required double velocity,
  required double itemExtent,
  required double minScrollExtent,
  required CenterSnapScrollPhysics physics,
}) {
  final currentRawIndex = (currentPixels - minScrollExtent) / itemExtent;
  final nearestIndex = currentRawIndex.round();
  final clampedVelocity = velocity
      .clamp(-physics.maximumFlingVelocity, physics.maximumFlingVelocity)
      .toDouble();
  final effectiveVelocity = clampedVelocity * physics.velocityMultiplier;
  final velocityItemsPerSecond = effectiveVelocity / itemExtent;
  final maximumStep = maximumStepForVelocity(
    velocityItemsPerSecond,
    maxItemsPerFling: physics.maxItemsPerFling,
  );

  var projectedIndex = nearestIndex;
  final logicalIndexFor = logicalIndexForPhysical ?? (index) => index;
  if (effectiveVelocity.abs() < physics.minimumFlingVelocity ||
      maximumStep == 0) {
    return RailFlingPlan(
      gestureEpoch: gestureEpoch,
      createdAtPointerTimestamp: createdAtPointerTimestamp,
      startPositionPx: currentPixels,
      inputVelocityPxPerSecond: velocity,
      clampedVelocityPxPerSecond: clampedVelocity,
      effectiveVelocityPxPerSecond: effectiveVelocity,
      velocityBand: velocityBandFor(velocityItemsPerSecond),
      itemDelta: 0,
      targetRawIndex: nearestIndex,
      targetPhysicalIndex: nearestIndex,
      targetLogicalIndex: logicalIndexFor(nearestIndex),
      maximumStep: maximumStep,
      projectedRawIndex: projectedIndex,
    );
  }

  final friction = FrictionSimulation(
    physics.frictionDrag,
    currentPixels,
    effectiveVelocity,
    tolerance: physics.snapTolerance,
  );
  final projectedRawIndex = (friction.finalX - minScrollExtent) / itemExtent;
  projectedIndex = projectedRawIndex.round();
  var delta = projectedIndex - nearestIndex;
  final direction = effectiveVelocity.sign.toInt();

  if (delta == 0 && physics.forceOneItemOnFling) delta = direction;
  if (delta.sign != direction) delta = direction;
  delta = delta.clamp(-maximumStep, maximumStep);
  final targetIndex = nearestIndex + delta;
  return RailFlingPlan(
    gestureEpoch: gestureEpoch,
    createdAtPointerTimestamp: createdAtPointerTimestamp,
    startPositionPx: currentPixels,
    inputVelocityPxPerSecond: velocity,
    clampedVelocityPxPerSecond: clampedVelocity,
    effectiveVelocityPxPerSecond: effectiveVelocity,
    velocityBand: velocityBandFor(velocityItemsPerSecond),
    itemDelta: delta,
    targetRawIndex: targetIndex,
    targetPhysicalIndex: targetIndex,
    targetLogicalIndex: logicalIndexFor(targetIndex),
    maximumStep: maximumStep,
    projectedRawIndex: projectedIndex,
  );
}

class CenterSnapScrollPhysics extends ScrollPhysics {
  const CenterSnapScrollPhysics({
    required this.itemExtent,
    required this.itemCount,
    required this.frictionDrag,
    required this.velocityMultiplier,
    required this.minimumFlingVelocity,
    required this.maximumFlingVelocity,
    required this.maxItemsPerFling,
    required this.forceOneItemOnFling,
    required this.snapSpring,
    required this.snapTolerance,
    super.parent,
  });

  final double itemExtent;
  final int itemCount;
  final double frictionDrag;
  final double velocityMultiplier;
  final double minimumFlingVelocity;
  final double maximumFlingVelocity;
  final int maxItemsPerFling;
  final bool forceOneItemOnFling;
  final SpringDescription snapSpring;
  final Tolerance snapTolerance;

  @override
  CenterSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CenterSnapScrollPhysics(
      itemExtent: itemExtent,
      itemCount: itemCount,
      frictionDrag: frictionDrag,
      velocityMultiplier: velocityMultiplier,
      minimumFlingVelocity: minimumFlingVelocity,
      maximumFlingVelocity: maximumFlingVelocity,
      maxItemsPerFling: maxItemsPerFling,
      forceOneItemOnFling: forceOneItemOnFling,
      snapSpring: snapSpring,
      snapTolerance: snapTolerance,
      parent: buildParent(ancestor),
    );
  }

  double _pixelsForIndex(int index, ScrollMetrics position) {
    return position.minScrollExtent + index * itemExtent;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }
    if (itemCount <= 0 || itemExtent <= 0) return null;

    final currentPixels = position.pixels;
    final rawPlan = createFlingPlan(
      currentPixels: currentPixels,
      velocity: velocity,
      itemExtent: itemExtent,
      minScrollExtent: position.minScrollExtent,
      physics: this,
    );
    final candidate = rawPlan.copyWith(
      targetPhysicalIndex: rawPlan.targetRawIndex.clamp(0, itemCount - 1),
    );
    // ScrollPhysics can be asked for a ballistic simulation more than once
    // for the same native gesture. This method therefore derives its plan only
    // from its arguments and immutable configuration: it never observes,
    // freezes or publishes the target.
    final plan = candidate;
    final targetIndex = plan.targetPhysicalIndex.clamp(0, itemCount - 1);
    final targetPixels = _pixelsForIndex(
      targetIndex,
      position,
    ).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    final clampedVelocity = velocity
        .clamp(-maximumFlingVelocity, maximumFlingVelocity)
        .toDouble();
    final effectiveVelocity = clampedVelocity * velocityMultiplier;
    final velocityItemsPerSecond = effectiveVelocity / itemExtent;
    final snapVelocity = snapVelocityFor(
      effectiveVelocity: effectiveVelocity,
      itemExtent: itemExtent,
    );
    final distanceToTarget = (targetPixels - currentPixels).abs();

    if (distanceToTarget <= snapTolerance.distance &&
        effectiveVelocity.abs() <= snapTolerance.velocity) {
      return null;
    }

    final spring = springForVelocity(
      velocityItemsPerSecond: velocityItemsPerSecond,
      baseSpring: snapSpring,
    );
    final simulation = ScrollSpringSimulation(
      spring,
      currentPixels,
      targetPixels,
      distanceToTarget <= snapTolerance.distance ? 0 : snapVelocity,
      tolerance: snapTolerance,
    );
    return simulation;
  }
}
