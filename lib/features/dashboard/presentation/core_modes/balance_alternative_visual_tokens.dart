import 'package:flutter/material.dart';

/// The sole visual-token owner for the alternative Balance extended sheet.
///
/// Values are transcribed from the canonical Havi 2 / Éves HTML source, not
/// sampled from an image. The prototype comments establish the captured
/// physical-to-logical ratio: 26.73 HTML pixels equal 12 Flutter logical px.
abstract final class BalanceAlternativeHtmlTokens {
  static const double sourcePixelsPerLogicalPixel = 2.2275;

  static double logical(double sourcePixels) =>
      sourcePixels / sourcePixelsPerLogicalPixel;

  // HTML root geometry: 26.73px outer inset and 6.68px half gutter.
  static const double outerInset = 12;
  static const double halfGutter = 3;
  static const double directContentMinimumTolerance = .01;

  // The canonical SUM Mother Card is intentionally narrower and shorter than
  // the historical capture. Every child card therefore renders directly:
  // fixed typography/padding stay authored, while flexible plots receive the
  // remaining space. A whole-card FittedBox would break the approved 1:1 HTML
  // hierarchy, including for the 30%-wide side card.
  static const Size extendedSheetPrimaryCardMinimumSize = Size.zero;
  static const Size extendedSheetSideCardMinimumSize = Size.zero;
  static const Size extendedSheetCombinedCardMinimumSize = Size.zero;

  // HTML: .variant-card / .baseline-card.
  static double get childBorderRadius => logical(25);
  static const Color childSurface = Color(0xFFFFFFFF);
  static const Color childBorder = Color(0xFFE7EBF0);
  static const Color textPrimary = Color(0xFF111B59);
  static const Color textSecondary = Color(0xFF7181AA);
  static const Color supportingText = Color(0xFF63759A);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLineStart = Color(0xFF4D50E7);
  static const Color purpleLineEnd = Color(0xFF6254E8);
  static const Color positive = Color(0xFF19AA70);
  static const Color positiveLight = Color(0xFFC9F2DD);
  static const Color dailyAreaStart = Color(0xFFDDDEFE);
  static const Color dailyAreaEnd = Color(0xFFEEF0FF);
  static const Color chartGrid = Color(0xFFDfe4EF);
  static const Color incomeStripStart = Color(0xFF89DF9C);
  static const Color incomeStripEnd = Color(0xFFD4FAD6);
  static const Color expenseStripStart = Color(0xFFFFE2E7);
  static const Color expenseStripEnd = Color(0xFFFFB9C9);
  static const Color closingPositiveStart = Color(0xFF89E5CD);
  static const Color closingPositiveEnd = Color(0xFF75DCC1);
  static const Color closingNegativeStart = Color(0xFFFF9CB5);
  static const Color closingNegativeEnd = Color(0xFFFF8EAA);

  // HTML .daily-spend-card: 24px 24px 20px; 10px inter-row gap.
  static EdgeInsets get dailyCardPadding =>
      EdgeInsets.fromLTRB(logical(24), logical(24), logical(24), logical(20));
  static double get dailyHeaderHeight => logical(64);
  static double get dailyInsightHeight => logical(102);
  static double get dailyGap => logical(10);
  static double get dailyTitleSize => logical(30);
  static double get dailySubtitleSize => logical(19);
  static double get dailyComparisonSize => logical(32);
  static double get dailyBodySize => logical(17);
  static double get dailyInsightTitleSize => logical(23);
  static double get dailyIconWidth => logical(30);
  static double get dailyIconHeight => logical(42);
  static double get dailyInsightIconExtent => logical(58);
  static double get dailyInsightRadius => logical(23);

  // HTML .baseline-income-expense: 23px 20px 19px; 42/145px rows.
  static EdgeInsets get incomeExpensePadding =>
      EdgeInsets.fromLTRB(logical(20), logical(23), logical(20), logical(19));
  static double get incomeExpenseHeadingHeight => logical(42);
  static double get incomeExpenseStripHeight => logical(145);
  static double get incomeExpenseGap => logical(13);
  static double get incomeExpenseTitleSize => logical(27);
  static double get incomeExpenseValueSize => logical(23);
  static double get incomeExpenseBodySize => logical(17);
  static double get incomeExpenseStripRadius => logical(25);
  static double get incomeExpenseSwitchExtent => logical(56);

  // HTML .annual-closings-card: 24px 22px 20px, 63px title and 31px legend.
  static EdgeInsets get annualClosingsPadding =>
      EdgeInsets.fromLTRB(logical(22), logical(24), logical(22), logical(20));
  static double get annualClosingsHeadingHeight => logical(63);
  static double get annualClosingsLegendHeight => logical(31);
  static double get annualTitleSize => logical(30);
  static double get annualSubtitleSize => logical(19);
  static double get annualLegendSize => logical(15);
  static double get annualGap => logical(8);

  // Shared Havi 2 small-card chrome. HTML: 21px 16px / 20px title and 66px
  // no-spend metric; those source units are converted by [logical].
  static EdgeInsets get smallCardPadding =>
      EdgeInsets.symmetric(horizontal: logical(16), vertical: logical(21));
  static double get smallTitleSize => logical(20);
  static double get noSpendValueSize => logical(66);
  static double get smallBodySize => logical(17);
  static double get smallRingSize => logical(132);
  static double get annualSavingsTitleSize => logical(21);
  static double get annualSavingsValueSize => logical(37);

  // HTML .income-expense-card (Éves lower combined card).
  static EdgeInsets get annualIncomeExpensePadding =>
      EdgeInsets.fromLTRB(logical(22), logical(21), logical(22), logical(19));
  static double get annualIncomeExpenseHeadingHeight => logical(60);
  static double get annualIncomeExpenseGap => logical(8);
  static double get annualIncomeExpenseIconExtent => logical(42);
  static double get annualIncomeExpenseLegendSize => logical(17);
  static double get annualIncomeExpenseToggleExtent => logical(34);

  static BoxDecoration childCardDecoration() => BoxDecoration(
    color: childSurface,
    borderRadius: BorderRadius.circular(childBorderRadius),
    border: Border.all(color: childBorder, width: logical(2)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x0614213A), blurRadius: 3, offset: Offset(0, 1)),
    ],
  );
}
