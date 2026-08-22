import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_catalog_ids.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_budget_palette.dart';

void main() {
  group('Budget Header canonical category palettes', () {
    test(
      'derives exactly ten identity-preserving slots for every category',
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
          expect(palette.slots.first, isNot(const Color(0xffffffff)));
          expect(palette.slots.last, isNot(canonical));
          expect(
            palette.slots.map((color) => color.toARGB32()).toSet().length,
            greaterThanOrEqualTo(9),
            reason: '${palette.id} must not collapse into duplicate RGB steps',
          );
        }
      },
    );

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
