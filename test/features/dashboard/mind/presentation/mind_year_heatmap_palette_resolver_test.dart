import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  MindYearHeatmapDay day({
    required double intensity,
    MindYearHeatmapPaletteIntensity paletteIntensity =
        MindYearHeatmapPaletteIntensity.interpolated,
    int? total = 100,
  }) => MindYearHeatmapDay(
    date: const LocalDate(year: 2027, month: 1, day: 1),
    total: total,
    kind: total == null
        ? MindYearHeatmapTileKind.empty
        : MindYearHeatmapTileKind.interpolated,
    intensity: intensity,
    paletteIntensity: paletteIntensity,
  );

  test('HMP-03 B3M-MY3 uses the exact five approved visual levels', () {
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: 0),
      ).background,
      const Color.fromARGB(128, 255, 255, 255),
    );
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: .25),
      ).background,
      const Color.fromARGB(107, 255, 177, 92),
    );
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: .5),
      ).background,
      const Color.fromARGB(148, 255, 107, 107),
    );
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: .75),
      ).background,
      const Color.fromARGB(184, 245, 54, 141),
    );
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: .75),
      ).foreground,
      Colors.white,
    );
    final maximum = MindYearHeatmapPaletteResolver.resolve(
      style: MindYearHeatmapPaletteStyle.b3mMy3,
      day: day(intensity: 1),
    );
    expect(maximum.background, const Color.fromARGB(214, 130, 42, 194));
    expect(maximum.foreground, Colors.white);
  });

  test('HMP-04 B3M maps real non-empty intensity but keeps empty neutral', () {
    final empty = MindYearHeatmapPaletteResolver.resolve(
      style: MindYearHeatmapPaletteStyle.b3mMy3,
      day: day(
        intensity: 0,
        total: null,
        paletteIntensity: MindYearHeatmapPaletteIntensity.empty,
      ),
    );
    final minimum = MindYearHeatmapPaletteResolver.resolve(
      style: MindYearHeatmapPaletteStyle.b3mMy3,
      day: day(
        intensity: 0,
        paletteIntensity: MindYearHeatmapPaletteIntensity.minimum,
      ),
    );

    expect(empty.background, FluviVisualTokens.mindHeatmapEmpty);
    expect(minimum.background, isNot(empty.background));
    expect(minimum.level, 0);
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: -.8),
      ).level,
      0,
    );
    expect(
      MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.b3mMy3,
        day: day(intensity: 1.8),
      ).level,
      4,
    );
  });

  test('HMP-02 Fluvi stays byte-for-byte on its existing semantic palette', () {
    final minimum = MindYearHeatmapPaletteResolver.resolve(
      style: MindYearHeatmapPaletteStyle.fluvi,
      day: day(
        intensity: 0,
        paletteIntensity: MindYearHeatmapPaletteIntensity.minimum,
      ),
    );
    final equalRange = MindYearHeatmapPaletteResolver.resolve(
      style: MindYearHeatmapPaletteStyle.fluvi,
      day: day(
        intensity: .72,
        paletteIntensity: MindYearHeatmapPaletteIntensity.equalRange,
      ),
    );

    expect(minimum.background, FluviVisualTokens.mindHeatmapMinimum);
    expect(equalRange.background, FluviVisualTokens.mindHeatmapEqualRange);
  });

  test('RED LEG-02: legend samples use the active resolver scale only', () {
    final fluvi = MindYearHeatmapPaletteResolver.legendSamples(
      MindYearHeatmapPaletteStyle.fluvi,
    );
    final b3m = MindYearHeatmapPaletteResolver.legendSamples(
      MindYearHeatmapPaletteStyle.b3mMy3,
    );

    expect(fluvi, hasLength(5));
    expect(b3m, hasLength(5));
    expect(b3m.map((sample) => sample.background), const <Color>[
      Color.fromARGB(128, 255, 255, 255),
      Color.fromARGB(107, 255, 177, 92),
      Color.fromARGB(148, 255, 107, 107),
      Color.fromARGB(184, 245, 54, 141),
      Color.fromARGB(214, 130, 42, 194),
    ]);
    expect(fluvi.map((sample) => sample.background), <Color>[
      FluviVisualTokens.mindHeatmapMinimum,
      FluviVisualTokens.mindHeatmapInterpolated(.25),
      FluviVisualTokens.mindHeatmapInterpolated(.5),
      FluviVisualTokens.mindHeatmapInterpolated(.75),
      FluviVisualTokens.mindHeatmapMaximum,
    ]);
  });
}
