import 'transaction_category.dart';

enum RecurringTriggerType {
  date,
  push;

  String get nativeValue => switch (this) {
    RecurringTriggerType.date => 'date',
    RecurringTriggerType.push => 'push',
  };

  String get label => switch (this) {
    RecurringTriggerType.date => 'Idő',
    RecurringTriggerType.push => 'Push',
  };

  static RecurringTriggerType fromAny(Object? value) {
    return value?.toString() == 'push'
        ? RecurringTriggerType.push
        : RecurringTriggerType.date;
  }
}

class PushRecurringSettings {
  const PushRecurringSettings({required this.conflictPolicy});

  final PushRecurringConflictPolicy conflictPolicy;

  factory PushRecurringSettings.defaults() {
    return const PushRecurringSettings(
      conflictPolicy: PushRecurringConflictPolicy.automaticBestMatch,
    );
  }

  factory PushRecurringSettings.fromMap(Map<dynamic, dynamic> map) {
    return PushRecurringSettings(
      conflictPolicy: PushRecurringConflictPolicyX.fromAny(
        map['conflictPolicy'],
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{'conflictPolicy': conflictPolicy.nativeValue};
  }
}

enum PushRecurringConflictPolicy { automaticBestMatch, askOnMultipleMatches }

extension PushRecurringConflictPolicyX on PushRecurringConflictPolicy {
  String get nativeValue => switch (this) {
    PushRecurringConflictPolicy.automaticBestMatch => 'automaticBestMatch',
    PushRecurringConflictPolicy.askOnMultipleMatches => 'askOnMultipleMatches',
  };

  static PushRecurringConflictPolicy fromAny(Object? value) {
    return value?.toString() == 'askOnMultipleMatches'
        ? PushRecurringConflictPolicy.askOnMultipleMatches
        : PushRecurringConflictPolicy.automaticBestMatch;
  }
}

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.triggerType,
    required this.transactionType,
    required this.name,
    required this.estimatedAmount,
    required this.expectedDayOfMonth,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIconSlot,
    required this.isActive,
    required this.appFilterText,
    required this.packageName,
    required this.appLabel,
    required this.sampleText,
    required this.includeKeyword,
    required this.amountPattern,
    required this.amountSelection,
    required this.merchantPattern,
    required this.merchantSelection,
    required this.dateToleranceDays,
    required this.amountTolerancePercent,
    required this.amountToleranceMin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringRule.fromMap(Map<dynamic, dynamic> map) {
    return RecurringRule(
      id: _int(map['id']),
      triggerType: RecurringTriggerType.fromAny(map['triggerType']),
      transactionType: TransactionTypeX.fromAny(map['transactionType']),
      name: map['name']?.toString() ?? '',
      estimatedAmount: _double(map['estimatedAmount']),
      expectedDayOfMonth: _int(map['expectedDayOfMonth']),
      categoryId: _int(map['categoryId']),
      categoryName: map['categoryName']?.toString() ?? '',
      categoryColor: map['categoryColor']?.toString() ?? '#64748b',
      categoryIconSlot: _int(map['categoryIconSlot']),
      isActive: _bool(map['isActive']),
      appFilterText: map['appFilterText']?.toString() ?? '',
      packageName: map['packageName']?.toString() ?? '',
      appLabel: map['appLabel']?.toString() ?? '',
      sampleText: map['sampleText']?.toString() ?? '',
      includeKeyword: map['includeKeyword']?.toString() ?? '',
      amountPattern: map['amountPattern']?.toString() ?? '',
      amountSelection: map['amountSelection']?.toString() ?? '',
      merchantPattern: map['merchantPattern']?.toString() ?? '',
      merchantSelection: map['merchantSelection']?.toString() ?? '',
      dateToleranceDays: _int(map['dateToleranceDays']),
      amountTolerancePercent: _double(map['amountTolerancePercent']),
      amountToleranceMin: _double(map['amountToleranceMin']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  final int id;
  final RecurringTriggerType triggerType;
  final TransactionType transactionType;
  final String name;
  final double estimatedAmount;
  final int expectedDayOfMonth;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final int categoryIconSlot;
  final bool isActive;
  final String appFilterText;
  final String packageName;
  final String appLabel;
  final String sampleText;
  final String includeKeyword;
  final String amountPattern;
  final String amountSelection;
  final String merchantPattern;
  final String merchantSelection;
  final int dateToleranceDays;
  final double amountTolerancePercent;
  final double amountToleranceMin;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RecurringRuleDraft {
  const RecurringRuleDraft({
    required this.triggerType,
    required this.transactionType,
    required this.name,
    required this.estimatedAmount,
    required this.expectedDayOfMonth,
    required this.categoryId,
    this.isActive = true,
    this.appFilterText = '',
    this.packageName = '',
    this.appLabel = '',
    this.sampleText = '',
    this.includeKeyword = '',
    this.amountPattern = '',
    this.amountSelection = '',
    this.merchantPattern = '',
    this.merchantSelection = '',
    this.dateToleranceDays = 5,
    this.amountTolerancePercent = 20,
    this.amountToleranceMin = 5000,
  });

  final RecurringTriggerType triggerType;
  final TransactionType transactionType;
  final String name;
  final double estimatedAmount;
  final int expectedDayOfMonth;
  final int categoryId;
  final bool isActive;
  final String appFilterText;
  final String packageName;
  final String appLabel;
  final String sampleText;
  final String includeKeyword;
  final String amountPattern;
  final String amountSelection;
  final String merchantPattern;
  final String merchantSelection;
  final int dateToleranceDays;
  final double amountTolerancePercent;
  final double amountToleranceMin;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'triggerType': triggerType.nativeValue,
      'transactionType': transactionType.nativeValue,
      'name': name,
      'estimatedAmount': estimatedAmount,
      'expectedDayOfMonth': expectedDayOfMonth,
      'categoryId': categoryId,
      'isActive': isActive,
      'appFilterText': appFilterText,
      'packageName': packageName,
      'appLabel': appLabel,
      'sampleText': sampleText,
      'includeKeyword': includeKeyword,
      'amountPattern': amountPattern,
      'amountSelection': amountSelection,
      'merchantPattern': merchantPattern,
      'merchantSelection': merchantSelection,
      'dateToleranceDays': dateToleranceDays,
      'amountTolerancePercent': amountTolerancePercent,
      'amountToleranceMin': amountToleranceMin,
    };
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == 'true';
}

DateTime _date(Object? value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
