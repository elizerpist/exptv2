import '../../../services/native_bridge.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_record.dart';
import 'transaction_csv_exporter.dart';

class TransactionCsvBundle {
  const TransactionCsvBundle({
    required this.fileName,
    required this.csv,
    required this.transactionCount,
  });

  final String fileName;
  final String csv;
  final int transactionCount;
}

class TransactionExportSaveResult {
  const TransactionExportSaveResult({
    required this.uri,
    required this.transactionCount,
  });

  final String uri;
  final int transactionCount;
}

class TransactionExportService {
  const TransactionExportService({
    required TransactionRepositoryContract repository,
    required NativeBridge nativeBridge,
    DateTime Function()? clock,
    TransactionCsvExporter csvExporter = const TransactionCsvExporter(),
    int pageSize = 500,
  }) : _repository = repository,
       _nativeBridge = nativeBridge,
       _clock = clock,
       _csvExporter = csvExporter,
       _pageSize = pageSize;

  final TransactionRepositoryContract _repository;
  final NativeBridge _nativeBridge;
  final DateTime Function()? _clock;
  final TransactionCsvExporter _csvExporter;
  final int _pageSize;

  Future<TransactionCsvBundle> buildCsvBundle() async {
    final bootstrap = await _repository.loadBootstrap();
    final transactions = await _loadAllTransactions();
    final csv = _csvExporter.buildCsv(
      transactions: transactions,
      categories: bootstrap.categories,
    );
    return TransactionCsvBundle(
      fileName: _fileName(_clock?.call() ?? DateTime.now()),
      csv: csv,
      transactionCount: transactions.length,
    );
  }

  Future<TransactionExportSaveResult> saveCsvFile() async {
    final bundle = await buildCsvBundle();
    final uri = await _nativeBridge.expenseSaveTextFile(
      fileName: bundle.fileName,
      mimeType: 'text/csv',
      content: bundle.csv,
    );
    return TransactionExportSaveResult(
      uri: uri,
      transactionCount: bundle.transactionCount,
    );
  }

  Future<TransactionCsvBundle> shareCsvFile() async {
    final bundle = await buildCsvBundle();
    await _nativeBridge.expenseShareTextFile(
      fileName: bundle.fileName,
      mimeType: 'text/csv',
      content: bundle.csv,
      chooserTitle: 'CSV megosztása',
    );
    return bundle;
  }

  Future<TransactionCsvBundle> clipboardCsv() {
    return buildCsvBundle();
  }

  Future<List<TransactionRecord>> _loadAllTransactions() async {
    final rows = <TransactionRecord>[];
    var offset = 0;
    while (true) {
      final page = await _repository.listTransactionPage(
        TransactionPageQuery(limit: _pageSize, offset: offset),
      );
      rows.addAll(page.transactions);
      offset += page.transactions.length;
      if (page.transactions.isEmpty || rows.length >= page.totalCount) {
        return rows;
      }
    }
  }

  String _fileName(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'exptv2-transactions-$year-$month-$day.csv';
  }
}
