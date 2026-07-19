import 'package:flutter/material.dart';

/// Immutable, computed visual state for the Spendee common Budget header.
///
/// The source of truth is `docs/prototypes/color_lab.html`. Line references in
/// this file point to the approved 2026-07-13 prototype revision.
@immutable
class SpendeeHeaderVisualSpec {
  const SpendeeHeaderVisualSpec._({
    required this.scaleCenter,
    required this.scaleWindow,
    required this.samplePositions,
    required this.gradientColors,
    required this.gradientStops,
    required this.gradientCssAngleDegrees,
    required this.graphicLayerOpacity,
    required this.reactiveAccentMix,
    required this.reactiveAccent,
    required this.reactiveGlossOpacity,
    required this.geometry,
    required this.glass,
    required this.glow,
    required this.budget,
    required this.menu,
    required this.handle,
  });

  /// HTML lines 78–91 and 7514–7525.
  static const List<Color> coolScaleStops = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFE6FBFF),
    Color(0xFFBDF5FF),
    Color(0xFF75E6FF),
    Color(0xFF22D3EE),
    Color(0xFF06B6D4),
    Color(0xFF0284C7),
    Color(0xFF0057D9),
    Color(0xFF0030A8),
    Color(0xFF00135F),
  ];

  /// HTML lines 99–114 and 7527–7538.
  static const List<double> opacityScaleStops = <double>[
    0.16,
    0.24,
    0.32,
    0.42,
    0.52,
    0.62,
    0.72,
    0.82,
    0.91,
    1,
  ];

  static const SpendeeHeaderGeometrySpec _htmlGeometry =
      SpendeeHeaderGeometrySpec._(
        referenceViewport: Size(412, 892),
        headerTop: 104,
        headerHorizontalInset: 20,
        stage0Height: 104,
        stage1Height: 238,
        contentGap: 4,
        stage2SafetyBottom: 18,
        bottomNavHeight: 80,
        searchPillHeight: 46,
        typeRowHeight: 66,
        summaryVisibleHeight: 59,
        searchTopGap: 12,
        searchVisibleHeight: 45,
      );

  static const SpendeeHeaderGlassSpec _htmlGlass = SpendeeHeaderGlassSpec._(
    radius: 24,
    borderWidth: 1,
    borderColor: Colors.white,
    backdropBlurSigma: 18,
    whiteGlossCenter: Offset(0.14, 0.20),
    whiteGlossOpacity: 0.52,
    whiteGlossEndStop: 0.32,
    reactiveGlossRightInset: 36.8,
    reactiveGlossY: 30.8,
    reactiveGlossStops: <double>[0, 0.34, 0.68],
    reactiveGlossOpacities: <double>[0.26, 0.13, 0],
    diagonalGlossCssAngleDegrees: 164,
    diagonalGlossOpacity: 0.28,
    diagonalGlossEndStop: 0.54,
    cardShadows: <BoxShadow>[],
  );

  static const SpendeeHeaderGlowSpec _htmlGlow = SpendeeHeaderGlowSpec._(
    horizontalOverflow: 36,
    top: 24,
    baseHeight: 264,
    baselineHeaderHeight: 104,
    radius: 44,
    blurSigma: 34,
    opacity: 0.24,
    verticalFadeHeight: 48,
    radialMaskStops: <double>[0, 0.46, 0.72, 0.90, 1],
    radialMaskOpacities: <double>[1, 0.88, 0.56, 0.18, 0],
  );

  static const SpendeeBudgetStageSpec _htmlBudget = SpendeeBudgetStageSpec._(
    stage1HorizontalInset: 16,
    stage1Top: 96,
    stage1Height: 130,
    avatarSizes: <double>[36, 46, 66],
    avatarIconSizes: <double>[17, 22, 30],
    stage2Top: 236,
    stage2Bottom: 18,
    donutVisualSize: 112,
    donutCoordinateSize: 120,
    donutRadius: 40,
    donutBaseStrokeWidth: 13,
    donutSelectedStrokeWidth: 17,
    donutCenterRadius: 29,
    donutSelectedGlowBlur: 8,
    donutSelectedGlowOpacity: 1,
  );

  static const SpendeeHeaderMenuSpec _htmlMenu = SpendeeHeaderMenuSpec._(
    size: 33.6,
    radius: 13.6,
    top: 14,
    right: 20,
    fillColor: Color.fromRGBO(255, 255, 255, 0.32),
    borderColor: Color.fromRGBO(255, 255, 255, 0.48),
    borderWidth: 1,
    topInsetColor: Color.fromRGBO(255, 255, 255, 0.68),
    bottomInsetColor: Color.fromRGBO(120, 220, 230, 0.14),
    insetWidth: 1,
    barWidth: 16,
    barHeight: 3,
    barGap: 3,
    barRadius: 1.5,
    barGradientStops: <double>[0, 0.52, 1],
    barGradientColors: <Color>[
      Color.fromRGBO(255, 255, 255, 0.96),
      Color.fromRGBO(222, 255, 255, 0.72),
      Color.fromRGBO(149, 229, 236, 0.46),
    ],
  );

  static const SpendeeHeaderHandleSpec _htmlHandle = SpendeeHeaderHandleSpec._(
    hitHeight: 28,
    width: 38,
    height: 4,
    bottom: 7,
    radius: 999,
    fillColor: Color.fromRGBO(255, 255, 255, 0.86),
    topInsetColor: Color.fromRGBO(255, 255, 255, 0.74),
    outerShadow: BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.13),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  );

  /// Computes the prototype's default Budget state.
  ///
  /// HTML lines 7566–7576 define center `50` and window `28`; lines 7745–7753
  /// sample the resulting positions `36`, `50`, and `64` into a 112° gradient.
  /// Mode opacity is sampled at `50` by lines 7599–7603 and 7702–7710.
  factory SpendeeHeaderVisualSpec.budgetDefault() {
    const scaleCenter = 50.0;
    const scaleWindow = 28.0;
    const samplePositions = <double>[36, 50, 64];
    final gradientColors = List<Color>.unmodifiable(
      samplePositions.map(sampleCoolScale),
    );
    // HTML lines 7435–7440 choose the final gradient stop, mix it 42% toward
    // white with the same rounded RGB helper, then render it at alpha .26.
    final reactiveAccent = _mixOpaqueRgb(
      gradientColors.last,
      Colors.white,
      0.42,
    );

    return SpendeeHeaderVisualSpec._(
      scaleCenter: scaleCenter,
      scaleWindow: scaleWindow,
      samplePositions: samplePositions,
      gradientColors: gradientColors,
      gradientStops: const <double>[0, 0.5, 1],
      gradientCssAngleDegrees: 112,
      graphicLayerOpacity: sampleOpacityScale(50),
      reactiveAccentMix: 0.42,
      reactiveAccent: reactiveAccent,
      reactiveGlossOpacity: 0.26,
      geometry: _htmlGeometry,
      glass: _htmlGlass,
      glow: _htmlGlow,
      budget: _htmlBudget,
      menu: _htmlMenu,
      handle: _htmlHandle,
    );
  }

  final double scaleCenter;
  final double scaleWindow;
  final List<double> samplePositions;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final double gradientCssAngleDegrees;
  final double graphicLayerOpacity;
  final double reactiveAccentMix;
  final Color reactiveAccent;
  final double reactiveGlossOpacity;
  final SpendeeHeaderGeometrySpec geometry;
  final SpendeeHeaderGlassSpec glass;
  final SpendeeHeaderGlowSpec glow;
  final SpendeeBudgetStageSpec budget;
  final SpendeeHeaderMenuSpec menu;
  final SpendeeHeaderHandleSpec handle;

  Color get reactiveGlossColor =>
      reactiveAccent.withValues(alpha: reactiveGlossOpacity);

  /// Mirrors the clamped, evenly spaced interpolation at HTML lines 7640–7647.
  static Color sampleCoolScale(double position) {
    final bounded = position.clamp(0.0, 100.0).toDouble();
    final scaled = (bounded / 100) * (coolScaleStops.length - 1);
    final index = scaled.floor();
    final nextIndex = (index + 1).clamp(0, coolScaleStops.length - 1);
    return _mixOpaqueRgb(
      coolScaleStops[index],
      coolScaleStops[nextIndex],
      scaled - index,
    );
  }

  /// Mirrors the clamped scalar interpolation at HTML lines 7649–7655.
  static double sampleOpacityScale(double position) {
    final bounded = position.clamp(0.0, 100.0).toDouble();
    final scaled = (bounded / 100) * (opacityScaleStops.length - 1);
    final index = scaled.floor();
    final nextIndex = (index + 1).clamp(0, opacityScaleStops.length - 1);
    return opacityScaleStops[index] +
        (opacityScaleStops[nextIndex] - opacityScaleStops[index]) *
            (scaled - index);
  }

  /// Mirrors `mixColor`/`Math.round` at HTML lines 7630–7637.
  static Color _mixOpaqueRgb(Color left, Color right, double amount) {
    final bounded = amount.clamp(0.0, 1.0).toDouble();
    final leftArgb = left.toARGB32();
    final rightArgb = right.toARGB32();

    int mixChannel(int shift) {
      final leftChannel = (leftArgb >> shift) & 0xFF;
      final rightChannel = (rightArgb >> shift) & 0xFF;
      return (leftChannel + (rightChannel - leftChannel) * bounded).round();
    }

    return Color.fromARGB(0xFF, mixChannel(16), mixChannel(8), mixChannel(0));
  }
}

