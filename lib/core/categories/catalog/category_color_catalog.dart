// GENERATED FILE. Edit assets/category_catalog/category_catalog.json instead.
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CategoryGradientToken {
  const CategoryGradientToken({
    required this.id,
    required this.colorA,
    required this.middleColor,
    required this.colorB,
    required this.angleDegrees,
  });

  final String id;
  final Color colorA;
  final Color middleColor;
  final Color colorB;
  final double angleDegrees;

  List<Color> get colors => <Color>[colorA, middleColor, colorB];

  LinearGradient get gradient => LinearGradient(
    colors: colors,
    stops: const <double>[0, 0.52, 1],
    transform: GradientRotation((90 - angleDegrees) * math.pi / 180),
  );
}

abstract final class CategoryColorCatalog {
  static const CategoryGradientToken fallback = CategoryGradientToken(
    id: 'fallback',
    colorA: Color(0xFF64748B),
    middleColor: Color(0xFF7C8CA3),
    colorB: Color(0xFF94A3B8),
    angleDegrees: 135,
  );

  static const Map<String, CategoryGradientToken> values =
      <String, CategoryGradientToken>{
        "color_01": CategoryGradientToken(
          id: "color_01",
          colorA: Color(0xFFFF3B4F),
          middleColor: Color(0xFFFF5268),
          colorB: Color(0xFFFF6B7D),
          angleDegrees: 135,
        ),
        "color_02": CategoryGradientToken(
          id: "color_02",
          colorA: Color(0xFFFF5733),
          middleColor: Color(0xFFFF7043),
          colorB: Color(0xFFFF8A50),
          angleDegrees: 125,
        ),
        "color_03": CategoryGradientToken(
          id: "color_03",
          colorA: Color(0xFFFF8C1A),
          middleColor: Color(0xFFFFA12B),
          colorB: Color(0xFFFFB340),
          angleDegrees: 145,
        ),
        "color_04": CategoryGradientToken(
          id: "color_04",
          colorA: Color(0xFFF7B500),
          middleColor: Color(0xFFFFC233),
          colorB: Color(0xFFFFD15C),
          angleDegrees: 135,
        ),
        "color_05": CategoryGradientToken(
          id: "color_05",
          colorA: Color(0xFFF4DF24),
          middleColor: Color(0xFFF7EA45),
          colorB: Color(0xFFFFF06A),
          angleDegrees: 125,
        ),
        "color_06": CategoryGradientToken(
          id: "color_06",
          colorA: Color(0xFFD4F52F),
          middleColor: Color(0xFFB7EA2A),
          colorB: Color(0xFF98DC3F),
          angleDegrees: 145,
        ),
        "color_07": CategoryGradientToken(
          id: "color_07",
          colorA: Color(0xFF7DD943),
          middleColor: Color(0xFF5BD265),
          colorB: Color(0xFF3CCF7D),
          angleDegrees: 135,
        ),
        "color_08": CategoryGradientToken(
          id: "color_08",
          colorA: Color(0xFF35C76E),
          middleColor: Color(0xFF24C889),
          colorB: Color(0xFF18BA78),
          angleDegrees: 125,
        ),
        "color_09": CategoryGradientToken(
          id: "color_09",
          colorA: Color(0xFF15BD6F),
          middleColor: Color(0xFF12B980),
          colorB: Color(0xFF13AD8E),
          angleDegrees: 145,
        ),
        "color_10": CategoryGradientToken(
          id: "color_10",
          colorA: Color(0xFF18C99A),
          middleColor: Color(0xFF19C0AA),
          colorB: Color(0xFF1BB6B8),
          angleDegrees: 135,
        ),
        "color_11": CategoryGradientToken(
          id: "color_11",
          colorA: Color(0xFF1AC3C8),
          middleColor: Color(0xFF1BB7D2),
          colorB: Color(0xFF22ABD8),
          angleDegrees: 125,
        ),
        "color_12": CategoryGradientToken(
          id: "color_12",
          colorA: Color(0xFF22D3EE),
          middleColor: Color(0xFF2BC4F3),
          colorB: Color(0xFF39B8F4),
          angleDegrees: 145,
        ),
        "color_13": CategoryGradientToken(
          id: "color_13",
          colorA: Color(0xFF38AEF8),
          middleColor: Color(0xFF3B9DF5),
          colorB: Color(0xFF418CF0),
          angleDegrees: 135,
        ),
        "color_14": CategoryGradientToken(
          id: "color_14",
          colorA: Color(0xFF3D7EF2),
          middleColor: Color(0xFF496DEB),
          colorB: Color(0xFF555EE4),
          angleDegrees: 125,
        ),
        "color_15": CategoryGradientToken(
          id: "color_15",
          colorA: Color(0xFF4F63E6),
          middleColor: Color(0xFF5A55DF),
          colorB: Color(0xFF6548D6),
          angleDegrees: 145,
        ),
        "color_16": CategoryGradientToken(
          id: "color_16",
          colorA: Color(0xFF6750E8),
          middleColor: Color(0xFF7546DC),
          colorB: Color(0xFF843BD0),
          angleDegrees: 135,
        ),
        "color_17": CategoryGradientToken(
          id: "color_17",
          colorA: Color(0xFF7C4DFF),
          middleColor: Color(0xFF8B45ED),
          colorB: Color(0xFF9A3DDB),
          angleDegrees: 125,
        ),
        "color_18": CategoryGradientToken(
          id: "color_18",
          colorA: Color(0xFF9B5CF6),
          middleColor: Color(0xFFA94EE6),
          colorB: Color(0xFFB841D5),
          angleDegrees: 145,
        ),
        "color_19": CategoryGradientToken(
          id: "color_19",
          colorA: Color(0xFFA855F7),
          middleColor: Color(0xFFB84CE0),
          colorB: Color(0xFFC43DD0),
          angleDegrees: 135,
        ),
        "color_20": CategoryGradientToken(
          id: "color_20",
          colorA: Color(0xFFCB3ED6),
          middleColor: Color(0xFFD932C9),
          colorB: Color(0xFFE427BD),
          angleDegrees: 125,
        ),
        "color_21": CategoryGradientToken(
          id: "color_21",
          colorA: Color(0xFFE43EC4),
          middleColor: Color(0xFFF04AB6),
          colorB: Color(0xFFFB56A8),
          angleDegrees: 145,
        ),
      };

  static CategoryGradientToken resolve(String colorId) =>
      values[colorId] ?? fallback;

  static bool contains(String colorId) => values.containsKey(colorId);

  static List<CategoryGradientToken> get all =>
      List<CategoryGradientToken>.unmodifiable(values.values);
}
