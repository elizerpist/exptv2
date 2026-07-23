import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../debug/debug_console.dart';

enum KeyboardAnimationPhase { listen, start, progress, end, unknown }

class NativeKeyboardAnimationSession {
  const NativeKeyboardAnimationSession({
    required this.phase,
    required this.sequence,
    required this.startInset,
    required this.endInset,
    required this.currentInset,
    required this.duration,
    required this.fraction,
    required this.receivedAt,
    this.startedAt,
    this.eventNanos,
    this.nativeSource,
  });

  final KeyboardAnimationPhase phase;
  final int sequence;
  final double startInset;
  final double endInset;
  final double currentInset;
  final Duration duration;
  final double fraction;
  final DateTime receivedAt;
  final DateTime? startedAt;
  final int? eventNanos;
  final String? nativeSource;

  bool get isActive =>
      phase == KeyboardAnimationPhase.start ||
      phase == KeyboardAnimationPhase.progress;

  static NativeKeyboardAnimationSession? fromEvent(Object? event) {
    if (event is! Map) return null;
    if (event['kind']?.toString() != 'session') return null;

    final startInset = NativeKeyboardInsetSample._doubleFrom(
      event['startImeDp'] ?? event['startInset'],
    );
    final endInset = NativeKeyboardInsetSample._doubleFrom(
      event['endImeDp'] ?? event['endInset'],
    );
    final currentInset = NativeKeyboardInsetSample._doubleFrom(
      event['imeDp'] ?? event['inset'],
    );
    if (startInset == null || endInset == null || currentInset == null) {
      return null;
    }

    return NativeKeyboardAnimationSession(
      phase: _phaseFrom(event['phase']),
      sequence:
          NativeKeyboardInsetSample._intFrom(
            event['seq'] ?? event['sequence'],
          ) ??
          0,
      startInset: startInset,
      endInset: endInset,
      currentInset: currentInset,
      duration: Duration(
        milliseconds:
            NativeKeyboardInsetSample._intFrom(event['durationMs']) ?? 0,
      ),
      fraction: (NativeKeyboardInsetSample._doubleFrom(event['fraction']) ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      receivedAt: DateTime.now(),
      startedAt: _dateFromEpochMillis(
        event['startedAtEpochMs'] ?? event['startedAtMillis'],
      ),
      eventNanos: NativeKeyboardInsetSample._intFrom(event['eventNanos']),
      nativeSource: event['nativeSource']?.toString(),
    );
  }

  double progressAt(DateTime now) {
    final durationMs = duration.inMilliseconds;
    if (durationMs <= 0) return fraction.clamp(0.0, 1.0).toDouble();
    final anchor = startedAt;
    if (anchor != null) {
      return (now.difference(anchor).inMilliseconds / durationMs)
          .clamp(0.0, 1.0)
          .toDouble();
    }
    final elapsedSinceSample = now.difference(receivedAt).inMilliseconds;
    return (fraction + elapsedSinceSample / durationMs)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static DateTime? _dateFromEpochMillis(Object? value) {
    final millis = NativeKeyboardInsetSample._intFrom(value);
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static KeyboardAnimationPhase _phaseFrom(Object? phase) {
    switch (phase?.toString()) {
      case 'listen':
        return KeyboardAnimationPhase.listen;
      case 'start':
        return KeyboardAnimationPhase.start;
      case 'progress':
        return KeyboardAnimationPhase.progress;
      case 'end':
        return KeyboardAnimationPhase.end;
      default:
        return KeyboardAnimationPhase.unknown;
    }
  }
}

class NativeKeyboardInsetSample {
  const NativeKeyboardInsetSample({
    required this.inset,
    required this.source,
    required this.phase,
    required this.sequence,
    required this.receivedAt,
    this.frameNanos,
    this.eventNanos,
    this.fraction,
    this.nativeSource,
  });

  final double inset;
  final String source;
  final String phase;
  final int sequence;
  final DateTime receivedAt;
  final int? frameNanos;
  final int? eventNanos;
  final double? fraction;
  final String? nativeSource;

  static NativeKeyboardInsetSample? fromEvent(Object? event) {
    if (event is! Map) return null;
    final inset = _doubleFrom(event['imeDp'] ?? event['inset']);
    if (inset == null) return null;
    return NativeKeyboardInsetSample(
      inset: inset,
      source: event['source']?.toString() ?? 'native-ime',
      phase: event['phase']?.toString() ?? 'unknown',
      sequence: _intFrom(event['seq'] ?? event['sequence']) ?? 0,
      receivedAt: DateTime.now(),
      frameNanos: _intFrom(event['frameNanos']),
      eventNanos: _intFrom(event['eventNanos']),
      fraction: _doubleFrom(event['fraction']),
      nativeSource: event['nativeSource']?.toString(),
    );
  }

  static double? _doubleFrom(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _intFrom(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class ResolvedKeyboardInset {
  const ResolvedKeyboardInset({
    required this.inset,
    required this.source,
    required this.fallbackInset,
    this.phase,
    this.sequence,
    this.ageMs,
    this.nativeSource,
  });

  final double inset;
  final String source;
  final double fallbackInset;
  final String? phase;
  final int? sequence;
  final int? ageMs;
  final String? nativeSource;
}

class NativeKeyboardInsetResolver {
  const NativeKeyboardInsetResolver._();

  static const freshWindow = Duration(milliseconds: 300);

  static ResolvedKeyboardInset resolve({
    required NativeKeyboardInsetSample? nativeSample,
    required double fallbackInset,
    required DateTime now,
  }) {
    final native = nativeSample;
    if (native == null) {
      return ResolvedKeyboardInset(
        inset: fallbackInset,
        source: 'flutter-viewInsets',
        fallbackInset: fallbackInset,
      );
    }

    final ageMs = now.difference(native.receivedAt).inMilliseconds;
    final fresh = ageMs <= freshWindow.inMilliseconds;
    if (fresh) {
      return ResolvedKeyboardInset(
        inset: native.inset,
        source: native.source,
        fallbackInset: fallbackInset,
        phase: native.phase,
        sequence: native.sequence,
        ageMs: ageMs,
        nativeSource: native.nativeSource,
      );
    }

    return ResolvedKeyboardInset(
      inset: fallbackInset,
      source: 'flutter-viewInsets',
      fallbackInset: fallbackInset,
      phase: 'native-stale',
      sequence: native.sequence,
      ageMs: ageMs,
      nativeSource: native.nativeSource,
    );
  }
}

class KeyboardInsetMotionCoordinator {
  const KeyboardInsetMotionCoordinator._();

  static const staleWindow = NativeKeyboardInsetResolver.freshWindow;
  static const mismatchThreshold = 24.0;

  static ResolvedKeyboardInset resolveIdle({
    required NativeKeyboardInsetSample? nativeSample,
    required double fallbackInset,
    required DateTime now,
  }) {
    final native = nativeSample;
    if (native == null) {
      return ResolvedKeyboardInset(
        inset: fallbackInset,
        source: 'flutter-viewInsets',
        fallbackInset: fallbackInset,
      );
    }

    final ageMs = now.difference(native.receivedAt).inMilliseconds;
    final largeMismatch =
        (native.inset - fallbackInset).abs() > mismatchThreshold;
    final nativeAnimationSample =
        native.nativeSource == 'WindowInsetsAnimation' ||
        native.phase == 'progress';
    if (ageMs <= staleWindow.inMilliseconds &&
        nativeAnimationSample &&
        largeMismatch) {
      return ResolvedKeyboardInset(
        inset: fallbackInset,
        source: 'flutter-viewInsets',
        fallbackInset: fallbackInset,
        phase: 'native-behind-fallback',
        sequence: native.sequence,
        ageMs: ageMs,
        nativeSource: native.nativeSource,
      );
    }

    return NativeKeyboardInsetResolver.resolve(
      nativeSample: native,
      fallbackInset: fallbackInset,
      now: now,
    );
  }

  static ResolvedKeyboardInset interpolateSession({
    required NativeKeyboardAnimationSession session,
    required DateTime now,
    required double fallbackInset,
  }) {
    if (session.phase == KeyboardAnimationPhase.end) {
      return ResolvedKeyboardInset(
        inset: fallbackInset,
        source: 'flutter-viewInsets',
        fallbackInset: fallbackInset,
        phase: 'session-ended',
        sequence: session.sequence,
        ageMs: now.difference(session.receivedAt).inMilliseconds,
        nativeSource: session.nativeSource,
      );
    }

    final elapsed = now.difference(session.startedAt ?? session.receivedAt);
    final progress = session.progressAt(now);
    final inset =
        session.startInset + (session.endInset - session.startInset) * progress;
    return ResolvedKeyboardInset(
      inset: inset,
      source: 'local-ime-session',
      fallbackInset: fallbackInset,
      phase: progress >= 1 ? 'session-complete' : 'session-active',
      sequence: session.sequence,
      ageMs: elapsed.inMilliseconds,
      nativeSource: session.nativeSource,
    );
  }
}

class NativeKeyboardInsetSampleGate {
  NativeKeyboardInsetSample? _lastPublished;

  bool shouldPublish(NativeKeyboardInsetSample sample) {
    final previous = _lastPublished;
    if (previous == null) {
      _lastPublished = sample;
      return true;
    }

    final endpoint =
        sample.phase == 'listen' ||
        sample.phase == 'start' ||
        sample.phase == 'end' ||
        sample.phase == 'apply';
    final insetChanged = (sample.inset - previous.inset).abs() >= 0.5;
    final sourceChanged = sample.source != previous.source;
    if (endpoint || insetChanged || sourceChanged) {
      _lastPublished = sample;
      return true;
    }
    return false;
  }

  void reset() {
    _lastPublished = null;
  }
}

class NativeKeyboardInsets extends ChangeNotifier {
  NativeKeyboardInsets._();

  static final NativeKeyboardInsets instance = NativeKeyboardInsets._();

  EventChannel _eventChannel = const EventChannel('exptv2/keyboard_insets');
  StreamSubscription<Object?>? _subscription;
  NativeKeyboardInsetSample? _latest;
  NativeKeyboardAnimationSession? _latestSession;
  final NativeKeyboardInsetSampleGate _sampleGate =
      NativeKeyboardInsetSampleGate();
  var _started = false;
  var _streamErrorLogged = false;
  var _nativeSheetSuspendCount = 0;

  NativeKeyboardInsetSample? get latest => _latest;
  NativeKeyboardAnimationSession? get latestSession => _latestSession;
  bool get suspendedForNativeSheet => _nativeSheetSuspendCount > 0;

  void suspendForNativeSheet() {
    _nativeSheetSuspendCount += 1;
    _latest = null;
    _latestSession = null;
    _sampleGate.reset();
    DebugConsole.log(
      '[KeyboardNative] suspended for native sheet count=$_nativeSheetSuspendCount',
    );
    notifyListeners();
  }

  void resumeForNativeSheet() {
    if (_nativeSheetSuspendCount > 0) {
      _nativeSheetSuspendCount -= 1;
    }
    DebugConsole.log(
      '[KeyboardNative] resumed for native sheet count=$_nativeSheetSuspendCount',
    );
    if (_nativeSheetSuspendCount == 0) {
      _latest = null;
      _latestSession = null;
      _sampleGate.reset();
    }
    notifyListeners();
  }

  void ensureStarted() {
    if (kIsWeb) return;
    if (_started) return;
    _started = true;
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: _handleStreamError,
      cancelOnError: false,
    );
  }

  void _handleEvent(Object? event) {
    if (suspendedForNativeSheet) return;
    final session = NativeKeyboardAnimationSession.fromEvent(event);
    if (session != null) {
      _latestSession = session;
      DebugConsole.log(
        '[KeyboardNativeSession] seq=${session.sequence} '
        'phase=${session.phase.name} '
        'start=${session.startInset.toStringAsFixed(1)} '
        'end=${session.endInset.toStringAsFixed(1)} '
        'current=${session.currentInset.toStringAsFixed(1)} '
        'duration=${session.duration.inMilliseconds}ms '
        'fraction=${session.fraction.toStringAsFixed(3)} '
        'source=${session.nativeSource ?? 'native-ime'}',
      );
      notifyListeners();
      return;
    }

    final sample = NativeKeyboardInsetSample.fromEvent(event);
    if (sample == null) return;
    if (!_sampleGate.shouldPublish(sample)) return;
    _latest = sample;
    DebugConsole.log(
      '[KeyboardNative] seq=${sample.sequence} phase=${sample.phase} '
      'imeDp=${sample.inset.toStringAsFixed(1)} '
      'fraction=${sample.fraction?.toStringAsFixed(3) ?? 'n/a'} '
      'source=${sample.nativeSource ?? sample.source}',
    );
    notifyListeners();
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (_streamErrorLogged) return;
    _streamErrorLogged = true;
    DebugConsole.log('[KeyboardNative] stream unavailable error=$error');
  }

  @visibleForTesting
  void debugSetSampleForTesting(NativeKeyboardInsetSample sample) {
    if (suspendedForNativeSheet) return;
    _latest = sample;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetSessionForTesting(NativeKeyboardAnimationSession session) {
    if (suspendedForNativeSheet) return;
    _latestSession = session;
    notifyListeners();
  }

  @visibleForTesting
  void debugResetForTesting() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    _latest = null;
    _latestSession = null;
    _sampleGate.reset();
    _streamErrorLogged = false;
    _nativeSheetSuspendCount = 0;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetEventChannelForTesting(EventChannel eventChannel) {
    _eventChannel = eventChannel;
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    _sampleGate.reset();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
