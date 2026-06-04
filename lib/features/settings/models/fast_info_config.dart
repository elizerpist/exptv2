import 'fast_info_card_catalog.dart';

enum FastInfoSlotType {
  pill('pill'),
  box('box');

  const FastInfoSlotType(this.nativeValue);
  final String nativeValue;

  static FastInfoSlotType fromAny(Object? value) {
    return value?.toString() == 'box'
        ? FastInfoSlotType.box
        : FastInfoSlotType.pill;
  }
}

class FastInfoSlot {
  const FastInfoSlot({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    this.extra,
    this.progress,
    this.pillValue,
    this.boxValue,
    this.boxSubtitle,
    this.visualType = FastInfoVisualType.plain,
  });

  factory FastInfoSlot.fromCard(
    FastInfoCardDefinition card,
    FastInfoSlotType type,
  ) {
    return FastInfoSlot(
      id: card.id,
      label: card.title,
      value: '',
      type: type,
      extra: null,
      progress: null,
      pillValue: null,
      boxValue: null,
      boxSubtitle: null,
      visualType: FastInfoVisualType.plain,
    );
  }

  factory FastInfoSlot.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final catalogCard = fastInfoCardById(id);
    final type = FastInfoSlotType.fromAny(map['type']);
    if (catalogCard != null) {
      final catalogSlot = FastInfoSlot.fromCard(catalogCard, type);
      return FastInfoSlot(
        id: id,
        label: map['label']?.toString() ?? catalogSlot.label,
        value: map['value']?.toString() ?? catalogSlot.value,
        extra: map['extra']?.toString() ?? catalogSlot.extra,
        progress: _double(map['progress']) ?? catalogSlot.progress,
        type: type,
        pillValue: map['pillValue']?.toString() ?? catalogSlot.pillValue,
        boxValue: map['boxValue']?.toString() ?? catalogSlot.boxValue,
        boxSubtitle: map['boxSubtitle']?.toString() ?? catalogSlot.boxSubtitle,
        visualType: FastInfoVisualType.fromAny(
          map['visualType'] ?? catalogSlot.visualType.nativeValue,
        ),
      );
    }
    return FastInfoSlot(
      id: id,
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      extra: map['extra']?.toString(),
      progress: _double(map['progress']),
      type: type,
      pillValue: map['pillValue']?.toString(),
      boxValue: map['boxValue']?.toString(),
      boxSubtitle: map['boxSubtitle']?.toString(),
      visualType: FastInfoVisualType.fromAny(map['visualType']),
    );
  }

  final String id;
  final String label;
  final String value;
  final String? extra;
  final double? progress;
  final FastInfoSlotType type;
  final String? pillValue;
  final String? boxValue;
  final String? boxSubtitle;
  final FastInfoVisualType visualType;

  FastInfoSlot asType(FastInfoSlotType nextType) {
    final card = fastInfoCardById(id);
    if (card != null) return FastInfoSlot.fromCard(card, nextType);
    return FastInfoSlot(
      id: id,
      label: label,
      value: nextType == FastInfoSlotType.pill
          ? (pillValue ?? value)
          : (boxValue ?? value),
      extra: boxSubtitle ?? extra,
      progress: progress,
      type: nextType,
      pillValue: pillValue,
      boxValue: boxValue,
      boxSubtitle: boxSubtitle,
      visualType: visualType,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'value': value,
      if (extra != null) 'extra': extra,
      if (progress != null) 'progress': progress,
      'type': type.nativeValue,
      if (pillValue != null) 'pillValue': pillValue,
      if (boxValue != null) 'boxValue': boxValue,
      if (boxSubtitle != null) 'boxSubtitle': boxSubtitle,
      'visualType': visualType.nativeValue,
    };
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class FastInfoConfig {
  FastInfoConfig({
    required List<FastInfoSlot?> pills,
    required List<FastInfoSlot?> boxes,
  }) : pills = _fixed(pills),
       boxes = _fixed(boxes);

  factory FastInfoConfig.defaults() {
    return FastInfoConfig(
      pills: defaultFastInfoPillCardIds
          .map(
            (id) => FastInfoSlot.fromCard(
              fastInfoCardById(id)!,
              FastInfoSlotType.pill,
            ),
          )
          .toList(),
      boxes: defaultFastInfoBoxCardIds
          .map(
            (id) => FastInfoSlot.fromCard(
              fastInfoCardById(id)!,
              FastInfoSlotType.box,
            ),
          )
          .toList(),
    );
  }

  factory FastInfoConfig.fromMap(Map<dynamic, dynamic> map) {
    final seen = <String>{};

    FastInfoSlot? migrate(Object? raw, FastInfoSlotType type) {
      if (raw is! Map<dynamic, dynamic>) return null;
      final id = canonicalFastInfoCardId(raw['id']?.toString() ?? '');
      if (id == null || !seen.add(id)) return null;
      return FastInfoSlot.fromCard(fastInfoCardById(id)!, type);
    }

    final rawPills = _rawFixedSlots(map['pills']);
    final rawBoxes = _rawFixedSlots(map['boxes']);
    return FastInfoConfig(
      pills: [for (final raw in rawPills) migrate(raw, FastInfoSlotType.pill)],
      boxes: [for (final raw in rawBoxes) migrate(raw, FastInfoSlotType.box)],
    );
  }

  final List<FastInfoSlot?> pills;
  final List<FastInfoSlot?> boxes;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'pills': pills.map((slot) => slot?.toMap()).toList(),
      'boxes': boxes.map((slot) => slot?.toMap()).toList(),
    };
  }

  static List<Object?> _rawFixedSlots(Object? value) {
    final fixed = value is List
        ? List<Object?>.from(value.take(3))
        : <Object?>[];
    while (fixed.length < 3) {
      fixed.add(null);
    }
    return fixed;
  }

  static List<FastInfoSlot?> _fixed(List<FastInfoSlot?> values) {
    final fixed = List<FastInfoSlot?>.from(values.take(3));
    while (fixed.length < 3) {
      fixed.add(null);
    }
    return List.unmodifiable(fixed);
  }
}
