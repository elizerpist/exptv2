import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryIconOption {
  const CategoryIconOption(this.name);

  final String name;

  String get assetPath => 'assets/icons/lucide/$name.svg';
}

class CategoryIconManager {
  const CategoryIconManager._();

  static const _preferencesKey = 'categoryIconSlots.v1';

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

  static const iconOptions = <CategoryIconOption>[
    CategoryIconOption('shirt'),
    CategoryIconOption('shopping-cart'),
    CategoryIconOption('handbag'),
    CategoryIconOption('ambulance'),
    CategoryIconOption('beer'),
    CategoryIconOption('briefcase-business'),
    CategoryIconOption('bitcoin'),
    CategoryIconOption('broccoli'),
    CategoryIconOption('bus-front'),
    CategoryIconOption('factory'),
    CategoryIconOption('plane'),
    CategoryIconOption('car-taxi-front'),
    CategoryIconOption('fuel'),
    CategoryIconOption('paw-print'),
    CategoryIconOption('hamburger'),
    CategoryIconOption('lightbulb'),
    CategoryIconOption('dollar-sign'),
    CategoryIconOption('hospital'),
    CategoryIconOption('piggy-bank'),
    CategoryIconOption('clover'),
    CategoryIconOption('drama'),
    CategoryIconOption('gamepad-2'),
    CategoryIconOption('cross'),
    CategoryIconOption('dumbbell'),
    CategoryIconOption('clapperboard'),
    CategoryIconOption('gift'),
    CategoryIconOption('house'),
    CategoryIconOption('ghost'),
    CategoryIconOption('heart'),
    CategoryIconOption('music-4'),
    CategoryIconOption('graduation-cap'),
    CategoryIconOption('baby'),
    CategoryIconOption('hand-metal'),
    CategoryIconOption('coffee'),
    CategoryIconOption('utensils'),
    CategoryIconOption('wine'),
    CategoryIconOption('apple'),
    CategoryIconOption('luggage'),
    CategoryIconOption('parasol'),
    CategoryIconOption('palette'),
    CategoryIconOption('wrench'),
    CategoryIconOption('book-open-text'),
    CategoryIconOption('store'),
    CategoryIconOption('wand-sparkles'),
    CategoryIconOption('gem'),
    CategoryIconOption('plug-2'),
    CategoryIconOption('chart-candlestick'),
    CategoryIconOption('tent'),
    CategoryIconOption('crown'),
    CategoryIconOption('zap'),
    CategoryIconOption('fingerprint-pattern'),
    CategoryIconOption('trophy'),
    CategoryIconOption('radiation'),
    CategoryIconOption('pizza'),
    CategoryIconOption('skull'),
    CategoryIconOption('rocket'),
    CategoryIconOption('hand-coins'),
    CategoryIconOption('banknote'),
    CategoryIconOption('thumbs-up'),
    CategoryIconOption('eye-closed'),
  ];

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static ValueListenable<int> get revision => _revision;

  static Map<int, String> _slotIconNames = _defaultSlotIconNames();

  static String iconNameForSlot(int? slot) {
    final normalized = _normalizeSlot(slot);
    return _slotIconNames[normalized] ?? _defaultIconNameForSlot(normalized);
  }

  static String assetPath(int? slot) =>
      assetPathForIconName(iconNameForSlot(slot));

  static String assetPathForIconName(String iconName) {
    final option = iconOptions.firstWhere(
      (option) => option.name == iconName,
      orElse: () => iconOptions.first,
    );
    return option.assetPath;
  }

  static bool containsIconName(String iconName) {
    return iconOptions.any((option) => option.name == iconName);
  }

  static Future<void> load({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferencesKey);
    if (raw == null || raw.isEmpty) return;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    final next = _defaultSlotIconNames();
    for (final entry in decoded.entries) {
      final slot = int.tryParse(entry.key);
      final iconName = entry.value;
      if (slot == null || !slots.contains(slot) || iconName is! String) {
        continue;
      }
      if (!containsIconName(iconName)) continue;
      next[slot] = iconName;
    }

    _slotIconNames = next;
    _notifyChanged();
  }

  static Future<void> assignIconToSlot(
    int slot,
    String iconName, {
    SharedPreferences? preferences,
  }) async {
    final normalized = _normalizeSlot(slot);
    if (!containsIconName(iconName)) {
      throw ArgumentError.value(iconName, 'iconName', 'Unknown category icon');
    }

    _slotIconNames = {..._slotIconNames, normalized: iconName};
    _notifyChanged();

    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, jsonEncode(_encodedAssignments()));
  }

  @visibleForTesting
  static void resetForTests() {
    _slotIconNames = _defaultSlotIconNames();
    _notifyChanged();
  }

  static int _normalizeSlot(int? slot) {
    return slots.contains(slot) ? slot! : 0;
  }

  static String _defaultIconNameForSlot(int slot) {
    return iconOptions[slot].name;
  }

  static Map<int, String> _defaultSlotIconNames() {
    return {for (final slot in slots) slot: _defaultIconNameForSlot(slot)};
  }

  static Map<String, String> _encodedAssignments() {
    return {
      for (final entry in _slotIconNames.entries) '${entry.key}': entry.value,
    };
  }

  static void _notifyChanged() {
    _revision.value = _revision.value + 1;
  }
}
