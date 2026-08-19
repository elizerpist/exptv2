import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_budget_partner_distribution_snapshot_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';

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
    List<String> dominantCategoryIds,
  ) {
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
  );
  return bytes.takeBytes();
}
