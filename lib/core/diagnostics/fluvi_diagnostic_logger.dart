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

/// Fixed-capacity FIFO without list shifts. Snapshot materialization is only
/// requested by the onscreen console, never by the scroll/render hot path.
final class _FluviDiagnosticRingBuffer<T> {
  _FluviDiagnosticRingBuffer(this.capacity)
    : _values = List<T?>.filled(capacity, null) {
    if (capacity < 1) throw ArgumentError.value(capacity, 'capacity');
  }

  final int capacity;
  final List<T?> _values;
  int _head = 0;
  int _length = 0;

  int get length => _length;
  T? get last =>
      _length == 0 ? null : _values[(_head + _length - 1) % capacity];

  void add(T value) {
    if (_length < capacity) {
      _values[(_head + _length) % capacity] = value;
      _length += 1;
      return;
    }
    _values[_head] = value;
    _head = (_head + 1) % capacity;
  }

  void replaceLast(T value) {
    if (_length == 0) {
      add(value);
      return;
    }
    _values[(_head + _length - 1) % capacity] = value;
  }

  void clear() {
    _head = 0;
    _length = 0;
  }

  List<T> snapshot() => List<T>.generate(
    _length,
    (index) => _values[(_head + index) % capacity] as T,
    growable: false,
  );
}

/// The single debug-only sink used by the on-screen diagnostic projection.
abstract final class FluviDiagnosticLogger {
  static const maxEntries = 1000;
  static const captureMaxEntries = 2048;
  static const _emitStartupSceneTrace = bool.fromEnvironment(
    'FLUVI_ONSCREEN_DIAGNOSTICS',
  );
  static final _FluviDiagnosticRingBuffer<FluviDiagnosticEvent> _entries =
      _FluviDiagnosticRingBuffer<FluviDiagnosticEvent>(maxEntries);
  static final _FluviDiagnosticRingBuffer<FluviDiagnosticEvent> _capture =
      _FluviDiagnosticRingBuffer<FluviDiagnosticEvent>(captureMaxEntries);
  static final _FluviDiagnosticNotifier _version = _FluviDiagnosticNotifier(0);
  static var _notifyScheduled = false;
  static var _captureId = 0;
  static var _captureActive = false;
  static var _captureFrozen = false;
  static DateTime? _captureStartedAt;
  static DateTime? _captureStoppedAt;

  static void log(FluviDiagnosticEvent event) {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    final stamped = event.timestamp == null
        ? event.withTimestamp(DateTime.now())
        : event;
    _append(_entries, stamped);
    _emitBoundedStartupSceneTrace(stamped);
    if (_captureActive && !_captureFrozen) {
      _append(_capture, stamped.withCaptureId(_captureId));
    }
    _scheduleNotify();
  }

  /// The persistent on-screen ring remains the diagnostic authority. The
  /// physical diagnostic APK and CI profile build additionally mirror only
  /// startup/scene ownership boundaries and low-frequency Header renderer
  /// proof events to logcat. This makes the active GPU path observable without
  /// adding paint-frame traffic.
  static void _emitBoundedStartupSceneTrace(FluviDiagnosticEvent event) {
    if (!_emitStartupSceneTrace || !isPlatformTraceStage(event.stage)) {
      return;
    }
    debugPrint(
      '[FluviDiagnostic] stage=${event.stage} '
      'scope=${event.scope ?? '-'} '
      'entryCount=${event.entryCount ?? '-'} '
      'error=${event.error ?? '-'} '
      'message=${event.message ?? '-'}',
    );
  }

  /// Compile-time-testable allow-list for the bounded physical diagnostic log.
  /// It intentionally excludes phase/frame/painter events.
  static bool isPlatformTraceStage(String stage) =>
      _isStartupSceneBoundary(stage) || _isHeaderRendererBoundary(stage);

  static bool _isStartupSceneBoundary(String stage) =>
      stage.startsWith('DASHBOARD_STARTUP_') ||
      stage.startsWith('READINESS_') ||
      stage.startsWith('SCENE_WINDOW_PREPARE_') ||
      stage.startsWith('SCENE_WINDOW_SLICE_') ||
      stage.startsWith('SCENE_WINDOW_ATOMIC_') ||
      stage == 'SUMMARY_PARENT_HOTSET_PREPARE_STARTED' ||
      stage == 'SUMMARY_PARENT_HOTSET_PREPARE_READY';

  static bool _isHeaderRendererBoundary(String stage) =>
      stage == 'HEADER_RENDER_BACKEND_BOUND' ||
      stage == 'HEADER_SHADER_READY' ||
      stage == 'HEADER_SHADER_FALLBACK' ||
      stage == 'HEADER_RENDER_FIDELITY_CONFIG' ||
      stage == 'HEADER_RENDER_SESSION_SUMMARY' ||
      stage.startsWith('HEADER_DEEP_DRIFT_') ||
      stage.startsWith('HEADER_TAP_WAVE_') ||
      stage.startsWith('BUDGET_HEADER_');

