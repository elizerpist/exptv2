import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/prepared_budget_limit_snapshot_binary_codec.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';

void main() {
  test(
    'decodes a compact exact revision Budget bank with missing versus zero',
    () {
      final cells = List<PreparedBudgetLimitCell>.generate(
        28,
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
          incomeCategoryIds: const <String>['food'],
          incomeCells: cells,
          expenseCategoryIds: const <String>['rent'],
          expenseCells: cells,
        ),
      );

      expect(snapshot.coreRevision, 41);
      expect(snapshot.incomeBank.orderedCategoryIds, const <String>['food']);
      expect(snapshot.expenseBank.orderedCategoryIds, const <String>['rent']);
      expect(snapshot.nativeSqlCallCount, 4);
      expect(snapshot.nativeSqlDurationMicros, 1);
      expect(snapshot.spendingRhythmSnapshot, isNotNull);
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
          incomeCategoryIds: const <String>['food'],
          incomeCells: const <PreparedBudgetLimitCell>[
            PreparedBudgetLimitCell(actualScaled100: 1, limitScaled100: 1),
          ],
          expenseCategoryIds: const <String>['rent'],
          expenseCells: const <PreparedBudgetLimitCell>[
            PreparedBudgetLimitCell(actualScaled100: 1, limitScaled100: 1),
          ],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('decodes sparse exact target/day rhythm parts with the dense bank', () {
    final cell = const PreparedBudgetLimitCell(
      actualScaled100: 0,
      limitScaled100: null,
    );
    final snapshot = DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
      _encode(
        revision: 41,
        startYear: 2026,
        endYear: 2026,
        incomeCategoryIds: const <String>['salary'],
        incomeCells: List<PreparedBudgetLimitCell>.filled(28, cell),
        expenseCategoryIds: const <String>['food'],
        expenseCells: List<PreparedBudgetLimitCell>.filled(28, cell),
        expenseRhythmPoints: const <(int, int, List<int>)>[
          (20_000, 123, <int>[3, 0, 0, 0, 0, 0, 0, 120]),
        ],
      ),
    );

    expect(
      snapshot.spendingRhythmSnapshot!.expenseBank
          .targetView(0)
          .dayAtEpochDay(20_000)!
          .actualFor(SpendingRhythmDayPart.lateEvening),
      120,
    );
  });

  test(
    'rejects a transported Spending Rhythm day whose eight parts disagree',
    () {
      final cell = const PreparedBudgetLimitCell(
        actualScaled100: 0,
        limitScaled100: null,
      );
      expect(
        () => DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
          _encode(
            revision: 41,
            startYear: 2026,
            endYear: 2026,
            incomeCategoryIds: const <String>[],
            incomeCells: List<PreparedBudgetLimitCell>.filled(14, cell),
            expenseCategoryIds: const <String>[],
            expenseCells: List<PreparedBudgetLimitCell>.filled(14, cell),
            expenseRhythmPoints: const <(int, int, List<int>)>[
              (20_000, 100, <int>[99, 0, 0, 0, 0, 0, 0, 0]),
            ],
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test('rejects the legacy global-target Budget payload version', () {
    expect(
      () => DashboardPreparedBudgetLimitSnapshotBinaryCodec.decode(
        _encode(
          revision: 41,
          startYear: 2026,
          endYear: 2026,
          incomeCategoryIds: const <String>[],
          incomeCells: List<PreparedBudgetLimitCell>.filled(
            14,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
          expenseCategoryIds: const <String>[],
          expenseCells: List<PreparedBudgetLimitCell>.filled(
            14,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
          version: 1,
        ),
      ),
      throwsFormatException,
    );
  });
}

Uint8List _encode({
  required int revision,
  required int startYear,
  required int endYear,
  required List<String> incomeCategoryIds,
  required List<PreparedBudgetLimitCell> incomeCells,
  required List<String> expenseCategoryIds,
  required List<PreparedBudgetLimitCell> expenseCells,
  List<(int, int, List<int>)> expenseRhythmPoints =
      const <(int, int, List<int>)>[],
  int version = DashboardPreparedBudgetLimitSnapshotBinaryCodec.version,
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
  int32(version);
  int64(revision);
  int32(startYear);
  int32(endYear);
  int32(4); // bounded native SQL call count
  int64(1000); // native duration
  void bank(List<String> categoryIds, List<PreparedBudgetLimitCell> cells) {
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
            DashboardPreparedBudgetLimitSnapshotBinaryCodec
                .missingLimitSentinel,
      );
    }
    int32(cells.length);
    bytes.add(<int>[
      for (final cell in cells)
        switch (cell.limitSource) {
          PreparedBudgetLimitSource.unavailable => 0,
          PreparedBudgetLimitSource.base => 1,
          PreparedBudgetLimitSource.override => 2,
        },
    ]);
  }

  bank(incomeCategoryIds, incomeCells);
  bank(expenseCategoryIds, expenseCells);
  void rhythm(int targetCount, List<(int, int, List<int>)> points) {
    int32(targetCount);
    int32(targetCount + 1);
    int32(0);
    int32(points.length);
    for (var index = 1; index < targetCount; index += 1) {
      int32(points.length);
    }
    int32(points.length);
    for (final point in points) {
      int64(point.$1);
      int64(point.$2);
      for (final part in point.$3) {
        int64(part);
      }
    }
  }

  rhythm(incomeCategoryIds.length + 1, const <(int, int, List<int>)>[]);
  rhythm(expenseCategoryIds.length + 1, expenseRhythmPoints);
  return bytes.takeBytes();
}
