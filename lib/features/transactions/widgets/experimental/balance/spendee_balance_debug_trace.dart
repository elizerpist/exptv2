import 'package:flutter/foundation.dart';

import '../../../../../core/debug/debug_console.dart';

/// Debug-only timing trace for the bounded Balance operations.
///
/// The operation vocabulary is intentionally closed so diagnostic output can
/// never accidentally include transaction data such as merchant names or
/// amounts.
class BalanceDebugTrace {
  BalanceDebugTrace._();

  static const _safeOperations = <String>{
    'balance-entry',
    'balance-type-switch',
    'balance-rail-toggle',
    'balance-rail-load',
    'balance-fast-info-dimension',
    'balance-log-scroll',
    'balance-frame-resolve',
    'balance-transaction-log-build',
  };
  static const _safeFieldNames = <String>{
    'build_bound',
    'cache',
    'cache_extent',
    'card',
    'expanded',
    'extent_after',
    'frame_cache',
    'from_dimension',
    'from_rows',
    'from_scope',
    'from_type',
    'groups',
    'has_more',
    'load_more',
    'loaded_rows',
    'log_cache',
    'metric_cache',
    'page_size',
    'prebuilt_slots',
    'reason',
    'requested_rows',
    'requested_scope',
    'scope_options',
    'selected_scope',
    'to_dimension',
    'to_type',
    'type',
    'visible_rows',
    'window',
  };
  static final _safeToken = RegExp(r'^[a-zA-Z0-9_.:-]{1,64}$');

  static var _nextCorrelation = 0;

  /// Call sites use this guard before constructing diagnostic maps.  Keeping
  /// the guard outside [begin] means profile/release builds do not allocate
  /// field maps, callbacks or stopwatches for the instrumentation itself.
  static bool get enabled => kDebugMode;

  /// Starts a debug-only trace and returns its correlation token.
  ///
  /// Release and profile builds return `null` without allocating a stopwatch
  /// or writing to the debug console.
  static BalanceDebugTraceToken? begin(
    String operation, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!kDebugMode) return null;
    final token = BalanceDebugTraceToken._(
      operation: _safeOperations.contains(operation) ? operation : 'unknown',
      correlation: ++_nextCorrelation,
    );
    _write(token, phase: 'request', fields: fields);
    return token;
  }

  /// Adds a bounded lifecycle checkpoint to [token].  Fields are deliberately
  /// restricted to counters, booleans and enum-like tokens, so an accidental
  /// merchant, query or amount cannot enter debug output.
  static void mark(
    BalanceDebugTraceToken? token,
    String phase, {
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!kDebugMode || token == null || token._finished) return;
    _write(token, phase: phase, fields: fields);
  }

  /// Completes [token] once, recording only safe diagnostic metadata.
  static void finish(
    BalanceDebugTraceToken? token, {
    Object? error,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!kDebugMode || token == null || token._finished) return;
    token._finished = true;
    token._stopwatch.stop();
    _write(token, phase: 'complete', error: error, fields: fields);
  }

  static void _write(
    BalanceDebugTraceToken token, {
    required String phase,
    Object? error,
    required Map<String, Object?> fields,
  }) {
    final serializedFields = _serializeFields(fields);
    DebugConsole.log(
      '[BalanceTrace] operation=${token.operation} '
      'correlation=${token.correlation} '
      'phase=${_safeToken.hasMatch(phase) ? phase : 'unknown'} '
      'duration_ms=${token._stopwatch.elapsedMilliseconds} '
      'error_kind=${_errorKind(error)}'
      '${serializedFields.isEmpty ? '' : ' $serializedFields'}',
    );
  }

  static String _serializeFields(Map<String, Object?> fields) {
    final entries = <String>[];
    for (final entry in fields.entries) {
      if (!_safeFieldNames.contains(entry.key)) continue;
      final value = entry.value;
      final encoded = switch (value) {
        bool value => value ? 'true' : 'false',
        int value => value.toString(),
        double value when value.isFinite => value.toStringAsFixed(1),
        String value when _safeToken.hasMatch(value) => value,
        _ => null,
      };
      if (encoded != null) entries.add('${entry.key}=$encoded');
    }
    entries.sort();
    return entries.join(' ');
  }

  static String _errorKind(Object? error) {
    if (error == null) return 'none';
    if (error is StateError) return 'StateError';
    if (error is ArgumentError) return 'ArgumentError';
    if (error is FormatException) return 'FormatException';
    return 'other';
  }
}

/// Opaque correlation token returned by [BalanceDebugTrace.begin].
class BalanceDebugTraceToken {
  BalanceDebugTraceToken._({required this.operation, required this.correlation})
    : _stopwatch = Stopwatch()..start();

  final String operation;
  final int correlation;
  final Stopwatch _stopwatch;
  var _finished = false;
}
