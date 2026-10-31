import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/fluvi_diagnostic_event.dart';
import '../diagnostics/fluvi_diagnostic_logger.dart';
import '../../features/automation/domain/automation_models.dart';
import '../../features/automation/domain/automation_repository.dart';

typedef DebugDiagnosticStatusProvider = Map<String, Object?> Function();

/// Bounded onscreen diagnostic projection. It owns no dashboard state; report
/// snapshots are requested only by an explicit user action.
class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({
    super.key,
    this.physicalReportProvider,
    this.diagnosticStatusProvider,
    this.automationPermissions,
  });

  final String Function()? physicalReportProvider;
  final DebugDiagnosticStatusProvider? diagnosticStatusProvider;
  final AutomationPermissionRepository? automationPermissions;

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

enum _DebugConsoleSection { logs, report, push }

/// A view-only projection over the one bounded diagnostic ring.  It owns no
/// second history, export path, or diagnostic retention policy.
enum _DebugConsoleLogFilter { all, mindHeatmap, balanceWave, ghost }

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  static const _followThreshold = 36.0;
  final ScrollController _logsScrollController = ScrollController();
  final TextEditingController _reportController = TextEditingController();
  _DebugConsoleSection _section = _DebugConsoleSection.logs;
  _DebugConsoleLogFilter _logFilter = _DebugConsoleLogFilter.all;
  var _following = true;
  var _unseenCount = 0;
  var _lastSessionEventCount = 0;
  var _liveJumpScheduled = false;
  bool _copied = false;
  bool _captureCopied = false;
  bool _physicalReportCopied = false;
  bool _copyingPhysicalReport = false;
  String? _physicalReportError;
  PushDiagnosticsSnapshot? _pushSnapshot;
  bool _loadingPush = false;
  bool _pushCopied = false;

  @override
  void initState() {
    super.initState();
    _lastSessionEventCount = FluviDiagnosticLogger.sessionEventCount;
    _logsScrollController.addListener(_handleLogScroll);
    FluviDiagnosticLogger.notifier.addListener(_refreshLogs);
    if (widget.automationPermissions != null) _refreshPush();
    _scheduleJumpToLive();
  }

  @override
  void dispose() {
    FluviDiagnosticLogger.notifier.removeListener(_refreshLogs);
    _logsScrollController
      ..removeListener(_handleLogScroll)
      ..dispose();
    _reportController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    if (!mounted) return;
    final currentSessionCount = FluviDiagnosticLogger.sessionEventCount;
    final added = currentSessionCount >= _lastSessionEventCount
        ? currentSessionCount - _lastSessionEventCount
        : currentSessionCount;
    _lastSessionEventCount = currentSessionCount;
    setState(() {
      _copied = false;
      if (!_following) _unseenCount += added;
    });
    if (_following) _scheduleJumpToLive();
  }

  void _handleLogScroll() {
    if (!_logsScrollController.hasClients) return;
    final atLiveEnd = _logsScrollController.offset <= _followThreshold;
    if (atLiveEnd == _following) return;
    setState(() {
      _following = atLiveEnd;
      if (atLiveEnd) _unseenCount = 0;
    });
  }

  void _scheduleJumpToLive() {
    if (_liveJumpScheduled) return;
    _liveJumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _liveJumpScheduled = false;
      if (!mounted || !_following || !_logsScrollController.hasClients) {
        return;
      }
      _logsScrollController.jumpTo(0);
    });
  }

  void _returnToLive() {
    setState(() {
      _following = true;
      _unseenCount = 0;
    });
    _scheduleJumpToLive();
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
    final entries = _filteredEntries();
    try {
      await Clipboard.setData(
        ClipboardData(
          text: _logFilter == _DebugConsoleLogFilter.ghost
              ? FluviDiagnosticLogger.latestText(
                  domain: FluviDiagnosticDomain.ghost,
                )
              : FluviDiagnosticLogger.exportEvents(
                  label: 'LIVE_FILTER',
                  events: entries,
                ),
        ),
      );
      if (mounted) setState(() => _copied = true);
    } on Object catch (_) {
      // The physical-report tab contains explicit copy diagnostics. Logs stay
      // non-disruptive because they are an auxiliary projection.
    }
  }

  Future<void> _copyCapture() async {
    try {
      await Clipboard.setData(
        ClipboardData(text: FluviDiagnosticLogger.captureText()),
      );
      if (mounted) setState(() => _captureCopied = true);
    } on Object catch (_) {
      // The frozen capture remains intact when the platform clipboard fails.
    }
  }

  void _markBug(String issue) {
    final status =
        widget.diagnosticStatusProvider?.call() ?? const <String, Object?>{};
    final ghost = issue == 'ghost_transactions';
    if (ghost) {
      setState(() {
        _logFilter = _DebugConsoleLogFilter.ghost;
        _section = _DebugConsoleSection.logs;
      });
      _scheduleJumpToLive();
    }
    FluviDiagnosticLogger.markUserBug(
      issue,
      context: ghost ? <String, Object?>{'ghost': status['ghost']} : status,
      providerOwnerPrefix: ghost ? 'ghost.' : null,
    );
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

  Future<void> _refreshPush() async {
    final permissions = widget.automationPermissions;
    if (permissions == null || _loadingPush) return;
    setState(() => _loadingPush = true);
    try {
      final snapshot = await permissions.pushDiagnostics();
      if (mounted) setState(() => _pushSnapshot = snapshot);
    } finally {
      if (mounted) setState(() => _loadingPush = false);
    }
  }

  Future<void> _sendPushProbe() async {
    final permissions = widget.automationPermissions;
    if (permissions == null) return;
    await permissions.sendTestNotification();
    await _refreshPush();
  }

  Future<void> _copyPushDiagnostics() async {
    final snapshot = _pushSnapshot;
    if (snapshot == null) return;
    final text = <String>[
      'Push diagnosztika',
      'Build: ${snapshot.buildVersion ?? '—'} (${snapshot.buildCode ?? '—'}) · Android API ${snapshot.androidApi ?? '—'}',
      'Saját értesítések: ${snapshot.postNotificationsGranted && snapshot.appNotificationsEnabled && snapshot.testChannelEnabled ? 'engedélyezve' : 'nem küldhető'}',
      'Listener: ${snapshot.listenerConnected ? 'csatlakozva' : 'nincs csatlakozva'}',
      'App lista: ${snapshot.applicationListMode} · ${snapshot.applicationListFound}/${snapshot.applicationListVisible}',
      if (snapshot.applicationListError != null)
        'App lista hiba: ${snapshot.applicationListError}',
      'Utolsó próba: ${snapshot.lastTestStep ?? '—'} · ${snapshot.lastTestResult ?? '—'}',
      ...snapshot.events.map(
        (event) =>
            '${event.atUtcMs} · ${event.code} · ${event.message}${event.sourcePackage == null ? '' : ' · ${event.sourcePackage}'}',
      ),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _pushCopied = true);
  }

  Future<void> _clearPushDiagnostics() async {
    await widget.automationPermissions?.clearPushDiagnostics();
    await _refreshPush();
  }

  @override
  Widget build(BuildContext context) {
    final count = FluviDiagnosticLogger.retainedEntryCount;
    final status =
        widget.diagnosticStatusProvider?.call() ?? const <String, Object?>{};
    final balanceWaveStatus = _logFilter == _DebugConsoleLogFilter.balanceWave
        ? FluviDiagnosticLogger.userMarkerContextForOwnerPrefix('balanceWave.')
        : const <String, Object?>{};
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
                  PopupMenuButton<String>(
                    key: const ValueKey('debug-console-mark-bug'),
                    tooltip: 'MARK BUG NOW',
                    onSelected: _markBug,
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem(
                        value: 'gray_rectangle',
                        child: Text(
                          'Gray rectangle',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'mind_slider',
                        child: Text(
                          'Mind slider',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'mind_slider_no_live_list',
                        child: Text(
                          'Mind slider: no live list',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'mind_heatmap',
                        child: Text(
                          'Mind Heatmap',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'balance_wave',
                        child: Text(
                          'Balance wave',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ghost_transactions',
                        child: Text(
                          'Ghost tranzakciók',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'avatar_fling',
                        child: Text(
                          'Avatar fling',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'avatar_filter_stuck',
                        child: Text(
                          'Avatar filter stuck',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'time_fling',
                        child: Text(
                          'Time fling',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'time_target_jump',
                        child: Text(
                          'Time target jump',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'budget_limit',
                        child: Text(
                          'Budget / limit',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'other',
                        child: Text(
                          'Other',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    color: const Color(0xFFF8FAFC),
                    iconColor: const Color(0xFFF9E2AF),
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
                    onPressed: count == 0
                        ? null
                        : () {
                            FluviDiagnosticLogger.clearLive();
                            setState(() {
                              _unseenCount = 0;
                              _following = true;
                            });
                          },
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_following ? 'LIVE' : 'REVIEWING'} · $count retained · '
                      '${FluviDiagnosticLogger.sessionEventCount} session events',
                      key: const ValueKey('debug-console-tail-status'),
                      style: const TextStyle(
                        color: Color(0xFF6C7086),
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<_DebugConsoleLogFilter>(
                      key: const ValueKey('debug-console-log-filter'),
                      value: _logFilter,
                      isDense: true,
                      dropdownColor: const Color(0xFF313244),
                      style: const TextStyle(
                        color: Color(0xFFCDD6F4),
                        fontSize: 10.5,
                      ),
                      onChanged: (value) {
                        if (value == null || value == _logFilter) return;
                        setState(() => _logFilter = value);
                        _scheduleJumpToLive();
                      },
                      items: const <DropdownMenuItem<_DebugConsoleLogFilter>>[
                        DropdownMenuItem(
                          value: _DebugConsoleLogFilter.all,
                          child: Text('All'),
                        ),
                        DropdownMenuItem(
                          value: _DebugConsoleLogFilter.mindHeatmap,
                          child: Text('Mind Heatmap'),
                        ),
                        DropdownMenuItem(
                          value: _DebugConsoleLogFilter.balanceWave,
                          child: Text('Balance Wave'),
                        ),
                        DropdownMenuItem(
                          value: _DebugConsoleLogFilter.ghost,
                          child: Text('Ghost tranzakciók'),
                        ),
                      ],
                    ),
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
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            if (balanceWaveStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SelectableText(
                  'BALANCE WAVE STATUS\n${_statusText(balanceWaveStatus)}',
                  key: const ValueKey('debug-console-balance-wave-status'),
                  maxLines: 10,
                  style: const TextStyle(
                    color: Color(0xFFC4B5FD),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  if (!FluviDiagnosticLogger.captureActive)
                    OutlinedButton.icon(
                      key: const ValueKey('debug-console-start-capture'),
                      onPressed: () {
                        FluviDiagnosticLogger.startCapture(
                          domain: _logFilter == _DebugConsoleLogFilter.ghost
                              ? FluviDiagnosticDomain.ghost
                              : FluviDiagnosticDomain.all,
                        );
                        FluviDiagnosticLogger.recordCaptureStateSnapshot(
                          'start',
                          status,
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.fiber_manual_record, size: 15),
                      label: const Text('START CAPTURE'),
                    )
                  else
                    OutlinedButton.icon(
                      key: const ValueKey('debug-console-stop-capture'),
                      onPressed: () {
                        FluviDiagnosticLogger.recordCaptureStateSnapshot(
                          'stop',
                          status,
                        );
                        FluviDiagnosticLogger.stopCapture();
                        setState(() {});
                      },
                      icon: const Icon(Icons.stop_circle_outlined, size: 15),
                      label: const Text('STOP CAPTURE'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('debug-console-clear-capture'),
                    onPressed: () {
                      FluviDiagnosticLogger.clearCapture();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                    label: const Text('CLEAR CAPTURE'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('debug-console-copy-capture'),
                    tooltip: 'COPY FROZEN CAPTURE',
                    onPressed: FluviDiagnosticLogger.captureEntries.isEmpty
                        ? null
                        : _copyCapture,
                    icon: Icon(
                      _captureCopied ? Icons.check : Icons.copy_outlined,
                      size: 16,
                    ),
                    color: _captureCopied
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF89B4FA),
                  ),
                  const Spacer(),
                  Text(
                    'C${FluviDiagnosticLogger.captureId} '
                    '${FluviDiagnosticLogger.captureActive ? 'REC' : (FluviDiagnosticLogger.captureFrozen ? 'FROZEN' : 'IDLE')}',
                    key: const ValueKey('debug-console-capture-status'),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ],
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
                if (widget.automationPermissions != null)
                  _sectionButton(
                    key: const ValueKey('debug-console-push-tab'),
                    label: 'PUSH',
                    selected: _section == _DebugConsoleSection.push,
                    onPressed: () {
                      setState(() => _section = _DebugConsoleSection.push);
                      _refreshPush();
                    },
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
      final entries = _filteredEntries();
      return entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Még nincs log ebben a szűrőben.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          : Stack(
              children: [
                ListView.builder(
                  key: const ValueKey('debug-console-logs'),
                  controller: _logsScrollController,
                  reverse: true,
                  itemCount: entries.length,
                  cacheExtent: 320,
                  findChildIndexCallback: (key) {
                    if (key is! ValueKey<int>) return null;
                    for (
                      var index = entries.length - 1;
                      index >= 0;
                      index -= 1
                    ) {
                      if (entries[index].sequence == key.value) {
                        return entries.length - 1 - index;
                      }
                    }
                    return null;
                  },
                  itemBuilder: (context, reverseIndex) {
                    final event = entries[entries.length - 1 - reverseIndex];
                    return Padding(
                      key: ValueKey<int>(event.sequence ?? reverseIndex),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      child: SelectableText(
                        event.toLine(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Color(0xFFCDD6F4),
                        ),
                      ),
                    );
                  },
                ),
                if (!_following && _unseenCount > 0)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FilledButton.icon(
                      key: const ValueKey('debug-console-jump-live'),
                      onPressed: _returnToLive,
                      icon: const Icon(Icons.south, size: 15),
                      label: Text('+$_unseenCount new'),
                    ),
                  ),
              ],
            );
    }
    if (_section == _DebugConsoleSection.push) return _pushBody();
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

  Widget _pushBody() {
    final snapshot = _pushSnapshot;
    if (_loadingPush && snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _refreshPush,
          icon: const Icon(Icons.refresh),
          label: const Text('Frissítés'),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('debug-console-push-send-test'),
                onPressed: _loadingPush ? null : _sendPushProbe,
                icon: const Icon(Icons.send_outlined, size: 15),
                label: const Text('Saját teszt küldése'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('debug-console-push-refresh'),
                onPressed: _loadingPush ? null : _refreshPush,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Frissítés'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('debug-console-push-copy'),
                onPressed: _copyPushDiagnostics,
                icon: Icon(
                  _pushCopied ? Icons.check : Icons.copy_outlined,
                  size: 15,
                ),
                label: const Text('Diagnosztika másolása'),
              ),
              TextButton(
                key: const ValueKey('debug-console-push-clear'),
                onPressed: _clearPushDiagnostics,
                child: const Text('Törlés'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          child: SelectableText(
            'Értesítésfigyelő: ${snapshot.listenerConnected ? 'csatlakozva' : 'még nem csatlakozott'}\n'
            'Build: ${snapshot.buildVersion ?? '—'} (${snapshot.buildCode ?? '—'}) · Android API ${snapshot.androidApi ?? '—'}\n'
            'Saját értesítések: ${snapshot.postNotificationsGranted && snapshot.appNotificationsEnabled && snapshot.testChannelEnabled ? 'engedélyezve' : 'nem küldhető'}\n'
            'Alkalmazáslista: ${snapshot.applicationListMode} · ${snapshot.applicationListFound} talált · ${snapshot.applicationListVisible} megjeleníthető\n'
            'Utolsó próba: ${snapshot.lastTestStep ?? '—'} · ${snapshot.lastTestResult ?? '—'}'
            '${snapshot.applicationListError == null ? '' : '\nAlkalmazáslista hiba: ${snapshot.applicationListError}'}',
            key: const ValueKey('debug-console-push-status'),
            style: const TextStyle(
              color: Color(0xFFBAC2DE),
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF313244)),
        Expanded(
          child: snapshot.events.isEmpty
              ? const Center(
                  child: Text(
                    'Még nincs push diagnosztikai esemény.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('debug-console-push-events'),
                  itemCount: snapshot.events.length,
                  itemBuilder: (context, index) {
                    final event = snapshot.events[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: SelectableText(
                        '${DateTime.fromMillisecondsSinceEpoch(event.atUtcMs).toLocal().toIso8601String().substring(11, 19)} · ${event.code}\n${event.message}${event.sourcePackage == null ? '' : '\n${event.sourcePackage}'}',
                        style: const TextStyle(
                          color: Color(0xFFCDD6F4),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<FluviDiagnosticEvent> _filteredEntries() {
    final entries = FluviDiagnosticLogger.entries;
    return List<FluviDiagnosticEvent>.unmodifiable(
      entries.where(
        (entry) => switch (_logFilter) {
          _DebugConsoleLogFilter.all => true,
          _DebugConsoleLogFilter.mindHeatmap =>
            entry.stage.startsWith('MIND_HEATMAP|') ||
                entry.stage.startsWith('MIND_TEMPORAL_HEATMAP|') ||
                entry.stage.startsWith('MIND_SUM|') ||
                entry.stage.startsWith('MIND_ENTRY|'),
          _DebugConsoleLogFilter.balanceWave => entry.stage.startsWith(
            'BALANCE_WAVE|',
          ),
          _DebugConsoleLogFilter.ghost => entry.isGhostDiagnostic,
        },
      ),
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
