import 'package:flutter/foundation.dart';

/// Debug-only event marks for tracing preview/settled navigation latency.
abstract final class DashboardSummaryTimingDebug {
  /// Disabled by default because preview callbacks are on the carousel hot
  /// path. Enable only for an explicit timing investigation.
  static const _enabled = bool.fromEnvironment('FLUVI_TRACE_SUMMARY_TIMING');

  static void mark(String event, {Object? value}) {
    assert(() {
      if (!_enabled) return true;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = value == null ? '' : ' value=$value';
      debugPrint('[SummaryTiming] event=$event time=$timestamp$suffix');
      return true;
    }());
  }
}
