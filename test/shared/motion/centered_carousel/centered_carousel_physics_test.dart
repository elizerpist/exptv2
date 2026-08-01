import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_physics.dart';

CenterSnapScrollPhysics _physics({int itemCount = 20, int maxItems = 5}) {
  return CenterSnapScrollPhysics(
    itemExtent: 100,
    itemCount: itemCount,
    frictionDrag: .5,
    velocityMultiplier: 1,
    minimumFlingVelocity: 120,
    maximumFlingVelocity: 6000,
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

  test(
    'positive fling uses friction projection and moves at least one item',
    () {
      final simulation = _physics().createBallisticSimulation(
        _position(pixels: 200),
        120,
      );

      expect(_settledPosition(simulation!), closeTo(400, .01));
    },
  );

  test('negative fling chooses an item to the left', () {
    final simulation = _physics().createBallisticSimulation(
      _position(pixels: 300),
      -120,
    );

    expect(_settledPosition(simulation!), closeTo(100, .01));
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
