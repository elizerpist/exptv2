import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/network_failure.dart';
import '../data/transaction_repository.dart';
import '../export/transaction_export_row.dart';
import '../models/transaction_record.dart';
import 'google_sheets_api_client.dart';
import 'google_sheets_auth_client.dart';
import 'google_sheets_sync_config.dart';
import 'google_sheets_sync_models.dart';
import 'google_sheets_sync_store.dart';

typedef GoogleSheetsApiClientFactory =
    GoogleSheetsApiClientContract Function(Map<String, String> authHeaders);

class GoogleSheetsSyncController extends ChangeNotifier {
  GoogleSheetsSyncController({
    required GoogleSheetsAuthClientContract authClient,
    required GoogleSheetsApiClientFactory apiClientFactory,
    required GoogleSheetsSyncStoreContract store,
    required TransactionRepositoryContract repository,
    DateTime Function()? clock,
    TransactionExportRowBuilder rowBuilder =
        const TransactionExportRowBuilder(),
    int pageSize = 500,
  }) : _authClient = authClient,
       _apiClientFactory = apiClientFactory,
       _store = store,
       _repository = repository,
       _clock = clock,
       _rowBuilder = rowBuilder,
       _pageSize = pageSize;

  final GoogleSheetsAuthClientContract _authClient;
  final GoogleSheetsApiClientFactory _apiClientFactory;
  final GoogleSheetsSyncStoreContract _store;
  final TransactionRepositoryContract _repository;
  final DateTime Function()? _clock;
  final TransactionExportRowBuilder _rowBuilder;
  final int _pageSize;

  GoogleSheetsApiClientContract? _apiClient;
  GoogleSheetsSyncSettings _settings = GoogleSheetsSyncSettings.disconnected();
  GoogleSheetsSyncStatus _status = GoogleSheetsSyncStatus.disconnected;
  bool _syncing = false;

  GoogleSheetsSyncSettings get settings => _settings;
  GoogleSheetsSyncStatus get status => _status;
  String? get lastError => _settings.lastError;

  Future<void> start() async {
    _settings = await _store.load();
    _status = _settings.connected
        ? GoogleSheetsSyncStatus.idle
        : GoogleSheetsSyncStatus.disconnected;
    notifyListeners();
  }

  Future<void> connect() async {
    _setStatus(GoogleSheetsSyncStatus.signingIn);
    try {
      final account = await _authClient.signIn();
      final api = _apiClientFactory(account.authHeaders);
      _apiClient = api;
      final spreadsheet = await api.createSpreadsheet(
        GoogleSheetsSyncConfig.spreadsheetName,
      );
      _settings = GoogleSheetsSyncSettings(
        enabled: true,
        accountEmail: account.email,
        spreadsheetId: spreadsheet.id,
        spreadsheetUrl: spreadsheet.url,
        lastSyncedAtMillis: null,
        lastError: null,
      );
      await _store.save(_settings);
      notifyListeners();
      await _sync(api);
    } catch (error) {
      final failedStatus = isNetworkFailure(error)
          ? GoogleSheetsSyncStatus.waitingForNetwork
          : GoogleSheetsSyncStatus.failed;
      await _recordFailure(
        error,
        failedStatus,
        userMessage: googleSheetsAuthUserMessage(error),
      );
    }
  }

  Future<void> syncOnAppEntry() async {
    if (!_settings.connected || _syncing) return;
    final api = await _authorizedApi(interactive: false);
    if (api == null) return;
    await _sync(api);
  }

  Future<void> syncNow() async {
    if (!_settings.connected || _syncing) return;
    final api = await _authorizedApi(interactive: true);
    if (api == null) return;
    await _sync(api);
  }

