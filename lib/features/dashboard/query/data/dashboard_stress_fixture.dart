import 'package:flutter/foundation.dart';

import 'dashboard_ledger_repository.dart';

@immutable
class DashboardStressFixture {
  const DashboardStressFixture({
    required this.seed,
    required this.entries,
    required this.emptyChildKeys,
  });

  final int seed;
  final List<DashboardLedgerEntry> entries;
  final Set<String> emptyChildKeys;
}

/// Deterministic data generator for large-data tests and debug profiling.
/// It deliberately lives outside widget code and performs no I/O.
abstract final class DashboardStressFixtureGenerator {
  static DashboardStressFixture generate({
    required int transactionCount,
    required int seed,
    int dayCount = 365,
    int emptyChildCount = 3,
  }) {
    if (transactionCount < 0) {
      throw ArgumentError.value(transactionCount, 'transactionCount');
    }
    if (dayCount <= 0) throw ArgumentError.value(dayCount, 'dayCount');
    if (emptyChildCount < 0 || emptyChildCount >= dayCount) {
      throw ArgumentError.value(emptyChildCount, 'emptyChildCount');
    }
    var random = seed & 0x7fffffff;
    final entries = <DashboardLedgerEntry>[];
    final occupied = <int>{};
    final populatedDayCount = dayCount - emptyChildCount;
    final baseEpochDay =
        DateTime.utc(2024, 1, 1).millisecondsSinceEpoch ~/ 86400000;
    for (var index = 0; index < transactionCount; index += 1) {
      random = (random * 1103515245 + 12345) & 0x7fffffff;
      final dayOffset = random % populatedDayCount;
      random = (random * 1103515245 + 12345) & 0x7fffffff;
      final minute = random % (24 * 60);
      final expense = index.isOdd;
      occupied.add(dayOffset);
      entries.add(
        DashboardLedgerEntry(
          id: 'stress-$seed-$index',
          partnerId: 'partner-${index % 17}',
          categoryId: 'category-${index % 11}',
          direction: expense ? 'expense' : 'income',
          amountMinor: 100 + (random % 500000),
          bookedLocalEpochDay: baseEpochDay + dayOffset,
          bookedLocalTimeMinutes: minute,
          partnerDisplayName: 'Partner ${index % 17}',
          categoryDisplayName: 'Category ${index % 11}',
          categoryColorId: 'color-${index % 8}',
          categoryIconId: 'icon-${index % 8}',
        ),
      );
    }
    final emptyChildKeys = <String>{};
    for (var dayOffset = 0; dayOffset < dayCount; dayOffset += 1) {
      if (!occupied.contains(dayOffset)) {
        emptyChildKeys.add(
          DateTime.fromMillisecondsSinceEpoch(
            (baseEpochDay + dayOffset) * 86400000,
            isUtc: true,
          ).toIso8601String().substring(0, 10),
        );
      }
    }
    return DashboardStressFixture(
      seed: seed,
      entries: List.unmodifiable(entries),
      emptyChildKeys: Set.unmodifiable(emptyChildKeys),
    );
  }

  static List<DashboardLedgerEntry> firstPreviewRows(
    Iterable<DashboardLedgerEntry> entries, {
    required int rowBudget,
  }) {
    if (rowBudget <= 0) throw ArgumentError.value(rowBudget, 'rowBudget');
    return List<DashboardLedgerEntry>.unmodifiable(entries.take(rowBudget));
  }
}
