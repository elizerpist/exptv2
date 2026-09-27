import 'package:flutter/material.dart';

/// The reference-locked visual language for the two Category Movers pages.
/// Keeping these values semantic and centralized prevents page/painter drift.
abstract final class BalanceCategoryMoversVisualTokens {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF14213A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color hairline = Color(0xFFE7EAF1);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA879FF);
  static const Color negative = Color(0xFFFF2E7D);
  static const Color positive = Color(0xFF16B981);
  static const Color referenceSeries = Color(0xFF91A0B6);
  static const Color lavenderSurface = Color(0xFFF7F3FF);
  static const Color selectedPeriodSurface = Color(0xFFF5F0FF);
  static const Color negativeSurface = Color(0xFFFFF1F6);
  static const Color positiveSurface = Color(0xFFEFFBF6);
  static const Color unselectedSegmentSurface = Color(0xFFF0F1F6);
  static const LinearGradient selectedSegmentGradient = LinearGradient(
    colors: <Color>[purple, Color(0xFF8B5CF6)],
  );
  static const LinearGradient upperDecorationGradient = LinearGradient(
    colors: <Color>[Color(0x12A879FF), Color(0x087C3AED), Color(0x00FFFFFF)],
  );

  static const double horizontalInset = 14;
  static const double outerRadius = 22;
  static const double titleSize = 18;
  static const double rowHeight = 46;
}
