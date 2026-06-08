# Google Sheets Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Google Sheets transaction sync with app-entry/manual full-year rewrites, remove unused location fields, remove clipboard export, and sign CI APKs with the registered Google OAuth SHA-1 key.

**Architecture:** Keep local DB as the source of truth. Reuse one transaction export row builder for CSV and Sheets, isolate Google auth/API calls behind testable adapters, and trigger sync only from unlocked UI entry or the manual settings action. Native Android remains responsible for local Room persistence and file save/share.

**Tech Stack:** Flutter/Dart, Kotlin/Room, `google_sign_in`, `googleapis`, `http`, `shared_preferences`, `url_launcher`, GitHub Actions signing secrets.

---

## File Structure

- `lib/features/transactions/export/transaction_export_row.dart`: shared row/header builder used by CSV and Sheets.
- `lib/features/transactions/export/transaction_csv_exporter.dart`: CSV formatting only.
- `lib/features/transactions/sync/google_sheets_sync_config.dart`: non-secret Google client IDs and scopes.
- `lib/features/transactions/sync/google_sheets_sync_models.dart`: sync settings/state/value objects.
- `lib/features/transactions/sync/google_sheets_sync_store.dart`: `SharedPreferences` metadata persistence.
- `lib/features/transactions/sync/google_sheets_auth_client.dart`: Google Sign-In wrapper.
- `lib/features/transactions/sync/google_sheets_api_client.dart`: Sheets API wrapper.
- `lib/features/transactions/sync/google_sheets_sync_controller.dart`: orchestration and UI state.
- `lib/features/settings/widgets/options/export_options_panel.dart`: export/sync UI.
- `lib/features/security/security_gate.dart`: emits one UI-entry callback after unlock.
- `lib/exptv2_app.dart`, `lib/features/shell/expt_shell.dart`, `lib/features/settings/settings_page.dart`: pass the sync controller to UI.
- `android/app/src/main/kotlin/com/exptv2/app/expense/*`: remove transaction location columns and add Room migration.
- `.github/workflows/android-build.yml`, `android/app/build.gradle.kts`: stable signing for CI APK.

## Task 1: Dependencies and Export Row Cleanup

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/transactions/export/transaction_export_row.dart`
- Modify: `lib/features/transactions/export/transaction_csv_exporter.dart`
- Modify: `lib/features/transactions/models/transaction_record.dart`
- Modify: `lib/features/settings/widgets/options/export_options_panel.dart`
- Test: `test/transactions/transaction_models_test.dart`
- Test: `test/transactions/transaction_csv_exporter_test.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Add dependency entries**

Add these dependencies under `dependencies:`:

```yaml
  google_sign_in: ^7.2.0
  googleapis: ^14.0.0
  http: ^1.2.2
  shared_preferences: ^2.3.3
  url_launcher: ^6.3.1
```

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter pub get'
```

Expected: `pubspec.lock` updates successfully.

- [ ] **Step 2: Write failing Dart cleanup tests**

Update `test/transactions/transaction_models_test.dart` so `TransactionRecord` fixtures no longer include `latitude`, `longitude`, or `address`, and add:

```dart
expect(record.toMap().containsKey('latitude'), isFalse);
expect(record.toMap().containsKey('longitude'), isFalse);
expect(record.toMap().containsKey('address'), isFalse);
```

Update `test/transactions/transaction_csv_exporter_test.dart` expected header to:

```dart
'id,date,time,type,amount,merchant,userAssignedName,categoryId,category,recurring\n'
'1,2026.06.08,09:15,expense,-1290,Corner Shop,Kávé,6,Élelmiszer,false\n'
```

Update the escaping assertion to:

```dart
expect(
  csv,
  contains(
    '2,2026.06.08,10:00,income,5000,"Bolt, ""Market""","Line\nBreak",7,"Fizetés, bónusz",true',
  ),
);
```

Update `test/settings/settings_page_test.dart` export test to remove the clipboard expectation:

```dart
expect(find.text('CSV másolása vágólapra'), findsNothing);
```

- [ ] **Step 3: Run failing targeted tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_models_test.dart test/transactions/transaction_csv_exporter_test.dart test/settings/settings_page_test.dart'
```

Expected: FAIL because the model/exporter/UI still expose the removed fields and clipboard option.

- [ ] **Step 4: Implement shared export rows**

Create `transaction_export_row.dart`:

