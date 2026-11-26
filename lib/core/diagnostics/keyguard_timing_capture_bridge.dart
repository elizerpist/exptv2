import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum KeyguardTimingCaptureMode {
  light('LIGHT'),
  full('FULL');

  const KeyguardTimingCaptureMode(this.wireValue);

  final String wireValue;
}

enum KeyguardOrbRenderMode {
  surfaceLive('SURFACE_LIVE'),
  surfaceStatic('SURFACE_STATIC'),
  legacyR11('LEGACY_R11');

  const KeyguardOrbRenderMode(this.wireValue);
  final String wireValue;

  static KeyguardOrbRenderMode fromWire(Object? value) => values.firstWhere(
    (mode) => mode.wireValue == value,
    orElse: () => surfaceLive,
  );
}

enum KeyguardDisplayRoute {
  fluviStream('FLUVI_STREAM'),
  widgetsAnywhere('WIDGETS_ANYWHERE');

  const KeyguardDisplayRoute(this.wireValue);
  final String wireValue;

  static KeyguardDisplayRoute fromWire(Object? value) => values.firstWhere(
    (route) => route.wireValue == value,
    orElse: () => fluviStream,
  );
}

@immutable
class KeyguardDisplayRouteStatus {
  const KeyguardDisplayRouteStatus({
    required this.available,
    required this.connected,
    required this.configured,
    required this.active,
    required this.reason,
    this.sampleOnly = false,
  });

  factory KeyguardDisplayRouteStatus.fromMap(Map<Object?, Object?> map) =>
      KeyguardDisplayRouteStatus(
        available:
            map['available'] == true &&
            KeyguardDisplayRoute.values.any(
              (route) => route.wireValue == map['configured'],
            ),
        connected: map['connected'] == true,
        configured: KeyguardDisplayRoute.fromWire(map['configured']),
        active: map['active']?.toString() ?? 'NONE',
        reason: map['reason']?.toString() ?? 'UNOBSERVED',
        sampleOnly: map['sampleOnly'] == true,
      );

  final bool available;
  final bool connected;
  final KeyguardDisplayRoute configured;
  final String active;
  final String reason;
  final bool sampleOnly;
}

@immutable
class KeyguardOrbRenderModeStatus {
  const KeyguardOrbRenderModeStatus({
    required this.available,
    required this.configured,
    required this.effective,
    required this.pendingBoundary,
  });

  factory KeyguardOrbRenderModeStatus.fromMap(Map<Object?, Object?> map) =>
      KeyguardOrbRenderModeStatus(
        available:
            map['available'] == true &&
            KeyguardOrbRenderMode.values.any(
              (mode) => mode.wireValue == map['configured'],
            ) &&
            KeyguardOrbRenderMode.values.any(
              (mode) => mode.wireValue == map['effective'],
            ),
        configured: KeyguardOrbRenderMode.fromWire(map['configured']),
        effective: KeyguardOrbRenderMode.fromWire(map['effective']),
        pendingBoundary: map['pendingBoundary'] == true,
      );

