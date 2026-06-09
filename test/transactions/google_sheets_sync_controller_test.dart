import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/export/transaction_export_row.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_api_client.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_auth_client.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_sync_config.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_sync_controller.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_sync_models.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'connect creates spreadsheet and syncs years grouped from local transactions',
    () async {
      final api = FakeGoogleSheetsApiClient();
      final store = FakeGoogleSheetsSyncStore();
      final controller = buildController(api: api, store: store);

      await controller.connect();

      expect(api.createdTitle, GoogleSheetsSyncConfig.spreadsheetName);
      expect(api.rewrittenYears, [2025, 2026]);
      expect(store.saved.last.spreadsheetId, 'sheet-id');
      expect(store.saved.last.lastError, isNull);
    },
  );

  test(
    'manual sync rewrites the same yearly ranges as app-entry sync',
    () async {
      final api = FakeGoogleSheetsApiClient();
      final store = FakeGoogleSheetsSyncStore.connected();
      final controller = buildController(api: api, store: store);
      await controller.start();

      await controller.syncOnAppEntry();
      await controller.syncNow();

      expect(api.rewrittenYears, [2025, 2026, 2025, 2026]);
    },
  );

  test(
    'api failure preserves enabled settings and records last error',
    () async {
      final api = FakeGoogleSheetsApiClient(failRewrites: true);
      final store = FakeGoogleSheetsSyncStore.connected();
      final controller = buildController(api: api, store: store);
      await controller.start();

      await controller.syncNow();

      expect(store.saved.last.enabled, isTrue);
      expect(store.saved.last.spreadsheetId, 'sheet-id');
      expect(store.saved.last.lastError, contains('sync failed'));
    },
  );

  test(
    'disconnect clears metadata without touching local repository',
    () async {
      final repository = FakeTransactionRepository();
      final store = FakeGoogleSheetsSyncStore.connected();
      final controller = buildController(repository: repository, store: store);
      await controller.start();

      await controller.disconnect();

      expect(store.cleared, isTrue);
      expect(repository.loadBootstrapCalls, 0);
    },
  );
}

GoogleSheetsSyncController buildController({
  FakeGoogleSheetsApiClient? api,
  FakeGoogleSheetsSyncStore? store,
  FakeTransactionRepository? repository,
}) {
  final resolvedApi = api ?? FakeGoogleSheetsApiClient();
  return GoogleSheetsSyncController(
    authClient: FakeGoogleSheetsAuthClient(),
    apiClientFactory: (_) => resolvedApi,
    store: store ?? FakeGoogleSheetsSyncStore(),
    repository: repository ?? FakeTransactionRepository(),
    clock: () => DateTime.fromMillisecondsSinceEpoch(1780950000000),
  );
}

class FakeGoogleSheetsAuthClient implements GoogleSheetsAuthClientContract {
  @override
  Future<void> disconnect() async {}

  @override
  Future<GoogleSheetsSignedInAccount?> restore() async {
    return const GoogleSheetsSignedInAccount(
      email: 'user@example.com',
      authHeaders: {'Authorization': 'Bearer token'},
    );
  }

  @override
  Future<GoogleSheetsSignedInAccount> signIn() async {
    return const GoogleSheetsSignedInAccount(
      email: 'user@example.com',
      authHeaders: {'Authorization': 'Bearer token'},
    );
  }
}

class FakeGoogleSheetsApiClient implements GoogleSheetsApiClientContract {
  FakeGoogleSheetsApiClient({this.failRewrites = false});

  final bool failRewrites;
  String? createdTitle;
  final rewrittenYears = <int>[];

  @override
  Future<GoogleSpreadsheetRef> createSpreadsheet(String title) async {
    createdTitle = title;
    return const GoogleSpreadsheetRef(
      id: 'sheet-id',
      url: 'https://docs.google.com/spreadsheets/d/sheet-id/edit',
    );
  }

  @override
  Future<void> ensureYearSheets({
    required String spreadsheetId,
    required Set<int> years,
  }) async {}

  @override
  Future<void> rewriteYear({
    required String spreadsheetId,
    required int year,
    required List<TransactionExportRow> rows,
  }) async {
    if (failRewrites) throw Exception('boom');
    rewrittenYears.add(year);
  }
}

class FakeGoogleSheetsSyncStore implements GoogleSheetsSyncStoreContract {
  FakeGoogleSheetsSyncStore([GoogleSheetsSyncSettings? initial])
    : _settings = initial ?? GoogleSheetsSyncSettings.disconnected();

  factory FakeGoogleSheetsSyncStore.connected() {
    return FakeGoogleSheetsSyncStore(
      const GoogleSheetsSyncSettings(
        enabled: true,
        accountEmail: 'user@example.com',
        spreadsheetId: 'sheet-id',
        spreadsheetUrl: 'https://docs.google.com/spreadsheets/d/sheet-id/edit',
        lastSyncedAtMillis: null,
        lastError: null,
      ),
    );
  }

  GoogleSheetsSyncSettings _settings;
  final saved = <GoogleSheetsSyncSettings>[];
  bool cleared = false;

  @override
  Future<void> clear() async {
    cleared = true;
    _settings = GoogleSheetsSyncSettings.disconnected();
  }

  @override
  Future<GoogleSheetsSyncSettings> load() async => _settings;

  @override
  Future<void> save(GoogleSheetsSyncSettings settings) async {
    saved.add(settings);
    _settings = settings;
  }
}

class FakeTransactionRepository implements TransactionRepositoryContract {
  int loadBootstrapCalls = 0;

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    loadBootstrapCalls += 1;
    return TransactionBootstrap(
      categories: [_category(1, 'Élelmiszer'), _category(2, 'Fizetés')],
      transactions: const [],
      limits: const [],
    );
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final transactions = [
      _transaction(1, '2025.12.31', -1000, 1),
      _transaction(2, '2026.01.01', 5000, 2),
    ];
    if (query.offset > 0) {
      return TransactionPage(
        transactions: const [],
        totalCount: transactions.length,
        limit: query.limit,
        offset: query.offset,
      );
    }
    return TransactionPage(
      transactions: transactions,
      totalCount: transactions.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, int>> categoryCounts() {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteRecurringRule(int id) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<RecurringRule>> listRecurringRules() async => const [];

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> updateRecurringRule(int id, RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> toggleRecurringRule(int id, bool isActive) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) {
    throw UnimplementedError();
  }
}

TransactionCategory _category(int id, String name) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: id == 2 ? 'bevétel' : 'kiadás',
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

TransactionRecord _transaction(
  int id,
  String date,
  double amount,
  int categoryId,
) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '09:15',
    latitude: null,
    longitude: null,
    address: null,
    merchant: amount > 0 ? 'Salary' : 'Corner Shop',
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}
