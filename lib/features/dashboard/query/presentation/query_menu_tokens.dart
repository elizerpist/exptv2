import 'package:flutter/material.dart';

/// Query-specific translation of the accepted HTML layout contract.
///
/// These values intentionally do not mutate dashboard-wide visual tokens:
/// they describe the transient composer sheet only.
abstract final class QueryMenuTokens {
  static const Color sheet = Color(0xFFFFFFFF);
  static const Color sectionSurface = Color(0xFFFAFBFE);
  static const Color controlSurface = Color(0xFFF3F6FB);
  static const Color controlSurfacePressed = Color(0xFFEAF0F9);
  static const Color borderSoft = Color(0x1430405A);
  static const Color textPrimary = Color(0xFF172554);
  static const Color textSecondary = Color(0xFF68778D);
  static const Color textAccent = Color(0xFF2878F0);
  static const Color selectionStart = Color(0xFF247EF3);
  static const Color selectionEnd = Color(0xFF7659F1);
  static const Color actionStart = Color(0xFF715EFB);
  static const Color actionEnd = Color(0xFFE478C3);
  static const Color scrim = Color(0x8F0D172E);

  static const LinearGradient selectionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[selectionStart, selectionEnd],
  );
  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[actionStart, actionEnd],
  );

  static const double screenInset = 16;
  static const double sectionGap = 24;
  static const double sectionRadius = 24;
  static const double controlRadius = 16;
  static const double chipRadius = 17;
  static const Duration morphDuration = Duration(milliseconds: 260);
  static const Duration contentDuration = Duration(milliseconds: 180);
  static const Curve sheetCurve = Cubic(0.2, 0.85, 0.25, 1);

  static const BoxShadow surfaceShadow = BoxShadow(
    color: Color(0x0D233755),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static const BoxShadow controlShadow = BoxShadow(
    color: Color(0x09233755),
    blurRadius: 12,
    offset: Offset(0, 3),
  );
}