  final bool available;
  final KeyguardOrbRenderMode configured;
  final KeyguardOrbRenderMode effective;
  final bool pendingBoundary;
}

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

  Future<KeyguardTimingCaptureSnapshot> start({
    KeyguardTimingCaptureMode mode = KeyguardTimingCaptureMode.light,
    bool r43Evidence = false,
  }) => _invoke('startKeyguardDiagnosticCapture', <String, Object?>{
    'build': buildCommit,
    'buildMode': buildMode,
    'captureMode': mode.wireValue,
    'r43Evidence': r43Evidence,
  });

  Future<KeyguardTimingCaptureSnapshot> freeze() =>
      _invoke('freezeKeyguardDiagnosticCapture');

  Future<KeyguardTimingCaptureSnapshot> get() =>
      _invoke('getKeyguardDiagnosticCapture');

  Future<KeyguardTimingCaptureSnapshot> clear() =>
      _invoke('clearKeyguardDiagnosticCapture');

  Future<Map<String, bool>> r44SyntheticTrial({bool? enabled}) async {
    if (!_isAndroid()) return const {'available': false, 'enabled': false};
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      enabled == null ? 'getR44SyntheticTrial' : 'setR44SyntheticTrial',
      enabled == null ? null : <String, Object?>{'enabled': enabled},
    );
    return {
      'available': raw?['available'] == true && raw?['enabled'] is bool,
      'enabled': raw?['enabled'] == true,
    };
  }

  /// The native service, not this bridge, owns the sample/capture receipt.
  Future<Map<Object?, Object?>> startR442SampleCapture({
    KeyguardTimingCaptureMode mode = KeyguardTimingCaptureMode.light,
    bool expanded = false,
    bool oneWakePrint = false,
  }) async {
    if (!_isAndroid()) {
      return const {'active': false, 'reason': 'unsupportedBuild'};
    }
    return await _channel.invokeMapMethod<Object?, Object?>(
          oneWakePrint ? 'startR446PrintCapture' : 'startR442SampleCapture',
          <String, Object?>{
            'build': buildCommit,
            'buildMode': buildMode,
            'captureMode': mode.wireValue,
            'expanded': expanded,
          },
        ) ??
        const {'active': false, 'reason': 'missingReceipt'};
  }

  Future<Map<Object?, Object?>> r442SampleStatus() async {
    if (!_isAndroid()) {
      return const {'active': false, 'reason': 'unsupportedBuild'};
    }
    return await _channel.invokeMapMethod<Object?, Object?>(
          'getR442SampleCaptureStatus',
        ) ??
        const {'active': false, 'reason': 'missingReceipt'};
  }

  /// The selected route is checked again by the live Android service.
  Future<Map<Object?, Object?>> startR449SampleCapture({
    required KeyguardDisplayRoute route,
    KeyguardTimingCaptureMode mode = KeyguardTimingCaptureMode.light,
    bool session = false,
  }) async {
    if (!_isAndroid()) {
      return const {'active': false, 'reason': 'unsupportedBuild'};
    }
    return await _channel.invokeMapMethod<Object?, Object?>(
          'startR449SampleCapture',
          <String, Object?>{
            'build': buildCommit,
            'buildMode': buildMode,
            'captureMode': mode.wireValue,
            'actionKind': session ? 'SESSION' : 'ONE_WAKE',
            'routeRequested': route.wireValue,
          },
        ) ??
        const {'active': false, 'reason': 'missingReceipt'};
  }

  Future<KeyguardOrbRenderModeStatus> getRenderMode() =>
      _invokeRenderMode('getKeyguardOrbRenderMode');

  Future<KeyguardDisplayRouteStatus> getDisplayRoute() =>
      _invokeDisplayRoute('getR448DisplayRoute');

  Future<String> getDisplayComparison() async {
    if (!_isAndroid()) return '';
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getR448Comparison',
    );
    return raw?['report']?.toString() ?? '';
  }

  Future<KeyguardDisplayRouteStatus> setDisplayRoute(
    KeyguardDisplayRoute route,
  ) => _invokeDisplayRoute('setR448DisplayRoute', {'route': route.wireValue});

  Future<KeyguardDisplayRouteStatus> _invokeDisplayRoute(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!_isAndroid()) {
      return const KeyguardDisplayRouteStatus(
        available: false,
        connected: false,
        configured: KeyguardDisplayRoute.fluviStream,
        active: 'NONE',
        reason: 'UNSUPPORTED',
      );
    }
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      method,
      arguments,
    );
    return KeyguardDisplayRouteStatus.fromMap(
      raw ?? const <Object?, Object?>{},
    );
  }

  Future<KeyguardOrbRenderModeStatus> setRenderMode(
    KeyguardOrbRenderMode mode,
  ) => _invokeRenderMode('setKeyguardOrbRenderMode', <String, Object?>{
    'mode': mode.wireValue,
  });

  Future<KeyguardOrbRenderModeStatus> _invokeRenderMode(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!_isAndroid()) {
      return const KeyguardOrbRenderModeStatus(
        available: false,
        configured: KeyguardOrbRenderMode.surfaceLive,
        effective: KeyguardOrbRenderMode.surfaceLive,
        pendingBoundary: false,
      );
    }
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      method,
      arguments,
    );
    return KeyguardOrbRenderModeStatus.fromMap(
      raw ?? const <Object?, Object?>{},
    );
  }

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
    required this.diagnosticDroppedRecords,
    required this.report,
    this.captureMode = 'LIGHT',
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
      diagnosticDroppedRecords: value('diagnosticDroppedRecords', '0'),
      report: value('report', ''),
      captureMode: value('captureMode', 'LIGHT'),
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
        diagnosticDroppedRecords: '0',
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
  final String diagnosticDroppedRecords;
  final String report;
  final String captureMode;
  final bool recoveredFromDisk;
  final String? message;

  bool get recording => state == 'REC';
}
