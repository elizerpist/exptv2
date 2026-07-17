import 'package:exptv2/features/transactions/widgets/experimental/spendee_header_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpendeeHeaderVisualSpec Budget computation', () {
    test('samples the exact HTML cool scale colors at 36, 50, and 64', () {
      expect(
        SpendeeHeaderVisualSpec.sampleCoolScale(36),
        const Color(0xFF61E1FB),
      );
      expect(
        SpendeeHeaderVisualSpec.sampleCoolScale(50),
        const Color(0xFF14C5E1),
      );
      expect(
        SpendeeHeaderVisualSpec.sampleCoolScale(64),
        const Color(0xFF0390CA),
      );

      final spec = SpendeeHeaderVisualSpec.budgetDefault();
      expect(spec.gradientColors, const <Color>[
        Color(0xFF61E1FB),
        Color(0xFF14C5E1),
        Color(0xFF0390CA),
      ]);
      expect(spec.gradientStops, const <double>[0, 0.5, 1]);
      expect(spec.gradientCssAngleDegrees, 112);
    });

    test('samples the exact HTML graphic-layer opacity at center 50', () {
      expect(
        SpendeeHeaderVisualSpec.sampleOpacityScale(50),
        closeTo(0.57, 1e-12),
      );
      expect(
        SpendeeHeaderVisualSpec.budgetDefault().graphicLayerOpacity,
        closeTo(0.57, 1e-12),
      );
    });

    test('mixes the sampled right stop 42 percent toward white', () {
      final spec = SpendeeHeaderVisualSpec.budgetDefault();

      expect(spec.reactiveAccentMix, 0.42);
      expect(spec.reactiveAccent, const Color(0xFF6DBFE0));
      expect(
        spec.reactiveGlossColor,
        const Color(0xFF6DBFE0).withValues(alpha: 0.26),
      );
    });

    test('clamps scale samples and exposes immutable stop collections', () {
      expect(
        SpendeeHeaderVisualSpec.sampleCoolScale(-20),
        const Color(0xFFFFFFFF),
      );
      expect(
        SpendeeHeaderVisualSpec.sampleCoolScale(120),
        const Color(0xFF00135F),
      );
      expect(
        SpendeeHeaderVisualSpec.sampleOpacityScale(-20),
        closeTo(0.16, 1e-12),
      );
      expect(
        SpendeeHeaderVisualSpec.sampleOpacityScale(120),
        closeTo(1, 1e-12),
      );

      final spec = SpendeeHeaderVisualSpec.budgetDefault();
      expect(
        () => SpendeeHeaderVisualSpec.coolScaleStops.add(Colors.black),
        throwsUnsupportedError,
      );
      expect(
        () => SpendeeHeaderVisualSpec.opacityScaleStops.add(0),
        throwsUnsupportedError,
      );
      expect(
        () => spec.gradientColors.add(Colors.black),
        throwsUnsupportedError,
      );
    });
  });

  group('SpendeeHeaderVisualSpec HTML geometry', () {
    test('centralizes exact header and stage dimensions', () {
      final geometry = SpendeeHeaderVisualSpec.budgetDefault().geometry;

      expect(geometry.referenceViewport, const Size(412, 892));
      expect(geometry.headerTop, 104);
      expect(geometry.headerHorizontalInset, 20);
      expect(geometry.stage0Height, 104);
      expect(geometry.stage1Height, 238);
      expect(geometry.contentGap, 4);
      expect(geometry.stage2SafetyBottom, 18);
      expect(geometry.bottomNavHeight, 80);
      expect(geometry.typeRowHeight, 66);
      expect(geometry.summaryVisibleHeight, 59);
      expect(geometry.searchTopGap, 12);
      expect(geometry.searchVisibleHeight, 45);
      expect(geometry.searchPillHeight, 46);
      expect(geometry.stage2HeightFor(892), 510);
      expect(geometry.contentTopFor(geometry.stage0Height), 212);
    });

    test('centralizes glass layers and exact HTML card shadow tokens', () {
      final glass = SpendeeHeaderVisualSpec.budgetDefault().glass;

      expect(glass.radius, 24);
      expect(glass.borderWidth, 1);
      expect(glass.borderColor, Colors.white);
      expect(glass.backdropBlurSigma, 18);
      expect(glass.whiteGlossCenter, const Offset(0.14, 0.20));
      expect(glass.whiteGlossOpacity, 0.52);
      expect(glass.whiteGlossEndStop, 0.32);
      expect(glass.reactiveGlossRightInset, 36.8);
      expect(glass.reactiveGlossY, 30.8);
      expect(glass.reactiveGlossStops, const <double>[0, 0.34, 0.68]);
      expect(glass.reactiveGlossOpacities, const <double>[0.26, 0.13, 0]);
      expect(glass.diagonalGlossCssAngleDegrees, 164);
      expect(glass.diagonalGlossOpacity, 0.28);
      expect(glass.diagonalGlossEndStop, 0.54);

      expect(glass.cardShadows, hasLength(2));
      expect(
        glass.cardShadows[0].color,
        const Color.fromRGBO(244, 114, 182, 0.18),
      );
      expect(glass.cardShadows[0].offset, const Offset(0, 18));
      expect(glass.cardShadows[0].blurRadius, 42);
      expect(
        glass.cardShadows[1].color,
        const Color.fromRGBO(139, 92, 246, 0.12),
      );
      expect(glass.cardShadows[1].offset, const Offset(0, 14));
      expect(glass.cardShadows[1].blurRadius, 34);
    });

    test('centralizes the intersected outer-glow masks and growth rule', () {
      final glow = SpendeeHeaderVisualSpec.budgetDefault().glow;

      expect(glow.horizontalOverflow, 36);
      expect(glow.top, 24);
      expect(glow.baseHeight, 264);
      expect(glow.radius, 44);
      expect(glow.blurSigma, 34);
      expect(glow.opacity, 0.24);
      expect(glow.verticalFadeHeight, 48);
      expect(glow.radialMaskStops, const <double>[0, 0.46, 0.72, 0.90, 1]);
      expect(glow.radialMaskOpacities, const <double>[1, 0.88, 0.56, 0.18, 0]);
      expect(glow.heightForHeader(104), 264);
      expect(glow.heightForHeader(238), 398);
    });

    test('centralizes the approved C2 and C3 budget-stage geometry', () {
      final budget = SpendeeHeaderVisualSpec.budgetDefault().budget;

      expect(budget.stage1HorizontalInset, 16);
      expect(budget.stage1Top, 96);
      expect(budget.stage1Height, 130);
      expect(budget.avatarSizes, const <double>[36, 46, 66]);
      expect(budget.avatarIconSizes, const <double>[17, 22, 30]);
      expect(budget.stage2Top, 236);
      expect(budget.stage2Bottom, 18);
      expect(budget.donutVisualSize, 112);
      expect(budget.donutCoordinateSize, 120);
      expect(budget.donutRadius, 40);
      expect(budget.donutBaseStrokeWidth, 13);
      expect(budget.donutSelectedStrokeWidth, 17);
      expect(budget.donutCenterRadius, 29);
      expect(budget.donutSelectedGlowBlur, 8);
      expect(budget.donutSelectedGlowOpacity, 1);
    });

    test('centralizes the exact HTML menu and handle tokens', () {
      final spec = SpendeeHeaderVisualSpec.budgetDefault();
      final menu = spec.menu;
      final handle = spec.handle;

      expect(menu.size, 33.6);
      expect(menu.radius, 13.6);
      expect(menu.top, 14);
      expect(menu.right, 20);
      expect(menu.fillColor, const Color.fromRGBO(255, 255, 255, 0.32));
      expect(menu.borderColor, const Color.fromRGBO(255, 255, 255, 0.48));
      expect(menu.borderWidth, 1);
      expect(menu.topInsetColor, const Color.fromRGBO(255, 255, 255, 0.68));
      expect(menu.bottomInsetColor, const Color.fromRGBO(120, 220, 230, 0.14));
      expect(menu.insetWidth, 1);
      expect(menu.barWidth, 16);
      expect(menu.barHeight, 3);
      expect(menu.barGap, 3);
      expect(menu.barRadius, 1.5);
      expect(menu.barGradientStops, const <double>[0, 0.52, 1]);
      expect(menu.barGradientColors, const <Color>[
        Color.fromRGBO(255, 255, 255, 0.96),
        Color.fromRGBO(222, 255, 255, 0.72),
        Color.fromRGBO(149, 229, 236, 0.46),
      ]);

      expect(handle.hitHeight, 28);
      expect(handle.width, 38);
      expect(handle.height, 4);
      expect(handle.bottom, 7);
      expect(handle.radius, 999);
      expect(handle.fillColor, const Color.fromRGBO(255, 255, 255, 0.86));
      expect(handle.topInsetColor, const Color.fromRGBO(255, 255, 255, 0.74));
      expect(handle.outerShadow.color, const Color.fromRGBO(15, 23, 42, 0.13));
      expect(handle.outerShadow.offset, const Offset(0, 2));
      expect(handle.outerShadow.blurRadius, 8);
    });
  });
}