```dart
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
  final int categoryId;
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
```

Update `TransactionCsvExporter` to use `TransactionExportRow.headers` and row `values`. Remove its location fields.

Update `TransactionRecord` constructor, fields, `fromMap`, and `toMap` to remove `latitude`, `longitude`, and `address`.

Remove clipboard import/action/method from `ExportOptionsPanel`.

- [ ] **Step 5: Verify targeted tests pass**

Run the command from Step 3 again.

Expected: all targeted tests pass.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/transactions/export/transaction_export_row.dart lib/features/transactions/export/transaction_csv_exporter.dart lib/features/transactions/models/transaction_record.dart lib/features/settings/widgets/options/export_options_panel.dart test/transactions/transaction_models_test.dart test/transactions/transaction_csv_exporter_test.dart test/settings/settings_page_test.dart
git commit -m "refactor: remove transaction location export fields"
```

## Task 2: Android Room Location Field Removal

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt`
- Modify any Kotlin tests found by `rg -n "latitude|longitude|address" android/app/src/test`

- [ ] **Step 1: Write failing Kotlin entity tests**

Update `ExpenseTransactionEntityTest` constructors to remove `latitude`, `longitude`, and `address`, then assert:

```kotlin
org.junit.Assert.assertFalse(row.toMap().containsKey("latitude"))
org.junit.Assert.assertFalse(row.toMap().containsKey("longitude"))
org.junit.Assert.assertFalse(row.toMap().containsKey("address"))
```

- [ ] **Step 2: Run compile check expected to fail before implementation**

Run from GitHub Actions after push or locally only if Gradle is available through Flutter. Do not run a local APK build on Termux.

For fast static discovery, run:

```bash
rg -n "latitude|longitude|address" android/app/src/main android/app/src/test
```

Expected before implementation: matches remain in entity, repository, seed data, and tests.

- [ ] **Step 3: Remove entity fields and map keys**

In `ExpenseTransactionEntity`, remove:

```kotlin
val latitude: Double?,
val longitude: Double?,
val address: String?,
```

Also remove these keys from `toMap()`.

- [ ] **Step 4: Remove repository and seed arguments**

Delete `latitude`, `longitude`, and `address` arguments from every `ExpenseTransactionEntity` constructor call in:

```bash
android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt
android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt
```

In `addTransaction`, remove reads from `args["latitude"]`, `args["longitude"]`, and `args["address"]`.

- [ ] **Step 5: Add Room migration 8 to 9**

In `ExpenseTrackerDatabase`, set `version = 9` and add `MIGRATION_8_9`.

Migration shape:

```kotlin
private val MIGRATION_8_9 = object : Migration(8, 9) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("PRAGMA foreign_keys=OFF")
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS transactions_new (
                id INTEGER PRIMARY KEY NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                merchant TEXT NOT NULL,
                amount REAL NOT NULL,
                userAssignedName TEXT,
                transactionCategoryID INTEGER NOT NULL,
                recurringTransactionId INTEGER,
                recurringRuleId INTEGER,
                recurringInstanceId INTEGER,
                FOREIGN KEY(transactionCategoryID) REFERENCES transaction_categories(transactionCategoryID) ON UPDATE NO ACTION ON DELETE RESTRICT
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            INSERT INTO transactions_new (
                id, date, time, merchant, amount, userAssignedName,
                transactionCategoryID, recurringTransactionId,
                recurringRuleId, recurringInstanceId
            )
            SELECT id, date, time, merchant, amount, userAssignedName,
                transactionCategoryID, recurringTransactionId,
                recurringRuleId, recurringInstanceId
            FROM transactions
            """.trimIndent(),
        )
        db.execSQL("DROP TABLE transactions")
        db.execSQL("ALTER TABLE transactions_new RENAME TO transactions")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_transactionCategoryID ON transactions(transactionCategoryID)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_date ON transactions(date)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_merchant ON transactions(merchant)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_amount ON transactions(amount)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringTransactionId ON transactions(recurringTransactionId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringRuleId ON transactions(recurringRuleId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringInstanceId ON transactions(recurringInstanceId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_date_time_id ON transactions(date, time, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_amount_date_time_id ON transactions(amount, date, time, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_transactionCategoryID_date_time_id ON transactions(transactionCategoryID, date, time, id)")
        db.execSQL("PRAGMA foreign_keys=ON")
    }
}
```

