import 'package:flutter/foundation.dart';

import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/time_child_summary.dart';
import 'dashboard_ledger_repository.dart';

/// Immutable first-page data prepared for one semantic child scope.
///
/// This is a read model, not a widget cache. It contains no Flutter element,
/// controller, render object or lifecycle owner and can therefore be built by
/// the native/read layer before the rail starts moving.
@immutable
class DashboardChildPreview {
  DashboardChildPreview({
    required this.childPeriodValue,
    required this.scope,
    required this.result,
  }) : assert(result.scopeKey == null || result.scopeKey == scope.key.value),
       assert(
         result.direction == null || result.direction == scope.direction.name,
       );

  final String childPeriodValue;
  final CurrentLedgerQueryScope scope;
  final DashboardLedgerResult result;

  LedgerQueryKey get queryKey => scope.key;
  int? get contentDigest => Object.hash(
    result.coreRevision,
    result.totalMinor,
    result.entryCount,
    Object.hashAll(result.entries.map((entry) => entry.id)),
  );
}

/// Batch child preview payload for one exact parent query identity.
@immutable
class DashboardChildPreviewBundle {
  DashboardChildPreviewBundle({
    required this.parentScope,
    required this.childPeriod,
    required this.coreRevision,
    required Map<LedgerQueryKey, DashboardChildPreview> childrenByQueryKey,
    this.previewPageSize = 50,
  }) : childrenByQueryKey = Map.unmodifiable(childrenByQueryKey),
       assert(
         childrenByQueryKey.values.every(
           (child) => child.scope.direction == parentScope.direction,
         ),
       ),
       assert(previewPageSize > 0);

  final CurrentLedgerQueryScope parentScope;
  final TimeChildPeriod childPeriod;
  final int coreRevision;
  final int previewPageSize;
  final Map<LedgerQueryKey, DashboardChildPreview> childrenByQueryKey;

  LedgerQueryKey get parentQueryKey => parentScope.key;
  LedgerDirection get direction => parentScope.direction;

  String get cacheKey => [
    parentQueryKey.value,
    'child:${childPeriod.name}',
    'revision:$coreRevision',
    'page:$previewPageSize',
  ].join('|');

  DashboardChildPreview? operator [](LedgerQueryKey key) =>
      childrenByQueryKey[key];
}
