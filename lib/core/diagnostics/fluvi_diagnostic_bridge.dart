import 'package:flutter/services.dart';

import 'fluvi_diagnostic_event.dart';
import 'fluvi_onscreen_diagnostics.dart';

/// Debug-only native sink for the on-screen signal-path logger.
///
/// The bridge deliberately exposes events, not database or query state. The
/// application shell forwards them to [FluviDiagnosticLogger], while the
/// debug overlay remains a presentation-only projection.
class FluviDiagnosticBridge {
  FluviDiagnosticBridge({EventChannel? channel})
    : _channel = channel ?? const EventChannel(_channelName);

  static const _channelName = 'com.fluvi/diagnostics';

  final EventChannel _channel;

  Stream<FluviDiagnosticEvent> watch() {
    if (!kFluviOnscreenDiagnosticsEnabled) {
      return const Stream<FluviDiagnosticEvent>.empty();
    }
    return _channel
        .receiveBroadcastStream()
        .where((raw) => raw is Map)
        .cast<Map>()
        .map((raw) {
          final map = raw.map<Object?, Object?>(
            (key, value) => MapEntry<Object?, Object?>(key, value),
          );
          return FluviDiagnosticEvent.fromMap(map);
        });
  }
}
