import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_query_debug.dart';

/// Debug-only event marks for tracing preview/settled navigation latency.
abstract final class DashboardSummaryTimingDebug {
  /// Disabled by default because preview callbacks are on the carousel hot
  /// path. Enable only for an explicit timing investigation.
  static const _enabled = bool.fromEnvironment('FLUVI_TRACE_SUMMARY_TIMING');

  static void mark(String event, {Object? value}) {
    assert(() {
      // R1 runs for every visual center crossed during a fling. Persisting a
      // FLOW line from that callback makes diagnostic work part of the rail's
      // frame budget. Keep the lower-frequency settle marks enabled, and opt
      // into R1 only for an explicit timing trace.
      final isPreviewCenter = event.startsWith('R1 ');
      if (event.startsWith('R') && (!isPreviewCenter || _enabled)) {
        DashboardQueryDebug.mark(
          event,
          detail: value == null ? null : 'value=$value',
        );
      }
      if (!_enabled) return true;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = value == null ? '' : ' value=$value';
      debugPrint('[SummaryTiming] event=$event time=$timestamp$suffix');
      return true;
    }());
  }
}
