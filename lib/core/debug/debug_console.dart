import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/fluvi_diagnostic_logger.dart';

typedef DebugDiagnosticStatusProvider = Map<String, Object?> Function();

/// Bounded onscreen diagnostic projection. It owns no dashboard state; report
/// snapshots are requested only by an explicit user action.
class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({
    super.key,
    this.physicalReportProvider,
    this.diagnosticStatusProvider,
  });

  final String Function()? physicalReportProvider;
  final DebugDiagnosticStatusProvider? diagnosticStatusProvider;

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

enum _DebugConsoleSection { logs, report }

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  final TextEditingController _logsController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  _DebugConsoleSection _section = _DebugConsoleSection.logs;
  bool _copied = false;
  bool _physicalReportCopied = false;
  bool _copyingPhysicalReport = false;
  String? _physicalReportError;

  @override
  void initState() {
    super.initState();
    _logsController.text = FluviDiagnosticLogger.allText;
    FluviDiagnosticLogger.notifier.addListener(_refreshLogs);
  }

  @override
  void dispose() {
    FluviDiagnosticLogger.notifier.removeListener(_refreshLogs);
    _logsController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    if (!mounted) return;
    final text = FluviDiagnosticLogger.allText;
    _logsController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  void _showReport() {
    setState(() => _section = _DebugConsoleSection.report);
    _refreshPhysicalReport();
  }

  void _refreshPhysicalReport() {
    final provider = widget.physicalReportProvider;
    if (provider == null) return;
    try {
      final report = provider();
      _reportController.value = TextEditingValue(
        text: report,
        selection: const TextSelection.collapsed(offset: 0),
      );
      if (mounted) {
        setState(() {
          _physicalReportError = null;
          _physicalReportCopied = false;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _physicalReportError = '$error');
    }
  }

  Future<void> _copyAll() async {
    if (_logsController.text.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: _logsController.text));
      if (mounted) setState(() => _copied = true);
    } on Object catch (_) {
      // The physical-report tab contains explicit copy diagnostics. Logs stay
      // non-disruptive because they are an auxiliary projection.
    }
  }

  Future<void> _copyPhysicalReport() async {
    if (_copyingPhysicalReport) return;
    final provider = widget.physicalReportProvider;
    if (provider == null) return;
    setState(() {
      _copyingPhysicalReport = true;
      _physicalReportCopied = false;
      _physicalReportError = null;
    });
    try {
      final report = _reportController.text.isEmpty
          ? provider()
          : _reportController.text;
      await Clipboard.setData(ClipboardData(text: report));
      if (mounted) setState(() => _physicalReportCopied = true);
    } on Object catch (error) {
      if (mounted) setState(() => _physicalReportError = '$error');
    } finally {
      if (mounted) setState(() => _copyingPhysicalReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = FluviDiagnosticLogger.entries.length;
    final status =
        widget.diagnosticStatusProvider?.call() ?? const <String, Object?>{};
    return Dialog(
      key: const ValueKey('debug-console-dialog'),
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal,
                    size: 16,
                    color: Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Debug Console',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFCDD6F4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '($count)',
                    style: const TextStyle(
                      color: Color(0xFF6C7086),
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-copy'),
                    onPressed: count == 0 ? null : _copyAll,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 17,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_outlined,
                      size: 16,
                    ),
                    color: _copied
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF89B4FA),
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-clear'),
                    onPressed: count == 0 ? null : FluviDiagnosticLogger.clear,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 17,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: const Color(0xFFEF4444),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 17,
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
            if (status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SelectableText(
                  _statusText(status),
                  key: const ValueKey('debug-console-live-status'),
                  maxLines: 10,
                  style: const TextStyle(
                    color: Color(0xFFBAC2DE),
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            const Divider(height: 1, color: Color(0xFF313244)),
            Row(
              children: [
                _sectionButton(
                  key: const ValueKey('debug-console-logs-tab'),
                  label: 'LOGS',
                  selected: _section == _DebugConsoleSection.logs,
                  onPressed: () =>
                      setState(() => _section = _DebugConsoleSection.logs),
                ),
                if (widget.physicalReportProvider != null)
                  _sectionButton(
                    key: const ValueKey('debug-console-report-tab'),
                    label: 'PHYSICAL REPORT',
                    selected: _section == _DebugConsoleSection.report,
                    onPressed: _showReport,
                  ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFF313244)),
            Flexible(child: _sectionBody(count)),
          ],
        ),
      ),
    );
  }

  Widget _sectionButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) => Expanded(
    child: TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? const Color(0xFF06B6D4)
            : const Color(0xFF94A3B8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _sectionBody(int count) {
    if (_section == _DebugConsoleSection.logs) {
      return count == 0
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Még nincs log.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          : _readOnlyText(
              _logsController,
              key: const ValueKey('debug-console-logs'),
            );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('debug-console-refresh-physical-report'),
                onPressed: _refreshPhysicalReport,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Frissítés'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('debug-console-copy-physical-report'),
                onPressed: _copyingPhysicalReport ? null : _copyPhysicalReport,
                icon: Icon(
                  _copyingPhysicalReport
                      ? Icons.hourglass_top
                      : _physicalReportCopied
                      ? Icons.check
                      : Icons.copy_outlined,
                  size: 15,
                ),
                label: Text(_copyingPhysicalReport ? 'Másolás…' : 'Másolás'),
              ),
            ],
          ),
        ),
        if (_physicalReportError case final String error)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: Text(
              error,
              key: const ValueKey('debug-console-physical-report-error'),
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
            ),
          ),
        Expanded(
          child: _readOnlyText(
            _reportController,
            key: const ValueKey('debug-console-physical-report'),
            emptyText: 'A riport a Frissítés gombbal készül.',
          ),
        ),
      ],
    );
  }

  static Widget _readOnlyText(
    TextEditingController controller, {
    required Key key,
    String? emptyText,
  }) => controller.text.isEmpty && emptyText != null
      ? Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        )
      : TextField(
          key: key,
          controller: controller,
          readOnly: true,
          maxLines: null,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            height: 1.45,
            color: Color(0xFFCDD6F4),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(14),
          ),
        );

  static String _statusText(Map<String, Object?> status) => status.entries
      .map((entry) => '${entry.key}: ${entry.value ?? '—'}')
      .join('\n');
}
