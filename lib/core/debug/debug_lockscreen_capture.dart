import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      await _channel.invokeMapMethod<String, Object?>(
        method,
        method == 'start'
            ? <String, Object?>{
                'source': const String.fromEnvironment('FLUVI_BUILD_COMMIT'),
                'purpose': kFluviBuildPurpose.diagnosticLabel,
              }
            : null,
      ) ??
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
      'INTERRUPTED' => 'A felvétel megszakadt a folyamat leállásakor',
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Text(state, style: _text, key: const ValueKey('wa-capture-state')),
        if (service.isNotEmpty) Text(service, style: _text),
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
