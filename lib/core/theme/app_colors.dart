import 'package:flutter/material.dart';

import 'category_color_manager.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF06B6D4);
  static const primaryDark = Color(0xFF0891B2);
  static const primaryLight = Color(0xFF67E8F9);
  static const primaryActiveBackground = Color(0x1506B6D4);

  static const white = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);

  static const income = Color(0xFF22C55E);
  static const expense = Color(0xFFEF4444);

  static const navShadow = Color(0x33000000);
  static const fabShadow = Color(0x40000000);

  static const slotColorHexes = CategoryColorManager.hexes;

  static Color slotColor(int slot) => CategoryColorManager.color(slot);

  static String slotColorHex(int slot) => CategoryColorManager.hex(slot);

  static Color fromHex(String value) => CategoryColorManager.fromHex(value);
}
