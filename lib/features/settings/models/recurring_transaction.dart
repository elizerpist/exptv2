import '../../transactions/models/transaction_category.dart';

class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.transactionType,
    required this.dayOfMonth,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIconSlot,
    required this.isActive,
    this.lastProcessedPeriodKey,
    this.lastProcessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringTransaction.fromMap(Map<dynamic, dynamic> map) {
    return RecurringTransaction(
      id: _int(map['id']),
      name: map['name']?.toString() ?? '',
      amount: _double(map['amount']),
      transactionType: TransactionTypeX.fromAny(map['transactionType']),
      dayOfMonth: _int(map['dayOfMonth']),
      categoryId: _int(map['categoryId']),
      categoryName: map['categoryName']?.toString() ?? '',
      categoryColor: map['categoryColor']?.toString() ?? '#64748b',
      categoryIconSlot: _int(map['categoryIconSlot']),
      isActive: _bool(map['isActive']),
      lastProcessedPeriodKey: map['lastProcessedPeriodKey']?.toString(),
      lastProcessedAt: _optionalDate(map['lastProcessedAt']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  final int id;
  final String name;
  final double amount;
  final TransactionType transactionType;
  final int dayOfMonth;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final int categoryIconSlot;
  final bool isActive;
  final String? lastProcessedPeriodKey;
  final DateTime? lastProcessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RecurringTransactionDraft {
  const RecurringTransactionDraft({
    required this.name,
    required this.amount,
    required this.transactionType,
    required this.dayOfMonth,
    required this.categoryId,
    this.isActive = true,
  });

  final String name;
  final double amount;
  final TransactionType transactionType;
  final int dayOfMonth;
  final int categoryId;
  final bool isActive;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'amount': amount,
      'transactionType': transactionType.nativeValue,
      'dayOfMonth': dayOfMonth,
      'categoryId': categoryId,
      'isActive': isActive,
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

DateTime _date(Object? value) => _optionalDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return DateTime.tryParse(value.toString());
}
