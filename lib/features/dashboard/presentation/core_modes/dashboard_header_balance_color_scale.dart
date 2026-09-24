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

/// The fixed authored intensity variant for a Balance palette family.
///
/// The values are deliberately not derived from another colour space. Each
/// family/variant pair has its own approved anchor list in the catalog below.
enum DashboardBalanceHeaderPaletteVariant { original, saturated, vivid }

extension DashboardBalanceHeaderPaletteVariantPresentation
    on DashboardBalanceHeaderPaletteVariant {
  String get label => switch (this) {
    DashboardBalanceHeaderPaletteVariant.original => 'Eredeti',
    DashboardBalanceHeaderPaletteVariant.saturated => 'Telítettebb',
    DashboardBalanceHeaderPaletteVariant.vivid => 'Élénk',
  };
}

@immutable
final class DashboardBalanceHeaderColorState {
  const DashboardBalanceHeaderColorState({
    required this.palette,
    this.variant = DashboardBalanceHeaderPaletteVariant.original,
    required this.positionPercent,
    required this.windowWidthPercent,
  });

  const DashboardBalanceHeaderColorState.defaults()
    : palette = DashboardBalanceHeaderPalette.softRainbow,
      variant = DashboardBalanceHeaderPaletteVariant.original,
      positionPercent = 50,
      windowWidthPercent = 28;

  final DashboardBalanceHeaderPalette palette;
  final DashboardBalanceHeaderPaletteVariant variant;
  final double positionPercent;
  final double windowWidthPercent;

  DashboardBalanceHeaderColorState copyWith({
    DashboardBalanceHeaderPalette? palette,
    DashboardBalanceHeaderPaletteVariant? variant,
    double? positionPercent,
    double? windowWidthPercent,
  }) => DashboardBalanceHeaderColorState(
    palette: palette ?? this.palette,
    variant: variant ?? this.variant,
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
      variant == other.variant &&
      positionPercent == other.positionPercent &&
      windowWidthPercent == other.windowWidthPercent;

  @override
  int get hashCode =>
      Object.hash(palette, variant, positionPercent, windowWidthPercent);
}

@immutable
final class DashboardBalanceHeaderPaletteScale {
  const DashboardBalanceHeaderPaletteScale({
    required this.palette,
    required this.variant,
    required this.colors,
  });

