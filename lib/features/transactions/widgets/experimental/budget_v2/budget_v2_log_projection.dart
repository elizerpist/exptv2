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

class BudgetV2LogProjectionCache {
  BudgetV2LogProjectionCache({this.maximumCachedQueries = 12})
    : assert(maximumCachedQueries > 0);

  final int maximumCachedQueries;
  final Map<_BudgetV2LogProjectionKey, BudgetV2LogProjection> _projections =
      <_BudgetV2LogProjectionKey, BudgetV2LogProjection>{};

  BudgetV2LogProjection resolve({
    required BudgetV2PreparedSnapshot snapshot,
    required BudgetV2LogQuery query,
  }) {
    final normalized = _NormalizedBudgetV2LogQuery.from(query);
    final key = _BudgetV2LogProjectionKey(
      sourceRevision: snapshot.sourceRevision,
      query: normalized,
    );
    final cached = _projections.remove(key);
    if (cached != null) {
      _projections[key] = cached;
      return cached;
    }

    final avatar = snapshot.avatarData(normalized.avatarKey);
    final vendorKey = normalized.selectedVendorKey;
    final records = vendorKey == null
        ? avatar.records
        : avatar.recordsForVendor(vendorKey);
    final ghosts = vendorKey == null
        ? avatar.ghosts
        : avatar.ghostsForVendor(vendorKey);
    final projection = projectTransactionLogEntries(
      _matchingEntries(records: records, ghosts: ghosts, query: normalized),
      rowLimit: normalized.rowLimit,
    );
    final result = BudgetV2LogProjection(
      entries: projection.entries,
      visibleRowCount: projection.visibleRowCount,
      totalRowCount: projection.totalRowCount,
    );
    _projections[key] = result;
    if (_projections.length > maximumCachedQueries) {
      _projections.remove(_projections.keys.first);
    }
    return result;
  }
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
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(sourceRevision, query);
}
