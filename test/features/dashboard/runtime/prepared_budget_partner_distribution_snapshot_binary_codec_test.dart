import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_budget_partner_distribution_snapshot_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';

void main() {
  test('decodes one exact revision dense partner bank for both directions', () {
    final snapshot =
        DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec.decode(
          _encode(),
        );

    expect(snapshot.coreRevision, 41);
    expect(snapshot.yearWindowStart, 2026);
    expect(snapshot.yearWindowEndInclusive, 2026);
    expect(
      snapshot.directionBank(LedgerDirection.expense).orderedPartnerIds,
      const <String>['shop', 'rent'],
    );
    expect(
      snapshot
          .cellAt(
            direction: LedgerDirection.expense,
            period: const BudgetLimitPeriod.month(2026, 1),
            partnerHandle: 1,
          )
          .actualScaled100,
      600,
    );
    expect(
      snapshot
          .cellAt(
            direction: LedgerDirection.expense,
            period: const BudgetLimitPeriod.month(2026, 1),
            partnerHandle: 1,
          )
          .dominantCategoryId,
      'food',
    );
    expect(
      snapshot.directionBank(LedgerDirection.expense).orderedCategoryIds,
      const <String>['food'],
    );
    expect(
      snapshot
          .contributionsFor(
            direction: LedgerDirection.expense,
            period: const BudgetLimitPeriod.month(2026, 1),
            targetHandle: 1,
          )
          .single
          .actualScaled100,
      600,
    );
    expect(
      snapshot.directionBank(LedgerDirection.expense).dayEpochDays,
      const <int>[20_000],
    );
    expect(
      snapshot
          .directionBank(LedgerDirection.expense)
          .dayAggregateFor(20_000)
          .single
          .dominantCategoryId,
      'food',
    );
    expect(
      snapshot
          .directionBank(LedgerDirection.expense)
          .dayContributionsFor(epochDay: 20_000, targetHandle: 1)
          .single
          .partnerHandle,
      1,
    );
  });

  test('rejects an unsupported compact partner payload version', () {
    expect(
      () =>
          DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec.decode(
            _encode(version: 999),
          ),
      throwsFormatException,
    );
  });
}

Uint8List _encode({
  int version =
      DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec.version,
}) {
  final bytes = BytesBuilder(copy: false);
  void int32(int value) {
    final data = ByteData(4)..setInt32(0, value, Endian.big);
    bytes.add(data.buffer.asUint8List());
  }

  void int64(int value) {
    final data = ByteData(8)..setInt64(0, value, Endian.big);
    bytes.add(data.buffer.asUint8List());
  }

  void text(String value) {
    final encoded = utf8.encode(value);
    int32(encoded.length);
    bytes.add(encoded);
  }

  int32(DashboardPreparedBudgetPartnerDistributionSnapshotBinaryCodec.magic);
  int32(version);
  int64(41);
  int32(2026);
  int32(2026);
  int32(3);
  int64(1000);
  void bank(
    List<String> ids,
    List<String> titles,
    List<int> amounts,
    List<String> dominantCategoryIds, {
    List<String> categoryIds = const <String>[],
    List<int> contributionOffsets = const <int>[0],
    List<(int, int)> contributions = const <(int, int)>[],
    List<int> dayEpochDays = const <int>[],
    List<int>? dayAggregateOffsets,
    List<(int, int, String)> dayAggregateCells = const <(int, int, String)>[],
    List<int>? dayCategoryContributionOffsets,
    List<(int, int)> dayCategoryContributions = const <(int, int)>[],
  }) {
    int32(ids.length);
    for (final id in ids) {
      text(id);
    }
    for (final title in titles) {
      text(title);
    }
    int32(amounts.length);
    for (final amount in amounts) {
      int64(amount);
    }
    int32(dominantCategoryIds.length);
    for (final categoryId in dominantCategoryIds) {
      text(categoryId);
    }
    int32(categoryIds.length);
    for (final categoryId in categoryIds) {
      text(categoryId);
    }
    int32(contributionOffsets.length);
    for (final offset in contributionOffsets) {
      int32(offset);
    }
    int32(contributions.length);
    for (final contribution in contributions) {
      int32(contribution.$1);
      int64(contribution.$2);
    }
    int32(dayEpochDays.length);
    for (final epochDay in dayEpochDays) {
      int64(epochDay);
    }
    final aggregateOffsets =
        dayAggregateOffsets ?? List<int>.filled(dayEpochDays.length + 1, 0);
    int32(aggregateOffsets.length);
    for (final offset in aggregateOffsets) {
      int32(offset);
    }
    int32(dayAggregateCells.length);
    for (final cell in dayAggregateCells) {
      int32(cell.$1);
      int64(cell.$2);
      text(cell.$3);
    }
    final dayOffsets =
        dayCategoryContributionOffsets ??
        List<int>.filled(dayEpochDays.length * categoryIds.length + 1, 0);
    int32(dayOffsets.length);
    for (final offset in dayOffsets) {
      int32(offset);
    }
    int32(dayCategoryContributions.length);
    for (final contribution in dayCategoryContributions) {
      int32(contribution.$1);
      int64(contribution.$2);
    }
  }

  // Sum, year and twelve months; two entries in the expense direction.
  final expenseAmounts = List<int>.filled(28, 0)..[5] = 600;
  final expenseDominant = List<String>.filled(28, '')..[5] = 'food';
  bank(const <String>[], const <String>[], const <int>[], const <String>[]);
  bank(
    const <String>['shop', 'rent'],
    const <String>['Bolt', 'Lakbér'],
    expenseAmounts,
    expenseDominant,
    categoryIds: const <String>['food'],
    contributionOffsets: <int>[
      0,
      0,
      0,
      1,
      for (var index = 0; index < 11; index += 1) 1,
    ],
    contributions: const <(int, int)>[(1, 600)],
    dayEpochDays: const <int>[20_000],
    dayAggregateOffsets: const <int>[0, 1],
    dayAggregateCells: const <(int, int, String)>[(1, 600, 'food')],
    dayCategoryContributionOffsets: const <int>[0, 1],
    dayCategoryContributions: const <(int, int)>[(1, 600)],
  );
  return bytes.takeBytes();
}