  final DashboardBalanceHeaderPalette palette;
  final DashboardBalanceHeaderPaletteVariant variant;
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
    Map<
      DashboardBalanceHeaderPaletteVariant,
      DashboardBalanceHeaderPaletteScale
    >
  >
  _scales =
      Map<
        DashboardBalanceHeaderPalette,
        Map<
          DashboardBalanceHeaderPaletteVariant,
          DashboardBalanceHeaderPaletteScale
        >
      >.unmodifiable(<
        DashboardBalanceHeaderPalette,
        Map<
          DashboardBalanceHeaderPaletteVariant,
          DashboardBalanceHeaderPaletteScale
        >
      >{
        DashboardBalanceHeaderPalette.softRainbow: _variants(
          DashboardBalanceHeaderPalette.softRainbow,
          original: <int>[
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
          ],
          saturated: <int>[
            0xfffff99f,
            0xffffcea4,
            0xffffa6ac,
            0xffff89e9,
            0xffb382ff,
            0xff6eaaff,
            0xff5cd6ff,
            0xff5bf1ff,
            0xff65ffde,
            0xff8cff98,
          ],
          vivid: <int>[
            0xffffd81a,
            0xffff9d45,
            0xffff6674,
            0xfff044c7,
            0xff8a5cff,
            0xff3d84f7,
            0xff27c0eb,
            0xff20dde4,
            0xff28ddb4,
            0xff58e66b,
          ],
        ),
        DashboardBalanceHeaderPalette.levanderRoseEmbrace: _variants(
          DashboardBalanceHeaderPalette.levanderRoseEmbrace,
          original: <int>[
            0xffaf99ff,
            0xffcaadff,
            0xffffc2e2,
            0xffffadc7,
            0xffff99b6,
          ],
          saturated: <int>[
            0xff9678ff,
            0xffb388ff,
            0xffff9ed6,
            0xffff7fae,
            0xffff6a95,
          ],
          vivid: <int>[
            0xff7a52ff,
            0xff9f66ff,
            0xffff78cb,
            0xffff4f96,
            0xffff3380,
          ],
        ),
        DashboardBalanceHeaderPalette.majesticLevanderDreams: _variants(
          DashboardBalanceHeaderPalette.majesticLevanderDreams,
          original: <int>[
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
          saturated: <int>[
            0xff9448c8,
            0xffa753e0,
            0xffb85eff,
            0xffc96eff,
            0xffdb7dff,
            0xffea8fff,
            0xffff9aff,
            0xffffabff,
            0xffffb3ff,
            0xffffbbff,
          ],
          vivid: <int>[
            0xff812db8,
            0xff9538d4,
            0xffa841ff,
            0xffba4eff,
            0xffd35eff,
            0xffe66eff,
            0xffff78ff,
            0xffff8cff,
            0xffff96ff,
            0xffffa3ff,
          ],
        ),
        DashboardBalanceHeaderPalette.fairyLossDream: _variants(
          DashboardBalanceHeaderPalette.fairyLossDream,
          original: <int>[
            0xfffcd6f9,
            0xffffc6fe,
            0xfff6b2ff,
            0xffceafff,
            0xffc19bff,
          ],
          saturated: <int>[
            0xfff8b3f4,
            0xffff9dfe,
            0xffee8cff,
            0xffb991ff,
            0xffa56fff,
          ],
          vivid: <int>[
            0xfff48ced,
            0xffff72fd,
            0xffe165ff,
            0xffa46bff,
            0xff8c41ff,
          ],
        ),
        DashboardBalanceHeaderPalette.lecanderSpringWishper: _variants(
          DashboardBalanceHeaderPalette.lecanderSpringWishper,
          original: <int>[
            0xffa06ec4,
            0xffcba9ef,
            0xffebe0f5,
            0xfff8b5d2,
            0xffe378a8,
          ],
          saturated: <int>[
            0xff8b4fbe,
            0xffb78be8,
            0xffdbc5f0,
            0xfff493bc,
            0xffd4558f,
          ],
          vivid: <int>[
            0xff7430b8,
            0xffa66adb,
            0xffc9aceb,
            0xffef6fa6,
            0xffc93378,
          ],
        ),
        DashboardBalanceHeaderPalette.cottonCandyDreams: _variants(
          DashboardBalanceHeaderPalette.cottonCandyDreams,
          original: <int>[
            0xffffb2e6,
            0xfff6a2ed,
            0xffec92f3,
            0xffe382f9,
            0xffd972ff,
          ],
          saturated: <int>[
            0xffff8cd8,
            0xfff67eea,
            0xffe56bed,
            0xffda5ff6,
            0xffc94eff,
          ],
          vivid: <int>[
            0xffff6bce,
            0xfff453e5,
            0xffde43e8,
            0xffd02ff3,
            0xffba1eff,
          ],
        ),
        // The five otherwise unnamed supplied colours deliberately continue
        // this palette. There is no tenth user-approved palette identity.
        DashboardBalanceHeaderPalette.whimiscalUnicornDream: _variants(
          DashboardBalanceHeaderPalette.whimiscalUnicornDream,
          original: <int>[
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
          ],
          saturated: <int>[
            0xff8a6be6,
            0xff946dff,
            0xffb583ff,
            0xffff9dd6,
            0xffff82af,
            0xffff6e9a,
            0xffb22eff,
            0xffa537ff,
            0xff962eff,
            0xff7d23ff,
            0xff6717ff,
          ],
          vivid: <int>[
            0xff7449e6,
            0xff7a49ff,
            0xffa458ff,
            0xffff75c6,
            0xffff5b95,
            0xffff3d7a,
            0xff9e00ff,
            0xff8c00ff,
            0xff7b00ff,
            0xff6200f8,
            0xff4700f5,
          ],
        ),
        DashboardBalanceHeaderPalette.misticLevanderFields: _variants(
          DashboardBalanceHeaderPalette.misticLevanderFields,
          original: <int>[
            0xfffdc5f5,
            0xfff7aef8,
            0xffb388eb,
            0xffc2a0ef,
            0xffceb3f2,
          ],
          saturated: <int>[
            0xfffd9af1,
            0xfff376f4,
            0xff9d5fe6,
            0xffa77ae9,
            0xffb891ed,
          ],
          vivid: <int>[
            0xfffc6aed,
            0xffed3eea,
            0xff7e36e4,
            0xff9250e5,
            0xffa16ae8,
          ],
        ),
        DashboardBalanceHeaderPalette.magicalLevanderHaze: _variants(
          DashboardBalanceHeaderPalette.magicalLevanderHaze,
          original: <int>[
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
          ],
          saturated: <int>[
            0xff4a15e6,
            0xff5a2cff,
            0xff7b4dff,
            0xffa16cff,
            0xffcc82f0,
            0xffff93d6,
            0xffff79b6,
            0xffff5d98,
            0xfff55d7d,
            0xffea5370,
          ],
          vivid: <int>[
            0xff3b07d6,
            0xff4a17ff,
            0xff6732ff,
            0xff9249ff,
            0xffbe5fea,
            0xffff61c9,
            0xffff419f,
            0xffff2f7a,
            0xffee2e5f,
            0xffe11f49,
          ],
        ),
        DashboardBalanceHeaderPalette.limitColorLab: _variants(
          DashboardBalanceHeaderPalette.limitColorLab,
          original: <int>[
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
          ],
          saturated: <int>[
            0xff5b1acf,
            0xff7c3ff2,
            0xff9568f7,
            0xffc99afd,
            0xfff8a8d8,
            0xfff678bf,
            0xffec409f,
            0xffe51e7e,
            0xffd81f6e,
            0xffc9165f,
          ],
          vivid: <int>[
            0xff4a0fbf,
            0xff6829e8,
            0xff7e3ef5,
            0xffb876fb,
            0xfff48ace,
            0xfff43ea8,
            0xffe91a85,
            0xffd7006b,
            0xffc10058,
            0xffad004b,
          ],
        ),
        DashboardBalanceHeaderPalette.customBalance: _variants(
          DashboardBalanceHeaderPalette.customBalance,
          original: <int>[
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
          ],
          saturated: <int>[
            0xff6842ff,
            0xff8758ff,
            0xffa272ff,
            0xffca78ec,
            0xffed5ac6,
            0xffff4ba4,
            0xffff3b8a,
            0xffff6a58,
            0xffff7f36,
            0xffffa74a,
          ],
          vivid: <int>[
            0xff5628ff,
            0xff7139ff,
            0xff924eff,
            0xffbb4fe8,
            0xffe331b7,
            0xffff228c,
            0xffff0f6e,
            0xffff4b36,
            0xffff6a14,
            0xffff9526,
          ],
        ),
      });

  static DashboardBalanceHeaderPaletteScale scaleFor(
    DashboardBalanceHeaderPalette palette, [
    DashboardBalanceHeaderPaletteVariant variant =
        DashboardBalanceHeaderPaletteVariant.original,
  ]) => _scales[palette]![variant]!;

  static List<DashboardBalanceHeaderPalette> get palettes =>
      List<DashboardBalanceHeaderPalette>.unmodifiable(
        DashboardBalanceHeaderPalette.values,
      );

  static List<DashboardBalanceHeaderPaletteVariant> get variants =>
      List<DashboardBalanceHeaderPaletteVariant>.unmodifiable(
        DashboardBalanceHeaderPaletteVariant.values,
      );

  static Map<
    DashboardBalanceHeaderPaletteVariant,
    DashboardBalanceHeaderPaletteScale
  >
  _variants(
    DashboardBalanceHeaderPalette palette, {
    required List<int> original,
    required List<int> saturated,
    required List<int> vivid,
  }) =>
      Map<
        DashboardBalanceHeaderPaletteVariant,
        DashboardBalanceHeaderPaletteScale
      >.unmodifiable(<
        DashboardBalanceHeaderPaletteVariant,
        DashboardBalanceHeaderPaletteScale
      >{
        DashboardBalanceHeaderPaletteVariant.original: _scale(
          palette,
          DashboardBalanceHeaderPaletteVariant.original,
          original,
        ),
        DashboardBalanceHeaderPaletteVariant.saturated: _scale(
          palette,
          DashboardBalanceHeaderPaletteVariant.saturated,
          saturated,
        ),
        DashboardBalanceHeaderPaletteVariant.vivid: _scale(
          palette,
          DashboardBalanceHeaderPaletteVariant.vivid,
          vivid,
        ),
      });

  static DashboardBalanceHeaderPaletteScale _scale(
    DashboardBalanceHeaderPalette palette,
    DashboardBalanceHeaderPaletteVariant variant,
    List<int> argb,
  ) => DashboardBalanceHeaderPaletteScale(
    palette: palette,
    variant: variant,
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
    final scale = DashboardBalanceHeaderPaletteCatalog.scaleFor(
      state.palette,
      state.variant,
    );
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
