import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/copy_last_unlock.dart';
import '../diagnostics/fluvi_build_identity.dart';

/// The native process owns recording and the immutable frozen text.
class DebugLockscreenCapture extends StatefulWidget {
  const DebugLockscreenCapture({super.key});

  @override
  State<DebugLockscreenCapture> createState() => _DebugLockscreenCaptureState();
}

class _DebugLockscreenCaptureState extends State<DebugLockscreenCapture>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('fluvi/wa_lockscreen_capture');
  static const _text = TextStyle(color: Color(0xFFCDD6F4));
  Map<String, Object?>? _status;
  Timer? _timer;
  bool _busy = false;
  bool _polling = false;
  int _revision = 0;
  String? _feedback;
  int _armMs = 50;

  bool get _recording => _status?['state'] == 'RECORDING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _timer?.cancel();
    }
  }

  void _resume() {
    unawaited(_refresh());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recording) unawaited(_refresh());
    });
  }

  Future<Map<String, Object?>> _request(String method) async =>
      await _channel.invokeMapMethod<String, Object?>(method, <String, Object?>{
        'purpose': kFluviBuildPurpose.diagnosticLabel,
        if (method == 'start') ...{
          'source': const String.fromEnvironment('FLUVI_BUILD_COMMIT'),
          if (_status?['armAvailable'] == true) 'armMs': _armMs,
        },
      }) ??
      const <String, Object?>{};

  Future<void> _refresh() async {
    if (_busy || _polling) return;
    _polling = true;
    final revision = _revision;
    try {
      final status = await _request('status');
      if (mounted && revision == _revision && !_busy)
        setState(() => _status = status);
    } on Object {
      if (mounted && revision == _revision && !_busy) {
        setState(() => _feedback = 'A felvétel állapota nem olvasható.');
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _run(String method) async {
    if (_busy) return;
    _revision++;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final status = Map<String, Object?>.of(await _request(method));
      if (!mounted) return;
      final text = status.remove('text');
      setState(() => _status = status);
      if (method == 'getFrozen') {
        if (text is! String || text.isEmpty) {
          setState(() => _feedback = 'Nincs másolható felvétel.');
          return;
        }
        try {
          await Clipboard.setData(ClipboardData(text: text));
          if (mounted) {
            setState(() => _feedback = 'Felvétel a vágólapon.');
          }
        } on Object {
          if (mounted) {
            setState(() {
              _feedback = 'A másolás sikertelen. A felvétel megmaradt.';
            });
          }
        }
      }
    } on Object {
      if (mounted) {
        setState(() => _feedback = 'A felvétel művelete sikertelen.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = switch (_status?['state']) {
      'RECORDING' => 'Rögzítés folyamatban',
      'FROZEN' => 'Lezárt felvétel',
      'INTERRUPTED' => 'A felvétel megszakadt',
      'INVALID' => 'A felvétel érvénytelen',
      'IDLE' => 'Nincs felvétel',
      _ => 'Állapot betöltése',
    };
    final service = switch (_status?['service']) {
      'CONNECTED' => 'ORB-szolgáltatás csatlakoztatva',
      'DISABLED' => 'ORB-szolgáltatás kikapcsolva',
      'DISCONNECTED' => 'ORB-szolgáltatás nincs csatlakoztatva',
      _ => '',
    };
    final ms = _status?['elapsedMs'] as int? ?? 0;
    final id = _status?['id'] as String?;
    final drops = _status?['drops'] as int? ?? 0;
    final observed = _status?['effectiveMs'] as int?;
    final arm = _status?['armMs'] as int?;
    final restoration = _status?['restoration'];
    final readback = switch ((restoration, _recording, observed)) {
      ('PENDING', _, _) => 'Visszaállítás függőben',
      ('RESTORED' || 'NORMALIZED', false, 50) => 'Visszaállítva: 50 ms',
      ('ACTIVE', true, final int effective) when effective == arm =>
        'Aktív beállítás: $effective ms',
      (_, _, final int effective) => 'Visszaolvasott beállítás: $effective ms',
      _ => 'A szolgáltatás beállítása nem olvasható.',
    };
    final armError = switch (_status?['armError']) {
      'SERVICE_UNAVAILABLE' =>
        'Kapcsold be az ORB akadálymentesítési szolgáltatást.',
      'FOREGROUND_REQUIRED' => 'Feloldott telefonnál indítsd a felvételt.',
      'WINDOW_ACTIVE' => 'A felvétel indításakor még aktív az ORB ablaka.',
      'ALREADY_RECORDING' => 'A korábbi felvétel még fut.',
      'BASELINE_MISMATCH' => 'Az 50 ms-os alapbeállítás nem igazolható.',
      'ARM_READBACK_FAILED' => 'A szolgáltatás nem igazolta a kért beállítást.',
      'TIMEOUT_CHANGED' =>
        'A szolgáltatás beállítása megváltozott a felvétel alatt.',
      'SERVICE_DISCONNECTED' =>
        'Az ORB-szolgáltatás kapcsolatát bontotta a rendszer.',
      'CAPTURE_SETUP_FAILED' || 'INVALID_ARM' => 'A mérés indítása sikertelen.',
      _ => null,
    };
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const CopyLastUnlock(feedbackStyle: _text),
        Text(state, style: _text, key: const ValueKey('wa-capture-state')),
        if (service.isNotEmpty) Text(service, style: _text),
        if (_status?['armAvailable'] == true) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final value in [50, 0])
                ChoiceChip(
                  key: ValueKey('wa-capture-arm-$value'),
                  label: Text(value == 50 ? 'A · 50 ms' : 'B · 0 ms'),
                  selected: (_recording ? arm : _armMs) == value,
                  onSelected: _busy || _recording
                      ? null
                      : (_) => setState(() => _armMs = value),
                ),
            ],
          ),
          Text(
            readback,
            style: _text,
            key: const ValueKey('wa-capture-arm-status'),
          ),
        ],
        if (armError != null) Text(armError, style: _text),
        if (id != null) ...[
          Text('Azonosító $id', style: _text),
          Text(
            'Időtartam ${(ms / 1000).toStringAsFixed(1)} mp · Kihagyott rekordok $drops',
            style: _text,
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton(
              key: const ValueKey('wa-capture-toggle'),
              onPressed: _busy
                  ? null
                  : () => _run(_recording ? 'stop' : 'start'),
              child: Text(_recording ? 'Leállítás' : 'Felvétel indítása'),
            ),
            OutlinedButton(
              key: const ValueKey('wa-capture-copy'),
              onPressed: _busy || _status?['hasCapture'] != true
                  ? null
                  : () => _run('getFrozen'),
              child: const Text('Vágólapra másolás'),
            ),
          ],
        ),
        if (_status?['storageError'] == true)
          const Text('A felvétel csak a memóriában érhető el.', style: _text),
        if (_feedback != null)
          Text(
            _feedback!,
            style: _text,
            key: const ValueKey('wa-capture-feedback'),
          ),
      ],
    );
  }
}
