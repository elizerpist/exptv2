import 'package:flutter/foundation.dart';

/// Structured timings for one parent/bounded-preview batch.
///
/// The read layer may populate this record without assembling a verbose log
/// string on the rail path. Durations are integer milliseconds so the model is
/// cheap to pass across a diagnostic boundary and deterministic in tests.
@immutable
class DashboardBatchMetrics {
  const DashboardBatchMetrics({
    required this.sqlMs,
    required this.nativeProjectionMs,
    required this.payloadBytes,
    required this.dartDecodeMs,
    required this.dartProjectionMs,
    required this.cacheInsertionMs,
    required this.snapshotCount,
    required this.rowCount,
  });

  final int sqlMs;
  final int nativeProjectionMs;
  final int payloadBytes;
  final int dartDecodeMs;
  final int dartProjectionMs;
  final int cacheInsertionMs;
  final int snapshotCount;
  final int rowCount;

  int get totalMeasuredMs =>
      sqlMs +
      nativeProjectionMs +
      dartDecodeMs +
      dartProjectionMs +
      cacheInsertionMs;
}
