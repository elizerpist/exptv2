import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_budget_limit_snapshot_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';

void main() {
  test(
    'decodes a compact exact revision Budget bank with missing versus zero',
    () {
      final cells = List<PreparedBudgetLimitCell>.generate(
        56,
        (index) => PreparedBudgetLimitCell(
          actualScaled100: index * 10,
          limitScaled100: index == 0
              ? null
              : index == 1
              ? 0
              : index * 20,
        ),
      );
      final snapshot = DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
        _encode(
          revision: 41,
          startYear: 2026,
          endYear: 2026,
          categoryIds: const <String>['food'],
          cells: cells,
        ),
      );

      expect(snapshot.coreRevision, 41);
      expect(snapshot.orderedCategoryIds, const <String>['food']);
      expect(snapshot.nativeSqlCallCount, 4);
      expect(snapshot.nativeSqlDurationMicros, 1);
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 0,
            )
            .limitScaled100,
        isNull,
      );
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 1,
            )
            .limitScaled100,
        0,
      );
    },
  );

  test('rejects a mismatched dense vector length', () {
    expect(
      () => DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
        _encode(
          revision: 41,
          startYear: 2026,
          endYear: 2026,
          categoryIds: const <String>['food'],
          cells: const <PreparedBudgetLimitCell>[
            PreparedBudgetLimitCell(actualScaled100: 1, limitScaled100: 1),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });
}

Uint8List _encode({
  required int revision,
  required int startYear,
  required int endYear,
  required List<String> categoryIds,
  required List<PreparedBudgetLimitCell> cells,
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

  void utf8Value(String value) {
    final encoded = utf8.encode(value);
    int32(encoded.length);
    bytes.add(encoded);
  }

  int32(DashboardPreparedBudgetLimitSnapshotBinaryCodec.magic);
  int32(DashboardPreparedBudgetLimitSnapshotBinaryCodec.version);
  int64(revision);
  int32(startYear);
  int32(endYear);
  int32(4); // bounded native SQL call count
  int64(1000); // native duration
  int32(categoryIds.length);
  for (final id in categoryIds) {
    utf8Value(id);
  }
  int32(cells.length);
  for (final cell in cells) {
    int64(cell.actualScaled100);
  }
  int32(cells.length);
  for (final cell in cells) {
    int64(
      cell.limitScaled100 ??
          DashboardPreparedBudgetLimitSnapshotBinaryCodec.missingLimitSentinel,
    );
  }
  return bytes.takeBytes();
}
