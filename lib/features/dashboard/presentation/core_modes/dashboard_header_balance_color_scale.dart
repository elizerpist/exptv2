import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_header_perceptual_color.dart';

/// The nine user-approved Balance-only manual palette identities. These are
/// presentation controls only: no financial or Summary value participates.
enum DashboardBalanceHeaderPalette {
  softRainbow,
  levanderRoseEmbrace,
  majesticLevanderDreams,
  fairyLossDream,
  lecanderSpringWishper,
  cottonCandyDreams,
  whimiscalUnicornDream,
  misticLevanderFields,
  magicalLevanderHaze,
  limitColorLab,
  customBalance,
}

extension DashboardBalanceHeaderPalettePresentation
    on DashboardBalanceHeaderPalette {
  String get label => switch (this) {
    DashboardBalanceHeaderPalette.softRainbow => 'Soft rainbow',
    DashboardBalanceHeaderPalette.levanderRoseEmbrace =>
      'Levander rose embrace',
    DashboardBalanceHeaderPalette.majesticLevanderDreams =>
      'Majestic levander dreams',
    DashboardBalanceHeaderPalette.fairyLossDream => 'Fairy loss dream',
    DashboardBalanceHeaderPalette.lecanderSpringWishper =>
      'Lecander spring wishper',
    DashboardBalanceHeaderPalette.cottonCandyDreams => 'Cotton candy dreams',
    DashboardBalanceHeaderPalette.whimiscalUnicornDream =>
      'Whimiscal unicorn dream',
    DashboardBalanceHeaderPalette.misticLevanderFields =>
      'Mistic levander fields',
    DashboardBalanceHeaderPalette.magicalLevanderHaze =>
      'Magical levander haze',
    DashboardBalanceHeaderPalette.limitColorLab => 'Limit (Color Lab)',
    DashboardBalanceHeaderPalette.customBalance => 'Custom Balance',
  };
}

@immutable
final class DashboardBalanceHeaderColorState {
  const DashboardBalanceHeaderColorState({
    required this.palette,
    required this.positionPercent,
    required this.windowWidthPercent,
  });

  const DashboardBalanceHeaderColorState.defaults()
    : palette = DashboardBalanceHeaderPalette.softRainbow,
      positionPercent = 50,
      windowWidthPercent = 28;

  final DashboardBalanceHeaderPalette palette;
  final double positionPercent;
  final double windowWidthPercent;

  DashboardBalanceHeaderColorState copyWith({
    DashboardBalanceHeaderPalette? palette,
    double? positionPercent,
    double? windowWidthPercent,
  }) => DashboardBalanceHeaderColorState(
    palette: palette ?? this.palette,
    positionPercent: (positionPercent ?? this.positionPercent)
        .clamp(0.0, 100.0)
        .roundToDouble(),
    windowWidthPercent: (windowWidthPercent ?? this.windowWidthPercent)
        .clamp(10.0, 100.0)
        .roundToDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardBalanceHeaderColorState &&
      palette == other.palette &&
      positionPercent == other.positionPercent &&
      windowWidthPercent == other.windowWidthPercent;

  @override
  int get hashCode => Object.hash(palette, positionPercent, windowWidthPercent);
}

@immutable
final class DashboardBalanceHeaderPaletteScale {
  const DashboardBalanceHeaderPaletteScale({
    required this.palette,
    required this.colors,
  });

  final DashboardBalanceHeaderPalette palette;
  final List<Color> colors;

  Color samplePercent(double percent) {
    final bounded = (percent.isFinite ? percent : 0)
        .clamp(0.0, 100.0)
        .toDouble();
    final position = bounded / 100 * (colors.length - 1);
    final left = position.floor().clamp(0, colors.length - 1);
    final right = math.min(colors.length - 1, left + 1);
    return DashboardHeaderPerceptualColorMath.mix(
      colors[left],
      colors[right],
      position - left,
    );
  }
}

@immutable
final class DashboardBalanceHeaderColorWindow {
  const DashboardBalanceHeaderColorWindow({
    required this.state,
    required this.leftSamplePercent,
    required this.rightSamplePercent,
    required this.colorA,
    required this.colorMid,
    required this.colorB,
  });

  final DashboardBalanceHeaderColorState state;
  final double leftSamplePercent;
  final double rightSamplePercent;
  final Color colorA;
  final Color colorMid;
  final Color colorB;

  List<Color> get colors =>
      List<Color>.unmodifiable(<Color>[colorA, colorMid, colorB]);
  List<double> get stops => const <double>[0, .5, 1];

  @override
  bool operator ==(Object other) =>
      other is DashboardBalanceHeaderColorWindow &&
      state == other.state &&
      leftSamplePercent == other.leftSamplePercent &&
      rightSamplePercent == other.rightSamplePercent &&
      colorA == other.colorA &&
      colorMid == other.colorMid &&
      colorB == other.colorB;

