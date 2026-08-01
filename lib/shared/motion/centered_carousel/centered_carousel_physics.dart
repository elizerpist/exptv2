import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

int maximumStepForVelocity(
  double velocityItemsPerSecond, {
  int maxItemsPerFling = 5,
}) {
  final speed = velocityItemsPerSecond.abs();
  final profileStep = speed < .60
      ? 0
      : speed < 2.75
      ? 1
      : speed < 5.50
      ? 2
      : speed < 8.50
      ? 3
      : speed < 12.00
      ? 4
      : 5;
  return math.min(profileStep, maxItemsPerFling);
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

  if (effectiveVelocity.abs() < physics.minimumFlingVelocity ||
      maximumStep == 0) {
    return nearestIndex.toDouble();
  }

  final friction = FrictionSimulation(
    physics.frictionDrag,
    currentPixels,
    effectiveVelocity,
    tolerance: physics.snapTolerance,
  );
  final projectedRawIndex = (friction.finalX - minScrollExtent) / itemExtent;
  var delta = projectedRawIndex.round() - nearestIndex;
  final direction = effectiveVelocity.sign.toInt();

  if (delta == 0 && physics.forceOneItemOnFling) delta = direction;
  if (delta.sign != direction) delta = direction;
  delta = delta.clamp(-maximumStep, maximumStep);
  return (nearestIndex + delta).toDouble();
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
    final targetRawIndex = calculateTargetRawIndex(
      currentPixels: currentPixels,
      velocity: velocity,
      itemExtent: itemExtent,
      minScrollExtent: position.minScrollExtent,
      physics: this,
    );
    final targetIndex = targetRawIndex.round().clamp(0, itemCount - 1);
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

    return ScrollSpringSimulation(
      springForVelocity(
        velocityItemsPerSecond: velocityItemsPerSecond,
        baseSpring: snapSpring,
      ),
      currentPixels,
      targetPixels,
      distanceToTarget <= snapTolerance.distance ? 0 : snapVelocity,
      tolerance: snapTolerance,
    );
  }
}
