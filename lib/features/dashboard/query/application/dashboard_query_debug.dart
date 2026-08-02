import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../data/dashboard_ledger_repository.dart';
import '../domain/current_ledger_query_scope.dart';

/// Debug-only boundary telemetry for the Room -> Flutter dashboard path.
///
/// This is deliberately side-effect free in release builds. It exists to
/// distinguish an empty query result from a missing bridge/presentation
/// emission without making the UI depend on logging.
abstract final class DashboardQueryDebug {
  static String? _lastSummaryPresentationKey;

  static String flowIdFor(CurrentLedgerQueryScope scope) =>
      'Q-${scope.key.value}';

  static void mark(
    String event, {
    CurrentLedgerQueryScope? scope,
    DashboardLedgerResult? result,
    String? flowId,
    String? queryKey,
    int? coreRevision,
    int? totalMinor,
    int? entryCount,
    String? formattedTotal,
    int? durationMs,
    bool? isStale,
    Object? detail,
  }) {
    assert(() {
      final effectiveQueryKey = queryKey ?? scope?.key.value;
      final effectiveFlowId =
          flowId ?? (scope == null ? null : flowIdFor(scope));
      final effectiveRevision = coreRevision ?? result?.coreRevision;
      final effectiveTotal = totalMinor ?? result?.totalMinor;
      final effectiveCount = entryCount ?? result?.entryCount;
      final scopeText = scope == null ? null : _scopeText(scope);
      final effectiveDirection = scope?.direction.name ?? result?.direction;
      final firstSpace = event.indexOf(' ');
      final stage = firstSpace == -1 ? event : event.substring(0, firstSpace);
      final message = firstSpace == -1 ? null : event.substring(firstSpace + 1);
      final zeroResult = effectiveTotal == 0;
      if (event == 'D9 amountPresentationEmitted') {
        final presentationKey = <Object?>[
          effectiveFlowId,
          effectiveQueryKey,
          effectiveRevision,
          effectiveTotal,
          effectiveCount,
          formattedTotal,
          detail,
        ].join('|');
        if (presentationKey == _lastSummaryPresentationKey) return true;
        _lastSummaryPresentationKey = presentationKey;
      }
      final diagnostic = FluviDiagnosticEvent(
        stage: stage,
        message: detail == null
            ? '${message ?? ''}${zeroResult ? ' QUERY_ZERO_RESULT' : ''}'
            : '${message == null ? '' : '$message '}'
                  'detail=$detail${zeroResult ? ' QUERY_ZERO_RESULT' : ''}',
        flowId: effectiveFlowId,
        queryKey: effectiveQueryKey,
        direction: effectiveDirection,
        scope: scopeText,
        coreRevision: effectiveRevision,
        totalMinor: effectiveTotal,
        formattedTotal: formattedTotal,
        entryCount: effectiveCount,
        durationMs: durationMs,
        isStale: isStale,
      );
      FluviDiagnosticLogger.log(diagnostic);
      debugPrint(
        '[DashboardQuery] '
        'event=$event '
        'time=${DateTime.now().microsecondsSinceEpoch} '
        'queryKey=${effectiveQueryKey ?? '-'} '
        'revision=${effectiveRevision ?? '-'} '
        'direction=${effectiveDirection ?? '-'} '
        'scope=${scopeText ?? '-'} '
        'totalMinor=${effectiveTotal ?? '-'} '
        'formatted=${formattedTotal ?? '-'} '
        'entryCount=${effectiveCount ?? '-'}'
        '${detail == null ? '' : ' detail=$detail'}',
      );
      return true;
    }());
  }

  static String _scopeText(CurrentLedgerQueryScope scope) {
    final boundaries = scope.timeScope.boundaries;
    if (boundaries == null) return scope.timeScope.canonicalKey;
    return '${scope.timeScope.canonicalKey} '
        '[${boundaries.startInclusive.isoString},'
        ' ${boundaries.endExclusive.isoString})';
  }
}
