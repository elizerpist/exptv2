import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fluvi_diagnostic_event.dart';

class _FluviDiagnosticNotifier extends ValueNotifier<int> {
  _FluviDiagnosticNotifier(super.value);

  var _listenerCount = 0;

  bool get hasExternalListeners => _listenerCount > 0;

  @override
  void addListener(VoidCallback listener) {
    _listenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_listenerCount > 0) _listenerCount -= 1;
    super.removeListener(listener);
  }
}

/// The single debug-only sink used by the on-screen diagnostic projection.
abstract final class FluviDiagnosticLogger {
  static const maxEntries = 500;
  static final List<FluviDiagnosticEvent?> _ring =
      List<FluviDiagnosticEvent?>.filled(maxEntries, null);
  static int _ringStart = 0;
  static int _ringLength = 0;
  static final _FluviDiagnosticNotifier _version = _FluviDiagnosticNotifier(0);
  static var _notifyScheduled = false;

  static void log(FluviDiagnosticEvent event) {
    if (!kDebugMode) return;
    final insertionIndex = (_ringStart + _ringLength) % maxEntries;
    _ring[insertionIndex] = event.timestamp == null
        ? event.withTimestamp(DateTime.now())
        : event;
    if (_ringLength < maxEntries) {
      _ringLength += 1;
    } else {
      _ringStart = (_ringStart + 1) % maxEntries;
    }
    _scheduleNotify();
  }

  static void ingestNative(Object? raw) {
    if (!kDebugMode || raw is! Map) return;
    final map = raw.map<Object?, Object?>((key, value) => MapEntry(key, value));
    log(FluviDiagnosticEvent.fromMap(map));
  }

  static void clear() {
    _ring.fillRange(0, maxEntries);
    _ringStart = 0;
    _ringLength = 0;
    _scheduleNotify();
  }

  /// This projection is requested only by the open debug panel or tests. Hot
  /// append remains O(1) and never formats the event's FLOW string.
  static List<FluviDiagnosticEvent> get entries =>
      List<FluviDiagnosticEvent>.unmodifiable([
        for (var offset = 0; offset < _ringLength; offset += 1)
          _ring[(_ringStart + offset) % maxEntries]!,
      ]);

  /// Formatting is intentionally lazy: closed panels neither subscribe nor
  /// call this getter, while an open panel receives at most one refresh/frame.
  static String get allText =>
      entries.map((event) => event.toLine()).join('\n');

  static ValueNotifier<int> get notifier => _version;

  static void _scheduleNotify() {
    if (!_version.hasExternalListeners) return;
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
}
