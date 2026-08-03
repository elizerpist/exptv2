import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_physics.dart';

CenterSnapScrollPhysics _physics({int itemCount = 20, int maxItems = 5}) {
  return CenterSnapScrollPhysics(
    itemExtent: 100,
    itemCount: itemCount,
    frictionDrag: .135,
    velocityMultiplier: .66,
    minimumFlingVelocity: 140,
    maximumFlingVelocity: 5200,
    maxItemsPerFling: maxItems,
    forceOneItemOnFling: true,
    snapSpring: SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 420,
      ratio: 1,
    ),
    snapTolerance: const Tolerance(distance: .01, velocity: .01),
    parent: const ClampingScrollPhysics(),
  );
}

ScrollMetrics _position({double pixels = 200, int itemCount = 20}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: (itemCount - 1) * 100,
    pixels: pixels,
    viewportDimension: 360,
    axisDirection: AxisDirection.right,
    devicePixelRatio: 1,
  );
}

double _settledPosition(Simulation simulation) {
  var time = 0.0;
  for (var i = 0; i < 1000 && !simulation.isDone(time); i++) {
    time += .016;
  }
  return simulation.x(time);
}

void main() {
  test('velocity profile caps steps in items per second', () {
    expect(maximumStepForVelocity(.79), 0);
    expect(maximumStepForVelocity(.80), 1);
    expect(maximumStepForVelocity(4.99), 1);
    expect(maximumStepForVelocity(5.0), 2);
    expect(maximumStepForVelocity(9.99), 2);
    expect(maximumStepForVelocity(10.0), 3);
    expect(maximumStepForVelocity(15.99), 3);
    expect(maximumStepForVelocity(16.0), 4);
    expect(maximumStepForVelocity(23.99), 4);
    expect(maximumStepForVelocity(24.0), 5);
    expect(maximumStepForVelocity(-.80), 1);
    expect(maximumStepForVelocity(-16.0), 4);
    expect(maximumStepForVelocity(30.0, maxItemsPerFling: 2), 2);
  });

  test('snap velocity is attenuated and independently clamped', () {
    expect(
      snapVelocityFor(effectiveVelocity: 1000, itemExtent: 100),
      closeTo(180, .0001),
    );
    expect(
      snapVelocityFor(effectiveVelocity: 10000, itemExtent: 100),
      closeTo(450, .0001),
    );
  });

  test('spring stiffness increases with item velocity', () {
    final slow = springForVelocity(
      velocityItemsPerSecond: 1,
      baseSpring: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 420,
        ratio: 1,
      ),
    );
    final fast = springForVelocity(
      velocityItemsPerSecond: 12,
      baseSpring: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 420,
        ratio: 1,
      ),
    );

    expect(slow.stiffness, closeTo(182.174, .001));
    expect(fast.stiffness, closeTo(340, .001));
    expect(fast.stiffness, greaterThan(slow.stiffness));
  });

  test('friction projection remains within the velocity step cap', () {
    final target = calculateTargetRawIndex(
      currentPixels: 500,
      velocity: 6000,
      itemExtent: 100,
      minScrollExtent: 0,
      physics: _physics(itemCount: 100),
    );

    expect(target, greaterThanOrEqualTo(6));
    expect(target, lessThanOrEqualTo(10));
  });

  test('identical fling inputs create an identical immutable target plan', () {
    final plans = List.generate(
      100,
      (_) => createFlingPlan(
        currentPixels: 500,
        velocity: 6000,
        itemExtent: 100,
        minScrollExtent: 0,
        physics: _physics(itemCount: 100),
      ),
    );
    final first = plans.first;

    for (final plan in plans.skip(1)) {
      expect(plan.targetRawIndex, first.targetRawIndex);
      expect(plan.velocityBand, first.velocityBand);
      expect(plan.itemDelta, first.itemDelta);
    }

    expect(first.startPositionPx, 500);
    expect(first.inputVelocityPxPerSecond, 6000);
    expect(first.clampedVelocityPxPerSecond, 5200);
    expect(first.effectiveVelocityPxPerSecond, 3432);
    expect(first.velocityBand, 'max-5');
    expect(first.itemDelta, 5);
    expect(first.targetRawIndex, 10);
    expect(first.targetPhysicalIndex, 10);
    expect(first.targetLogicalIndex, 10);
    expect(first.gestureEpoch, 0);
    expect(
      calculateTargetRawIndex(
        currentPixels: 500,
        velocity: 6000,
        itemExtent: 100,
        minScrollExtent: 0,
        physics: _physics(itemCount: 100),
      ),
      first.targetRawIndex.toDouble(),
    );
  });

  test('100-run target matrix is invariant to presentation content state', () {
    const presentationContexts = <String>[
      'empty-logbox',
      'one-row-logbox',
      'nine-row-logbox',
      'cold-preview-cache',
      'warm-preview-cache',
      'logger-disabled',
      'logger-closed',
      'logger-open',
    ];
    const inputs = <({double pixels, double velocity})>[
      (pixels: 0, velocity: 0),
      (pixels: 200, velocity: 400),
      (pixels: 500, velocity: 6000),
      (pixels: 900, velocity: -850),
    ];

    for (final input in inputs) {
      final baseline = createFlingPlan(
        currentPixels: input.pixels,
        velocity: input.velocity,
        itemExtent: 100,
        minScrollExtent: 0,
        physics: _physics(itemCount: 100),
      );
      for (final context in presentationContexts) {
        for (var run = 0; run < 100; run += 1) {
          final plan = createFlingPlan(
            currentPixels: input.pixels,
            velocity: input.velocity,
            itemExtent: 100,
            minScrollExtent: 0,
            physics: _physics(itemCount: 100),
          );
          expect(plan.velocityBand, baseline.velocityBand, reason: context);
          expect(plan.itemDelta, baseline.itemDelta, reason: context);
          expect(
            plan.targetPhysicalIndex,
            baseline.targetPhysicalIndex,
            reason: context,
          );
          expect(
            plan.targetLogicalIndex,
            baseline.targetLogicalIndex,
            reason: context,
          );
        }
      }
    }
  });

  test('zero velocity snaps to the nearest fixed item', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 249),
      0,
    );

    expect(simulation, isA<ScrollSpringSimulation>());
    expect(_settledPosition(simulation!), closeTo(200, .01));
  });

  test('small velocity still settles to the nearest item', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 249),
      40,
    );

    expect(_settledPosition(simulation!), closeTo(200, .01));
  });

  test('slow fling does not project beyond one item', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 200),
      180,
    );

    expect(_settledPosition(simulation!), closeTo(200, .01));
  });

  test(
    'positive fling uses friction projection and moves at least one item',
    () {
      final simulation = _physics().createBallisticSimulation(
        _position(pixels: 200),
        400,
      );

      expect(_settledPosition(simulation!), closeTo(300, .01));
    },
  );

  test('negative fling chooses an item to the left', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 300),
      -400,
    );

    expect(_settledPosition(simulation!), closeTo(200, .01));
  });

  test('large fling is bounded by maxItemsPerFling', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 500),
      6000,
    );

    expect(_settledPosition(simulation!), closeTo(1000, .01));
  });

  test('first and last item bounds are respected', () {
    final atFirst = _physics().createBallisticSimulation(
      _position(pixels: 0),
      -6000,
    );
    final atLast = _physics().createBallisticSimulation(
      _position(pixels: 1900),
      6000,
    );

    expect(_settledPosition(atFirst!), 0);
    expect(_settledPosition(atLast!), 1900);
  });
}
