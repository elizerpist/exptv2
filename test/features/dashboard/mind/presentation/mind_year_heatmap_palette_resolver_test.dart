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
    'SCALE-02: default ten mode remains byte-compatible at anchors and off-anchor interpolation',
    () {
      for (final entry in expected.entries) {
        final stops = entry.value;
        for (var index = 0; index < stops.length - 1; index += 1) {
          const localT = .37;
          final intensity = (index + localT) / (stops.length - 1);
          final scaled = intensity * (stops.length - 1);
          expect(
            MindYearHeatmapPaletteResolver.resolve(
              style: entry.key,
              day: day(intensity),
            ).background,
            Color.lerp(stops[index], stops[index + 1], scaled - index),
            reason: '${entry.key.name} default ten interval $index',
          );
        }
        expect(
          MindYearHeatmapPaletteResolver.legendSamples(entry.key),
          hasLength(10),
        );
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

  const expectedTwenty = <MindYearHeatmapPaletteStyle, List<Color>>{
    MindYearHeatmapPaletteStyle.fluvi: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.b3mMy3: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.meadowGreen: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.fluviStretched: <Color>[
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
    ],
    MindYearHeatmapPaletteStyle.b3mMy3Stretched: <Color>[
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
    ],
  };

  test('SCALE-03 RED: every palette has the exact twenty authored anchors', () {
    for (final entry in expectedTwenty.entries) {
      expect(entry.value, hasLength(20), reason: entry.key.name);
      for (var index = 0; index < entry.value.length; index += 1) {
        expect(
          MindYearHeatmapPaletteResolver.resolve(
            style: entry.key,
            day: day(index / 19),
            scaleResolution: MindHeatmapScaleResolution.twenty,
          ).background,
          entry.value[index],
          reason: '${entry.key.name} twenty stop $index',
        );
      }
      expect(
        MindYearHeatmapPaletteResolver.legendSamples(
          entry.key,
          scaleResolution: MindHeatmapScaleResolution.twenty,
        ).map((sample) => sample.background),
        entry.value,
      );
    }
  });

  test(
    'SCALE-04/06: twenty is a distinct central tile curve and its legend has twenty samples',
    () {
      for (final style in MindYearHeatmapPaletteStyle.values) {
        const intensity = .41;
        final ten = MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(intensity),
        );
        final twenty = MindYearHeatmapPaletteResolver.resolve(
          style: style,
          day: day(intensity),
          scaleResolution: MindHeatmapScaleResolution.twenty,
        );
        expect(
          twenty.background,
          isNot(ten.background),
          reason: '$style must not be a twenty-swatch-only presentation',
        );
        expect(
          MindYearHeatmapPaletteResolver.legendSamples(
            style,
            scaleResolution: MindHeatmapScaleResolution.twenty,
          ),
          hasLength(20),
        );
      }
    },
  );
}
