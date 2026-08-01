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
}

@immutable
class DashboardLedgerResult {
  const DashboardLedgerResult({
    required this.totalMinor,
    this.entryCount = 0,
    this.entries = const <DashboardLedgerEntry>[],
    this.nextCursor,
    this.coreRevision,
  });

  final int totalMinor;
  final int entryCount;
  final List<DashboardLedgerEntry> entries;
  final Map<String, Object?>? nextCursor;
  final int? coreRevision;
}

abstract interface class DashboardLedgerRepository {
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope);
}

/// Used by the data-free Flutter host until the Android query bridge is
/// connected. It preserves the query contract without inventing UI data.
class EmptyDashboardLedgerRepository implements DashboardLedgerRepository {
  const EmptyDashboardLedgerRepository();

  @override
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope) async {
    return const DashboardLedgerResult(totalMinor: 0);
  }
}
