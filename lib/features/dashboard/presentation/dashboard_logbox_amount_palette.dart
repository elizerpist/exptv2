import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/design/dashboard_mode_palette.dart';

/// Discrete provenance-preserving amount palette choices. Colour resolution is
/// deliberately centralized in the LogBox presentation profile, not per row.
enum DashboardLogBoxIncomePalette {
  current,
  fluviCategoryGreen07,
  fluviCategoryGreen08,
  fluviCategoryGreen09,
  fluviCategoryGreen10,
  budgetReference,
  balanceReference,
}

enum DashboardLogBoxExpensePalette {
  current,
  fluviCategoryRed01,
  fluviCategoryPink20,
  fluviCategoryPink21,
  budgetReference,
  balanceReference,
}

/// Source-pinned, paint-only colours consumed once by the LogBox painter.
///
/// Fluvi category entries resolve their exact `middleColor` from the existing
/// category catalog. The Budget reference uses its source `income/expense`
/// palette. The active Balance row renderer has one
/// unconditional source amount `#FF3E73`; it is kept source-true in both
/// selectors rather than inventing or relabelling a Balance income green.
@immutable
final class DashboardLogBoxAmountPaletteProfile {
  const DashboardLogBoxAmountPaletteProfile(this.settings);

  final DashboardLogBoxAmountPaletteSettings settings;

  Color get income => switch (settings.income) {
    DashboardLogBoxIncomePalette.current =>
      FluviVisualTokens.logBoxIncomeAmount,
    DashboardLogBoxIncomePalette.fluviCategoryGreen07 =>
      CategoryColorCatalog.resolve('color_07').middleColor,
    DashboardLogBoxIncomePalette.fluviCategoryGreen08 =>
      CategoryColorCatalog.resolve('color_08').middleColor,
    DashboardLogBoxIncomePalette.fluviCategoryGreen09 =>
      CategoryColorCatalog.resolve('color_09').middleColor,
    DashboardLogBoxIncomePalette.fluviCategoryGreen10 =>
      CategoryColorCatalog.resolve('color_10').middleColor,
    DashboardLogBoxIncomePalette.budgetReference => const Color(0xFF22C55E),
    DashboardLogBoxIncomePalette.balanceReference => const Color(0xFFFF3E73),
  };

  Color get expense => switch (settings.expense) {
    DashboardLogBoxExpensePalette.current =>
      FluviVisualTokens.logBoxExpenseAmount,
    DashboardLogBoxExpensePalette.fluviCategoryRed01 =>
      CategoryColorCatalog.resolve('color_01').middleColor,
    DashboardLogBoxExpensePalette.fluviCategoryPink20 =>
      CategoryColorCatalog.resolve('color_20').middleColor,
    DashboardLogBoxExpensePalette.fluviCategoryPink21 =>
      CategoryColorCatalog.resolve('color_21').middleColor,
    DashboardLogBoxExpensePalette.budgetReference => const Color(0xFFEF4444),
    DashboardLogBoxExpensePalette.balanceReference => const Color(0xFFFF3E73),
  };
}

@immutable
final class DashboardLogBoxAmountPaletteSettings {
  const DashboardLogBoxAmountPaletteSettings({
    this.income = DashboardLogBoxIncomePalette.current,
    this.expense = DashboardLogBoxExpensePalette.current,
  });

  static const defaults = DashboardLogBoxAmountPaletteSettings();

  final DashboardLogBoxIncomePalette income;
  final DashboardLogBoxExpensePalette expense;

  DashboardLogBoxAmountPaletteSettings copyWith({
    DashboardLogBoxIncomePalette? income,
    DashboardLogBoxExpensePalette? expense,
  }) => DashboardLogBoxAmountPaletteSettings(
    income: income ?? this.income,
    expense: expense ?? this.expense,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxAmountPaletteSettings &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(income, expense);
}

final class DashboardLogBoxAmountPaletteController
    extends ValueNotifier<DashboardLogBoxAmountPaletteSettings> {
  DashboardLogBoxAmountPaletteController()
    : super(DashboardLogBoxAmountPaletteSettings.defaults);

  void selectIncome(DashboardLogBoxIncomePalette palette) {
    final next = value.copyWith(income: palette);
    if (next != value) value = next;
  }

  void selectExpense(DashboardLogBoxExpensePalette palette) {
    final next = value.copyWith(expense: palette);
    if (next != value) value = next;
  }
}

final class DashboardLogBoxAmountPaletteScope
    extends InheritedNotifier<DashboardLogBoxAmountPaletteController> {
  const DashboardLogBoxAmountPaletteScope({
    super.key,
    required DashboardLogBoxAmountPaletteController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardLogBoxAmountPaletteSettings settingsOf(
    BuildContext context,
  ) =>
      context
          .dependOnInheritedWidgetOfExactType<
            DashboardLogBoxAmountPaletteScope
          >()
          ?.notifier
          ?.value ??
      DashboardLogBoxAmountPaletteSettings.defaults;

  static DashboardLogBoxAmountPaletteProfile profileOf(BuildContext context) =>
      DashboardLogBoxAmountPaletteProfile(settingsOf(context));
}
