import 'package:fluvi/features/dashboard/presentation/dashboard_logbox_amount_palette.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'income and expense palette selections have independent current defaults',
    () {
      const settings = DashboardLogBoxAmountPaletteSettings.defaults;

      expect(settings.income, DashboardLogBoxIncomePalette.current);
      expect(settings.expense, DashboardLogBoxExpensePalette.current);

      final mixed = settings.copyWith(
        income: DashboardLogBoxIncomePalette.balanceReference,
        expense: DashboardLogBoxExpensePalette.fluviCategoryRed01,
      );

      expect(mixed.income, DashboardLogBoxIncomePalette.balanceReference);
      expect(mixed.expense, DashboardLogBoxExpensePalette.fluviCategoryRed01);
    },
  );

  test('every amount palette option pins a source-authored colour', () {
    for (final palette in DashboardLogBoxIncomePalette.values) {
      final color = DashboardLogBoxAmountPaletteProfile(
        DashboardLogBoxAmountPaletteSettings(income: palette),
      ).income;
      expect(color, isA<Color>(), reason: palette.name);
    }
    for (final palette in DashboardLogBoxExpensePalette.values) {
      final color = DashboardLogBoxAmountPaletteProfile(
        DashboardLogBoxAmountPaletteSettings(expense: palette),
      ).expense;
      expect(color, isA<Color>(), reason: palette.name);
    }

    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          income: DashboardLogBoxIncomePalette.budgetReference,
          expense: DashboardLogBoxExpensePalette.budgetReference,
        ),
      ).income,
      const Color(0xFF22C55E),
    );
    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          income: DashboardLogBoxIncomePalette.budgetReference,
          expense: DashboardLogBoxExpensePalette.budgetReference,
        ),
      ).expense,
      const Color(0xFFEF4444),
    );
    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          income: DashboardLogBoxIncomePalette.balanceReference,
        ),
      ).income,
      const Color(0xFFFF3E73),
      reason:
          'The active Balance renderer has one unconditional source amount '
          'colour; do not relabel Budget green as Balance green.',
    );
    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          expense: DashboardLogBoxExpensePalette.balanceReference,
        ),
      ).expense,
      const Color(0xFFFF3E73),
    );
    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          income: DashboardLogBoxIncomePalette.fluviCategoryGreen07,
          expense: DashboardLogBoxExpensePalette.fluviCategoryRed01,
        ),
      ).income,
      CategoryColorCatalog.resolve('color_07').middleColor,
    );
    expect(
      DashboardLogBoxAmountPaletteProfile(
        const DashboardLogBoxAmountPaletteSettings(
          income: DashboardLogBoxIncomePalette.fluviCategoryGreen07,
          expense: DashboardLogBoxExpensePalette.fluviCategoryRed01,
        ),
      ).expense,
      CategoryColorCatalog.resolve('color_01').middleColor,
    );
  });
}