/// Header and downstream safety geometry from HTML lines 21–41 and 805–815.
@immutable
class SpendeeHeaderGeometrySpec {
  const SpendeeHeaderGeometrySpec._({
    required this.referenceViewport,
    required this.headerTop,
    required this.headerHorizontalInset,
    required this.stage0Height,
    required this.stage1Height,
    required this.contentGap,
    required this.stage2SafetyBottom,
    required this.bottomNavHeight,
    required this.searchPillHeight,
    required this.typeRowHeight,
    required this.summaryVisibleHeight,
    required this.searchTopGap,
    required this.searchVisibleHeight,
  });

  final Size referenceViewport;
  final double headerTop;
  final double headerHorizontalInset;
  final double stage0Height;
  final double stage1Height;
  final double contentGap;
  final double stage2SafetyBottom;
  final double bottomNavHeight;
  final double searchPillHeight;
  final double typeRowHeight;
  final double summaryVisibleHeight;
  final double searchTopGap;
  final double searchVisibleHeight;

  double get stage2VisibleStackHeight =>
      typeRowHeight + summaryVisibleHeight + searchTopGap + searchVisibleHeight;

  double stage2HeightFor(double screenHeight) =>
      screenHeight -
      bottomNavHeight -
      searchTopGap -
      headerTop -
      contentGap -
      stage2VisibleStackHeight;

