import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_catalog_ids.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_budget_palette.dart';

const _paletteV2ArgbFixture = <String, List<int>>{
  'color_01': <int>[
    0xffffffff,
    0xfffff2f8,
    0xffffc9e2,
    0xffffaed6,
    0xffffc4de,
    0xffff7a86,
    0xffff5268,
    0xffd60025,
    0xff992700,
    0xff6e1e00,
  ],
  'color_02': <int>[
    0xffffffff,
    0xfffff2f2,
    0xffffcccc,
    0xffce5d65,
    0xffe85e67,
    0xffff9171,
    0xffff7043,
    0xffc35600,
    0xff894e00,
    0xff653a00,
  ],
  'color_03': <int>[
    0xffffffff,
    0xfffff3ef,
    0xffffcebe,
    0xffc6684a,
    0xfff58259,
    0xffffbb79,
    0xffffa12b,
    0xffc58000,
    0xff956b00,
    0xff745400,
  ],
  'color_04': <int>[
    0xffffffff,
    0xfffff4e9,
    0xffffd1a3,
    0xffb87521,
    0xfff6a23c,
    0xffffd992,
    0xffffc233,
    0xffc69f00,
    0xff958700,
    0xff756e00,
  ],
  'color_05': <int>[
    0xffffffff,
    0xfffef5e2,
    0xfff8d692,
    0xffaa7e00,
    0xffe6ae00,
    0xfffff051,
    0xfff7ea45,
    0xffbfc400,
    0xff89ab00,
    0xff6d8e00,
  ],
  'color_06': <int>[
    0xffffffff,
    0xfff9f7e0,
    0xffe4e086,
    0xff928a00,
    0xffc6bd00,
    0xffcafc3c,
    0xffb7ea2a,
    0xff79c300,
    0xff00aa11,
    0xff008a24,
  ],
  'color_07': <int>[
    0xffffffff,
    0xfff2f9e5,
    0xffcbe79f,
    0xff739420,
    0xff87b421,
    0xff6fe472,
    0xff5bd265,
    0xff00a850,
    0xff008454,
    0xff006643,
  ],
  'color_08': <int>[
    0xffffffff,
    0xffecfaec,
    0xffb7eab9,
    0xff519956,
    0xff53af5e,
    0xff3fdb98,
    0xff24c889,
    0xff009a74,
    0xff007766,
    0xff005a4f,
  ],
  'color_09': <int>[
    0xffffffff,
    0xffecfaec,
    0xffb9eabb,
    0xff99df9c,
    0xff98f0a0,
    0xff33cb8f,
    0xff12b980,
    0xff008b6a,
    0xff00695a,
    0xff004d43,
  ],
  'color_10': <int>[
    0xffffffff,
    0xffe8fbf1,
    0xffb2eace,
    0xff459974,
    0xff3eaa7f,
    0xff36d2ba,
    0xff19c0aa,
    0xff00928d,
    0xff006f7b,
    0xff00535e,
  ],
  'color_11': <int>[
    0xffffffff,
    0xffe5fbf7,
    0xffa9eae1,
    0xff30998d,
    0xff10a89d,
    0xff33c9e4,
    0xff1bb7d2,
    0xff008aad,
    0xff006699,
    0xff004b77,
  ],
  'color_12': <int>[
    0xffffffff,
    0xffe4fbfb,
    0xffa0eaeb,
    0xff00999a,
    0xff00b6ba,
    0xff58d5ff,
    0xff2bc4f3,
    0xff0096cd,
    0xff0071b9,
    0xff005695,
  ],
  'color_13': <int>[
    0xffffffff,
    0xffeaf9ff,
    0xffa8e5ff,
    0xff77d9ff,
    0xffa1e3ff,
    0xff58afff,
    0xff3b9df5,
    0xff1b6fd2,
    0xff2648b7,
    0xff192c95,
  ],
  'color_14': <int>[
    0xffffffff,
    0xffeff7ff,
    0xffc0deff,
    0xff88c3ff,
    0xffa8d2ff,
    0xff557fff,
    0xff496deb,
    0xff3f38c5,
    0xff410097,
    0xff2a0061,
  ],
  'color_15': <int>[
    0xffffffff,
    0xffeff7ff,
    0xffc0deff,
    0xff6cb5ff,
    0xff90c4ff,
    0xff6567f5,
    0xff5a55df,
    0xff4519b8,
    0xff36007d,
    0xff1f004b,
  ],
  'color_16': <int>[
    0xffffffff,
    0xfff3f5ff,
    0xffd3d8ff,
    0xff9ea6ff,
    0xffb2b8ff,
    0xff8458f2,
    0xff7546dc,
    0xff5c00ac,
    0xff44006a,
    0xff28003e,
  ],
  'color_17': <int>[
    0xffffffff,
    0xfff3f5ff,
    0xffd3d8ff,
    0xffabb3ff,
    0xffbfc5ff,
    0xff995bff,
    0xff8b45ed,
    0xff6f00b5,
    0xff550072,
    0xff360048,
  ],
  'color_18': <int>[
    0xffffffff,
    0xfff6f4ff,
    0xffdbd4ff,
    0xffc8bcff,
    0xffd8cfff,
    0xffba5ffc,
    0xffa94ee6,
    0xff8e00b0,
    0xff6f006b,
    0xff4c0046,
  ],
  'color_19': <int>[
    0xffffffff,
    0xfff7f4ff,
    0xffdfd3ff,
    0xffd1beff,
    0xffddceff,
    0xffca5df6,
    0xffb84ce0,
    0xff9800ad,
    0xff75006f,
    0xff51004a,
  ],
  'color_20': <int>[
    0xffffffff,
    0xfffbf2ff,
    0xfff0cbff,
    0xffe9b3ff,
    0xfff0c6ff,
    0xffed46de,
    0xffd932c9,
    0xffa90090,
    0xff80005e,
    0xff59003f,
  ],
  'color_21': <int>[
    0xffffffff,
    0xfffff1fc,
    0xffffc6f4,
    0xffffa8f1,
    0xffffc0f2,
    0xffff64c7,
    0xfff04ab6,
    0xffc90076,
    0xff9d0039,
    0xff740023,
  ],
};

