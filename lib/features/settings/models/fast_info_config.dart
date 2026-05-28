enum FastInfoSlotType {
  pill('pill'),
  box('box');

  const FastInfoSlotType(this.nativeValue);
  final String nativeValue;

  static FastInfoSlotType fromAny(Object? value) {
    return value?.toString() == 'box' ? FastInfoSlotType.box : FastInfoSlotType.pill;
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
  });

  factory FastInfoSlot.fromMap(Map<dynamic, dynamic> map) {
    return FastInfoSlot(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      extra: map['extra']?.toString(),
      progress: _double(map['progress']),
      type: FastInfoSlotType.fromAny(map['type']),
    );
  }

  final String id;
  final String label;
  final String value;
  final String? extra;
  final double? progress;
  final FastInfoSlotType type;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'value': value,
      if (extra != null) 'extra': extra,
      if (progress != null) 'progress': progress,
      'type': type.nativeValue,
    };
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class FastInfoConfig {
  FastInfoConfig({required List<FastInfoSlot?> pills, required List<FastInfoSlot?> boxes})
    : pills = _fixed(pills),
      boxes = _fixed(boxes);

  factory FastInfoConfig.defaults() {
    return FastInfoConfig(
      pills: const <FastInfoSlot?>[
        FastInfoSlot(
          id: 'megtakaritas',
          label: 'Megtakarítás',
          value: '156,780 Ft',
          type: FastInfoSlotType.pill,
        ),
        null,
        null,
      ],
      boxes: const <FastInfoSlot?>[
        FastInfoSlot(
          id: 'mai_nap',
          label: 'Mai nap',
          value: '2 db',
          extra: '-4,500 Ft',
          type: FastInfoSlotType.box,
        ),
        FastInfoSlot(
          id: 'havi_limit',
          label: 'Havi limit',
          value: '180k / 200k',
          progress: 0.9,
          type: FastInfoSlotType.box,
        ),
        FastInfoSlot(
          id: 'trend',
          label: 'Trend',
          value: '+12%',
          type: FastInfoSlotType.box,
        ),
      ],
    );
  }

  factory FastInfoConfig.fromMap(Map<dynamic, dynamic> map) {
    return FastInfoConfig(
      pills: _slots(map['pills']),
      boxes: _slots(map['boxes']),
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

  static List<FastInfoSlot?> _slots(Object? value) {
    if (value is! List) return const <FastInfoSlot?>[null, null, null];
    return value.map((item) {
      if (item is Map<dynamic, dynamic>) return FastInfoSlot.fromMap(item);
      return null;
    }).toList();
  }

  static List<FastInfoSlot?> _fixed(List<FastInfoSlot?> values) {
    final fixed = List<FastInfoSlot?>.from(values.take(3));
    while (fixed.length < 3) {
      fixed.add(null);
    }
    return List.unmodifiable(fixed);
  }
}
