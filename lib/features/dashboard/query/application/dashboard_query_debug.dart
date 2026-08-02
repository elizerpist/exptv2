import 'package:flutter/foundation.dart';

import '../data/dashboard_ledger_repository.dart';
import '../domain/current_ledger_query_scope.dart';

/// Debug-only boundary telemetry for the Room -> Flutter dashboard path.
///
/// This is deliberately side-effect free in release builds. It exists to
/// distinguish an empty query result from a missing bridge/presentation
/// emission without making the UI depend on logging.
abstract final class DashboardQueryDebug {
  static void mark(
    String event, {
    CurrentLedgerQueryScope? scope,
    DashboardLedgerResult? result,
    String? queryKey,
    int? coreRevision,
    int? totalMinor,
    int? entryCount,
    Object? detail,
  }) {
    assert(() {
      final effectiveQueryKey = queryKey ?? scope?.key.value;
      final effectiveRevision = coreRevision ?? result?.coreRevision;
      final effectiveTotal = totalMinor ?? result?.totalMinor;
      final effectiveCount = entryCount ?? result?.entryCount;
      final scopeText = scope == null ? null : _scopeText(scope);
      debugPrint(
        '[DashboardQuery] '
        'event=$event '
        'time=${DateTime.now().microsecondsSinceEpoch} '
        'queryKey=${effectiveQueryKey ?? '-'} '
        'revision=${effectiveRevision ?? '-'} '
        'direction=${scope?.direction.name ?? '-'} '
        'scope=${scopeText ?? '-'} '
        'totalMinor=${effectiveTotal ?? '-'} '
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
