import 'package:flutter/foundation.dart';

import 'current_ledger_query_scope.dart';
import 'ledger_direction.dart';

/// The provenance of a displayed SummaryPill amount/count pair.
enum SummaryMetricsSource {
  parentSummary,
  childPreviewIndex,
  childSettledIndex,
  cache,
  freshQuery,
  stalePreviousValue,
}

/// One immutable, scope-identical amount and transaction-count snapshot.
///
/// A missing pair is represented by two nulls while loading or stale. A real
/// empty scope is always the explicit pair `0` / `0`; the two must never be
/// mixed with values from another query scope.
@immutable
class ScopeSummaryMetrics {
  ScopeSummaryMetrics({
    required this.scope,
    required this.canonicalQueryKey,
    required this.coreRevision,
    required this.totalMinor,
    required this.entryCount,
    required this.source,
    required this.isLoading,
    required this.isStale,
    required this.hasError,
  }) : assert(canonicalQueryKey == scope.key.value),
       assert((totalMinor == null) == (entryCount == null));

  final CurrentLedgerQueryScope scope;
  final String canonicalQueryKey;
  final int? coreRevision;
  final int? totalMinor;
  final int? entryCount;
  final SummaryMetricsSource source;
  final bool isLoading;
  final bool isStale;
  final bool hasError;

  bool get hasValue => totalMinor != null;
  LedgerDirection get direction => scope.direction;
  Set<String> get categoryIds => scope.categoryIds;
  Set<String> get partnerIds => scope.partnerIds;
  Map<String, Object?> get refinements => scope.refinements;
}
