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

  test(
    'RED HMP-PRESET-01: ordered fixed presets retain every authored stop',
    () {
      final expected = <String, List<Color>>{
        'oceanSunset': const <Color>[
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
        ],
        'boldBerry': const <Color>[
          Color(0xfff9dbbd),
          Color(0xffffa5ab),
          Color(0xffda627d),
          Color(0xffa53860),
          Color(0xff450920),
        ],
        'meadowGreen': const <Color>[
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
        'peachyDelight': const <Color>[
          Color(0xffd8e2dc),
          Color(0xffffe5d9),
          Color(0xffffcad4),
          Color(0xfff4acb7),
          Color(0xff9d8189),
        ],
        'softRainbow': const <Color>[
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
        ],
        'cherryBlossom': const <Color>[
          Color(0xffebd4cb),
          Color(0xffda9f93),
          Color(0xffb6465f),
          Color(0xff890620),
          Color(0xff2c0703),
        ],
        'softPastels': const <Color>[
          Color(0xfffaf3dd),
          Color(0xffc8d5b9),
          Color(0xff8fc0a9),
          Color(0xff68b0ab),
          Color(0xff4a7c59),
        ],
        'customColour': const <Color>[
          Color(0xffce84ad),
          Color(0xffce96a6),
          Color(0xffd1a7a0),
          Color(0xffd4cbb3),
          Color(0xffd2e0bf),
        ],
      };

      for (final entry in expected.entries) {
        final style = MindYearHeatmapPaletteStyle.values.singleWhere(
          (candidate) => candidate.name == entry.key,
        );
        for (var index = 0; index < entry.value.length; index += 1) {
          final intensity = index / (entry.value.length - 1);
          expect(
            MindYearHeatmapPaletteResolver.resolve(
              style: style,
              day: day(intensity: intensity),
            ).background,
            entry.value[index],
            reason: '${entry.key} stop $index must remain exact.',
          );
        }
        expect(
          MindYearHeatmapPaletteResolver.resolve(
            style: style,
            day: day(intensity: -1),
          ).background,
          entry.value.first,
        );
        expect(
          MindYearHeatmapPaletteResolver.resolve(
            style: style,
            day: day(intensity: 2),
          ).background,
          entry.value.last,
        );
      }
    },
  );

  test(
    'HMP-PRESET-02: authored palettes interpolate adjacent stops and keep a bounded resolver legend',
    () {
      final midpoint = MindYearHeatmapPaletteResolver.resolve(
        style: MindYearHeatmapPaletteStyle.oceanSunset,
        day: day(intensity: .5 / 9),
      );
      expect(
        midpoint.background,
        Color.lerp(const Color(0xff001219), const Color(0xff005f73), .5),
      );
      expect(midpoint.foreground, Colors.white);

      for (final style in MindYearHeatmapPaletteStyle.values) {
        final samples = MindYearHeatmapPaletteResolver.legendSamples(style);
        expect(samples, hasLength(5));
        for (var index = 0; index < samples.length; index += 1) {
          expect(
            samples[index].background,
            MindYearHeatmapPaletteResolver.resolve(
              style: style,
              day: day(intensity: index / 4),
            ).background,
          );
        }
      }
    },
  );
}
