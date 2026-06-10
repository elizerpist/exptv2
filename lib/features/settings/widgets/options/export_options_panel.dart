import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../transactions/export/transaction_export_service.dart';
import '../../../transactions/sync/google_sheets_auth_client.dart';
import '../../../transactions/sync/google_sheets_sync_controller.dart';
import '../../../transactions/sync/google_sheets_sync_models.dart';
import 'settings_option_widgets.dart';

class ExportOptionsPanel extends StatefulWidget {
  const ExportOptionsPanel({
    super.key,
    required this.exportService,
    this.googleSheetsSyncController,
  });

  final TransactionExportService exportService;
  final GoogleSheetsSyncController? googleSheetsSyncController;

  @override
  State<ExportOptionsPanel> createState() => _ExportOptionsPanelState();
}

class _ExportOptionsPanelState extends State<ExportOptionsPanel> {
  String? _busyAction;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    widget.googleSheetsSyncController?.addListener(_onGoogleSyncChanged);
  }

  @override
  void didUpdateWidget(covariant ExportOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.googleSheetsSyncController ==
        widget.googleSheetsSyncController) {
      return;
    }
    oldWidget.googleSheetsSyncController?.removeListener(_onGoogleSyncChanged);
    widget.googleSheetsSyncController?.addListener(_onGoogleSyncChanged);
  }

  @override
  void dispose() {
    widget.googleSheetsSyncController?.removeListener(_onGoogleSyncChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final googleController = widget.googleSheetsSyncController;
    final googleConnected = googleController?.settings.connected ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'Tranzakciók exportálása',
          children: [
            SettingsOptionItem(
              title: 'CSV mentése telefonra',
              onTap: () => _run('save', _saveCsv),
              trailing: _trailing('save'),
            ),
            SettingsOptionItem(
              title: 'CSV megosztása',
              onTap: () => _run('share', _shareCsv),
              trailing: _trailing('share'),
              isLast: true,
            ),
          ],
        ),
        SettingsSection(
          title: 'Google Sheets szinkron',
          children: [
            if (!googleConnected)
              SettingsOptionItem(
                title: 'Google Sheets csatlakoztatása',
                subtitle: 'Bejelentkezés Google-fiókkal',
                leading: const _GoogleMark(),
                onTap: () => _run('connect-google', _connectGoogle),
                trailing: _googleTrailing('connect-google'),
              ),
            SettingsOptionItem(
              title: 'Szinkron most',
              onTap: () => _run('sync-google', _syncGoogle),
              trailing: _googleTrailing('sync-google'),
              isLast: !googleConnected,
            ),
            if (googleConnected) ...[
              SettingsOptionItem(
                title: 'Google Sheet megnyitása',
                onTap: () => _run('open-google', _openGoogle),
                trailing: _trailing('open-google'),
              ),
              SettingsOptionItem(
                title: 'Google kapcsolat bontása',
                onTap: () => _run('disconnect-google', _disconnectGoogle),
                trailing: _trailing('disconnect-google'),
                isLast: true,
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _googleStatusText(),
            style: const TextStyle(color: AppColors.gray500),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'A CSV export és a Google Sheets sync az összes tranzakciót tartalmazza.',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
        if (_statusMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _statusMessage!,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ),
      ],
    );
  }

  Widget _trailing(String action) {
    if (_busyAction == action) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const Icon(Icons.chevron_right, color: AppColors.gray400);
  }

  Widget _googleTrailing(String action) {
    final status = widget.googleSheetsSyncController?.status;
    if ((action == 'connect-google' &&
            status == GoogleSheetsSyncStatus.signingIn) ||
        (action == 'sync-google' && status == GoogleSheetsSyncStatus.syncing)) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return _trailing(action);
  }

  Future<void> _run(String action, Future<void> Function() callback) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      await callback();
    } catch (error) {
      _showMessage(
        googleSheetsAuthUserMessage(error) ?? 'Export sikertelen: $error',
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _saveCsv() async {
    final result = await widget.exportService.saveCsvFile();
    _showMessage('CSV fájl mentve: ${result.transactionCount} tranzakció');
  }

  Future<void> _shareCsv() async {
    await widget.exportService.shareCsvFile();
    _showMessage('CSV megosztás előkészítve');
  }

  Future<void> _connectGoogle() async {
    final controller = widget.googleSheetsSyncController;
    if (controller == null) {
      _showMessage('Google sync inicializálása folyamatban');
      return;
    }
    await controller.connect();
    if (controller.status == GoogleSheetsSyncStatus.failed ||
        controller.status == GoogleSheetsSyncStatus.waitingForNetwork ||
        controller.lastError != null) {
      _showMessage(
        controller.lastError ?? 'Google Sheets csatlakoztatása sikertelen',
      );
      return;
    }
    _showMessage('Google Sheets csatlakoztatva');
  }

  Future<void> _syncGoogle() async {
    final controller = widget.googleSheetsSyncController;
    if (controller == null) {
      _showMessage('Google sync inicializálása folyamatban');
      return;
    }
    if (!controller.settings.connected) {
      _showMessage('Előbb csatlakoztasd Google Sheetset');
      return;
    }
    await controller.syncNow();
    _showMessage(
      controller.lastError == null ? 'Szinkron kész' : 'Szinkron sikertelen',
    );
  }

  Future<void> _openGoogle() async {
    await widget.googleSheetsSyncController?.openSpreadsheet();
  }

  Future<void> _disconnectGoogle() async {
    await widget.googleSheetsSyncController?.disconnect();
    _showMessage('Google kapcsolat bontva');
  }

  String _googleStatusText() {
    final controller = widget.googleSheetsSyncController;
    final status = controller?.status ?? GoogleSheetsSyncStatus.disconnected;
    return switch (status) {
      GoogleSheetsSyncStatus.disconnected =>
        'Google Sheets nincs csatlakoztatva',
      GoogleSheetsSyncStatus.signingIn => 'Google bejelentkezés folyamatban',
      GoogleSheetsSyncStatus.syncing => 'Szinkronizálás folyamatban',
      GoogleSheetsSyncStatus.waitingForNetwork => 'Szinkron várakozik',
      GoogleSheetsSyncStatus.failed =>
        controller?.lastError ?? 'Szinkron sikertelen',
      GoogleSheetsSyncStatus.idle => _lastSyncText(controller),
    };
  }

  String _lastSyncText(GoogleSheetsSyncController? controller) {
    final lastSyncedAtMillis = controller?.settings.lastSyncedAtMillis;
    if (lastSyncedAtMillis == null) return 'Google Sheets csatlakoztatva';
    final date = DateTime.fromMillisecondsSinceEpoch(lastSyncedAtMillis);
    return 'Utolsó sync: ${_two(date.year)}.${_two(date.month)}.${_two(date.day)} '
        '${_two(date.hour)}:${_two(date.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  void _onGoogleSyncChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _statusMessage = message);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset('assets/brand/google_g.svg'),
    );
  }
}
