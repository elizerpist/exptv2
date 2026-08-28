import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/financial_limits/presentation/budget_ring_presentation.dart';

void main() {
  test('SUM presentation defaults to current ring and fixed healthy green', () {
    final controller = BudgetRingPresentationController();
    addTearDown(controller.dispose);

    expect(controller.value.sumRingStyle, BudgetSumRingStyle.current);
    expect(
      controller.value.healthyColorMode,
      BudgetHealthyColorMode.fixedGreen,
    );
  });

  test('healthy resolver changes only its resolved healthy source', () {
    const accent = Color(0xff8055d4);
    const fixed = Color(0xff3bb36f);

    expect(
      BudgetHealthyVisualColorResolver.resolve(
        mode: BudgetHealthyColorMode.fixedGreen,
        targetAccent: accent,
        fixedGreen: fixed,
      ),
      fixed,
    );
    expect(
      BudgetHealthyVisualColorResolver.resolve(
        mode: BudgetHealthyColorMode.targetAccent,
        targetAccent: accent,
        fixedGreen: fixed,
      ),
      accent,
    );
  });

  test(
    'SUM style catalogue is closed and coloured boundaries are white track points',
    () {
      expect(BudgetSumRingStyle.values, <BudgetSumRingStyle>[
        BudgetSumRingStyle.current,
        BudgetSumRingStyle.coloredScaleWhiteArc,
        BudgetSumRingStyle.coloredScaleMovingSphere,
      ]);

      final geometry = BudgetProgressRingGeometry.source;
      final boundaries = BudgetProgressRingSumColoredScaleMarkers.resolve(
        geometry: geometry,
      );
      expect(boundaries.map((marker) => marker.ratio), <double>[.75, .90]);
      for (final marker in boundaries) {
        expect(
          (marker.center - geometry.center).distance,
          closeTo(geometry.trackRadius, .000001),
        );
        expect(marker.material, BudgetProgressRingSphereMaterial.white);
        expect(marker.material.usesCategoryHueShift, isFalse);
      }
    },
  );

  test(
    'healthy target accent does not leak into warning or danger scale anchors',
    () {
      const accent = Color(0xff8055d4);
      final markers = BudgetProgressRingSumScaleMarkers.resolve(
        geometry: BudgetProgressRingGeometry.source,
        healthyColor: accent,
      );

      expect(markers[0].material.base, accent);
      expect(markers[1].material.base, FluviVisualTokens.budgetProgressWarning);
      expect(markers[2].material.base, FluviVisualTokens.budgetProgressDanger);
    },
  );
}
