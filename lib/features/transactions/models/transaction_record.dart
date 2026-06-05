import 'transaction_category.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.merchant,
    required this.amount,
    required this.userAssignedName,
    required this.transactionCategoryID,
    this.recurringTransactionId,
  });

  final int id;
  final String date;
  final String time;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String merchant;
  final double amount;
  final String? userAssignedName;
  final int transactionCategoryID;
  final int? recurringTransactionId;

  TransactionType get type =>
      amount > 0 ? TransactionType.income : TransactionType.expense;

  bool get isRecurringGenerated =>
      recurringTransactionId != null && recurringTransactionId! > 0;

  String get displayMerchant => (userAssignedName?.trim().isNotEmpty ?? false)
      ? userAssignedName!.trim()
      : merchant.trim();

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

  String get displayAmount =>
      '${type == TransactionType.income ? '+' : '-'}${formatHuf(amount.abs())}';

  factory TransactionRecord.fromMap(Map<dynamic, dynamic> map) {
    return TransactionRecord(
      id: _int(map['id']),
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      latitude: _nullableDouble(map['latitude']),
      longitude: _nullableDouble(map['longitude']),
      address: map['address']?.toString(),
      merchant: map['merchant']?.toString() ?? '',
      amount: _double(map['amount']),
      userAssignedName: map['userAssignedName']?.toString(),
      transactionCategoryID: _int(map['transactionCategoryID']),
      recurringTransactionId: _nullableInt(map['recurringTransactionId']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'merchant': merchant,
      'amount': amount,
      'userAssignedName': userAssignedName,
      'transactionCategoryID': transactionCategoryID,
      if (recurringTransactionId != null)
        'recurringTransactionId': recurringTransactionId,
    };
  }
}

String formatHuf(num amount) {
  final rounded = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i += 1) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(' ');
  }
  return '${buffer.toString()} Ft';
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
double _double(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
double? _nullableDouble(Object? value) => value == null ? null : _double(value);
int? _nullableInt(Object? value) => value == null ? null : _int(value);
