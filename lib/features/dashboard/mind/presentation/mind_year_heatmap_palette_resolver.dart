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
}
