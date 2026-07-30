import 'package:flutter/foundation.dart';

import '../../../models/recurring_ghost_record.dart';
import '../../../models/transaction_log_entry.dart';
import '../../../models/transaction_log_projection.dart';
import '../../../models/transaction_record.dart';
import '../../../state/transaction_store.dart';
import 'budget_v2_query_controller.dart';
import 'budget_v2_snapshot.dart';

@immutable
class BudgetV2LogQuery {
  const BudgetV2LogQuery({
    required this.avatarKey,
    required this.scope,
    this.selectedVendorKey,
    this.rowLimit = TransactionStore.visibleDisplayLogPageSize,
  });

  final String avatarKey;
  final BudgetV2ExternalQueryScope scope;
  final String? selectedVendorKey;
  final int rowLimit;
}

@immutable
class BudgetV2LogProjection {
  const BudgetV2LogProjection({
    required this.entries,
    required this.visibleRowCount,
    required this.totalRowCount,
  });

  final List<TransactionLogEntry> entries;
  final int visibleRowCount;
  final int totalRowCount;

  bool get hasMore => visibleRowCount < totalRowCount;
}

@immutable
class BudgetV2LogProjectionCacheDiagnostics {
  const BudgetV2LogProjectionCacheDiagnostics({
    required this.resolveCount,
    required this.cacheMissCount,
    required this.projectionCount,
    this.fullScanCount = 0,
    this.materializationCount = 0,
    this.cachedQueryCount = 0,
    this.retainedLogicalRowCount = 0,
    this.retainedMaterializedWindowCount = 0,
  });

  final int resolveCount;
  final int cacheMissCount;
  final int projectionCount;
  final int fullScanCount;
  final int materializationCount;
  final int cachedQueryCount;
  final int retainedLogicalRowCount;
  final int retainedMaterializedWindowCount;

  @override
  bool operator ==(Object other) =>
      other is BudgetV2LogProjectionCacheDiagnostics &&
      resolveCount == other.resolveCount &&
      cacheMissCount == other.cacheMissCount &&
      projectionCount == other.projectionCount &&
      fullScanCount == other.fullScanCount &&
      materializationCount == other.materializationCount &&
      cachedQueryCount == other.cachedQueryCount &&
      retainedLogicalRowCount == other.retainedLogicalRowCount &&
      retainedMaterializedWindowCount == other.retainedMaterializedWindowCount;

  @override
  int get hashCode => Object.hash(
    resolveCount,
    cacheMissCount,
    projectionCount,
    fullScanCount,
    materializationCount,
    cachedQueryCount,
    retainedLogicalRowCount,
    retainedMaterializedWindowCount,
  );
}

class BudgetV2LogProjectionCache {
  BudgetV2LogProjectionCache({this.maximumCachedQueries = 12})
    : assert(maximumCachedQueries > 0);

  final int maximumCachedQueries;
  final Map<_BudgetV2LogProjectionKey, _BudgetV2LogicalLogProjection>
  _logicalProjections =
      <_BudgetV2LogProjectionKey, _BudgetV2LogicalLogProjection>{};
  var _resolveCount = 0;
  var _cacheMissCount = 0;
  var _projectionCount = 0;
  var _fullScanCount = 0;
  var _materializationCount = 0;

  BudgetV2LogProjectionCacheDiagnostics get diagnostics =>
      BudgetV2LogProjectionCacheDiagnostics(
        resolveCount: _resolveCount,
        cacheMissCount: _cacheMissCount,
        projectionCount: _projectionCount,
        fullScanCount: _fullScanCount,
        materializationCount: _materializationCount,
        cachedQueryCount: _logicalProjections.length,
        retainedLogicalRowCount: _logicalProjections.values.fold<int>(
          0,
          (total, projection) => total + projection.orderedRows.length,
        ),
        retainedMaterializedWindowCount: 0,
      );

  BudgetV2LogProjection resolve({
    required BudgetV2PreparedSnapshot snapshot,
    required BudgetV2LogQuery query,
  }) {
    _resolveCount += 1;
    final normalized = _NormalizedBudgetV2LogQuery.from(query);
    final key = _BudgetV2LogProjectionKey(
      sourceRevision: snapshot.sourceRevision,
      query: normalized,
    );
    var logical = _logicalProjections.remove(key);
    if (logical == null) {
      _cacheMissCount += 1;
      _fullScanCount += 1;
      final avatar = snapshot.avatarData(normalized.avatarKey);
      final vendorKey = normalized.selectedVendorKey;
      final records = vendorKey == null
          ? avatar.records
          : avatar.recordsForVendor(vendorKey);
      final ghosts = vendorKey == null
          ? avatar.ghosts
          : avatar.ghostsForVendor(vendorKey);
      final matches = _matchingEntries(
        records: records,
        ghosts: ghosts,
        query: normalized,
      ).toList(growable: false);
      final ordered = projectTransactionLogEntries(
        matches,
        rowLimit: matches.length,
      );
      _projectionCount += 1;
      logical = _BudgetV2LogicalLogProjection(
        orderedRows: ordered.rows,
        totalRowCount: ordered.totalRowCount,
        totalDisplayEntryCount: ordered.totalDisplayEntryCount,
      );
    }
    _logicalProjections[key] = logical;
    if (_logicalProjections.length > maximumCachedQueries) {
      _logicalProjections.remove(_logicalProjections.keys.first);
    }
    _materializationCount += 1;
    final window = materializeOrderedTransactionLogEntries(
      logical.orderedRows,
      rowLimit: normalized.rowLimit,
      totalRowCount: logical.totalRowCount,
      totalDisplayEntryCount: logical.totalDisplayEntryCount,
    );
    return BudgetV2LogProjection(
      entries: window.entries,
      visibleRowCount: window.visibleRowCount,
      totalRowCount: window.totalRowCount,
    );
  }
}

