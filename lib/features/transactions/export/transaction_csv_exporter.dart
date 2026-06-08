import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionCsvExporter {
  const TransactionCsvExporter();

  static const headers = <String>[
    'id',
    'date',
    'time',
    'type',
    'amount',
    'merchant',
    'userAssignedName',
    'categoryId',
    'category',
    'address',
    'latitude',
    'longitude',
    'recurring',
  ];

  String buildCsv({
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
  }) {
    final categoriesById = {
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    final buffer = StringBuffer()..writeln(headers.join(','));
    for (final transaction in transactions) {
      buffer.writeln(
        [
          transaction.id,
          transaction.date,
          transaction.displayTime,
          transaction.type.nativeValue,
          _amount(transaction.amount),
          transaction.merchant,
          transaction.userAssignedName,
          transaction.transactionCategoryID,
          categoriesById[transaction.transactionCategoryID]?.name ?? '',
          transaction.address,
          transaction.latitude,
          transaction.longitude,
          transaction.isRecurringGenerated,
        ].map(_field).join(','),
      );
    }
    return buffer.toString();
  }

  String _amount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  String _field(Object? value) {
    final raw = value?.toString() ?? '';
    if (!raw.contains(',') && !raw.contains('"') && !raw.contains('\n')) {
      return raw;
    }
    return '"${raw.replaceAll('"', '""')}"';
  }
}
