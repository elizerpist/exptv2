import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/security/security_gate.dart';
import 'features/shell/expt_shell.dart';
import 'features/stats/data/stats_render_frame_worker.dart';
import 'features/transactions/data/transaction_repository.dart';
import 'features/transactions/sync/google_auth_headers_client.dart';
import 'features/transactions/sync/google_sheets_api_client.dart';
import 'features/transactions/sync/google_sheets_auth_client.dart';
import 'features/transactions/sync/google_sheets_sync_controller.dart';
import 'features/transactions/sync/google_sheets_sync_store.dart';
import 'features/transactions/slots/category_icon_manager.dart';
import 'features/transactions/widgets/category_slot_icon.dart';
import 'services/native_bridge.dart';
import 'state/event_store.dart';

Future<void>? _categoryIconStartupFuture;
var _categoryIconStartupReady = false;

Future<void> bootstrapCategoryIconsForStartup({
  SharedPreferences? preferences,
}) {
  if (_categoryIconStartupReady) return Future<void>.value();
  final existing = _categoryIconStartupFuture;
  if (existing != null) return existing;
  final future = _loadAndWarmCategoryIcons(preferences: preferences);
  _categoryIconStartupFuture = future;
  return future;
}

Future<void> _loadAndWarmCategoryIcons({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  await CategoryIconManager.load(preferences: prefs);
  await warmUpCategorySlotIconCache(strokeWidth: 1.35);
  _categoryIconStartupReady = true;
}

class Exptv2App extends StatefulWidget {
  const Exptv2App({
    super.key,
    required this.store,
    required this.nativeBridge,
    this.statsRenderFrameWorker,
  });

  final EventStore store;
  final NativeBridge nativeBridge;
  final StatsRenderFrameWorker? statsRenderFrameWorker;

  @override
  State<Exptv2App> createState() => _Exptv2AppState();
}

class _Exptv2AppState extends State<Exptv2App> {
  GoogleSheetsSyncController? _googleSheetsSyncController;
  final _securityGateController = SecurityGateController();

  @override
  void initState() {
    super.initState();
    unawaited(bootstrapCategoryIconsForStartup());
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
    return KeyboardProvider(
      child: MaterialApp(
        title: 'Exptv2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: SecurityGate(
          controller: _securityGateController,
          nativeBridge: widget.nativeBridge,
          onUnlocked: _googleSheetsSyncController == null
              ? null
              : _syncGoogleSheetsOnUnlocked,
          child: ExptShell(
            store: widget.store,
            nativeBridge: widget.nativeBridge,
            googleSheetsSyncController: _googleSheetsSyncController,
            statsRenderFrameWorker: widget.statsRenderFrameWorker,
            onSecuritySettingsChanged: _securityGateController.updateSettings,
          ),
        ),
      ),
    );
  }
}
