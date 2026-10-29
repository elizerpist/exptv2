import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets(
    'Canvas center plate rim is light at the top and darkest at the bottom',
    (tester) async {
      const capture = ValueKey<String>('clay-donut-rim-capture');
      final scene = BudgetClayDonutScene.fromSlices(
        const <BudgetClayDonutSliceInput>[
          BudgetClayDonutSliceInput(
            label: 'Food',
            value: 100,
            color: Color(0xff224466),
          ),
        ],
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 424,
                height: 424,
                child: CustomPaint(
                  painter: BudgetClayDonutPainter(
                    scene: scene,
                    selectedSliceIndex: -1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      Future<Color> pixelAt(int x, int y) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final offset = (y * image.width + x) * 4;
          final bytes = data!.buffer.asUint8List();
          final color = Color.fromARGB(
            bytes[offset + 3],
            bytes[offset],
            bytes[offset + 1],
            bytes[offset + 2],
          );
          image.dispose();
          return color;
        }))!;
      }

      final top = await pixelAt(212, 106);
      final bottom = await pixelAt(212, 318);
      expect(top.computeLuminance(), greaterThan(bottom.computeLuminance()));
      expect(bottom.r, lessThan(top.r));
      expect(bottom.g, lessThan(top.g));
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
