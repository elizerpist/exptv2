import 'package:google_sign_in/google_sign_in.dart';

import 'google_sheets_sync_config.dart';

class GoogleSheetsSignedInAccount {
  const GoogleSheetsSignedInAccount({
    required this.email,
    required this.authHeaders,
  });

  final String email;
  final Map<String, String> authHeaders;
}

class GoogleSheetsAuthClient {
  GoogleSheetsAuthClient({
    GoogleSignIn? googleSignIn,
    List<String> scopes = const [GoogleSheetsSyncConfig.driveFileScope],
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _scopes = scopes;

  final GoogleSignIn _googleSignIn;
  final List<String> _scopes;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      clientId: GoogleSheetsSyncConfig.androidClientId,
      serverClientId: GoogleSheetsSyncConfig.serverClientId,
    );
    _initialized = true;
  }

  Future<GoogleSheetsSignedInAccount?> restore() async {
    await initialize();
    final future = _googleSignIn.attemptLightweightAuthentication();
    final account = future == null ? null : await future;
    if (account == null) return null;

    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
    );
    if (headers == null) return null;
    return GoogleSheetsSignedInAccount(
      email: account.email,
      authHeaders: headers,
    );
  }

  Future<GoogleSheetsSignedInAccount> signIn() async {
    await initialize();
    final account = await _googleSignIn.authenticate(scopeHint: _scopes);
    await account.authorizationClient.authorizationForScopes(_scopes);
    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );
    if (headers == null) {
      throw StateError('Google Sheets authorization was not granted.');
    }
    return GoogleSheetsSignedInAccount(
      email: account.email,
      authHeaders: headers,
    );
  }

  Future<void> disconnect() async {
    await initialize();
    await _googleSignIn.disconnect();
  }
}
