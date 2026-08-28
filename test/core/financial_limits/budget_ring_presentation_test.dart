import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets(
    'RED: the rendered coloured SUM raster starts green at twelve and ends '
    'red back at the seam',
    (tester) async {
      final controller = BudgetRingPresentationController();
      addTearDown(controller.dispose);
      final boundary = GlobalKey();

      Future<_RingRaster> render(BudgetSumRingStyle style) async {
        controller.selectSumRingStyle(style);
        await tester.pumpWidget(
          BudgetRingPresentationScope(
            controller: controller,
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: boundary,
                    child: const BudgetCategoryAvatarSelectionChrome(
                      categoryColor: Color(0xff8055d4),
                      geometry: BudgetLimitProgressChromeGeometry.typicalMarker,
                      typicalMarkerPosition: .40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return _captureRingRaster(tester, boundary);
      }

      for (final style in <BudgetSumRingStyle>[
        BudgetSumRingStyle.coloredScaleWhiteArc,
        BudgetSumRingStyle.coloredScaleMovingSphere,
      ]) {
        final raster = await render(style);
        final top = raster.colorForRatio(.02);
        final right = raster.colorForRatio(.25);
        final bottom = raster.colorForRatio(.50);
        final warning = raster.colorForRatio(.82);
        final danger = raster.colorForRatio(.96);
        final seam = raster.colorForRatio(.99);
        expect(_isHealthyGreen(top), isTrue, reason: '$style top=$top');
        expect(_isHealthyGreen(right), isTrue, reason: '$style right=$right');
        expect(
          _isHealthyGreen(bottom),
          isTrue,
          reason: '$style bottom=$bottom',
        );
        expect(
          _isWarningYellow(warning),
          isTrue,
          reason: '$style warning=$warning',
        );
        expect(_isDangerRed(danger), isTrue, reason: '$style danger=$danger');
        expect(
          _isDangerRed(seam),
          isTrue,
          reason:
              '$style seam=$seam; red must occupy the final clockwise span before twelve',
        );
      }
    },
  );
}

Future<_RingRaster> _captureRingRaster(
  WidgetTester tester,
  GlobalKey boundary,
) async {
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => renderBoundary.toImage(pixelRatio: 3),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('SUM ring raster bytes unavailable.');
    return _RingRaster(bytes, image.width, image.height);
  } finally {
    image.dispose();
  }
}

final class _RingRaster {
  const _RingRaster(this.bytes, this.width, this.height);

  final ByteData bytes;
  final int width;
  final int height;

  Color colorForRatio(double ratio) {
    final source = BudgetProgressRingGeometry.source;
    final point = source.pointForRatio(ratio);
    final scale = width / source.viewport.width;
    final x = (point.dx * scale).round().clamp(0, width - 1);
    final y = (point.dy * scale).round().clamp(0, height - 1);
    final offset = (y * width + x) * 4;
    return Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
  }
}

bool _isHealthyGreen(Color color) =>
    color.g > color.r * 1.10 && color.g > color.b * 1.10;

bool _isWarningYellow(Color color) =>
    color.r > color.b * 1.25 && color.g > color.b * 1.25;

bool _isDangerRed(Color color) =>
    color.r > color.g * 1.25 && color.r > color.b * 1.50;
