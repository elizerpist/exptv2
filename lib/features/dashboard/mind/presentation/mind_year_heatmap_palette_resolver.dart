import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../presentation/core_modes/dashboard_header_perceptual_color.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../time_navigation/domain/local_date.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';

/// One paint-only palette decision over an already prepared heatmap day.
/// Financial membership and intensity remain owned by the immutable frame.
@immutable
final class MindYearHeatmapPaletteSample {
  const MindYearHeatmapPaletteSample({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// Ordered paint stops shared by the dynamic cells, legend and Mind range.
/// It deliberately carries neither score calculation nor heatmap membership.
@immutable
final class MindHeatmapResolvedScale {
  const MindHeatmapResolvedScale(this.stops) : assert(stops.length >= 2);

  final List<Color> stops;

  Color colorAt(double intensity) =>
      MindYearHeatmapPaletteResolver.interpolateStops(stops, intensity);
}

/// Central resolver shared by MonthCard paint and tests. It deliberately maps
/// the already-real Fluvi intensity; the B3M HTML's decorative fixture never
/// enters this financial presentation path.
abstract final class MindYearHeatmapPaletteResolver {
  static MindYearHeatmapPaletteSample resolve({
    required MindYearHeatmapPaletteStyle style,
    required MindYearHeatmapDay day,
    MindHeatmapScaleResolution scaleResolution = MindHeatmapScaleResolution.ten,
    MindHeatmapResolvedScale? dynamicScale,
  }) => resolveTile(
    style: style,
    isEmpty: day.isEmpty,
    intensity: day.intensity,
    paletteIntensity: day.paletteIntensity,
    scaleResolution: scaleResolution,
    dynamicScale: dynamicScale,
  );

  /// Shared token resolution for Year day cells, Month day cells and Sum
  /// month cells. The caller supplies already-normalized financial semantics;
  /// this resolver has no membership or aggregation authority.
  static MindYearHeatmapPaletteSample resolveTile({
    required MindYearHeatmapPaletteStyle style,
    required bool isEmpty,
    required double intensity,
    required MindYearHeatmapPaletteIntensity paletteIntensity,
    MindHeatmapScaleResolution scaleResolution = MindHeatmapScaleResolution.ten,
    MindHeatmapResolvedScale? dynamicScale,
  }) => _authored(
    isEmpty: isEmpty,
    intensity: intensity,
    stops: dynamicScale?.stops ?? _authoredStopsFor(style, scaleResolution),
  );

  /// Ordered, non-empty authored scale positions for every Mind surface. The
  /// legend intentionally delegates to this resolver rather than owning
  /// another palette; empty and equal-range are tile states, not scale stops.
  static List<MindYearHeatmapPaletteSample> legendSamples(
    MindYearHeatmapPaletteStyle style, {
    MindHeatmapScaleResolution scaleResolution = MindHeatmapScaleResolution.ten,
    MindHeatmapResolvedScale? dynamicScale,
  }) => List<MindYearHeatmapPaletteSample>.unmodifiable(
    List<MindYearHeatmapPaletteSample>.generate(
      dynamicScale?.stops.length ?? scaleResolution.authoredStopCount,
      (index) => resolve(
        style: style,
        day: _legendDay(
          index /
              ((dynamicScale?.stops.length ??
                      scaleResolution.authoredStopCount) -
                  1),
        ),
        scaleResolution: scaleResolution,
        dynamicScale: dynamicScale,
      ),
      growable: false,
    ),
  );

  static MindYearHeatmapDay _legendDay(double intensity) {
    final paletteIntensity = intensity <= 0
        ? MindYearHeatmapPaletteIntensity.minimum
        : intensity >= 1
        ? MindYearHeatmapPaletteIntensity.maximum
        : MindYearHeatmapPaletteIntensity.interpolated;
    return MindYearHeatmapDay(
      date: const LocalDate(year: 2000, month: 1, day: 1),
      total: 1,
      kind: switch (paletteIntensity) {
        MindYearHeatmapPaletteIntensity.minimum =>
          MindYearHeatmapTileKind.minimum,
        MindYearHeatmapPaletteIntensity.maximum =>
          MindYearHeatmapTileKind.maximum,
        _ => MindYearHeatmapTileKind.interpolated,
      },
      intensity: intensity,
      paletteIntensity: paletteIntensity,
    );
  }

  static MindYearHeatmapPaletteSample _authored({
    required bool isEmpty,
    required double intensity,
    required List<Color> stops,
  }) {
    if (isEmpty) {
      return const MindYearHeatmapPaletteSample(
        background: FluviVisualTokens.mindHeatmapEmpty,
        foreground: FluviVisualTokens.textSecondary,
      );
    }
    final background = interpolateStops(stops, intensity);
    return MindYearHeatmapPaletteSample(
      background: background,
      foreground: _foregroundFor(background),
    );
  }

  static Color interpolateStops(List<Color> stops, double intensity) {
    final bounded = intensity.clamp(0.0, 1.0).toDouble();
    final scaled = bounded * (stops.length - 1);
    final lowerIndex = scaled.floor();
    final upperIndex = math.min(lowerIndex + 1, stops.length - 1);
    if (lowerIndex == upperIndex) return stops[lowerIndex];
    return Color.lerp(
      stops[lowerIndex],
      stops[upperIndex],
      scaled - lowerIndex,
    )!;
  }

  /// Exact score-anchored 10-stop palette morph. Matching indices interpolate
  /// only with matching indices, preserving low/high heatmap intensity roles.
  static MindHeatmapResolvedScale resolveDynamicMixedScale(double score) {
    const anchors = <double>[18, 35, 58, 70, 82];
    const palettes = <List<Color>>[
      _dynamicRed,
      _dynamicRedB3mBridge,
      _b3mMy3,
      _dynamicB3mMeadowBridge,
      _meadowGreen,
    ];
    if (score <= anchors.first) {
      return MindHeatmapResolvedScale(_dynamicRed);
    }
    if (score >= anchors.last) {
      return MindHeatmapResolvedScale(_meadowGreen);
    }
    for (var index = 0; index < anchors.length - 1; index += 1) {
      final lower = anchors[index];
      final upper = anchors[index + 1];
      if (score <= upper) {
        if (score == lower) return MindHeatmapResolvedScale(palettes[index]);
        if (score == upper) {
          return MindHeatmapResolvedScale(palettes[index + 1]);
        }
        final t = ((score - lower) / (upper - lower)).clamp(0.0, 1.0);
        return MindHeatmapResolvedScale(
          List<Color>.unmodifiable(
            List<Color>.generate(
              10,
              (stop) => DashboardHeaderPerceptualColorMath.mix(
                palettes[index][stop],
                palettes[index + 1][stop],
                t,
              ),
              growable: false,
            ),
          ),
        );
      }
    }
    return MindHeatmapResolvedScale(_meadowGreen);
  }

  static MindHeatmapResolvedScale resolveScale({
    required MindYearHeatmapPaletteStyle style,
    required MindHeatmapScaleResolution scaleResolution,
    required MindHeatmapScaleMode scaleMode,
    required double score,
  }) => scaleMode == MindHeatmapScaleMode.dynamicMixed
      ? resolveDynamicMixedScale(score)
      : MindHeatmapResolvedScale(_authoredStopsFor(style, scaleResolution));

  static Color _foregroundFor(Color background) =>
      background.computeLuminance() > .36
      ? FluviVisualTokens.textSecondary
      : Colors.white;

  static List<Color> _authoredStopsFor(
    MindYearHeatmapPaletteStyle style,
    MindHeatmapScaleResolution scaleResolution,
  ) => switch ((style, scaleResolution)) {
    (MindYearHeatmapPaletteStyle.fluvi, MindHeatmapScaleResolution.ten) =>
      _fluvi,
    (MindYearHeatmapPaletteStyle.fluvi, MindHeatmapScaleResolution.twenty) =>
      _fluviTwenty,
    (MindYearHeatmapPaletteStyle.b3mMy3, MindHeatmapScaleResolution.ten) =>
      _b3mMy3,
    (MindYearHeatmapPaletteStyle.b3mMy3, MindHeatmapScaleResolution.twenty) =>
      _b3mMy3Twenty,
    (MindYearHeatmapPaletteStyle.meadowGreen, MindHeatmapScaleResolution.ten) =>
      _meadowGreen,
    (
      MindYearHeatmapPaletteStyle.meadowGreen,
      MindHeatmapScaleResolution.twenty,
    ) =>
      _meadowGreenTwenty,
    (
      MindYearHeatmapPaletteStyle.fluviStretched,
      MindHeatmapScaleResolution.ten,
    ) =>
      _fluviStretched,
    (
      MindYearHeatmapPaletteStyle.fluviStretched,
      MindHeatmapScaleResolution.twenty,
    ) =>
      _fluviStretchedTwenty,
    (
      MindYearHeatmapPaletteStyle.b3mMy3Stretched,
      MindHeatmapScaleResolution.ten,
    ) =>
      _b3mMy3Stretched,
    (
      MindYearHeatmapPaletteStyle.b3mMy3Stretched,
      MindHeatmapScaleResolution.twenty,
    ) =>
      _b3mMy3StretchedTwenty,
  };

  static const List<Color> _fluvi = <Color>[
    Color(0xffedf7f6),
    Color(0xffd6f1ef),
    Color(0xffb7e9ea),
    Color(0xff8fdadf),
    Color(0xff67c7dd),
    Color(0xff56b0e1),
    Color(0xff668fe3),
    Color(0xff816fe1),
    Color(0xffa05fdd),
    Color(0xffc05cd7),
  ];
  static const List<Color> _dynamicRed = <Color>[
    Color(0xffffe7d6),
    Color(0xffffd0b3),
    Color(0xffffb28f),
    Color(0xffff916e),
    Color(0xffff6f58),
    Color(0xfff55449),
    Color(0xffe63a3d),
    Color(0xffc72b3c),
    Color(0xffa5223c),
    Color(0xff7e1f39),
  ];
  static const List<Color> _dynamicRedB3mBridge = <Color>[
    Color(0xfffff0e4),
    Color(0xffffe0c8),
    Color(0xfffec7a6),
    Color(0xfffda77f),
    Color(0xfff7866c),
    Color(0xfff26862),
    Color(0xffe95276),
    Color(0xffd33f8d),
    Color(0xffb433a0),
    Color(0xff9227a8),
  ];
  static const List<Color> _dynamicB3mMeadowBridge = <Color>[
    Color(0xffeef1d2),
    Color(0xffd9e493),
    Color(0xffbed77a),
    Color(0xff9cc870),
    Color(0xff78b978),
    Color(0xff55a982),
    Color(0xff39998a),
    Color(0xff278790),
    Color(0xff206f86),
    Color(0xff195a75),
  ];
  static const List<Color> _b3mMy3 = <Color>[
    Color(0xfff4f7fb),
    Color(0xffffeeda),
    Color(0xffffd5af),
    Color(0xffffb15c),
    Color(0xffff8d64),
    Color(0xffff6b6b),
    Color(0xfff536bd),
    Color(0xffd03cb0),
    Color(0xffa237bf),
    Color(0xff821ac2),
  ];
  static const List<Color> _meadowGreen = <Color>[
    Color(0xffd9ed92),
    Color(0xffb5e48c),
    Color(0xff99d98c),
    Color(0xff76c893),
    Color(0xff52b69a),
    Color(0xff34a0a4),
    Color(0xff168aad),
    Color(0xff1a759f),
    Color(0xff1e6091),
    Color(0xff184e77),
  ];
  static const List<Color> _fluviStretched = <Color>[
    Color(0xffe9e0fc),
    Color(0xffdcccfd),
    Color(0xffcab0fb),
    Color(0xffbfa1fa),
    Color(0xffb18ef8),
    Color(0xff9570ed),
    Color(0xff8b65e5),
    Color(0xff7657c5),
    Color(0xff684eb1),
    Color(0xff493590),
  ];
  static const List<Color> _b3mMy3Stretched = <Color>[
    Color(0xfffcf0e4),
    Color(0xfffed2a6),
    Color(0xfffcb476),
    Color(0xfff5956a),
    Color(0xfff97184),
    Color(0xfff96b8b),
    Color(0xffee46a1),
    Color(0xffbf3cb6),
    Color(0xff843bc3),
    Color(0xff47188c),
  ];

  static const List<Color> _fluviTwenty = <Color>[
    Color(0xffedf7f6),
    Color(0xffe2f4f3),
    Color(0xffd7f1ef),
    Color(0xffc9eeed),
    Color(0xffbaeaeb),
    Color(0xffa8e3e6),
    Color(0xff95dce1),
    Color(0xff82d4de),
    Color(0xff6fcbdd),
    Color(0xff63c1de),
    Color(0xff5ab6e0),
    Color(0xff59a9e1),
    Color(0xff6199e2),
    Color(0xff6a8ae3),
    Color(0xff777be2),
    Color(0xff846de1),
    Color(0xff9366df),
    Color(0xffa25fdd),
    Color(0xffb15dda),
    Color(0xffc05cd7),
  ];
  static const List<Color> _b3mMy3Twenty = <Color>[
    Color(0xfff4f7fb),
    Color(0xfff9f3eb),
    Color(0xfffeeedc),
    Color(0xffffe3c8),
    Color(0xffffd8b4),
    Color(0xffffc890),
    Color(0xffffb769),
    Color(0xffffa65f),
    Color(0xffff9562),
    Color(0xffff8466),
    Color(0xffff7469),
    Color(0xfffd607c),
    Color(0xfff847a3),
    Color(0xffef37bb),
    Color(0xffde3ab5),
    Color(0xffcb3bb2),
    Color(0xffb539b9),
    Color(0xffa035bf),
    Color(0xff9128c1),
    Color(0xff821ac2),
  ];
  static const List<Color> _meadowGreenTwenty = <Color>[
    Color(0xffd9ed92),
    Color(0xffc8e98f),
    Color(0xffb7e48c),
    Color(0xffa9df8c),
    Color(0xff9cda8c),
    Color(0xff8cd38f),
    Color(0xff7ccb92),
    Color(0xff6bc295),
    Color(0xff5aba99),
    Color(0xff4ab09d),
    Color(0xff3ca6a1),
    Color(0xff2e9ba6),
    Color(0xff1f91aa),
    Color(0xff1787ab),
    Color(0xff197da4),
    Color(0xff1a739e),
    Color(0xff1c6997),
    Color(0xff1e5f90),
    Color(0xff1b5783),
    Color(0xff184e77),
  ];
  static const List<Color> _fluviStretchedTwenty = <Color>[
    Color(0xffe9e0fc),
    Color(0xffe3d7fc),
    Color(0xffddcdfd),
    Color(0xffd4c0fc),
    Color(0xffccb3fb),
    Color(0xffc6aafb),
    Color(0xffc1a3fa),
    Color(0xffbb9bf9),
    Color(0xffb492f8),
    Color(0xffaa86f5),
    Color(0xff9c78f0),
    Color(0xff936eeb),
    Color(0xff8e68e8),
    Color(0xff8863e0),
    Color(0xff7e5cd1),
    Color(0xff7556c3),
    Color(0xff6e52b9),
    Color(0xff664daf),
    Color(0xff5841a0),
    Color(0xff493590),
  ];
  static const List<Color> _b3mMy3StretchedTwenty = <Color>[
    Color(0xfffcf0e4),
    Color(0xfffde2c7),
    Color(0xfffed4a9),
    Color(0xfffdc592),
    Color(0xfffcb77b),
    Color(0xfff9a972),
    Color(0xfff69a6c),
    Color(0xfff68a72),
    Color(0xfff8797f),
    Color(0xfff96f86),
    Color(0xfff96d89),
    Color(0xfff76390),
    Color(0xfff1529a),
    Color(0xffe744a4),
    Color(0xffd040ae),
    Color(0xffb93cb7),
    Color(0xff9d3bbe),
    Color(0xff8139c0),
    Color(0xff6429a6),
    Color(0xff47188c),
  ];
}
