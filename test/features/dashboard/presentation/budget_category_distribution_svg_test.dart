import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_svg.dart';

void main() {
  const slices = <BudgetCategoryDistributionSvgSlice>[
    BudgetCategoryDistributionSvgSlice(
      label: 'A',
      value: 60,
      color: Color(0xffff5268),
    ),
    BudgetCategoryDistributionSvgSlice(
      label: 'B',
      value: 30,
      color: Color(0xffff7043),
    ),
    BudgetCategoryDistributionSvgSlice(
      label: 'C',
      value: 10,
      color: Color(0xffffa12b),
    ),
  ];

  test(
    'ports the Spendee clay-donut source geometry and proportional arcs',
    () {
      final svg = BudgetCategoryDistributionSvg.clayDonut(
        slices: slices,
        selectedIndex: null,
      );

      expect(BudgetCategoryDistributionSvg.viewBox, '44 44 424 424');
      expect(BudgetCategoryDistributionSvg.centerPlateRadius, 106);
      expect(BudgetCategoryDistributionSvg.innerRadius, 92);
      expect(BudgetCategoryDistributionSvg.normalOuterRadius, 164);
      expect(BudgetCategoryDistributionSvg.gapDegreesForSliceCount(7), 1.7);
      expect(BudgetCategoryDistributionSvg.gapDegreesForSliceCount(8), .9);
      expect(BudgetCategoryDistributionSvg.gapDegreesForSliceCount(12), .9);
      expect(BudgetCategoryDistributionSvg.gapDegreesForSliceCount(13), .5);
      expect(svg, contains('viewBox="44 44 424 424"'));
      expect(svg, contains('r="106"'));
      expect(svg, contains('data-fluvi-donut-segment-sides="true"'));
      expect(
        svg,
        contains('stroke="#ffffff" stroke-opacity=".58" stroke-width="3"'),
      );
      expect(RegExp('data-fluvi-donut-slice=').allMatches(svg), hasLength(3));

      expect(BudgetCategoryDistributionSvg.sweepDegrees(60, 100), 216);
      expect(BudgetCategoryDistributionSvg.sweepDegrees(30, 100), 108);
      expect(BudgetCategoryDistributionSvg.sweepDegrees(10, 100), 36);
      final top = BudgetCategoryDistributionSvg.point(256, 256, 164, 0);
      expect(top.$1, closeTo(256, .000001));
      expect(top.$2, closeTo(92, .000001));
    },
  );

  test(
    'selected variant lifts only the selected source sector and changes center text',
    () {
      final svg = BudgetCategoryDistributionSvg.clayDonut(
        slices: slices,
        selectedIndex: 1,
      );

      expect(svg, contains('data-fluvi-donut-selected="true"'));
      expect(
        RegExp('data-fluvi-donut-selected="true"').allMatches(svg),
        hasLength(2),
      );
      expect(svg, contains('data-fluvi-donut-slice="1"'));
      expect(
        svg,
        contains('A 160.38 160.38'),
        reason: 'selected sector radius',
      );
      expect(svg, contains('>30%</text>'));
      expect(svg, contains('>B</text>'));
      expect(
        BudgetCategoryDistributionSvg.selectedOffsetFor(
          start: 216.85,
          end: 323.15,
        ).$1.abs(),
        greaterThan(0),
      );
    },
  );

  test('unselected and empty centers retain the reference center labels', () {
    expect(
      BudgetCategoryDistributionSvg.clayDonut(
        slices: slices,
        selectedIndex: null,
      ),
      allOf(contains('>100%</text>'), contains('>összesen</text>')),
    );
    expect(
      BudgetCategoryDistributionSvg.clayDonut(
        slices: const <BudgetCategoryDistributionSvgSlice>[],
        selectedIndex: null,
      ),
      allOf(contains('>0%</text>'), contains('>nincs adat</text>')),
    );
  });

  test('mathematical hit test shares the ordered source sector domain', () {
    const size = Size(150, 150);
    expect(
      BudgetCategoryDistributionDonutHitTest.resolve(
        localPosition: const Offset(75, 75),
        size: size,
        values: const <int>[60, 30, 10],
      ),
      const BudgetCategoryDistributionDonutTap.center(),
    );
    expect(
      BudgetCategoryDistributionDonutHitTest.resolve(
        localPosition: const Offset(75, 20),
        size: size,
        values: const <int>[60, 30, 10],
      ),
      const BudgetCategoryDistributionDonutTap.slice(0),
    );
    expect(
      BudgetCategoryDistributionDonutHitTest.resolve(
        localPosition: const Offset(75, 75 - 75),
        size: size,
        values: const <int>[60, 30, 10],
      ).target,
      BudgetCategoryDistributionDonutTapTarget.outside,
    );
    final atB = Offset(
      75 + 55 * math.sin(250 * math.pi / 180),
      75 - 55 * math.cos(250 * math.pi / 180),
    );
    expect(
      BudgetCategoryDistributionDonutHitTest.resolve(
        localPosition: atB,
        size: size,
        values: const <int>[60, 30, 10],
      ),
      const BudgetCategoryDistributionDonutTap.slice(1),
    );
  });
}
