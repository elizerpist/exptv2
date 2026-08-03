import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Compact, profile-only dashboard trace. It intentionally stores numeric
/// fields only and is independent of the interactive debug-console logger.
enum DashboardPerformanceTraceKind {
  railFlingPlanCreated,
  railLogicalIndexCrossed,
  displaySnapshotSelected,
  logPreviewFirstPaint,
  parentBundleReady,
  frameTiming,
}

@immutable
class DashboardPerformanceTraceEvent {
  const DashboardPerformanceTraceEvent({
    required this.kind,
    required this.timestampMicros,
    this.valueA = 0,
    this.valueB = 0,
  });

  final DashboardPerformanceTraceKind kind;
  final int timestampMicros;
  final int valueA;
  final int valueB;

  @override
  bool operator ==(Object other) =>
      other is DashboardPerformanceTraceEvent &&
      kind == other.kind &&
      timestampMicros == other.timestampMicros &&
      valueA == other.valueA &&
      valueB == other.valueB;

  @override
  int get hashCode => Object.hash(kind, timestampMicros, valueA, valueB);
}

abstract final class DashboardPerformanceTrace {
  static const capacity = 512;
  static final List<DashboardPerformanceTraceEvent?> _ring =
      List<DashboardPerformanceTraceEvent?>.filled(capacity, null);
  static int _start = 0;
  static int _length = 0;
  static bool _frameTimingsAttached = false;
  static bool? _enabledOverride;

  static bool get isEnabled => _enabledOverride ?? kProfileMode;

  static List<DashboardPerformanceTraceEvent> get events =>
      List<DashboardPerformanceTraceEvent>.unmodifiable([
        for (var offset = 0; offset < _length; offset += 1)
          _ring[(_start + offset) % capacity]!,
      ]);

  /// Starts frame-timing collection only in profile mode. Normal debug and
  /// release sessions perform no callback registration or trace allocation.
  static void start() {
    if (!isEnabled || _frameTimingsAttached) return;
    WidgetsBinding.instance.addTimingsCallback(_handleFrameTimings);
    _frameTimingsAttached = true;
  }

  static void stop() {
    if (!_frameTimingsAttached) return;
    WidgetsBinding.instance.removeTimingsCallback(_handleFrameTimings);
    _frameTimingsAttached = false;
  }

  static void record(
    DashboardPerformanceTraceKind kind, {
    int valueA = 0,
    int valueB = 0,
    int? timestampMicros,
  }) {
    if (!isEnabled) return;
    final event = DashboardPerformanceTraceEvent(
      kind: kind,
      timestampMicros: timestampMicros ?? DateTime.now().microsecondsSinceEpoch,
      valueA: valueA,
      valueB: valueB,
    );
    final insertionIndex = (_start + _length) % capacity;
    _ring[insertionIndex] = event;
    if (_length < capacity) {
      _length += 1;
    } else {
      _start = (_start + 1) % capacity;
    }
  }

  static void recordFrameTiming({
    required int timestampMicros,
    required int uiMicros,
    required int rasterMicros,
  }) => record(
    DashboardPerformanceTraceKind.frameTiming,
    timestampMicros: timestampMicros,
    valueA: uiMicros,
    valueB: rasterMicros,
  );

  static void _handleFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      recordFrameTiming(
        timestampMicros: timing.timestampInMicroseconds(FramePhase.buildStart),
        uiMicros: timing.buildDuration.inMicroseconds,
        rasterMicros: timing.rasterDuration.inMicroseconds,
      );
    }
  }

  @visibleForTesting
  static void resetForTest({bool? enabled}) {
    stop();
    _ring.fillRange(0, capacity);
    _start = 0;
    _length = 0;
    _enabledOverride = enabled;
  }
}