Add `MIGRATION_8_9` to the database builder migration list:

```kotlin
.addMigrations(
    MIGRATION_1_2,
    MIGRATION_2_3,
    MIGRATION_3_4,
    MIGRATION_4_5,
    MIGRATION_5_6,
    MIGRATION_6_7,
    MIGRATION_7_8,
    MIGRATION_8_9,
)
```

- [ ] **Step 6: Verify no location references remain**

Run:

```bash
rg -n "latitude|longitude|address" lib android/app/src/main android/app/src/test test
```

Expected: no transaction location-field usages remain. Non-transaction words such as unrelated UI text may remain only if not about these fields.

- [ ] **Step 7: Commit**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt
git commit -m "refactor: remove transaction location columns"
```

## Task 3: Google Sync Models and Metadata Store

**Files:**
- Create: `lib/features/transactions/sync/google_sheets_sync_config.dart`
- Create: `lib/features/transactions/sync/google_sheets_sync_models.dart`
- Create: `lib/features/transactions/sync/google_sheets_sync_store.dart`
- Test: `test/transactions/google_sheets_sync_store_test.dart`

- [ ] **Step 1: Write store tests**

Create `google_sheets_sync_store_test.dart` with `SharedPreferences.setMockInitialValues({})` and tests for saving/loading:

```dart
test('persists connected google sheets sync settings', () async {
  SharedPreferences.setMockInitialValues({});
  final store = GoogleSheetsSyncStore(await SharedPreferences.getInstance());

  await store.save(
    const GoogleSheetsSyncSettings(
      enabled: true,
      accountEmail: 'user@example.com',
      spreadsheetId: 'sheet-id',
      spreadsheetUrl: 'https://docs.google.com/spreadsheets/d/sheet-id/edit',
      lastSyncedAtMillis: 1780950000000,
      lastError: null,
    ),
  );

  final loaded = await store.load();

  expect(loaded.enabled, isTrue);
  expect(loaded.accountEmail, 'user@example.com');
  expect(loaded.spreadsheetId, 'sheet-id');
});
```

Add a disconnect test that calls `store.clear()` and expects `GoogleSheetsSyncSettings.disconnected()`.

- [ ] **Step 2: Run failing test**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_sync_store_test.dart'
```

Expected: FAIL because sync model/store files do not exist.

- [ ] **Step 3: Implement config and settings**

`google_sheets_sync_config.dart`:

```dart
class GoogleSheetsSyncConfig {
  const GoogleSheetsSyncConfig._();

  static const serverClientId =
      '881674880679-ndqgunmnbq49nkdd4oikelnhu88ip13l.apps.googleusercontent.com';
  static const androidClientId =
      '881674880679-h7abq4ipc3igqt65r870h4b5m34kghc7.apps.googleusercontent.com';
  static const driveFileScope =
      'https://www.googleapis.com/auth/drive.file';
  static const spreadsheetName = 'Exptv2 Transactions';
}
```

`google_sheets_sync_models.dart`:

```dart
enum GoogleSheetsSyncStatus {
  disconnected,
  idle,
  signingIn,
  syncing,
  waitingForNetwork,
  failed,
}

class GoogleSheetsSyncSettings {
  const GoogleSheetsSyncSettings({
    required this.enabled,
    required this.accountEmail,
    required this.spreadsheetId,
    required this.spreadsheetUrl,
    required this.lastSyncedAtMillis,
    required this.lastError,
  });

  factory GoogleSheetsSyncSettings.disconnected() =>
      const GoogleSheetsSyncSettings(
        enabled: false,
        accountEmail: null,
        spreadsheetId: null,
        spreadsheetUrl: null,
        lastSyncedAtMillis: null,
        lastError: null,
      );

  final bool enabled;
  final String? accountEmail;
  final String? spreadsheetId;
  final String? spreadsheetUrl;
  final int? lastSyncedAtMillis;
  final String? lastError;

  bool get connected => enabled && spreadsheetId != null;
}
```

- [ ] **Step 4: Implement SharedPreferences store**

Use keys under prefix `googleSheetsSync.`. Implement `load()`, `save(settings)`, and `clear()`.

