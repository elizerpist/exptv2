import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

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
  if (effectiveVelocity.abs() < physics.minimumFlingVelocity ||
      maximumStep == 0) {
    _debugLogRelease(
      rawVelocity: velocity,
      effectiveVelocity: effectiveVelocity,
      itemExtent: itemExtent,
      velocityItemsPerSecond: velocityItemsPerSecond,
      band: velocityBandFor(velocityItemsPerSecond),
      maximumStep: maximumStep,
      projectedIndex: projectedIndex,
      targetIndex: nearestIndex,
      delta: 0,
    );
    return nearestIndex.toDouble();
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
  _debugLogRelease(
    rawVelocity: velocity,
    effectiveVelocity: effectiveVelocity,
    itemExtent: itemExtent,
    velocityItemsPerSecond: velocityItemsPerSecond,
    band: velocityBandFor(velocityItemsPerSecond),
    maximumStep: maximumStep,
    projectedIndex: projectedIndex,
    targetIndex: targetIndex,
    delta: delta,
  );
  return targetIndex.toDouble();
}

void _debugLogRelease({
  required double rawVelocity,
  required double effectiveVelocity,
  required double itemExtent,
  required double velocityItemsPerSecond,
  required String band,
  required int maximumStep,
  required int projectedIndex,
  required int targetIndex,
  required int delta,
}) {
  assert(() {
    debugPrint(
      'Carousel fling: '
      'raw=${rawVelocity.toStringAsFixed(1)}px/s, '
      'effective=${effectiveVelocity.toStringAsFixed(1)}px/s, '
      'itemExtent=${itemExtent.toStringAsFixed(2)}, '
      'speed=${velocityItemsPerSecond.toStringAsFixed(2)} items/s, '
      'band=$band, '
      'maxStep=$maximumStep, '
      'projected=$projectedIndex, '
      'target=$targetIndex, '
      'delta=$delta',
    );
    return true;
  }());
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
    assert(() {
      var elapsed = 0.0;
      while (!simulation.isDone(elapsed) && elapsed < 5.0) {
        elapsed += 0.016;
      }
      debugPrint(
        'Carousel snap: '
        'stiffness=${spring.stiffness.toStringAsFixed(1)}, '
        'settle=${(elapsed * 1000).round()}ms',
      );
      return true;
    }());
    return simulation;
  }
}