  @override
  int get hashCode => Object.hash(
    state,
    leftSamplePercent,
    rightSamplePercent,
    colorA,
    colorMid,
    colorB,
  );
}

abstract final class DashboardBalanceHeaderPaletteCatalog {
  static final Map<
    DashboardBalanceHeaderPalette,
    DashboardBalanceHeaderPaletteScale
  >
  _scales =
      Map<
        DashboardBalanceHeaderPalette,
        DashboardBalanceHeaderPaletteScale
      >.unmodifiable(
        <DashboardBalanceHeaderPalette, DashboardBalanceHeaderPaletteScale>{
          DashboardBalanceHeaderPalette.softRainbow:
              _scale(DashboardBalanceHeaderPalette.softRainbow, <int>[
                0xfffbf8cc,
                0xfffde4cf,
                0xffffcfd2,
                0xfff1c0e8,
                0xffcfbaf0,
                0xffa3c4f3,
                0xff90dbf4,
                0xff8eecf5,
                0xff98f5e1,
                0xffb9fbc0,
              ]),
          DashboardBalanceHeaderPalette.levanderRoseEmbrace: _scale(
            DashboardBalanceHeaderPalette.levanderRoseEmbrace,
            <int>[0xffaf99ff, 0xffcaadff, 0xffffc2e2, 0xffffadc7, 0xffff99b6],
          ),
          DashboardBalanceHeaderPalette.majesticLevanderDreams: _scale(
            DashboardBalanceHeaderPalette.majesticLevanderDreams,
            <int>[
              0xffa564d3,
              0xffb66ee8,
              0xffc879ff,
              0xffd689ff,
              0xffe498ff,
              0xfff2a8ff,
              0xffffb7ff,
              0xffffc4ff,
              0xffffc9ff,
              0xffffceff,
            ],
          ),
          DashboardBalanceHeaderPalette.fairyLossDream: _scale(
            DashboardBalanceHeaderPalette.fairyLossDream,
            <int>[0xfffcd6f9, 0xffffc6fe, 0xfff6b2ff, 0xffceafff, 0xffc19bff],
          ),
          DashboardBalanceHeaderPalette.lecanderSpringWishper: _scale(
            DashboardBalanceHeaderPalette.lecanderSpringWishper,
            <int>[0xffa06ec4, 0xffcba9ef, 0xffebe0f5, 0xfff8b5d2, 0xffe378a8],
          ),
          DashboardBalanceHeaderPalette.cottonCandyDreams: _scale(
            DashboardBalanceHeaderPalette.cottonCandyDreams,
            <int>[0xffffb2e6, 0xfff6a2ed, 0xffec92f3, 0xffe382f9, 0xffd972ff],
          ),
          // The five otherwise unnamed supplied colours deliberately continue
          // this palette. There is no tenth user-approved palette identity.
          DashboardBalanceHeaderPalette.whimiscalUnicornDream:
              _scale(DashboardBalanceHeaderPalette.whimiscalUnicornDream, <int>[
                0xff9f8be8,
                0xffaf99ff,
                0xffcaadff,
                0xffffc2e2,
                0xffffadc7,
                0xffff99b6,
                0xffc468ff,
                0xffba63ff,
                0xffaf5dff,
                0xff9a52ff,
                0xff8447ff,
              ]),
          DashboardBalanceHeaderPalette.misticLevanderFields: _scale(
            DashboardBalanceHeaderPalette.misticLevanderFields,
            <int>[0xfffdc5f5, 0xfff7aef8, 0xffb388eb, 0xffc2a0ef, 0xffceb3f2],
          ),
          DashboardBalanceHeaderPalette.magicalLevanderHaze:
              _scale(DashboardBalanceHeaderPalette.magicalLevanderHaze, <int>[
                0xff5d36e7,
                0xff6e44ff,
                0xff936bff,
                0xffb892ff,
                0xffdcaaf1,
                0xffffc2e2,
                0xffffa9cb,
                0xffff90b3,
                0xfff7859c,
                0xffef7a85,
              ]),
          DashboardBalanceHeaderPalette.limitColorLab:
              _scale(DashboardBalanceHeaderPalette.limitColorLab, <int>[
                0xff6d28d9,
                0xff8b5cf6,
                0xffa78bfa,
                0xffd8b4fe,
                0xfffbcfe8,
                0xfff9a8d4,
                0xfff472b6,
                0xffec4899,
                0xffe23883,
                0xffdb2777,
              ]),
          DashboardBalanceHeaderPalette.customBalance:
              _scale(DashboardBalanceHeaderPalette.customBalance, <int>[
                0xff7c5cff,
                0xff9b7bff,
                0xffb794ff,
                0xffd9a1f3,
                0xfff08bd6,
                0xffff7bb7,
                0xffff6ea4,
                0xffff8a7a,
                0xffff9b5f,
                0xffffb36b,
              ]),
        },
      );

  static DashboardBalanceHeaderPaletteScale scaleFor(
    DashboardBalanceHeaderPalette palette,
  ) => _scales[palette]!;

  static List<DashboardBalanceHeaderPalette> get palettes =>
      List<DashboardBalanceHeaderPalette>.unmodifiable(
        DashboardBalanceHeaderPalette.values,
      );

  static DashboardBalanceHeaderPaletteScale _scale(
    DashboardBalanceHeaderPalette palette,
    List<int> argb,
  ) => DashboardBalanceHeaderPaletteScale(
    palette: palette,
    colors: List<Color>.unmodifiable(
      argb.map(Color.new).toList(growable: false),
    ),
  );
}

abstract final class DashboardBalanceHeaderWindowSampler {
  static DashboardBalanceHeaderColorWindow sample(
    DashboardBalanceHeaderColorState state,
  ) {
    final center = state.positionPercent.clamp(0.0, 100.0).toDouble();
    final width = state.windowWidthPercent.clamp(10.0, 100.0).toDouble();
    final left = (center - width / 2).clamp(0.0, 100.0).toDouble();
    final right = (center + width / 2).clamp(0.0, 100.0).toDouble();
    final scale = DashboardBalanceHeaderPaletteCatalog.scaleFor(state.palette);
    return DashboardBalanceHeaderColorWindow(
      state: state,
      leftSamplePercent: left,
      rightSamplePercent: right,
      colorA: scale.samplePercent(left),
      colorMid: scale.samplePercent(center),
      colorB: scale.samplePercent(right),
    );
  }
}
