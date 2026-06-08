import 'package:shared_preferences/shared_preferences.dart';

import 'google_sheets_sync_models.dart';

class GoogleSheetsSyncStore {
  const GoogleSheetsSyncStore(this._preferences);

  static const _prefix = 'googleSheetsSync.';
  static const _enabledKey = '${_prefix}enabled';
  static const _accountEmailKey = '${_prefix}accountEmail';
  static const _spreadsheetIdKey = '${_prefix}spreadsheetId';
  static const _spreadsheetUrlKey = '${_prefix}spreadsheetUrl';
  static const _lastSyncedAtMillisKey = '${_prefix}lastSyncedAtMillis';
  static const _lastErrorKey = '${_prefix}lastError';

  final SharedPreferences _preferences;

  Future<GoogleSheetsSyncSettings> load() async {
    final enabled = _preferences.getBool(_enabledKey) ?? false;
    if (!enabled) {
      return GoogleSheetsSyncSettings.disconnected();
    }

    return GoogleSheetsSyncSettings(
      enabled: enabled,
      accountEmail: _preferences.getString(_accountEmailKey),
      spreadsheetId: _preferences.getString(_spreadsheetIdKey),
      spreadsheetUrl: _preferences.getString(_spreadsheetUrlKey),
      lastSyncedAtMillis: _preferences.getInt(_lastSyncedAtMillisKey),
      lastError: _preferences.getString(_lastErrorKey),
    );
  }

  Future<void> save(GoogleSheetsSyncSettings settings) async {
    await _preferences.setBool(_enabledKey, settings.enabled);
    await _setNullableString(_accountEmailKey, settings.accountEmail);
    await _setNullableString(_spreadsheetIdKey, settings.spreadsheetId);
    await _setNullableString(_spreadsheetUrlKey, settings.spreadsheetUrl);
    await _setNullableInt(
      _lastSyncedAtMillisKey,
      settings.lastSyncedAtMillis,
    );
    await _setNullableString(_lastErrorKey, settings.lastError);
  }

  Future<void> clear() async {
    await _preferences.remove(_enabledKey);
    await _preferences.remove(_accountEmailKey);
    await _preferences.remove(_spreadsheetIdKey);
    await _preferences.remove(_spreadsheetUrlKey);
    await _preferences.remove(_lastSyncedAtMillisKey);
    await _preferences.remove(_lastErrorKey);
  }

  Future<void> _setNullableString(String key, String? value) {
    if (value == null) {
      return _preferences.remove(key);
    }
    return _preferences.setString(key, value);
  }

  Future<void> _setNullableInt(String key, int? value) {
    if (value == null) {
      return _preferences.remove(key);
    }
    return _preferences.setInt(key, value);
  }
}
