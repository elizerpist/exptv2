import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  MindYearHeatmapDay day(double intensity, {bool empty = false}) =>
      MindYearHeatmapDay(
        date: const LocalDate(year: 2027, month: 1, day: 1),
        total: empty ? null : 100,
        kind: empty
            ? MindYearHeatmapTileKind.empty
            : MindYearHeatmapTileKind.interpolated,
        intensity: intensity,
        paletteIntensity: empty
            ? MindYearHeatmapPaletteIntensity.empty
            : MindYearHeatmapPaletteIntensity.interpolated,
      );

  const expected = <MindYearHeatmapPaletteStyle, List<Color>>{
    MindYearHeatmapPaletteStyle.fluvi: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.b3mMy3: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.meadowGreen: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.fluviStretched: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.b3mMy3Stretched: <Color>[
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
    ],
  };

  test(
    'PAL-REDUCE-03: exactly five product scales expose ten authored anchors',
    () {
      expect(MindYearHeatmapPaletteStyle.values, hasLength(5));
      expect(expected, hasLength(5));
      for (final entry in expected.entries) {
        expect(entry.value, hasLength(10), reason: entry.key.name);
        for (var index = 0; index < 10; index += 1) {
          expect(
            MindYearHeatmapPaletteResolver.resolve(
              style: entry.key,
              day: day(index / 9),
            ).background,
            entry.value[index],
            reason: '${entry.key.name} stop $index',
          );
        }
      }
    },
  );

  test(
    'PAL-REDUCE-04: ten resolver samples form the bounded active legend',
    () {
      for (final entry in expected.entries) {
        final legend = MindYearHeatmapPaletteResolver.legendSamples(entry.key);
        expect(legend, hasLength(10));
        expect(legend.map((sample) => sample.background), entry.value);
      }
    },
  );

  test(
    'RED PAL-04: interpolation is adjacent, clamped and empty stays neutral',
    () {
      final style = MindYearHeatmapPaletteStyle.meadowGreen;
      final stops = expected[style]!;
      expect(
        MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(.5 / 9),
        ).background,
        Color.lerp(stops[0], stops[1], .5),
      );
      expect(
        MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(-1),
        ).background,
        stops.first,
      );
      expect(
        MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(2),
        ).background,
        stops.last,
      );
      expect(
        MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(0, empty: true),
        ).background,
        FluviVisualTokens.mindHeatmapEmpty,
      );
    },
  );
}
