import 'recurring_ghost_record.dart';
import 'transaction_record.dart';

class TransactionLogEntry {
  const TransactionLogEntry._({this.record, this.ghost});

  factory TransactionLogEntry.record(TransactionRecord record) {
    return TransactionLogEntry._(record: record);
  }

  factory TransactionLogEntry.ghost(RecurringGhostRecord ghost) {
    return TransactionLogEntry._(ghost: ghost);
  }

  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;

  bool get isGhost => ghost != null;
  String get date => record?.date ?? ghost!.date;
  String get time => record?.time ?? ghost!.time;
  int get sortId => record?.id ?? ghost!.id;
}
