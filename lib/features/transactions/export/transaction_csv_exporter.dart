import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'transaction_export_row.dart';

class TransactionCsvExporter {
  const TransactionCsvExporter();

  String buildCsv({
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
  }) {
    final rows = const TransactionExportRowBuilder().build(
      transactions: transactions,
      categories: categories,
    );
    final buffer = StringBuffer()
      ..writeln(TransactionExportRow.headers.join(','));
    for (final row in rows) {
      buffer.writeln(row.values.map(_field).join(','));
    }
    return buffer.toString();
  }

  String _field(Object? value) {
    final raw = value?.toString() ?? '';
    if (!raw.contains(',') && !raw.contains('"') && !raw.contains('\n')) {
      return raw;
    }
    return '"${raw.replaceAll('"', '""')}"';
  }
}
