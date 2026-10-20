import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/financial_limits/presentation/budget_ring_presentation.dart';
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
    'solid health paints one 3D material family without changing geometry',
    () {
      final presentation = BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: 1.15,
        direction: LedgerDirection.expense,
        activeGradient: accent,
      );
      final segmented = presentation.materialFor(
        presentation: BudgetProgressColorPresentation.segmentedScale,
        healthyColorMode: BudgetHealthyColorMode.targetAccent,
      );
      final solid = presentation.materialFor(
        presentation: BudgetProgressColorPresentation.solidHealth,
        healthyColorMode: BudgetHealthyColorMode.targetAccent,
      );

      expect(presentation.visualProgress, closeTo(1.15 / 1.20, .0001));
      expect(segmented.stops, hasLength(7));
      expect(solid.stops, const <double>[0, .5, 1]);
      expect(solid.colors[1], FluviVisualTokens.budgetProgressDanger);
      expect(solid.colors.first, isNot(solid.colors.last));
    },
  );

  test('solid healthy color reuses the selected healthy-colour authority', () {
    final presentation = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: .74,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    final green = presentation.materialFor(
      presentation: BudgetProgressColorPresentation.solidHealth,
      healthyColorMode: BudgetHealthyColorMode.fixedGreen,
    );
    final accentMaterial = presentation.materialFor(
      presentation: BudgetProgressColorPresentation.solidHealth,
      healthyColorMode: BudgetHealthyColorMode.targetAccent,
    );

    expect(green.colors[1], FluviVisualTokens.budgetProgressHealthy);
    expect(accentMaterial.colors[1], accent[1]);
  });

  test(
    'income over target never receives the expense danger solid material',
    () {
      final presentation = BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: 1.16,
        direction: LedgerDirection.income,
        activeGradient: accent,
      );
      final solid = presentation.materialFor(
        presentation: BudgetProgressColorPresentation.solidHealth,
        healthyColorMode: BudgetHealthyColorMode.fixedGreen,
      );

      expect(presentation.health, BudgetClayGaugeHealth.incomeExceededTarget);
      expect(solid.colors[1], const Color(0xFF22C55E));
      expect(solid.colors[1], isNot(FluviVisualTokens.budgetProgressDanger));
    },
  );
}
