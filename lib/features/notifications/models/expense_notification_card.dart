enum ExpenseNotificationType {
  recurringTransactionAlert('recurring_transaction_alert'),
  budgetAlert('budget_alert'),
  spendingLimit('spending_limit'),
  monthlyBudgetAlert('monthly_budget_alert'),
  system('system');

  const ExpenseNotificationType(this.nativeValue);
  final String nativeValue;

  static ExpenseNotificationType fromNative(String value) {
    return ExpenseNotificationType.values.firstWhere(
      (type) => type.nativeValue == value,
      orElse: () => ExpenseNotificationType.system,
    );
  }
}

class ExpenseNotificationCard {
  const ExpenseNotificationCard({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.isActive,
    required this.priority,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIconSlot,
    this.recurringTransactionId,
    this.transactionId,
    this.amount,
    this.triggerDate,
    this.nextDueDate,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final ExpenseNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isActive;
  final String priority;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final int? categoryIconSlot;
  final int? recurringTransactionId;
  final int? transactionId;
  final double? amount;
  final String? triggerDate;
  final String? nextDueDate;
  final int? createdAt;
  final int? updatedAt;

  String get monthKey =>
      '${timestamp.year.toString().padLeft(4, '0')}-${timestamp.month.toString().padLeft(2, '0')}';

  factory ExpenseNotificationCard.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseNotificationCard(
      id: _int(map['id']),
      type: ExpenseNotificationType.fromNative(
        map['type']?.toString() ?? 'system',
      ),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(_int(map['timestamp'])),
      isRead: map['isRead'] == true,
      isActive: map['isActive'] != false,
      priority: map['priority']?.toString() ?? 'normal',
      categoryId: _nullableInt(map['categoryId']),
      categoryName: map['categoryName']?.toString(),
      categoryColor: map['categoryColor']?.toString(),
      categoryIconSlot: _nullableInt(map['categoryIconSlot']),
      recurringTransactionId: _nullableInt(map['recurringTransactionId']),
      transactionId: _nullableInt(map['transactionId']),
      amount: _nullableDouble(map['amount']),
      triggerDate: map['triggerDate']?.toString(),
      nextDueDate: map['nextDueDate']?.toString(),
      createdAt: _nullableInt(map['createdAt']),
      updatedAt: _nullableInt(map['updatedAt']),
    );
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _int(value);
double? _nullableDouble(Object? value) => value == null
    ? null
    : (value is num ? value.toDouble() : double.parse(value.toString()));
