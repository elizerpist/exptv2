import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/security/security_gate.dart';
import 'features/shell/expt_shell.dart';
import 'features/transactions/data/transaction_repository.dart';
import 'features/transactions/sync/google_auth_headers_client.dart';
import 'features/transactions/sync/google_sheets_api_client.dart';
import 'features/transactions/sync/google_sheets_auth_client.dart';
import 'features/transactions/sync/google_sheets_sync_controller.dart';
import 'features/transactions/sync/google_sheets_sync_store.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

class Exptv2App extends StatefulWidget {
  const Exptv2App({super.key, required this.store, required this.nativeBridge});

  final EventStore store;
  final NativeBridge nativeBridge;

  @override
  State<Exptv2App> createState() => _Exptv2AppState();
}

class _Exptv2AppState extends State<Exptv2App> {
  GoogleSheetsSyncController? _googleSheetsSyncController;

  @override
  void initState() {
    super.initState();
    unawaited(_initGoogleSheetsSync());
  }

  @override
  void dispose() {
    _googleSheetsSyncController?.dispose();
    super.dispose();
  }

  Future<void> _initGoogleSheetsSync() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = GoogleSheetsSyncController(
      authClient: GoogleSheetsAuthClient(),
      apiClientFactory: (headers) =>
          GoogleSheetsApiClient(GoogleAuthHeadersClient(headers)),
      store: GoogleSheetsSyncStore(preferences),
      repository: TransactionRepository(widget.nativeBridge),
    );
    await controller.start();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() => _googleSheetsSyncController = controller);
  }

  void _syncGoogleSheetsOnUnlocked() {
    final controller = _googleSheetsSyncController;
    if (controller == null) return;
    unawaited(controller.syncOnAppEntry());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exptv2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SecurityGate(
        nativeBridge: widget.nativeBridge,
        onUnlocked: _googleSheetsSyncController == null
            ? null
            : _syncGoogleSheetsOnUnlocked,
        child: ExptShell(
          store: widget.store,
          nativeBridge: widget.nativeBridge,
          googleSheetsSyncController: _googleSheetsSyncController,
        ),
      ),
    );
  }
}
