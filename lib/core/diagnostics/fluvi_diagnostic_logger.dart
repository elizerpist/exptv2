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
  T operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    return _values[(_head + index) % capacity] as T;
  }

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
  // Capture/export is another on-screen diagnostic projection. Keeping this
  // at the same boundary prevents a hidden second history from exposing a
  // different retention contract than the panel and its Copy action.
  static const captureMaxEntries = maxEntries;
  static const _emitStartupSceneTrace = bool.fromEnvironment(
    'FLUVI_ONSCREEN_DIAGNOSTICS',
  );
  static final _FluviDiagnosticRingBuffer<FluviDiagnosticEvent> _entries =
      _FluviDiagnosticRingBuffer<FluviDiagnosticEvent>(maxEntries);
  static final _FluviDiagnosticRingBuffer<FluviDiagnosticEvent> _capture =
      _FluviDiagnosticRingBuffer<FluviDiagnosticEvent>(captureMaxEntries);
  // Header backend binding happens while the surface is created, whereas a
  // human commonly starts the on-screen capture later. Retain only these
  // low-frequency physical-renderer facts so a new capture can prove the
  // actual already-bound APK path instead of silently missing startup.
  static final Map<String, FluviDiagnosticEvent> _headerRendererEvidence =
      <String, FluviDiagnosticEvent>{};
  static final _FluviDiagnosticNotifier _version = _FluviDiagnosticNotifier(0);
  static final Stopwatch _sessionStopwatch = Stopwatch()..start();
  static final String _sessionId =
      'fluvi-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  static var _nextSequence = 0;
  static var _sessionEventCount = 0;
  static var _uiPublicationCount = 0;
  static var _notifyScheduled = false;
  static var _captureId = 0;
  static var _captureActive = false;
  static var _captureFrozen = false;
  static DateTime? _captureStartedAt;
  static DateTime? _captureStoppedAt;

  static void log(FluviDiagnosticEvent event) {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    final stamped =
        (event.timestamp == null ? event.withTimestamp(DateTime.now()) : event)
            .withTraceStamp(
              sequence: ++_nextSequence,
              elapsedMicros: _sessionStopwatch.elapsedMicroseconds,
            );
    _sessionEventCount += 1;
    if (_isHeaderRendererBoundary(stamped.stage) &&
        !(stamped.scope?.contains('captureReplay=true') ?? false)) {
      _headerRendererEvidence[stamped.stage] = stamped;
    }
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
      stage == 'HEADER_TOUCH_RENDER_PATH_BOUND' ||
      stage.startsWith('HEADER_SPACE_FABRIC_') ||
      stage.startsWith('HEADER_STATIC_COLOR_RENDERER_') ||
      stage.startsWith('HEADER_DEEP_DRIFT_') ||
      stage.startsWith('HEADER_PORTAL_') ||
      stage.startsWith('HEADER_TAP_WAVE_') ||
      stage.startsWith('BUDGET_HEADER_');

  static void ingestNative(Object? raw) {
    if (!kFluviOnscreenDiagnosticsEnabled || raw is! Map) return;
    final map = raw.map<Object?, Object?>((key, value) => MapEntry(key, value));
    log(FluviDiagnosticEvent.fromMap(map));
  }

  static void clear() {
    _entries.clear();
    _headerRendererEvidence.clear();
    _sessionEventCount = 0;
    _clearCapture(notify: false);
    _scheduleNotify();
  }

  /// Clears the rolling projection without disturbing an explicitly frozen
  /// capture. Sequence identity remains process-monotonic while the displayed
  /// session counter starts a new user-visible tail.
  static void clearLive() {
    _entries.clear();
    _headerRendererEvidence.clear();
    _scheduleNotify();
  }

  static List<FluviDiagnosticEvent> get entries =>
      List<FluviDiagnosticEvent>.unmodifiable(_entries.snapshot());
  static int get retainedEntryCount => _entries.length;
  static int get sessionEventCount => _sessionEventCount;
  static int get uiPublicationCount => _uiPublicationCount;
  static String get sessionId => _sessionId;

  /// Indexed access lets the virtualized console build only visible rows.
  static FluviDiagnosticEvent entryAt(int index) => _entries[index];

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
    // Emit exact Header lifecycle evidence through the same logger/logcat
    // path, not by synthesising a parallel diagnostics string. This is
    // intentionally capture-start-only and bounded by renderer stages.
    for (final event in _headerRendererEvidence.values) {
      log(
        FluviDiagnosticEvent(
          stage: event.stage,
          scope:
              '${event.scope ?? '-'} captureReplay=true originalTimestamp=${event.timestamp?.toIso8601String() ?? '-'}',
        ),
      );
    }
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
      'sessionId': _sessionId,
      'sessionEventCount': _sessionEventCount,
      'firstRetainedSequence': events.isEmpty ? null : events.first.sequence,
      'lastRetainedSequence': events.isEmpty ? null : events.last.sequence,
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

  /// Materializes the rolling tail only for an explicit copy/export action.
  static String latestText() =>
      _exportText(label: 'LIVE_TAIL', events: _entries.snapshot());

  /// Materializes the independent bounded capture only on explicit copy.
  static String captureText() => _exportText(
    label: 'FROZEN_CAPTURE',
    events: _capture.snapshot(),
    captureId: _captureId,
  );

  static void markUserBug(
    String issue, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    final fields = <String, Object?>{'issue': issue, ...context}.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    log(FluviDiagnosticEvent(stage: 'USER_MARK', scope: fields));
  }

  static String _exportText({
    required String label,
    required List<FluviDiagnosticEvent> events,
    int? captureId,
  }) {
    final firstSequence = events.isEmpty ? null : events.first.sequence;
    final lastSequence = events.isEmpty ? null : events.last.sequence;
    final header = <String>[
      'FLUVI_DIAGNOSTICS $label',
      'sessionId=$_sessionId',
      'sessionEventCount=$_sessionEventCount',
      if (captureId != null) 'captureId=$captureId',
      'retainedCount=${events.length}',
      'firstRetainedSequence=${firstSequence ?? '-'}',
      'lastRetainedSequence=${lastSequence ?? '-'}',
    ].join(' ');
    if (events.isEmpty) return header;
    return '$header\n${events.map((event) => event.toLine()).join('\n')}';
  }

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
      _uiPublicationCount += 1;
      _version.value += 1;
    });
    binding.scheduleFrame();
  }
}
