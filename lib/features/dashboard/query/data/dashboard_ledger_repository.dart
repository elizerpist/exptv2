import 'package:flutter/foundation.dart';

import '../domain/current_ledger_query_scope.dart';

@immutable
class DashboardLedgerEntry {
  const DashboardLedgerEntry({
    required this.id,
    required this.partnerId,
    required this.categoryId,
    required this.direction,
    required this.amountMinor,
    required this.bookedLocalEpochDay,
    required this.bookedLocalTimeMinutes,
    this.note,
    this.occurredAtUtcMs,
    this.partnerDisplayName,
    this.categoryDisplayName,
    this.categoryColorId,
    this.categoryIconId,
    this.assignmentMode,
    this.originKind,
  });

  final String id;
  final String partnerId;
  final String categoryId;
  final String direction;
  final int amountMinor;
  final int bookedLocalEpochDay;
  final int bookedLocalTimeMinutes;
  final String? note;
  final int? occurredAtUtcMs;
  final String? partnerDisplayName;
  final String? categoryDisplayName;
  final String? categoryColorId;
  final String? categoryIconId;
  final String? assignmentMode;
  final String? originKind;
}

@immutable
class DashboardLedgerResult {
  const DashboardLedgerResult({
    required this.totalMinor,
    this.entryCount = 0,
    this.entries = const <DashboardLedgerEntry>[],
    this.nextCursor,
    this.coreRevision,
    this.scopeKey,
    this.timeScopeKey,
    this.direction,
    this.flowId,
  });

  final int totalMinor;
  final int entryCount;
  final List<DashboardLedgerEntry> entries;
  final Map<String, Object?>? nextCursor;
  final int? coreRevision;
  final String? scopeKey;
  final String? timeScopeKey;
  final String? direction;
  final String? flowId;
}

abstract interface class DashboardLedgerRepository {
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  });

  /// Emits the current snapshot and subsequent core invalidation snapshots.
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  });
}

/// Optional production capability for one stable database invalidation
/// subscription shared by every dashboard scope.
///
/// Selection changes must not recreate this stream. Implementations emit the
/// current monotonic core revision and subsequent revisions without reading
/// or serializing an exact dashboard scope.
abstract interface class DashboardCoreRevisionRepository {
  Stream<int> watchCoreRevision();
}

/// Used by the data-free Flutter host until the Android query bridge is
/// connected. It preserves the query contract without inventing UI data.
class EmptyDashboardLedgerRepository implements DashboardLedgerRepository {
  const EmptyDashboardLedgerRepository();

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    return const DashboardLedgerResult(totalMinor: 0);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    yield await read(scope, pageSize: pageSize, after: after);
  }
}
