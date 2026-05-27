enum LimitTargetType { overview, category }

enum LimitWindow { monthly, yearly, allTime }

extension LimitTargetTypeX on LimitTargetType {
  String get nativeValue => switch (this) {
    LimitTargetType.overview => 'overview',
    LimitTargetType.category => 'category',
  };

  static LimitTargetType fromAny(Object? value) {
    return value?.toString() == 'overview'
        ? LimitTargetType.overview
        : LimitTargetType.category;
  }
}

extension LimitWindowX on LimitWindow {
  String get nativeValue => switch (this) {
    LimitWindow.monthly => 'monthly',
    LimitWindow.yearly => 'yearly',
    LimitWindow.allTime => 'all_time',
  };

  static LimitWindow fromAny(Object? value) {
    return switch (value?.toString()) {
      'monthly' => LimitWindow.monthly,
      'yearly' => LimitWindow.yearly,
      'all_time' || 'allTime' || 'sum' => LimitWindow.allTime,
      _ => LimitWindow.allTime,
    };
  }
}

class CategoryLimit {
  const CategoryLimit({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.transactionType,
    required this.window,
    required this.periodKey,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final LimitTargetType targetType;
  final int targetId;
  final String transactionType;
  final LimitWindow window;
  final String periodKey;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final int createdAt;
  final int updatedAt;

  factory CategoryLimit.fromMap(Map<dynamic, dynamic> map) {
    return CategoryLimit(
      id: _int(map['id']),
      targetType: LimitTargetTypeX.fromAny(map['targetType']),
      targetId: _int(map['targetId']),
      transactionType: map['transactionType']?.toString() ?? 'expense',
      window: LimitWindowX.fromAny(map['window']),
      periodKey: map['periodKey']?.toString() ?? 'all',
      hasLimit: _bool(map['hasLimit']),
      limitAmount: _double(map['limitAmount']),
      alertActive: _bool(map['alertActive']),
      createdAt: _int(map['createdAt']),
      updatedAt: _int(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'targetType': targetType.nativeValue,
      'targetId': targetId,
      'transactionType': transactionType,
      'window': window.nativeValue,
      'periodKey': periodKey,
      'hasLimit': hasLimit,
      'limitAmount': limitAmount,
      'alertActive': alertActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
double _double(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';
