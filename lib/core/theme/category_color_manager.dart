import 'package:flutter/material.dart';

class CategoryColorManager {
  const CategoryColorManager._();

  static const fallbackHex = '#64748b';

  static const hexes = <int, String>{
    0: '#ff5268',
    1: '#ff7043',
    2: '#ffa12b',
    3: '#ffc233',
    4: '#f7ea45',
    5: '#b7ea2a',
    6: '#5bd265',
    7: '#24c889',
    8: '#12b980',
    9: '#19c0aa',
    10: '#1bb7d2',
    11: '#2bc4f3',
    12: '#3b9df5',
    13: '#496deb',
    14: '#5a55df',
    15: '#7546dc',
    16: '#8b45ed',
    17: '#a94ee6',
    18: '#b84ce0',
    19: '#d932c9',
    20: '#f04ab6',
  };

  static const gradientHexes = <int, List<String>>{
    0: ['#ff3b4f', '#ff5268', '#ff6b7d'],
    1: ['#ff5733', '#ff7043', '#ff8a50'],
    2: ['#ff8c1a', '#ffa12b', '#ffb340'],
    3: ['#f7b500', '#ffc233', '#ffd15c'],
    4: ['#f4df24', '#f7ea45', '#fff06a'],
    5: ['#d4f52f', '#b7ea2a', '#98dc3f'],
    6: ['#7dd943', '#5bd265', '#3ccf7d'],
    7: ['#35c76e', '#24c889', '#18ba78'],
    8: ['#15bd6f', '#12b980', '#13ad8e'],
    9: ['#18c99a', '#19c0aa', '#1bb6b8'],
    10: ['#1ac3c8', '#1bb7d2', '#22abd8'],
    11: ['#22d3ee', '#2bc4f3', '#39b8f4'],
    12: ['#38aef8', '#3b9df5', '#418cf0'],
    13: ['#3d7ef2', '#496deb', '#555ee4'],
    14: ['#4f63e6', '#5a55df', '#6548d6'],
    15: ['#6750e8', '#7546dc', '#843bd0'],
    16: ['#7c4dff', '#8b45ed', '#9a3ddb'],
    17: ['#9b5cf6', '#a94ee6', '#b841d5'],
    18: ['#a855f7', '#b84ce0', '#c43dd0'],
    19: ['#cb3ed6', '#d932c9', '#e427bd'],
    20: ['#e43ec4', '#f04ab6', '#fb56a8'],
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

  static List<Color> gradientStops(int? slot) {
    final stops = gradientHexes[slot];
    if (stops == null) {
      return <Color>[fromHex(fallbackHex), fromHex(fallbackHex)];
    }
    return List<Color>.unmodifiable(stops.map(fromHex));
  }

  static LinearGradient gradient(int? slot) {
    final colors = gradientStops(slot);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: colors.length == 3 ? const <double>[0, 0.52, 1] : null,
    );
  }

  static Color fromHex(String value) {
    final clean = value.replaceFirst('#', '').trim();
    if (clean.length != 6) return fromHex(fallbackHex);
    final parsed = int.tryParse('ff$clean', radix: 16);
    return Color(
      parsed ?? int.parse('ff${fallbackHex.substring(1)}', radix: 16),
    );
  }

  static String toHex(Color color) {
    final value = color.toARGB32() & 0x00ffffff;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }
}
