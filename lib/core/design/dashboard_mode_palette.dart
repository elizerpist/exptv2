import 'package:flutter/material.dart';

import 'app_control_metrics.dart';
import 'dashboard_layout_metrics.dart';
import '../../features/dashboard/application/dashboard_mode_spec.dart';

/// The single semantic visual source for the first Fluvi dashboard slice.
abstract final class FluviVisualTokens {
  static const pageBackground = Color(0xFFF1F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const surfaceInactive = Color(0xFFF4F0F8);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF172554);
  static const textSecondary = Color(0xFF64748B);
  static const collapseHandleIdleColor = Color(0xFF94A3B8);
  static const textOnAction = Color(0xFFFFFFFF);
  static const logBoxIncomeAmount = Color(0xFF0F766E);
  static const logBoxExpenseAmount = Color(0xFFB42318);

  /// Budget-limit utilisation tones are semantic, not category-specific.
  /// The progress projection resolves them once from raw utilisation while the
  /// selected avatar keeps its category accent below the warning threshold.
  static const budgetProgressWarning = Color(0xFFF59E0B);
  static const budgetProgressDanger = Color(0xFFEF4444);

  /// The single app highlight ramp taken from the Balance B3M active rail.
  /// Every non-income/expense highlight must resolve through this gradient.
  static const appHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF715EFB), Color(0xFFB484F3), Color(0xFFE478C3)],
    stops: [0, .5, 1],
  );

  /// Explicit snapshot for the active income control.
  ///
  /// This intentionally has the same current colors as the app highlight,
  /// but is an independent token so future app-highlight changes do not
  /// silently change the income control.
  static const incomeButtonHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF715EFB), Color(0xFFB484F3), Color(0xFFE478C3)],
    stops: [0, .5, 1],
  );
  static const appHighlightPressedColor = Color(0xFF6E5CF1);
  static const appHighlightBorderColor = Color(0xFFB484F3);
  static const appHighlightShadowColor = Color(0x407D5BE6);
  static const appHighlightText = Color(0xFFFFFFFF);
  static const appHighlightShadow = BoxShadow(
    color: appHighlightShadowColor,
    blurRadius: 17,
    offset: Offset(0, 8),
  );

  /// Shared neutral 3D-like lower lip for every rounded card surface.
  ///
  /// The unblurred offset creates the small visible foot below the border;
  /// the second shadow preserves the softer Balance-card elevation around it.
  static const cardFootShadow = BoxShadow(
    color: Color(0x26524B93),
    offset: Offset(0, 4),
    blurRadius: 0,
    spreadRadius: 0,
  );
  static const cardElevationShadow = BoxShadow(
    color: Color(0x1A524B93),
    offset: Offset(0, 10),
    blurRadius: 18,
    spreadRadius: 0,
  );
  static const cardSurfaceShadows = <BoxShadow>[
    cardFootShadow,
    cardElevationShadow,
  ];

  /// The only generic component shape. Component sizes remain independent.
  static const roundedBoxRadius = BorderRadius.all(
    Radius.circular(AppRadii.control),
  );
  static const handleRadius = BorderRadius.all(Radius.circular(2));
  static const smallRadius = BorderRadius.all(Radius.circular(AppRadii.small));
  static const logBoxGroupRadius = BorderRadius.all(
    Radius.circular(AppRadii.logGroup),
  );

  static const brandMarkSize = 42.0;
  static const brandGap = 10.0;
  static const wordmarkFontSize = 24.0;
  static const mottoFontSize = 10.0;
  static const labelFontSize = 16.0;
  static const bodyFontSize = 13.0;
  static const captionFontSize = 10.0;
  static const iconSize = 20.0;
  static const actionIconSize = 32.0;
  static const directionIconScaleMultiplier = 1.10;
  static const controlInnerGap = 8.0;
  static const controlHorizontalInset = 12.0;
  static const railItemExtent = B3mReferenceMetrics.referenceItemExtent;
  static const railVisualWidth = B3mReferenceMetrics.referenceCompactTileWidth;
  static const handleBarWidth = 42.0;
  static const handleBarHeight = 4.0;
  static const dotSize = 6.0;
  static const dotHorizontalInset = 3.0;
  static const placeholderDotInactive = Color(0xFFCBD5E1);
  static const navigationHeight = 116.0;
  static const navigationHorizontalInset = 18.0;
  static const navigationItemWidth = 150.0;
  static const navigationItemVerticalInset = 12.0;
  static const navigationItemBottomInset = 12.0;
  static const navigationIconSize = 20.0;
  static const navigationLabelFontSize = 11.0;
  static const centerFabSize = 64.0;
  static const centerFabTopInset = 10.0;
  static const navigationBumpSideTop = 26.0;
  static const navigationBumpPeak = 0.0;
  static const navigationBumpHalfWidth = 62.0;
  static const navigationActiveIcon = appHighlightPressedColor;
  static const navigationInactiveIcon = Color(0xFF64748B);
  static const navigationFabGradient = appHighlightGradient;
  static const fullscreenButtonSize = 44.0;

  static const brandWordmarkTextStyle = TextStyle(
    color: textPrimary,
    fontSize: wordmarkFontSize,
    fontWeight: FontWeight.w800,
    height: 1,
  );
  static const brandMottoTextStyle = TextStyle(
    color: textSecondary,
    fontSize: mottoFontSize,
    height: 1.2,
  );
  static const actionLabelTextStyle = TextStyle(
    color: textPrimary,
    fontSize: B3mReferenceMetrics.activeFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const actionLabelOnActiveTextStyle = TextStyle(
    color: textOnAction,
    fontSize: B3mReferenceMetrics.activeFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const summaryLabelTextStyle = TextStyle(
    color: textSecondary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const summaryTitleTextStyle = TextStyle(
    color: textPrimary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const summaryPlaneTextStyle = TextStyle(
    color: textSecondary,
    fontSize: captionFontSize,
    fontWeight: FontWeight.w500,
    height: 1.1,
  );
  static const logBoxHeaderTextStyle = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const logBoxResultAmountTextStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static const logBoxSearchTextStyle = TextStyle(
    color: textSecondary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const logBoxDayHeaderTextStyle = TextStyle(
    color: textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const logBoxRowTitleTextStyle = TextStyle(
    color: textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const logBoxRowAmountTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const logBoxRowSecondaryTextStyle = TextStyle(
    color: textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const summaryAmountTextStyle = TextStyle(
    color: textPrimary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const railTextStyle = TextStyle(
    color: textPrimary,
    fontSize: B3mReferenceMetrics.inactiveFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const railActiveTextStyle = TextStyle(
    color: appHighlightText,
    fontSize: B3mReferenceMetrics.activeFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const navigationLabelTextStyle = TextStyle(
    color: navigationInactiveIcon,
    fontSize: navigationLabelFontSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const navigationActiveLabelTextStyle = TextStyle(
    color: appHighlightPressedColor,
    fontSize: navigationLabelFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

/// Shared geometry for the lazy LogBox presentation.
abstract final class DashboardLogBoxTokens {
  static const horizontalGutter = 0.0;
  static const summaryHeaderHeight =
      DashboardLayoutMetrics.referenceLogBoxHeaderHeight;

  /// The fixed top-of-Ledger structure is metric-owned rather than painted
  /// with offsets. Its reference values sum to [summaryHeaderHeight].
  static const ledgerResultTopInset =
      DashboardLayoutMetrics.referenceStandardGap;
  static const ledgerResultAmountHeight = 26.0;
  static const ledgerResultCountHeight = 17.0;
  static const ledgerResultToSearchGap =
      DashboardLayoutMetrics.referenceStandardGap;
  static const ledgerSearchPillHeight = 46.0;
  static const ledgerSearchToListGap =
      DashboardLayoutMetrics.referenceStandardGap;

  /// Extra breathing room after the terminal LogBox shadow. The shell reports
  /// the actual navigation obstruction through `MediaQuery`; this token never
  /// shortens the viewport and never becomes row/page geometry.
  static const terminalBottomBreathingRoom = 12.0;

  /// A deliberately small visual separation between active Query facets and
  /// the structural LogBox scroll lane.
  static const facetListGap = 6.0;
  static const dayHeaderHeight = 20.0;
  static const dayHeaderTopInset = 7.0;
  static const dayGroupGap = 10.0;
  static const rowHeight = 55.0;
  static const rowHorizontalInset = 12.0;
  static const rowVerticalInset = 8.0;
  static const rowGap = 10.0;
  static const avatarSize = 34.0;
  static const avatarIconSize = 18.0;
  static const dividerHeight = 1.0;
  static const cacheExtent = 360.0;
}

/// Palette supplied for a dashboard mode without duplicating visual policy in a
/// renderer.
@immutable
class DashboardModePalette {
  const DashboardModePalette({
    this.pageBackground = FluviVisualTokens.pageBackground,
    required this.incomeGradient,
    required this.expenseGradient,
    required this.upcomingHeaderTone,
  });

  final Color pageBackground;
  final LinearGradient incomeGradient;
  final LinearGradient expenseGradient;
  final Color upcomingHeaderTone;
}

/// Resolves the immutable palette for one dashboard mode.
///
/// The motion host accepts this policy as a dependency so it can cache the
/// result across visual ticker frames while the central resolver remains the
/// production default.
typedef DashboardModePaletteLookup =
    DashboardModePalette Function(DashboardModeSpec mode);

/// Resolves shared, dynamic action treatments from dashboard semantics.
abstract final class DashboardModePaletteResolver {
  static const _incomeStart = Color(0xFF7048E8);
  static const _incomeEnd = Color(0xFFF542A7);
  static const _expenseStart = Color(0xFFFF8A3D);
  static const _expenseEnd = Color(0xFFF542A7);

  static const _balance = DashboardModePalette(
    pageBackground: FluviVisualTokens.pageBackground,
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
    upcomingHeaderTone: Color(0xFF172554),
  );
  static const _budget = DashboardModePalette(
    pageBackground: FluviVisualTokens.pageBackground,
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
    upcomingHeaderTone: Color(0xFF6D28D9),
  );
  static const _mind = DashboardModePalette(
    pageBackground: FluviVisualTokens.pageBackground,
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
    upcomingHeaderTone: Color(0xFF0F766E),
  );

  static DashboardModePalette resolve(DashboardModeSpec mode) {
    return switch (mode.mode) {
      DashboardMode.balance => _balance,
      DashboardMode.budget => _budget,
      DashboardMode.mind => _mind,
    };
  }
}

/// Shared timing policy for the dashboard's only motion owner.
abstract final class DashboardMotionTokens {
  static const pulseDuration = Duration(milliseconds: 420);
  static const railDuration = Duration(milliseconds: 180);
  static const collapseDuration = Duration(milliseconds: 180);

  /// Balance HTML collapse treatment for the two white lower card layers.
  static const subheaderOneCollapseShift = -18.0;
  static const subheaderOneCollapseScale = .90;
  static const zone2CollapseShift = -24.0;
  static const zone2CollapseScale = .96;
  // Start the upper card farther behind the header so its full slide-out
  // remains visible over the same master duration as the header collapse.
  static const upperHiddenOverlap = 48.0;
  static const upperNestedInset = 18.0;
  static const lowerHiddenOverlap = 32.0;
  static const lowerNestedInset = 18.0;

  static const hiddenReveal = 0.0;
  static const shownReveal = 1.0;
  static const restingScale = 1.0;
  static const pulseStartScale = .90;
  static const pulsePeakScale = 1.12;
  static const pulseSettleScale = .98;
  static const pulseRiseWeight = 30.0;
  static const pulseSettleWeight = 40.0;
  static const pulseRestWeight = 30.0;
  static const transitionCurve = Curves.easeOutCubic;
}