- [ ] **Step 5: Verify store tests pass and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_sync_store_test.dart'
git add lib/features/transactions/sync/google_sheets_sync_config.dart lib/features/transactions/sync/google_sheets_sync_models.dart lib/features/transactions/sync/google_sheets_sync_store.dart test/transactions/google_sheets_sync_store_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add google sheets sync metadata store"
```

## Task 4: Google Auth and Sheets API Adapters

**Files:**
- Create: `lib/features/transactions/sync/google_auth_headers_client.dart`
- Create: `lib/features/transactions/sync/google_sheets_auth_client.dart`
- Create: `lib/features/transactions/sync/google_sheets_api_client.dart`
- Test: `test/transactions/google_sheets_api_client_test.dart`

- [ ] **Step 1: Write API client unit tests with fakes**

The tests should not call Google. Test a fake adapter or injectable `sheets.SheetsApi` wrapper for:

```dart
test('builds yearly sheet title and update range', () {
  expect(GoogleSheetsApiClient.yearTitle(2026), '2026');
  expect(GoogleSheetsApiClient.yearRange('2026'), "'2026'!A1:J");
});
```

Add a request-shaping test that verifies rows include `TransactionExportRow.headers` plus row values.

- [ ] **Step 2: Run failing tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_api_client_test.dart'
```

Expected: FAIL because API adapter files do not exist.

- [ ] **Step 3: Implement auth headers HTTP client**

```dart
import 'package:http/http.dart' as http;

class GoogleAuthHeadersClient extends http.BaseClient {
  GoogleAuthHeadersClient(this._headers, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
```

- [ ] **Step 4: Implement Google Sign-In wrapper**

Use the package's current authorization model:

```dart
final authorization = await account.authorizationClient
    .authorizationForScopes(scopes);
final headers = await account.authorizationClient.authorizationHeaders(scopes);
```

When user interaction is required, call `authorizeScopes(scopes)` from the settings connect action. This follows the `google_sign_in` 7.x authorization flow documented on pub.dev.

- [ ] **Step 5: Implement Sheets API wrapper**

Use `googleapis/sheets/v4.dart`.

Required methods:

```dart
Future<GoogleSpreadsheetRef> createSpreadsheet(String title);
Future<void> ensureYearSheets({
  required String spreadsheetId,
  required Set<int> years,
});
Future<void> rewriteYear({
  required String spreadsheetId,
  required int year,
  required List<TransactionExportRow> rows,
});
```

`rewriteYear` must clear `"'$year'!A1:J"` and then write a values matrix made from `TransactionExportRow.headers` followed by `rows.map((row) => row.values).toList()` with `valueInputOption: 'RAW'`.

- [ ] **Step 6: Verify adapter tests pass and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_api_client_test.dart'
git add lib/features/transactions/sync/google_auth_headers_client.dart lib/features/transactions/sync/google_sheets_auth_client.dart lib/features/transactions/sync/google_sheets_api_client.dart test/transactions/google_sheets_api_client_test.dart
git commit -m "feat: add google sheets api adapters"
```

## Task 5: Sync Controller and Yearly Reconcile

**Files:**
- Create: `lib/features/transactions/sync/google_sheets_sync_controller.dart`
- Test: `test/transactions/google_sheets_sync_controller_test.dart`

- [ ] **Step 1: Write controller tests**

Use fake auth, fake sheets API, fake store, and fake `TransactionRepositoryContract`.

Cover:

```dart
test('connect creates spreadsheet and syncs years grouped from local transactions', () async {
  final api = FakeGoogleSheetsApiClient();
  final store = FakeGoogleSheetsSyncStore();
  final controller = buildController(api: api, store: store);

  await controller.connect();

  expect(api.createdTitle, 'Exptv2 Transactions');
  expect(api.rewrittenYears, [2025, 2026]);
  expect(store.saved.last.spreadsheetId, 'sheet-id');
  expect(store.saved.last.lastError, isNull);
});

test('manual sync rewrites the same yearly ranges as app-entry sync', () async {
  final api = FakeGoogleSheetsApiClient();
  final store = FakeGoogleSheetsSyncStore.connected();
  final controller = buildController(api: api, store: store);

  await controller.syncOnAppEntry();
  await controller.syncNow();

  expect(api.rewrittenYears, [2025, 2026, 2025, 2026]);
});

test('api failure preserves enabled settings and records last error', () async {
  final api = FakeGoogleSheetsApiClient(failRewrites: true);
  final store = FakeGoogleSheetsSyncStore.connected();
  final controller = buildController(api: api, store: store);

  await controller.syncNow();

  expect(store.saved.last.enabled, isTrue);
  expect(store.saved.last.spreadsheetId, 'sheet-id');
  expect(store.saved.last.lastError, contains('sync failed'));
});

