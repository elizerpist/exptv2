import 'transaction_category.dart';
import 'transaction_record.dart';

class TransactionSummary {
  const TransactionSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  factory TransactionSummary.fromRecords(Iterable<TransactionRecord> records) {
    var income = 0.0;
    var expense = 0.0;
    for (final record in records) {
      if (record.amount > 0) {
        income += record.amount;
      } else {
        expense += record.amount.abs();
      }
    }
    return TransactionSummary(income: income, expense: expense);
  }

  String formattedFor(TransactionType type) {
    return type == TransactionType.income
        ? '+${formatHuf(income)}'
        : '-${formatHuf(expense)}';
  }
}
