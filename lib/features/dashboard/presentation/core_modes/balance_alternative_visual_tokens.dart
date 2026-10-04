import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_header_balance_color_scale.dart';

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

  // The primary monthly/yearly charts contain a fixed title/subtitle lane,
  // plot and legend. Keep that authored composition at a stable source floor;
  // unusually compact transient slots scale it as one unit rather than
  // clipping headings or emitting RenderFlex overflow diagnostics.
  static Size get extendedSheetPrimaryCardMinimumSize =>
      Size(logical(480), logical(420));
  static const Size extendedSheetSideCardMinimumSize = Size.zero;
  static const Size extendedSheetCombinedCardMinimumSize = Size.zero;

  // The approved SUM composition has authored source dimensions. These are
  // only a below-physical-minimum fallback: at normal Mother Card dimensions
  // SUM stays direct, while an unusually small host scales the full child
  // hierarchy rather than overflowing or changing Mother geometry.
  static Size get sumSideCardMinimumContentSize =>
      Size(logical(252), logical(300));
  static Size get sumCombinedCardMinimumContentSize =>
      Size(logical(720), logical(340));
  static Size get napi4ImpactCardMinimumContentSize =>
      Size(logical(252), logical(600));
  static Size get napi4RhythmCardMinimumContentSize =>
      Size(logical(720), logical(340));

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

  // SUM distribution cards. The histogram's dynamic hues are resolved from
  // the single approved Soft rainbow catalog instead of a local copy.
  static List<Color> get sumOriginalSoftRainbow =>
      DashboardBalanceHeaderPaletteCatalog.scaleFor(
        DashboardBalanceHeaderPalette.softRainbow,
      ).colors;
  static const Color sumPurple = Color(0xFF7339D4);
  static const Color sumPurpleLight = Color(0xFFEEE9FF);
  static const Color sumInsightStart = Color(0xFFF5F2FF);
  static const Color sumInsightEnd = Color(0xFFEDE8FF);
  static const Color sumBandNegative = Color(0xFFFDE0E7);
  static const Color sumBandPurpleStart = Color(0xFFF1EBFF);
  static const Color sumBandPurpleEnd = Color(0xFFF0EAFF);
  static const Color sumBandPositive = Color(0xFFD3F7DF);
  static const Color sumBandRule = Color(0xFFAEB9C9);
  static const Color sumBandZeroRule = Color(0xFF9CA9BA);
  static const Color sumBandDot = Color(0xFF9D78E9);
  static const Color sumBandNegativeDot = Color(0xFFEF89A0);
  static const Color sumBandPositiveDot = Color(0xFF38B96B);

  // Napi 4, transcribed from the canonical daily-momentum HTML. The same
  // semantic token owner supplies the coordinate field, impact tube and
  // rhythm strip; individual card renderers never own a local palette.
  static const Color dailyMomentumPurple = Color(0xFF7750DF);
  static const Color dailyMomentumPurpleLight = Color(0xFFB395FF);
  static const Color dailyMomentumTeal = Color(0xFF41C9BE);
  static const Color dailyMomentumMint = Color(0xFF20B78D);
  static const Color dailyMomentumCoral = Color(0xFFEF7184);
  static const Color dailyMomentumAxis = Color(0xFF8293AE);
  static const Color dailyMomentumFieldUpperLeft = Color(0xFFE2F7EE);
  static const Color dailyMomentumFieldUpperRight = Color(0xFFDCF5F2);
  static const Color dailyMomentumFieldLowerLeft = Color(0xFFE1EBF4);
  static const Color dailyMomentumFieldLowerRight = Color(0xFFF1EBEB);
  static const Color dailyMomentumWell = Color(0xFFE9F0F1);
  static const Color dailyMomentumRing = Color(0xFFFDFEFC);

  /// Semantic original-Soft-rainbow resolver used by every adaptive SUM bar.
  /// Negative ranges progress coral/rose -> purple and positive ranges
  /// progress purple -> blue/turquoise/green; count never affects hue.
  static Color sumHistogramColorForNet({
    required double netMinor,
    required double regularDomainMinimumMinor,
    required double regularDomainMaximumMinor,
  }) {
    if (netMinor <= 0) {
      final span = (-regularDomainMinimumMinor).clamp(.000001, double.infinity);
      return _sumSoftRainbowSample(1, 4, (netMinor + span) / span);
    }
    final span = regularDomainMaximumMinor.clamp(.000001, double.infinity);
    return _sumSoftRainbowSample(4, 9, netMinor / span);
  }

  static Color _sumSoftRainbowSample(
    int startIndex,
    int endIndex,
    double amount,
  ) {
    final palette = sumOriginalSoftRainbow;
    final position =
        startIndex + (endIndex - startIndex) * amount.clamp(0.0, 1.0);
    final lower = position.floor();
    final upper = position.ceil().clamp(0, palette.length - 1);
    return Color.lerp(palette[lower], palette[upper], position - lower)!;
  }

  // HTML .daily-spend-card: 24px 24px 20px; 10px inter-row gap.
  static EdgeInsets get dailyCardPadding =>
      EdgeInsets.fromLTRB(logical(24), logical(24), logical(24), logical(20));
  // The historical source lane was shorter than Flutter's actual two-line
  // title/subtitle metrics. Give the semantic heading a real lane so it does
  // not overlap the chart or overflow when the core surface changes scope.
  static double get dailyHeaderHeight => logical(108);
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
  // Annual title/subtitle use the same explicit rendered-metric contract as
  // the daily heading above.
  static double get annualClosingsHeadingHeight => logical(108);
  static double get annualClosingsLegendHeight => logical(31);
  static double get annualTitleSize => logical(30);
  static double get annualSubtitleSize => logical(19);
  static double get annualLegendSize => logical(18);
  static double get annualGap => logical(8);
  static double get annualClosingBarMaximumWidth => logical(28);
  static const double annualClosingBarStepFraction = .74;

  static double annualClosingBarWidthFor({
    required double plotWidth,
    required int bucketCount,
  }) {
    if (plotWidth <= 0 || bucketCount <= 0) return 0;
    return math.min(
      annualClosingBarMaximumWidth,
      plotWidth / bucketCount * annualClosingBarStepFraction,
    );
  }

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
  static double get annualIncomeExpenseBarMaximumWidth => logical(14);
  static const double annualIncomeExpenseBarStepFraction = .38;
  static double get annualIncomeExpenseBarGap => logical(2);
  static double get annualIncomeExpenseMonthLabelSize => logical(16);

  static double annualIncomeExpenseBarWidthFor({
    required double plotWidth,
    required int bucketCount,
  }) {
    if (plotWidth <= 0 || bucketCount <= 0) return 0;
    return math.min(
      annualIncomeExpenseBarMaximumWidth,
      plotWidth / bucketCount * annualIncomeExpenseBarStepFraction,
    );
  }

  // SUM Card 3: canonical `sum-histogram-card` CSS.
  static EdgeInsets get sumHistogramPadding =>
      EdgeInsets.fromLTRB(logical(24), logical(22), logical(24), logical(20));
  static double get sumHistogramHeadingHeight => logical(58);
  static double get sumHistogramGap => logical(10);
  static double get sumHistogramInsightHeight => logical(82);
  static double get sumHistogramTitleSize => logical(25);
  static double get sumHistogramSubtitleSize => logical(16);
  static double get sumHistogramInsightTitleSize => logical(17);
  static double get sumHistogramInsightBodySize => logical(14);
  static double get sumHistogramMedianCalloutWidth => logical(112);
  static double get sumHistogramMedianCalloutHeight => logical(50);

  // SUM Card 4: canonical `sum-positive-streak-card` CSS.
  static EdgeInsets get sumStreakPadding =>
      EdgeInsets.fromLTRB(logical(16), logical(18), logical(16), logical(16));
  static double get sumStreakHeadingHeight => logical(43);
  static double get sumStreakValueHeight => logical(57);
  static double get sumStreakCopyHeight => logical(25);
  static double get sumStreakGap => logical(3);
  static double get sumStreakValueSize => logical(54);
  static double get sumStreakTitleSize => logical(17);
  static double get sumStreakBodySize => logical(12);

  // SUM lower combined card: canonical `cashflow-stability-card` CSS.
  static double get sumStabilityHorizontalInset => logical(8);
  static EdgeInsets get sumStabilityPadding => EdgeInsets.fromLTRB(
    sumStabilityHorizontalInset,
    logical(18),
    sumStabilityHorizontalInset,
    logical(20),
  );
  static double get sumStabilityHeadingHeight => logical(48);
  static double get sumStabilityChartHeight => logical(126);
  static double get sumStabilityGap => logical(10);
  static double get sumStabilityTitleSize => logical(24);
  static double get sumStabilitySubtitleSize => logical(14);
  static double get sumStabilityChipSize => logical(15);
  static double get sumStabilityLegendSize => logical(16);

  static double get napi4RhythmHorizontalInset => logical(8);

  static BoxDecoration childCardDecoration() => BoxDecoration(
    color: childSurface,
    borderRadius: BorderRadius.circular(childBorderRadius),
    border: Border.all(color: childBorder, width: logical(2)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x0614213A), blurRadius: 3, offset: Offset(0, 1)),
    ],
  );
}
