import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/recurring_alarm_service.dart';

class DebugConsole {
  DebugConsole._();

  static const _maxEntries = 500;
  static final List<String> _entries = <String>[];
  static final ValueNotifier<int> _version = ValueNotifier<int>(0);
  static var _notifyScheduled = false;

  static void log(String message) {
    final now = DateTime.now();
    final stamp =
        '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond ~/ 10).toString().padLeft(2, '0')}]';
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add('$stamp $message');
    _scheduleNotify();
  }

  static void clear() {
    _entries.clear();
    _scheduleNotify();
  }

  static void _scheduleNotify() {
    if (!_version.hasListeners) return;
    if (_notifyScheduled) return;
    late final WidgetsBinding binding;
    try {
      binding = WidgetsBinding.instance;
    } on FlutterError {
      _version.value += 1;
      return;
    }
    _notifyScheduled = true;
    binding.addPostFrameCallback((_) {
      _notifyScheduled = false;
      _version.value += 1;
    });
    binding.scheduleFrame();
  }

  static List<String> get entries => List.unmodifiable(_entries);
  static String get allText => _entries.join('\n');
  static ValueNotifier<int> get notifier => _version;
}

class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({
    super.key,
    this.recurringAlarmService,
    this.onRecurringChanged,
  });

  final RecurringAlarmService? recurringAlarmService;
  final VoidCallback? onRecurringChanged;

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _copied = false;
  bool _alarmLoading = false;
  String? _alarmError;
  RecurringAlarmDebugState? _alarmState;

  @override
  void initState() {
    super.initState();
    _controller.text = DebugConsole.allText;
    DebugConsole.notifier.addListener(_refresh);
    if (widget.recurringAlarmService != null) {
      _loadAlarmState();
    }
  }

  @override
  void dispose() {
    DebugConsole.notifier.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final text = DebugConsole.allText;
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

  Future<void> _loadAlarmState() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      _alarmState = await service.loadDebugState();
    }, logSuccess: false);
  }

  Future<void> _syncRecurringAlarms() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      await service.syncRecurringAlarms();
      _alarmState = await service.loadDebugState();
      DebugConsole.log('[RecurringAlarm] sync requested from debug console');
    });
  }

  Future<void> _processRecurringNow() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      final result = await service.processRecurringNow();
      _alarmState = result.state;
      DebugConsole.log(
        '[RecurringAlarm] debug processed ${result.processedCount} recurring rows',
      );
      widget.onRecurringChanged?.call();
    });
  }

  Future<void> _shiftDebugDate(int days) async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      final base = _alarmState?.effectiveDate ?? DateTime.now();
      final target = DateTime(base.year, base.month, base.day + days);
      final result = await service.setDebugDateOverride(target);
      _alarmState = result.state;
      DebugConsole.log(
        '[RecurringAlarm] debug date ${_formatDate(target)} processed ${result.processedCount}',
      );
      widget.onRecurringChanged?.call();
    });
  }

  Future<void> _clearDebugDateOverride() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      _alarmState = await service.clearDebugDateOverride();
      DebugConsole.log('[RecurringAlarm] debug date reset to phone date');
      widget.onRecurringChanged?.call();
    });
  }

  Future<void> _scheduleDebugTestAlarm() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    const delay = Duration(minutes: 2);
    await _runAlarmAction(() async {
      _alarmState = await service.scheduleDebugTestAlarm(delay: delay);
      DebugConsole.log(
        '[RecurringAlarm] debug test alarm scheduled in ${delay.inMinutes} minutes',
      );
    });
  }

  Future<void> _clearNativeDebugLog() async {
    final service = widget.recurringAlarmService;
    if (service == null) return;
    await _runAlarmAction(() async {
      await service.clearDebugLog();
      _alarmState = await service.loadDebugState();
      DebugConsole.log('[RecurringAlarm] native debug log cleared');
    });
  }

  Future<void> _runAlarmAction(
    Future<void> Function() action, {
    bool logSuccess = true,
  }) async {
    if (_alarmLoading) return;
    setState(() {
      _alarmLoading = true;
      _alarmError = null;
    });
    try {
      await action();
    } catch (error) {
      _alarmError = error.toString();
      DebugConsole.log('[RecurringAlarm] debug action failed: $error');
    } finally {
      if (mounted) {
        setState(() => _alarmLoading = false);
        if (logSuccess) _refresh();
      }
    }
  }

  Widget _buildRecurringAlarmPanel() {
    final service = widget.recurringAlarmService;
    if (service == null) return const SizedBox.shrink();

    final state = _alarmState;
    final effective = state?.effectiveDate;
    final logs = state?.logs ?? const <String>[];
    return Container(
      key: const ValueKey('debug-console-recurring-section'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF313244))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alarm,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  effective == null
                      ? 'Recurring alarm'
                      : 'Recurring alarm · ${_formatDate(effective)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_alarmLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-prev-day'),
                icon: Icons.chevron_left,
                tooltip: 'Previous debug day',
                onPressed: _alarmLoading ? null : () => _shiftDebugDate(-1),
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-next-day'),
                icon: Icons.chevron_right,
                tooltip: 'Next debug day',
                onPressed: _alarmLoading ? null : () => _shiftDebugDate(1),
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-process-now'),
                icon: Icons.play_arrow,
                tooltip: 'Process recurring now',
                onPressed: _alarmLoading ? null : _processRecurringNow,
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-sync'),
                icon: Icons.sync,
                tooltip: 'Sync recurring alarms',
                onPressed: _alarmLoading ? null : _syncRecurringAlarms,
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-reset'),
                icon: Icons.restore,
                tooltip: 'Reset debug date',
                onPressed: _alarmLoading ? null : _clearDebugDateOverride,
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-test-alarm'),
                icon: Icons.alarm_add_outlined,
                tooltip: 'Schedule background test alarm',
                onPressed: _alarmLoading ? null : _scheduleDebugTestAlarm,
              ),
              _SmallDebugIconButton(
                key: const ValueKey('recurring-debug-native-log-clear'),
                icon: Icons.layers_clear_outlined,
                tooltip: 'Clear native recurring log',
                onPressed: _alarmLoading ? null : _clearNativeDebugLog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state?.usingOverride == true ? 'Override active' : 'Phone date',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
          if (_alarmError != null) ...[
            const SizedBox(height: 4),
            Text(
              _alarmError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
            ),
          ],
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...logs.reversed.take(3).map(
                  (entry) => Text(
                    entry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = DebugConsole.entries.length;
    return Dialog(
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
                  const Text(
                    'Debug Console',
                    style: TextStyle(
                      color: Color(0xFFCDD6F4),
                      fontWeight: FontWeight.w700,
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
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('debug-console-copy'),
                    onPressed: count == 0 ? null : _copyAll,
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
                    onPressed: count == 0 ? null : DebugConsole.clear,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: const Color(0xFFEF4444),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF313244)),
            _buildRecurringAlarmPanel(),
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

class _SmallDebugIconButton extends StatelessWidget {
  const _SmallDebugIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 30,
            child: Icon(
              icon,
              size: 16,
              color: onPressed == null
                  ? const Color(0xFF4B5563)
                  : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
