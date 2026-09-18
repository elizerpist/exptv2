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
    this.level,
  });

  final Color background;
  final Color foreground;

  /// B3M visual level when applicable. `null` means the preserved Fluvi
  /// semantic palette or the separate empty-day treatment.
  final int? level;
}

/// Central resolver shared by MonthCard paint and tests. It deliberately maps
/// the already-real Fluvi intensity; the B3M HTML's decorative fixture never
/// enters this financial presentation path.
abstract final class MindYearHeatmapPaletteResolver {
  static const Color _b3mLevel0 = Color.fromARGB(128, 255, 255, 255);
  static const Color _b3mLevel1 = Color.fromARGB(107, 255, 177, 92);
  static const Color _b3mLevel2 = Color.fromARGB(148, 255, 107, 107);
  static const Color _b3mLevel3 = Color.fromARGB(184, 245, 54, 141);
  static const Color _b3mLevel4 = Color.fromARGB(214, 130, 42, 194);

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
  }) => switch (style) {
    MindYearHeatmapPaletteStyle.fluvi => _fluvi(
      isEmpty: isEmpty,
      intensity: intensity,
      paletteIntensity: paletteIntensity,
    ),
    MindYearHeatmapPaletteStyle.b3mMy3 => _b3m(
      isEmpty: isEmpty,
      intensity: intensity,
    ),
    _ => _authored(
      isEmpty: isEmpty,
      intensity: intensity,
      stops: _authoredStopsFor(style),
    ),
  };

  /// Five ordered, non-empty scale positions for every Mind heatmap surface.
  /// The legend intentionally delegates to this resolver rather than owning
  /// another palette; empty and equal-range are tile states, not scale stops.
  static List<MindYearHeatmapPaletteSample> legendSamples(
    MindYearHeatmapPaletteStyle style,
  ) => List<MindYearHeatmapPaletteSample>.unmodifiable(
    List<MindYearHeatmapPaletteSample>.generate(
      5,
      (index) => resolve(style: style, day: _legendDay(index / 4)),
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

  static MindYearHeatmapPaletteSample _fluvi({
    required bool isEmpty,
    required double intensity,
    required MindYearHeatmapPaletteIntensity paletteIntensity,
  }) => MindYearHeatmapPaletteSample(
    background: switch (paletteIntensity) {
      MindYearHeatmapPaletteIntensity.empty =>
        FluviVisualTokens.mindHeatmapEmpty,
      MindYearHeatmapPaletteIntensity.minimum =>
        FluviVisualTokens.mindHeatmapMinimum,
      MindYearHeatmapPaletteIntensity.interpolated =>
        FluviVisualTokens.mindHeatmapInterpolated(intensity),
      MindYearHeatmapPaletteIntensity.maximum =>
        FluviVisualTokens.mindHeatmapMaximum,
      MindYearHeatmapPaletteIntensity.equalRange =>
        FluviVisualTokens.mindHeatmapEqualRange,
    },
    foreground: FluviVisualTokens.textSecondary,
  );

  static MindYearHeatmapPaletteSample _b3m({
    required bool isEmpty,
    required double intensity,
  }) {
    if (isEmpty) {
      return const MindYearHeatmapPaletteSample(
        background: FluviVisualTokens.mindHeatmapEmpty,
        foreground: FluviVisualTokens.textSecondary,
      );
    }
    final level = (intensity.clamp(0.0, 1.0) * 4).round();
    final background = switch (level) {
      0 => _b3mLevel0,
      1 => _b3mLevel1,
      2 => _b3mLevel2,
      3 => _b3mLevel3,
      _ => _b3mLevel4,
    };
    return MindYearHeatmapPaletteSample(
      background: background,
      foreground: level >= 3 ? Colors.white : const Color(0xA314213A),
      level: level,
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
        MindYearHeatmapPaletteStyle.oceanSunset => _oceanSunset,
        MindYearHeatmapPaletteStyle.boldBerry => _boldBerry,
        MindYearHeatmapPaletteStyle.meadowGreen => _meadowGreen,
        MindYearHeatmapPaletteStyle.peachyDelight => _peachyDelight,
        MindYearHeatmapPaletteStyle.softRainbow => _softRainbow,
        MindYearHeatmapPaletteStyle.cherryBlossom => _cherryBlossom,
        MindYearHeatmapPaletteStyle.softPastels => _softPastels,
        MindYearHeatmapPaletteStyle.customColour => _customColour,
        MindYearHeatmapPaletteStyle.fluvi ||
        MindYearHeatmapPaletteStyle.b3mMy3 => throw ArgumentError.value(
          style,
          'style',
          'Not an authored palette',
        ),
      };

  static const List<Color> _oceanSunset = <Color>[
    Color(0xff001219),
    Color(0xff005f73),
    Color(0xff0a9396),
    Color(0xff94d2bd),
    Color(0xffe9d8a6),
    Color(0xffee9b00),
    Color(0xffca6702),
    Color(0xffbb3e03),
    Color(0xffae2012),
    Color(0xff9b2226),
  ];
  static const List<Color> _boldBerry = <Color>[
    Color(0xfff9dbbd),
    Color(0xffffa5ab),
    Color(0xffda627d),
    Color(0xffa53860),
    Color(0xff450920),
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
  static const List<Color> _peachyDelight = <Color>[
    Color(0xffd8e2dc),
    Color(0xffffe5d9),
    Color(0xffffcad4),
    Color(0xfff4acb7),
    Color(0xff9d8189),
  ];
  static const List<Color> _softRainbow = <Color>[
    Color(0xfffbf8cc),
    Color(0xfffde4cf),
    Color(0xffffcfd2),
    Color(0xfff1c0e8),
    Color(0xffcfbaf0),
    Color(0xffa3c4f3),
    Color(0xff90dbf4),
    Color(0xff8eecf5),
    Color(0xff98f5e1),
    Color(0xffb9fbc0),
  ];
  static const List<Color> _cherryBlossom = <Color>[
    Color(0xffebd4cb),
    Color(0xffda9f93),
    Color(0xffb6465f),
    Color(0xff890620),
    Color(0xff2c0703),
  ];
  static const List<Color> _softPastels = <Color>[
    Color(0xfffaf3dd),
    Color(0xffc8d5b9),
    Color(0xff8fc0a9),
    Color(0xff68b0ab),
    Color(0xff4a7c59),
  ];
  static const List<Color> _customColour = <Color>[
    Color(0xffce84ad),
    Color(0xffce96a6),
    Color(0xffd1a7a0),
    Color(0xffd4cbb3),
    Color(0xffd2e0bf),
  ];
}
