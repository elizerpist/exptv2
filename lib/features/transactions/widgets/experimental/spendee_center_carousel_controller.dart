import 'dart:math' as math;

class SpendeeCenterCarouselUpdate {
  const SpendeeCenterCarouselUpdate({
    required this.index,
    required this.residualDx,
    required this.tickedIndexes,
  });

  final int index;
  final double residualDx;
  final List<int> tickedIndexes;
}

class SpendeeCenterCarouselReleasePlan {
  const SpendeeCenterCarouselReleasePlan({
    required this.steps,
    required this.distanceSteps,
    required this.velocitySteps,
    required this.swipedLeft,
    required this.distance,
    required this.velocity,
  });

  final int steps;
  final int distanceSteps;
  final int velocitySteps;
  final bool swipedLeft;
  final double distance;
  final double velocity;
}

class SpendeeCenterCarouselController {
  SpendeeCenterCarouselController({
    required this.itemCount,
    this.initialIndex = 0,
    this.slotDistance = 64,
    this.switchThreshold = 44,
  }) : _index = initialIndex.clamp(0, math.max(0, itemCount - 1)).toInt();

  final int itemCount;
  final int initialIndex;
  final double slotDistance;
  final double switchThreshold;

  int _index;
  double _residualDx = 0;
  double _totalDx = 0;

  int get index => _index;
  double get residualDx => _residualDx;
  double get totalDx => _totalDx;

  void reset({int? index}) {
    _index = (index ?? _index).clamp(0, math.max(0, itemCount - 1)).toInt();
    _residualDx = 0;
    _totalDx = 0;
  }

  SpendeeCenterCarouselUpdate applyDragDelta(double deltaDx) {
    if (itemCount < 2 || deltaDx == 0) {
      return SpendeeCenterCarouselUpdate(
        index: _index,
        residualDx: _residualDx,
        tickedIndexes: const <int>[],
      );
    }
    _totalDx += deltaDx;
    var nextDx = _residualDx + deltaDx;
    var nextIndex = _index;
    final ticked = <int>[];
    while (nextDx <= -slotDistance) {
      nextDx += slotDistance;
      nextIndex = (nextIndex + 1) % itemCount;
      ticked.add(nextIndex);
    }
    while (nextDx >= slotDistance) {
      nextDx -= slotDistance;
      nextIndex = nextIndex == 0 ? itemCount - 1 : nextIndex - 1;
      ticked.add(nextIndex);
    }
    _index = nextIndex;
    _residualDx = nextDx;
    return SpendeeCenterCarouselUpdate(
      index: _index,
      residualDx: _residualDx,
      tickedIndexes: List<int>.unmodifiable(ticked),
    );
  }

  SpendeeCenterCarouselReleasePlan releasePlan({required double velocityDx}) {
    final distance = math.max(_totalDx.abs(), _residualDx.abs());
    final velocity = velocityDx.abs();
    if (itemCount < 2) {
      return SpendeeCenterCarouselReleasePlan(
        steps: 0,
        distanceSteps: 0,
        velocitySteps: 0,
        swipedLeft: false,
        distance: distance,
        velocity: velocity,
      );
    }
    final maxSteps = math.max(1, itemCount - 1);
    final distanceSteps = distance < switchThreshold
        ? 0
        : math.max(1, (distance / slotDistance).round());
    final velocitySteps = velocity < 1200 ? 0 : (velocity / 1200).floor();
    final rawDirection = velocityDx.abs() >= 50
        ? velocityDx
        : (_totalDx == 0 ? _residualDx : _totalDx);
    return SpendeeCenterCarouselReleasePlan(
      steps: (distanceSteps + velocitySteps).clamp(0, maxSteps).toInt(),
      distanceSteps: distanceSteps.clamp(0, maxSteps).toInt(),
      velocitySteps: velocitySteps.clamp(0, maxSteps).toInt(),
      swipedLeft: rawDirection < 0,
      distance: distance,
      velocity: velocity,
    );
  }
}
