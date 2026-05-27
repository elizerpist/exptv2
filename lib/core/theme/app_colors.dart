import 'package:flutter/material.dart';

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

  static const slotColorHexes = <int, String>{
    0: '#ef4444',
    1: '#f97316',
    2: '#eab308',
    3: '#84cc16',
    4: '#22c55e',
    5: '#10b981',
    6: '#06b6d4',
    7: '#0ea5e9',
    8: '#3b82f6',
    9: '#6366f1',
    10: '#8b5cf6',
    11: '#a855f7',
    12: '#d946ef',
    13: '#ec4899',
    14: '#f43f5e',
    15: '#6b7280',
    16: '#374151',
    17: '#1f2937',
    18: '#064e3b',
    19: '#7c2d12',
    20: '#4c1d95',
  };

  static Color slotColor(int slot) => fromHex(slotColorHex(slot));

  static String slotColorHex(int slot) => slotColorHexes[slot] ?? '#64748b';

  static Color fromHex(String value) {
    final clean = value.replaceFirst('#', '');
    return Color(int.parse('ff$clean', radix: 16));
  }
}