test('disconnect clears metadata without touching local repository', () async {
  final repository = FakeTransactionRepository();
  final store = FakeGoogleSheetsSyncStore.connected();
  final controller = buildController(repository: repository, store: store);

  await controller.disconnect();

  expect(store.cleared, isTrue);
  expect(repository.loadBootstrapCalls, 0);
});
```

Expected fake assertions:

```dart
expect(api.createdTitle, 'Exptv2 Transactions');
expect(api.rewrittenYears, [2025, 2026]);
expect(store.saved.last.lastError, isNull);
```

- [ ] **Step 2: Run failing tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_sync_controller_test.dart'
```

Expected: FAIL because controller does not exist.

- [ ] **Step 3: Implement controller**

The controller extends `ChangeNotifier` and exposes:

```dart
GoogleSheetsSyncSettings get settings;
GoogleSheetsSyncStatus get status;
String? get lastError;
Future<void> start();
Future<void> connect();
Future<void> syncOnAppEntry();
Future<void> syncNow();
Future<void> openSpreadsheet();
Future<void> disconnect();
```

Rules:

- `syncOnAppEntry()` returns immediately if settings are not connected or a sync is already running.
- `syncNow()` uses the same private `_sync()` path.
- `_sync()` loads all paged transactions plus categories through `TransactionRepositoryContract`.
- Group years by `int.parse(transaction.normalizedDate.substring(0, 4))`.
- On success, save `lastSyncedAtMillis` and clear `lastError`.
- On `SocketException`, set `waitingForNetwork`; on other errors, set `failed`.
- Never delete local data.

- [ ] **Step 4: Verify controller tests pass and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/google_sheets_sync_controller_test.dart'
git add lib/features/transactions/sync/google_sheets_sync_controller.dart test/transactions/google_sheets_sync_controller_test.dart
git commit -m "feat: add google sheets sync controller"
```

## Task 6: Settings UI and App-Entry Trigger

**Files:**
- Modify: `lib/features/settings/widgets/options/export_options_panel.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/security/security_gate.dart`
- Modify: `lib/exptv2_app.dart`
- Test: `test/settings/settings_page_test.dart`
- Test: `test/security/security_gate_test.dart`

- [ ] **Step 1: Write UI and entry-trigger tests**

Settings page expectations:

```dart
expect(find.text('CSV másolása vágólapra'), findsNothing);
expect(find.text('Google Sheets csatlakoztatása'), findsOneWidget);
expect(find.text('Szinkron most'), findsOneWidget);
```

Security gate expectation:

```dart
var unlockedCount = 0;
await tester.pumpWidget(MaterialApp(
  home: SecurityGate(
    nativeBridge: bridge,
    onUnlocked: () => unlockedCount += 1,
    child: const Text('Unlocked app'),
  ),
));
```

After PIN unlock, expect `unlockedCount == 1`. During ordinary foreground pumping, expect it stays `1`. After paused/resumed and unlocking again, expect `2`.

- [ ] **Step 2: Run failing tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/settings/settings_page_test.dart test/security/security_gate_test.dart'
```

Expected: FAIL because UI/controller wiring and `onUnlocked` do not exist.

- [ ] **Step 3: Add `onUnlocked` to `SecurityGate`**

Add optional callback:

```dart
final VoidCallback? onUnlocked;
```

Track a private `_reportedUnlocked` flag. When build sees `!_controller.loading && !_controller.locked`, schedule one post-frame callback that calls `widget.onUnlocked`. Reset `_reportedUnlocked = false` when app pauses/detaches and when it locks for resume.

- [ ] **Step 4: Wire controller through app shell**

Convert `Exptv2App` to a stateful widget that creates one `GoogleSheetsSyncController`. Pass:

```dart
onUnlocked: _syncController.syncOnAppEntry
```

to `SecurityGate`, and pass `_syncController` down to `ExptShell` -> `SettingsPage` -> `ExportOptionsPanel`.

- [ ] **Step 5: Update export panel UI**

Keep CSV save/share. Remove clipboard. Add Google actions:

- connected false: `Google Sheets csatlakoztatása`
- connected true: `Szinkron most`, `Google Sheet megnyitása`, `Google kapcsolat bontása`

Use controller status to show short status text such as:

