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

/// A complete persisted local-day bucket returned with a dashboard first page.
///
/// This stays at the query boundary (rather than in the LogBox widget layer)
/// so the first committed snapshot can carry its aggregate and rows together.
@immutable
class DashboardLedgerDayGroup {
  const DashboardLedgerDayGroup({
    required this.bookedLocalEpochDay,
    required this.entries,
  });

  final int bookedLocalEpochDay;
  final List<DashboardLedgerEntry> entries;
}

@immutable
class DashboardLedgerResult {
  const DashboardLedgerResult({
    required this.totalMinor,
    this.entryCount = 0,
    this.entries = const <DashboardLedgerEntry>[],
    this.dayGroups = const <DashboardLedgerDayGroup>[],
    this.nextCursor,
    this.nextDayCursor,
    this.coreRevision,
    this.scopeKey,
    this.timeScopeKey,
    this.direction,
    this.flowId,
  });

  final int totalMinor;
  final int entryCount;
  final List<DashboardLedgerEntry> entries;
  final List<DashboardLedgerDayGroup> dayGroups;
  final Map<String, Object?>? nextCursor;
  final Map<String, Object?>? nextDayCursor;
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

/// Optional capability for the one bounded first page used by the LogBox.
///
/// It returns the same [DashboardLedgerResult] contract as the committed
/// observer, including total/count and complete local-day groups. This lets a
/// final rail target warm the existing query cache without introducing a
/// second LogBox state owner or a parallel aggregate query.
abstract interface class DashboardLedgerFirstPagePrefetchRepository {
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  });
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
