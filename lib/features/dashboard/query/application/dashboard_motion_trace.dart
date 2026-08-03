import 'dart:developer' as developer;

/// Numeric, bounded motion diagnostics for the rail hot path.
///
/// Recording writes into preallocated primitive arrays. It never formats a
/// query key, calls debugPrint, notifies a listener, or copies the ring. A
/// human-readable export can be built by an explicit diagnostics panel later.
abstract final class DashboardMotionEventId {
  static const int previewCentered = 1;
  static const int semanticSettle = 2;
  static const int baselineEstablished = 3;
  static const int programmaticMotion = 4;
}

abstract final class DashboardMotionTrace {
  static const int capacity = 256;
  static final List<int> _eventIds = List<int>.filled(capacity, 0);
  static final List<int> _epochs = List<int>.filled(capacity, 0);
  static final List<int> _physicalIndexes = List<int>.filled(capacity, 0);
  static final List<int> _logicalIndexes = List<int>.filled(capacity, 0);
  static final List<int> _timestampsMicros = List<int>.filled(capacity, 0);
  static int _writeIndex = 0;
  static int _count = 0;
  static int _epoch = 0;
  static bool enabled = true;

  static int get count => _count;
  static int get epoch => _epoch;

  static void beginEpoch() {
    _epoch += 1;
  }

  static void record({
    required int eventId,
    required int physicalIndex,
    required int logicalIndex,
    int? epoch,
    int? timestampMicros,
  }) {
    if (!enabled) return;
    final index = _writeIndex;
    _eventIds[index] = eventId;
    _epochs[index] = epoch ?? _epoch;
    _physicalIndexes[index] = physicalIndex;
    _logicalIndexes[index] = logicalIndex;
    _timestampsMicros[index] = timestampMicros ?? developer.Timeline.now;
    _writeIndex = (index + 1) % capacity;
    if (_count < capacity) _count += 1;
  }

  /// Copies only on explicit inspection, never from a scroll callback.
  static List<DashboardMotionTraceEvent> export() {
    final result = <DashboardMotionTraceEvent>[];
    final start = _count == capacity ? _writeIndex : 0;
    for (var offset = 0; offset < _count; offset += 1) {
      final index = (start + offset) % capacity;
      result.add(
        DashboardMotionTraceEvent(
          eventId: _eventIds[index],
          epoch: _epochs[index],
          physicalIndex: _physicalIndexes[index],
          logicalIndex: _logicalIndexes[index],
          timestampMicros: _timestampsMicros[index],
        ),
      );
    }
    return result;
  }

  static void clear() {
    _writeIndex = 0;
    _count = 0;
    _epoch = 0;
  }
}

class DashboardMotionTraceEvent {
  const DashboardMotionTraceEvent({
    required this.eventId,
    required this.epoch,
    required this.physicalIndex,
    required this.logicalIndex,
    required this.timestampMicros,
  });

  final int eventId;
  final int epoch;
  final int physicalIndex;
  final int logicalIndex;
  final int timestampMicros;
}
