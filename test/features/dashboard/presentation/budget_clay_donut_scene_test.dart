import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_donut_scene.dart';

void main() {
  test(
    'one clay scene retains geometry while selection is only a paint parameter',
    () {
      final scene =
          BudgetClayDonutScene.fromSlices(const <BudgetClayDonutSliceInput>[
            BudgetClayDonutSliceInput(
              stableId: 'food',
              label: 'Food',
              value: 60,
              color: Color(0xff224466),
            ),
            BudgetClayDonutSliceInput(
              stableId: 'health',
              label: 'Health',
              value: 30,
              color: Color(0xff446688),
            ),
            BudgetClayDonutSliceInput(
              stableId: 'home',
              label: 'Home',
              value: 10,
              color: Color(0xff6688aa),
            ),
          ]);

      expect(scene.slices, hasLength(3));
      expect(
        scene.slices.map((slice) => slice.sweepDegrees),
        closeToList(<double>[216, 108, 36], 0.0001),
      );
      expect(scene.selectedSliceIndexForStableId('health'), 1);
      expect(scene.geometryBuildCount, 1);
    },
  );

  test('paint and hit testing share the retained slice geometry', () {
    final scene =
        BudgetClayDonutScene.fromSlices(const <BudgetClayDonutSliceInput>[
          BudgetClayDonutSliceInput(
            stableId: 'food',
            label: 'Food',
            value: 60,
            color: Color(0xff224466),
          ),
          BudgetClayDonutSliceInput(
            stableId: 'health',
            label: 'Health',
            value: 30,
            color: Color(0xff446688),
          ),
          BudgetClayDonutSliceInput(
            stableId: 'home',
            label: 'Home',
            value: 10,
            color: Color(0xff6688aa),
          ),
        ]);

    final food = scene.slices[0];
    final foodMidpoint =
        BudgetClayDonutGeometry.point(
          BudgetClayDonutGeometry.sourceCenter,
          BudgetClayDonutGeometry.sourceCenter,
          128,
          (food.startDegrees + food.endDegrees) / 2,
        ) -
        const Offset(
          BudgetClayDonutGeometry.sourceMin,
          BudgetClayDonutGeometry.sourceMin,
        );
    expect(
      scene
          .hitTest(
            localPosition: const Offset(212, 212),
            size: const Size(424, 424),
          )
          .target,
      BudgetClayDonutTapTarget.center,
    );
    expect(
      scene
          .hitTest(localPosition: foodMidpoint, size: const Size(424, 424))
          .index,
      0,
    );
    expect(
      scene
          .hitTest(
            localPosition: const Offset(423, 423),
            size: const Size(424, 424),
          )
          .target,
      BudgetClayDonutTapTarget.outside,
    );
    expect(food.selectedOffset.distance, closeTo(10, .0001));
    expect(
      food.normalTopPath.getBounds(),
      isNot(equals(food.selectedTopPath.getBounds())),
    );
  });

  test(
    'an absent selection stays unlifted without pretending to be aggregate',
    () {
      final scene = BudgetClayDonutScene.fromSlices(
        const <BudgetClayDonutSliceInput>[
          BudgetClayDonutSliceInput(
            label: 'Food',
            value: 100,
            color: Color(0xff224466),
          ),
        ],
      );

      final center = BudgetClayDonutCenter.forScene(
        scene,
        selectedSliceIndex: -1,
        absentSelectionLabel: 'Rezsi',
      );
      expect(center.valueLabel, '0%');
      expect(center.label, 'Rezsi');
    },
  );
}

Matcher closeToList(List<double> values, double tolerance) =>
    predicate<Iterable<double>>(
      (actual) =>
          actual.length == values.length &&
          actual.indexed.every(
            (item) => (item.$2 - values[item.$1]).abs() <= tolerance,
          ),
      'a list close to $values',
    );