- `Google Sheets nincs csatlakoztatva`
- `Szinkronizálás folyamatban`
- `Utolsó sync: 2026.06.08 22:30`
- `Szinkron várakozik`
- `Szinkron sikertelen`

- [ ] **Step 6: Verify tests pass and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/settings/settings_page_test.dart test/security/security_gate_test.dart'
git add lib/features/settings/widgets/options/export_options_panel.dart lib/features/settings/settings_page.dart lib/features/shell/expt_shell.dart lib/features/security/security_gate.dart lib/exptv2_app.dart test/settings/settings_page_test.dart test/security/security_gate_test.dart
git commit -m "feat: wire google sheets sync UI"
```

## Task 7: Stable APK Signing for Google OAuth

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `.github/workflows/android-build.yml`
- Modify: `.gitignore`

- [ ] **Step 1: Configure local ignore rules**

Add:

```gitignore
android/key.properties
android/app/exptv2-debug.keystore
```

- [ ] **Step 2: Configure Gradle signing from properties**

In `android/app/build.gradle.kts`, load `../key.properties` if present and create signing config `exptv2Debug`. Apply it to `debug` and `release` only when all properties are present. Keep fallback to Gradle's debug signing for local development.

Expected properties:

```properties
storeFile=app/exptv2-debug.keystore
storePassword=android
keyAlias=exptv2debug
keyPassword=android
```

- [ ] **Step 3: Configure GitHub Actions secrets**

Set secrets from the local keystore:

```bash
proot-distro login ubuntu -- bash -lc 'base64 -w0 /root/.android/exptv2-debug.keystore' | gh secret set EXPTV2_ANDROID_KEYSTORE_BASE64 --body-file -
gh secret set EXPTV2_ANDROID_KEYSTORE_PASSWORD --body android
gh secret set EXPTV2_ANDROID_KEY_ALIAS --body exptv2debug
gh secret set EXPTV2_ANDROID_KEY_PASSWORD --body android
```

- [ ] **Step 4: Decode secrets in workflow**

Before `flutter build apk --debug`, add a step:

```yaml
      - name: Configure Android signing
        run: |
          printf '%s' "${{ secrets.EXPTV2_ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/exptv2-debug.keystore
          cat > android/key.properties <<EOF
          storeFile=app/exptv2-debug.keystore
          storePassword=${{ secrets.EXPTV2_ANDROID_KEYSTORE_PASSWORD }}
          keyAlias=${{ secrets.EXPTV2_ANDROID_KEY_ALIAS }}
          keyPassword=${{ secrets.EXPTV2_ANDROID_KEY_PASSWORD }}
          EOF
```

- [ ] **Step 5: Commit**

```bash
git add .gitignore android/app/build.gradle.kts .github/workflows/android-build.yml
git commit -m "ci: sign debug apk with google oauth key"
```

## Task 8: Verification, Push, and Remote Build

**Files:** all changed files.

- [ ] **Step 1: Format Dart**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/dart format lib test'
```

- [ ] **Step 2: Run targeted tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_models_test.dart test/transactions/transaction_csv_exporter_test.dart test/transactions/google_sheets_sync_store_test.dart test/transactions/google_sheets_api_client_test.dart test/transactions/google_sheets_sync_controller_test.dart test/settings/settings_page_test.dart test/security/security_gate_test.dart'
```

Expected: all targeted tests pass.

- [ ] **Step 3: Run analyze**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 4: Run full Flutter tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/neumorphism-night-theme && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all Flutter tests pass. Existing non-fatal hit-test warnings may appear but must not fail the run.

- [ ] **Step 5: Check diff and commit any remaining verification fixes**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors. Commit any remaining intentional changes with a focused message.

- [ ] **Step 6: Push implementation branch**

Use implementation branch `feature/google-sheets-sync`:

```bash
git push -u origin feature/google-sheets-sync
```

- [ ] **Step 7: Trigger GitHub Actions APK build**

```bash
gh workflow run android-build.yml --ref feature/google-sheets-sync
RUN_ID=$(gh run list --workflow android-build.yml --branch feature/google-sheets-sync --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN_ID" --exit-status
```

Expected: workflow succeeds through analyze, tests, debug APK build, and release upload.

- [ ] **Step 8: Report direct APK link**

After success, verify the release asset:

```bash
gh release view debug-latest --json assets,tagName,url
```

Direct APK link:

```text
https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk
```
