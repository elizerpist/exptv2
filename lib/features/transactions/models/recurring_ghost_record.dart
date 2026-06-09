import 'transaction_category.dart';
import 'transaction_record.dart';

class RecurringGhostRecord {
  const RecurringGhostRecord({
    required this.id,
    required this.recurringTransactionId,
    required this.periodKey,
    required this.name,
    required this.amount,
    this.triggerType = 'date',
    required this.transactionType,
    required this.date,
    required this.time,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIconSlot,
    required this.triggerMillis,
    required this.isActivated,
    required this.activatedTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int recurringTransactionId;
  final String periodKey;
  final String name;
  final double amount;
  final String triggerType;
  final String transactionType;
  final String date;
  final String time;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final int categoryIconSlot;
  final int triggerMillis;
  final bool isActivated;
  final int? activatedTransactionId;
  final int createdAt;
  final int updatedAt;

  TransactionType get type => TransactionTypeX.fromAny(transactionType);

  bool get isPushTriggered => triggerType == 'push';

  String get displayAmount =>
      '${type == TransactionType.income ? '+' : '-'}${formatHuf(amount.abs())}';

  String get displayTime {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  String get normalizedDate => date.replaceAll('.', '-');

  String get yearMonthKey => normalizedDate.length >= 7
      ? normalizedDate.substring(0, 7)
      : normalizedDate;

  factory RecurringGhostRecord.fromMap(Map<dynamic, dynamic> map) {
    return RecurringGhostRecord(
      id: _int(map['id']),
      recurringTransactionId: _int(map['recurringTransactionId']),
      periodKey: map['periodKey']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      amount: _double(map['amount']),
      triggerType: map['triggerTypeSnapshot']?.toString() ?? 'date',
      transactionType: map['transactionType']?.toString() ?? 'expense',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      categoryId: _int(map['categoryId']),
      categoryName: map['categoryName']?.toString() ?? '',
      categoryColor: map['categoryColor']?.toString() ?? '',
      categoryIconSlot: _int(map['categoryIconSlot']),
      triggerMillis: _int(map['triggerMillis']),
      isActivated: _bool(map['isActivated']),
      activatedTransactionId: _nullableInt(map['activatedTransactionId']),
      createdAt: _int(map['createdAt']),
      updatedAt: _int(map['updatedAt']),
    );
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _int(value);
double _double(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';
