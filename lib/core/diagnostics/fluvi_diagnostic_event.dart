import 'package:flutter/foundation.dart';

/// Immutable, debug-only metadata for tracing a value across app boundaries.
///
/// This model intentionally carries no ledger content beyond aggregate query
/// metadata. Notes, partner aliases, and other potentially sensitive values do
/// not belong in the on-screen diagnostic stream.
@immutable
class FluviDiagnosticEvent {
  const FluviDiagnosticEvent({
    required this.stage,
    this.message,
    this.timestamp,
    this.flowId,
    this.captureId,
    this.repeatCount = 1,
    this.queryKey,
    this.direction,
    this.scope,
    this.startInclusive,
    this.endExclusive,
    this.coreRevision,
    this.totalMinor,
    this.formattedTotal,
    this.entryCount,
    this.durationMs,
    this.isStale,
    this.error,
  });

  final String stage;
  final String? message;
  final DateTime? timestamp;
  final String? flowId;
  final int? captureId;
  final int repeatCount;
  final String? queryKey;
  final String? direction;
  final String? scope;
  final String? startInclusive;
  final String? endExclusive;
  final int? coreRevision;
  final int? totalMinor;
  final String? formattedTotal;
  final int? entryCount;
  final int? durationMs;
  final bool? isStale;
  final String? error;

  FluviDiagnosticEvent withTimestamp(DateTime value) {
    return FluviDiagnosticEvent(
      stage: stage,
      message: message,
      timestamp: value,
      flowId: flowId,
      captureId: captureId,
      repeatCount: repeatCount,
      queryKey: queryKey,
      direction: direction,
      scope: scope,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      coreRevision: coreRevision,
      totalMinor: totalMinor,
      formattedTotal: formattedTotal,
      entryCount: entryCount,
      durationMs: durationMs,
      isStale: isStale,
      error: error,
    );
  }

  FluviDiagnosticEvent withCaptureId(int value) => FluviDiagnosticEvent(
    stage: stage,
    message: message,
    timestamp: timestamp,
    flowId: flowId,
    captureId: value,
    repeatCount: repeatCount,
    queryKey: queryKey,
    direction: direction,
    scope: scope,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
    coreRevision: coreRevision,
    totalMinor: totalMinor,
    formattedTotal: formattedTotal,
    entryCount: entryCount,
    durationMs: durationMs,
    isStale: isStale,
    error: error,
  );

  FluviDiagnosticEvent withRepeatCount(int value) => FluviDiagnosticEvent(
    stage: stage,
    message: message,
    timestamp: timestamp,
    flowId: flowId,
    captureId: captureId,
    repeatCount: value,
    queryKey: queryKey,
    direction: direction,
    scope: scope,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
    coreRevision: coreRevision,
    totalMinor: totalMinor,
    formattedTotal: formattedTotal,
    entryCount: entryCount,
    durationMs: durationMs,
    isStale: isStale,
    error: error,
  );

  String toLine() {
    final value = timestamp ?? DateTime.now();
    final stamp =
        '[${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}.${(value.millisecond ~/ 10).toString().padLeft(2, '0')}]';
    final fields = <String>[
      if (flowId != null) 'flowId=$flowId',
      if (captureId != null) 'captureId=$captureId',
      if (repeatCount > 1) 'repeatCount=$repeatCount',
      if (queryKey != null) 'queryKey=$queryKey',
      if (direction != null) 'direction=$direction',
      if (scope != null) 'scope=$scope',
      if (startInclusive != null) 'start=$startInclusive',
      if (endExclusive != null) 'end=$endExclusive',
      if (coreRevision != null) 'revision=$coreRevision',
      if (totalMinor != null) 'totalMinor=$totalMinor',
      if (formattedTotal != null) 'formatted=$formattedTotal',
      if (entryCount != null) 'entryCount=$entryCount',
      if (durationMs != null) 'durationMs=$durationMs',
      if (isStale != null) 'stale=$isStale',
      if (error != null) 'error=$error',
      ?message,
    ];
    return '$stamp [FLOW][$stage] ${fields.join(' ')}'.trimRight();
  }

  factory FluviDiagnosticEvent.fromMap(Map<Object?, Object?> raw) {
    int? intValue(Object? value) => (value as num?)?.toInt();

    return FluviDiagnosticEvent(
      stage: raw['stage'] as String? ?? 'NATIVE',
      message: raw['message'] as String?,
      timestamp: _timestamp(raw['timestampMicros']),
      flowId: raw['flowId'] as String?,
      captureId: intValue(raw['captureId']),
      repeatCount: intValue(raw['repeatCount']) ?? 1,
      queryKey: raw['queryKey'] as String?,
      direction: raw['direction'] as String?,
      scope: raw['scope'] as String?,
      startInclusive: raw['startInclusive'] as String?,
      endExclusive: raw['endExclusive'] as String?,
      coreRevision: intValue(raw['coreRevision']),
      totalMinor: intValue(raw['totalMinor']),
      formattedTotal: raw['formattedTotal'] as String?,
      entryCount: intValue(raw['entryCount']),
      durationMs: intValue(raw['durationMs']),
      isStale: raw['stale'] as bool?,
      error: raw['error'] as String?,
    );
  }

  static DateTime? _timestamp(Object? raw) {
    final micros = (raw as num?)?.toInt();
    if (micros == null) return null;
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }
}