  double contentTopFor(double headerHeight) =>
      headerTop + headerHeight + contentGap;
}

/// Glass paint tokens from HTML lines 835–867.
@immutable
class SpendeeHeaderGlassSpec {
  const SpendeeHeaderGlassSpec._({
    required this.radius,
    required this.borderWidth,
    required this.borderColor,
    required this.backdropBlurSigma,
    required this.whiteGlossCenter,
    required this.whiteGlossOpacity,
    required this.whiteGlossEndStop,
    required this.reactiveGlossRightInset,
    required this.reactiveGlossY,
    required this.reactiveGlossStops,
    required this.reactiveGlossOpacities,
    required this.diagonalGlossCssAngleDegrees,
    required this.diagonalGlossOpacity,
    required this.diagonalGlossEndStop,
    required this.cardShadows,
  });

  final double radius;
  final double borderWidth;
  final Color borderColor;
  final double backdropBlurSigma;
  final Offset whiteGlossCenter;
  final double whiteGlossOpacity;
  final double whiteGlossEndStop;
  final double reactiveGlossRightInset;
  final double reactiveGlossY;
  final List<double> reactiveGlossStops;
  final List<double> reactiveGlossOpacities;
  final double diagonalGlossCssAngleDegrees;
  final double diagonalGlossOpacity;
  final double diagonalGlossEndStop;
  final List<BoxShadow> cardShadows;
}

