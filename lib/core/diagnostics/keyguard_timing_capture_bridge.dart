import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Small read/control bridge for the Android-owned keyguard timing capture.
/// It deliberately has no dependency on lock-screen-card repositories, so a
/// debug refresh can never trigger a financial preview, surface inspection or
/// settings update.
class KeyguardTimingCaptureBridge {
  KeyguardTimingCaptureBridge({
    MethodChannel? channel,
    bool Function()? isAndroid,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _isAndroid =
           isAndroid ??
           (() => !kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static const _channelName = 'com.fluvi/runtime_monitoring';
  static const String buildCommit = String.fromEnvironment(
    'FLUVI_BUILD_COMMIT',
    defaultValue: 'unknown',
  );
  static const String buildMode = kProfileMode
      ? 'profile'
      : (kDebugMode ? 'debug' : 'release');

  final MethodChannel _channel;
  final bool Function() _isAndroid;

  bool get isSupportedPlatform => _isAndroid();

  Future<KeyguardTimingCaptureSnapshot> start() => _invoke(
    'startKeyguardDiagnosticCapture',
    <String, Object?>{'build': buildCommit, 'buildMode': buildMode},
  );

  Future<KeyguardTimingCaptureSnapshot> freeze() =>
      _invoke('freezeKeyguardDiagnosticCapture');

  Future<KeyguardTimingCaptureSnapshot> get() =>
      _invoke('getKeyguardDiagnosticCapture');

  Future<KeyguardTimingCaptureSnapshot> clear() =>
      _invoke('clearKeyguardDiagnosticCapture');

  Future<KeyguardTimingCaptureSnapshot> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!_isAndroid()) return KeyguardTimingCaptureSnapshot.unavailable();
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      method,
      arguments,
    );
    return KeyguardTimingCaptureSnapshot.fromMap(
      raw ?? const <Object?, Object?>{},
    );
  }
}

@immutable
class KeyguardTimingCaptureSnapshot {
  const KeyguardTimingCaptureSnapshot({
    required this.available,
    required this.state,
    required this.captureId,
    required this.attemptCount,
    required this.eventsRecorded,
    required this.eventsRetained,
    required this.eventsEvicted,
    required this.eventsCoalesced,
    required this.report,
    this.recoveredFromDisk = false,
    this.message,
  });

  factory KeyguardTimingCaptureSnapshot.fromMap(Map<Object?, Object?> map) {
    String value(String key, [String fallback = '—']) =>
        map[key]?.toString() ?? fallback;
    return KeyguardTimingCaptureSnapshot(
      available: map['available'] == true,
      state: value('captureState', 'IDLE'),
      captureId: value('captureId', '-'),
      attemptCount: value('attemptCount', '0'),
      eventsRecorded: value('eventsRecorded', '0'),
      eventsRetained: value('eventsRetained', '0'),
      eventsEvicted: value('eventsEvicted', '0'),
      eventsCoalesced: value('eventsCoalesced', '0'),
      report: value('report', ''),
      recoveredFromDisk: map['recoveredFromDisk'] == true,
    );
  }

  factory KeyguardTimingCaptureSnapshot.unavailable() =>
      const KeyguardTimingCaptureSnapshot(
        available: false,
        state: 'UNAVAILABLE',
        captureId: '-',
        attemptCount: '0',
        eventsRecorded: '0',
        eventsRetained: '0',
        eventsEvicted: '0',
        eventsCoalesced: '0',
        report: '',
        message: 'A zárképernyő-időzítés rögzítése csak Androidon érhető el.',
      );

  final bool available;
  final String state;
  final String captureId;
  final String attemptCount;
  final String eventsRecorded;
  final String eventsRetained;
  final String eventsEvicted;
  final String eventsCoalesced;
  final String report;
  final bool recoveredFromDisk;
  final String? message;

  bool get recording => state == 'REC';
}