void main() {
  group('Budget Header canonical category palettes', () {
    test(
      'derives a ten-slot sibling-hue micro-palette with exact canonical slot seven',
      () {
        final palettes = BudgetHeaderPaletteCatalog.allCategoryPalettes;
        expect(palettes, hasLength(21));
        expect(
          palettes.map((palette) => palette.id),
          CategoryCatalogIds.colorIds,
        );
        for (final palette in palettes) {
          final canonical = CategoryColorCatalog.resolve(
            palette.id,
          ).middleColor;
          expect(palette.slots, hasLength(BudgetHeaderPalette.slotCount));
          expect(
            palette.slots[BudgetHeaderPalette.canonicalSlotIndex],
            canonical,
            reason: '${palette.id} must retain the canonical identity zone',
          );
          expect(BudgetHeaderPalette.canonicalSlotIndex, 6);
          expect(palette.slots.first, const Color(0xffffffff));
          expect(palette.slots.last, isNot(canonical));
          expect(
            palette.slots.map((color) => color.toARGB32()).toSet().length,
            greaterThanOrEqualTo(9),
            reason: '${palette.id} must not collapse into duplicate RGB steps',
          );
          final canonicalHue = _OklabSample.fromColor(canonical).hue;
          final leadHueTravel = palette.slots
              .take(BudgetHeaderPalette.canonicalSlotIndex)
              .map((color) => _OklabSample.fromColor(color))
              .where((sample) => sample.chroma > .045)
              .map((sample) => _angularDistance(sample.hue, canonicalHue))
              .fold<double>(0, math.max);
          final tailHueTravel = palette.slots
              .skip(BudgetHeaderPalette.canonicalSlotIndex + 1)
              .map((color) => _OklabSample.fromColor(color))
              .where((sample) => sample.chroma > .045)
              .map((sample) => _angularDistance(sample.hue, canonicalHue))
              .fold<double>(0, math.max);
          expect(
            leadHueTravel,
            greaterThanOrEqualTo(.13),
            reason: '${palette.id} needs a real lead sister-hue corridor',
          );
          expect(
            tailHueTravel,
            greaterThanOrEqualTo(.13),
            reason: '${palette.id} needs a real deep sister-hue corridor',
          );
          final index = CategoryCatalogIds.colorIds.indexOf(palette.id);
          final oppositeId =
              CategoryCatalogIds.colorIds[(index +
                      CategoryCatalogIds.colorIds.length ~/ 2) %
                  CategoryCatalogIds.colorIds.length];
          final terminalHue = _OklabSample.fromColor(palette.slots.last).hue;
          final oppositeHue = _OklabSample.fromColor(
            CategoryColorCatalog.resolve(oppositeId).middleColor,
          ).hue;
          expect(
            _angularDistance(terminalHue, canonicalHue),
            lessThan(_angularDistance(terminalHue, oppositeHue)),
            reason:
                '${palette.id} must stay in its local family, not turn into an '
                'unrelated rainbow endpoint',
          );
        }
      },
    );

    test('reproduces the reviewed deterministic 21 by 10 palette fixture', () {
      expect(_paletteV2ArgbFixture, hasLength(21));
      for (final palette in BudgetHeaderPaletteCatalog.allCategoryPalettes) {
        expect(
          palette.slots.map((color) => color.toARGB32()).toList(),
          _paletteV2ArgbFixture[palette.id],
          reason: '${palette.id} output drifted from the reviewed V2 palette',
        );
      }
    });

    for (final width in <double>[28, 30]) {
      test(
        '$width% windows remain perceptually informative for all category families',
        () {
          for (final palette
              in BudgetHeaderPaletteCatalog.allCategoryPalettes) {
            for (final progress in <double>[.2, .35, .5, .65, .8]) {
              final window = BudgetHeaderColorWindowSampler.sample(
                palette: palette,
                rawProgress: progress,
                windowWidthPercent: width,
              );
              final a = _OklabSample.fromColor(window.colorA);
              final b = _OklabSample.fromColor(window.colorB);
              final distance = a.distanceTo(b);
              final chromaDelta = (a.chroma - b.chroma).abs();
              final hueDelta = a.chroma > .045 && b.chroma > .045
                  ? _angularDistance(a.hue, b.hue)
                  : 0.0;

              expect(
                distance,
                greaterThanOrEqualTo(.08),
                reason:
                    '${palette.id} at ${(progress * 100).round()}%/$width% '
                    'must communicate more than a nearly identical endpoint '
                    '(A=${window.colorA.toARGB32().toRadixString(16)}, '
                    'B=${window.colorB.toARGB32().toRadixString(16)}, '
                    'L=${a.lightness.toStringAsFixed(3)}→${b.lightness.toStringAsFixed(3)}, '
                    'C=${a.chroma.toStringAsFixed(3)}→${b.chroma.toStringAsFixed(3)}, '
                    'H=${a.hue.toStringAsFixed(3)}→${b.hue.toStringAsFixed(3)})',
              );
              expect(
                chromaDelta >= .025 || hueDelta >= .14,
                isTrue,
                reason:
                    '${palette.id} at ${(progress * 100).round()}%/$width% '
                    'must differ through a chromatic dimension, not lightness alone',
              );
            }
          }
        },
      );
    }

    test('samples the finite window continuously from its ten slots', () {
      final palette = BudgetHeaderPaletteCatalog.paletteForColorId('color_13');
      final sample = BudgetHeaderColorWindowSampler.sample(
        palette: palette,
        rawProgress: .5,
        windowWidthPercent: 28,
      );

      expect(sample.centerPercent, 50);
      expect(sample.leftPercent, 36);
      expect(sample.rightPercent, 64);
      expect(sample.leftSlotPosition, closeTo(3.24, 1e-12));
      expect(sample.rightSlotPosition, closeTo(5.76, 1e-12));
      expect(sample.colorA, palette.samplePercent(36));
      expect(sample.colorB, palette.samplePercent(64));
      expect(sample.colorA, isNot(sample.colorB));
    });

    test('changing only window width immediately changes sampled A/B', () {
      final palette = BudgetHeaderPaletteCatalog.paletteForColorId('color_08');
      final narrow = BudgetHeaderColorWindowSampler.sample(
        palette: palette,
        rawProgress: .5,
        windowWidthPercent: 20,
      );
      final wide = BudgetHeaderColorWindowSampler.sample(
        palette: palette,
        rawProgress: .5,
        windowWidthPercent: 60,
      );

      expect(narrow.leftPercent, 40);
      expect(narrow.rightPercent, 60);
      expect(wide.leftPercent, 20);
      expect(wide.rightPercent, 80);
      expect(narrow.colorA, isNot(wide.colorA));
      expect(narrow.colorB, isNot(wide.colorB));
    });

    test('clamps progress at the terminal palette edge without wrapping', () {
      final palette = BudgetHeaderPaletteCatalog.paletteForColorId('color_20');
      final terminal = BudgetHeaderColorWindowSampler.sample(
        palette: palette,
        rawProgress: 1,
        windowWidthPercent: 28,
      );
      final over = BudgetHeaderColorWindowSampler.sample(
        palette: palette,
        rawProgress: 2.8,
        windowWidthPercent: 28,
      );

      expect(terminal.leftPercent, 72);
      expect(terminal.rightPercent, 100);
      expect(over.leftPercent, terminal.leftPercent);
      expect(over.rightPercent, terminal.rightPercent);
      expect(over.colorA, terminal.colorA);
      expect(over.colorB, terminal.colorB);
    });
  });
}

