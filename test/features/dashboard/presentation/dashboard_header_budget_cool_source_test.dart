import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_budget_cool_source.dart';

void main() {
  group('Budget Header global Color Lab Cool source', () {
    test('owns the exact ten authored Cool stops in order', () {
      expect(BudgetHeaderCoolColorSource.stops, const <Color>[
        Color(0xffffffff),
        Color(0xffe6fbff),
        Color(0xffbdf5ff),
        Color(0xff75e6ff),
        Color(0xff22d3ee),
        Color(0xff06b6d4),
        Color(0xff0284c7),
        Color(0xff0057d9),
        Color(0xff0030a8),
        Color(0xff00135f),
      ]);
    });

    test('matches the Color Lab encoded RGB samples exactly', () {
      const expected = <(double, Color)>[
        (0, Color(0xffffffff)),
        (25, Color(0xffabf1ff)),
        (36, Color(0xff61e1fb)),
        (50, Color(0xff14c5e1)),
        (64, Color(0xff0390ca)),
        (75, Color(0xff0162d5)),
        (100, Color(0xff00135f)),
      ];
      for (final entry in expected) {
        expect(BudgetHeaderCoolColorSource.sample(entry.$1), entry.$2);
      }
      expect(
        BudgetHeaderCoolColorSource.sample(-20),
        BudgetHeaderCoolColorSource.sample(0),
      );
      expect(
        BudgetHeaderCoolColorSource.sample(120),
        BudgetHeaderCoolColorSource.sample(100),
      );
    });

    test('uses the Color Lab default three-probe window', () {
      final window = BudgetHeaderCoolWindowSampler.sample(
        const BudgetHeaderGlobalCoolState.defaults(),
      );
      expect(window.leftRawPercent, 36);
      expect(window.centerRawPercent, 50);
      expect(window.rightRawPercent, 64);
      expect(window.leftSamplePercent, 36);
      expect(window.centerSamplePercent, 50);
      expect(window.rightSamplePercent, 64);
      expect(window.colors, const <Color>[
        Color(0xff61e1fb),
        Color(0xff14c5e1),
        Color(0xff0390ca),
      ]);
      expect(window.stops, const <double>[0, .5, 1]);
    });

    test('does not clamp the global position when width is 100', () {
      BudgetHeaderCoolWindow sampleAt(double position) =>
          BudgetHeaderCoolWindowSampler.sample(
            BudgetHeaderGlobalCoolState(
              positionPercent: position,
              windowWidthPercent: 100,
            ),
          );

      final left = sampleAt(0);
      expect(left.leftRawPercent, -50);
      expect(left.centerRawPercent, 0);
      expect(left.rightRawPercent, 50);
      expect(left.leftSamplePercent, 0);
      expect(left.centerSamplePercent, 0);
      expect(left.rightSamplePercent, 50);
      expect(left.colors, const <Color>[
        Color(0xffffffff),
        Color(0xffffffff),
        Color(0xff14c5e1),
      ]);

      final middle = sampleAt(50);
      expect(middle.colors, const <Color>[
        Color(0xffffffff),
        Color(0xff14c5e1),
        Color(0xff00135f),
      ]);

      final right = sampleAt(100);
      expect(right.leftRawPercent, 50);
      expect(right.centerRawPercent, 100);
      expect(right.rightRawPercent, 150);
      expect(right.leftSamplePercent, 50);
      expect(right.centerSamplePercent, 100);
      expect(right.rightSamplePercent, 100);
      expect(right.colors, const <Color>[
        Color(0xff14c5e1),
        Color(0xff00135f),
        Color(0xff00135f),
      ]);
    });

    test('keeps position and width as orthogonal integer user controls', () {
      const state = BudgetHeaderGlobalCoolState(
        positionPercent: 80,
        windowWidthPercent: 28,
      );
      final widthChanged = state.copyWith(windowWidthPercent: 100);
      expect(widthChanged.positionPercent, 80);
      expect(widthChanged.windowWidthPercent, 100);

      final positionChanged = widthChanged.copyWith(positionPercent: 10);
      expect(positionChanged.positionPercent, 10);
      expect(positionChanged.windowWidthPercent, 100);
    });
  });
}
