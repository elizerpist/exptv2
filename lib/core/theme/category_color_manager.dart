import 'package:flutter/material.dart';

class CategoryColorManager {
  const CategoryColorManager._();

  static const fallbackHex = '#64748b';

  static const hexes = <int, String>{
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

  static const slots = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
  ];

  static String hex(int? slot) => hexes[slot] ?? fallbackHex;

  static Color color(int? slot) => fromHex(hex(slot));

  static Color fromHex(String value) {
    final clean = value.replaceFirst('#', '').trim();
    if (clean.length != 6) return fromHex(fallbackHex);
    final parsed = int.tryParse('ff$clean', radix: 16);
    return Color(
      parsed ?? int.parse('ff${fallbackHex.substring(1)}', radix: 16),
    );
  }
}
