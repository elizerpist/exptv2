import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

void main() {
  const accent = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF2BC4F3),
    Color(0xFF39B8F4),
  ];

  test('expense overshoot keeps warning and danger zones distinct', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: 1.15,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(presentation.rawRatio, 1.15);
    expect(presentation.visualProgress, closeTo(1.15 / 1.20, .0001));
    expect(presentation.health, BudgetClayGaugeHealth.expenseDanger);
    expect(presentation.overshootZones, hasLength(2));
    expect(
      presentation.overshootZones.last.colors.last,
      const Color(0xFFDC2626),
    );
  });

  test('income over target is a positive zone, never expense danger', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: 1.16,
      direction: LedgerDirection.income,
      activeGradient: accent,
    );

    expect(presentation.health, BudgetClayGaugeHealth.incomeExceededTarget);
    expect(presentation.overshootZones, hasLength(1));
    expect(
      presentation.overshootZones.single.colors,
      isNot(contains(const Color(0xFFDC2626))),
    );
    expect(presentation.hasVisualOverflow, isFalse);
  });

  test('visual progress clamps at 120 percent without losing raw value', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: 1.53,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(presentation.rawRatio, 1.53);
    expect(presentation.visualProgress, 1);
    expect(presentation.hasVisualOverflow, isTrue);
  });

  test('uses the selected-avatar sphere material for the endpoint marker', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: .75,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(
      presentation.markerMaterial.sourceGeometryId,
      BudgetProgressRingSphereMaterial.sourceId,
    );
    expect(
      presentation.markerMaterial.body,
      isNot(accent.first),
      reason: 'the shared sphere material receives the resolved progress hue',
    );
  });

  test('expense colours use one blended material ramp across thresholds', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: 1.15,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(presentation.progressStops, hasLength(7));
    expect(
      presentation.progressStops,
      orderedEquals(presentation.progressStops.toList()..sort()),
    );
    expect(presentation.progressGradient[2], accent.last);
    expect(
      presentation.progressGradient[3],
      isNot(presentation.progressGradient[2]),
      reason: 'the shader blends these adjacent stops around the 100% boundary',
    );
    expect(
      presentation.progressGradient[5],
      isNot(presentation.progressGradient[4]),
      reason: 'the warning-to-danger boundary is also a blend, not a new arc',
    );
  });

  test(
    'SUM and MONTH layouts preserve the one shared material cross-section',
    () {
      final sum = BudgetSemicircleMaterialGeometry.resolve(
        const Size(390, 150),
        layout: BudgetSemicircleMaterialLayout.sumHero,
      );
      final month = BudgetSemicircleMaterialGeometry.resolve(
        const Size(195, 110),
        layout: BudgetSemicircleMaterialLayout.monthMetric,
      );

      expect(
        sum.stroke / sum.trackRadius,
        closeTo(month.stroke / month.trackRadius, .000001),
      );
      expect(
        sum.activeStripWidth / sum.stroke,
        closeTo(month.activeStripWidth / month.stroke, .000001),
      );
      expect(
        sum.decorativeStripWidth / sum.stroke,
        closeTo(month.decorativeStripWidth / month.stroke, .000001),
      );
      expect(sum.trackRadius, greaterThan(month.trackRadius));
    },
  );

  test(
    'fixed accent material keeps elapsed time outside financial health logic',
    () {
      final presentation = BudgetSemicircleMaterialPresentation.fixedAccent(
        rawRatio: .61,
        activeGradient: accent,
      );

      expect(presentation.progressGradient, orderedEquals(accent));
      expect(presentation.progressStops, const <double>[0, .5, 1]);
      expect(presentation.overshootZones, isEmpty);
    },
  );
}
