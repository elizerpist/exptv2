import 'package:flutter/foundation.dart';

/// Debug-only event marks for tracing preview/settled navigation latency.
abstract final class DashboardSummaryTimingDebug {
  static void mark(String event, {Object? value}) {
    assert(() {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final suffix = value == null ? '' : ' value=$value';
      debugPrint('[SummaryTiming] event=$event time=$timestamp$suffix');
      return true;
    }());
  }
}