  static void ingestNative(Object? raw) {
    if (!kFluviOnscreenDiagnosticsEnabled || raw is! Map) return;
    final map = raw.map<Object?, Object?>((key, value) => MapEntry(key, value));
    log(FluviDiagnosticEvent.fromMap(map));
  }

  static void clear() {
    _entries.clear();
    _clearCapture(notify: false);
    _scheduleNotify();
  }

  static List<FluviDiagnosticEvent> get entries =>
      List<FluviDiagnosticEvent>.unmodifiable(_entries.snapshot());

  static int get captureId => _captureId;
  static bool get captureActive => _captureActive;
  static bool get captureFrozen => _captureFrozen;
  static List<FluviDiagnosticEvent> get captureEntries =>
      List<FluviDiagnosticEvent>.unmodifiable(_capture.snapshot());

  static int startCapture() {
    if (!kFluviOnscreenDiagnosticsEnabled) return 0;
    _captureId += 1;
    _capture.clear();
    _captureActive = true;
    _captureFrozen = false;
    _captureStartedAt = DateTime.now();
    _captureStoppedAt = null;
    log(
      FluviDiagnosticEvent(
        stage: 'CAPTURE_STARTED',
        message: 'captureId=$_captureId',
        timestamp: _captureStartedAt,
      ),
    );
    return _captureId;
  }

  static void stopCapture() {
    if (!_captureActive || _captureFrozen) return;
    _captureStoppedAt = DateTime.now();
    log(
      FluviDiagnosticEvent(
        stage: 'CAPTURE_STOPPED',
        message: 'captureId=$_captureId',
        timestamp: _captureStoppedAt,
      ),
    );
    _captureActive = false;
    _captureFrozen = true;
    _scheduleNotify();
  }

  static void clearCapture() => _clearCapture(notify: true);

  static void recordCaptureStateSnapshot(
    String boundary,
    Map<String, Object?> state,
  ) {
    if (!_captureActive || _captureFrozen) return;
    final fields = state.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    log(
      FluviDiagnosticEvent(
        stage: 'CAPTURE_STATE_SNAPSHOT',
        message: 'boundary=$boundary $fields',
      ),
    );
  }

  static Map<String, Object?> captureReport() {
    final events = captureEntries;
    final stageCounts = <String, int>{};
    var verticalCacheMisses = 0;
    var requests = 0;
    var commits = 0;
    var rejects = 0;
    var evictions = 0;
    var frontierAdvances = 0;
    for (final event in events) {
      stageCounts.update(
        event.stage,
        (count) => count + event.repeatCount,
        ifAbsent: () => event.repeatCount,
      );
      switch (event.stage) {
        case 'VERTICAL_CACHE_MISS':
          verticalCacheMisses += event.repeatCount;
        case 'VERTICAL_PAGE_REQUESTED':
          requests += event.repeatCount;
        case 'VERTICAL_PAGE_COMMITTED':
          commits += event.repeatCount;
        case 'VERTICAL_PAGE_COMMIT_REJECTED':
          rejects += event.repeatCount;
        case 'VERTICAL_PAGE_EVICTED':
          evictions += event.entryCount ?? event.repeatCount;
        case 'VERTICAL_FRONTIER_ADVANCED':
          frontierAdvances += event.repeatCount;
      }
    }
    return <String, Object?>{
      'captureId': _captureId,
      'active': _captureActive,
      'frozen': _captureFrozen,
      'startedAt': _captureStartedAt?.toIso8601String(),
      'stoppedAt': _captureStoppedAt?.toIso8601String(),
      'eventCount': _capture.length,
      'stageCounts': stageCounts,
      'counters': <String, int>{
        'requests': requests,
        'commits': commits,
        'rejects': rejects,
        'verticalCacheMisses': verticalCacheMisses,
        'evictions': evictions,
        'frontierAdvances': frontierAdvances,
      },
      'events': events.map((event) => event.toLine()).toList(),
    };
  }

  static String get allText =>
      entries.map((event) => event.toLine()).join('\n');

  static ValueNotifier<int> get notifier => _version;

  static void _append(
    _FluviDiagnosticRingBuffer<FluviDiagnosticEvent> buffer,
    FluviDiagnosticEvent event,
  ) {
    final previous = buffer.last;
    if (previous != null && _sameRepeatedFailure(previous, event)) {
      buffer.replaceLast(previous.withRepeatCount(previous.repeatCount + 1));
      return;
    }
    buffer.add(event);
  }

  static bool _sameRepeatedFailure(
    FluviDiagnosticEvent previous,
    FluviDiagnosticEvent next,
  ) =>
      previous.stage == next.stage &&
      previous.queryKey == next.queryKey &&
      previous.coreRevision == next.coreRevision &&
      previous.error == next.error &&
      previous.message == next.message &&
      (next.stage == 'VERTICAL_CACHE_MISS' || next.stage == 'TEXT_LAYOUT_MISS');

  static void _clearCapture({required bool notify}) {
    _capture.clear();
    _captureActive = false;
    _captureFrozen = false;
    _captureStartedAt = null;
    _captureStoppedAt = null;
    if (notify) _scheduleNotify();
  }

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
