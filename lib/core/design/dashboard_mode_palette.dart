import 'package:flutter/material.dart';

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
  static const textOnAction = Color(0xFFFFFFFF);
  static const railActiveSurface = Color(0xFFA855F7);
  static const railActiveText = Color(0xFFFFFFFF);

  static const cardRadius = BorderRadius.all(Radius.circular(20));
  static const controlRadius = BorderRadius.all(Radius.circular(18));
  static const pillRadius = BorderRadius.all(Radius.circular(999));
  static const smallRadius = BorderRadius.all(Radius.circular(12));

  static const brandMarkSize = 42.0;
  static const brandGap = 10.0;
  static const wordmarkFontSize = 24.0;
  static const mottoFontSize = 10.0;
  static const labelFontSize = 16.0;
  static const bodyFontSize = 13.0;
  static const captionFontSize = 10.0;
  static const iconSize = 20.0;
  static const actionIconSize = 32.0;
  static const controlInnerGap = 8.0;
  static const controlHorizontalInset = 12.0;
  static const pillHorizontalInset = 16.0;
  static const railPillGap = 8.0;
  static const handleBarWidth = 42.0;
  static const handleBarHeight = 4.0;
  static const filterControlAspectRatio = 1.0;

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
    fontSize: labelFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const actionLabelOnActiveTextStyle = TextStyle(
    color: textOnAction,
    fontSize: labelFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const summaryLabelTextStyle = TextStyle(
    color: textSecondary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const searchHintTextStyle = TextStyle(
    color: textSecondary,
    fontSize: captionFontSize,
    height: 1.2,
  );
  static const railPillTextStyle = TextStyle(
    color: textPrimary,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const railPillActiveTextStyle = TextStyle(
    color: railActiveText,
    fontSize: bodyFontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}

/// Palette supplied for a dashboard mode without duplicating visual policy in a
/// renderer.
@immutable
class DashboardModePalette {
  const DashboardModePalette({
    required this.incomeGradient,
    required this.expenseGradient,
    required this.upcomingHeaderTone,
  });

  final LinearGradient incomeGradient;
  final LinearGradient expenseGradient;
  final Color upcomingHeaderTone;
}

/// Resolves the immutable palette for one dashboard mode.
///
/// The motion host accepts this policy as a dependency so it can cache the
/// result across visual ticker frames while the central resolver remains the
/// production default.
typedef DashboardModePaletteLookup = DashboardModePalette Function(
  DashboardModeSpec mode,
);

/// Resolves shared, dynamic action treatments from dashboard semantics.
abstract final class DashboardModePaletteResolver {
  static const _incomeStart = Color(0xFF7048E8);
  static const _incomeEnd = Color(0xFFF542A7);
  static const _expenseStart = Color(0xFFFF8A3D);
  static const _expenseEnd = Color(0xFFF542A7);

  static const _balance = DashboardModePalette(
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
    upcomingHeaderTone: Color(0xFF172554),
  );
  static const _budget = DashboardModePalette(
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
    upcomingHeaderTone: Color(0xFF6D28D9),
  );
  static const _mind = DashboardModePalette(
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
