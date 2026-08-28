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

  test('SUM polar scale starts at twelve and advances clockwise', () {
    final geometry = BudgetProgressRingGeometry.source;
    final top = geometry.pointForRatio(0);
    final right = geometry.pointForRatio(.25);
    final bottom = geometry.pointForRatio(.50);
    final left = geometry.pointForRatio(.75);
    final seam = geometry.pointForRatio(1);

    expect(top.dx, closeTo(geometry.center.dx, .000001));
    expect(top.dy, lessThan(geometry.center.dy));
    expect(right.dx, greaterThan(geometry.center.dx));
    expect(right.dy, closeTo(geometry.center.dy, .000001));
    expect(bottom.dx, closeTo(geometry.center.dx, .000001));
    expect(bottom.dy, greaterThan(geometry.center.dy));
    expect(left.dx, lessThan(geometry.center.dx));
    expect(left.dy, closeTo(geometry.center.dy, .000001));
    expect(seam.dx, closeTo(top.dx, .000001));
    expect(seam.dy, closeTo(top.dy, .000001));
  });

  test(
    'SUM scale seam is red ending into healthy green clockwise at twelve',
    () {
      final healthy = FluviVisualTokens.budgetProgressHealthy;
      expect(
        BudgetProgressRingSumHealthScale.colorForRatio(
          ratio: .0001,
          healthy: healthy,
        ),
        healthy,
      );
      expect(
        BudgetProgressRingSumHealthScale.colorForRatio(
          ratio: .82,
          healthy: healthy,
        ),
        FluviVisualTokens.budgetProgressWarning,
      );
      expect(
        BudgetProgressRingSumHealthScale.colorForRatio(
          ratio: .9999,
          healthy: healthy,
        ),
        FluviVisualTokens.budgetProgressDanger,
      );
      expect(BudgetProgressRingSumHealthScale.healthyWarningBoundary, .75);
      expect(BudgetProgressRingSumHealthScale.warningDangerBoundary, .90);
    },
  );

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
