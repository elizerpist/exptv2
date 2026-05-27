import 'package:flutter/widgets.dart';

class CategoryIconManager {
  const CategoryIconManager._();

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

  static String assetPath(int? slot) {
    final normalized = slots.contains(slot) ? slot! : 0;
    final suffix = normalized.toString().padLeft(2, '0');
    return 'assets/category_icons/slot_$suffix.png';
  }

  static AssetImage assetImage(int? slot) => AssetImage(assetPath(slot));
}