@immutable
class _BudgetV2LogicalLogProjection {
  const _BudgetV2LogicalLogProjection({
    required this.orderedRows,
    required this.totalRowCount,
    required this.totalDisplayEntryCount,
  });

  final List<TransactionLogEntry> orderedRows;
  final int totalRowCount;
  final int totalDisplayEntryCount;
}

Iterable<TransactionLogEntry> _matchingEntries({
  required Iterable<TransactionRecord> records,
  required Iterable<RecurringGhostRecord> ghosts,
  required _NormalizedBudgetV2LogQuery query,
}) sync* {
  for (final record in records) {
    if (!_matchesScope(
      record.transactionCategoryID,
      record.displayMerchant,
      query,
    )) {
      continue;
    }
    yield TransactionLogEntry.record(record);
  }
  for (final ghost in ghosts) {
    if (!_matchesScope(ghost.categoryId, ghost.name, query)) continue;
    yield TransactionLogEntry.ghost(ghost);
  }
}

bool _matchesScope(
  int? categoryId,
  String merchant,
  _NormalizedBudgetV2LogQuery query,
) {
  if (query.categoryIds.isNotEmpty && !query.categoryIds.contains(categoryId)) {
    return false;
  }
  if (query.merchantKeys.isNotEmpty && !query.merchantKeys.contains(merchant)) {
    return false;
  }
  return query.normalizedSearch.isEmpty ||
      merchant.toLowerCase().contains(query.normalizedSearch);
}

class _NormalizedBudgetV2LogQuery {
  const _NormalizedBudgetV2LogQuery({
    required this.avatarKey,
    required this.normalizedSearch,
    required this.categoryIds,
    required this.merchantKeys,
    required this.selectedVendorKey,
    required this.rowLimit,
  });

  factory _NormalizedBudgetV2LogQuery.from(BudgetV2LogQuery query) {
    final categoryIds = query.scope.categoryIds.toList()..sort();
    final merchantKeys = query.scope.merchantKeys.toList()..sort();
    return _NormalizedBudgetV2LogQuery(
      avatarKey: query.avatarKey,
      normalizedSearch: query.scope.searchQuery.trim().toLowerCase(),
      categoryIds: List<int>.unmodifiable(categoryIds),
      merchantKeys: List<String>.unmodifiable(merchantKeys),
      selectedVendorKey: query.selectedVendorKey,
      rowLimit: query.rowLimit < 0 ? 0 : query.rowLimit,
    );
  }

  final String avatarKey;
  final String normalizedSearch;
  final List<int> categoryIds;
  final List<String> merchantKeys;
  final String? selectedVendorKey;
  final int rowLimit;

  @override
  bool operator ==(Object other) {
    return other is _NormalizedBudgetV2LogQuery &&
        other.avatarKey == avatarKey &&
        other.normalizedSearch == normalizedSearch &&
        listEquals(other.categoryIds, categoryIds) &&
        listEquals(other.merchantKeys, merchantKeys) &&
        other.selectedVendorKey == selectedVendorKey &&
        other.rowLimit == rowLimit;
  }

  @override
  int get hashCode => Object.hash(
    avatarKey,
    normalizedSearch,
    Object.hashAll(categoryIds),
    Object.hashAll(merchantKeys),
    selectedVendorKey,
    rowLimit,
  );
}

class _BudgetV2LogProjectionKey {
  const _BudgetV2LogProjectionKey({
    required this.sourceRevision,
    required this.query,
  });

  final BudgetV2SnapshotRevision sourceRevision;
  final _NormalizedBudgetV2LogQuery query;

  @override
  bool operator ==(Object other) {
    return other is _BudgetV2LogProjectionKey &&
        other.sourceRevision == sourceRevision &&
        other.query.avatarKey == query.avatarKey &&
        other.query.normalizedSearch == query.normalizedSearch &&
        listEquals(other.query.categoryIds, query.categoryIds) &&
        listEquals(other.query.merchantKeys, query.merchantKeys) &&
        other.query.selectedVendorKey == query.selectedVendorKey;
  }

  @override
  int get hashCode => Object.hash(
    sourceRevision,
    query.avatarKey,
    query.normalizedSearch,
    Object.hashAll(query.categoryIds),
    Object.hashAll(query.merchantKeys),
    query.selectedVendorKey,
  );
}
