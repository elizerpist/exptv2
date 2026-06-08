import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../transactions/export/transaction_export_service.dart';
import 'settings_option_widgets.dart';

class ExportOptionsPanel extends StatefulWidget {
  const ExportOptionsPanel({super.key, required this.exportService});

  final TransactionExportService exportService;

  @override
  State<ExportOptionsPanel> createState() => _ExportOptionsPanelState();
}

class _ExportOptionsPanelState extends State<ExportOptionsPanel> {
  String? _busyAction;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
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
            ),
            SettingsOptionItem(
              title: 'Google Sheets (később)',
              onTap: _showGooglePlaceholder,
              trailing: const Icon(
                Icons.lock_clock_outlined,
                color: AppColors.gray400,
              ),
              isLast: true,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'A CSV export az összes tranzakciót tartalmazza.',
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

  Future<void> _run(String action, Future<void> Function() callback) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      await callback();
    } catch (_) {
      _showMessage('Export sikertelen');
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

  void _showGooglePlaceholder() {
    _showMessage('Google Sheets export később érkezik');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _statusMessage = message);
    if (Scaffold.maybeOf(context) != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
