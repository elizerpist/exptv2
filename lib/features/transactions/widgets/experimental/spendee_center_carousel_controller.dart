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

class SpendeeCenterCarouselMotion {
  const SpendeeCenterCarouselMotion({
    required this.initialTravel,
    required this.preferredDxDirection,
    required this.directionalSnapAllowed,
    required this.inertial,
    required this.initialDuration,
  });

  final double initialTravel;
  final int preferredDxDirection;
  final bool directionalSnapAllowed;
  final bool inertial;
  final Duration initialDuration;
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

  /// Ports the shipping backheader belt release physics without reducing the
  /// fling to a precomputed number of discrete jumps.
  SpendeeCenterCarouselMotion releaseMotion({
    required double velocityDx,
    required bool liveTicked,
  }) {
    final speed = velocityDx.abs();
    final preferredDxDirection = _preferredDxDirection(
      velocityDx: velocityDx,
      residual: _residualDx,
    );
    final inertialTravel = speed < 700
        ? 0.0
        : (velocityDx * 0.055)
              .clamp(-slotDistance * 3, slotDistance * 3)
              .toDouble();
    final directionalSnapAllowed =
        inertialTravel != 0 ||
        liveTicked ||
        _totalDx.abs() >= slotDistance ||
        _residualDx.abs() >= slotDistance / 2;
    final releaseDirection = inertialTravel == 0
        ? preferredDxDirection
        : _dxDirection(inertialTravel);
    final initialTravel = inertialTravel == 0
        ? _snapTravel(
            _residualDx,
            preferredDxDirection: preferredDxDirection,
            allowDirectionalSnap: directionalSnapAllowed,
          )
        : inertialTravel;
    final duration = inertialTravel == 0
        ? const Duration(milliseconds: 120)
        : Duration(milliseconds: (180 + speed * 0.045).clamp(200, 340).round());
    return SpendeeCenterCarouselMotion(
      initialTravel: initialTravel,
      preferredDxDirection: releaseDirection,
      directionalSnapAllowed: directionalSnapAllowed,
      inertial: inertialTravel != 0,
      initialDuration: duration,
    );
  }

  double settleTravel({
    required int preferredDxDirection,
    required bool allowDirectionalSnap,
  }) {
    return _snapTravel(
      _residualDx,
      preferredDxDirection: preferredDxDirection,
      allowDirectionalSnap: allowDirectionalSnap,
    );
  }

  double _snapTravel(
    double residual, {
    int preferredDxDirection = 0,
    bool allowDirectionalSnap = false,
  }) {
    final residualDirection = _dxDirection(residual);
    if (allowDirectionalSnap &&
        preferredDxDirection != 0 &&
        residualDirection == preferredDxDirection &&
        residual.abs() >= 16) {
      return preferredDxDirection < 0
          ? -slotDistance - residual
          : slotDistance - residual;
    }
    if (residual.abs() >= switchThreshold) {
      return residual < 0 ? -slotDistance - residual : slotDistance - residual;
    }
    return -residual;
  }

  int _preferredDxDirection({
    required double velocityDx,
    required double residual,
  }) {
    final velocityDirection = _dxDirection(velocityDx);
    if (velocityDirection != 0 && velocityDx.abs() >= 50) {
      return velocityDirection;
    }
    final dragDirection = _dxDirection(_totalDx);
    if (dragDirection != 0) return dragDirection;
    return _dxDirection(residual);
  }

  int _dxDirection(double value) {
    if (value > 0.5) return 1;
    if (value < -0.5) return -1;
    return 0;
  }
}
