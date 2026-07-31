import 'package:flutter/material.dart';

import '../../features/dashboard/application/dashboard_mode_spec.dart';
import '../../features/dashboard/application/transaction_direction_controller.dart';

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
}

/// Palette supplied for a dashboard mode without duplicating visual policy in a
/// renderer.
@immutable
class DashboardModePalette {
  const DashboardModePalette({
    required this.incomeGradient,
    required this.expenseGradient,
  });

  final LinearGradient incomeGradient;
  final LinearGradient expenseGradient;
}

/// Resolves shared, dynamic action treatments from dashboard semantics.
abstract final class DashboardModePaletteResolver {
  static const _incomeStart = Color(0xFF7048E8);
  static const _incomeEnd = Color(0xFFF542A7);
  static const _expenseStart = Color(0xFFFF8A3D);
  static const _expenseEnd = Color(0xFFF542A7);

  static const _balance = DashboardModePalette(
    incomeGradient: LinearGradient(colors: [_incomeStart, _incomeEnd]),
    expenseGradient: LinearGradient(colors: [_expenseStart, _expenseEnd]),
  );

  static DashboardModePalette resolve(DashboardModeSpec mode) {
    return switch (mode.mode) {
      DashboardMode.balance ||
      DashboardMode.budget ||
      DashboardMode.mind => _balance,
    };
  }

  static LinearGradient actionGradientFor(
    TransactionDirection direction, {
    DashboardModeSpec mode = DashboardModeSpec.balance,
  }) {
    final palette = resolve(mode);
    return switch (direction) {
      TransactionDirection.income => palette.incomeGradient,
      TransactionDirection.expense => palette.expenseGradient,
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
}
