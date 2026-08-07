import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/fluvi_diagnostic_logger.dart';

/// The reference debug console projection, backed by Fluvi's shared
/// diagnostic ring buffer. It is intentionally unaware of ledger or query
/// state.
class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({super.key, this.physicalReportProvider});

  final String Function()? physicalReportProvider;

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _copied = false;
  bool _physicalReportCopied = false;

  @override
  void initState() {
    super.initState();
    _controller.text = FluviDiagnosticLogger.allText;
    FluviDiagnosticLogger.notifier.addListener(_refresh);
  }

  @override
  void dispose() {
    FluviDiagnosticLogger.notifier.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final text = FluviDiagnosticLogger.allText;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  Future<void> _copyAll() async {
    if (_controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  Future<void> _copyPhysicalReport() async {
    final provider = widget.physicalReportProvider;
    if (provider == null) return;
    await Clipboard.setData(ClipboardData(text: provider()));
    if (!mounted) return;
    setState(() => _physicalReportCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final count = FluviDiagnosticLogger.entries.length;
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
                  const SizedBox(width: 6),
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
                  if (widget.physicalReportProvider != null)
                    IconButton(
                      key: const ValueKey('debug-console-copy-physical-report'),
                      tooltip: 'Rail diagnostic riport másolása',
                      onPressed: _copyPhysicalReport,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 17,
                      icon: Icon(
                        _physicalReportCopied
                            ? Icons.check
                            : Icons.monitor_heart_outlined,
                        size: 16,
                      ),
                      color: _physicalReportCopied
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF9E2AF),
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
            const Divider(height: 1, color: Color(0xFF313244)),
            Flexible(
              child: count == 0
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Még nincs log.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : TextField(
                      controller: _controller,
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
