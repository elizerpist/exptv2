import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/header_cascade_motion.dart';

const _geometry = HeaderCascadeGeometry(
  upperCollapsedTop: 223,
  upperExpandedTop: 374,
  upperHeight: 72,
  upperCollapsedInset: 17,
  upperExpandedInset: 17,
  upperCollapsedScale: .90,
  upperExpandedScale: 1,
  lowerExpandedTop: 457,
  lowerExpandedInset: 17,
  lowerHiddenOverlap: 32,
  lowerNestedInset: 18,
  lowerCollapsedScale: .96,
  lowerExpandedScale: 1,
);

void main() {
  test('interval progress clamps before and after its range', () {
    expect(HeaderCascadeMotion.intervalProgress(.10, .18, 1), 0);
    expect(
      HeaderCascadeMotion.intervalProgress(.40, .18, 1),
      closeTo(.2683, .0001),
    );
    expect(HeaderCascadeMotion.intervalProgress(1, .18, 1), 1);
  });

  test('lower card starts behind the moving upper card', () {
    final result = HeaderCascadeMotion.calculate(
      masterProgress: 0,
      geometry: _geometry,
    );

    expect(result.upper.progress, 0);
    expect(result.upper.top, 223);
    expect(result.upper.opacity, 0);
    expect(result.lower.progress, 0);
    expect(result.lower.top, 263);
    expect(result.lower.left, 35);
    expect(result.lower.right, 35);
    expect(result.lower.opacity, 0);
  });

  test(
    'lower card follows with continuous position, width, and opacity motion',
    () {
      final result = HeaderCascadeMotion.calculate(
        masterProgress: .40,
        geometry: _geometry,
      );

      expect(result.upper.progress, greaterThan(0));
      expect(result.lower.progress, greaterThan(0));
      expect(result.lower.top, greaterThan(324));
      expect(result.lower.top, lessThan(457));
      expect(result.lower.left, greaterThan(17));
      expect(result.lower.left, lessThan(35));
      expect(result.lower.right, result.lower.left);
      expect(result.lower.opacity, greaterThan(0));
      expect(result.lower.opacity, lessThan(1));
    },
  );

  test('both card motions finish only at the shared master endpoint', () {
    final beforeEndpoint = HeaderCascadeMotion.calculate(
      masterProgress: .80,
      geometry: _geometry,
    );
    final endpoint = HeaderCascadeMotion.calculate(
      masterProgress: 1,
      geometry: _geometry,
    );

    expect(beforeEndpoint.upper.progress, lessThan(1));
    expect(beforeEndpoint.lower.progress, lessThan(1));
    expect(endpoint.upper.progress, 1);
    expect(endpoint.lower.progress, 1);
  });

  test(
    'card motion does not pre-settle ahead of the shared master timeline',
    () {
      final result = HeaderCascadeMotion.calculate(
        masterProgress: .80,
        geometry: _geometry,
      );

      expect(result.upper.progress, closeTo(.80, .0001));
      expect(result.lower.progress, closeTo((.80 - .18) / .82, .0001));
      expect(result.upper.opacity, closeTo(.80, .0001));
      expect(result.lower.opacity, closeTo((.80 - .18) / .82, .0001));
    },
  );

  test('expanded endpoint restores both cards exactly', () {
    final result = HeaderCascadeMotion.calculate(
      masterProgress: 1,
      geometry: _geometry,
    );

    expect(result.upper.progress, 1);
    expect(result.upper.top, 374);
    expect(result.upper.left, 17);
    expect(result.upper.right, 17);
    expect(result.upper.opacity, 1);
    expect(result.upper.scale, 1);
    expect(result.lower.progress, 1);
    expect(result.lower.top, 457);
    expect(result.lower.left, 17);
    expect(result.lower.right, 17);
    expect(result.lower.opacity, 1);
    expect(result.lower.scale, 1);
  });

  test('the same calculation is continuous when reveal progress reverses', () {
    final forward = HeaderCascadeMotion.calculate(
      masterProgress: .65,
      geometry: _geometry,
    );
    final reverse = HeaderCascadeMotion.calculate(
      masterProgress: .65,
      geometry: _geometry,
    );

    expect(reverse.upper.top, forward.upper.top);
    expect(reverse.lower.top, forward.lower.top);
    expect(reverse.lower.left, forward.lower.left);
    expect(reverse.lower.opacity, forward.lower.opacity);
  });

  test(
    'lower motion progresses monotonically toward its expanded endpoint',
    () {
      var previousTop = 0.0;
      var previousInset = double.infinity;
      var previousOpacity = 0.0;

      for (var step = 0; step <= 10; step++) {
        final result = HeaderCascadeMotion.calculate(
          masterProgress: step / 10,
          geometry: _geometry,
        );

        expect(result.lower.top, greaterThanOrEqualTo(previousTop));
        expect(result.lower.left, lessThanOrEqualTo(previousInset));
        expect(result.lower.opacity, greaterThanOrEqualTo(previousOpacity));
        previousTop = result.lower.top;
        previousInset = result.lower.left;
        previousOpacity = result.lower.opacity;
      }
    },
  );
}
