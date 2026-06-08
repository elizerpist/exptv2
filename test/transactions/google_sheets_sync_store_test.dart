import 'package:exptv2/features/transactions/sync/google_sheets_sync_models.dart';
import 'package:exptv2/features/transactions/sync/google_sheets_sync_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    expect(
      loaded.spreadsheetUrl,
      'https://docs.google.com/spreadsheets/d/sheet-id/edit',
    );
    expect(loaded.lastSyncedAtMillis, 1780950000000);
    expect(loaded.lastError, isNull);
  });

  test('clears google sheets sync settings on disconnect', () async {
    SharedPreferences.setMockInitialValues({});
    final store = GoogleSheetsSyncStore(await SharedPreferences.getInstance());

    await store.save(
      const GoogleSheetsSyncSettings(
        enabled: true,
        accountEmail: 'user@example.com',
        spreadsheetId: 'sheet-id',
        spreadsheetUrl: 'https://docs.google.com/spreadsheets/d/sheet-id/edit',
        lastSyncedAtMillis: 1780950000000,
        lastError: 'old error',
      ),
    );

    await store.clear();

    final loaded = await store.load();
    final disconnected = GoogleSheetsSyncSettings.disconnected();
    expect(loaded.enabled, disconnected.enabled);
    expect(loaded.accountEmail, disconnected.accountEmail);
    expect(loaded.spreadsheetId, disconnected.spreadsheetId);
    expect(loaded.spreadsheetUrl, disconnected.spreadsheetUrl);
    expect(loaded.lastSyncedAtMillis, disconnected.lastSyncedAtMillis);
    expect(loaded.lastError, disconnected.lastError);
  });
}
