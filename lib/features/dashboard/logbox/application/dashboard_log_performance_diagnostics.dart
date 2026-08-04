import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';

/// Measured phases of the LogBox presentation lane.
///
/// These values are intentionally typed and compact. They can be collected in
/// profile mode without constructing a verbose FLOW string for every rail
/// crossing.
enum DashboardLogPerformancePhase {
  railPreviewLookup,
  summaryPreviewBind,
  logBoxPreviewSelect,
  logBoxViewModelProject,
  logBoxWidgetBuild,
  logBoxLayout,
  logBoxPaint,
}

@immutable
class DashboardLogPerformanceSample {
  const DashboardLogPerformanceSample({
    required this.phase,
    required this.queryKey,
    required this.entryCount,
    required this.rowCount,
    required this.dataAttached,
    required this.durationMicros,
    required this.motionEpoch,
  });

  final DashboardLogPerformancePhase phase;
  final LedgerQueryKey queryKey;
  final int entryCount;
  final int rowCount;
  final bool dataAttached;
  final int durationMicros;
  final int motionEpoch;
}

/// Bounded numeric diagnostics for LogBox work.
///
/// The default is enabled outside release builds and can be disabled by the
/// owner when profiling a completely detached baseline. Recording is a cheap
/// no-op when disabled, so the production presentation path does not depend
/// on the diagnostics sink.
class DashboardLogPerformanceDiagnostics {
  DashboardLogPerformanceDiagnostics({int capacity = 512, bool? enabled})
    : assert(capacity > 0),
      _capacity = capacity,
      enabled = enabled ?? !kReleaseMode;

  final int _capacity;
  final bool enabled;
  final ListQueue<DashboardLogPerformanceSample> _samples =
      ListQueue<DashboardLogPerformanceSample>();
  final Map<DashboardLogPerformancePhase, int> _counts =
      <DashboardLogPerformancePhase, int>{};
  final Map<DashboardLogPerformancePhase, int> _totalMicros =
      <DashboardLogPerformancePhase, int>{};

  List<DashboardLogPerformanceSample> get samples =>
      List<DashboardLogPerformanceSample>.unmodifiable(_samples);

  int countFor(DashboardLogPerformancePhase phase) => _counts[phase] ?? 0;

  int totalMicrosFor(DashboardLogPerformancePhase phase) =>
      _totalMicros[phase] ?? 0;

  void record({
    required DashboardLogPerformancePhase phase,
    required LedgerQueryKey queryKey,
    required int entryCount,
    required int rowCount,
    required bool dataAttached,
    required int durationMicros,
    required int motionEpoch,
  }) {
    if (!enabled) return;
    final sample = DashboardLogPerformanceSample(
      phase: phase,
      queryKey: queryKey,
      entryCount: entryCount,
      rowCount: rowCount,
      dataAttached: dataAttached,
      durationMicros: durationMicros,
      motionEpoch: motionEpoch,
    );
    _samples.addLast(sample);
    while (_samples.length > _capacity) {
      _samples.removeFirst();
    }
    _counts[phase] = countFor(phase) + 1;
    _totalMicros[phase] = totalMicrosFor(phase) + durationMicros;
  }
}
