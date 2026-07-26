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
    'balance-action-type-change',
    'balance-rail-toggle',
    'balance-rail-select',
    'balance-frame-resolve',
    'balance-transaction-log-build',
  };

  static var _nextCorrelation = 0;

  /// Starts a debug-only trace and returns its correlation token.
  ///
  /// Release and profile builds return `null` without allocating a stopwatch
  /// or writing to the debug console.
  static BalanceDebugTraceToken? begin(String operation) {
    if (!kDebugMode) return null;
    return BalanceDebugTraceToken._(
      operation: _safeOperations.contains(operation) ? operation : 'unknown',
      correlation: ++_nextCorrelation,
    );
  }

  /// Completes [token] once, recording only safe diagnostic metadata.
  static void finish(BalanceDebugTraceToken? token, {Object? error}) {
    if (!kDebugMode || token == null || token._finished) return;
    token._finished = true;
    token._stopwatch.stop();
    DebugConsole.log(
      '[BalanceTrace] operation=${token.operation} '
      'correlation=${token.correlation} '
      'duration_ms=${token._stopwatch.elapsedMilliseconds} '
      'error_kind=${_errorKind(error)}',
    );
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
