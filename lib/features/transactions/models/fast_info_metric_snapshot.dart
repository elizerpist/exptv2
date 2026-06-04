import 'category_limit.dart';
import 'recurring_ghost_record.dart';
import 'transaction_category.dart';
import 'transaction_record.dart';

class FastInfoMetricSnapshot {
  FastInfoMetricSnapshot({
    required this.now,
    required this.balance,
    this.savingGoal,
    List<TransactionRecord> transactions = const <TransactionRecord>[],
    List<TransactionCategory> categories = const <TransactionCategory>[],
    List<CategoryLimit> limits = const <CategoryLimit>[],
    List<RecurringGhostRecord> recurringGhosts = const <RecurringGhostRecord>[],
  }) : transactions = List.unmodifiable(transactions),
       categories = List.unmodifiable(categories),
       limits = List.unmodifiable(limits),
       recurringGhosts = List.unmodifiable(recurringGhosts);

  final DateTime now;
  final double balance;
  final double? savingGoal;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final List<CategoryLimit> limits;
  final List<RecurringGhostRecord> recurringGhosts;
}
