import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/export/transaction_export_service.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/export_service_methods');
  late NativeBridge bridge;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/export_service_events'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'expenseSaveTextFile':
              return 'content://downloads/exptv2-transactions.csv';
            case 'expenseShareTextFile':
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads every transaction page and builds a dated csv file', () async {
    final repository = _PagedExportRepository(pageSize: 2);
    final service = TransactionExportService(
      repository: repository,
      nativeBridge: bridge,
      clock: () => DateTime(2026, 6, 8, 12),
      pageSize: 2,
    );

    final bundle = await service.buildCsvBundle();

    expect(bundle.fileName, 'exptv2-transactions-2026-06-08.csv');
    expect(bundle.transactionCount, 3);
    expect(bundle.csv, contains('id,date,time,type,amount'));
    expect(bundle.csv, contains('3,2026.06.08,12:00,income,9900'));
    expect(repository.queries.map((query) => query.offset), [0, 2]);
  });

  test('sends csv payload to native save and share methods', () async {
    final service = TransactionExportService(
      repository: _PagedExportRepository(pageSize: 10),
      nativeBridge: bridge,
      clock: () => DateTime(2026, 6, 8, 12),
      pageSize: 10,
    );

    final saveResult = await service.saveCsvFile();
    await service.shareCsvFile();

    expect(saveResult.uri, 'content://downloads/exptv2-transactions.csv');
    expect(calls.map((call) => call.method), [
      'expenseSaveTextFile',
      'expenseShareTextFile',
    ]);
    final savePayload = calls.first.arguments as Map<dynamic, dynamic>;
    expect(savePayload['fileName'], 'exptv2-transactions-2026-06-08.csv');
    expect(savePayload['mimeType'], 'text/csv');
    expect(savePayload['content'], contains('Corner Shop'));
  });
}

class _PagedExportRepository extends TransactionRepositoryContract {
  _PagedExportRepository({required this.pageSize});

  final int pageSize;
  final queries = <TransactionPageQuery>[];
  final categories = <TransactionCategory>[
    _category(id: 6, name: 'Bolt'),
    _category(id: 7, name: 'Fizetés'),
  ];
  late final transactions = <TransactionRecord>[
    _transaction(id: 1, amount: -1200, categoryId: 6, merchant: 'Corner Shop'),
    _transaction(id: 2, amount: -450, categoryId: 6, merchant: 'Bakery'),
    _transaction(id: 3, amount: 9900, categoryId: 7, merchant: 'Salary'),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    return TransactionBootstrap(
      categories: categories,
      transactions: const <TransactionRecord>[],
      limits: const <CategoryLimit>[],
      recurringGhostTransactions: const <RecurringGhostRecord>[],
    );
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    queries.add(query);
    return TransactionPage(
      transactions: transactions.skip(query.offset).take(query.limit).toList(),
      totalCount: transactions.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TransactionRecord _transaction({
  required int id,
  required double amount,
  required int categoryId,
  required String merchant,
}) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': '2026.06.08',
    'time': '12:00',
    'merchant': merchant,
    'amount': amount,
    'transactionCategoryID': categoryId,
  });
}

TransactionCategory _category({required int id, required String name}) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: 'kiadás',
    colorSlot: null,
    iconSlot: null,
    backgroundColor: '#f3f4f6',
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}