  Future<void> openSpreadsheet() async {
    final url = _settings.spreadsheetUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> disconnect() async {
    await _authClient.disconnect();
    await _store.clear();
    _apiClient = null;
    _settings = GoogleSheetsSyncSettings.disconnected();
    _setStatus(GoogleSheetsSyncStatus.disconnected);
  }

  Future<GoogleSheetsApiClientContract?> _authorizedApi({
    required bool interactive,
  }) async {
    final cached = _apiClient;
    if (cached != null) return cached;

    GoogleSheetsSignedInAccount? account;
    try {
      account = interactive
          ? await _authClient.signIn()
          : await _authClient.restore();
    } catch (error) {
      await _recordFailure(
        error,
        GoogleSheetsSyncStatus.failed,
        userMessage: googleSheetsAuthUserMessage(error),
      );
      return null;
    }
    if (account == null) {
      await _recordFailure(
        StateError('Google sign-in required.'),
        GoogleSheetsSyncStatus.failed,
        userMessage: 'Google bejelentkezés szükséges a szinkronhoz.',
      );
      return null;
    }

    _apiClient = _apiClientFactory(account.authHeaders);
    if (account.email != _settings.accountEmail) {
      _settings = GoogleSheetsSyncSettings(
        enabled: _settings.enabled,
        accountEmail: account.email,
        spreadsheetId: _settings.spreadsheetId,
        spreadsheetUrl: _settings.spreadsheetUrl,
        lastSyncedAtMillis: _settings.lastSyncedAtMillis,
        lastError: _settings.lastError,
      );
      await _store.save(_settings);
      notifyListeners();
    }
    return _apiClient;
  }

  Future<void> _sync(GoogleSheetsApiClientContract api) async {
    final spreadsheetId = _settings.spreadsheetId;
    if (spreadsheetId == null || _syncing) return;

    _syncing = true;
    _setStatus(GoogleSheetsSyncStatus.syncing);
    try {
      final bootstrap = await _repository.loadBootstrap();
      final transactions = await _loadAllTransactions();
      final grouped = _groupByYear(transactions);
      final years = grouped.keys.toList()..sort();

      await api.ensureYearSheets(
        spreadsheetId: spreadsheetId,
        years: years.toSet(),
      );
      for (final year in years) {
        final rows = _rowBuilder.build(
          transactions: grouped[year]!,
          categories: bootstrap.categories,
        );
        await api.rewriteYear(
          spreadsheetId: spreadsheetId,
          year: year,
          rows: rows,
        );
      }

      _settings = GoogleSheetsSyncSettings(
        enabled: _settings.enabled,
        accountEmail: _settings.accountEmail,
        spreadsheetId: _settings.spreadsheetId,
        spreadsheetUrl: _settings.spreadsheetUrl,
        lastSyncedAtMillis:
            (_clock?.call() ?? DateTime.now()).millisecondsSinceEpoch,
        lastError: null,
      );
      await _store.save(_settings);
      _setStatus(GoogleSheetsSyncStatus.idle);
    } catch (error) {
      final failedStatus = isNetworkFailure(error)
          ? GoogleSheetsSyncStatus.waitingForNetwork
          : GoogleSheetsSyncStatus.failed;
      await _recordFailure(error, failedStatus);
    } finally {
      _syncing = false;
    }
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

  Map<int, List<TransactionRecord>> _groupByYear(
    List<TransactionRecord> transactions,
  ) {
    final grouped = <int, List<TransactionRecord>>{};
    for (final transaction in transactions) {
      final year = int.parse(transaction.normalizedDate.substring(0, 4));
      grouped.putIfAbsent(year, () => <TransactionRecord>[]).add(transaction);
    }
    return grouped;
  }

  Future<void> _recordFailure(
    Object error,
    GoogleSheetsSyncStatus failedStatus, {
    String? userMessage,
  }) async {
    _settings = GoogleSheetsSyncSettings(
      enabled: _settings.enabled,
      accountEmail: _settings.accountEmail,
      spreadsheetId: _settings.spreadsheetId,
      spreadsheetUrl: _settings.spreadsheetUrl,
      lastSyncedAtMillis: _settings.lastSyncedAtMillis,
      lastError: userMessage ?? 'sync failed: $error',
    );
    await _store.save(_settings);
    _setStatus(failedStatus);
  }

  void _setStatus(GoogleSheetsSyncStatus status) {
    _status = status;
    notifyListeners();
  }
}
