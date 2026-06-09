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
