import 'package:flutter/material.dart';

import '../slots/category_color_manager.dart';

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get nativeValue => switch (this) {
    TransactionType.income => 'income',
    TransactionType.expense => 'expense',
  };

  String get hungarianValue => switch (this) {
    TransactionType.income => 'bevétel',
    TransactionType.expense => 'kiadás',
  };

  String get label => switch (this) {
    TransactionType.income => 'Bevétel',
    TransactionType.expense => 'Kiadás',
  };

  static TransactionType fromAny(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'income' || normalized == 'bevétel') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}

class TransactionCategory {
  const TransactionCategory({
    required this.transactionCategoryID,
    required this.name,
    required this.type,
    required this.colorSlot,
    required this.iconSlot,
    required this.backgroundColor,
    required this.icon,
    required this.notification,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.isCustomIcon,
    required this.originalIcon,
  });

  final int transactionCategoryID;
  final String name;
  final String type;
  final int? colorSlot;
  final int? iconSlot;
  final String? backgroundColor;
  final String? icon;
  final String? notification;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final bool isCustomIcon;
  final String? originalIcon;

  TransactionType get normalizedType => TransactionTypeX.fromAny(type);

  String get slotColorHex {
    final slot = colorSlot;
    if (slot == null) {
      return backgroundColor ?? CategoryColorManager.fallbackHex;
    }
    return CategoryColorManager.hex(slot);
  }

  Color get slotColor => CategoryColorManager.fromHex(slotColorHex);

  factory TransactionCategory.fromMap(Map<dynamic, dynamic> map) {
    return TransactionCategory(
      transactionCategoryID: _int(map['transactionCategoryID']),
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'kiadás',
      colorSlot: _nullableInt(map['colorSlot']),
      iconSlot: _nullableInt(map['iconSlot']),
      backgroundColor: map['backgroundColor']?.toString(),
      icon: map['icon']?.toString(),
      notification: map['notification']?.toString(),
      hasLimit: _bool(map['hasLimit']),
      limitAmount: _double(map['limitAmount']),
      alertActive: _bool(map['alertActive']),
      isCustomIcon: _bool(map['isCustomIcon']),
      originalIcon: map['originalIcon']?.toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'transactionCategoryID': transactionCategoryID,
      'name': name,
      'type': type,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
      'backgroundColor': backgroundColor,
      'icon': icon,
      'notification': notification,
      'hasLimit': hasLimit,
      'limitAmount': limitAmount,
      'alertActive': alertActive,
      'isCustomIcon': isCustomIcon,
      'originalIcon': originalIcon,
    };
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _int(value);
double _double(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';
