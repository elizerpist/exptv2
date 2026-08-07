import 'package:flutter/widgets.dart';

import 'fluvi_diagnostic_event.dart';
import 'fluvi_onscreen_diagnostics.dart';

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
  static final List<FluviDiagnosticEvent> _entries = <FluviDiagnosticEvent>[];
  static final _FluviDiagnosticNotifier _version = _FluviDiagnosticNotifier(0);
  static var _notifyScheduled = false;

  static void log(FluviDiagnosticEvent event) {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    if (_entries.length >= maxEntries) _entries.removeAt(0);
    _entries.add(
      event.timestamp == null ? event.withTimestamp(DateTime.now()) : event,
    );
    _scheduleNotify();
  }

  static void ingestNative(Object? raw) {
    if (!kFluviOnscreenDiagnosticsEnabled || raw is! Map) return;
    final map = raw.map<Object?, Object?>((key, value) => MapEntry(key, value));
    log(FluviDiagnosticEvent.fromMap(map));
  }

  static void clear() {
    _entries.clear();
    _scheduleNotify();
  }

  static List<FluviDiagnosticEvent> get entries =>
      List<FluviDiagnosticEvent>.unmodifiable(_entries);

  static String get allText =>
      _entries.map((event) => event.toLine()).join('\n');

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