/// Intersected outer-glow masks from HTML lines 554–568 and 831–833.
@immutable
class SpendeeHeaderGlowSpec {
  const SpendeeHeaderGlowSpec._({
    required this.horizontalOverflow,
    required this.top,
    required this.baseHeight,
    required this.baselineHeaderHeight,
    required this.radius,
    required this.blurSigma,
    required this.opacity,
    required this.verticalFadeHeight,
    required this.radialMaskStops,
    required this.radialMaskOpacities,
  });

  final double horizontalOverflow;
  final double top;
  final double baseHeight;
  final double baselineHeaderHeight;
  final double radius;
  final double blurSigma;
  final double opacity;
  final double verticalFadeHeight;
  final List<double> radialMaskStops;
  final List<double> radialMaskOpacities;

  double heightForHeader(double headerHeight) =>
      baseHeight + headerHeight - baselineHeaderHeight;
}

/// Budget C2/C3 geometry from the approved HTML stage layers and donut SVG.
@immutable
class SpendeeBudgetStageSpec {
  const SpendeeBudgetStageSpec._({
    required this.stage1HorizontalInset,
    required this.stage1Top,
    required this.stage1Height,
    required this.avatarSizes,
    required this.avatarIconSizes,
    required this.stage2Top,
    required this.stage2Bottom,
    required this.donutVisualSize,
    required this.donutCoordinateSize,
    required this.donutRadius,
    required this.donutBaseStrokeWidth,
    required this.donutSelectedStrokeWidth,
    required this.donutCenterRadius,
    required this.donutSelectedGlowBlur,
    required this.donutSelectedGlowOpacity,
  });

  final double stage1HorizontalInset;
  final double stage1Top;
  final double stage1Height;
  final List<double> avatarSizes;
  final List<double> avatarIconSizes;
  final double stage2Top;
  final double stage2Bottom;
  final double donutVisualSize;
  final double donutCoordinateSize;
  final double donutRadius;
  final double donutBaseStrokeWidth;
  final double donutSelectedStrokeWidth;
  final double donutCenterRadius;
  final double donutSelectedGlowBlur;
  final double donutSelectedGlowOpacity;
}

/// Foreground menu geometry and inset/gradient tokens from HTML lines 932–952
/// and 3017–3028.
@immutable
class SpendeeHeaderMenuSpec {
  const SpendeeHeaderMenuSpec._({
    required this.size,
    required this.radius,
    required this.top,
    required this.right,
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.topInsetColor,
    required this.bottomInsetColor,
    required this.insetWidth,
    required this.barWidth,
    required this.barHeight,
    required this.barGap,
    required this.barRadius,
    required this.barGradientStops,
    required this.barGradientColors,
  });

  final double size;
  final double radius;
  final double top;
  final double right;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final Color topInsetColor;
  final Color bottomInsetColor;
  final double insetWidth;
  final double barWidth;
  final double barHeight;
  final double barGap;
  final double barRadius;
  final List<double> barGradientStops;
  final List<Color> barGradientColors;
}

/// Visible and hit-target handle tokens from HTML lines 1044–1057 and the
/// approved 28-pixel interaction contract.
@immutable
class SpendeeHeaderHandleSpec {
  const SpendeeHeaderHandleSpec._({
    required this.hitHeight,
    required this.width,
    required this.height,
    required this.bottom,
    required this.radius,
    required this.fillColor,
    required this.topInsetColor,
    required this.outerShadow,
  });

  final double hitHeight;
  final double width;
  final double height;
  final double bottom;
  final double radius;
  final Color fillColor;
  final Color topInsetColor;
  final BoxShadow outerShadow;
}