double _angularDistance(double a, double b) {
  final raw = (a - b).abs() % (math.pi * 2);
  return raw > math.pi ? math.pi * 2 - raw : raw;
}

final class _OklabSample {
  const _OklabSample(this.lightness, this.a, this.b);

  factory _OklabSample.fromColor(Color color) {
    double linear(double channel) => channel <= .04045
        ? channel / 12.92
        : math.pow((channel + .055) / 1.055, 2.4).toDouble();
    final red = linear(color.r);
    final green = linear(color.g);
    final blue = linear(color.b);
    final l = .4122214708 * red + .5363325363 * green + .0514459929 * blue;
    final m = .2119034982 * red + .6806995451 * green + .1073969566 * blue;
    final s = .0883024619 * red + .2817188376 * green + .6299787005 * blue;
    final lRoot = math.pow(l, 1 / 3).toDouble();
    final mRoot = math.pow(m, 1 / 3).toDouble();
    final sRoot = math.pow(s, 1 / 3).toDouble();
    return _OklabSample(
      .2104542553 * lRoot + .7936177850 * mRoot - .0040720468 * sRoot,
      1.9779984951 * lRoot - 2.4285922050 * mRoot + .4505937099 * sRoot,
      .0259040371 * lRoot + .7827717662 * mRoot - .8086757660 * sRoot,
    );
  }

  final double lightness;
  final double a;
  final double b;

  double get chroma => math.sqrt(a * a + b * b);
  double get hue => math.atan2(b, a);
  double distanceTo(_OklabSample other) => math.sqrt(
    math.pow(lightness - other.lightness, 2) +
        math.pow(a - other.a, 2) +
        math.pow(b - other.b, 2),
  );
}
