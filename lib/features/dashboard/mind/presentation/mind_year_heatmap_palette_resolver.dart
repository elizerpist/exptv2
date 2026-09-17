import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
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
  }) => switch (style) {
    MindYearHeatmapPaletteStyle.fluvi => _fluvi(day),
    MindYearHeatmapPaletteStyle.b3mMy3 => _b3m(day),
  };

  static MindYearHeatmapPaletteSample _fluvi(MindYearHeatmapDay day) =>
      MindYearHeatmapPaletteSample(
        background: switch (day.paletteIntensity) {
          MindYearHeatmapPaletteIntensity.empty =>
            FluviVisualTokens.mindHeatmapEmpty,
          MindYearHeatmapPaletteIntensity.minimum =>
            FluviVisualTokens.mindHeatmapMinimum,
          MindYearHeatmapPaletteIntensity.interpolated =>
            FluviVisualTokens.mindHeatmapInterpolated(day.intensity),
          MindYearHeatmapPaletteIntensity.maximum =>
            FluviVisualTokens.mindHeatmapMaximum,
          MindYearHeatmapPaletteIntensity.equalRange =>
            FluviVisualTokens.mindHeatmapEqualRange,
        },
        foreground: FluviVisualTokens.textSecondary,
      );

  static MindYearHeatmapPaletteSample _b3m(MindYearHeatmapDay day) {
    if (day.isEmpty) {
      return const MindYearHeatmapPaletteSample(
        background: FluviVisualTokens.mindHeatmapEmpty,
        foreground: FluviVisualTokens.textSecondary,
      );
    }
    final level = (day.intensity.clamp(0.0, 1.0) * 4).round();
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
