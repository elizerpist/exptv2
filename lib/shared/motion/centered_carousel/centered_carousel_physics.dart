import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

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

  int _indexForPixels(double pixels, ScrollMetrics position) {
    final relativePixels = pixels - position.minScrollExtent;
    final rawIndex = (relativePixels / itemExtent).round();
    return rawIndex.clamp(0, math.max(0, itemCount - 1));
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
    if (itemCount <= 0 || itemExtent <= 0) {
      return null;
    }

    final currentPixels = position.pixels;
    final currentIndex = _indexForPixels(currentPixels, position);
    final clampedVelocity = velocity
        .clamp(-maximumFlingVelocity, maximumFlingVelocity)
        .toDouble();
    final effectiveVelocity = clampedVelocity * velocityMultiplier;
    final isRealFling = effectiveVelocity.abs() >= minimumFlingVelocity;

    var projectedPixels = currentPixels;
    if (isRealFling) {
      projectedPixels = FrictionSimulation(
        frictionDrag,
        currentPixels,
        effectiveVelocity,
        tolerance: snapTolerance,
      ).finalX;
    }

    var targetIndex = _indexForPixels(projectedPixels, position);
    if (forceOneItemOnFling && isRealFling && targetIndex == currentIndex) {
      targetIndex += effectiveVelocity > 0 ? 1 : -1;
    }

    final minAllowedIndex = math.max(0, currentIndex - maxItemsPerFling);
    final maxAllowedIndex = math.min(
      itemCount - 1,
      currentIndex + maxItemsPerFling,
    );
    targetIndex = targetIndex.clamp(minAllowedIndex, maxAllowedIndex);
    targetIndex = targetIndex.clamp(0, itemCount - 1);

    final targetPixels = _pixelsForIndex(
      targetIndex,
      position,
    ).clamp(position.minScrollExtent, position.maxScrollExtent).toDouble();
    final distanceToTarget = (targetPixels - currentPixels).abs();

    if (distanceToTarget <= snapTolerance.distance &&
        effectiveVelocity.abs() <= snapTolerance.velocity) {
      return null;
    }

    return ScrollSpringSimulation(
      snapSpring,
      currentPixels,
      targetPixels,
      effectiveVelocity,
      tolerance: snapTolerance,
    );
  }
}
