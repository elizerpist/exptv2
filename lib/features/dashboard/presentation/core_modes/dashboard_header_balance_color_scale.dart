import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_header_perceptual_color.dart';

/// The eight user-approved Balance-only manual palette identities. These are
/// presentation controls only: no financial or Summary value participates.
enum DashboardBalanceHeaderPalette {
  softRainbow,
  levanderRoseEmbrace,
  limitColorLab,
  customBalance,
  balanceDiverging,
  limitColorLabNoWhite,
  softRainbowNoYellowLeft,
  softRainbowReordered,
}

extension DashboardBalanceHeaderPalettePresentation
    on DashboardBalanceHeaderPalette {
  String get label => switch (this) {
    DashboardBalanceHeaderPalette.softRainbow => 'Soft rainbow',
    DashboardBalanceHeaderPalette.levanderRoseEmbrace =>
      'Levander rose embrace',
    DashboardBalanceHeaderPalette.limitColorLab => 'Limit (Color Lab)',
    DashboardBalanceHeaderPalette.customBalance => 'Custom Balance',
    DashboardBalanceHeaderPalette.balanceDiverging => 'Balance diverging',
    DashboardBalanceHeaderPalette.limitColorLabNoWhite => 'Limit (no white)',
    DashboardBalanceHeaderPalette.softRainbowNoYellowLeft =>
      'Soft rainbow (no yellow)',
    DashboardBalanceHeaderPalette.softRainbowReordered =>
      'Soft rainbow (reordered)',
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
        // Curated remixes: each anchor occurs in the pre-existing approved
        // four-family source set. They are explicit authored data, never a
        // runtime colour-space transformation.
        DashboardBalanceHeaderPalette.balanceDiverging: _variants(
          DashboardBalanceHeaderPalette.balanceDiverging,
          original: <int>[
            0xffa3c4f3,
            0xffaf99ff,
            0xffb794ff,
            0xffcfbaf0,
            0xfff1c0e8,
            0xfffbf8cc,
            0xfffde4cf,
            0xffffcfd2,
            0xffffc2e2,
            0xffffadc7,
            0xffff99b6,
          ],
          saturated: <int>[
            0xff6eaaff,
            0xff9678ff,
            0xffa272ff,
            0xffb382ff,
            0xffff89e9,
            0xfffff99f,
            0xffffcea4,
            0xffffa6ac,
            0xffff9ed6,
            0xffff7fae,
            0xffff6a95,
          ],
          vivid: <int>[
            0xff3d84f7,
            0xff7a52ff,
            0xff8a5cff,
            0xff924eff,
            0xfff044c7,
            0xffffd81a,
            0xffff9d45,
            0xffff6674,
            0xffff78cb,
            0xffff4f96,
            0xffff3380,
          ],
        ),
        DashboardBalanceHeaderPalette.limitColorLabNoWhite: _variants(
          DashboardBalanceHeaderPalette.limitColorLabNoWhite,
          original: <int>[
            0xff6d28d9,
            0xff8b5cf6,
            0xff9b7bff,
            0xffb794ff,
            0xffd9a1f3,
            0xfff08bd6,
            0xffff7bb7,
            0xffff6ea4,
            0xfff472b6,
            0xffec4899,
          ],
          saturated: <int>[
            0xff5b1acf,
            0xff7c3ff2,
            0xff8758ff,
            0xffa272ff,
            0xffca78ec,
            0xffed5ac6,
            0xfff678bf,
            0xffff4ba4,
            0xffec409f,
            0xffe51e7e,
          ],
          vivid: <int>[
            0xff4a0fbf,
            0xff6829e8,
            0xff7139ff,
            0xff924eff,
            0xffbb4fe8,
            0xffe331b7,
            0xfff43ea8,
            0xffff228c,
            0xffe91a85,
            0xffd7006b,
          ],
        ),
        DashboardBalanceHeaderPalette.softRainbowNoYellowLeft: _variants(
          DashboardBalanceHeaderPalette.softRainbowNoYellowLeft,
          original: <int>[
            0xfffde4cf,
            0xffffcfd2,
            0xfff1c0e8,
            0xffcfbaf0,
            0xffcaadff,
            0xffa3c4f3,
            0xff90dbf4,
            0xff8eecf5,
            0xff98f5e1,
            0xffb9fbc0,
          ],
          saturated: <int>[
            0xffffcea4,
            0xffffa6ac,
            0xffff89e9,
            0xffb382ff,
            0xff9678ff,
            0xff6eaaff,
            0xff5cd6ff,
            0xff5bf1ff,
            0xff65ffde,
            0xff8cff98,
          ],
          vivid: <int>[
            0xffff9d45,
            0xffff6674,
            0xfff044c7,
            0xff8a5cff,
            0xff7a52ff,
            0xff3d84f7,
            0xff27c0eb,
            0xff20dde4,
            0xff28ddb4,
            0xff58e66b,
          ],
        ),
        DashboardBalanceHeaderPalette.softRainbowReordered: _variants(
          DashboardBalanceHeaderPalette.softRainbowReordered,
          original: <int>[
            0xffaf99ff,
            0xffcfbaf0,
            0xffa3c4f3,
            0xff90dbf4,
            0xfff1c0e8,
            0xffffcfd2,
            0xffffadc7,
            0xfffbf8cc,
            0xff98f5e1,
            0xffb9fbc0,
          ],
          saturated: <int>[
            0xff9678ff,
            0xffb382ff,
            0xff6eaaff,
            0xff5cd6ff,
            0xffff89e9,
            0xffff9ed6,
            0xffff7fae,
            0xfffff99f,
            0xff65ffde,
            0xff8cff98,
          ],
          vivid: <int>[
            0xff7a52ff,
            0xff8a5cff,
            0xff3d84f7,
            0xff27c0eb,
            0xfff044c7,
            0xffff78cb,
            0xffff4f96,
            0xffffd81a,
            0xff28ddb4,
            0xff58e66b,
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
