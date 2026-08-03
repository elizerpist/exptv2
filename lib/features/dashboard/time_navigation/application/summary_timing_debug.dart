import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_query_debug.dart';

/// Debug-only event marks for tracing preview/settled navigation latency.
abstract final class DashboardSummaryTimingDebug {
  /// Disabled by default because preview callbacks are on the carousel hot
  /// path. Enable only for an explicit timing investigation.
  static const _enabled = bool.fromEnvironment('FLUVI_TRACE_SUMMARY_TIMING');

  static bool get isEnabled => _enabled;

  static void mark(String event, {Object? value}) {
    // The timing trace is explicitly opt-in. In particular, a rail preview
    // tick must not even enter the assert closure that formats a FLOW event.
    if (!_enabled) return;
    assert(() {
      if (event.startsWith('R')) {
        DashboardQueryDebug.mark(
          event,
          detail: value == null ? null : 'value=$value',
        );
      }
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = value == null ? '' : ' value=$value';
      debugPrint('[SummaryTiming] event=$event time=$timestamp$suffix');
      return true;
    }());
  }
}
