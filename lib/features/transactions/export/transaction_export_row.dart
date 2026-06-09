import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionExportRow {
  const TransactionExportRow({
    required this.id,
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
    required this.merchant,
    required this.userAssignedName,
    required this.categoryId,
    required this.category,
    required this.recurring,
  });

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
    'recurring',
  ];

  final Object id;
  final String date;
  final String time;
  final String type;
  final String amount;
  final String merchant;
  final String? userAssignedName;
  final int? categoryId;
  final String category;
  final bool recurring;

  List<Object?> get values => [
    id,
    date,
    time,
    type,
    amount,
    merchant,
    userAssignedName,
    categoryId,
    category,
    recurring,
  ];
}

class TransactionExportRowBuilder {
  const TransactionExportRowBuilder();

  List<TransactionExportRow> build({
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
  }) {
    final categoriesById = {
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    return [
      for (final transaction in transactions)
        TransactionExportRow(
          id: transaction.id,
          date: transaction.date,
          time: transaction.displayTime,
          type: transaction.type.nativeValue,
          amount: _amount(transaction.amount),
          merchant: transaction.merchant,
          userAssignedName: transaction.userAssignedName,
          categoryId: transaction.transactionCategoryID,
          category:
              categoriesById[transaction.transactionCategoryID]?.name ?? '',
          recurring: transaction.isRecurringGenerated,
        ),
    ];
  }

  String _amount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }
}
