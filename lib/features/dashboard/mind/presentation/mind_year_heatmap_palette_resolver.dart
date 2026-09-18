import 'dart:math' as math;

import 'package:flutter/material.dart';

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

/// Central resolver shared by MonthCard paint and tests. It deliberately maps
/// the already-real Fluvi intensity; the B3M HTML's decorative fixture never
/// enters this financial presentation path.
abstract final class MindYearHeatmapPaletteResolver {
  static MindYearHeatmapPaletteSample resolve({
    required MindYearHeatmapPaletteStyle style,
    required MindYearHeatmapDay day,
  }) => resolveTile(
    style: style,
    isEmpty: day.isEmpty,
    intensity: day.intensity,
    paletteIntensity: day.paletteIntensity,
  );

  /// Shared token resolution for Year day cells, Month day cells and Sum
  /// month cells. The caller supplies already-normalized financial semantics;
  /// this resolver has no membership or aggregation authority.
  static MindYearHeatmapPaletteSample resolveTile({
    required MindYearHeatmapPaletteStyle style,
    required bool isEmpty,
    required double intensity,
    required MindYearHeatmapPaletteIntensity paletteIntensity,
  }) => _authored(
    isEmpty: isEmpty,
    intensity: intensity,
    stops: _authoredStopsFor(style),
  );

  /// Ten ordered, non-empty authored scale positions for every Mind surface.
  /// The legend intentionally delegates to this resolver rather than owning
  /// another palette; empty and equal-range are tile states, not scale stops.
  static List<MindYearHeatmapPaletteSample> legendSamples(
    MindYearHeatmapPaletteStyle style,
  ) => List<MindYearHeatmapPaletteSample>.unmodifiable(
    List<MindYearHeatmapPaletteSample>.generate(
      10,
      (index) => resolve(style: style, day: _legendDay(index / 9)),
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
    final background = _interpolateAuthoredStops(stops, intensity);
    return MindYearHeatmapPaletteSample(
      background: background,
      foreground: _foregroundFor(background),
    );
  }

  static Color _interpolateAuthoredStops(List<Color> stops, double intensity) {
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

  static Color _foregroundFor(Color background) =>
      background.computeLuminance() > .36
      ? FluviVisualTokens.textSecondary
      : Colors.white;

  static List<Color> _authoredStopsFor(MindYearHeatmapPaletteStyle style) =>
      switch (style) {
        MindYearHeatmapPaletteStyle.fluvi => _fluvi,
        MindYearHeatmapPaletteStyle.b3mMy3 => _b3mMy3,
        MindYearHeatmapPaletteStyle.meadowGreen => _meadowGreen,
        MindYearHeatmapPaletteStyle.fluviStretched => _fluviStretched,
        MindYearHeatmapPaletteStyle.b3mMy3Stretched => _b3mMy3Stretched,
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
}
