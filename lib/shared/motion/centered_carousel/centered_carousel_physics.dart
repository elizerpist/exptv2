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

/// Mutable geometry/configuration read by one stable physics identity.
///
/// Flutter may create an applied physics wrapper for a ScrollPosition, but the
/// feature-owned physics object and this configuration remain stable while
/// data length and viewport geometry change.
class CenterSnapPhysicsConfiguration {
  CenterSnapPhysicsConfiguration({
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
    this.onBallisticStarted,
  });

  double itemExtent;
  int itemCount;
  double frictionDrag;
  double velocityMultiplier;
  double minimumFlingVelocity;
  double maximumFlingVelocity;
  int maxItemsPerFling;
  bool forceOneItemOnFling;
  SpringDescription snapSpring;
  Tolerance snapTolerance;
  final ValueChanged<double>? onBallisticStarted;

  void update({
    required double itemExtent,
    required int itemCount,
    required double frictionDrag,
    required double velocityMultiplier,
    required double minimumFlingVelocity,
    required double maximumFlingVelocity,
    required int maxItemsPerFling,
    required bool forceOneItemOnFling,
    required SpringDescription snapSpring,
    required Tolerance snapTolerance,
  }) {
    this.itemExtent = itemExtent;
    this.itemCount = itemCount;
    this.frictionDrag = frictionDrag;
    this.velocityMultiplier = velocityMultiplier;
    this.minimumFlingVelocity = minimumFlingVelocity;
    this.maximumFlingVelocity = maximumFlingVelocity;
    this.maxItemsPerFling = maxItemsPerFling;
    this.forceOneItemOnFling = forceOneItemOnFling;
    this.snapSpring = snapSpring;
    this.snapTolerance = snapTolerance;
  }
}

class CenterSnapScrollPhysics extends ScrollPhysics {
  const CenterSnapScrollPhysics({
    required double itemExtent,
    required int itemCount,
    required double frictionDrag,
    required double velocityMultiplier,
    required double minimumFlingVelocity,
    required double maximumFlingVelocity,
    required int maxItemsPerFling,
    required bool forceOneItemOnFling,
    required SpringDescription snapSpring,
    required Tolerance snapTolerance,
    super.parent,
  }) : _configuration = null,
       _itemExtent = itemExtent,
       _itemCount = itemCount,
       _frictionDrag = frictionDrag,
       _velocityMultiplier = velocityMultiplier,
       _minimumFlingVelocity = minimumFlingVelocity,
       _maximumFlingVelocity = maximumFlingVelocity,
       _maxItemsPerFling = maxItemsPerFling,
       _forceOneItemOnFling = forceOneItemOnFling,
       _snapSpring = snapSpring,
       _snapTolerance = snapTolerance;

  const CenterSnapScrollPhysics.configured({
    required CenterSnapPhysicsConfiguration configuration,
    super.parent,
  }) : _configuration = configuration,
       _itemExtent = null,
       _itemCount = null,
       _frictionDrag = null,
       _velocityMultiplier = null,
       _minimumFlingVelocity = null,
       _maximumFlingVelocity = null,
       _maxItemsPerFling = null,
       _forceOneItemOnFling = null,
       _snapSpring = null,
       _snapTolerance = null;

  final CenterSnapPhysicsConfiguration? _configuration;
  final double? _itemExtent;
  final int? _itemCount;
  final double? _frictionDrag;
  final double? _velocityMultiplier;
  final double? _minimumFlingVelocity;
  final double? _maximumFlingVelocity;
  final int? _maxItemsPerFling;
  final bool? _forceOneItemOnFling;
  final SpringDescription? _snapSpring;
  final Tolerance? _snapTolerance;

  double get itemExtent => _configuration?.itemExtent ?? _itemExtent!;
  int get itemCount => _configuration?.itemCount ?? _itemCount!;
  double get frictionDrag => _configuration?.frictionDrag ?? _frictionDrag!;
  double get velocityMultiplier =>
      _configuration?.velocityMultiplier ?? _velocityMultiplier!;
  double get minimumFlingVelocity =>
      _configuration?.minimumFlingVelocity ?? _minimumFlingVelocity!;
  double get maximumFlingVelocity =>
      _configuration?.maximumFlingVelocity ?? _maximumFlingVelocity!;
  int get maxItemsPerFling =>
      _configuration?.maxItemsPerFling ?? _maxItemsPerFling!;
  bool get forceOneItemOnFling =>
      _configuration?.forceOneItemOnFling ?? _forceOneItemOnFling!;
  SpringDescription get snapSpring =>
      _configuration?.snapSpring ?? _snapSpring!;
  Tolerance get snapTolerance =>
      _configuration?.snapTolerance ?? _snapTolerance!;

  @override
  CenterSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    final configuration = _configuration;
    if (configuration != null) {
      return CenterSnapScrollPhysics.configured(
        configuration: configuration,
        parent: buildParent(ancestor),
      );
    }
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
    if (velocity.abs() > snapTolerance.velocity) {
      _configuration?.onBallisticStarted?.call(velocity);
    }

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
