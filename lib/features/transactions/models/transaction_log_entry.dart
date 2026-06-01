import 'recurring_ghost_record.dart';
import 'transaction_record.dart';

class TransactionLogEntry {
  const TransactionLogEntry._({this.header, this.record, this.ghost});

  factory TransactionLogEntry.header(String date) {
    return TransactionLogEntry._(header: date);
  }

  factory TransactionLogEntry.record(TransactionRecord record) {
    return TransactionLogEntry._(record: record);
  }

  factory TransactionLogEntry.ghost(RecurringGhostRecord ghost) {
    return TransactionLogEntry._(ghost: ghost);
  }

  final String? header;
  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;

  bool get isHeader => header != null;
  bool get isGhost => ghost != null;
  String get date => header ?? record?.date ?? ghost!.date;
  String get time => record?.time ?? ghost?.time ?? '';
  int get sortId => record?.id ?? ghost?.id ?? 0;
}
